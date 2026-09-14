from fastapi import (
    APIRouter,
    HTTPException,
    Request,
    UploadFile,
    File,
    Query,
)
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates

from auth.database import db

import traceback
import datetime
import shutil
import uuid
import time
import asyncio
import os

from image_analysis.prediction import model_predict
from image_analysis.voice_helper import (
    generate_voice,
    clean_label_for_voice,
)

from chatbot.app import get_gemini_response

from ipm.lookup import (
    load_knowledge_base,
    get_advisory,
)

from ipm.review_queue import (
    needs_review,
    add_case,
)

from schemas import ImageUploadResponse

from utils.cv_adapter import adapt_cv_result

# ============================================================
# MODULE 3 - MULTIMODAL RISK FUSION
# ============================================================

from fusion.fusion import calculate_fusion_from_cv

# ============================================================
# LIVE WEATHER
# ============================================================

from weather.services import fetch_weather_by_coords


# ============================================================
# CONFIGURATION
# ============================================================

UPLOAD_DIR = "uploadimages"

os.makedirs(
    UPLOAD_DIR,
    exist_ok=True
)

router = APIRouter()

templates = Jinja2Templates(
    directory="templates"
)


# ============================================================
# HELPERS
# ============================================================

def normalize_disease_name(
    disease_name: str
) -> str:
    """
    Converts model labels into simplified disease names
    that Module 3 can understand.

    Example:
        Tomato_Late_blight
        ->
        late_blight
    """

    if not disease_name:
        return ""

    name = disease_name.lower().strip()

    # --------------------------------------------------------
    # Remove crop prefixes
    # --------------------------------------------------------

    prefixes = [
        "tomato_",
        "tomato___",
        "potato_",
        "potato___",
        "apple_",
        "apple___",
        "grape_",
        "grape___",
        "corn_",
        "corn___",
        "peach_",
        "peach___",
        "pepper_",
        "pepper,_bell_",
        "cherry_",
        "cherry___",
        "strawberry_",
        "strawberry___",
        "squash_",
        "squash___",
    ]

    for prefix in prefixes:

        if name.startswith(prefix):

            name = name[len(prefix):]

            break

    # --------------------------------------------------------
    # Normalize separators
    # --------------------------------------------------------

    name = name.replace(
        " ",
        "_"
    )

    name = name.replace(
        "-",
        "_"
    )

    name = name.replace(
        "(",
        ""
    )

    name = name.replace(
        ")",
        ""
    )

    # --------------------------------------------------------
    # Common disease mappings
    # --------------------------------------------------------

    mappings = {

        "late_blight":
            "late_blight",

        "early_blight":
            "early_blight",

        "powdery_mildew":
            "powdery_mildew",

        "leaf_mold":
            "leaf_mold",

        "septoria_leaf_spot":
            "septoria_leaf_spot",

        "bacterial_spot":
            "bacterial_spot",

        "target_spot":
            "target_spot",

        "spider_mites_two_spotted_spider_mite":
            "spider_mites",

        "tomato_yellow_leaf_curl_virus":
            "yellow_leaf_curl_virus",

        "tomato_mosaic_virus":
            "tomato_mosaic_virus",

        "black_rot":
            "black_rot",

        "cedar_apple_rust":
            "cedar_apple_rust",

        "apple_scab":
            "apple_scab",

        "leaf_blight_isariopsis_leaf_spot":
            "leaf_blight",

        "esca_black_measles":
            "esca",

        "cercospora_leaf_spot_gray_leaf_spot":
            "cercospora_leaf_spot",

        "common_rust":
            "common_rust",

        "northern_leaf_blight":
            "northern_leaf_blight",

        "haunglongbing_citrus_greening":
            "citrus_greening",

        "bacterial_spot":
            "bacterial_spot",

    }

    return mappings.get(
        name,
        name
    )


def calculate_live_weather_risk(
    weather_data: dict
) -> float:
    """
    Calculates weather risk from live Open-Meteo data.

    Inputs:
        temperature
        humidity
        precipitation

    Output:
        score between 0 and 0.95
    """

    temperature = float(
        weather_data.get(
            "temperature_c",
            28.0
        )
        or 28.0
    )

    humidity = float(
        weather_data.get(
            "humidity",
            70.0
        )
        or 70.0
    )

    rainfall = float(
        weather_data.get(
            "precipitation_mm",
            0.0
        )
        or 0.0
    )

    # --------------------------------------------------------
    # Base risk
    # --------------------------------------------------------

    risk_score = 0.10

    # --------------------------------------------------------
    # Humidity
    # --------------------------------------------------------

    if humidity >= 85:

        risk_score += 0.35

    elif humidity >= 70:

        risk_score += 0.25

    # --------------------------------------------------------
    # Temperature
    # --------------------------------------------------------

    if 20 <= temperature <= 32:

        risk_score += 0.20

    # --------------------------------------------------------
    # Rainfall
    # --------------------------------------------------------

    if rainfall >= 10:

        risk_score += 0.25

    elif rainfall >= 5:

        risk_score += 0.15

    # --------------------------------------------------------
    # Clamp
    # --------------------------------------------------------

    return round(
        min(
            risk_score,
            0.95
        ),
        2
    )


