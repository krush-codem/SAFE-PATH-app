from config import supabase
client = supabase

uid = "de08f5af-e440-41f3-8c4a-df4405376ab5"
print("Checking auth.users:")
# Since supabase-py has limited admin API functionality, 
# we can just run the RPC to check or just dump users.
res = client.auth.admin.get_user_by_id(uid)
print(res)
