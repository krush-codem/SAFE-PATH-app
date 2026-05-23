from config import supabase

# System User ID
user_id = "ba7a1ae1-8b29-4256-a49e-6624d359d4b2"

def test_upsert():
    print(f"--- Testing Upsert for System User {user_id} ---")
    try:
        # Try to upsert with only ID and Email
        res = supabase.table('profiles').upsert({
            'id': user_id,
            'email': 'system@safepath.app'
        }).execute()
        print("Success! Upsert worked with minimal columns.")
    except Exception as e:
        print(f"Failed! Error: {str(e)}")

test_upsert()
