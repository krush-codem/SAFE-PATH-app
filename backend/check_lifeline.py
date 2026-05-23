from config import supabase
client = supabase

print("Fetching valid profiles...")
res = client.table("profiles").select("email, lifeline_setup_complete").execute()
for p in res.data:
    print(f"{p['email']} - Setup Complete: {p['lifeline_setup_complete']}")
