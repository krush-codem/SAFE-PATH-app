import os
import asyncio
import uuid
import random
import base64
import httpx
from typing import Optional, List, Dict, Any
from datetime import datetime, timezone, timedelta
from fastapi import FastAPI, HTTPException, Security, BackgroundTasks, Header, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from supabase import create_client, Client
from twilio.rest import Client as TwilioClient
from config import (
    SUPABASE_URL, SUPABASE_KEY, 
    TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER,
    VIRUSTOTAL_API_KEY, VIRUSTOTAL_BASE_URL,
    supabase
)

# Initialize Twilio Client (only if credentials are provided)
twilio_client: Optional[TwilioClient] = None
if TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN:
    try:
        twilio_client = TwilioClient(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        print("✅ Twilio client initialized successfully")
    except Exception as e:
        print(f"⚠️ Failed to initialize Twilio client: {e}")

app = FastAPI(
    title="Safe-Path Backend",
    description="Python FastAPI backend for the Digital Sentinel mobile app",
    version="1.0.0"
)

# --- CORS Configuration ---
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # For development, allow all origins
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- Constants ---
SYSTEM_USER_ID = "ba7a1ae1-8b29-4256-a49e-6624d359d4b2"
SYSTEM_USER_EMAIL = "system@safepath.app"

@app.on_event("startup")
async def startup_event():
    """Ensure system user profile exists for automated messages."""
    global SYSTEM_USER_ID
    try:
        # Check if system user exists by email in profiles
        res = supabase.table('profiles').select('id, email').eq('email', SYSTEM_USER_EMAIL).execute()
        if res.data:
            SYSTEM_USER_ID = res.data[0]['id']
            print(f"✅ System User loaded from database. ID: {SYSTEM_USER_ID}")
        else:
            print("System User not found. Creating via auth admin...")
            # Create user in auth.users
            new_user = supabase.auth.admin.create_user({
                "email": SYSTEM_USER_EMAIL,
                "password": f"SysPass_{uuid.uuid4().hex[:12]}!",
                "email_confirm": True,
                "user_metadata": {"full_name": "SafePath System"},
            })
            SYSTEM_USER_ID = new_user.user.id
            print(f"✅ System User created in auth.users and profiles. ID: {SYSTEM_USER_ID}")
    except Exception as e:
        print(f"⚠️ Startup warning: Could not ensure System User exists: {e}")

# --- Models ---

class StatusUpdate(BaseModel):
    user_id: str
    latitude: float
    longitude: float
    status: str

class SosTrigger(BaseModel):
    user_id: str
    latitude: float
    longitude: float

class OtpRequest(BaseModel):
    user_id: str
    interval_mins: Optional[int] = 30

class OtpVerify(BaseModel):
    user_id: str
    journey_id: Optional[str] = None
    otp: str

class UserRequest(BaseModel):
    user_id: str

class SmsAlertRequest(BaseModel):
    user_id: str
    guardian_id: str
    message: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class VoiceAlertRequest(BaseModel):
    user_id: str
    guardian_id: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class BulkAlertRequest(BaseModel):
    user_id: str
    message: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    alert_type: str = "sms"  # "sms", "voice", or "both"

class UrlScanRequest(BaseModel):
    url: str

class SecurityScanResponse(BaseModel):
    id: str
    status: str
    malicious: int
    suspicious: int
    undetected: int
    harmless: int
    total_engines: int
    link: Optional[str] = None

# --- Twilio Helper Functions ---

def send_sms_alert(to_phone: str, message: str) -> bool:
    """Send SMS alert using Twilio."""
    if not twilio_client or not TWILIO_PHONE_NUMBER:
        print(f"[TWILIO MOCK] SMS to {to_phone}: {message}")
        print(f"[DEBUG] twilio_client: {twilio_client}, TWILIO_PHONE_NUMBER: {TWILIO_PHONE_NUMBER}")
        return False
    
    try:
        # Format phone number (ensure it has + prefix)
        if not to_phone.startswith('+'):
            to_phone = '+' + to_phone
        
        message = twilio_client.messages.create(
            body=message,
            from_=TWILIO_PHONE_NUMBER,
            to=to_phone
        )
        print(f"✅ SMS sent successfully to {to_phone}. SID: {message.sid}")
        return True
    except Exception as e:
        print(f"❌ Failed to send SMS to {to_phone}: {e}")
        return False

def send_voice_alert(to_phone: str, latitude: float, longitude: float) -> bool:
    """Send Voice call alert using Twilio with emergency message."""
    if not twilio_client or not TWILIO_PHONE_NUMBER:
        print(f"[TWILIO MOCK] Voice call to {to_phone}: Emergency Alert!")
        return True
    
    try:
        # Format phone number
        if not to_phone.startswith('+'):
            to_phone = '+' + to_phone
        
        # Create TwiML for the emergency message
        location_url = f"https://www.google.com/maps?q={latitude},{longitude}"
        twiml = f"""<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="en-US">
        Emergency Alert from Safe Path. Your contact needs immediate help. 
        Their current location is at latitude {latitude}, longitude {longitude}.
        Please check your messages for the map link and respond immediately.
        This is an automated emergency call from the Safe Path safety app.
    </Say>
    <Pause length="2"/>
    <Say voice="alice" language="en-US">
        Location link: {location_url}
    </Say>
</Response>"""
        
        call = twilio_client.calls.create(
            twiml=twiml,
            from_=TWILIO_PHONE_NUMBER,
            to=to_phone
        )
        print(f"✅ Voice call initiated to {to_phone}. SID: {call.sid}")
        return True
    except Exception as e:
        print(f"❌ Failed to initiate voice call to {to_phone}: {e}")
        return False

async def send_emergency_alerts(user_id: str, latitude: float, longitude: float, alert_type: str = "both"):
    """Send emergency alerts to all guardians via SMS and/or Voice."""
    try:
        # Get user profile for name
        user_res = supabase.table('profiles').select('full_name').eq('id', user_id).execute()
        user_name = user_res.data[0].get('full_name', 'Someone') if user_res.data else 'Someone'
        
        # Get all active guardians
        res = supabase.table('guardians').select('id, guardian_name, guardian_phone').eq('user_id', user_id).eq('is_active', True).execute()
        guardians = res.data if res.data else []
        
        if not guardians:
            print(f"⚠️ No active guardians found for user {user_id}")
            return
        
        location_url = f"https://www.google.com/maps?q={latitude},{longitude}"
        sms_message = f"🚨 SAFE PATH SOS: {user_name} needs immediate help! Location: {location_url} (Coords: {latitude:.6f}, {longitude:.6f}). Reply OK to confirm you received this."
        
        for guardian in guardians:
            phone = guardian.get('guardian_phone')
            name = guardian.get('guardian_name', 'Guardian')
            
            if not phone:
                print(f"⚠️ Guardian {name} has no phone number")
                continue
            
            # Send SMS if alert_type is "sms" or "both"
            if alert_type in ["sms", "both"]:
                success = send_sms_alert(phone, sms_message)
                if success:
                    # Record the SMS sent in messages table
                    supabase.table('messages').insert({
                        'sender_id': SYSTEM_USER_ID,
                        'receiver_id': user_id,
                        'content': f"📱 SMS Alert sent to {name} ({phone})",
                        'is_read': False
                    }).execute()
            
            # Send Voice if alert_type is "voice" or "both"
            if alert_type in ["voice", "both"]:
                success = send_voice_alert(phone, latitude, longitude)
                if success:
                    # Record the voice call in messages table
                    supabase.table('messages').insert({
                        'sender_id': SYSTEM_USER_ID,
                        'receiver_id': user_id,
                        'content': f"📞 Voice Alert call initiated to {name} ({phone})",
                        'is_read': False
                    }).execute()
            
            # Small delay between alerts to avoid rate limiting
            await asyncio.sleep(1)
        
        print(f"✅ Emergency alerts sent to {len(guardians)} guardians for user {user_id}")
        
    except Exception as e:
        print(f"❌ Error sending emergency alerts: {e}")

# --- SOS Periodic Broadcaster (In-Memory for now) ---
active_sos_tasks = {}
active_journey_loops = {}
pending_otps = {} # {user_id: {"otp": str, "expiry": datetime, "tries": int}}

async def otp_safety_loop(user_id: str, interval_mins: int):
    """Periodically checks user safety via OTP."""
    print(f"Starting safety loop for {user_id} every {interval_mins} mins")
    
    while user_id in active_journey_loops:
        # 1. Wait for the full interval before sending OTP
        wait_time = interval_mins * 60
        if wait_time > 0:
            await asyncio.sleep(wait_time)
        
        if user_id not in active_journey_loops: break

        # 2. Generate and Send OTP
        import random
        otp = "".join([str(random.randint(0, 9)) for _ in range(6)])
        # Use 5 minutes (300 seconds) to match the frontend constant
        pending_otps[user_id] = {"otp": otp, "expiry": datetime.now() + timedelta(minutes=5), "tries": 3}
        
        message = f"🔐 SAFETY CHECK: Your Checkpoint OTP is {otp}. Please enter this in the APP within 5 minutes to confirm your safety."
        
        try:
            supabase.table('messages').insert({
                'sender_id': SYSTEM_USER_ID, 
                'receiver_id': user_id,
                'content': message,
                'is_read': False
            }).execute()
            print(f"OTP {otp} sent to {user_id}")
        except Exception as e:
            print(f"Error sending Safety OTP to {user_id}: {e}")

        # 3. Wait for 5 minutes for verification
        start_wait = datetime.now()
        verified = False
        while (datetime.now() - start_wait).total_seconds() < 300: # 5 minutes
            if user_id not in pending_otps: # Verification successful (removed from dict by handler)
                verified = True
                break
            await asyncio.sleep(5)

        if not verified:
            print(f"FAILED SAFETY CHECK for {user_id}. Triggering SOS!")
            # Trigger SOS Automatically
            if user_id not in active_sos_tasks:
                active_sos_tasks[user_id] = True
                # Get last known location from profiles
                profile = supabase.table('profiles').select('last_lat, last_lng').eq('id', user_id).execute()
                lat = profile.data[0].get('last_lat', 0.0) if profile.data else 0.0
                lng = profile.data[0].get('last_lng', 0.0) if profile.data else 0.0
                
                # We can't easily add a task to BackgroundTasks from a loop, 
                # but we can call it directly since we are already in an async loop or use create_task
                asyncio.create_task(sos_broadcast_loop(user_id, lat, lng))
            
            # Send alert to SYSTEM channel
            supabase.table('messages').insert({
                'sender_id': SYSTEM_USER_ID, 
                'receiver_id': user_id,
                'content': "🚨 SAFETY CHECK FAILED: SOS HAS BEEN AUTOMATICALLY TRIGGERED.",
                'is_read': False
            }).execute()
            
            # Stop the loop if SOS triggered? Usually yes, SOS replaces the journey
            if user_id in active_journey_loops:
                del active_journey_loops[user_id]
            break

async def sos_broadcast_loop(user_id: str, latitude: float, longitude: float):
    """Sends SOS alerts via Chat and SMS every 5 min until stopped."""
    # First alert: Send immediately with SMS only (no voice calls)
    await send_emergency_alerts(user_id, latitude, longitude, alert_type="sms")
    
    while user_id in active_sos_tasks:
        try:
            # 1. Update Journey status to 'sos'
            supabase.table('journeys').update({'status': 'sos'}).eq('user_id', user_id).eq('status', 'active').execute()
            
            # 2. Get Guardians from the 'guardians' table
            res = supabase.table('guardians').select('id, guardian_name, guardian_phone').eq('user_id', user_id).eq('is_active', True).execute()
            guardians = res.data if res.data else []
            
            if not guardians:
                print(f"SOS Broadcaster: No active guardians found for user {user_id}")
            
            # Get user name for personalized message
            user_res = supabase.table('profiles').select('full_name').eq('id', user_id).execute()
            user_name = user_res.data[0].get('full_name', 'I') if user_res.data else 'I'
            
            message = f"🚨 SOS ALERT: {user_name} needs help! Location: https://www.google.com/maps?q={latitude},{longitude} (Coords: {latitude:.6f}, {longitude:.6f})"
            
            for g in guardians:
                g_id = g['id']
                phone = g.get('guardian_phone')
                name = g.get('guardian_name', 'Guardian')
                
                # Add message to chat for each guardian
                try:
                    supabase.table('messages').insert({
                        'sender_id': user_id, 
                        'receiver_id': g_id,
                        'content': message,
                        'is_read': False
                    }).execute()
                except Exception as e:
                    print(f"Error sending chat message to {name}: {e}")
                
                # Send SMS alert via Twilio
                if phone:
                    sms_success = send_sms_alert(phone, message)
                    if sms_success:
                        # Record SMS sent in system chat
                        supabase.table('messages').insert({
                            'sender_id': SYSTEM_USER_ID,
                            'receiver_id': user_id,
                            'content': f"📱 SMS sent to {name} ({phone})",
                            'is_read': False
                        }).execute()
                    else:
                        print(f"⚠️ SMS failed to send to {name} ({phone}) - check Twilio config")

            # 3. Mirror to SYSTEM Channel for the user (Self-notification)
            try:
                supabase.table('messages').insert({
                    'sender_id': SYSTEM_USER_ID, 
                    'receiver_id': user_id,
                    'content': f"🚨 YOUR SOS IS ACTIVE! Your location is being shared with {len(guardians)} guardians via SMS.",
                    'is_read': False
                }).execute()
            except Exception as e:
                print(f"Error mirroring to SYSTEM for {user_id}: {e}")

            print(f"✅ SOS Broadcast sent to {len(guardians)} guardians for user {user_id} at {datetime.now()}")
            
        except Exception as e:
            print(f"❌ Error in SOS Broadcaster for {user_id}: {e}")
            
        await asyncio.sleep(300) # 5 minutes

@app.get("/")
def read_root():
    return {"message": "Safe-Path Backend is running securely"}

@app.post("/api/v1/sos/trigger")
async def trigger_sos(payload: SosTrigger, background_tasks: BackgroundTasks):
    if payload.user_id in active_sos_tasks:
        return {"message": "SOS already active"}
    
    active_sos_tasks[payload.user_id] = True
    background_tasks.add_task(sos_broadcast_loop, payload.user_id, payload.latitude, payload.longitude)
    
    return {"success": True, "message": "SOS alert triggered and broadcasting."}

@app.post("/api/v1/sos/stop")
async def stop_sos(payload: UserRequest):
    user_id = payload.user_id
    if user_id in active_sos_tasks:
        del active_sos_tasks[user_id]
        return {"success": True, "message": "SOS deactivated."}
    return {"message": "No active SOS found for user."}

@app.post("/api/v1/journey/start")
async def start_journey_handler(payload: OtpRequest, background_tasks: BackgroundTasks):
    interval = payload.interval_mins or 30
    if payload.user_id in active_journey_loops:
        return {"success": False, "message": "Journey loop already active"}
    
    active_journey_loops[payload.user_id] = True
    background_tasks.add_task(otp_safety_loop, payload.user_id, interval)
    print(f"Safety Journey started for {payload.user_id}")
    return {"success": True, "message": f"Safety Journey started. Next check in {interval} mins."}

@app.post("/api/v1/journey/verify-otp")
async def verify_journey_otp(payload: OtpVerify):
    user_id = payload.user_id
    otp_provided = payload.otp
    
    if user_id not in pending_otps:
        return {"success": False, "message": "No pending safety check or time expired."}
    
    session = pending_otps[user_id]
    if session["otp"] == otp_provided:
        # Success!
        del pending_otps[user_id]
        return {"success": True, "message": "Safety verified. Next check scheduled."}
    else:
        session["tries"] -= 1
        if session["tries"] <= 0:
            # Immediate SOS Trigger on 3 failed tries
            if user_id not in active_sos_tasks:
                active_sos_tasks[user_id] = True
                profile = supabase.table('profiles').select('last_lat, last_lng').eq('id', user_id).execute()
                lat = profile.data[0].get('last_lat', 0.0) if profile.data else 0.0
                lng = profile.data[0].get('last_lng', 0.0) if profile.data else 0.0
                # Directly start SOS broadcast
                asyncio.create_task(sos_broadcast_loop(user_id, lat, lng))
            
            # Message back to user
            supabase.table('messages').insert({
                'sender_id': SYSTEM_USER_ID, 
                'receiver_id': user_id,
                'content': "🚨 SAFETY CHECK FAILED: 0 TRIES LEFT. SOS HAS BEEN AUTOMATICALLY TRIGGERED.",
                'is_read': False
            }).execute()
            
            if user_id in active_journey_loops:
                del active_journey_loops[user_id]
            del pending_otps[user_id] # Stop the safety_loop wait

            return {"success": False, "message": "Incorrect OTP. 0 tries left. SOS Triggering..."}
        
        return {"success": False, "message": f"Incorrect OTP. {session['tries']} tries left."}

@app.post("/api/v1/journey/stop")
async def stop_journey_handler(payload: UserRequest):
    user_id = payload.user_id
    if user_id in active_journey_loops:
        del active_journey_loops[user_id]
    if user_id in pending_otps:
        del pending_otps[user_id]
    return {"success": True, "message": "Journey safety loop stopped."}

@app.post("/api/v1/user/delete")
async def delete_user_account_handler(payload: UserRequest):
    """
    Completely deletes a user from Supabase Auth and the database.
    This requires the service_role key to access auth.admin.
    """
    user_id = payload.user_id
    try:
        print(f"HARD DELETE REQUEST for user_id: {user_id}")
        
        # 1. First, stop any active journey loops or SOS tasks
        if user_id in active_sos_tasks:
            del active_sos_tasks[user_id]
        if user_id in active_journey_loops:
            del active_journey_loops[user_id]
        if user_id in pending_otps:
            del pending_otps[user_id]
            
        # 2. Delete guardians linked to this user
        supabase.table('guardians').delete().eq('user_id', user_id).execute()
        
        # 3. Delete user journeys and alerts
        supabase.table('journeys').delete().eq('user_id', user_id).execute()
        supabase.table('sos_alerts').delete().eq('user_id', user_id).execute()
        
        # 4. Cleanup messages
        supabase.table('messages').delete().eq('sender_id', user_id).execute()
        supabase.table('messages').delete().eq('receiver_id', user_id).execute()
        
        # 5. Delete user profile
        supabase.table('profiles').delete().eq('id', user_id).execute()
        
        # 6. Finally, delete from Supabase Auth
        # Note: In supabase-py, auth.admin.delete_user is how you do it with service_role
        res = supabase.auth.admin.delete_user(user_id)
        
        print(f"SUCCESSfully deleted user {user_id}")
        return {"success": True, "message": "User account and all data deleted permanently."}
        
    except Exception as e:
        print(f"ERROR deleting user {user_id}: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to delete account: {str(e)}")

# --- User Profile & Guardian Endpoints (Bypassing RLS with service_role) ---

@app.get("/api/v1/user/profile/{user_id}")
async def get_user_profile(user_id: str):
    try:
        res = supabase.table('profiles').select('*').eq('id', user_id).execute()
        return res.data[0] if res.data else None
    except Exception as e:
        print(f"ERROR fetching profile for {user_id}: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=str(e))

@app.put("/api/v1/user/profile/{user_id}")
async def update_user_profile(user_id: str, updates: dict):
    try:
        supabase.table('profiles').update(updates).eq('id', user_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/user/guardians/{user_id}")
async def get_user_guardians(user_id: str):
    try:
        res = supabase.table('guardians').select('*').eq('user_id', user_id).eq('is_active', True).execute()
        guardians = res.data if res.data else []
        
        # Enrich with profile info if they are registered users
        if guardians:
            phones = [g.get('guardian_phone') for g in guardians if g.get('guardian_phone')]
            if phones:
                # Fetch profiles matching these phones
                profiles_res = supabase.table('profiles').select('id, phone_number, avatar_url, full_name').in_('phone_number', phones).execute()
                profiles_map = {p['phone_number']: p for p in (profiles_res.data if profiles_res.data else [])}
                
                for g in guardians:
                    phone = g.get('guardian_phone')
                    if phone in profiles_map:
                        p = profiles_map[phone]
                        g['guardian_name'] = p.get('full_name') or g.get('guardian_name')
                        g['avatar_url'] = p.get('avatar_url')
                        g['is_app_user'] = True
                        g['profile_id'] = p.get('id')
                        
        return guardians
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/user/guardians/{user_id}")
async def add_user_guardian(user_id: str, guardian_data: dict, background_tasks: BackgroundTasks):
    try:
        # Robustly handle both old ('full_name', 'phone') and new ('guardian_name', 'guardian_phone') keys
        if 'full_name' in guardian_data and 'guardian_name' not in guardian_data:
            guardian_data['guardian_name'] = guardian_data.pop('full_name')
        if 'phone' in guardian_data and 'guardian_phone' not in guardian_data:
            guardian_data['guardian_phone'] = guardian_data.pop('phone')
            
        guardian_data['user_id'] = user_id
        supabase.table('guardians').insert(guardian_data).execute()

        # Send welcome SMS to the added guardian
        phone = guardian_data.get('guardian_phone')
        name = guardian_data.get('guardian_name', 'Guardian')
        if phone:
            try:
                user_res = supabase.table('profiles').select('full_name').eq('id', user_id).execute()
                user_name = user_res.data[0].get('full_name', 'Someone') if user_res.data else 'Someone'
            except Exception as ue:
                print(f"Error fetching user name for guardian welcome SMS: {ue}")
                user_name = "Someone"

            message = f"🛡️ SAFE PATH: Hi {name}, {user_name} has added you as an emergency guardian. You will receive SMS alerts in case of an emergency."
            background_tasks.add_task(send_sms_alert, phone, message)

        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.delete("/api/v1/user/guardians/{guardian_id}")
async def delete_user_guardian(guardian_id: str):
    try:
        supabase.table('guardians').delete().eq('id', guardian_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

# --- Twilio Alert Endpoints for Chat Screen ---

@app.post("/api/v1/alerts/send-sms")
async def send_sms_alert_endpoint(payload: SmsAlertRequest):
    """Send manual SMS alert to a specific guardian from the chat screen."""
    try:
        # Get guardian details
        res = supabase.table('guardians').select('full_name, phone').eq('id', payload.guardian_id).single().execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Guardian not found")
        
        guardian = res.data
        phone = guardian.get('phone')
        name = guardian.get('full_name', 'Guardian')
        
        if not phone:
            raise HTTPException(status_code=400, detail="Guardian has no phone number")
        
        # Get user name
        user_res = supabase.table('profiles').select('full_name').eq('id', payload.user_id).single().execute()
        user_name = user_res.data.get('full_name', 'Someone') if user_res.data else 'Someone'
        
        # Build message
        if payload.message:
            message = f"📱 Message from {user_name} via Safe Path: {payload.message}"
        elif payload.latitude and payload.longitude:
            location_url = f"https://www.google.com/maps?q={payload.latitude},{payload.longitude}"
            message = f"🚨 ALERT from {user_name}: I need assistance! Location: {location_url}"
        else:
            message = f"🚨 ALERT from {user_name}: Please check the Safe Path app immediately."
        
        # Send SMS
        success = send_sms_alert(phone, message)
        
        if success:
            # Record in messages table
            supabase.table('messages').insert({
                'sender_id': SYSTEM_USER_ID,
                'receiver_id': payload.user_id,
                'content': f"📱 SMS sent to {name} ({phone})",
                'is_read': False
            }).execute()
            return {"success": True, "message": f"SMS sent to {name}"}
        else:
            raise HTTPException(status_code=500, detail="Failed to send SMS")
            
    except Exception as e:
        print(f"Error sending SMS alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/alerts/send-voice")
async def send_voice_alert_endpoint(payload: VoiceAlertRequest):
    """Send manual Voice call alert to a specific guardian from the chat screen."""
    try:
        # Get guardian details
        res = supabase.table('guardians').select('full_name, phone').eq('id', payload.guardian_id).single().execute()
        if not res.data:
            raise HTTPException(status_code=404, detail="Guardian not found")
        
        guardian = res.data
        phone = guardian.get('phone')
        name = guardian.get('full_name', 'Guardian')
        
        if not phone:
            raise HTTPException(status_code=400, detail="Guardian has no phone number")
        
        # Get location or use defaults
        lat = payload.latitude or 0.0
        lng = payload.longitude or 0.0
        
        # Send Voice call
        success = send_voice_alert(phone, lat, lng)
        
        if success:
            # Record in messages table
            supabase.table('messages').insert({
                'sender_id': SYSTEM_USER_ID,
                'receiver_id': payload.user_id,
                'content': f"📞 Voice call initiated to {name} ({phone})",
                'is_read': False
            }).execute()
            return {"success": True, "message": f"Voice call initiated to {name}"}
        else:
            raise HTTPException(status_code=500, detail="Failed to initiate voice call")
            
    except Exception as e:
        print(f"Error sending voice alert: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/api/v1/alerts/send-bulk")
async def send_bulk_alerts_endpoint(payload: BulkAlertRequest):
    """Send SMS/Voice alerts to all guardians from the chat screen or panic button."""
    try:
        lat = payload.latitude or 0.0
        lng = payload.longitude or 0.0
        
        await send_emergency_alerts(
            payload.user_id, 
            lat, 
            lng, 
            alert_type=payload.alert_type
        )
        
        alert_type_desc = {
            "sms": "SMS alerts",
            "voice": "Voice calls",
            "both": "SMS and Voice alerts"
        }.get(payload.alert_type, "Alerts")
        
        return {
            "success": True, 
            "message": f"{alert_type_desc} sent to all guardians"
        }
            
    except Exception as e:
        print(f"Error sending bulk alerts: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/v1/twilio/status")
async def twilio_status():
    """Check Twilio configuration status."""
    return {
        "configured": twilio_client is not None,
        "phone_number": TWILIO_PHONE_NUMBER if TWILIO_PHONE_NUMBER else None,
        "message": "Twilio is ready" if twilio_client else "Twilio not configured - running in mock mode"
    }

# --- Security Scanner (VirusTotal Proxy) ---

async def poll_virustotal_analysis(analysis_id: str) -> Dict[str, Any]:
    """Helper to poll VirusTotal for analysis completion."""
    headers = {
        "x-apikey": VIRUSTOTAL_API_KEY,
        "accept": "application/json"
    }
    
    async with httpx.AsyncClient() as client:
        # Maximum 20 retries (approx 1 minute max)
        for _ in range(20):
            await asyncio.sleep(3)
            try:
                response = await client.get(
                    f"{VIRUSTOTAL_BASE_URL}/analyses/{analysis_id}",
                    headers=headers
                )
                if response.status_code == 200:
                    data = response.json()
                    status = data["data"]["attributes"]["status"]
                    if status == "completed":
                        return data["data"]["attributes"]
                elif response.status_code == 429:
                    print("⚠️ VirusTotal Rate Limit Exceeded during polling")
                    await asyncio.sleep(5) # Backoff
            except Exception as e:
                print(f"Error polling analysis {analysis_id}: {e}")
        
    raise HTTPException(status_code=408, detail="Security scan timed out. Please try again.")

@app.post("/api/v1/security/scan-url", response_model=SecurityScanResponse)
async def scan_url_endpoint(payload: UrlScanRequest):
    """Proxy URL scan requests to VirusTotal safely."""
    if not VIRUSTOTAL_API_KEY:
        raise HTTPException(status_code=503, detail="Security service not configured on server")

    headers = {
        "x-apikey": VIRUSTOTAL_API_KEY,
        "accept": "application/json"
    }

    async with httpx.AsyncClient() as client:
        # Encode URL for v3 API
        url_id = base64.urlsafe_b64encode(payload.url.encode()).decode().strip("=")
        
        # 1. Try to get existing report first (to save quota)
        try:
            report_res = await client.get(f"{VIRUSTOTAL_BASE_URL}/urls/{url_id}", headers=headers)
            if report_res.status_code == 200:
                stats = report_res.json()["data"]["attributes"]["last_analysis_stats"]
                return SecurityScanResponse(
                    id=url_id,
                    status="completed",
                    malicious=stats.get("malicious", 0),
                    suspicious=stats.get("suspicious", 0),
                    underected=stats.get("undetected", 0),
                    harmless=stats.get("harmless", 0),
                    total_engines=sum(stats.values()),
                    link=f"https://www.virustotal.com/gui/url/{url_id}"
                )
        except Exception:
            pass # Fallback to new scan

        # 2. Submit new scan
        try:
            submit_res = await client.post(
                f"{VIRUSTOTAL_BASE_URL}/urls",
                headers=headers,
                data={"url": payload.url}
            )
            
            if submit_res.status_code != 200:
                detail = submit_res.json().get("error", {}).get("message", "VirusTotal Submission Failed")
                raise HTTPException(status_code=submit_res.status_code, detail=detail)
            
            analysis_id = submit_res.json()["data"]["id"]
            results = await poll_virustotal_analysis(analysis_id)
            stats = results["stats"]
            
            return SecurityScanResponse(
                id=analysis_id,
                status="completed",
                malicious=stats.get("malicious", 0),
                suspicious=stats.get("suspicious", 0),
                undetected=stats.get("undetected", 0),
                harmless=stats.get("harmless", 0),
                total_engines=sum(stats.values()),
                link=f"https://www.virustotal.com/gui/url/{url_id}"
            )
        except HTTPException:
            raise
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"Internal Security Scan Error: {str(e)}")

@app.post("/api/v1/security/scan-file", response_model=SecurityScanResponse)
async def scan_file_endpoint(file: UploadFile = File(...)):
    """Proxy file scan requests to VirusTotal safely."""
    if not VIRUSTOTAL_API_KEY:
        raise HTTPException(status_code=503, detail="Security service not configured on server")

    headers = {
        "x-apikey": VIRUSTOTAL_API_KEY,
        "accept": "application/json"
    }

    async with httpx.AsyncClient() as client:
        try:
            # 1. Submit file
            content = await file.read()
            files = {"file": (file.filename, content)}
            
            submit_res = await client.post(
                f"{VIRUSTOTAL_BASE_URL}/files",
                headers=headers,
                files=files
            )
            
            if submit_res.status_code != 200:
                detail = submit_res.json().get("error", {}).get("message", "VirusTotal File Submission Failed")
                raise HTTPException(status_code=submit_res.status_code, detail=detail)
            
            analysis_id = submit_res.json()["data"]["id"]
            results = await poll_virustotal_analysis(analysis_id)
            stats = results["stats"]
            
            # For files, the ID in GUI is usually the SHA256, which isn't analysis_id
            # but we can return analysis results directly.
            return SecurityScanResponse(
                id=analysis_id,
                status="completed",
                malicious=stats.get("malicious", 0),
                suspicious=stats.get("suspicious", 0),
                undetected=stats.get("undetected", 0),
                harmless=stats.get("harmless", 0),
                total_engines=sum(stats.values())
            )
        except Exception as e:
            raise HTTPException(status_code=500, detail=f"File Scan Error: {str(e)}")
