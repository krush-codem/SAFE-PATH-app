from config import supabase
client = supabase

print("Fetching pending profiles...")
res = client.table("pending_profiles").select("*").execute()
for p in res.data:
    print(p)

print("\nFetching valid profiles...")
res2 = client.table("profiles").select("*").execute()
for p in res2.data:
    print(p['email'])
