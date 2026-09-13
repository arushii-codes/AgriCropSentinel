from uuid import uuid4
from schemas import ImageUploadResponse, RiskLevel


def adapt_cv_result(cv_result: dict) -> ImageUploadResponse:
    """
    Convert raw Computer Vision output into the standardized format
    expected by Risk Fusion (Module 3).
    """

    disease = cv_result.get("disease") or cv_result.get("predicted_class", "unknown_disease")
    confidence = cv_result.get("confidence", 0.85)
    severity = cv_result.get("severity", "medium")

    # Map raw severity string to RiskLevel Enum
    severity_mapping = {
        "low": RiskLevel.LOW,
        "moderate": RiskLevel.MEDIUM,
        "medium": RiskLevel.MEDIUM,
        "high": RiskLevel.HIGH,
        "critical": RiskLevel.CRITICAL,
        "none": RiskLevel.LOW,
    }

    normalized_severity = severity_mapping.get(
        str(severity).lower(),
        RiskLevel.MEDIUM,
    )

    is_healthy = "healthy" in disease.lower()

    # Extract crop type from disease label if available (e.g., "Tomato___Late_blight" -> "Tomato")
    if "___" in disease:
        crop_type = disease.split("___")[0]
    elif "_" in disease:
        crop_type = disease.split("_")[0].capitalize()
    else:
        crop_type = "Crop"

    return ImageUploadResponse(
        request_id=str(uuid4()),
        crop_type=crop_type,
        disease_or_pest_name=disease,
        is_healthy=is_healthy,
        confidence=confidence,
        severity=normalized_severity,
        heatmap_url=cv_result.get("heatmap_url", None),
    )
