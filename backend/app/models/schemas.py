from pydantic import BaseModel
from typing import Optional, List, Dict, Any

class StatusUpdate(BaseModel):
    user_id: str
    latitude: float
    longitude: float
    status: str

class SosTrigger(BaseModel):
    user_id: str
    latitude: float
    longitude: float

class OtpRequest(BaseModel):
    user_id: str
    interval_mins: Optional[int] = 30

class OtpVerify(BaseModel):
    user_id: str
    journey_id: Optional[str] = None
    otp: str

class UserRequest(BaseModel):
    user_id: str

class SmsAlertRequest(BaseModel):
    user_id: str
    guardian_id: str
    message: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class VoiceAlertRequest(BaseModel):
    user_id: str
    guardian_id: str
    latitude: Optional[float] = None
    longitude: Optional[float] = None

class BulkAlertRequest(BaseModel):
    user_id: str
    message: Optional[str] = None
    latitude: Optional[float] = None
    longitude: Optional[float] = None
    alert_type: str = "sms"  # "sms", "voice", or "both"

class UrlScanRequest(BaseModel):
    url: str

class SecurityScanResponse(BaseModel):
    id: str
    status: str
    malicious: int
    suspicious: int
    undetected: int
    harmless: int
    total_engines: int
    link: Optional[str] = None

class ChatMessagePayload(BaseModel):
    receiver_id: str
    content: str
    sender_id: Optional[str] = None # Added by backend after auth
