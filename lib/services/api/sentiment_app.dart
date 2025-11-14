import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>> analyzeSentiment(String text, {bool useAiEnhancement = true}) async {
  try {
    final url = Uri.parse(useAiEnhancement 
      ? "https://sentiment-app-s691.onrender.com/predict-enhanced"
      : "https://sentiment-app-s691.onrender.com/predict");

    // Add timeout to prevent hanging on cold starts (Render free tier)
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "text": text,
        if (useAiEnhancement) "use_ai_enhancement": true,
      }),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        print('Sentiment API timeout - using fallback');
        throw TimeoutException('API timeout');
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data;
    } else if (response.statusCode == 429) {
      // Rate limit exceeded - return fallback
      print('Sentiment API rate limit exceeded (429)');
      return _getFallbackSentiment(text);
    } else {
      print('Sentiment API error: ${response.statusCode}');
      return _getFallbackSentiment(text);
    }
  } catch (e) {
    print('Exception calling sentiment API: $e');
    return _getFallbackSentiment(text);
  }
}

// Fallback sentiment analysis using keyword matching
Map<String, dynamic> _getFallbackSentiment(String text) {
  final lowerText = text.toLowerCase();
  
  // High-risk keywords
  final highRiskKeywords = [
    'suicide', 'kill myself', 'end my life', 'want to die', 'better off dead',
    'no reason to live', 'can\'t go on', 'hopeless', 'worthless'
  ];
  
  // Negative keywords
  final negativeKeywords = [
    'sad', 'depressed', 'anxious', 'stressed', 'worried', 'scared', 'afraid',
    'lonely', 'upset', 'angry', 'frustrated', 'overwhelmed', 'tired', 'exhausted'
  ];
  
  // Positive keywords
  final positiveKeywords = [
    'happy', 'joyful', 'excited', 'grateful', 'thankful', 'blessed', 'content',
    'peaceful', 'calm', 'relaxed', 'confident', 'proud', 'motivated', 'hopeful'
  ];
  
  // Check for high risk
  if (highRiskKeywords.any((keyword) => lowerText.contains(keyword))) {
    return {
      'sentiment': 'negative',
      'thought': 'We noticed you might be going through a difficult time. Please consider reaching out to a counselor or crisis hotline for support.',
    };
  }
  
  // Count keyword occurrences
  int negativeCount = negativeKeywords.where((k) => lowerText.contains(k)).length;
  int positiveCount = positiveKeywords.where((k) => lowerText.contains(k)).length;
  
  String sentiment;
  String thought;
  
  if (positiveCount > negativeCount) {
    sentiment = 'positive';
    thought = 'It sounds like you\'re experiencing positive emotions. Keep nurturing these feelings!';
  } else if (negativeCount > positiveCount) {
    sentiment = 'negative';
    thought = 'It seems like you\'re facing some challenges. Remember, it\'s okay to seek support when you need it.';
  } else {
    sentiment = 'neutral';
    thought = 'Thank you for sharing your thoughts. Journaling is a great way to process your feelings.';
  }
  
  return {
    'sentiment': sentiment,
    'thought': thought,
  };
}

class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);
}

// Legacy method for backward compatibility
Future<Map<String, dynamic>> analyzeSentimentBasic(String text) async {
  return analyzeSentiment(text, useAiEnhancement: false);
}

// Enhanced method with detailed analysis
Future<Map<String, dynamic>> analyzeSentimentEnhanced(String text) async {
  return analyzeSentiment(text, useAiEnhancement: true);
}