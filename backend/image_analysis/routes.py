from fastapi import APIRouter, HTTPException, Request, UploadFile, File, Query
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
from image_analysis.voice_helper import generate_voice, clean_label_for_voice
from chatbot.app import get_gemini_response
from ipm.lookup import load_knowledge_base, get_advisory
from ipm.review_queue import needs_review, add_case
from schemas import ImageUploadResponse
from utils.cv_adapter import adapt_cv_result

UPLOAD_DIR = "uploadimages"
os.makedirs(UPLOAD_DIR, exist_ok=True)

router = APIRouter()
templates = Jinja2Templates(directory="templates")

# Load IPM Knowledge Base once at module import
try:
    ipm_kb = load_knowledge_base()
    print("✅ IPM Knowledge Base loaded successfully")
except Exception as e:
    print(f"⚠️ IPM KB load error: {e}")
    ipm_kb = {"crops": {}}

async def save_analysis_to_db(analysis_data: dict):
    """Async helper to save analysis to MongoDB."""
    try:
        if db is not None:
            await db["image_analyses"].insert_one(analysis_data)
            print("✅ Analysis saved to DB")
    except Exception as e:
        print(f"❌ DB save error: {e}")

def calculate_risk_fusion(confidence: float, disease_name: str):
    """Calculates multimodal risk fusion metrics based on CV confidence & disease context."""
    if confidence >= 0.80:
        risk_level = "critical" if "blight" in disease_name.lower() or "virus" in disease_name.lower() else "high"
    elif confidence >= 0.60:
        risk_level = "medium"
    else:
        risk_level = "low"
    
    score_map = {"low": 0.25, "medium": 0.55, "high": 0.78, "critical": 0.92}
    urgency_map = {
        "low": "Monitor crop weekly",
        "medium": "Monitor closely & apply organic preventative steps",
        "high": "Act soon with targeted IPM measures",
        "critical": "Act immediately to prevent severe crop loss"
    }
    
    fused_score = score_map.get(risk_level, 0.5)
    urgency = urgency_map.get(risk_level, "Monitor closely")
    spread_risk = round(fused_score * 0.85, 2)
    
    explanation = (
        f"Assessed as {risk_level.upper()} risk level based on computer vision confidence ({confidence:.1%}) "
        f"and epidemiological disease characteristics for {disease_name}."
    )
    
    return {
        "fused_risk_score": fused_score,
        "risk_level": risk_level,
        "urgency": urgency,
        "spread_risk": spread_risk,
        "explanation": explanation
    }

