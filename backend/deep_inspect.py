from config import supabase
import json

def get_minute_details():
    tables = ['profiles', 'guardians', 'journeys', 'messages']
    details = {}

    for table in tables:
        print(f"--- Analyzing table: {table} ---")
        try:
            # Query information_schema for column details
            # Note: This might fail if the API doesn't expose information_schema, 
            # but in many Supabase setups, the service_role key can access it if the API is configured to allow it.
            # However, PostgREST usually doesn't expose information_schema by default.
            # We'll try a different approach: querying the table and inspecting a row, 
            # and then trying to infer nullability by attempting inserts.
            
            # 1. Get sample row
            res = supabase.table(table).select('*').limit(1).execute()
            sample = res.data[0] if res.data else None
            
            # 2. Get columns (we already have this for profiles, but let's do all)
            if sample:
                details[table] = {
                    'columns': list(sample.keys()),
                    'sample_data': sample
                }
            else:
                details[table] = {'columns': 'No data found'}

            # 3. Check for unique constraints or indexes via error messages
            # We'll try to insert a duplicate of the sample if it exists
            if sample and 'id' in sample:
                try:
                    # Attempt a duplicate insert to see the error message (contains constraint name)
                    supabase.table(table).insert(sample).execute()
                except Exception as e:
                    print(f"Constraint info for {table}: {str(e)}")

        except Exception as e:
            print(f"Error analyzing {table}: {e}")

    # Special check: try to query information_schema directly
    # This is speculative but highly valuable if it works.
    try:
        rpc_res = supabase.rpc('get_table_info', {'t_name': 'profiles'}).execute()
        print("RPC get_table_info success:", rpc_res.data)
    except:
        print("RPC get_table_info not available.")

get_minute_details()
