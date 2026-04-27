// import 'dart:async';
// import 'dart:convert';
// import 'package:flutter/foundation.dart';
// import 'package:http/http.dart' as http;

// class ApiClient {
//   static const String base = "https://estimate-pro-backend.onrender.com";

//   static Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body, {String? token}) async {
//     try {
//       final url = Uri.parse("$base$endpoint");
//       debugPrint("API POST: $url");

//       final headers = {
//         "Content-Type": "application/json",
//         if (token != null) "Authorization": "Bearer $token",
//       };

//       final res = await http
//           .post(url, headers: headers, body: jsonEncode(body))
//           .timeout(const Duration(seconds: 120));

//       return {
//         "status": res.statusCode,
//         "body": res.body.isNotEmpty ? jsonDecode(res.body) : {},
//         "success": res.statusCode >= 200 && res.statusCode < 300,
//       };
//     } on TimeoutException {
//       throw TimeoutException("timeout");
//     } catch (e) {
//       debugPrint("API RAW ERROR: $e");
//       return {"status": 0, "body": {"message": "Network Error"}, "success": false};
//     }
//   }

//   /// retry for cold server
//   static Future<Map<String, dynamic>> postWithRetry(
//       String endpoint, Map<String, dynamic> body) async {
//     for (int i = 1; i <= 3; i++) {
//       try {
//         debugPrint("Attempt $i");
//         return await post(endpoint, body);
//       } on TimeoutException {
//         debugPrint("Timeout attempt $i, waiting 10 sec...");
//         await Future.delayed(const Duration(seconds: 10));
//       }
//     }
//     return {"success": false, "body": {"message": "Server not responding"}};
//   }
// }
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Fixed & production-ready ApiClient for your Render backend
/// • Fixes Cloudflare/Render bot protection (User-Agent issue)
/// • Handles cold-start retry logic (Render free tier)
class ApiClient {
  static const String base = "https://estimate-pro-backend.onrender.com";

  // This User-Agent makes Cloudflare/Render happy
  static const String _userAgent =
      "Mozilla/5.0 (Linux; Android 12; SM-S908B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Mobile Safari/537.36";