@router.post("/predict", response_model=ImageUploadResponse)
async def predict_endpoint(file: UploadFile = File(...)):
    """
    Standardized Computer Vision prediction endpoint matching ImageUploadResponse contract.
    """
    filename = f"temp_{uuid.uuid4().hex}_{file.filename}"
    image_path = os.path.join(UPLOAD_DIR, filename)
    with open(image_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
    try:
        analysis_result = await asyncio.to_thread(model_predict, image_path)
        if 'predicted_class' not in analysis_result:
            raise HTTPException(status_code=400, detail="Image analysis failed")
        return adapt_cv_result(analysis_result)
    finally:
        if os.path.exists(image_path):
            try:
                os.remove(image_path)
            except Exception:
                pass

@router.post("/analyze")
async def analyze_image_endpoint(
    request: Request, 
    file: UploadFile = File(...), 
    voice: bool = Query(True, description="Generate voice?"), 
    lang: str = Query("hi", description="Language: 'hi' for Hinglish, 'en' for English, 'pa' for Punjabi")
):
    start_time = time.time()
    try:
        allowed_types = ["image/jpeg", "image/png"]
        allowed_exts = [".jpg", ".jpeg", ".png"]

        ext = os.path.splitext(file.filename)[1].lower()
        if (file.content_type not in allowed_types) and (ext not in allowed_exts):
            raise HTTPException(status_code=400, detail="Only JPEG or PNG images are supported")

        filename = f"temp_{uuid.uuid4().hex}_{file.filename}"
        image_path = os.path.join(UPLOAD_DIR, filename)

        with open(image_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        upload_end = time.time()
        print(f"⏱️ Upload time: {upload_end - start_time:.2f}s")

        # Run prediction in background thread
        analysis_start = time.time()
        analysis_result = await asyncio.to_thread(model_predict, image_path)
        analysis_end = time.time()
        print(f"⏱️ Model prediction time: {analysis_end - analysis_start:.2f}s")

        # Check if prediction succeeded
        if 'predicted_class' not in analysis_result:
            raise HTTPException(status_code=400, detail=f"Image analysis failed: {analysis_result.get('cause', 'Unknown error')}")

        predicted_class = analysis_result['predicted_class']
        confidence = analysis_result.get('confidence', 0.85)
        cleaned_result = clean_label_for_voice(predicted_class)

        # Integrated Risk Fusion Calculation
        risk_fusion = calculate_risk_fusion(confidence, cleaned_result)

        # Integrated IPM Advisory Lookup & Expert Review Intercept
        if needs_review(confidence):
            queued_case = add_case(
                disease_or_pest_name=cleaned_result,
                risk_level=risk_fusion["risk_level"],
                language=lang.lower(),
                confidence=confidence,
                image_url=f"/uploadimages/{filename}"
            )
            ipm_advisory = {
                "advisory_text": (
                    f"This case has low prediction confidence ({confidence:.0%}) "
                    f"and has been queued for expert review (reference #{queued_case['case_id']}). "
                    f"The guidance below is general and preliminary."
                ),
                "ipm_steps": [
                    "Monitor the affected crop closely and take clear photos from multiple angles.",
                    "Avoid applying chemical treatment until confirmed by an expert.",
                    "Check back once expert review is complete for confirmed guidance."
                ],
                "language": lang.lower(),
                "expert_validated": False,
                "under_expert_review": True,
                "review_case_id": queued_case["case_id"]
            }
        else:
            ipm_advisory = get_advisory(ipm_kb, cleaned_result, risk_fusion["risk_level"], language=lang.lower())
            ipm_advisory["under_expert_review"] = False
            ipm_advisory["review_case_id"] = None

        # Language mapping for Gemini prompt
        lang_map = {
            'hi': 'Hinglish (write Hindi in English letters, e.g. "dawa lagao, paani do")',
            'hinglish': 'Hinglish (write Hindi in English letters, not Devanagari)',
            'en': 'English',
            'pa': 'Punjabi (write Punjabi in English letters, not Gurmukhi)'
        }
        user_lang = lang.lower()
        prompt_lang = lang_map.get(user_lang, 'English')

        summary = (
            f"This leaf is affected by {cleaned_result} (Risk: {risk_fusion['risk_level'].upper()}). "
            f"Cause: {analysis_result['cause']}. "
            f"Treatment: {analysis_result['cure']}."
        )

        detailed_prompt = (
            f"Briefly describe {cleaned_result} disease in {prompt_lang}. "
            f"Do not use native Hindi or Punjabi script, only English letters. "
            f"Explain what it is, treatment, cure, and fertilizer suggestions. "
            f"Keep it concise, under 80 words."
        )
        gemini_start = time.time()
        detailed_info = get_gemini_response(detailed_prompt)
        gemini_end = time.time()
        print(f"⏱️ Gemini API time: {gemini_end - gemini_start:.2f}s")

        # Generate voice
        voice_filename = None
        if voice:
            voice_start = time.time()
            voice_filename = generate_voice(detailed_info, lang=user_lang)
            voice_end = time.time()
            print(f"⏱️ Voice generation time: {voice_end - voice_start:.2f}s")

        analysis_data = {
            "filename": filename,
            "full_path": image_path,
            "analysis_result": analysis_result,
            "ipm_advisory": ipm_advisory,
            "risk_fusion": risk_fusion,
            "summary_text": summary,
            "detailed_info": detailed_info,
            "voice_file": voice_filename,
            "user_lang": user_lang,
            "timestamp": datetime.datetime.now()
        }

        asyncio.create_task(save_analysis_to_db(analysis_data))

        return {
            "filename": filename,
            "image_url": f"/uploadimages/{filename}",
            "analysis_result": analysis_result,
            "ipm_advisory": ipm_advisory,
            "risk_fusion": risk_fusion,
            "summary_text": summary,
            "detailed_info": detailed_info,
            "voice_url": f"/uploadvoices/{voice_filename}" if voice_filename else None,
            "timestamp": str(datetime.datetime.now())
        }
    except HTTPException:
        raise
    except Exception as e:
        print(f"Error in /analyze: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")

@router.get("/dashboard", response_class=HTMLResponse)
async def image_analysis_dashboard(request: Request):
    try:
        analyses = await db["image_analyses"].find().sort("timestamp", -1).to_list(length=10)
        analyses = [
            {
                "filename": analysis["filename"],
                "image_url": f"/uploadimages/{analysis['filename']}",
                "analysis_result": analysis["analysis_result"],
                "detailed_info": analysis.get("detailed_info", "No detailed info available"),
                "timestamp": str(analysis["timestamp"])
            }
            for analysis in analyses
        ]
        return templates.TemplateResponse("image_dashboard.html", {"request": request, "analyses": analyses})
    except Exception as e:
        print(f"Error in /dashboard: {traceback.format_exc()}")
        raise HTTPException(status_code=500, detail=f"Internal server error: {str(e)}")
