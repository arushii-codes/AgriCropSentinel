from pydantic import BaseModel
from typing import Optional


class ChatRequest(BaseModel):
    prompt: Optional[str] = None
    message: Optional[str] = None
    language: Optional[str] = "en"
    crop: Optional[str] = None
    disease: Optional[str] = None
    risk_level: Optional[str] = None
    weather_risk: Optional[float] = None


class DashboardResponse(BaseModel):
    name: str
    location: Optional[dict] = None
    weather: Optional[dict] = None
    news: Optional[list[dict]] = None
    market_prices: Optional[list[dict]] = None


class VoiceChatRequest(BaseModel):
    lang: Optional[str] = None