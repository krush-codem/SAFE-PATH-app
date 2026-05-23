from config import supabase

print(f"Checking ALL guardians...")
res = supabase.table('guardians').select('*').execute()
print(f"Count: {len(res.data)}")
for g in res.data:
    print(f"Guardian: {g.get('guardian_name', g.get('full_name', 'N/A'))}, UserID: {g['user_id']}")
