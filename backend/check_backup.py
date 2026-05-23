from config import supabase
client = supabase

try:
    print("Testing select from pg_tables:")
    res = client.table("pg_tables").select("*").execute()
    print("Data:", res.data[:5])
except Exception as e:
    print("Error pg_tables:", e)

try:
    print("Testing select from pg_proc:")
    res2 = client.table("pg_proc").select("*").execute()
    print("Data:", res2.data[:5])
except Exception as e:
    print("Error pg_proc:", e)
