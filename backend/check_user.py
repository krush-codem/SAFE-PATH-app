from config import supabase
client = supabase

uid = "de08f5af-e440-41f3-8c4a-df4405376ab5"
print(f"Profiles where id = {uid}:")
res = client.table("profiles").select("*").eq("id", uid).execute()
print(res.data)

print(f"Pending Profiles where id = {uid}:")
res = client.table("pending_profiles").select("*").eq("id", uid).execute()
print(res.data)
