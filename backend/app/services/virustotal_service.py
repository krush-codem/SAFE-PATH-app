import base64
import httpx
import asyncio
from typing import Dict, Any
from fastapi import HTTPException
from app.config import VIRUSTOTAL_API_KEY, VIRUSTOTAL_BASE_URL

async def poll_virustotal_analysis(analysis_id: str) -> Dict[str, Any]:
    """Helper to poll VirusTotal for analysis completion."""
    headers = {
        "x-apikey": VIRUSTOTAL_API_KEY,
        "accept": "application/json"
    }
    
    async with httpx.AsyncClient() as client:
        for _ in range(20):
            await asyncio.sleep(3)
            try:
                response = await client.get(
                    f"{VIRUSTOTAL_BASE_URL}/analyses/{analysis_id}",
                    headers=headers
                )
                if response.status_code == 200:
                    data = response.json()
                    status = data["data"]["attributes"]["status"]
                    if status == "completed":
                        return data["data"]["attributes"]
                elif response.status_code == 429:
                    await asyncio.sleep(5)
            except Exception as e:
                print(f"Error polling analysis {analysis_id}: {e}")
        
    raise HTTPException(status_code=408, detail="Security scan timed out.")

async def scan_url(url: str):
    if not VIRUSTOTAL_API_KEY:
        raise HTTPException(status_code=503, detail="Security service not configured")

    headers = {
        "x-apikey": VIRUSTOTAL_API_KEY,
        "accept": "application/json"
    }

    async with httpx.AsyncClient() as client:
        url_id = base64.urlsafe_b64encode(url.encode()).decode().strip("=")
        
        try:
            report_res = await client.get(f"{VIRUSTOTAL_BASE_URL}/urls/{url_id}", headers=headers)
            if report_res.status_code == 200:
                stats = report_res.json()["data"]["attributes"]["last_analysis_stats"]
                return {
                    "id": url_id,
                    "status": "completed",
                    "malicious": stats.get("malicious", 0),
                    "suspicious": stats.get("suspicious", 0),
                    "undetected": stats.get("undetected", 0),
                    "harmless": stats.get("harmless", 0),
                    "total_engines": sum(stats.values()),
                    "link": f"https://www.virustotal.com/gui/url/{url_id}"
                }
        except Exception:
            pass

        submit_res = await client.post(
            f"{VIRUSTOTAL_BASE_URL}/urls",
            headers=headers,
            data={"url": url}
        )
        
        if submit_res.status_code != 200:
            raise HTTPException(status_code=submit_res.status_code, detail="VirusTotal Submission Failed")
        
        analysis_id = submit_res.json()["data"]["id"]
        results = await poll_virustotal_analysis(analysis_id)
        stats = results["stats"]
        
        return {
            "id": analysis_id,
            "status": "completed",
            "malicious": stats.get("malicious", 0),
            "suspicious": stats.get("suspicious", 0),
            "undetected": stats.get("undetected", 0),
            "harmless": stats.get("harmless", 0),
            "total_engines": sum(stats.values()),
            "link": f"https://www.virustotal.com/gui/url/{url_id}"
        }

async def scan_file(file_content: bytes, filename: str):
    if not VIRUSTOTAL_API_KEY:
        raise HTTPException(status_code=503, detail="Security service not configured")

    headers = {
        "x-apikey": VIRUSTOTAL_API_KEY,
        "accept": "application/json"
    }

    async with httpx.AsyncClient() as client:
        files = {"file": (filename, file_content)}
        submit_res = await client.post(
            f"{VIRUSTOTAL_BASE_URL}/files",
            headers=headers,
            files=files
        )
        
        if submit_res.status_code != 200:
            raise HTTPException(status_code=submit_res.status_code, detail="VirusTotal File Submission Failed")
        
        analysis_id = submit_res.json()["data"]["id"]
        results = await poll_virustotal_analysis(analysis_id)
        stats = results["stats"]
        
        return {
            "id": analysis_id,
            "status": "completed",
            "malicious": stats.get("malicious", 0),
            "suspicious": stats.get("suspicious", 0),
            "undetected": stats.get("undetected", 0),
            "harmless": stats.get("harmless", 0),
            "total_engines": sum(stats.values())
        }
