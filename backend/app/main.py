import uuid
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import supabase, SYSTEM_USER_EMAIL
from app.internal import state
from app.routers import sos, journey, user, security, alerts

app = FastAPI(
    title="SafePath Secure Backend",
    description="Modularized and Secured FastAPI backend",
    version="2.0.0"
)

# --- Restricted CORS Configuration ---
# In production, replace ["*"] with your actual frontend domain
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.on_event("startup")
async def startup_event():
    """Ensure system user profile exists for automated messages."""
    try:
        res = supabase.table('profiles').select('id').eq('email', SYSTEM_USER_EMAIL).execute()
        if res.data:
            state.system_user_id = res.data[0]['id']
            print(f"✅ System User loaded: {state.system_user_id}")
        else:
            print("Creating System User...")
            new_user = supabase.auth.admin.create_user({
                "email": SYSTEM_USER_EMAIL,
                "password": f"SysPass_{uuid.uuid4().hex[:12]}!",
                "email_confirm": True,
                "user_metadata": {"full_name": "SafePath System"},
            })
            state.system_user_id = new_user.user.id
            print(f"✅ System User created: {state.system_user_id}")
    except Exception as e:
        print(f"⚠️ Startup warning: {e}")

# Include Routers
app.include_router(sos.router)
app.include_router(journey.router)
app.include_router(user.router)
app.include_router(security.router)
app.include_router(alerts.router)

@app.get("/")
def read_root():
    return {"status": "online", "message": "SafePath API is running securely"}

@app.get("/api/v1/twilio/status")
async def twilio_status():
    from app.services.twilio_service import twilio_client
    from app.config import TWILIO_PHONE_NUMBER
    return {
        "configured": twilio_client is not None,
        "phone_number": TWILIO_PHONE_NUMBER if TWILIO_PHONE_NUMBER else None,
        "message": "Ready" if twilio_client else "Mock Mode"
    }
