from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from app.config import supabase
from app.models.schemas import UserRequest
from app.services.twilio_service import send_sms_alert
from app.internal.state import active_sos_tasks, active_journey_loops, pending_otps
from app.dependencies import get_current_user, verify_user_id

router = APIRouter(prefix="/api/v1/user", tags=["User"])

@router.get("/profile/{user_id}")
async def get_user_profile(user_id: str, _ = Depends(verify_user_id)):
    try:
        res = supabase.table('profiles').select('*').eq('id', user_id).execute()
        return res.data[0] if res.data else None
    except Exception as e:
        # Use generic error message for security
        raise HTTPException(status_code=500, detail="Internal server error while fetching profile")

@router.put("/profile/{user_id}")
async def update_user_profile(user_id: str, updates: dict, _ = Depends(verify_user_id)):
    try:
        supabase.table('profiles').update(updates).eq('id', user_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error while updating profile")

@router.get("/guardians/{user_id}")
async def get_user_guardians(user_id: str, _ = Depends(verify_user_id)):
    try:
        res = supabase.table('guardians').select('*').eq('user_id', user_id).eq('is_active', True).execute()
        guardians = res.data if res.data else []
        return guardians
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error while fetching guardians")

@router.post("/guardians/{user_id}")
async def add_user_guardian(user_id: str, guardian_data: dict, background_tasks: BackgroundTasks, _ = Depends(verify_user_id)):
    try:
        if 'full_name' in guardian_data and 'guardian_name' not in guardian_data:
            guardian_data['guardian_name'] = guardian_data.pop('full_name')
        if 'phone' in guardian_data and 'guardian_phone' not in guardian_data:
            guardian_data['guardian_phone'] = guardian_data.pop('phone')
            
        guardian_data['user_id'] = user_id
        supabase.table('guardians').insert(guardian_data).execute()

        phone = guardian_data.get('guardian_phone')
        name = guardian_data.get('guardian_name', 'Guardian')
        
        if phone:
            user_res = supabase.table('profiles').select('full_name').eq('id', user_id).execute()
            user_name = user_res.data[0].get('full_name', 'Someone') if user_res.data else 'Someone'
            message = f"🛡️ SAFE PATH: Hi {name}, {user_name} has added you as a guardian."
            background_tasks.add_task(send_sms_alert, phone, message)

        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error while adding guardian")

@router.delete("/guardians/{guardian_id}")
async def delete_user_guardian(guardian_id: str, current_user = Depends(get_current_user)):
    try:
        # Verify ownership before delete
        check = supabase.table('guardians').select('user_id').eq('id', guardian_id).single().execute()
        if not check.data or check.data['user_id'] != current_user.id:
             raise HTTPException(status_code=403, detail="Not authorized")
        
        supabase.table('guardians').delete().eq('id', guardian_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error while deleting guardian")

@router.put("/guardians/{guardian_id}")
async def update_user_guardian(guardian_id: str, guardian_data: dict, background_tasks: BackgroundTasks, current_user = Depends(get_current_user)):
    try:
        # 1. Fetch old data to check for phone change
        old_res = supabase.table('guardians').select('*').eq('id', guardian_id).single().execute()
        if not old_res.data:
            raise HTTPException(status_code=404, detail="Guardian not found")
        
        if old_res.data['user_id'] != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized")

        old_phone = old_res.data.get('guardian_phone')
        
        # 2. Update
        update_payload = {}
        if 'full_name' in guardian_data: update_payload['guardian_name'] = guardian_data['full_name']
        if 'guardian_name' in guardian_data: update_payload['guardian_name'] = guardian_data['guardian_name']
        if 'phone' in guardian_data: update_payload['guardian_phone'] = guardian_data['phone']
        if 'guardian_phone' in guardian_data: update_payload['guardian_phone'] = guardian_data['guardian_phone']
        if 'relation' in guardian_data: update_payload['relation'] = guardian_data['relation']
        
        supabase.table('guardians').update(update_payload).eq('id', guardian_id).execute()

        # 3. If phone changed, send notification to new number
        new_phone = update_payload.get('guardian_phone')
        
        if new_phone and str(new_phone).strip() != str(old_phone).strip():
            name = update_payload.get('guardian_name', old_res.data.get('guardian_name', 'Guardian'))
            user_res = supabase.table('profiles').select('full_name').eq('id', current_user.id).execute()
            user_name = user_res.data[0].get('full_name', 'Someone') if user_res.data else 'Someone'
            message = f"🛡️ SAFE PATH: Hi {name}, {user_name} has added you as a guardian."
            background_tasks.add_task(send_sms_alert, new_phone, message)

        return {"success": True}
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error while updating guardian")

@router.post("/delete")
async def delete_user_account_handler(payload: UserRequest, _ = Depends(verify_user_id)):
    user_id = payload.user_id
    try:
        if user_id in active_sos_tasks: del active_sos_tasks[user_id]
        if user_id in active_journey_loops: del active_journey_loops[user_id]
        if user_id in pending_otps: del pending_otps[user_id]
            
        supabase.table('guardians').delete().eq('user_id', user_id).execute()
        supabase.table('journeys').delete().eq('user_id', user_id).execute()
        supabase.table('sos_alerts').delete().eq('user_id', user_id).execute()
        supabase.table('messages').delete().eq('sender_id', user_id).execute()
        supabase.table('messages').delete().eq('receiver_id', user_id).execute()
        supabase.table('profiles').delete().eq('id', user_id).execute()
        supabase.auth.admin.delete_user(user_id)
        
        return {"success": True, "message": "Account deleted."}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error during account deletion")
