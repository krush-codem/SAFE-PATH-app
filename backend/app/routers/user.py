from fastapi import APIRouter, HTTPException, BackgroundTasks, Depends
from datetime import datetime, timezone, timedelta
from app.config import supabase
from app.models.schemas import UserRequest
from app.services.twilio_service import send_sms_alert
from app.internal.state import active_sos_tasks, active_journey_loops, pending_otps
from app.dependencies import get_current_user, verify_user_id

router = APIRouter(prefix="/api/v1/user", tags=["User"])

@router.get("/profile/{user_id}")
def get_user_profile(user_id: str, _ = Depends(verify_user_id)):
    try:
        res = supabase.table('profiles').select('*').eq('id', user_id).execute()
        return res.data[0] if res.data else None
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

@router.put("/profile/{user_id}")
def update_user_profile(user_id: str, updates: dict, _ = Depends(verify_user_id)):
    try:
        if 'updated_at' not in updates:
            updates['updated_at'] = datetime.now(timezone.utc).isoformat()
        supabase.table('profiles').update(updates).eq('id', user_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/heartbeat")
def user_heartbeat(current_user = Depends(get_current_user)):
    try:
        now = datetime.now(timezone.utc).isoformat()
        supabase.table('profiles').update({'last_active': now}).eq('id', current_user.id).execute()
        return {"success": True, "timestamp": now}
    except Exception as e:
        return {"success": False, "error": str(e)}

@router.get("/guardians/{user_id}")
def get_user_guardians(user_id: str, _ = Depends(verify_user_id)):
    try:
        res = supabase.table('guardians').select('*').eq('user_id', user_id).eq('is_active', True).execute()
        guardians = res.data if res.data else []

        if not guardians:
            return []

        # 1. Efficient batch linking
        unlinked_phones = [g['guardian_phone'] for g in guardians if not g.get('guardian_user_id') and g.get('guardian_phone')]
        
        if unlinked_phones:
            p_res = supabase.table('profiles').select('id, phone_number').in_('phone_number', unlinked_phones).execute()
            phone_to_id = {p['phone_number']: p['id'] for p in p_res.data} if p_res.data else {}
            
            if phone_to_id:
                for g in guardians:
                    phone = g.get('guardian_phone')
                    if not g.get('guardian_user_id') and phone in phone_to_id:
                        guid = phone_to_id[phone]
                        g['guardian_user_id'] = guid
                        try:
                            supabase.table('guardians').update({'guardian_user_id': guid}).eq('id', g['id']).execute()
                        except: pass 

        # 2. Batch fetch status
        user_ids = [g['guardian_user_id'] for g in guardians if g.get('guardian_user_id')]
        if user_ids:
            profiles_res = supabase.table('profiles').select('id, last_active, avatar_url').in_('id', user_ids).execute()
            status_map = {p['id']: p for p in profiles_res.data}
            
            now = datetime.now(timezone.utc)
            for g in guardians:
                guid = g.get('guardian_user_id')
                if guid and guid in status_map:
                    p = status_map[guid]
                    g['last_active'] = p.get('last_active')
                    g['avatar_url'] = p.get('avatar_url')
                    
                    if g['last_active']:
                        try:
                            la_str = g['last_active'].replace('Z', '+00:00')
                            la_dt = datetime.fromisoformat(la_str)
                            g['is_online'] = now - la_dt < timedelta(minutes=5)
                        except: g['is_online'] = False
                    else: g['is_online'] = False
                else: g['is_online'] = False
        else:
            for g in guardians: g['is_online'] = False

        return guardians
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/guardians/{user_id}")
def add_user_guardian(user_id: str, guardian_data: dict, background_tasks: BackgroundTasks, _ = Depends(verify_user_id)):
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
        raise HTTPException(status_code=500, detail="Internal server error")

@router.delete("/guardians/{guardian_id}")
def delete_user_guardian(guardian_id: str, current_user = Depends(get_current_user)):
    try:
        check = supabase.table('guardians').select('user_id').eq('id', guardian_id).single().execute()
        if not check.data or check.data['user_id'] != current_user.id:
             raise HTTPException(status_code=403, detail="Not authorized")
        
        supabase.table('guardians').delete().eq('id', guardian_id).execute()
        return {"success": True}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

@router.put("/guardians/{guardian_id}")
def update_user_guardian(guardian_id: str, guardian_data: dict, background_tasks: BackgroundTasks, current_user = Depends(get_current_user)):
    try:
        old_res = supabase.table('guardians').select('*').eq('id', guardian_id).single().execute()
        if not old_res.data:
            raise HTTPException(status_code=404, detail="Guardian not found")
        
        if old_res.data['user_id'] != current_user.id:
            raise HTTPException(status_code=403, detail="Not authorized")

        old_phone = old_res.data.get('guardian_phone')
        
        update_payload = {}
        if 'full_name' in guardian_data: update_payload['guardian_name'] = guardian_data['full_name']
        if 'guardian_name' in guardian_data: update_payload['guardian_name'] = guardian_data['guardian_name']
        if 'phone' in guardian_data: update_payload['guardian_phone'] = guardian_data['phone']
        if 'guardian_phone' in guardian_data: update_payload['guardian_phone'] = guardian_data['guardian_phone']
        if 'relation' in guardian_data: update_payload['relation'] = guardian_data['relation']
        
        supabase.table('guardians').update(update_payload).eq('id', guardian_id).execute()

        new_phone = update_payload.get('guardian_phone')
        if new_phone and str(new_phone).strip() != str(old_phone).strip():
            name = update_payload.get('guardian_name', old_res.data.get('guardian_name', 'Guardian'))
            user_res = supabase.table('profiles').select('full_name').eq('id', current_user.id).execute()
            user_name = user_res.data[0].get('full_name', 'Someone') if user_res.data else 'Someone'
            message = f"🛡️ SAFE PATH: Hi {name}, {user_name} has added you as a guardian."
            background_tasks.add_task(send_sms_alert, new_phone, message)

        return {"success": True}
    except HTTPException: raise
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")

@router.post("/delete")
def delete_user_account_handler(payload: UserRequest, _ = Depends(verify_user_id)):
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
