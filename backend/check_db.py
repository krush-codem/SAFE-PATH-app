from config import supabase
client = supabase

print("Pending profiles:")
res1 = client.table("pending_profiles").select("*").execute()
print(res1.data)

print("Profiles:")
res2 = client.table("profiles").select("*").limit(5).execute()
print(res2.data)

# Let's inspect 'finalize_user_registration' manually if possible, though we can't easily read its source without direct pg connection.

# But we can get the guardians to see what's inserted:
print("Guardians:")
res3 = client.table("guardians").select("*").limit(5).execute()
print(res3.data)
