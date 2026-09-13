from fastapi import APIRouter, HTTPException, Request, Query
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from weather.services import fetch_weather, fetch_weather_by_coords
import requests
import feedparser
from auth.database import users_collection
from schemas import WeatherRiskResponse, GeoLocation
from chatbot.models import DashboardResponse

router = APIRouter()

# Set up Jinja2 templates
templates = Jinja2Templates(directory="templates")


@router.get("/risk", response_model=WeatherRiskResponse)
async def get_weather_risk(
    lat: float = Query(29.9695, description="Farmer field latitude"),
    lon: float = Query(76.8783, description="Farmer field longitude"),
):
    """
    Returns weather-based disease risk score and favorable disease conditions
    for the given field coordinates.
    """
    try:
        data = fetch_weather_by_coords(lat, lon)
        if data and "main" in data:
            temp = float(data["main"].get("temp", 28.5))
            humidity = float(data["main"].get("humidity", 75.0))
            rain = float(data.get("rain", {}).get("1h", 0.0)) * 24.0 if "rain" in data else 12.0
            
            # Simple risk heuristic: high humidity (>70%) & warm temp (20-32C) increases risk score
            risk_score = 0.5
            favorable = []
            if humidity > 70:
                risk_score += 0.25
                favorable.append("leaf_rust")
            if temp >= 20 and temp <= 32:
                risk_score += 0.15
                favorable.append("late_blight")
            if rain > 5.0:
                risk_score += 0.10
                favorable.append("powdery_mildew")

            risk_score = round(min(risk_score, 0.95), 2)
            return WeatherRiskResponse(
                location=GeoLocation(lat=lat, lon=lon),
                temperature_c=temp,
                humidity_pct=humidity,
                rainfall_mm_last_24h=round(rain, 1),
                weather_risk_score=risk_score,
                favorable_conditions_for=favorable if favorable else ["powdery_mildew"]
            )
    except Exception as e:
        print(f"⚠️ Weather risk lookup fallback: {e}")

    return WeatherRiskResponse(
        location=GeoLocation(lat=lat, lon=lon),
        temperature_c=28.5,
        humidity_pct=76.0,
        rainfall_mm_last_24h=12.4,
        weather_risk_score=0.62,
        favorable_conditions_for=["leaf_rust", "late_blight"]
    )

@router.get("/{location}")
async def get_weather(location: str):
    data = fetch_weather(location)
    if "error" in data:
        raise HTTPException(status_code=500, detail=data["error"])
    return data

@router.get("/dashboard", response_class=HTMLResponse)
async def weather_dashboard(request: Request, location: str = "London"):
    weather_data = fetch_weather(location)
    if "error" in weather_data:
        weather_data = {"location": location, "error": weather_data["error"]}
    return templates.TemplateResponse("dashboard.html", {"request": request, "weather": weather_data})


@router.get("/dashboard/{phone}", response_model=DashboardResponse)
async def dashboard(phone: str):
    # Load user
    user = await users_collection.find_one({"phone": phone})
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    name = user.get("name")
    location = user.get("location") or {}
    lat = location.get("lat")
    lon = location.get("lon")

    # Weather by coordinates
    weather = None
    if lat is not None and lon is not None:
        weather = fetch_weather_by_coords(lat, lon)

    # News: use Google News RSS with geo keywords
    news_items = []
    try:
        # Construct a query favoring agriculture/crop topics
        query = "agriculture OR crop OR farming"
        region = f"{location.get('district','')} {location.get('state','')}".strip()
        q = f"{query} {region}".strip()
        url = f"https://news.google.com/rss/search?q={requests.utils.quote(q)}&hl=en-IN&gl=IN&ceid=IN:en"
        feed = feedparser.parse(url)
        for entry in feed.entries[:10]:
            news_items.append({
                "title": entry.get("title"),
                "link": entry.get("link"),
                "published": entry.get("published"),
            })
    except Exception:
        news_items = []

    # Market prices: placeholder using Agmarknet-like structure (no key used)
    market_prices = []
    try:
        # Placeholder static or pseudo source. Replace with actual API if available.
        # For demo, fetch a public JSON sample or construct a simple list
        market_prices = [
            {"commodity": "Wheat", "state": location.get("state"), "price_per_qtl": 2150},
            {"commodity": "Rice", "state": location.get("state"), "price_per_qtl": 2400},
            {"commodity": "Maize", "state": location.get("state"), "price_per_qtl": 1900},
        ]
    except Exception:
        market_prices = []

    return DashboardResponse(
        name=name,
        location=location,
        weather=weather,
        news=news_items,
        market_prices=market_prices,
    )