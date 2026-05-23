from config import supabase

try:
    # Try to get one row to see the columns
    res = supabase.table('profiles').select('*').limit(1).execute()
    if res.data:
        print("Columns in 'profiles':", res.data[0].keys())
    else:
        # If no rows, try to select a non-existent column to see if it throws a specific error
        # or just print a message
        print("No data in 'profiles' to infer columns.")
        # Attempt to insert a dummy record and see the error
        dummy_res = supabase.table('profiles').insert({'id': '00000000-0000-0000-0000-000000000000'}).execute()
except Exception as e:
    print(f"Error: {e}")
