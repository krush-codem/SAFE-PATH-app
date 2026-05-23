from config import supabase

# CURRENT USER ID from the error message
user_id = "f0704d0f-b71a-47a1-a0ca-be0b6adc4026"

print(f"--- SEEDING DATABASE FOR USER {user_id} ---")

# 1. Ensure Profile exists
try:
    print("Checking/Creating Profile...")
    res = supabase.table('profiles').select('*').eq('id', user_id).execute()
    if not res.data:
        supabase.table('profiles').insert({
            'id': user_id,
            'full_name': 'Test User',
            'phone_number': '+910000000000',
            'lifeline_setup_complete': True
        }).execute()
        print("Created Profile.")
    else:
        print("Profile already exists.")
except Exception as e:
    print(f"Profile Seed Error: {e}")

# 2. Add Guardians
try:
    print("Adding Guardians...")
    # First clear any existing to avoid duplicates in this script
    supabase.table('guardians').delete().eq('user_id', user_id).execute()
    
    guardians = [
        {'user_id': user_id, 'guardian_name': 'absd', 'guardian_phone': '+918987231312', 'is_active': True},
        {'user_id': user_id, 'guardian_name': 'ahre', 'guardian_phone': '+918081104098', 'is_active': True},
    ]
    
    supabase.table('guardians').insert(guardians).execute()
    print(f"Inserted {len(guardians)} guardians.")
except Exception as e:
    print(f"Guardian Seed Error: {e}")

print("--- SEEDING COMPLETE ---")
