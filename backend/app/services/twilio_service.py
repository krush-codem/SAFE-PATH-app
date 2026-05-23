from typing import Optional
from twilio.rest import Client as TwilioClient
from app.config import TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER

# Initialize Twilio Client
twilio_client: Optional[TwilioClient] = None
if TWILIO_ACCOUNT_SID and TWILIO_AUTH_TOKEN:
    try:
        twilio_client = TwilioClient(TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN)
        print("✅ Twilio client initialized successfully")
    except Exception as e:
        print(f"⚠️ Failed to initialize Twilio client: {e}")

def send_sms_alert(to_phone: str, message: str) -> bool:
    """Send SMS alert using Twilio."""
    if not twilio_client or not TWILIO_PHONE_NUMBER:
        print(f"[TWILIO MOCK] SMS to {to_phone}: {message}")
        return False
    
    try:
        # Format phone number (ensure it has + prefix)
        if not to_phone.startswith('+'):
            to_phone = '+' + to_phone
        
        twilio_client.messages.create(
            body=message,
            from_=TWILIO_PHONE_NUMBER,
            to=to_phone
        )
        print(f"✅ SMS sent successfully to {to_phone}")
        return True
    except Exception as e:
        print(f"❌ Failed to send SMS to {to_phone}: {e}")
        return False

def send_voice_alert(to_phone: str, latitude: float, longitude: float) -> bool:
    """Send Voice call alert using Twilio with emergency message."""
    if not twilio_client or not TWILIO_PHONE_NUMBER:
        print(f"[TWILIO MOCK] Voice call to {to_phone}: Emergency Alert!")
        return True
    
    try:
        # Format phone number
        if not to_phone.startswith('+'):
            to_phone = '+' + to_phone
        
        location_url = f"https://www.google.com/maps?q={latitude},{longitude}"
        twiml = f"""<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say voice="alice" language="en-US">
        Emergency Alert from Safe Path. Your contact needs immediate help. 
        Their current location is at latitude {latitude}, longitude {longitude}.
        Please check your messages for the map link and respond immediately.
        This is an automated emergency call from the Safe Path safety app.
    </Say>
    <Pause length="2"/>
    <Say voice="alice" language="en-US">
        Location link: {location_url}
    </Say>
</Response>"""
        
        twilio_client.calls.create(
            twiml=twiml,
            from_=TWILIO_PHONE_NUMBER,
            to=to_phone
        )
        print(f"✅ Voice call initiated to {to_phone}")
        return True
    except Exception as e:
        print(f"❌ Failed to initiate voice call to {to_phone}: {e}")
        return False
