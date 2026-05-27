import asyncio
import json
from fastapi import APIRouter, WebSocket, WebSocketDisconnect, Query
from app.config import supabase
from app.models.schemas import ChatMessagePayload
from typing import Dict

router = APIRouter(prefix="/api/v1/chat", tags=["Chat"])

class ConnectionManager:
    def __init__(self):
        # Maps user_id -> WebSocket
        self.active_connections: Dict[str, WebSocket] = {}

    async def connect(self, user_id: str, websocket: WebSocket):
        await websocket.accept()
        self.active_connections[user_id] = websocket
        print(f"🔌 User {user_id} connected to WebSocket.")

    def disconnect(self, user_id: str):
        if user_id in self.active_connections:
            del self.active_connections[user_id]
            print(f"❌ User {user_id} disconnected from WebSocket.")

    async def send_personal_message(self, message: dict, user_id: str):
        if user_id in self.active_connections:
            await self.active_connections[user_id].send_json(message)

    async def broadcast(self, message: dict):
        """Future-ready for Redis Pub/Sub integration."""
        for connection in self.active_connections.values():
            await connection.send_json(message)

manager = ConnectionManager()

async def save_message_to_db(sender_id: str, receiver_id: str, content: str):
    """Background task to persist messages to Supabase."""
    try:
        supabase.table("messages").insert({
            "sender_id": sender_id,
            "receiver_id": receiver_id,
            "content": content,
            "is_read": False
        }).execute()
        print(f"💾 Message from {sender_id} to {receiver_id} saved to DB.")
    except Exception as e:
        print(f"⚠️ Error saving message to DB: {e}")

@router.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    user_id = None
    try:
        # 1. Wait for Auth Handshake
        await websocket.accept()
        auth_data = await websocket.receive_json()
        
        if auth_data.get("type") != "auth" or not auth_data.get("token"):
            await websocket.close(code=4001, reason="Authentication required as first message.")
            return

        # 2. Verify Supabase JWT
        token = auth_data["token"]
        try:
            res = supabase.auth.get_user(token)
            if not res or not res.user:
                await websocket.close(code=4001, reason="Invalid or expired token.")
                return
            user_id = res.user.id
        except Exception as e:
            print(f"JWT Verification Error: {e}")
            await websocket.close(code=4001, reason="Authentication failed.")
            return

        # 3. Register Connection
        manager.active_connections[user_id] = websocket
        print(f"✅ User {user_id} authenticated and connected.")

        # Send welcome/ack
        await websocket.send_json({"type": "status", "message": "Authenticated successfully"})

        # 4. Handle Incoming Messages
        while True:
            data = await websocket.receive_json()
            
            if data.get("type") == "chat":
                payload = ChatMessagePayload(**data["payload"])
                payload.sender_id = user_id

                # A) Immediate Ack to Sender
                await websocket.send_json({
                    "type": "ack",
                    "payload": data["payload"]
                })

                # B) Broadcast to Recipient (if online)
                message_to_send = {
                    "type": "msg",
                    "payload": {
                        "sender_id": user_id,
                        "receiver_id": payload.receiver_id,
                        "content": payload.content,
                        "created_at": None # DB will generate this, but we'll fix in sync
                    }
                }
                await manager.send_personal_message(message_to_send, payload.receiver_id)

                # C) Async Background DB Write
                asyncio.create_task(save_message_to_db(
                    sender_id=user_id,
                    receiver_id=payload.receiver_id,
                    content=payload.content
                ))
            
            elif data.get("type") == "ping":
                await websocket.send_json({"type": "pong"})

    except WebSocketDisconnect:
        if user_id:
            manager.disconnect(user_id)
    except Exception as e:
        print(f"WebSocket Error: {e}")
        if user_id:
            manager.disconnect(user_id)
