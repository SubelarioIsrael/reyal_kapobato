import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> analyzeSentiment(String text) async {
  final url = Uri.parse("https://sentiment-app-s691.onrender.com/predict");

  final response = await http.post(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({"text": text}),
  );

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return data;
  } else {
    throw Exception("Error: ${response.statusCode} - ${response.body}");
  }
}