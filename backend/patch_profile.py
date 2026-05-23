from config import supabase
client = supabase

uid = "de08f5af-e440-41f3-8c4a-df4405376ab5"
client.table("profiles").update({
    "full_name": "Alexander Vance (Dynamic)",
    "email": "alex.vance.dynamic@vigilant.sec"
}).eq("id", uid).execute()
print("Updated profile in DB!")
