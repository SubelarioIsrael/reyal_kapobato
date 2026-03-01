import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _kRenderHealthUrl = 'https://sentiment-app-s691.onrender.com/health';

/// Sends a one-off ping to wake up the Render free-tier server.
/// Call this early (e.g. on home page init) so the server is warm
/// by the time the student actually submits a journal entry.
void warmUpSentimentApi() {
  // Fire-and-forget: ignore errors, we only care about waking the server
  http.get(Uri.parse(_kRenderHealthUrl)).catchError((_) {});
}

/// Starts a periodic ping every 10 minutes to keep the Render free-tier
/// server alive (it spins down after 15 min of inactivity).
/// Returns the [Timer] — cancel it in your controller's dispose().
///
/// Example:
///   _warmupTimer = keepWarmSentimentApi();
///   // in dispose:
///   _warmupTimer?.cancel();
Timer keepWarmSentimentApi() {
  // Fire immediately so the server wakes on first call
  warmUpSentimentApi();
  // Then ping every 10 minutes to beat the 15-min spin-down threshold
  return Timer.periodic(const Duration(minutes: 10), (_) {
    warmUpSentimentApi();
  });
}

Future<Map<String, dynamic>> analyzeSentiment(String text, {bool useAiEnhancement = true}) async {
  try {
    final url = Uri.parse(useAiEnhancement 
      ? "https://sentiment-app-s691.onrender.com/predict-enhanced"
      : "https://sentiment-app-s691.onrender.com/predict");

    // 45-second timeout: covers Render free-tier cold boot (~30-60s).
    // The warm-up ping fired on home page init should have already started
    // the boot process, so real submissions typically complete well within 45s.
    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "text": text,
        if (useAiEnhancement) "use_ai_enhancement": true,
      }),
    ).timeout(
      const Duration(seconds: 45),
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
    'lonely', 'upset', 'angry', 'frustrated', 'overwhelmed', 'tired', 'exhausted',
    'hard', 'drained', 'drain', 'problem', 'problems', 'trouble', 'difficult',
    'struggle', 'struggling', 'terrible', 'awful', 'horrible', 'miserable',
    'pain', 'hurt', 'hurting', 'cry', 'crying', 'lost', 'broken', 'heavy',
    'burden', 'rough', 'tough', 'hell', 'mess', 'dark', 'helpless',
    'powerless', 'numb', 'empty', 'suffocating', 'trapped', 'stuck',
    'hopeless', 'worthless', 'devastated', 'heartbroken', 'hate', 'regret',
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