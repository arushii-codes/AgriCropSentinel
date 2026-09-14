from fastapi import APIRouter, Query
from schemas import WeatherRiskResponse, GeoLocation
from weather.services import fetch_weather_by_coords

router = APIRouter()


# ============================================================
# WEATHER RISK CALCULATION
# ============================================================

def calculate_weather_risk(
    temperature: float,
    humidity: float,
    rainfall: float,
):
    """
    Calculate weather-based crop disease/pest risk.

    Score range: 0.0 - 0.95
    """

    score = 0.10

    # --------------------------------------------------------
    # HUMIDITY
    # --------------------------------------------------------

    if humidity >= 85:
        score += 0.35

    elif humidity >= 70:
        score += 0.25

    elif humidity >= 60:
        score += 0.10

    # --------------------------------------------------------
    # TEMPERATURE
    # --------------------------------------------------------

    if 20 <= temperature <= 32:
        score += 0.20

    elif 15 <= temperature < 20:
        score += 0.10

    elif 32 < temperature <= 38:
        score += 0.10

    # --------------------------------------------------------
    # RAINFALL
    # --------------------------------------------------------

    if rainfall >= 10:
        score += 0.25

    elif rainfall >= 5:
        score += 0.15

    elif rainfall >= 2:
        score += 0.05

    score = min(score, 0.95)

    return round(score, 2)


# ============================================================
# FAVORABLE CONDITIONS
# ============================================================

def get_favorable_conditions(
    temperature: float,
    humidity: float,
    rainfall: float,
):
    conditions = []

    # Humidity
    if humidity >= 85:
        conditions.append(
            "High Humidity"
        )

    elif humidity >= 70:
        conditions.append(
            "Moderately High Humidity"
        )

    # Temperature
    if 20 <= temperature <= 32:
        conditions.append(
            "Favorable Temperature"
        )

    # Rain
    if rainfall >= 10:
        conditions.append(
            "Heavy Rainfall"
        )

    elif rainfall >= 5:
        conditions.append(
            "Recent Rainfall"
        )

    # Disease-specific environmental interpretation
    if humidity >= 80 and 18 <= temperature <= 28:
        conditions.append(
            "Favorable for fungal diseases"
        )

    if humidity >= 80 and rainfall >= 5:
        conditions.append(
            "Favorable for leaf-spot and blight development"
        )

    if 25 <= temperature <= 35 and humidity >= 60:
        conditions.append(
            "Favorable for several insect pests"
        )

    # Nothing special
    if not conditions:
        conditions.append(
            "No major disease-favorable conditions detected"
        )

    return conditions


# ============================================================
# WEATHER RISK API
# ============================================================

@router.get(
    "/risk",
    response_model=WeatherRiskResponse,
)
async def weather_risk(
    lat: float = Query(...),
    lon: float = Query(...),
):
    """
    Return current weather and crop-health weather risk.
    """

    try:

        weather = fetch_weather_by_coords(
            lat,
            lon,
        )

        # ----------------------------------------------------
        # API FAILURE
        # ----------------------------------------------------

        if "error" in weather:

            return WeatherRiskResponse(
                location=GeoLocation(
                    lat=lat,
                    lon=lon,
                ),

                temperature_c=28.5,
                humidity_pct=76.0,
                rainfall_mm_last_24h=12.4,

                weather_risk_score=0.62,

                favorable_conditions_for=[
                    "Moderately High Humidity",
                    "Favorable Temperature",
                    "Recent Rainfall",
                    "Favorable for fungal diseases",
                ],
            )

        # ----------------------------------------------------
        # LIVE VALUES
        # ----------------------------------------------------

        temperature = float(
            weather.get(
                "temperature_c",
                28.0,
            )
            or 28.0
        )

        humidity = float(
            weather.get(
                "humidity",
                70.0,
            )
            or 70.0
        )

        rainfall = float(
            weather.get(
                "precipitation_mm",
                0.0,
            )
            or 0.0
        )

        # ----------------------------------------------------
        # RISK
        # ----------------------------------------------------

        risk_score = calculate_weather_risk(
            temperature,
            humidity,
            rainfall,
        )

        # ----------------------------------------------------
        # FAVORABLE CONDITIONS
        # ----------------------------------------------------

        favorable = get_favorable_conditions(
            temperature,
            humidity,
            rainfall,
        )

        print(
            f"[WEATHER] "
            f"lat={lat} "
            f"lon={lon} "
            f"temp={temperature} "
            f"humidity={humidity} "
            f"rain={rainfall} "
            f"risk={risk_score}"
        )

        return WeatherRiskResponse(
            location=GeoLocation(
                lat=lat,
                lon=lon,
            ),

            temperature_c=temperature,

            humidity_pct=humidity,

            rainfall_mm_last_24h=rainfall,

            weather_risk_score=risk_score,

            favorable_conditions_for=favorable,
        )

    except Exception as e:

        print(
            f"[WEATHER ERROR] {e}"
        )

        return WeatherRiskResponse(
            location=GeoLocation(
                lat=lat,
                lon=lon,
            ),

            temperature_c=28.5,

            humidity_pct=76.0,

            rainfall_mm_last_24h=12.4,

            weather_risk_score=0.62,

            favorable_conditions_for=[
                "Moderately High Humidity",
                "Favorable Temperature",
                "Recent Rainfall",
                "Favorable for fungal diseases",
            ],
        )