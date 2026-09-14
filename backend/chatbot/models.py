from pydantic import BaseModel
from typing import Optional


class ChatRequest(BaseModel):
    prompt: str


class DashboardResponse(BaseModel):
    name: str
    location: Optional[dict] = None
    weather: Optional[dict] = None
    news: Optional[list[dict]] = None
    market_prices: Optional[list[dict]] = None


class VoiceChatRequest(BaseModel):
    lang: Optional[str] = None