async def get_live_weather_risk(
    lat: float,
    lon: float
) -> float:
    """
    Fetches live weather and converts it into
    a weather-risk score.

    Uses Open-Meteo through weather.services.
    """

    try:

        weather_data = await asyncio.to_thread(
            fetch_weather_by_coords,
            lat,
            lon
        )

        if (
            not weather_data
            or "error" in weather_data
        ):

            print(
                "[ANALYZE WEATHER] "
                "Weather API returned an error."
            )

            return 0.62

        temperature = float(
            weather_data.get(
                "temperature_c",
                28.0
            )
            or 28.0
        )

        humidity = float(
            weather_data.get(
                "humidity",
                70.0
            )
            or 70.0
        )

        rainfall = float(
            weather_data.get(
                "precipitation_mm",
                0.0
            )
            or 0.0
        )

        weather_risk = calculate_live_weather_risk(
            weather_data
        )

        print(
            f"[ANALYZE WEATHER] "
            f"temp={temperature}C "
            f"humidity={humidity}% "
            f"rain={rainfall}mm "
            f"risk={weather_risk}"
        )

        return weather_risk

    except Exception as e:

        print(
            f"[ANALYZE WEATHER ERROR] {e}"
        )

        return 0.62


def build_weather_summary(
    weather_risk: float
) -> str:
    """
    Human-readable weather risk summary.
    """

    if weather_risk >= 0.85:

        return (
            "Weather conditions are highly favorable "
            "for disease or pest development."
        )

    if weather_risk >= 0.60:

        return (
            "Weather conditions are moderately favorable "
            "for disease or pest development."
        )

    if weather_risk >= 0.40:

        return (
            "Weather conditions present some disease risk."
        )

    return (
        "Current weather conditions show relatively "
        "low disease risk."
    )


# ============================================================
# IMAGE ANALYSIS
# ============================================================

