from config import supabase

# System User ID
user_id = "ba7a1ae1-8b29-4256-a49e-6624d359d4b2"

def test_upsert_no_email():
    print(f"--- Testing Upsert (No Email) for System User {user_id} ---")
    try:
        res = supabase.table('profiles').upsert({
            'id': user_id,
            'full_name': 'SafePath System'
        }).execute()
        print("Success! Email is not required.")
    except Exception as e:
        print(f"Failed! Email might be required. Error: {str(e)}")

test_upsert_no_email()
