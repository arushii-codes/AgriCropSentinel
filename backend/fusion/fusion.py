from fastapi import APIRouter, HTTPException

from schemas import RiskFusionRequest, RiskFusionResponse, RiskLevel


router = APIRouter(
    prefix="/fusion",
    tags=["Module 3 - Risk Fusion"],
)


# ============================================================
# FUSION WEIGHTS
# ============================================================

CV_WEIGHT = 0.35
WEATHER_WEIGHT = 0.25
STAGE_WEIGHT = 0.20
CASE_WEIGHT = 0.20


# ============================================================
# DISEASE + CROP STAGE SUSCEPTIBILITY
# ============================================================

DISEASE_STAGE_SUSCEPTIBILITY = {
    "powdery_mildew": {
        "seedling": 0.40,
        "vegetative": 0.60,
        "tillering": 0.65,
        "flowering": 0.85,
        "fruiting": 0.90,
        "maturity": 0.70,
    },
    "late_blight": {
        "seedling": 0.50,
        "vegetative": 0.70,
        "tillering": 0.75,
        "flowering": 0.80,
        "fruiting": 0.85,
        "maturity": 0.60,
    },
    "early_blight": {
        "seedling": 0.45,
        "vegetative": 0.65,
        "tillering": 0.70,
        "flowering": 0.75,
        "fruiting": 0.80,
        "maturity": 0.65,
    },
    "rice_blast": {
        "seedling": 0.60,
        "vegetative": 0.75,
        "tillering": 0.85,
        "booting": 0.90,
        "flowering": 0.80,
        "maturity": 0.50,
    },
    "brown_planthopper": {
        "seedling": 0.50,
        "vegetative": 0.80,
        "tillering": 0.85,
        "booting": 0.90,
        "flowering": 0.85,
        "maturity": 0.60,
    },
    "rice_brown_planthopper": {
        "seedling": 0.50,
        "vegetative": 0.80,
        "tillering": 0.85,
        "booting": 0.90,
        "flowering": 0.85,
        "maturity": 0.60,
    },
    "yellow_rust": {
        "seedling": 0.55,
        "vegetative": 0.75,
        "tillering": 0.80,
        "flowering": 0.85,
        "maturity": 0.65,
    },
    "leaf_rust": {
        "seedling": 0.50,
        "vegetative": 0.70,
        "tillering": 0.75,
        "flowering": 0.80,
        "maturity": 0.60,
    },
    "bacterial_blight": {
        "seedling": 0.65,
        "vegetative": 0.80,
        "tillering": 0.85,
        "flowering": 0.85,
        "maturity": 0.55,
    },
    "aphids": {
        "seedling": 0.70,
        "vegetative": 0.80,
        "tillering": 0.75,
        "flowering": 0.75,
        "fruiting": 0.70,
        "maturity": 0.50,
    },
}


# ============================================================
# HELPER 1 — CROP STAGE RISK
# ============================================================

def _get_stage_risk(
    disease_name: str,
    growth_stage: str,
) -> float:
    """
    Calculate susceptibility based on disease and crop stage.

    Returns a value between 0 and 1.
    """

    disease_key = disease_name.lower().strip()
    stage_key = growth_stage.lower().strip()

    disease_data = DISEASE_STAGE_SUSCEPTIBILITY.get(
        disease_key
    )

    if disease_data is None:
        return 0.50

    return disease_data.get(
        stage_key,
        0.50,
    )


# ============================================================
# HELPER 2 — SCORE TO RISK LEVEL
# ============================================================

def _score_to_level(
    score: float,
) -> RiskLevel:
    """
    Convert numerical risk score into a risk category.
    """

    if score < 0.30:
        return RiskLevel.LOW

    if score < 0.60:
        return RiskLevel.MEDIUM

    if score < 0.85:
        return RiskLevel.HIGH

    return RiskLevel.CRITICAL


# ============================================================
# HELPER 3 — IMAGE RELIABILITY
# ============================================================

def _calculate_reliability(
    image_confidence: float,
) -> float:
    """
    Estimate how strongly the CV prediction should influence
    the final multimodal risk score.
    """

    if image_confidence >= 0.80:
        return 1.00

    if image_confidence >= 0.60:
        return 0.80

    if image_confidence >= 0.40:
        return 0.60

    return 0.40


# ============================================================
# HELPER 4 — SPREAD RISK
# ============================================================

def _calculate_spread_risk(
    weather_risk: float,
    case_risk: float,
) -> float:
    """
    Estimate local disease/pest spread risk using weather
    and nearby reported cases.
    """

    spread_risk = (
        0.50 * weather_risk
        + 0.50 * case_risk
    )

    return round(
        spread_risk,
        2,
    )


# ============================================================
# HELPER 5 — URGENCY
# ============================================================

def _calculate_urgency(
    risk_level: RiskLevel,
) -> str:
    """
    Convert risk level into an action-oriented urgency message.
    """

    if risk_level == RiskLevel.LOW:
        return "monitor"

    if risk_level == RiskLevel.MEDIUM:
        return "monitor closely"

    if risk_level == RiskLevel.HIGH:
        return "act soon"

    return "act immediately"


