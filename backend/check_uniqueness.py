from config import supabase

def check_uniqueness():
    print("--- Checking Uniqueness in Profiles ---")
    res = supabase.table('profiles').select('id, email, phone_number').execute()
    data = res.data
    
    emails = [r['email'] for r in data if r['email']]
    phones = [r['phone_number'] for r in data if r['phone_number']]
    
    print(f"Total rows: {len(data)}")
    print(f"Unique Emails: {len(set(emails))} / Total Emails: {len(emails)}")
    print(f"Unique Phones: {len(set(phones))} / Total Phones: {len(phones)}")
    
    # Check for empty strings vs None
    empty_emails = [r for r in data if r['email'] == '']
    empty_phones = [r for r in data if r['phone_number'] == '']
    null_phones = [r for r in data if r['phone_number'] is None]
    
    print(f"Empty string emails: {len(empty_emails)}")
    print(f"Empty string phones: {len(empty_phones)}")
    print(f"NULL phones: {len(null_phones)}")

check_uniqueness()
