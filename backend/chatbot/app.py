import os
import requests
from typing import Optional

# ============================================================
# OPTIONAL SPEECH RECOGNITION
# ============================================================

try:
    import speech_recognition as sr

    SPEECH_RECOGNITION_AVAILABLE = True

except ImportError:
    sr = None
    SPEECH_RECOGNITION_AVAILABLE = False


# ============================================================
# GEMINI CLIENT
# ============================================================

_client = None


def _get_gemini_client():
    """
    Create Gemini client only when required.
    """

    global _client

    if _client is not None:
        return _client

    api_key = os.getenv("GEMINI_API_KEY")

    if not api_key:
        print("[CHATBOT] GEMINI_API_KEY not configured.")
        return None

    try:

        from google import genai

        _client = genai.Client(
            api_key=api_key
        )

        return _client

    except Exception as e:

        print(
            f"[CHATBOT CLIENT ERROR] {e}"
        )

        return None


# ============================================================
# FALLBACK CHATBOT
# ============================================================

def fallback_response(
    message: str,
    language: str = "en",
) -> str:

    text = message.lower()

    # --------------------------------------------------------
    # DISEASE
    # --------------------------------------------------------

    if any(
        word in text
        for word in [
            "disease",
            "diseases",
            "infection",
            "infected",
            "bimari",
            "बीमारी",
            "रोग",
        ]
    ):

        if language.lower() in [
            "hi",
            "hinglish",
        ]:

            return (
                "Aap crop ki clear leaf image upload karein. "
                "AgriSentinel AI possible disease ya pest identify "
                "karke weather, crop growth stage aur nearby cases "
                "ke basis par risk assess kar sakta hai. "
                "Agar infection spread ho raha hai to affected "
                "leaves ko remove karein aur tools ko sanitize karein."
            )

        return (
            "Please upload a clear image of the affected leaf. "
            "AgriSentinel can identify a possible disease or pest "
            "and assess risk using weather, crop growth stage and "
            "nearby cases. If infection is spreading, remove "
            "affected leaves and sanitize tools."
        )

    # --------------------------------------------------------
    # PEST
    # --------------------------------------------------------

    if any(
        word in text
        for word in [
            "pest",
            "insect",
            "bug",
            "keeda",
            "कीड़ा",
            "कीट",
        ]
    ):

        if language.lower() in [
            "hi",
            "hinglish",
        ]:

            return (
                "Pest problem ke liye leaves ke underside ko check "
                "karein aur infestation ka spread monitor karein. "
                "Affected plants ko identify karke Integrated Pest "
                "Management practices follow karein."
            )

        return (
            "For pest problems, inspect the underside of leaves "
            "and monitor how quickly the infestation is spreading. "
            "Identify affected plants and follow Integrated Pest "
            "Management practices."
        )

    # --------------------------------------------------------
    # WEATHER
    # --------------------------------------------------------

    if any(
        word in text
        for word in [
            "weather",
            "rain",
            "rainfall",
            "temperature",
            "humidity",
            "mausam",
            "baarish",
            "बारिश",
            "मौसम",
        ]
    ):

        if language.lower() in [
            "hi",
            "hinglish",
        ]:

            return (
                "Weather crop-health risk ko affect karta hai. "
                "High humidity, suitable temperature aur rainfall "
                "fungal diseases aur kuch pests ke development ko "
                "favour kar sakte hain. AgriSentinel weather risk "
                "ko disease detection ke saath combine karta hai."
            )

        return (
            "Weather can affect crop-health risk. High humidity, "
            "suitable temperatures and rainfall can favor fungal "
            "diseases and some pests. AgriSentinel combines weather "
            "risk with disease detection."
        )

    # --------------------------------------------------------
    # NPK
    # --------------------------------------------------------

    if any(
        word in text
        for word in [
            "npk",
            "fertilizer",
            "fertiliser",
            "nutrient",
            "nutrition",
            "khad",
            "खाद",
        ]
    ):

        if language.lower() in [
            "hi",
            "hinglish",
        ]:

            return (
                "NPK ka matlab Nitrogen, Phosphorus aur Potassium "
                "hai. Fertilizer apply karne se pehle crop type, "
                "soil condition aur recommended dose ko consider "
                "karna chahiye."
            )

        return (
            "NPK stands for Nitrogen, Phosphorus and Potassium. "
            "Before applying fertilizer, consider the crop type, "
            "soil condition and recommended dose."
        )

    # --------------------------------------------------------
    # RISK
    # --------------------------------------------------------

    if any(
        word in text
        for word in [
            "risk",
            "danger",
            "high risk",
            "low risk",
            "medium risk",
            "khatra",
        ]
    ):

        if language.lower() in [
            "hi",
            "hinglish",
        ]:

            return (
                "Crop risk AI detection, weather conditions, "
                "growth stage aur nearby cases ko combine karke "
                "calculate kiya jata hai. High risk hone par "
                "affected crop ko closely monitor karein aur "
                "recommended IPM actions follow karein."
            )

        return (
            "Crop risk combines AI detection, weather conditions, "
            "crop growth stage and nearby cases. For high risk, "
            "closely monitor affected crops and follow recommended "
            "IPM actions."
        )

    # --------------------------------------------------------
    # GENERAL
    # --------------------------------------------------------

    if language.lower() in [
        "hi",
        "hinglish",
    ]:

        return (
            "Main AgriSentinel crop-health assistant hoon. "
            "Aap mujhse crop disease, pest, weather, crop risk, "
            "NPK, symptoms aur crop management ke baare mein "
            "pooch sakte hain."
        )

    return (
        "I am the AgriSentinel crop-health assistant. "
        "You can ask me about crop diseases, pests, weather, "
        "crop risk, NPK, symptoms and crop management."
    )