  // ──────────────────────────────────────────────────────────────
  // Normal POST with proper headers
  // ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    String? userId,
  }) async {
    final url = Uri.parse("$base$endpoint"); // ← fixed: added missing "
    debugPrint("API POST: $url");

    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": _userAgent, // ← THIS IS THE MAIN FIX
        if (token != null) "Authorization": "Bearer $token",
        if (userId != null) "userId": userId,
      };

      final response = await http
          .post(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      final Map<String, dynamic> decodedBody = response.body.isNotEmpty
          ? jsonDecode(response.body) as Map<String, dynamic>
          : {};

      return {
        "status": response.statusCode,
        "body": decodedBody,
        "success": response.statusCode >= 200 && response.statusCode < 300,
      };
    } on TimeoutException {
      throw TimeoutException("timeout");
    } on SocketException {
      return {
        "status": 0,
        "body": {"message": "No internet connection"},
        "success": false,
      };
    } catch (e) {
      debugPrint("API ERROR: $e");
      return {
        "status": 0,
        "body": {"message": "Network error"},
        "success": false,
      };
    }
  }

  // ──────────────────────────────────────────────────────────────
  // POST with automatic retry (for Render free tier cold starts)
  // ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> postWithRetry(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
    String? userId,
    int maxAttempts = 4,
  }) async {
    for (int i = 1; i <= maxAttempts; i++) {
      try {
        debugPrint("Attempt $i/$maxAttempts");
        final result = await post(endpoint, body, token: token, userId: userId);

        // If we got any HTTP status code (even error), stop retrying
        if (result["status"] != 0) {
          return result;
        }
      } on TimeoutException {
        debugPrint("Timeout on attempt $i");
      } catch (e) {
        debugPrint("Error on attempt $i: $e");
      }

      // Wait before next attempt (except after the last one)
      if (i < maxAttempts) {
        final waitSeconds = [15, 30, 45, 60][i - 1];
        debugPrint("Waiting $waitSeconds seconds before next try...");
        await Future.delayed(Duration(seconds: waitSeconds));
      }
    }

    return {
      "success": false,
      "status": 0,
      "body": {
        "message":
            "Server is taking too long to wake up. Please try again in a minute."
      }
    };
  }

  // ──────────────────────────────────────────────────────────────
  // Simple GET (optional, but handy)
  // ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
  }) async {
    final url = Uri.parse("$base$endpoint"); // ← fixed: added missing "
    debugPrint("API GET: $url");

    final headers = {
      "User-Agent": _userAgent,
      if (token != null) "Authorization": "Bearer $token",
    };

    try {
      final response = await http
          .get(url, headers: headers)
          .timeout(const Duration(seconds: 60));

      dynamic decodedBody;
      if (response.body.isNotEmpty) {
        try {
          decodedBody = jsonDecode(response.body);
        } catch (e) {
          debugPrint("JSON Decode Error: $e");
          debugPrint("Response body: ${response.body}");
          decodedBody = {
            "message": "Invalid JSON response",
            "raw": response.body
          };
        }
      } else {
        decodedBody = {};
      }

      return {
        "status": response.statusCode,
        "body": decodedBody,
        "success": response.statusCode >= 200 && response.statusCode < 300,
      };
    } catch (e) {
      debugPrint("GET ERROR: $e");
      return {
        "status": 0,
        "body": {"message": "Network error: $e"},
        "success": false,
      };
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Simple DELETE method
  // ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
  }) async {
    final url = Uri.parse("$base$endpoint");
    debugPrint("API DELETE: $url");

    final headers = {
      "User-Agent": _userAgent,
      if (token != null) "Authorization": "Bearer $token",
    };

    try {
      final response = await http
          .delete(url, headers: headers)
          .timeout(const Duration(seconds: 60));

      dynamic decodedBody;
      if (response.body.isNotEmpty) {
        try {
          decodedBody = jsonDecode(response.body);
        } catch (e) {
          debugPrint("JSON Decode Error: $e");
          debugPrint("Response body: ${response.body}");
          decodedBody = {
            "message": "Invalid JSON response",
            "raw": response.body
          };
        }
      } else {
        decodedBody = {};
      }

      return {
        "status": response.statusCode,
        "body": decodedBody,
        "success": response.statusCode >= 200 && response.statusCode < 300,
      };
    } catch (e) {
      debugPrint("DELETE ERROR: $e");
      return {
        "status": 0,
        "body": {"message": "Network error: $e"},
        "success": false,
      };
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Simple PUT method for updates
  // ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? token,
  }) async {
    final url = Uri.parse("$base$endpoint");
    debugPrint("API PUT: $url");

    try {
      final headers = {
        "Content-Type": "application/json",
        "Accept": "application/json",
        "User-Agent": _userAgent,
        if (token != null) "Authorization": "Bearer $token",
      };

      final response = await http
          .put(
            url,
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 60));

      dynamic decodedBody;
      if (response.body.isNotEmpty) {
        try {
          decodedBody = jsonDecode(response.body);
        } catch (e) {
          debugPrint("JSON Decode Error: $e");
          debugPrint("Response body: ${response.body}");
          decodedBody = {
            "message": "Invalid JSON response",
            "raw": response.body
          };
        }
      } else {
        decodedBody = {};
      }

      return {
        "status": response.statusCode,
        "body": decodedBody,
        "success": response.statusCode >= 200 && response.statusCode < 300,
      };
    } catch (e) {
      debugPrint("PUT ERROR: $e");
      return {
        "status": 0,
        "body": {"message": "Network error: $e"},
        "success": false,
      };
    }
  }
}
