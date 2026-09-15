from fastapi import APIRouter, HTTPException, UploadFile, File
import asyncio
import traceback
import datetime
import shutil
import uuid
import os

from chatbot.models import ChatRequest, VoiceChatRequest
from chatbot.app import get_gemini_response, transcribe_audio
from image_analysis.voice_helper import generate_voice

# MongoDB is OPTIONAL for chatbot.
# Chat should continue working even if MongoDB is unavailable.
try:
    from auth.database import db
except Exception as e:
    db = None
    print(f"[CHATBOT] MongoDB unavailable: {e}")


router = APIRouter()


# ============================================================
# DIRECTORIES
# ============================================================

UPLOAD_AUDIO_DIR = "uploadaudio"

os.makedirs(
    UPLOAD_AUDIO_DIR,
    exist_ok=True
)


# ============================================================
# GENERAL AI RESPONSE
# ============================================================

def get_general_ai_response(
    prompt: str,
    language: str = "en",
    context: str = None,
) -> str:

    try:

        return get_gemini_response(
            prompt=prompt,
            language=language,
            context=context,
        )

    except TypeError:

        # Compatibility with older get_gemini_response()
        try:

            return get_gemini_response(
                prompt
            )

        except Exception as e:

            print(
                f"[CHATBOT AI ERROR] {e}"
            )

            return (
                "Sorry, I could not process your question "
                "right now."
            )

    except Exception as e:

        print(
            f"[CHATBOT AI ERROR] {e}"
        )

        return (
            "Sorry, I could not process your question "
            "right now."
        )


# ============================================================
# SAVE CHAT TO DATABASE
# ============================================================

async def save_chat_to_db(
    chat_data: dict
):

    """
    Save chat history if MongoDB is available.

    MongoDB failure MUST NOT break the chatbot.
    """

    if db is None:

        print(
            "[CHATBOT] MongoDB not available. "
            "Chat history will not be saved."
        )

        return False

    try:

        await db[
            "chat_history"
        ].insert_one(
            chat_data
        )

        print(
            "[CHATBOT] Chat saved to DB"
        )

        return True

    except Exception as e:

        print(
            f"[CHATBOT DB WARNING] "
            f"Could not save chat: {e}"
        )

        # IMPORTANT:
        # Do NOT raise the error.
        # Chat should continue working.

        return False


# ============================================================
# TEXT CHAT
# ============================================================

@router.post("")
@router.post("/")
@router.post("/chat")
@router.post("/general")
async def chat(
    request: ChatRequest
):

    try:

        # ----------------------------------------------------
        # EXTRACT MESSAGE
        # ----------------------------------------------------

        message = getattr(
            request,
            "message",
            None
        )

        if not message:

            message = getattr(
                request,
                "prompt",
                None
            )

        if not message:

            raise HTTPException(
                status_code=400,
                detail="Message cannot be empty."
            )

        message = str(
            message
        ).strip()

        if not message:

            raise HTTPException(
                status_code=400,
                detail="Message cannot be empty."
            )

        # ----------------------------------------------------
        # LANGUAGE
        # ----------------------------------------------------

        language = getattr(
            request,
            "language",
            "en"
        )

        if not language:

            language = "en"

        # ----------------------------------------------------
        # OPTIONAL CROP CONTEXT
        # ----------------------------------------------------

        crop = getattr(
            request,
            "crop",
            None
        )

        disease = getattr(
            request,
            "disease",
            None
        )

        risk_level = getattr(
            request,
            "risk_level",
            None
        )

        weather_risk = getattr(
            request,
            "weather_risk",
            None
        )

        context_parts = []

        if crop:

            context_parts.append(
                f"Crop: {crop}"
            )

        if disease:

            context_parts.append(
                f"Detected disease or pest: {disease}"
            )

        if risk_level:

            context_parts.append(
                f"Current risk level: {risk_level}"
            )

        if weather_risk is not None:

            context_parts.append(
                f"Weather risk: {weather_risk}"
            )

        context = "\n".join(
            context_parts
        )

        # ----------------------------------------------------
        # GEMINI
        # ----------------------------------------------------

        response = await asyncio.to_thread(
            get_general_ai_response,
            prompt=message,
            language=language,
            context=context,
        )

        # ----------------------------------------------------
        # SAVE HISTORY
        # ----------------------------------------------------

        chat_data = {

            "type": "text_chat",

            "message": message,

            "language": language,

            "response": response,

            "crop": crop,

            "disease": disease,

            "risk_level": risk_level,

            "weather_risk": weather_risk,

            "timestamp": datetime.datetime.now(
                datetime.timezone.utc
            ),
        }

        await save_chat_to_db(
            chat_data
        )

        # ----------------------------------------------------
        # RESPONSE
        # ----------------------------------------------------

        return {

            "success": True,

            "response": response,

            "reply": response,

            "message": response,

            "prompt": message,

            "language": language,

            "timestamp": datetime.datetime.now(
                datetime.timezone.utc
            ).isoformat(),
        }

    except HTTPException:

        raise

    except Exception as e:

        print(
            "[CHAT ERROR]"
        )

        print(
            traceback.format_exc()
        )

        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )


