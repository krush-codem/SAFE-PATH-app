# In-memory state for active tasks and safety checks
# In production, this should be moved to Redis or a database

active_sos_tasks = {}
active_journey_loops = {}
pending_otps = {} # {user_id: {"otp": str, "expiry": datetime, "tries": int}}
system_user_id = "ba7a1ae1-8b29-4256-a49e-6624d359d4b2" # Default, will be updated on startup
