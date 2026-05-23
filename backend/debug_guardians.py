from config import supabase

user_id = "9283f834-3820-4305-b336-3b8d94e223a0"

print(f"Checking guardians for user: {user_id}")
res = supabase.table('guardians').select('*').eq('user_id', user_id).execute()
print(f"All guardians for user: {res.data}")

res_active = supabase.table('guardians').select('*').eq('user_id', user_id).eq('is_active', True).execute()
print(f"Active guardians for user: {res_active.data}")
