from fastapi import APIRouter, UploadFile, File, Depends
from app.models.schemas import UrlScanRequest, SecurityScanResponse
from app.services.virustotal_service import scan_url, scan_file
from app.dependencies import get_current_user

router = APIRouter(prefix="/api/v1/security", tags=["Security"])

@router.post("/scan-url", response_model=SecurityScanResponse)
async def scan_url_endpoint(payload: UrlScanRequest, _ = Depends(get_current_user)):
    results = await scan_url(payload.url)
    return results

@router.post("/scan-file", response_model=SecurityScanResponse)
async def scan_file_endpoint(file: UploadFile = File(...), _ = Depends(get_current_user)):
    content = await file.read()
    results = await scan_file(content, file.filename)
    return results
