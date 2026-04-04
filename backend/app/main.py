from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.api.routes import router as api_router

app = FastAPI(
    title="Emergency Dispatch API",
    description="Backend for the Safecall SOS Application",
    version="1.0.0"
)

# Enable CORS for the Flutter application to communicate with the backend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, this should be restricted to specific domains/IPs
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include our API routes
app.include_router(api_router, prefix="/api/v1")

@app.get("/")
async def root():
    return {"message": "Emergency Dispatch API is running. Visit /docs for Swagger UI."}
