import os
import json
from pathlib import Path

import requests
from dotenv import load_dotenv
from google.cloud import speech_v1p1beta1 as speech
from langdetect import detect, DetectorFactory


# ============================================================
# ENVIRONMENT CONFIGURATION
# ============================================================

# Load the .env file from:
# C:\Users\Dell\AgriCropSentinel\.env
#
# This works regardless of which folder Uvicorn is started from.

BASE_DIR = Path(__file__).resolve().parent.parent
ENV_FILE = BASE_DIR / ".env"

load_dotenv(ENV_FILE, override=True)


# ============================================================
# LANGUAGE DETECTION
# ============================================================

# Make language detection deterministic
DetectorFactory.seed = 0


# ============================================================
# GEMINI CONFIGURATION
# ============================================================

API_KEY = os.getenv(
    "GEMINI_API_KEY",
    os.getenv("API_KEY", "")
)

API_URL = (
    "https://generativelanguage.googleapis.com/"
    "v1beta/interactions"
)

# ============================================================
# SAFE STARTUP LOGGING
# ============================================================

print(f"📁 .env path: {ENV_FILE}")
print(f"📁 .env exists: {ENV_FILE.exists()}")
print(
    "🔑 Gemini API key loaded: "
    + ("YES" if API_KEY else "NO")
)


# ============================================================
# GEMINI AI FUNCTION
# ============================================================

def generate_gemini_response(
    prompt: str,
    language: str = "en"
):
    """
    Generate an agricultural response using
    Gemini Interactions API.
    """

    if not API_KEY:
        return {
            "success": False,
            "response": (
                "Gemini API key is not configured."
            ),
            "error": "GEMINI_API_KEY_MISSING"
        }

    language_names = {
        "en": "English",
        "hi": "Hindi",
        "mr": "Marathi",
        "pa": "Punjabi",
        "bn": "Bengali",
        "gu": "Gujarati",
        "ta": "Tamil",
        "te": "Telugu",
        "kn": "Kannada",
        "ml": "Malayalam"
    }

    language_name = language_names.get(
        language,
        "English"
    )

    system_instruction = f"""
You are AgriCropSentinel AI, an agricultural
assistant designed to help farmers.

Answer in {language_name}.

Your responsibilities:
1. Explain crop diseases in simple language.
2. Explain possible causes.
3. Suggest practical Integrated Pest Management (IPM).
4. Give preventive measures.
5. Consider weather and crop conditions when relevant.
6. Do not give dangerous or unsupported pesticide advice.
7. Recommend consultation with a local agricultural
   expert when field verification is required.

Keep answers practical, concise, and farmer-friendly.
"""

    payload = {
        "model": "gemini-3.6-flash",
        "input": prompt,
        "system_instruction": system_instruction,
        "store": False
    }

    headers = {
        "x-goog-api-key": API_KEY,
        "Content-Type": "application/json"
    }

    try:

        response = requests.post(
            API_URL,
            headers=headers,
            json=payload,
            timeout=60
        )

        response.raise_for_status()

        data = response.json()

        # The Interactions API returns model output
        # inside the steps array.
        steps = data.get("steps", [])

        text = ""

        for step in reversed(steps):

            if step.get("type") == "model_output":

                content = step.get(
                    "content",
                    []
                )

                for item in content:

                    if item.get("type") == "text":

                        text = item.get(
                            "text",
                            ""
                        ).strip()

                        if text:
                            break

            if text:
                break

        # Some responses may expose output_text directly.
        if not text:
            text = data.get(
                "output_text",
                ""
            ).strip()

        if not text:

            return {
                "success": False,
                "response": (
                    "Gemini returned an empty response."
                ),
                "error": {
                    "type": "EMPTY_GEMINI_RESPONSE",
                    "details": data
                }
            }

        return {
            "success": True,
            "response": text,
            "error": None
        }

    except requests.exceptions.HTTPError:

        try:
            error_data = response.json()
        except Exception:
            error_data = {}

        return {
            "success": False,
            "response": (
                "Unable to connect to Gemini AI."
            ),
            "error": {
                "type": "HTTP_ERROR",
                "status_code": response.status_code,
                "details": error_data
            }
        }

    except requests.exceptions.Timeout:

        return {
            "success": False,
            "response": (
                "Gemini AI request timed out."
            ),
            "error": "GEMINI_TIMEOUT"
        }

    except requests.exceptions.ConnectionError:

        return {
            "success": False,
            "response": (
                "Could not connect to Gemini AI."
            ),
            "error": "GEMINI_CONNECTION_ERROR"
        }

    except Exception as e:

        return {
            "success": False,
            "response": (
                "An unexpected Gemini error occurred."
            ),
            "error": str(e)
        }


# ============================================================
# LANGUAGE DETECTION
# ============================================================

