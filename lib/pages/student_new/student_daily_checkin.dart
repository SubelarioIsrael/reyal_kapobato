import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../controllers/student_daily_checkin_controller.dart';

class StudentDailyCheckinNew extends StatefulWidget {
  const StudentDailyCheckinNew({Key? key}) : super(key: key);

  @override
  State<StudentDailyCheckinNew> createState() => _StudentDailyCheckinNewState();
}

class _StudentDailyCheckinNewState extends State<StudentDailyCheckinNew> {
  final controller = StudentDailyCheckinController();
  int _selectedIndex = 2;

  @override
  void initState() {
    super.initState();
    controller.init();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, 'student-breathing-exercises');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, 'student-home');
        break;
      case 2:
        break;
    }
  }

  Future<void> _handleSubmit() async {
    final result = await controller.submitCheckIn();
    
    if (!mounted) return;

    if (result['success']) {
      _showSuccessDialog(result['message']);
    } else {
      _showErrorDialog(result['message']);
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    color: Colors.red.shade700,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Error',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            width: 300,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle_outline,
                    color: Colors.green.shade700,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Success!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF5D5D72),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Summary will be displayed automatically by ValueListenableBuilder
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
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
          "Daily Mood Check-In",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF3A3A50),
          ),
        ),
        centerTitle: true,
        actions: const [
          StudentNotificationButton(),
        ],
      ),
      drawer: const StudentDrawer(),
      body: ValueListenableBuilder<bool>(
        valueListenable: controller.isComplete,
        builder: (context, isComplete, child) {
          return ValueListenableBuilder<Map<String, dynamic>?>(
            valueListenable: controller.todayCheckIn,
            builder: (context, todayCheckIn, child) {
              if (isComplete && todayCheckIn != null) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildSummary(todayCheckIn),
                );
              }
              return SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: _buildStepper(),
                ),
              );
            },
          );
        },
      ),
      
    );
  }

  Widget _buildStepper() {
    return ValueListenableBuilder<int>(
      valueListenable: controller.currentStep,
      builder: (context, step, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (step == 0) ..._buildMoodStep(),
            if (step == 1) ..._buildReasonsStep(),
          ],
        );
      },
    );
  }

  List<Widget> _buildMoodStep() {
    return [
      const SizedBox(height: 20),
      Text(
        "What's your mood today?",
        style: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF3A3A50),
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      Text(
        "Select the mood that reflects how you're feeling at this moment",
        style: GoogleFonts.poppins(
          fontSize: 16,
          color: const Color(0xFF5D5D72),
        ),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 40),
      ValueListenableBuilder<String?>(
        valueListenable: controller.moodType,
        builder: (context, selectedMood, child) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: controller.moodOptions.map((mood) {
                final isSelected = selectedMood == mood['type'];
                return GestureDetector(
                  onTap: () => controller.selectMood(mood['type']!, mood['emoji']!),
                  child: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? const Color(0xFF7C83FD) 
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: isSelected 
                            ? const Color(0xFF7C83FD) 
                            : Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        mood['emoji']!,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
      const SizedBox(height: 50),
      ValueListenableBuilder<String?>(
        valueListenable: controller.moodType,
        builder: (context, selectedMood, child) {
          return SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: selectedMood == null ? null : controller.nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C83FD),
                disabledBackgroundColor: Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: Text(
                'Continue',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          );
        },
      ),
    ];
  }

  List<Widget> _buildReasonsStep() {
    return [
      Expanded(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 20),
              ValueListenableBuilder<String?>(
                valueListenable: controller.moodType,
                builder: (context, mood, child) {
                  return Text(
                    "What's making you feel ${mood != null ? controller.capitalizeString(mood) : ''}?",
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 12),
              Text(
                "Select at least one reason *",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: const Color(0xFF5D5D72),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ValueListenableBuilder<List<String>>(
                valueListenable: controller.reasons,
                builder: (context, selectedReasons, child) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reasons',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: controller.reasonOptions.map((reason) {
                            final selected = selectedReasons.contains(reason);
                            return FilterChip(
                              label: Text(reason),
                              selected: selected,
                              onSelected: (val) => controller.toggleReason(reason),
                              backgroundColor: Colors.grey[100],
                              selectedColor: const Color(0xFF7C83FD).withOpacity(0.1),
                              checkmarkColor: const Color(0xFF7C83FD),
                              labelStyle: GoogleFonts.poppins(
                                color: selected ? const Color(0xFF7C83FD) : const Color(0xFF5D5D72),
                                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                              ),
                              side: BorderSide(
                                color: selected ? const Color(0xFF7C83FD) : Colors.grey[300]!,
                              ),
                            );
                          }).toList(),
                        ),
                        if (selectedReasons.contains('Other')) ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: controller.otherReasonController,
                            decoration: InputDecoration(
                              labelText: 'Specify your reason *',
                              labelStyle: GoogleFonts.poppins(
                                color: const Color(0xFF5D5D72),
                                fontSize: 14,
                              ),
                              hintText: "What else is affecting your mood?",
                              hintStyle: GoogleFonts.poppins(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFF7C83FD)),
                              ),
                              contentPadding: const EdgeInsets.all(16),
                            ),
                            style: GoogleFonts.poppins(),
                            maxLength: 50,
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add a note (optional)',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: controller.noteController,
                      decoration: InputDecoration(
                        hintText: "Tell us more about how you're feeling...",
                        hintStyle: GoogleFonts.poppins(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF7C83FD)),
                        ),
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      maxLines: 3,
                      style: GoogleFonts.poppins(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      ValueListenableBuilder<bool>(
        valueListenable: controller.isSubmitting,
        builder: (context, isSubmitting, child) {
          return ValueListenableBuilder<String?>(
            valueListenable: controller.moodType,
            builder: (context, mood, child) {
              return ValueListenableBuilder<List<String>>(
                valueListenable: controller.reasons,
                builder: (context, reasons, child) {
                  return Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: OutlinedButton(
                            onPressed: controller.previousStep,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF7C83FD)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              'Back',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C83FD),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: ElevatedButton(
                            onPressed: isSubmitting || mood == null || reasons.isEmpty 
                                ? null 
                                : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              disabledBackgroundColor: Colors.grey[300],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    'Submit',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    ];
  }

  Widget _buildSummary(Map<String, dynamic> checkIn) {
    final emoji = checkIn['emoji_code'] ?? '';
    final mood = checkIn['mood_type'] ?? '';
    final reasonsList = (checkIn['reasons'] as List?)?.cast<String>() ?? [];
    final notes = checkIn['notes'] ?? '';

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFF7C83FD).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Center(
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Daily Check-in Complete!',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'You felt ${controller.capitalizeString(mood)}',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF5D5D72),
                ),
                textAlign: TextAlign.center,
              ),
              if (reasonsList.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reasons:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: reasonsList.map((reason) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7C83FD).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: const Color(0xFF7C83FD).withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              reason,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF7C83FD),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
              if (notes.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[300]!,
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your note:',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(minHeight: 80),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          notes,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF5D5D72),
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF7C83FD).withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle_outline,
                color: Color(0xFF7C83FD),
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                'Thanks for checking in today!',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF7C83FD),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Come back tomorrow to track your mood again.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // View History button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, 'student-checkin-history'),
            icon: const Icon(Icons.history, color: Color(0xFF7C83FD)),
            label: Text(
              'View Check-in History',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF7C83FD),
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Color(0xFF7C83FD), width: 2),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Back to Home button
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushReplacementNamed(context, 'student-home'),
            icon: const Icon(Icons.home, color: Colors.white),
            label: Text(
              'Return to Home',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FD),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }
}
