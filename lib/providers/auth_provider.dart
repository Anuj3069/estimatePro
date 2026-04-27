
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/services/api_client.dart';
import '../data/services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  bool sending = false;
  bool verifying = false;
  String? token;
  String? email;
  String? userId;
  bool? isVerified;

  bool get isLoggedIn => token != null && userId != null;

  AuthProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("auth_token");
    email = prefs.getString("auth_email");
    userId = prefs.getString("user_id");
    isVerified = prefs.getBool("is_verified");
    ApiService.setAuthToken(token);
    notifyListeners();
  }

  Future<String?> sendOtp(String e) async {
    sending = true;
    notifyListeners();

    email = e;
    final res =
        await ApiClient.postWithRetry("/auth/send-otp", {"email": e});

    sending = false;
    notifyListeners();

    if (res["success"] == true) return null;
    return res["body"]["message"] ?? "Error";
  }

  Future<String?> verifyOtp(String otp) async {
    if (email == null) return "Missing email";

    verifying = true;
    notifyListeners();

    final res = await ApiClient.postWithRetry(
        "/auth/verify-otp", {"email": email, "otp": otp});

    verifying = false;
    notifyListeners();


    // Check if API call was successful
    if (res["success"] == true || res["body"]?["success"] == true) {
      final body = res["body"];
      
      // Extract token from response body
      String? extractedToken;
      String? extractedUserId;
      String? extractedEmail;
      bool extractedIsVerified = false;
      
      if (body is Map) {
        // Get token
        extractedToken = body["token"];
        
        // Get user data
        final user = body["user"];
        if (user is Map) {
          extractedUserId = user["id"];
          extractedEmail = user["email"];
          extractedIsVerified = user["isVerified"] ?? false;
        }
      }
      
      
      if (extractedToken != null && extractedUserId != null) {
        final prefs = await SharedPreferences.getInstance();
        
        // Save all auth data
        await prefs.setString("auth_token", extractedToken);
        await prefs.setString("user_id", extractedUserId);
        await prefs.setString("auth_email", extractedEmail ?? email!);
        await prefs.setBool("is_verified", extractedIsVerified);
        
        // Update provider state
        token = extractedToken;
        userId = extractedUserId;
        email = extractedEmail ?? email;
        isVerified = extractedIsVerified;
        ApiService.setAuthToken(token);
        
        notifyListeners();
        return null;
      }
      return "Token or User ID missing in response";
    }
    return res["body"]?["message"] ?? "OTP verification failed";
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("user_id");
    await prefs.remove("auth_email");
    await prefs.remove("is_verified");
    token = null;
    email = null;
    userId = null;
    isVerified = null;
    ApiService.setAuthToken(null);
    notifyListeners();
  }

  /// Check if user is logged in (loads from SharedPreferences)
  Future<bool> checkLogin() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("auth_token");
    email = prefs.getString("auth_email");
    userId = prefs.getString("user_id");
    isVerified = prefs.getBool("is_verified");
    ApiService.setAuthToken(token);
    notifyListeners();
    return token != null && userId != null;
  }
  
  /// Validate token with backend (optional - call this if you want to verify token is still valid)
  Future<bool> validateToken() async {
    if (token == null) return false;
    
    try {
      // You can create a /auth/validate endpoint on your backend
      // For now, we'll just check if token exists
      return token != null && userId != null;
    } catch (e) {
      return false;
    }
  }
}
