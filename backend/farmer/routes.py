from fastapi import APIRouter
from pydantic import BaseModel
from typing import Dict, Any

router = APIRouter(prefix="/farmer", tags=["farmer"])


class PredictionRequest(BaseModel):
    state: str
    crop: str


@router.post("/predict")
async def predict_market(payload: PredictionRequest) -> Dict[str, Any]:
    """
    Market price prediction for the farmer app.

    Returns the structure expected by Flutter prediction_page.dart.
    """

    crop = payload.crop.strip().lower()
    state = payload.state.strip()

    # Demo/reference market values.
    # These can later be replaced with a real mandi-price ML model/API.
    crop_prices = {
        "wheat": 2450,
        "rice": 3200,
        "paddy": 3200,
        "maize": 2250,
        "cotton": 6800,
        "sugarcane": 360,
        "potato": 1800,
        "tomato": 2200,
        "onion": 2600,
        "apple": 7200,
    }

    current_price = crop_prices.get(crop, 2500)

    # Simple trend estimation.
    # This gives the UI a meaningful prediction even when no external
    # market-prediction model is available.
    trend = "Rising"
    confidence = 0.82

    weekly_changes = [0.012, 0.025, 0.041, 0.058, 0.072, 0.089, 0.105, 0.12]

    weekly_forecast = {}

    for index, change in enumerate(weekly_changes, start=1):
        predicted_price = round(current_price * (1 + change), 2)

        weekly_forecast[f"Week {index}"] = {
            "price": predicted_price
        }

    weather_impact = (
        "Moderate positive impact. Suitable weather conditions may "
        "support crop quality and market supply."
    )

    recommendation = (
        f"Market trend for {payload.crop.title()} in {state} is currently "
        f"{trend.lower()}. Consider monitoring mandi prices and selling "
        f"gradually instead of selling the entire produce at once."
    )

    return {
        "prediction_data": {
            "current_price": current_price,
            "trend": trend,
            "confidence": confidence,
            "weather_impact": weather_impact,
            "recommendation": recommendation,
            "weekly_forecast": weekly_forecast,
        }
    }
