# 🌿 AgriCropSentinel - Integrated AI Crop Disease & IPM Advisory Platform

AgriCropSentinel is a unified agricultural AI platform combining:
1. **CNN Crop Disease Recognition** (`sih-2025` model for 39 plant disease classes)
2. **Integrated Pest Management (IPM)** (`AgriSentinel` biological, chemical, cultural control database)
3. **Multimodal Risk Fusion** (`AgriSentinel` weighted risk engine combining CV confidence, weather risk, crop stage, and regional outbreaks)
4. **Multilingual Gemini AI & Voice Advisory** (gTTS voice output in Hinglish, English, Punjabi)
5. **Flutter Mobile Application** (`CropDrop` frontend streamlined with Marketplace and Crop Calendar stripped out)

---

## 🏗️ Project Architecture

```
AgriCropSentinel/
├── docker-compose.yml        # Docker Compose configuration for Backend & MongoDB
├── backend/                  # Unified FastAPI Python Backend
│   ├── Dockerfile            # Container definition for Python backend
│   ├── main.py               # Main API Application Entrypoint
│   ├── image_analysis/       # CNN Model (39 Disease Classes) + Voice Helper + Gemini AI
│   ├── ipm/                  # Integrated Pest Management KB & Lookup
│   ├── fusion/               # Multimodal Risk Fusion Engine
│   ├── chatbot/              # Voice & Text AI Farmer Assistant Router
│   ├── micro_calculator/     # NPK Fertilizer & Micronutrient Calculator
│   ├── weather/              # Weather Fetching & Risk Advisory
│   ├── auth/                 # User Auth & MongoDB Integration
│   └── requirements.txt      # Python Dependencies
└── frontend/                 # Streamlined Flutter Mobile App
    ├── lib/
    │   ├── main.dart         # Flutter App Entrypoint & Splash Screen
    │   ├── screens/
    │   │   ├── camera.dart        # Leaf Scan & Upload with Disease, IPM, and Risk Badge UI
    │   │   ├── chatbot.dart       # AI Assistant Voice & Text Interface
    │   │   ├── npk_calc.dart      # NPK Fertilizer Calculator UI
    │   │   ├── weather.dart       # Live Weather & Outbreak Advisory UI
    │   │   ├── profile_page.dart  # User Settings & Profile UI
    │   │   └── homepage.dart      # Main Dashboard with Bottom Navigation
    └── pubspec.yaml          # Flutter Dependencies
```

---

## 🚀 How to Run

### 1. Start the Backend API & Database (Docker - Recommended)

No separate installation of Python, MongoDB (`mongod`), or dependencies needed!

```bash
# Run from project root
docker compose up -d --build
```
- Interactive Swagger API Docs: `http://localhost:8000/docs`
- Unified Disease Detection Endpoint: `POST http://localhost:8000/image-analysis/analyze`

To stop the containerized services:
```bash
docker compose down
```

#### Manual Run (Without Docker)
```bash
cd backend
pip install -r requirements.txt
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

---

### 2. Launch the Flutter Mobile App

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🎯 Unified API Contract (`POST /image-analysis/analyze`)

Uploaded leaf images return structured JSON containing:
* `analysis_result`: Predicted disease class, confidence, cause, cure.
* `ipm_advisory`: Step-by-step biological, chemical, and cultural controls.
* `risk_fusion`: Fused risk score (0.0-1.0), risk level (*LOW*, *MEDIUM*, *HIGH*, *CRITICAL*), spread risk, action urgency.
* `detailed_info`: Gemini AI concise natural language response.
* `voice_url`: Generated audio file path for farmer voice playback.