# ============================================================
# HELPER 6 — HUMAN-READABLE EXPLANATION
# ============================================================

def _generate_explanation(
    risk_level: RiskLevel,
    image_risk: float,
    image_reliability: float,
    weather_risk: float,
    stage_risk: float,
    case_risk: float,
) -> str:
    """
    Generate a human-readable explanation for the final risk.
    """

    factors = []

    # --------------------------------------------------------
    # Computer Vision
    # --------------------------------------------------------

    if image_risk >= 0.80:

        factors.append(
            "the image model strongly indicates a disease or pest"
        )

    elif image_risk >= 0.60:

        factors.append(
            "the image model moderately indicates a disease or pest"
        )

    else:

        factors.append(
            "the image model has low confidence"
        )

    # --------------------------------------------------------
    # CV Reliability
    # --------------------------------------------------------

    if image_reliability < 0.60:

        factors.append(
            "the image prediction is given reduced influence because of low confidence"
        )

    # --------------------------------------------------------
    # Weather
    # --------------------------------------------------------

    if weather_risk >= 0.80:

        factors.append(
            "weather conditions are highly favorable"
        )

    elif weather_risk >= 0.50:

        factors.append(
            "weather conditions are moderately favorable"
        )

    else:

        factors.append(
            "weather conditions are not strongly favorable"
        )

    # --------------------------------------------------------
    # Crop Stage
    # --------------------------------------------------------

    if stage_risk >= 0.80:

        factors.append(
            "the current crop growth stage is highly susceptible"
        )

    elif stage_risk >= 0.50:

        factors.append(
            "the current crop growth stage has moderate susceptibility"
        )

    else:

        factors.append(
            "the current crop growth stage has low susceptibility"
        )

    # --------------------------------------------------------
    # Nearby Cases
    # --------------------------------------------------------

    if case_risk >= 0.80:

        factors.append(
            "many nearby cases indicate strong local outbreak activity"
        )

    elif case_risk >= 0.40:

        factors.append(
            "nearby cases indicate some local outbreak activity"
        )

    else:

        factors.append(
            "there is currently little nearby case evidence"
        )

    # --------------------------------------------------------
    # Final sentence
    # --------------------------------------------------------

    return (
        f"Overall risk is {risk_level.value}. "
        "The assessment is influenced by "
        + "; ".join(factors)
        + "."
    )


# ============================================================
# MAIN FUSION ENDPOINT
# ============================================================

