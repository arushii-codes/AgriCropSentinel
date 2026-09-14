# 🔗 AgriCropSentinef - Backend Docker Setup & VS Code Dev Tunnels Connection Guide

This guide explains step-by-step how to run the backend using Docker, expose it publicly using **VS Code Dev Tunnels**, and update the frontend Flutter files to connect to your live backend.

---

## 📌 Summary of Steps

1. **Start Backend & Database using Docker** (`docker compose up -d --build`)
2. **Expose Port 8000 using VS Code Dev Tunnels** and set access to **Public**
3. **Update the Live URL in Frontend Files** (6 locations)
4. **Run the Flutter App** (`flutter run`)

---

## 🚀 Step 1: Start Backend & Database using Docker

Ensure Docker Desktop / Docker Engine is running on your computer.

1. Open a terminal at the project root directory:
   ```bash
   cd /path/to/AgriCropSentinel
   ```

2. Start the MongoDB database and FastAPI backend services:
   ```bash
   docker compose up -d --build
   ```

3. Verify services are running:
   ```bash
   docker compose ps
   ```
   * Both `agricropsentinel-mongo` and `agricropsentinel-backend` should show `Up` (healthy).

4. Test backend locally:
   * Open your browser and navigate to: [http://localhost:8000/docs](http://localhost:8000/docs)
   * You should see the interactive FastAPI Swagger documentation.

---

## 🌐 Step 2: Make Backend Live Using VS Code Dev Tunnels

VS Code Dev Tunnels allow your local port `8000` to be accessed from any remote device (like a physical Android/iOS phone or cloud emulator).

### Method A: Using VS Code UI (Recommended)

1. Open VS Code.
2. Open the **Ports** view:
   * Go to menu: `View` ➔ `Ports` (or open Panel using `Ctrl + ~` and click the **Ports** tab).
3. Click **Forward a Port**.
4. Enter Port Number: `8000` and press `Enter`.
5. **CRITICAL STEP**: By default, forwarded ports are **Private**. You MUST change it to **Public**:
   * Right-click on the `8000` entry under **Port**.
   * Hover over **Port Visibility** ➔ Select **Public**.
6. Copy the **Forwarded Address** (URL). It will look similar to:
   ```text
   https://random-id-8000.inc1.devtunnels.ms
   ```

> ⚠️ **Important Note**: Do NOT include a trailing slash `/` at the end of the URL when pasting it into frontend files.

---

## 📱 Step 3: Update Backend URL in Frontend Files

You need to update the `baseUrl` / `backendUrl` string variable in **6 frontend files**.

Replace `"YOUR_DEV_TUNNEL_URL"` with your actual Dev Tunnel URL (e.g., `https://random-id-8000.inc1.devtunnels.ms`).

---

### 📂 Complete File Listing & Locations

#### 1. [lib/services/api_service.dart](file:///home/Frutus/Projects/AgriCropSentinel/frontend/lib/services/api_service.dart#L6)
* **Purpose**: Authentication (Register/Login/Profile), Cart, & Crop Prediction endpoints.
* **Line 6**:
  ```dart
  // REPLACE THIS:
  static const String baseUrl = "https://9406-2402-8100-2b63-7704-20d0-a3ae-9499-bab3.ngrok-free.app";

  // WITH THIS:
  static const String baseUrl = "YOUR_DEV_TUNNEL_URL";
  ```

---

#### 2. [lib/services/crop_backend.dart](file:///home/Frutus/Projects/AgriCropSentinel/frontend/lib/services/crop_backend.dart#L7)
* **Purpose**: Add crops, list all crops, and crop simulation backend integration.
* **Line 7**:
  ```dart
  // REPLACE THIS:
  static const String baseUrl = "https://9406-2402-8100-2b63-7704-20d0-a3ae-9499-bab3.ngrok-free.app";

  // WITH THIS:
  static const String baseUrl = "YOUR_DEV_TUNNEL_URL";
  ```

---

#### 3. [lib/services/weather_service.dart](file:///home/Frutus/Projects/AgriCropSentinel/frontend/lib/services/weather_service.dart#L7)
* **Purpose**: Weather risk calculation service (`/weather/risk`).
* **Line 7**:
  ```dart
  // REPLACE THIS:
  const String backendUrl = "http://localhost:8000";

  // WITH THIS:
  const String backendUrl = "YOUR_DEV_TUNNEL_URL";
  ```

---

#### 4. [lib/screens/camera.dart](file:///home/Frutus/Projects/AgriCropSentinel/frontend/lib/screens/camera.dart#L22)
* **Purpose**: Leaf disease diagnosis photo upload (`/vision/analyze`).
* **Line 22**:
  ```dart
  // REPLACE THIS:
  static const String backendUrl = 'https://9406-2402-8100-2b63-7704-20d0-a3ae-9499-bab3.ngrok-free.app';

  // WITH THIS:
  static const String backendUrl = 'YOUR_DEV_TUNNEL_URL';
  ```

---

#### 5. [lib/screens/chatbot.dart](file:///home/Frutus/Projects/AgriCropSentinel/frontend/lib/screens/chatbot.dart#L53)
* **Purpose**: AI Farmer Chatbot & Voice playback audio streaming (`/chat`).
* **Line 53**:
  ```dart
  // REPLACE THIS:
  static const String backendUrl = "https://9406-2402-8100-2b63-7704-20d0-a3ae-9499-bab3.ngrok-free.app";

  // WITH THIS:
  static const String backendUrl = "YOUR_DEV_TUNNEL_URL";
  ```

---

#### 6. [lib/screens/weather.dart](file:///home/Frutus/Projects/AgriCropSentinel/frontend/lib/screens/weather.dart#L16)
* **Purpose**: Direct live weather & outbreak advisory screen.
* **Line 16**:
  ```dart
  // REPLACE THIS:
  static const String backendUrl = 'http://localhost:8000';

  // WITH THIS:
  static const String backendUrl = 'YOUR_DEV_TUNNEL_URL';
  ```

---

## 🛠️ Step 4: Run the Flutter Frontend

Once all 6 files are updated with your VS Code Dev Tunnel URL:

1. Open a terminal in the `frontend` folder:
   ```bash
   cd frontend
   ```
2. Install dependencies (if not done already):
   ```bash
   flutter pub get
   ```
3. Run the app on your emulator or connected phone:
   ```bash
   flutter run
   ```

---

## 🔍 Quick Checklist & Troubleshooting

| Problem | Cause | Solution |
| :--- | :--- | :--- |
| **`Connection Refused` or `401 Unauthorized`** | Dev Tunnel visibility is set to Private | Open VS Code **Ports** tab ➔ Right click port 8000 ➔ Set **Port Visibility** to **Public**. |
| **`404 Not Found`** | Extra trailing slash in URL | Ensure URL is `https://xxx.devtunnels.ms` without `/` at the end. |
| **Docker backend not responding** | Docker containers stopped or crashed | Run `docker compose logs -f agricropsentinel-backend` to view logs. Restart via `docker compose restart`. |