# ============================================================
# VOICE CHAT
# ============================================================

@router.post("/voice_chat")
@router.post("/voice")
async def voice_chat(
    file: UploadFile = File(...)
):

    audio_path = None

    try:

        # ----------------------------------------------------
        # VALIDATE FILE
        # ----------------------------------------------------

        if not file:

            raise HTTPException(
                status_code=400,
                detail="Audio file is required."
            )

        # ----------------------------------------------------
        # SAVE AUDIO
        # ----------------------------------------------------

        extension = os.path.splitext(
            file.filename or ""
        )[1]

        if not extension:

            extension = ".wav"

        filename = (
            f"{uuid.uuid4().hex}"
            f"{extension}"
        )

        audio_path = os.path.join(
            UPLOAD_AUDIO_DIR,
            filename
        )

        with open(
            audio_path,
            "wb"
        ) as buffer:

            shutil.copyfileobj(
                file.file,
                buffer
            )

        print(
            f"[VOICE] Audio saved: {audio_path}"
        )

        # ----------------------------------------------------
        # TRANSCRIBE
        # ----------------------------------------------------

        detected_lang = "en-US"

        try:

            transcript = transcribe_audio(
                audio_path,
                detected_lang
            )

        except TypeError:

            # Compatibility with older
            # transcribe_audio(audio_path)

            transcript = transcribe_audio(
                audio_path
            )

        if not transcript:

            raise HTTPException(
                status_code=400,
                detail=(
                    "Could not understand the audio. "
                    "Please speak clearly and try again."
                )
            )

        print(
            f"[VOICE] Transcribed: "
            f"'{transcript}'"
        )

        # ----------------------------------------------------
        # AI RESPONSE
        # ----------------------------------------------------

        response = get_general_ai_response(
            prompt=transcript,
            language="en"
        )

        # ----------------------------------------------------
        # GENERATE VOICE RESPONSE
        # ----------------------------------------------------

        voice_filename = None

        try:

            voice_filename = generate_voice(
                response,
                lang="en",
                use_ssml=True,
                custom_rate=0.95
            )

        except Exception as e:

            print(
                f"[VOICE TTS WARNING] {e}"
            )

        # ----------------------------------------------------
        # SAVE CHAT HISTORY
        # ----------------------------------------------------

        chat_data = {

            "type": "voice_chat",

            "transcript": transcript,

            "detected_lang": detected_lang,

            "response": response,

            "voice_file": voice_filename,

            "timestamp": datetime.datetime.now(
                datetime.timezone.utc
            ),
        }

        await save_chat_to_db(
            chat_data
        )

        # ----------------------------------------------------
        # CLEAN TEMP AUDIO
        # ----------------------------------------------------

        try:

            if audio_path and os.path.exists(
                audio_path
            ):

                os.remove(
                    audio_path
                )

        except Exception as e:

            print(
                f"[VOICE CLEANUP WARNING] {e}"
            )

        # ----------------------------------------------------
        # RESPONSE
        # ----------------------------------------------------

        return {

            "success": True,

            "transcript": transcript,

            "detected_language": detected_lang,

            "response_text": response,

            "voice_url": (
                f"/uploadvoices/{voice_filename}"
                if voice_filename
                else None
            ),

            "timestamp": datetime.datetime.now(
                datetime.timezone.utc
            ).isoformat(),
        }

    except HTTPException:

        raise

    except Exception as e:

        print(
            "[VOICE CHAT ERROR]"
        )

        print(
            traceback.format_exc()
        )

        # Cleanup
        try:

            if audio_path and os.path.exists(
                audio_path
            ):

                os.remove(
                    audio_path
                )

        except Exception:

            pass

        raise HTTPException(
            status_code=500,
            detail=f"Internal server error: {str(e)}"
        )