@router.post(
    "/analyze"
)
async def analyze_image_endpoint(
    file: UploadFile = File(...),

    lang: str = Query(
        "en",
        description="Language: en, hi, hinglish, pa"
    ),

    growth_stage: str = Query(
        "vegetative",
        description="Crop growth stage"
    ),

    weather_risk: float | None = Query(
        None,
        ge=0.0,
        le=1.0,
        description=(
            "Optional weather risk score. "
            "If omitted, live weather is used."
        )
    ),

    nearby_cases: int = Query(
        0,
        ge=0,
        description=(
            "Nearby disease/pest cases "
            "in the last 7 days"
        )
    ),

    lat: float = Query(
        29.9695,
        description="Field latitude"
    ),

    lon: float = Query(
        76.8783,
        description="Field longitude"
    ),

    voice: bool = Query(
        False
    )
):

    request_id = str(
        uuid.uuid4()
    )

    start_time = time.time()

    image_path = None

    try:

        # ====================================================
        # STEP 1 - VALIDATE FILE
        # ====================================================

        if not file:

            raise HTTPException(
                status_code=400,
                detail="No image file provided."
            )

        allowed_extensions = {
            ".jpg",
            ".jpeg",
            ".png",
            ".webp"
        }

        original_name = (
            file.filename
            or "uploaded_image.jpg"
        )

        extension = os.path.splitext(
            original_name
        )[1].lower()

        if extension not in allowed_extensions:

            raise HTTPException(
                status_code=400,
                detail=(
                    "Unsupported image format. "
                    "Use JPG, JPEG, PNG or WEBP."
                )
            )

        # ====================================================
        # STEP 2 - SAVE IMAGE
        # ====================================================

        safe_filename = (
            f"{request_id}"
            f"{extension}"
        )

        image_path = os.path.join(
            UPLOAD_DIR,
            safe_filename
        )

        with open(
            image_path,
            "wb"
        ) as buffer:

            shutil.copyfileobj(
                file.file,
                buffer
            )

        print(
            f"[ANALYZE] "
            f"Image saved: {image_path}"
        )

        # ====================================================
        # STEP 3 - AI DISEASE PREDICTION
        # ====================================================

        analysis_result = await asyncio.to_thread(
            model_predict,
            image_path
        )

        if not analysis_result:

            raise HTTPException(
                status_code=500,
                detail="AI prediction failed."
            )

        predicted_class = analysis_result.get(
            "predicted_class",
            "Unknown"
        )

        confidence = float(
            analysis_result.get(
                "confidence",
                0.0
            )
            or 0.0
        )

        print(
            f"[VISION] "
            f"disease={predicted_class} "
            f"confidence={confidence:.4f}"
        )

        # ====================================================
        # STEP 4 - NORMALIZE DISEASE NAME
        # ====================================================

        fusion_disease_name = normalize_disease_name(
            predicted_class
        )

        print(
            f"[FUSION] "
            f"normalized disease="
            f"{fusion_disease_name}"
        )

        # ====================================================
        # STEP 5 - LIVE WEATHER
        # ====================================================

        if weather_risk is None:

            weather_risk = await get_live_weather_risk(
                lat,
                lon
            )

        else:

            weather_risk = round(
                float(weather_risk),
                2
            )

            print(
                f"[ANALYZE WEATHER] "
                f"Using supplied weather risk="
                f"{weather_risk}"
            )

        weather_summary = build_weather_summary(
            weather_risk
        )

        # ====================================================
        # STEP 6 - MODULE 3 RISK FUSION
        # ====================================================

        risk_fusion = calculate_fusion_from_cv(

            confidence=confidence,

            disease_name=fusion_disease_name,

            weather_risk=weather_risk,

            growth_stage=growth_stage,

            nearby_cases=nearby_cases
        )

        print(
            "[FUSION RESULT] "
            f"score="
            f"{risk_fusion.get('fused_risk_score')} "
            f"level="
            f"{risk_fusion.get('risk_level')} "
            f"severity="
            f"{risk_fusion.get('severity')}"
        )

        # ====================================================
        # STEP 7 - ADAPT CV RESULT
        # ====================================================

        try:

            adapted_cv = adapt_cv_result(
                analysis_result
            )

        except Exception as e:

            print(
                f"[CV ADAPTER WARNING] {e}"
            )

            adapted_cv = analysis_result

        # ====================================================
        # STEP 8 - IPM ADVISORY
        # ====================================================

        ipm_advisory = None

        try:

            # Load knowledge base
            knowledge_base = load_knowledge_base()

            ipm_advisory = get_advisory(
                disease_name=fusion_disease_name,
                risk_level=risk_fusion.get(
                    "risk_level",
                    "medium"
                ),
                language=lang
            )

        except TypeError:

            # Compatibility fallback for older
            # get_advisory() signatures.

            try:

                ipm_advisory = get_advisory(
                    fusion_disease_name
                )

            except Exception as advisory_error:

                print(
                    f"[IPM WARNING] "
                    f"{advisory_error}"
                )

        except Exception as e:

            print(
                f"[IPM WARNING] {e}"
            )

        # ====================================================
        # STEP 9 - LOW CONFIDENCE REVIEW QUEUE
        # ====================================================

        review_required = False

        try:

            review_required = needs_review(
                confidence
            )

        except Exception as e:

            print(
                f"[REVIEW WARNING] {e}"
            )

        if review_required:

            try:

                add_case(
                    image_path=image_path,
                    predicted_class=predicted_class,
                    confidence=confidence,
                    request_id=request_id
                )

                print(
                    "[REVIEW] "
                    "Case added to expert review queue."
                )

            except Exception as e:

                print(
                    f"[REVIEW QUEUE WARNING] {e}"
                )

        # ====================================================
        # STEP 10 - GEMINI EXPLANATION
        # ====================================================

        summary_text = ""

        try:

            prompt = f"""
You are an agricultural crop-health assistant.

Disease/Pest detected:
{predicted_class}

AI confidence:
{confidence:.2f}

Overall fused crop-health risk:
{risk_fusion.get("risk_level", "medium")}

Fused risk score:
{risk_fusion.get("fused_risk_score", 0)}

Weather risk:
{weather_risk}

Growth stage:
{growth_stage}

Nearby cases in last 7 days:
{nearby_cases}

Weather interpretation:
{weather_summary}

Explain the result for a farmer in simple language.

Mention:
1. What was detected.
2. Why the risk level was assigned.
3. How weather contributes.
4. What the farmer should do next.

Do not claim certainty.
Do not say that the crop is definitely destroyed.
Give practical and safe agricultural guidance.

Language:
{lang}
"""

            gemini_response = await asyncio.to_thread(
                get_gemini_response,
                prompt
            )

            if gemini_response:

                summary_text = str(
                    gemini_response
                )

        except Exception as e:

            print(
                f"[GEMINI WARNING] {e}"
            )

            summary_text = (
                f"{predicted_class} detected with "
                f"{confidence * 100:.1f}% AI confidence. "
                f"{weather_summary}"
            )

        # ====================================================
        # STEP 11 - DETAILED INFORMATION
        # ====================================================

        detailed_info = {

            "predicted_class":
                predicted_class,

            "normalized_disease":
                fusion_disease_name,

            "confidence":
                round(
                    confidence,
                    4
                ),

            "weather_risk":
                weather_risk,

            "growth_stage":
                growth_stage,

            "nearby_cases":
                nearby_cases,

            "weather_summary":
                weather_summary,

            "review_required":
                review_required,

            "processing_time_seconds":
                round(
                    time.time() - start_time,
                    3
                ),
        }

        # ====================================================
        # STEP 12 - OPTIONAL VOICE
        # ====================================================

        voice_url = None

        if voice:

            try:

                voice_label = clean_label_for_voice(
                    predicted_class
                )

                voice_text = (
                    f"{voice_label}. "
                    f"Risk level is "
                    f"{risk_fusion.get('risk_level', 'medium')}. "
                    f"{weather_summary}"
                )

                voice_file = await asyncio.to_thread(
                    generate_voice,
                    voice_text,
                    lang
                )

                if voice_file:

                    voice_url = voice_file

            except Exception as e:

                print(
                    f"[VOICE WARNING] {e}"
                )

        # ====================================================
        # STEP 13 - DATABASE RECORD
        # ====================================================

        analysis_data = {

            "request_id":
                request_id,

            "filename":
                safe_filename,

            "original_filename":
                original_name,

            "analysis_result":
                analysis_result,

            "predicted_class":
                predicted_class,

            "confidence":
                confidence,

            "risk_fusion":
                risk_fusion,

            "fusion_inputs": {

                "weather_risk":
                    weather_risk,

                "growth_stage":
                    growth_stage,

                "nearby_cases":
                    nearby_cases,

                "latitude":
                    lat,

                "longitude":
                    lon,
            },

            "ipm_advisory":
                ipm_advisory,

            "language":
                lang,

            "review_required":
                review_required,

            "timestamp":
                datetime.datetime.utcnow(),
        }

        try:

            if db is not None:

                await db.image_analyses.insert_one(
                    analysis_data
                )

                print(
                    "[DATABASE] "
                    "Analysis saved successfully."
                )

        except Exception as e:

            print(
                f"[DATABASE WARNING] {e}"
            )

        # ====================================================
        # STEP 14 - RESPONSE
        # ====================================================

        processing_time = round(
            time.time() - start_time,
            3
        )

        return {

            "request_id":
                request_id,

            "filename":
                safe_filename,

            "image_url":
                f"/image-analysis/image/{safe_filename}",

            "analysis_result":
                analysis_result,

            "adapted_cv_result":
                adapted_cv,

            "risk_fusion":
                risk_fusion,

            "weather": {

                "latitude":
                    lat,

                "longitude":
                    lon,

                "weather_risk":
                    weather_risk,

                "summary":
                    weather_summary,
            },

            "ipm_advisory":
                ipm_advisory,

            "summary_text":
                summary_text,

            "detailed_info":
                detailed_info,

            "voice_url":
                voice_url,

            "review_required":
                review_required,

            "processing_time_seconds":
                processing_time,

            "timestamp":
                datetime.datetime.utcnow().isoformat(),
        }

    # ========================================================
    # HTTP ERRORS
    # ========================================================

    except HTTPException:

        raise

    # ========================================================
    # GENERAL ERRORS
    # ========================================================

    except Exception as e:

        print(
            "\n========== IMAGE ANALYSIS ERROR =========="
        )

        print(
            str(e)
        )

        traceback.print_exc()

        print(
            "==========================================\n"
        )

        raise HTTPException(
            status_code=500,
            detail=(
                f"Internal server error: {str(e)}"
            )
        )


# ============================================================
# IMAGE SERVING
# ============================================================

@router.get(
    "/image/{filename}"
)
async def get_uploaded_image(
    filename: str
):

    file_path = os.path.join(
        UPLOAD_DIR,
        filename
    )

    if not os.path.exists(
        file_path
    ):

        raise HTTPException(
            status_code=404,
            detail="Image not found."
        )

    from fastapi.responses import FileResponse

    return FileResponse(
        file_path
    )


# ============================================================
# DASHBOARD
# ============================================================

@router.get(
    "/dashboard",
    response_class=HTMLResponse
)
async def image_dashboard(
    request: Request
):

    analyses = []

    try:

        if db is not None:

            cursor = (
                db.image_analyses
                .find({})
                .sort(
                    "timestamp",
                    -1
                )
                .limit(50)
            )

            analyses = await cursor.to_list(
                length=50
            )

    except Exception as e:

        print(
            f"[DASHBOARD WARNING] {e}"
        )

    return templates.TemplateResponse(
        "dashboard.html",
        {
            "request": request,
            "analyses": analyses,
        }
    )