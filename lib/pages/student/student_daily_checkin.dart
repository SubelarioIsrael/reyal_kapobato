import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentDailyCheckInPage extends StatefulWidget {
  const StudentDailyCheckInPage({Key? key}) : super(key: key);

  @override
  State<StudentDailyCheckInPage> createState() =>
      _StudentDailyCheckInPageState();
}

class _StudentDailyCheckInPageState extends State<StudentDailyCheckInPage> {
  int step = 0;
  String? moodType;
  String? emojiCode;
  List<String> reasons = [];
  TextEditingController noteController = TextEditingController();
  bool isSubmitting = false;
  bool isComplete = false;
  Map<String, dynamic>? todayCheckIn;

  final moodOptions = [
    {'type': 'angry', 'emoji': '😡'},
    {'type': 'sad', 'emoji': '😔'},
    {'type': 'neutral', 'emoji': '😐'},
    {'type': 'happy', 'emoji': '😃'},
    {'type': 'loved', 'emoji': '🥰'},
  ];
  final reasonOptions = ['Relationship', 'School', 'Friend', 'Work', 'Family'];

  @override
  void initState() {
    super.initState();
    _fetchTodayCheckIn();
  }

  Future<void> _fetchTodayCheckIn() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    final today = DateTime.now();
    final response = await Supabase.instance.client
        .from('mood_entries')
        .select()
        .eq('user_id', userId)
        .eq('entry_date',
            "${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}")
        .maybeSingle();
    setState(() {
      todayCheckIn = response;
      isComplete = response != null;
    });
  }

  Future<void> _submitCheckIn() async {
    setState(() => isSubmitting = true);
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;
    await Supabase.instance.client.from('mood_entries').insert({
      'user_id': userId,
      'mood_type': moodType,
      'emoji_code': emojiCode,
      'reasons': reasons,
      'notes': noteController.text,
    });
    setState(() {
      isSubmitting = false;
      isComplete = true;
    });
    await _fetchTodayCheckIn();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daily Mood Check-in'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isComplete && todayCheckIn != null
            ? _buildSummary()
            : _buildStepper(),
      ),
    );
  }

  Widget _buildStepper() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (step == 0) ...[
          Text(
            "What's your mood Today?",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Select mood reflects the most how you are feeling at this moment",
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: moodOptions.map((mood) {
              return GestureDetector(
                onTap: () {
                  setState(() {
                    moodType = mood['type'];
                    emojiCode = mood['emoji'];
                  });
                },
                child: CircleAvatar(
                  backgroundColor: moodType == mood['type']
                      ? Colors.green
                      : Colors.grey[200],
                  radius: 28,
                  child: Text(
                    mood['emoji']!,
                    style: TextStyle(
                      fontSize: 32,
                      color: moodType == mood['type']
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: moodType == null ? null : () => setState(() => step = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(double.infinity, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Continue', style: TextStyle(color: Colors.white)),
          ),
        ] else if (step == 1) ...[
          Text(
            "Choose the reason why you feel ${moodType?.capitalize() ?? ''}",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            "Select a reason",
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: reasonOptions.map((reason) {
              final selected = reasons.contains(reason);
              return ChoiceChip(
                label: Text(reason),
                selected: selected,
                selectedColor: Colors.green,
                onSelected: (val) {
                  setState(() {
                    if (selected) {
                      reasons.remove(reason);
                    } else {
                      reasons.add(reason);
                    }
                  });
                },
              );
            }).toList(),
          ),
          SizedBox(height: 24),
          TextField(
            controller: noteController,
            decoration: InputDecoration(
              labelText: "Note:",
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            maxLines: 3,
          ),
          Spacer(),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => step = 0),
                  child: Text('Back'),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed:
                      reasons.isEmpty || isSubmitting ? null : _submitCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: isSubmitting
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Add Mood', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ]
      ],
    );
  }

  Widget _buildSummary() {
    final emoji = todayCheckIn!['emoji_code'] ?? '';
    final mood = todayCheckIn!['mood_type'] ?? '';
    final reasonsStr = (todayCheckIn!['reasons'] as List?)?.join(', ') ?? '';
    final notes = todayCheckIn!['notes'] ?? '';
    final time =
        todayCheckIn!['entry_timestamp']?.toString().substring(11, 16) ?? '';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: 40),
        Text(
          '$emoji $mood'.capitalize(),
          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 8),
        Text('at $time',
            style: TextStyle(fontSize: 16, color: Colors.grey[700])),
        SizedBox(height: 16),
        if (reasonsStr.isNotEmpty)
          Text('Because of $reasonsStr',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        if (notes.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Text('"$notes"',
                style: TextStyle(
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[800])),
          ),
        SizedBox(height: 40),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            minimumSize: Size(double.infinity, 48),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text('Back to Home', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

extension StringCasingExtension on String {
  String capitalize() =>
      this.isNotEmpty ? "${this[0].toUpperCase()}${substring(1)}" : "";
}