def detect_language(text: str) -> str:
    """
    Detect the language of user input.

    Falls back to English if detection fails.
    """

    if not text or not text.strip():
        return "en"

    try:

        detected = detect(text)

        # Supported languages
        supported_languages = {
            "en",
            "hi",
            "mr",
            "pa",
            "bn",
            "gu",
            "ta",
            "te",
            "kn",
            "ml"
        }

        if detected in supported_languages:
            return detected

        return "en"

    except Exception:

        return "en"


# ============================================================
# TEXT CHAT FUNCTION
# ============================================================

def chat_with_gemini(
    message: str,
    language: str = None
):
    """
    Main chatbot function.

    If language is not provided,
    automatically detects it.
    """

    if not message or not message.strip():

        return {
            "success": False,
            "response": "Please enter a question.",
            "language": "en",
            "error": "EMPTY_MESSAGE"
        }

    # Automatically detect language
    if not language:
        language = detect_language(message)

    result = generate_gemini_response(
        prompt=message,
        language=language
    )

    result["language"] = language

    return result


# ============================================================
# GOOGLE CLOUD SPEECH-TO-TEXT
# ============================================================

def speech_to_text(
    audio_content: bytes,
    language_code: str = "en-IN"
):
    """
    Convert audio bytes to text using Google Cloud Speech-to-Text.
    """

    try:

        client = speech.SpeechClient()

        audio = speech.RecognitionAudio(
            content=audio_content
        )

        config = speech.RecognitionConfig(
            encoding=speech.RecognitionConfig.AudioEncoding.WEBM_OPUS,
            sample_rate_hertz=48000,
            language_code=language_code,
            enable_automatic_punctuation=True
        )

        response = client.recognize(
            config=config,
            audio=audio
        )

        transcripts = []

        for result in response.results:

            if result.alternatives:

                transcripts.append(
                    result.alternatives[0].transcript
                )

        text = " ".join(transcripts).strip()

        return {
            "success": True,
            "text": text,
            "error": None
        }

    except Exception as e:

        return {
            "success": False,
            "text": "",
            "error": str(e)
        }


# ============================================================
# VOICE CHAT FUNCTION
# ============================================================

def voice_chat(
    audio_content: bytes,
    language_code: str = "en-IN"
):
    """
    Complete voice pipeline:

    Audio
       ↓
    Speech-to-Text
       ↓
    Language Detection
       ↓
    Gemini AI
    """

    # Step 1: Speech recognition
    transcription = speech_to_text(
        audio_content=audio_content,
        language_code=language_code
    )

    if not transcription["success"]:

        return {
            "success": False,
            "text": "",
            "response": (
                "I could not understand the audio."
            ),
            "error": transcription["error"]
        }

    text = transcription["text"]

    if not text:

        return {
            "success": False,
            "text": "",
            "response": (
                "No speech was detected in the audio."
            ),
            "error": "NO_SPEECH_DETECTED"
        }

    # Step 2: Detect language
    language = detect_language(text)

    # Step 3: Gemini
    gemini_result = generate_gemini_response(
        prompt=text,
        language=language
    )

    return {
        "success": gemini_result["success"],
        "text": text,
        "response": gemini_result["response"],
        "language": language,
        "error": gemini_result.get("error")
    }


# ============================================================
# HEALTH CHECK
# ============================================================

def gemini_health_check():
    """
    Simple local configuration check.

    Does NOT make an API request.
    """

    return {
        "gemini_configured": bool(API_KEY),
        "env_file": str(ENV_FILE),
        "env_file_exists": ENV_FILE.exists()
    }


# ============================================================
# LOCAL TEST
# ============================================================

if __name__ == "__main__":

    print("\n====================================")
    print(" AgriCropSentinel Gemini Chatbot")
    print("====================================")

    health = gemini_health_check()

    print(
        "Gemini configured:",
        health["gemini_configured"]
    )

    print(
        "Environment file:",
        health["env_file"]
    )

    print(
        "Environment file exists:",
        health["env_file_exists"]
    )

    if API_KEY:

        print("\nTesting Gemini...")

        result = chat_with_gemini(
            "What are common causes of crop diseases?"
        )

        print("\nResponse:")

        print(result["response"])

        if result.get("error"):
            print("\nError:")
            print(result["error"])

    else:

        print(
            "\n❌ GEMINI_API_KEY is missing."
        )

        print(
            "Add GEMINI_API_KEY to the .env file."
        )
        # ============================================================
# BACKWARD COMPATIBILITY FOR chatbot/routes.py
# ============================================================

def get_gemini_response(
    prompt: str,
    language: str = "en"
):
    """
    Compatibility wrapper used by chatbot/routes.py.
    """

    result = generate_gemini_response(
        prompt=prompt,
        language=language
    )

    if result["success"]:
        return result["response"]

    return result["response"]


def transcribe_audio(
    audio_content: bytes,
    language_code: str = "en-IN"
):
    """
    Compatibility wrapper used by chatbot/routes.py.
    """

    result = speech_to_text(
        audio_content=audio_content,
        language_code=language_code
    )

    if result["success"]:
        return result["text"]

    return ""