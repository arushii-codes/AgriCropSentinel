import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://localhost:8000";

  static Future<bool> addCrop(
    Map<String, dynamic> cropData,
    BuildContext context,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone');

      if (phone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number not found!")),
        );
        return false;
      }

      final url = Uri.parse("$baseUrl/crop/add_crops?phone=$phone");

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(cropData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("✅ Crop added successfully");
        return true;
      } else {
        print("❌ Failed: ${response.body}");
        return false;
      }
    } catch (e) {
      print("⚠️ Error adding crop: $e");
      return false;
    }
  }

  // ✅ Get all crops for a specific user phone
  static Future<Map<String, dynamic>?> getAllCrops(BuildContext context) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('user_phone');

      if (phone == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number not found!")),
        );
        return null;
      }

      final url = Uri.parse("$baseUrl/crop/all_crops?phone=$phone");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("✅ Crops fetched successfully: $data");
        return data;
      } else {
        print("❌ Failed to fetch crops: ${response.body}");
        return null;
      }
    } catch (e) {
      print("⚠️ Error fetching crops: $e");
      return null;
    }
  }

  // 🔹 Simulate Crop API
  static Future<Map<String, dynamic>?> simulateCrop(
    Map<String, dynamic> cropData,
    String phone,
    BuildContext context,
  ) async {
    try {
      // ✅ If phone not found in SharedPreferences, use passed one
      final prefs = await SharedPreferences.getInstance();
      final savedPhone = prefs.getString('user_phone') ?? phone;

      if (savedPhone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("📱 Phone number not found!")),
        );
        return null;
      }

      final url = Uri.parse("$baseUrl/crop/simulate_crop?phone=$savedPhone");

      // ✅ Send POST request
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(cropData),
      );

      // ✅ Debug logs
      debugPrint("📤 Request URL: $url");
      debugPrint("📦 Request Body: ${jsonEncode(cropData)}");
      debugPrint("📥 Response (${response.statusCode}): ${response.body}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        debugPrint("✅ Decoded Data: $decoded");
        return decoded;
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("❌ Failed: ${response.body}")));
        return null;
      }
    } catch (e) {
      debugPrint("⚠️ simulateCrop Error: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("⚠️ Error: $e")));
      return null;
    }
  }
}
