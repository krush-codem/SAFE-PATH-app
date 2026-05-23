import asyncio
from datetime import datetime
from app.config import supabase
from app.services.twilio_service import send_sms_alert, send_voice_alert
from app.internal.state import active_sos_tasks, system_user_id

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
        sms_message = f"🚨 SAFE PATH SOS: {user_name} needs immediate help! Location: {location_url}"
        
        for guardian in guardians:
            phone = guardian.get('guardian_phone')
            name = guardian.get('guardian_name', 'Guardian')
            
            if not phone: continue
            
            if alert_type in ["sms", "both"]:
                if send_sms_alert(phone, sms_message):
                    supabase.table('messages').insert({
                        'sender_id': system_user_id,
                        'receiver_id': user_id,
                        'content': f"📱 SMS Alert sent to {name} ({phone})",
                        'is_read': False
                    }).execute()
            
            if alert_type in ["voice", "both"]:
                if send_voice_alert(phone, latitude, longitude):
                    supabase.table('messages').insert({
                        'sender_id': system_user_id,
                        'receiver_id': user_id,
                        'content': f"📞 Voice Alert call initiated to {name} ({phone})",
                        'is_read': False
                    }).execute()
            
            await asyncio.sleep(1)
        
    except Exception as e:
        print(f"❌ Error sending emergency alerts: {e}")

async def sos_broadcast_loop(user_id: str, latitude: float, longitude: float):
    """Sends SOS alerts via Chat and SMS every 5 min until stopped."""
    # First alert: Send immediately with SMS only
    await send_emergency_alerts(user_id, latitude, longitude, alert_type="sms")
    
    while user_id in active_sos_tasks:
        try:
            # 1. Update Journey status to 'sos'
            supabase.table('journeys').update({'status': 'sos'}).eq('user_id', user_id).eq('status', 'active').execute()
            
            # 2. Get Guardians
            res = supabase.table('guardians').select('id, guardian_name, guardian_phone').eq('user_id', user_id).eq('is_active', True).execute()
            guardians = res.data if res.data else []
            
            user_res = supabase.table('profiles').select('full_name').eq('id', user_id).execute()
            user_name = user_res.data[0].get('full_name', 'I') if user_res.data else 'I'
            
            message = f"🚨 SOS ALERT: {user_name} needs help! Location: https://www.google.com/maps?q={latitude},{longitude}"
            
            for g in guardians:
                g_id = g['id']
                phone = g.get('guardian_phone')
                
                # Chat message
                supabase.table('messages').insert({
                    'sender_id': user_id, 
                    'receiver_id': g_id,
                    'content': message,
                    'is_read': False
                }).execute()
                
                # SMS
                if phone:
                    send_sms_alert(phone, message)

            # Mirror to SYSTEM
            supabase.table('messages').insert({
                'sender_id': system_user_id, 
                'receiver_id': user_id,
                'content': f"🚨 YOUR SOS IS ACTIVE! Your location is being shared with {len(guardians)} guardians.",
                'is_read': False
            }).execute()

            print(f"✅ SOS Broadcast sent to {len(guardians)} guardians for user {user_id}")
            
        except Exception as e:
            print(f"❌ Error in SOS Broadcaster: {e}")
            
        await asyncio.sleep(300) # 5 minutes
