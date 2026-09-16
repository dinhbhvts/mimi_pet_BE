import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/config/api_config.dart';

/// Lỗi gọi API backend - [statusCode] cho phép caller phân biệt rõ nguyên
/// nhân (401 hết hạn đăng nhập, 429 gọi quá nhanh, 503 server chưa cấu hình
/// Gemini...) thay vì chỉ 1 thông báo lỗi chung chung.
class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => 'ApiException($statusCode, $message)';
}

/// Wrapper mỏng quanh package `http` (đã dùng sẵn cho Gemini - cùng cách gọi
/// như `gemini_chat_service.dart` trước đây) - tự thêm base URL
/// ([ApiConfig.baseUrl]) + JWT Authorization header + decode JSON, dùng
/// chung cho [AuthService]/[CloudStateStore]/`GeminiChatService`/
/// `GeminiDictionaryService`. Chỉ 1 instance DUY NHẤT được tạo ở `app.dart`
/// (đăng ký làm Provider) và chia sẻ cho mọi service cần gọi backend.
class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  String? _token;

  /// [AuthService] gọi hàm này mỗi khi đăng nhập/đăng xuất để MỌI request
  /// tiếp theo (kể cả từ các service khác dùng chung instance này) tự động
  /// kèm đúng token hiện tại.
  void setToken(String? token) => _token = token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, dynamic>> getJson(String path) async {
    final res = await _client.get(_uri(path), headers: _headers).timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Future<Map<String, dynamic>> postJson(String path, Map<String, dynamic> body) async {
    final res = await _client
        .post(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 25));
    return _decode(res);
  }

  Future<Map<String, dynamic>> putJson(String path, Map<String, dynamic> body) async {
    final res = await _client
        .put(_uri(path), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 15));
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      body = const {};
    }
    if (res.statusCode < 200 || res.statusCode >= 300) {
      final message = body['detail']?.toString() ?? 'HTTP ${res.statusCode}';
      throw ApiException(res.statusCode, message);
    }
    return body;
  }

  void dispose() => _client.close();
}