# ============================================================
# GEMINI CHATBOT
# ============================================================

def get_gemini_response(
    prompt: str,
    language: str = "en",
    context: Optional[str] = None,
) -> str:

    api_key = os.getenv("GEMINI_API_KEY")

    if not api_key:
        print("[CHATBOT] GEMINI_API_KEY not configured, using fallback.")
        return fallback_response(
            prompt,
            language,
        )

    # --------------------------------------------------------
    # LANGUAGE
    # --------------------------------------------------------

    if language.lower() in [
        "hi",
        "hinglish",
    ]:

        language_instruction = (
            "Respond in simple Hinglish using English letters. "
            "Do not use Devanagari."
        )

    elif language.lower() == "pa":

        language_instruction = (
            "Respond in simple Punjabi written using English letters."
        )

    else:

        language_instruction = (
            "Respond in clear, simple English."
        )

    # --------------------------------------------------------
    # SYSTEM PROMPT
    # --------------------------------------------------------

    system_prompt = f"""
You are AgriSentinel, an AI crop-health assistant.

Your purpose is to help farmers with:

1. Crop diseases
2. Crop pests
3. Disease symptoms
4. Weather-related crop risks
5. Crop growth stages
6. Integrated Pest Management (IPM)
7. Basic nutrient management
8. NPK information
9. Crop monitoring
10. Preventive agricultural practices

{language_instruction}

Important rules:

- Give practical farmer-friendly advice.
- Keep answers easy to understand and concise.
- Do not claim that an AI diagnosis is 100% certain.
- Recommend expert validation when necessary.
- Do not invent pesticide dosage.
- Do not recommend unsafe chemical use.
- Explain technical terms in simple language.
- Focus on early detection and prevention.

"""

    # --------------------------------------------------------
    # CONTEXT
    # --------------------------------------------------------

    if context:

        system_prompt += f"""

Current crop context:

{context}

"""

    # --------------------------------------------------------
    # FINAL PROMPT
    # --------------------------------------------------------

    final_prompt = (
        system_prompt
        + "\nFarmer question:\n"
        + prompt
    )

    # --------------------------------------------------------
    # GEMINI REST API CALL
    # --------------------------------------------------------

    models_to_try = [
        "gemini-3.5-flash-lite",
        "gemini-3.1-flash-lite",
        "gemini-3.5-flash",
    ]

    for model_name in models_to_try:
        try:
            url = f"https://generativelanguage.googleapis.com/v1beta/models/{model_name}:generateContent?key={api_key}"
            payload = {
                "contents": [
                    {
                        "parts": [{"text": final_prompt}]
                    }
                ],
                "generationConfig": {
                    "temperature": 0.7,
                    "maxOutputTokens": 600,
                }
            }

            res = requests.post(
                url,
                json=payload,
                headers={"Content-Type": "application/json"},
                timeout=6,
            )

            if res.status_code == 200:
                data = res.json()
                candidates = data.get("candidates", [])
                if candidates:
                    parts = candidates[0].get("content", {}).get("parts", [])
                    if parts and "text" in parts[0]:
                        answer = parts[0]["text"].strip()
                        if answer:
                            return answer

            print(
                f"[GEMINI WARNING] Model {model_name} status {res.status_code}: {res.text[:200]}"
            )

        except Exception as e:
            print(
                f"[GEMINI ERROR with {model_name}] {e}"
            )

    return fallback_response(
        prompt,
        language,
    )


