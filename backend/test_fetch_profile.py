from config import supabase

user_id = "b0f4d413-0178-4529-ac42-ce363922a4af"

def test_fetch():
    print(f"--- Testing fetch for user {user_id} ---")
    try:
        res = supabase.table('profiles').select('*').eq('id', user_id).maybe_single().execute()
        print(f"Success! Data: {res.data}")
    except Exception as e:
        print(f"Failed! Error: {str(e)}")
        import traceback
        traceback.print_exc()

test_fetch()