@router.post(
    "/risk",
    response_model=RiskFusionResponse,
)
async def fuse_risk(
    payload: RiskFusionRequest,
):
    """
    Multimodal risk fusion.

    Inputs:
        - Computer Vision confidence
        - Weather risk
        - Crop growth stage
        - Nearby disease/pest cases

    Outputs:
        - Final fused risk score
        - Risk level
        - Severity
        - Spread risk
        - Urgency
        - Explainable contributions
        - Human-readable explanation
    """

    try:

        # ====================================================
        # STEP 1 — COMPUTER VISION RISK
        # ====================================================

        image_risk = payload.cv_result.confidence

        image_reliability = _calculate_reliability(
            image_risk
        )


        # ====================================================
        # STEP 2 — WEATHER RISK
        # ====================================================

        weather_risk = (
            payload.weather_result.weather_risk_score
        )


        # ====================================================
        # STEP 3 — CROP STAGE RISK
        # ====================================================

        stage_risk = _get_stage_risk(
            disease_name=(
                payload.cv_result.disease_or_pest_name
            ),
            growth_stage=(
                payload.crop_growth_stage
            ),
        )


        # ====================================================
        # STEP 4 — NEARBY CASE RISK
        # ====================================================

        nearby_cases = (
            payload.nearby_case_count_7d
        )

        # Prototype assumption:
        # 5 or more nearby cases = maximum risk.

        case_risk = min(
            nearby_cases / 5.0,
            1.0,
        )


        # ====================================================
        # STEP 5 — VALIDATE WEIGHTS
        # ====================================================

        total_weight = (
            CV_WEIGHT
            + WEATHER_WEIGHT
            + STAGE_WEIGHT
            + CASE_WEIGHT
        )

        if abs(total_weight - 1.0) > 0.001:

            raise ValueError(
                "Fusion weights must add up to 1.0"
            )


        # ====================================================
        # STEP 6 — APPLY CV RELIABILITY
        # ====================================================

        reliable_image_risk = (
            image_risk
            * image_reliability
        )


        # ====================================================
        # STEP 7 — CALCULATE FINAL FUSED RISK
        # ====================================================

        fused_score = (
            CV_WEIGHT * reliable_image_risk
            + WEATHER_WEIGHT * weather_risk
            + STAGE_WEIGHT * stage_risk
            + CASE_WEIGHT * case_risk
        )

        # Keep score within 0–1.

        fused_score = max(
            0.0,
            min(fused_score, 1.0),
        )

        fused_score = round(
            fused_score,
            2,
        )


        # ====================================================
        # STEP 8 — CALCULATE CONTRIBUTIONS
        # ====================================================

        cv_contribution = round(
            CV_WEIGHT * reliable_image_risk,
            3,
        )

        weather_contribution = round(
            WEATHER_WEIGHT * weather_risk,
            3,
        )

        stage_contribution = round(
            STAGE_WEIGHT * stage_risk,
            3,
        )

        case_contribution = round(
            CASE_WEIGHT * case_risk,
            3,
        )


        # ====================================================
        # STEP 9 — FINAL RISK LEVEL
        # ====================================================

        risk_level = _score_to_level(
            fused_score
        )


        # ====================================================
        # STEP 10 — SEVERITY
        # ====================================================

        # Severity comes from Module 1.
        #
        # IMPORTANT:
        # Confidence != severity.
        #
        # Confidence = how sure the AI model is.
        # Severity   = how badly the crop is affected.

        severity = payload.cv_result.severity


        # ====================================================
        # STEP 11 — SPREAD RISK
        # ====================================================

        spread_risk = _calculate_spread_risk(
            weather_risk=weather_risk,
            case_risk=case_risk,
        )


        # ====================================================
        # STEP 12 — URGENCY
        # ====================================================

        urgency = _calculate_urgency(
            risk_level
        )


        # ====================================================
        # STEP 13 — EXPLANATION TEXT
        # ====================================================

        explanation_text = _generate_explanation(
            risk_level=risk_level,
            image_risk=image_risk,
            image_reliability=image_reliability,
            weather_risk=weather_risk,
            stage_risk=stage_risk,
            case_risk=case_risk,
        )


        # ====================================================
        # STEP 14 — RETURN FINAL RESPONSE
        # ====================================================

        return RiskFusionResponse(

            fused_risk_score=fused_score,

            risk_level=risk_level,

            severity=severity,

            spread_risk=spread_risk,

            urgency=urgency,

            # Raw/normalized input factors
            explanation={
                "cv_confidence": image_risk,
                "image_reliability": image_reliability,
                "weather_risk": weather_risk,
                "stage_risk": stage_risk,
                "nearby_cases": nearby_cases,
                "case_risk": case_risk,
            },

            # Actual contribution to final score
            contributions={
                "computer_vision": cv_contribution,
                "weather": weather_contribution,
                "crop_stage": stage_contribution,
                "nearby_cases": case_contribution,
            },

            explanation_text=explanation_text,
        )


    except Exception as e:

        raise HTTPException(
            status_code=500,
            detail=f"Risk fusion failed: {str(e)}",
        )


def calculate_fusion_from_cv(confidence: float, disease_name: str, weather_risk: float = 0.60, growth_stage: str = "vegetative", nearby_cases: int = 0) -> dict:
    """
    Service helper to calculate risk fusion directly from Computer Vision analysis results
    and return a clean dict format for API responses.
    """
    from utils.cv_adapter import adapt_cv_result
    from schemas import WeatherRiskResponse, GeoLocation

    mock_cv = {
        "predicted_class": disease_name,
        "confidence": confidence,
        "severity": "high" if confidence > 0.8 else ("moderate" if confidence > 0.6 else "low")
    }
    cv_res = adapt_cv_result(mock_cv)
    weather_res = WeatherRiskResponse(
        location=GeoLocation(lat=29.0, lon=76.5),
        temperature_c=28.0,
        humidity_pct=75.0,
        rainfall_mm_last_24h=10.0,
        weather_risk_score=weather_risk,
        favorable_conditions_for=[disease_name]
    )
    req = RiskFusionRequest(
        cv_result=cv_res,
        weather_result=weather_res,
        crop_growth_stage=growth_stage,
        nearby_case_count_7d=nearby_cases
    )

    # Reuse fuse_risk logic directly
    import asyncio
    res = asyncio.run(fuse_risk(req)) if not asyncio.get_event_loop().is_running() else None
    
    # Compute using the exact helper functions without creating async loop conflicts
    image_reliability = _calculate_reliability(confidence)
    stage_risk = _get_stage_risk(disease_name, growth_stage)
    case_risk = min(nearby_cases / 5.0, 1.0)
    reliable_cv = confidence * image_reliability
    fused_score = round(max(0.0, min(CV_WEIGHT * reliable_cv + WEATHER_WEIGHT * weather_risk + STAGE_WEIGHT * stage_risk + CASE_WEIGHT * case_risk, 1.0)), 2)
    risk_level = _score_to_level(fused_score)
    spread_risk = _calculate_spread_risk(weather_risk, case_risk)
    urgency = _calculate_urgency(risk_level)
    explanation = _generate_explanation(risk_level, confidence, image_reliability, weather_risk, stage_risk, case_risk)

    return {
        "fused_risk_score": fused_score,
        "risk_level": risk_level.value,
        "urgency": urgency,
        "spread_risk": spread_risk,
        "explanation": explanation
    }