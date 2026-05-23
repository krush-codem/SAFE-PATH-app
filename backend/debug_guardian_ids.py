from config import supabase

print(f"Checking guardians with IDs for user f0704...")
res = supabase.table('guardians').select('id, guardian_name').eq('user_id', 'f0704d0f-b71a-47a1-a0ca-be0b6adc4026').execute()
for g in res.data:
    print(f"Guardian: {g['guardian_name']}, ID (PK): {g['id']}")
