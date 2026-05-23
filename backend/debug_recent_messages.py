from config import supabase

print(f"Checking most recent messages...")
res = supabase.table('messages').select('*').order('created_at', desc=True).limit(10).execute()

for m in res.data:
    content = m['content'].encode('ascii', 'ignore').decode('ascii')
    print(f"ID: {m['id']}, From: {m['sender_id']}, To: {m['receiver_id']}, Content: {content[:50]}..., Created: {m['created_at']}")
