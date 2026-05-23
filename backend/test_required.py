from config import supabase
import uuid

def test_minimal_insert():
    print("--- Testing Minimal Insert to Find Required Columns ---")
    test_id = str(uuid.uuid4())
    try:
        # Try to insert only ID
        supabase.table('profiles').insert({'id': test_id}).execute()
        print("Success! Only 'id' is required.")
        # Cleanup
        supabase.table('profiles').delete().eq('id', test_id).execute()
    except Exception as e:
        print(f"Failed! Error: {str(e)}")
        # If it fails, try adding common columns one by one
        required_cols = []
        # This is a bit tedious, but let's try a more informative approach if the error message is clear.

test_minimal_insert()
