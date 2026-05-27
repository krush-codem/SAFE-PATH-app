from fastapi import Header, HTTPException, Depends
from typing import Optional
from app.config import supabase

def get_current_user(authorization: Optional[str] = Header(None)):
    """
    Verify the Supabase JWT and return the user object.
    Expects 'Authorization: Bearer <token>'
    """
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing or invalid authorization header")

    token = authorization.split(" ")[1]
    try:
        # get_user verifies the JWT with Supabase (blocking call)
        res = supabase.auth.get_user(token)
        if not res or not res.user:
            raise HTTPException(status_code=401, detail="Invalid or expired token")
        return res.user
    except Exception as e:
        print(f"JWT Verification Error: {e}")
        raise HTTPException(status_code=401, detail="Could not validate credentials")

def verify_user_id(user_id: str, current_user = Depends(get_current_user)):
    """
    Ensures the user_id in the request matches the authenticated user's ID.
    This prevents 'UUID Impersonation' loopholes.
    """
    if user_id != current_user.id:
        raise HTTPException(status_code=403, detail="Not authorized to perform action for this user")
    return user_id
