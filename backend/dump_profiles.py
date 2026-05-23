from config import supabase
client = supabase

print("Fetching all profiles...")
res = client.table("profiles").select("id, full_name, email, phone_number").execute()
for p in res.data:
    print(p)
