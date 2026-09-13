from pydantic import BaseModel, Field
from typing import Optional
from enum import Enum


# ============================================================
# RISK LEVEL
# ============================================================

class RiskLevel(str, Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


# ============================================================
# GEO LOCATION
# ============================================================

class GeoLocation(BaseModel):
    lat: float
    lon: float


# ============================================================
# MODULE 1 — COMPUTER VISION RESPONSE
# ============================================================

class ImageUploadResponse(BaseModel):
    request_id: str
    crop_type: str
    disease_or_pest_name: str
    is_healthy: bool

    confidence: float = Field(
        ...,
        ge=0,
        le=1,
        description="Computer vision model confidence from 0 to 1"
    )

    severity: RiskLevel

    heatmap_url: Optional[str] = Field(
        None,
        description="Optional Grad-CAM or heatmap image URL for explainability"
    )


# ============================================================
# MODULE 2 — WEATHER RESPONSE
# ============================================================

class WeatherRiskResponse(BaseModel):
    location: GeoLocation

    temperature_c: float

    humidity_pct: float

    rainfall_mm_last_24h: float

    weather_risk_score: float = Field(
        ...,
        ge=0,
        le=1,
        description="Weather-based disease/pest risk from 0 to 1"
    )

    favorable_conditions_for: list[str] = Field(
        default_factory=list,
        description="Diseases or pests whose conditions are currently favorable"
    )


# ============================================================
# MODULE 3 — RISK FUSION REQUEST
# ============================================================

class RiskFusionRequest(BaseModel):
    cv_result: ImageUploadResponse

    weather_result: WeatherRiskResponse

    crop_growth_stage: str

    nearby_case_count_7d: int = Field(
        0,
        ge=0,
        description="Number of similar disease/pest reports nearby in the last 7 days"
    )


# ============================================================
# MODULE 3 — RISK FUSION RESPONSE
# ============================================================

class RiskFusionResponse(BaseModel):

    # Final multimodal risk score
    fused_risk_score: float = Field(
        ...,
        ge=0,
        le=1,
        description="Final multimodal risk score from 0 to 1"
    )

    # Overall risk category
    risk_level: RiskLevel

    # Severity detected by the computer vision module
    severity: RiskLevel

    # Estimated possibility of local spread
    spread_risk: float = Field(
        ...,
        ge=0,
        le=1,
        description="Estimated local spread risk from 0 to 1"
    )

    # Recommended response urgency
    urgency: str

    # Raw numerical factors used by the fusion engine
    explanation: dict[str, float] = Field(
        default_factory=dict,
        description="Numeric input factors used by the fusion engine"
    )

    # Human-readable explanation for the officer
    explanation_text: str = Field(
        ...,
        description="Human-readable explanation of why the risk received this score"
    )

    # Contribution of every modality to final score
    contributions: dict[str, float] = Field(
        default_factory=dict,
        description="Contribution of each factor to the final risk score"
    )


# ============================================================
# MODULE 5 — ADVISORY REQUEST
# ============================================================

class AdvisoryRequest(BaseModel):
    disease_or_pest_name: str

    risk_level: RiskLevel

    language: str = Field(
        "en",
        description="ISO language code, for example en, hi, mr"
    )

    confidence: Optional[float] = Field(
        None,
        ge=0,
        le=1,
        description="Model confidence 0-1, optional. If provided and below threshold, case is queued for expert review."
    )


# ============================================================
# MODULE 5 — ADVISORY RESPONSE
# ============================================================

class AdvisoryResponse(BaseModel):
    advisory_text: str

    ipm_steps: list[str]

    language: str

    expert_validated: bool

    under_expert_review: bool = False

    review_case_id: Optional[str] = None


# ============================================================
# MODULE 4 — GIS HOTSPOT
# ============================================================

class Hotspot(BaseModel):
    location: GeoLocation

    disease_or_pest_name: str

    severity: RiskLevel

    case_count: int


# ============================================================
# MODULE 4 — GIS HOTSPOT RESPONSE
# ============================================================

class GISHotspotResponse(BaseModel):
    hotspots: list[Hotspot]