import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class NotificationApi {
  static String get _serverUrl => dotenv.env['NOTIF_SERVER_URL'] ?? 'http://localhost:8080';
  static String get _authToken => dotenv.env['NOTIF_SERVER_TOKEN'] ?? '';

  // Send a raw payload to the server (internal helper)
  static Future<http.Response> sendRaw(Map<String, dynamic> payload) {
    final url = Uri.parse('$_serverUrl/send');
    return http.post(url, headers: {
      'Content-Type': 'application/json',
      if (_authToken.isNotEmpty) 'x-auth-token': _authToken,
    }, body: json.encode(payload));
  }

  // Send to a single token
  static Future<http.Response> sendToToken(String token, {required String title, required String body, Map<String, String>? data}) {
    final payload = {
      'token': token,
      'notification': {'title': title, 'body': body},
      if (data != null) 'data': data,
    };
    return sendRaw(payload);
  }

  // Send to multiple tokens
  static Future<http.Response> sendToTokens(List<String> tokens, {required String title, required String body, Map<String, String>? data}) {
    final payload = {
      'tokens': tokens,
      'notification': {'title': title, 'body': body},
      if (data != null) 'data': data,
    };
    return sendRaw(payload);
  }

  /// Send notification to a userId (server will lookup tokens)
  static Future<http.Response> sendToUser(String userId, {required String title, required String body, Map<String, String>? data}) {
    final payload = {
      'userId': userId,
      'notification': {'title': title, 'body': body},
      if (data != null) 'data': data,
    };
    return sendRaw(payload);
  }
}
