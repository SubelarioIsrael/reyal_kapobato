import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotService {
  static const String apiKey = 'AIzaSyBwXXzxJ5bI58QKj2gEU533Ov7q61M-QE8';
  static const String apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent';

  static Future<String> generateResponse(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse('$apiUrl?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': '''
Your name is "Eirene". You are a kind and supportive friend. Speak with empathy and a friendly tone, as if you're chatting with someone you care about. 
Keep your responses short and simple unless the situation clearly needs more detail. 
Always aim to make the other person feel heard and supported. 
Give helpful suggestions only if they’re needed or asked for. 
Here’s the message to respond to: $userMessage
'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'topK': 40,
            'topP': 0.95,
            'maxOutputTokens': 1024,
          },
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['candidates'][0]['content']['parts'][0]['text'] as String;
      } else {
        print('API Error: ${response.statusCode} - ${response.body}');
        return 'I apologize, but I\'m having trouble processing your message right now. Please try again later.';
      }
    } catch (e) {
      print('Error generating response: $e');
      return 'I apologize, but I\'m having trouble processing your message right now. Please try again later.';
    }
  }
}
