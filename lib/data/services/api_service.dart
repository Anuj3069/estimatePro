// lib/data/services/api_service.dart
// 
// ═══════════════════════════════════════════════════════════════════════════
// COMPREHENSIVE API SERVICE - Postman-like pattern for all API calls
// ═══════════════════════════════════════════════════════════════════════════
// 
// Usage Example:
//   final result = await ApiService.login(email: 'test@example.com');
//   if (result.success) {
//     print('Token: ${result.data['token']}');
//   } else {
//     print('Error: ${result.message}');
//   }
// 

import 'api_client.dart';

/// Standard API Response wrapper
class ApiResponse<T> {
  final bool success;
  final int statusCode;
  final T? data;
  final String? message;

  ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
  });

  factory ApiResponse.fromMap(Map<String, dynamic> res) {
    return ApiResponse(
      success: res['success'] ?? false,
      statusCode: res['status'] ?? 0,
      data: res['body'] as T?,
      message: res['body']?['message'],
    );
  }
}

/// API Service - All API endpoints in one place
/// Similar to Postman collections
class ApiService {
  // Store token for authenticated requests
  static String? _authToken;

  static void setAuthToken(String? token) {
    _authToken = token;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // AUTH ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════

  /// POST /auth/send-otp
  /// Send OTP to email for login
  static Future<ApiResponse> sendOtp({required String email}) async {
    final res = await ApiClient.postWithRetry(
      '/auth/send-otp',
      {'email': email},
    );
    return ApiResponse.fromMap(res);
  }

  /// POST /auth/verify-otp
  /// Verify OTP and get auth token
  static Future<ApiResponse> verifyOtp({
    required String email,
    required String otp,
  }) async {
    final res = await ApiClient.postWithRetry(
      '/auth/verify-otp',
      {'email': email, 'otp': otp},
    );
    return ApiResponse.fromMap(res);
  }

  /// POST /auth/logout
  /// Logout user (if your backend requires it)
  static Future<ApiResponse> logout() async {
    final res = await ApiClient.post(
      '/auth/logout',
      {},
      token: _authToken,
    );
    return ApiResponse.fromMap(res);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // USER ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════

  /// GET /user/profile
  /// Get current user profile
  static Future<ApiResponse> getProfile() async {
    final res = await ApiClient.get(
      '/user/profile',
      token: _authToken,
    );
    return ApiResponse.fromMap(res);
  }

  /// POST /user/profile
  /// Update user profile
  static Future<ApiResponse> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (phone != null) body['phone'] = phone;
    if (address != null) body['address'] = address;

    final res = await ApiClient.post(
      '/user/profile',
      body,
      token: _authToken,
    );
    return ApiResponse.fromMap(res);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ORDERS ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════

  /// GET /orders
  /// Get all orders for current user
  static Future<ApiResponse> getOrders({
    int page = 1,
    int limit = 10,
    String? status,
  }) async {
    String endpoint = '/orders?page=$page&limit=$limit';
    if (status != null) endpoint += '&status=$status';

    final res = await ApiClient.get(endpoint, token: _authToken);
    return ApiResponse.fromMap(res);
  }

  /// GET /orders/:id
  /// Get single order details
  static Future<ApiResponse> getOrderById(String orderId) async {
    final res = await ApiClient.get(
      '/orders/$orderId',
      token: _authToken,
    );
    return ApiResponse.fromMap(res);
  }

  /// POST /orders
  /// Create new order
  static Future<ApiResponse> createOrder({
    required String type,
    required Map<String, dynamic> details,
  }) async {
    final res = await ApiClient.post(
      '/orders',
      {
        'type': type,
        'details': details,
      },
      token: _authToken,
    );
    return ApiResponse.fromMap(res);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ESTIMATE ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════

  /// POST /estimate/calculate
  /// Calculate estimate
  static Future<ApiResponse> calculateEstimate({
    required double area,
    required String type,
    Map<String, dynamic>? options,
  }) async {
    final res = await ApiClient.post(
      '/estimate/calculate',
      {
        'area': area,
        'type': type,
        if (options != null) 'options': options,
      },
      token: _authToken,
    );
    return ApiResponse.fromMap(res);
  }

  /// POST /estimate/save
  /// Save estimate
  static Future<ApiResponse> saveEstimate({
    required Map<String, dynamic> estimateData,
  }) async {
    final res = await ApiClient.post(
      '/estimate/save',
      estimateData,
      token: _authToken,
    );
    return ApiResponse.fromMap(res);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // PRICING ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════

  /// GET /pricing
  /// Get all pricing info
  static Future<ApiResponse> getPricing() async {
    final res = await ApiClient.get('/pricing', token: _authToken);
    return ApiResponse.fromMap(res);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // OFFERS ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════

  /// GET /offers
  /// Get active offers
  static Future<ApiResponse> getOffers() async {
    final res = await ApiClient.get('/offers', token: _authToken);
    return ApiResponse.fromMap(res);
  }

  /// POST /offers/apply
  /// Apply offer code
  static Future<ApiResponse> applyOffer({
    required String code,
    required String orderId,
  }) async {
    final res = await ApiClient.post(
      '/offers/apply',
      {'code': code, 'orderId': orderId},
      token: _authToken,
    );
    return ApiResponse.fromMap(res);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // FEEDBACK ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════

  /// POST /feedback
  /// Submit feedback
  static Future<ApiResponse> submitFeedback({
    required String message,
    String? type,
  }) async {
    final res = await ApiClient.post(
      '/feedback',
      {
        'message': message,
        if (type != null) 'type': type,
      },
      token: _authToken,
    );
    return ApiResponse.fromMap(res);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GENERIC ENDPOINTS - For custom API calls
  // ═══════════════════════════════════════════════════════════════════════

  /// Generic POST request
  static Future<ApiResponse> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool withRetry = false,
  }) async {
    final res = withRetry
        ? await ApiClient.postWithRetry(endpoint, body, token: _authToken)
        : await ApiClient.post(endpoint, body, token: _authToken);
    return ApiResponse.fromMap(res);
  }

  /// Generic GET request
  static Future<ApiResponse> get(String endpoint) async {
    final res = await ApiClient.get(endpoint, token: _authToken);
    return ApiResponse.fromMap(res);
  }
}
