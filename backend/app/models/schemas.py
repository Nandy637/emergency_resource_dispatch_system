from pydantic import BaseModel
from typing import List, Optional

class Location(BaseModel):
    latitude: float
    longitude: float

class SOSRequest(BaseModel):
    user_id: str
    location: Optional[Location] = None
    trigger_type: str = "button" # e.g., button, voice, shake

class Responder(BaseModel):
    id: str
    name: str
    type: str # e.g., Medical, Fire, Police
    eta: str
    distance: str
    status: str # e.g., En Route, Arrived

class IncidentResponse(BaseModel):
    incident_id: str
    status: str
    message: str

class TrackingResponse(BaseModel):
    incident_id: str
    responders: List[Responder]
    incident_status: str
