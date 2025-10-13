import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/chatbot_service.dart';
import '../../services/intervention_service.dart';
import '../../services/chat_message_service.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';

class StudentChatbot extends StatefulWidget {
  const StudentChatbot({super.key});

  @override
  State<StudentChatbot> createState() => _StudentChatbotState();
}

class _StudentChatbotState extends State<StudentChatbot> {
  final List<Map<String, String>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  List<Map<String, dynamic>> _hotlines = const [];
  // Simple abuse protection: cooldown + rolling window cap
  DateTime? _lastSendAt;
  final List<DateTime> _sendTimestamps = [];
  static const Duration _sendCooldown = Duration(seconds: 3);
  static const Duration _windowDuration = Duration(minutes: 10);
  static const int _windowMaxMessages = 15;

  @override
  void initState() {
    super.initState();
    // Seed the chat with an initial gray system message
    _messages.add({
      "sender": "system",
      "text":
          "You are chatting with ${ChatbotService.botName}. Please be respectful and kind. This app offers general support and is not a substitute for professional help. If you're in immediate danger or experiencing a crisis, contact local emergency services or a mental health professional.",
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Cooldown enforcement
    final now = DateTime.now();
    if (_lastSendAt != null && now.difference(_lastSendAt!) < _sendCooldown) {
      final remaining = _sendCooldown - now.difference(_lastSendAt!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Please wait ${remaining.inSeconds}s before sending again.')),
        );
      }
      return;
    }

    // Rolling window cap enforcement
    _sendTimestamps.removeWhere((t) => now.difference(t) > _windowDuration);
    if (_sendTimestamps.length >= _windowMaxMessages) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'You have reached the message limit. Please try again later.')),
        );
      }
      return;
    }
    _sendTimestamps.add(now);
    _lastSendAt = now;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _isLoading = true;
    });

    _controller.clear();

    // Store the user message for intervention analysis
    await ChatMessageService.storeMessage(text, 'user');

    // Check for intervention triggers
    await _checkForIntervention(text);

    try {
      final response = await ChatbotService.generateResponse(text);
      setState(() {
        _messages.add({"sender": "bot", "text": response});
      });

      // Store the bot response
      await ChatMessageService.storeMessage(response, 'bot');
    } catch (e) {
      print('Error getting response: $e');
      setState(() {
        _messages.add({
          "sender": "bot",
          "text":
              "I'm sorry, I'm having trouble responding right now. Please try again later.",
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Checks if the message requires intervention
  Future<void> _checkForIntervention(String message) async {
    try {
      // Analyze the current message
      final messageLevel = InterventionService.analyzeMessage(message);

      // If the message itself is concerning, trigger intervention
      if (messageLevel != InterventionLevel.none) {
        final hasRecent = await InterventionService.hasRecentIntervention();
        if (!hasRecent) {
          await InterventionService.triggerIntervention(messageLevel, message);
          if (messageLevel == InterventionLevel.high) {
            _hotlines = await InterventionService.fetchHotlines(limit: 5);
            if (mounted) _showHighRiskModal();
          }
        }
        return;
      }

      // Analyze recent chat history for patterns
      final historyLevel = await InterventionService.analyzeRecentChatHistory();
      if (historyLevel != InterventionLevel.none) {
        final hasRecent = await InterventionService.hasRecentIntervention();
        if (!hasRecent) {
          await InterventionService.triggerIntervention(historyLevel, message);
          if (historyLevel == InterventionLevel.high) {
            _hotlines = await InterventionService.fetchHotlines(limit: 5);
            if (mounted) _showHighRiskModal();
          }
        }
      }
    } catch (e) {
      print('Error checking for intervention: $e');
    }
  }

  void _showHighRiskModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          title: Text('We are here for you', style: GoogleFonts.poppins()),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'If things feel overwhelming, please reach out now. You can contact your counselor or call a hotline:',
                  style: GoogleFonts.poppins(fontSize: 13),
                ),
                const SizedBox(height: 12),
                ..._hotlines.map((h) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.call,
                              size: 16, color: Color(0xFF7C83FD)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h['name'] ?? 'Hotline',
                                    style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w600)),
                                Text(h['phone'] ?? '',
                                    style: GoogleFonts.poppins(fontSize: 12)),
                                if ((h['city_or_region'] ?? '')
                                    .toString()
                                    .isNotEmpty)
                                  Text(h['city_or_region'],
                                      style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          color: Colors.grey[600])),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.poppins()),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, 'student-counselors');
              },
              child: Text('Contact counselor',
                  style: GoogleFonts.poppins(color: const Color(0xFF7C83FD))),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 242, 241, 248),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF5D5D72)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "BreatheBetter",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: [
          const StudentNotificationButton(),
        ],
      ),
      drawer: const StudentDrawer(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg["sender"] == "user";
                final isSystem = msg["sender"] == "system";
                return Align(
                  alignment:
                      isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 16,
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isSystem
                          ? Colors.grey.shade300
                          : isUser
                              ? const Color(0xFF7C83FD)
                              : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        color: isSystem
                            ? const Color(0xFF3A3A50)
                            : isUser
                                ? Colors.white
                                : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(left: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF7C83FD),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text("Thinking..."),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey.shade400,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                    ),
                    style: GoogleFonts.poppins(),
                    onSubmitted: _sendMessage,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFF7C83FD),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded),
                    color: Colors.white,
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
