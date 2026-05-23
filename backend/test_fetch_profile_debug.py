from config import supabase

user_id = "b0f4d413-0178-4529-ac42-ce363922a4af"

def test_fetch():
    print(f"--- Testing fetch for user {user_id} ---")
    try:
        builder = supabase.table('profiles').select('*').eq('id', user_id).maybe_single()
        print(f"Builder: {builder}")
        res = builder.execute()
        print(f"Response: {res}")
        if res:
            print(f"Success! Data: {res.data}")
        else:
            print("Response is NONE!")
    except Exception as e:
        print(f"Failed! Error: {str(e)}")
        import traceback
        traceback.print_exc()

test_fetch()
