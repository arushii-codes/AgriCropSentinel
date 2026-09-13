import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = "http://10.26.133.104:8000";

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Register a new user
  static Future<Map<String, dynamic>> registerUser(
    String name,
    String phone,
  ) async {
    final url = Uri.parse("$baseUrl/auth/register/");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"name": name, "phone": phone}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to register user: ${response.body}");
    }
  }

  /// Login user and store JWT token
  static Future<Map<String, dynamic>> loginUser(String phone) async {
    final url = Uri.parse("$baseUrl/auth/login");
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"phone": phone}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // Save access token
      await _saveToken(data['access_token']);

      // Save phone too
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_phone', phone);

      return data;
    } else {
      throw Exception("Failed to login: ${response.body}");
    }
  }

  /// Get user profile using JWT token
  static Future<Map<String, dynamic>> getUserProfile() async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');

    if (token == null || phone == null) {
      throw Exception("No token/phone found. User might not be logged in.");
    }

    final url = Uri.parse("$baseUrl/auth/profile/$phone");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to fetch profile: ${response.body}");
    }
  }

  /// Add product to cart using JWT token
  static Future<Map<String, dynamic>> addToCart(
    Map<String, dynamic> product,
  ) async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    if (token == null) throw Exception("User not logged in");

    final url = Uri.parse("$baseUrl/cart/add_cart?phone=$phone");
    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
      body: jsonEncode(product),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception("Failed to add to cart: ${response.body}");
    }
  }

  static Future<List<dynamic>> getCart() async {
    final token = await _getToken();
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('user_phone');
    if (token == null) throw Exception("User not logged in");

    final url = Uri.parse("$baseUrl/cart/get_cart/?phone=$phone");
    final response = await http.get(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $token",
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data["items"] ?? [];
    } else {
      throw Exception("Failed to fetch cart: ${response.body}");
    }
  }

  static Future<Map<String, dynamic>> getPrediction({
    required String state,
    required String crop,
  }) async {
    final url = Uri.parse('$baseUrl/farmer/predict');

    final headers = {'Content-Type': 'application/json'};
    final body = jsonEncode({"state": state, "crop": crop});

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed: ${response.body}');
    }
  }

  static Future<List<double>> fetchLast8DaysPrices(
    String crop,
    String state,
  ) async {
    final url = Uri.parse(
      "https://api.data.gov.in/resource/9ef84268-d588-465a-a308-a864a43d0070?state=$state&crop=$crop",
    );

    final response = await http.get(
      url,
      headers: {
        "apiKey": "579b464db66ec23bdd000001a13a8ff7df7842db6af8e9322f1c3560",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final prices = (data['prices'] as List)
          .map((e) => (e['price'] ?? 0).toDouble())
          .toList()
          .cast<double>();
      return prices.take(8).toList();
    } else {
      throw Exception("Failed to fetch mandi prices");
    }
  }
}
