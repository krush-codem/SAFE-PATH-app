from config import supabase

print(f"Checking ALL profiles...")
res = supabase.table('profiles').select('*').execute()
print(f"Count: {len(res.data)}")
for p in res.data:
    print(f"Profile: {p.get('full_name')}, ID: {p['id']}")
