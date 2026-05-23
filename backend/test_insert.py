from config import supabase
client = supabase

uid = "de08f5af-e440-41f3-8c4a-df4405376ab5"
print("Attempting to manually insert into pending_profiles...")
try:
    res = client.table("pending_profiles").insert({
        "id": uid,
        "email": "",
        "phone_number": "918018104098",
        "full_name": ""
    }).execute()
    print("Success:", res.data)
except Exception as e:
    print("Error:", e)
    
print("Attempting to manually insert into profiles instead...")
try:
    res = client.table("profiles").insert({
        "id": uid,
        "email": "",
        "phone_number": "918018104098",
        "full_name": ""
    }).execute()
    print("Success profiles:", res.data)
except Exception as e:
    print("Error profiles:", e)
