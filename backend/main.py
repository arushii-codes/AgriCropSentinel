from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os

from auth.routes import router as auth_router
from chatbot.routes import router as chatbot_router
from weather.routes import router as weather_router
from image_analysis.routes import router as image_router
from micro_calculator.routes import router as micro_router
from news.routes import router as news_router
from fusion.fusion import router as fusion_router
from advisory.routes import router as advisory_router
from gis.routes import router as gis_router
from farmer.routes import router as farmer_router

# Ensure static directories exist
os.makedirs("uploadvoices", exist_ok=True)
os.makedirs("uploadimages", exist_ok=True)

app = FastAPI(title="AgriCropSentinel Unified AI Engine", version="2.0")

app.mount("/uploadvoices", StaticFiles(directory="uploadvoices"), name="uploadvoices")
app.mount("/uploadimages", StaticFiles(directory="uploadimages"), name="uploadimages")

# Add CORS middleware for Flutter frontend integration
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router, prefix="/auth", tags=["auth"])
app.include_router(chatbot_router, prefix="/chat", tags=["chat"])
app.include_router(weather_router, prefix="/weather", tags=["weather"])
app.include_router(image_router, prefix="/image-analysis", tags=["image-analysis"])
app.include_router(image_router, prefix="/vision", tags=["vision"])
app.include_router(micro_router, prefix="/micro-calculator", tags=["calculator"])
app.include_router(news_router, prefix="/news", tags=["news"])
app.include_router(fusion_router)
app.include_router(advisory_router, prefix="/advisory", tags=["advisory"])
app.include_router(gis_router, prefix="/gis", tags=["gis"])
app.include_router(farmer_router)

@app.get("/")
async def root():
    return {
        "app": "AgriCropSentinel Unified AI Engine",
        "status": "online",
        "features": [
            "CNN Crop Disease Detection (39 Classes)",
            "Integrated Pest Management (IPM)",
            "Multimodal Risk Fusion",
            "GIS Outbreak Intelligence & Spatial Clustering",
            "Human-in-the-Loop Expert Review Queue",
            "Gemini AI Farmer Voice Chatbot",
            "NPK Fertilizer Micronutrient Calculator",
            "Live Weather & Disease Risk Advisory"
        ]
    }


