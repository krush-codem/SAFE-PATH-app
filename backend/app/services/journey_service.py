import asyncio
import random
from datetime import datetime, timedelta
from app.config import supabase
from app.services.alert_service import sos_broadcast_loop
from app.internal.state import active_journey_loops, pending_otps, active_sos_tasks, system_user_id

async def otp_safety_loop(user_id: str, interval_mins: int):
    """Periodically checks user safety via OTP with escalation."""
    print(f"Starting safety loop for {user_id} every {interval_mins} mins")
    
    while user_id in active_journey_loops:
        # 1. Wait for the full interval
        await asyncio.sleep(interval_mins * 60)
        
        if user_id not in active_journey_loops: break

        # 2. Generate and Send OTP
        otp = "".join([str(random.randint(0, 9)) for _ in range(6)])
        pending_otps[user_id] = {
            "otp": otp, 
            "expiry": datetime.now() + timedelta(minutes=5), 
            "tries": 3
        }
        
        message = f"🔐 SAFETY CHECK: Your OTP is {otp}. Please enter it in the app within 5 minutes."
        
        try:
            supabase.table('messages').insert({
                'sender_id': system_user_id, 
                'receiver_id': user_id,
                'content': message,
                'is_read': False
            }).execute()
        except Exception as e:
            print(f"Error sending Safety OTP: {e}")

        # 3. Wait for 5 minutes for verification
        verified = False
        for _ in range(60): # 60 * 5s = 300s
            if user_id not in pending_otps:
                verified = True
                break
            await asyncio.sleep(5)

        if not verified:
            print(f"FAILED SAFETY CHECK for {user_id}. Escalating...")
            
            # --- REFINED ESCALATION LOGIC ---
            # 1. Send an urgent notification
            supabase.table('messages').insert({
                'sender_id': system_user_id, 
                'receiver_id': user_id,
                'content': "🚨 URGENT: Safety check missed! We are calling you now. If you don't respond, guardians will be alerted.",
                'is_read': False
            }).execute()
            
            # 2. Wait a bit more (e.g. 1 minute) for a last chance
            await asyncio.sleep(60)
            if user_id not in pending_otps: continue # They verified late but before SOS
            
            # 3. Trigger SOS
            if user_id not in active_sos_tasks:
                active_sos_tasks[user_id] = True
                profile = supabase.table('profiles').select('last_lat, last_lng').eq('id', user_id).execute()
                lat = profile.data[0].get('last_lat', 0.0) if profile.data else 0.0
                lng = profile.data[0].get('last_lng', 0.0) if profile.data else 0.0
                
                asyncio.create_task(sos_broadcast_loop(user_id, lat, lng))
            
            if user_id in active_journey_loops:
                del active_journey_loops[user_id]
            break