# ============================================================
# AUDIO TRANSCRIPTION
# ============================================================

def transcribe_audio(
    audio_source,
    language: str = "en-US",
) -> str:
    """
    Convert farmer voice input into text.

    Supports a file path or an audio file-like object.

    If SpeechRecognition is unavailable, returns a safe
    fallback message instead of crashing the API.
    """

    if not SPEECH_RECOGNITION_AVAILABLE:

        print(
            "[VOICE] speech_recognition is not installed."
        )

        return ""

    try:

        recognizer = sr.Recognizer()

        # ----------------------------------------------------
        # FILE PATH
        # ----------------------------------------------------

        if isinstance(
            audio_source,
            str,
        ):

            with sr.AudioFile(
                audio_source
            ) as source:

                audio = recognizer.record(
                    source
                )

        # ----------------------------------------------------
        # FILE-LIKE OBJECT
        # ----------------------------------------------------

        else:

            # Try to obtain a path if available.
            file_path = getattr(
                audio_source,
                "filename",
                None,
            )

            if file_path:

                with sr.AudioFile(
                    file_path
                ) as source:

                    audio = recognizer.record(
                        source
                    )

            else:

                raise ValueError(
                    "Audio source must be a valid audio file path."
                )

        # ----------------------------------------------------
        # GOOGLE SPEECH RECOGNITION
        # ----------------------------------------------------

        text = recognizer.recognize_google(
            audio,
            language=language,
        )

        print(
            f"[VOICE] Transcribed: {text}"
        )

        return text.strip()

    except sr.UnknownValueError:

        print(
            "[VOICE] Could not understand audio."
        )

        return ""

    except sr.RequestError as e:

        print(
            f"[VOICE] Speech recognition service error: {e}"
        )

        return ""

    except Exception as e:

        print(
            f"[VOICE ERROR] {e}"
        )

        return ""


# ============================================================
# HELPER FOR VOICE CHAT
# ============================================================

def process_voice_question(
    audio_source,
    language: str = "en-US",
    chat_language: str = "en",
    context: Optional[str] = None,
):
    """
    Transcribe voice and send the result to the chatbot.
    """

    text = transcribe_audio(
        audio_source,
        language,
    )

    if not text:

        return {
            "success": False,
            "transcription": "",
            "response": (
                "Sorry, I could not understand the voice input."
            ),
        }

    response = get_gemini_response(
        prompt=text,
        language=chat_language,
        context=context,
    )

    return {
        "success": True,
        "transcription": text,
        "response": response,
    }