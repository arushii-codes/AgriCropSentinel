from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def make_payload(
    confidence=0.95,
    severity="high",
    weather_risk=0.95,
    stage="flowering",
    nearby_cases=5,
):
    return {
        "cv_result": {
            "request_id": "test-request",
            "crop_type": "wheat",
            "disease_or_pest_name": "powdery_mildew",
            "is_healthy": False,
            "confidence": confidence,
            "severity": severity,
            "heatmap_url": None,
        },
        "weather_result": {
            "location": {
                "lat": 29.9695,
                "lon": 76.8783,
            },
            "temperature_c": 25,
            "humidity_pct": 90,
            "rainfall_mm_last_24h": 15,
            "weather_risk_score": weather_risk,
            "favorable_conditions_for": [
                "powdery_mildew"
            ],
        },
        "crop_growth_stage": stage,
        "nearby_case_count_7d": nearby_cases,
    }


def test_high_risk_case():
    response = client.post(
        "/fusion/risk",
        json=make_payload()
    )

    assert response.status_code == 200

    data = response.json()

    assert data["risk_level"] == "critical"
    assert data["fused_risk_score"] == 0.94
    assert data["severity"] == "high"
    assert data["urgency"] == "act immediately"


def test_low_risk_case():
    payload = make_payload(
        confidence=0.2,
        severity="low",
        weather_risk=0.1,
        stage="seedling",
        nearby_cases=0,
    )

    response = client.post(
        "/fusion/risk",
        json=payload
    )

    assert response.status_code == 200

    data = response.json()

    assert data["risk_level"] == "low"
    assert data["fused_risk_score"] == 0.13
    assert data["severity"] == "low"
    assert data["urgency"] == "monitor"


def test_unknown_disease_uses_fallback():
    payload = make_payload(
        confidence=0.75,
        severity="medium",
        weather_risk=0.60,
        stage="unknown_stage",
        nearby_cases=2,
    )

    payload["cv_result"]["disease_or_pest_name"] = "unknown_disease"

    response = client.post(
        "/fusion/risk",
        json=payload
    )

    assert response.status_code == 200

    data = response.json()

    assert data["risk_level"] == "medium"
    assert data["fused_risk_score"] == 0.54


def test_contributions_are_returned():
    response = client.post(
        "/fusion/risk",
        json=make_payload()
    )

    assert response.status_code == 200

    data = response.json()

    assert "contributions" in data

    assert "computer_vision" in data["contributions"]
    assert "weather" in data["contributions"]
    assert "crop_stage" in data["contributions"]
    assert "nearby_cases" in data["contributions"]
