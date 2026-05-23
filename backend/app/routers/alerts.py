from fastapi import APIRouter, HTTPException, Depends
from app.models.schemas import SmsAlertRequest, VoiceAlertRequest, BulkAlertRequest
from app.services.twilio_service import send_sms_alert, send_voice_alert
from app.services.alert_service import send_emergency_alerts
from app.config import supabase
from app.internal.state import system_user_id
from app.dependencies import verify_user_id

router = APIRouter(prefix="/api/v1/alerts", tags=["Alerts"])

@router.post("/send-sms")
async def send_sms_alert_endpoint(payload: SmsAlertRequest, _ = Depends(verify_user_id)):
    user_id = payload.user_id
    try:
        res = supabase.table('guardians').select('guardian_name, guardian_phone').eq('id', payload.guardian_id).single().execute()
        if not res.data: raise HTTPException(status_code=404, detail="Guardian not found")
        
        phone = res.data.get('guardian_phone')
        name = res.data.get('guardian_name', 'Guardian')
        
        user_res = supabase.table('profiles').select('full_name').eq('id', user_id).single().execute()
        user_name = user_res.data.get('full_name', 'Someone') if user_res.data else 'Someone'
        
        message = payload.message or f"🚨 ALERT from {user_name}: I need assistance!"
        
        if send_sms_alert(phone, message):
            supabase.table('messages').insert({
                'sender_id': system_user_id,
                'receiver_id': user_id,
                'content': f"📱 SMS sent to {name} ({phone})",
                'is_read': False
            }).execute()
            return {"success": True}
        else:
            raise HTTPException(status_code=500, detail="Failed to send SMS")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/send-voice")
async def send_voice_alert_endpoint(payload: VoiceAlertRequest, _ = Depends(verify_user_id)):
    user_id = payload.user_id
    try:
        res = supabase.table('guardians').select('guardian_name, guardian_phone').eq('id', payload.guardian_id).single().execute()
        if not res.data: raise HTTPException(status_code=404, detail="Guardian not found")
        
        phone = res.data.get('guardian_phone')
        name = res.data.get('guardian_name', 'Guardian')
        
        if send_voice_alert(phone, payload.latitude or 0.0, payload.longitude or 0.0):
            supabase.table('messages').insert({
                'sender_id': system_user_id,
                'receiver_id': user_id,
                'content': f"📞 Voice call initiated to {name} ({phone})",
                'is_read': False
            }).execute()
            return {"success": True}
        else:
            raise HTTPException(status_code=500, detail="Failed to initiate voice call")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/send-bulk")
async def send_bulk_alerts_endpoint(payload: BulkAlertRequest, _ = Depends(verify_user_id)):
    await send_emergency_alerts(payload.user_id, payload.latitude or 0.0, payload.longitude or 0.0, payload.alert_type)
    return {"success": True}
