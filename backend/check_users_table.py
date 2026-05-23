from config import supabase

try:
    res = supabase.table('users').select('*').limit(1).execute()
    print("Table 'users' exists!")
    print("Columns:", res.data[0].keys() if res.data else "No data")
except Exception as e:
    print(f"Table 'users' does not exist or error: {e}")
