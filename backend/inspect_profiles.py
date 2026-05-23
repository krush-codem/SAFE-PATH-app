from config import supabase

res = supabase.table('profiles').select('id, email, phone_number, full_name').execute()
for row in res.data:
    print(row)
