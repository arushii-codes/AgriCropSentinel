import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// FastAPI backend
const String backendUrl = "http://localhost:8000";

/// Fetch weather and weather-risk data for the farmer's
/// current GPS coordinates.
Future<Map<String, dynamic>> fetchWeather(
  double lat,
  double lon,
) async {
  final uri = Uri.parse(
    "$backendUrl/weather/risk"
    "?lat=$lat"
    "&lon=$lon",
  );

  print("🌦️ Fetching weather from: $uri");

  final response = await http.get(
    uri,
    headers: {
      "Accept": "application/json",
    },
  );

  print("🌦️ Weather response: ${response.statusCode}");
  print("🌦️ Weather body: ${response.body}");

  if (response.statusCode == 200) {
    final decoded = json.decode(response.body);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    throw Exception("Invalid weather response format.");
  }

  throw Exception(
    "Weather API failed: ${response.statusCode}",
  );
}

/// Get the farmer's current GPS location.
Future<Position> getUserLocation() async {
  // Check whether device location services are enabled.
  final serviceEnabled =
      await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    throw Exception(
      "Location services are disabled.",
    );
  }

  // Check current permission.
  LocationPermission permission =
      await Geolocator.checkPermission();

  // Ask for permission if not already granted.
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.denied) {
      throw Exception(
        "Location permission denied.",
      );
    }
  }

  // User permanently denied location permission.
  if (permission == LocationPermission.deniedForever) {
    throw Exception(
      "Location permissions permanently denied.",
    );
  }

  // Get current GPS position.
  final position =
      await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  print(
    "📍 Farmer location: "
    "${position.latitude}, ${position.longitude}",
  );

  return position;
}