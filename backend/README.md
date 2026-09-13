# 🚜 AgriCropSentinel Backend

FastAPI backend for AgriCropSentinel—empowering Indian farmers with AI-driven crop diagnostics, voice queries, and secure data management.

## 🌾 Key Features
- 🔐 JWT Authentication & User Management
- 📁 Image Upload & CNN Crop Disease Detection (39 Classes)
- 🎤 Gemini AI Farmer Voice & Chatbot Integration
- 🗺 GIS Outbreak Intelligence & Spatial Clustering
- 📊 Full REST APIs with Swagger Docs

## 🐳 Docker Setup (Recommended)

No need to install Python, MongoDB, or any system dependencies on your machine. Everything runs inside Docker containers.

### Prerequisites
- [Docker](https://docs.docker.com/get-docker/) & Docker Compose

### Running with Docker Compose

1. **Start all services (Backend + MongoDB)**:
   ```bash
   docker compose up -d --build
   ```

2. **Access API Documentation**:
   - Swagger UI: [http://localhost:8000/docs](http://localhost:8000/docs)
   - ReDoc: [http://localhost:8000/redoc](http://localhost:8000/redoc)

3. **Check Container Status & Logs**:
   ```bash
   docker compose ps
   docker compose logs -f backend
   ```

4. **Stop Services**:
   ```bash
   docker compose down
   ```

---

## 🛠 Manual Setup (Without Docker)
If you prefer running Python directly:
1. Ensure MongoDB is running locally on port 27017.
2. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Start FastAPI server:
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```