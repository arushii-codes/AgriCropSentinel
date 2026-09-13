from fastapi.testclient import TestClient
from main import app
from utils.cv_adapter import adapt_cv_result

client = TestClient(app)


def test_vision_weather_fusion_integration():
    # 1. Standardized Vision result
    vision_result = {
        "predicted_class": "rice_brown_planthopper",
        "confidence": 0.6759,
        "severity": "moderate",
    }

    # 2. Adapt Vision output to Module 3 format
    cv_result = adapt_cv_result(vision_result)

    # 3. Get Weather result
    weather_response = client.get(
        "/weather/risk",
        params={
            "lat": 29.9695,
            "lon": 76.8783,
        },
    )

    assert weather_response.status_code == 200
    weather_result = weather_response.json()

    # 4. Send everything to Risk Fusion
    fusion_payload = {
        "cv_result": cv_result.model_dump(),
        "weather_result": weather_result,
        "crop_growth_stage": "flowering",
        "nearby_case_count_7d": 2,
    }

    fusion_response = client.post(
        "/fusion/risk",
        json=fusion_payload,
    )

    assert fusion_response.status_code == 200
    result = fusion_response.json()

    # 5. Verify Module 3 produced expected fields
    assert "fused_risk_score" in result
    assert "risk_level" in result
    assert "severity" in result
    assert "spread_risk" in result
    assert "urgency" in result
    assert "explanation_text" in result
    assert "contributions" in result

    assert 0 <= result["fused_risk_score"] <= 1
    assert 0 <= result["spread_risk"] <= 1
