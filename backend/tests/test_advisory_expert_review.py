from fastapi.testclient import TestClient
from main import app

client = TestClient(app)


def test_advisory_high_confidence():
    payload = {
        "disease_or_pest_name": "Brown Planthopper",
        "risk_level": "high",
        "language": "en",
        "confidence": 0.88
    }

    response = client.post("/advisory/", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["under_expert_review"] is False
    assert len(data["ipm_steps"]) > 0


def test_advisory_low_confidence_review_queue():
    payload = {
        "disease_or_pest_name": "Rice Blast",
        "risk_level": "critical",
        "language": "en",
        "confidence": 0.45
    }

    response = client.post("/advisory/", json=payload)
    assert response.status_code == 200
    data = response.json()
    assert data["under_expert_review"] is True
    assert data["review_case_id"] is not None

    # Verify case is in pending queue
    pending_resp = client.get("/advisory/pending")
    assert pending_resp.status_code == 200
    pending_cases = pending_resp.json()["pending_cases"]
    assert any(c["case_id"] == data["review_case_id"] for c in pending_cases)

    # Resolve case via expert resolve API
    case_id = data["review_case_id"]
    resolve_resp = client.post("/advisory/resolve", json={
        "case_id": case_id,
        "decision": "approved",
        "expert_notes": "Confirmed by senior officer"
    })
    assert resolve_resp.status_code == 200
    assert resolve_resp.json()["case"]["status"] == "approved"


def test_gis_hotspots_endpoint():
    response = client.get("/gis/hotspots")
    assert response.status_code == 200
    data = response.json()
    assert "hotspots" in data
    assert len(data["hotspots"]) > 0
