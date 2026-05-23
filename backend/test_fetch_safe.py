from config import supabase

user_id = "b0f4d413-0178-4529-ac42-ce363922a4af"

def test_fetch_safe():
    print(f"--- Testing safe fetch for user {user_id} ---")
    try:
        res = supabase.table('profiles').select('*').eq('id', user_id).execute()
        print(f"Response type: {type(res)}")
        print(f"Data: {res.data}")
        if res.data:
            print(f"Found! {res.data[0]}")
        else:
            print("Not found (safely)")
    except Exception as e:
        print(f"Failed! Error: {str(e)}")
        import traceback
        traceback.print_exc()

test_fetch_safe()
