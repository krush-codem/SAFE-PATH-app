from fastapi import APIRouter, BackgroundTasks, Depends
from app.models.schemas import SosTrigger, UserRequest
from app.services.alert_service import sos_broadcast_loop
from app.internal.state import active_sos_tasks
from app.dependencies import verify_user_id

router = APIRouter(prefix="/api/v1/sos", tags=["SOS"])

@router.post("/trigger")
def trigger_sos(payload: SosTrigger, background_tasks: BackgroundTasks, _ = Depends(verify_user_id)):
    user_id = payload.user_id
    if user_id in active_sos_tasks:
        return {"message": "SOS already active"}
    
    active_sos_tasks[user_id] = True
    background_tasks.add_task(sos_broadcast_loop, user_id, payload.latitude, payload.longitude)
    
    return {"success": True, "message": "SOS alert triggered and broadcasting."}

@router.post("/stop")
def stop_sos(payload: UserRequest, _ = Depends(verify_user_id)):
    user_id = payload.user_id
    try:
        if user_id in active_sos_tasks:
            del active_sos_tasks[user_id]
            return {"success": True, "message": "SOS deactivated."}
        return {"message": "No active SOS found for user."}
    except Exception as e:
        raise HTTPException(status_code=500, detail="Internal server error")
