from fastapi import APIRouter, HTTPException
from app.models.schemas import SOSRequest, IncidentResponse, TrackingResponse, Responder
import uuid

router = APIRouter()

# Mock database to store incidents for development
active_incidents = {}

@router.post("/sos", response_model=IncidentResponse)
async def trigger_sos(request: SOSRequest):
    # Generate a unique incident ID (e.g., EMG-A1B2C3D4)
    incident_id = f"EMG-{uuid.uuid4().hex[:8].upper()}"
    
    # Store the incident in our mock database
    active_incidents[incident_id] = {
        "status": "Active",
        "location": request.location.dict() if request.location else None,
        "responders": [
            Responder(id="R1", name="Ambulance Unit A12", type="Medical", eta="8 min", distance="3.2 km", status="En Route"),
            Responder(id="R2", name="Police Patrol P8", type="Police", eta="6 min", distance="2.4 km", status="En Route")
        ]
    }
    
    return IncidentResponse(
        incident_id=incident_id,
        status="Alert Sent",
        message="Emergency services have been notified."
    )

@router.get("/incident/{incident_id}/tracking", response_model=TrackingResponse)
async def get_tracking_info(incident_id: str):
    # Retrieve incident from mock database
    if incident_id not in active_incidents:
        raise HTTPException(status_code=404, detail="Incident not found")
        
    incident = active_incidents[incident_id]
    return TrackingResponse(
        incident_id=incident_id,
        responders=incident["responders"],
        incident_status=incident["status"]
    )
