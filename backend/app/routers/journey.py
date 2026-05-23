import asyncio
from fastapi import APIRouter, BackgroundTasks, Depends
from app.models.schemas import OtpRequest, OtpVerify, UserRequest
from app.services.journey_service import otp_safety_loop
from app.services.alert_service import sos_broadcast_loop
from app.internal.state import active_journey_loops, pending_otps, active_sos_tasks, system_user_id
from app.config import supabase
from app.dependencies import verify_user_id

router = APIRouter(prefix="/api/v1/journey", tags=["Journey"])

@router.post("/start")
async def start_journey_handler(payload: OtpRequest, background_tasks: BackgroundTasks, _ = Depends(verify_user_id)):
    user_id = payload.user_id
    interval = payload.interval_mins or 30
    if user_id in active_journey_loops:
        return {"success": False, "message": "Journey loop already active"}
    
    active_journey_loops[user_id] = True
    background_tasks.add_task(otp_safety_loop, user_id, interval)
    return {"success": True, "message": f"Safety Journey started. Next check in {interval} mins."}

@router.post("/verify-otp")
async def verify_journey_otp(payload: OtpVerify, _ = Depends(verify_user_id)):
    user_id = payload.user_id
    otp_provided = payload.otp
    
    try:
        if user_id not in pending_otps:
            return {"success": False, "message": "No pending safety check or time expired."}
        
        session = pending_otps[user_id]
        if session["otp"] == otp_provided:
            del pending_otps[user_id]
            return {"success": True, "message": "Safety verified."}
        else:
            session["tries"] -= 1
            if session["tries"] <= 0:
                if user_id not in active_sos_tasks:
                    active_sos_tasks[user_id] = True
                    profile = supabase.table('profiles').select('last_lat, last_lng').eq('id', user_id).execute()
                    lat = profile.data[0].get('last_lat', 0.0) if profile.data else 0.0
                    lng = profile.data[0].get('last_lng', 0.0) if profile.data else 0.0
                    asyncio.create_task(sos_broadcast_loop(user_id, lat, lng))
                
                supabase.table('messages').insert({
                    'sender_id': system_user_id, 
                    'receiver_id': user_id,
                    'content': "🚨 SAFETY CHECK FAILED: SOS TRIGGERED.",
                    'is_read': False
                }).execute()
                
                if user_id in active_journey_loops: del active_journey_loops[user_id]
                del pending_otps[user_id]
                return {"success": False, "message": "Incorrect OTP. SOS Triggering..."}
            
            return {"success": False, "message": f"Incorrect OTP. {session['tries']} tries left."}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error during OTP verification")

@router.post("/stop")
async def stop_journey_handler(payload: UserRequest, _ = Depends(verify_user_id)):
    user_id = payload.user_id
    try:
        if user_id in active_journey_loops: del active_journey_loops[user_id]
        if user_id in pending_otps: del pending_otps[user_id]
        return {"success": True, "message": "Journey safety loop stopped."}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error while stopping journey")
