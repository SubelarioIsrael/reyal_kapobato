import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> analyzeSentiment(String text, {bool useAiEnhancement = true}) async {
  try {
    final url = Uri.parse(useAiEnhancement 
      ? "https://sentiment-app-s691.onrender.com/predict-enhanced"
      : "https://sentiment-app-s691.onrender.com/predict");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "text": text,
        if (useAiEnhancement) "use_ai_enhancement": true,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 429) {
      // Rate limit exceeded - return empty map to trigger fallback
      print('Sentiment API rate limit exceeded (429)');
      return {};
    } else {
      print('Sentiment API error: ${response.statusCode}');
      return {};
    }
  } catch (e) {
    print('Exception calling sentiment API: $e');
    return {};
  }
}

// Legacy method for backward compatibility
Future<Map<String, dynamic>> analyzeSentimentBasic(String text) async {
  return analyzeSentiment(text, useAiEnhancement: false);
}

// Enhanced method with detailed analysis
Future<Map<String, dynamic>> analyzeSentimentEnhanced(String text) async {
  return analyzeSentiment(text, useAiEnhancement: true);
}