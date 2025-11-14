import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/student_breathing_exercises_controller.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';

class StudentBreathingExercises extends StatefulWidget {
  const StudentBreathingExercises({super.key});

  @override
  State<StudentBreathingExercises> createState() =>
      _StudentBreathingExercisesState();
}

class _StudentBreathingExercisesState extends State<StudentBreathingExercises>
    with SingleTickerProviderStateMixin {
  final StudentBreathingExercisesController _controller =
      StudentBreathingExercisesController();
  late AnimationController _animationController;

  static const double _minCircleSize = 200;
  static const double _maxCircleSize = 300;
  
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _controller.setAnimationController(_animationController);
    _controller.init();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _startExercise(Map<String, dynamic> exercise) {
    _controller.stopExercise();

    _controller.remainingSeconds.value = exercise['duration'];
    _controller.isExerciseActive.value = true;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF7C83FD).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.play_circle_outline,
                color: Color(0xFF7C83FD),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Start ${exercise['name']}?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'This exercise will take ${exercise['duration'] ~/ 60} minutes. Find a comfortable position and make sure you won\'t be disturbed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _controller.isExerciseActive.value = false;
                    },
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C83FD),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _controller.runBreathingPattern(exercise['pattern']);
                    },
                    child: Text(
                      'Begin',
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
          ],
        ),
      ),
    );
  }

  void _showStopDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                color: Colors.orange,
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Stop Exercise?',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to stop the exercise?',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Continue',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _controller.stopExercise();
                    },
                    child: Text(
                      'Stop',
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
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0:
        break;
      case 1:
        Navigator.pushReplacementNamed(context, 'student-home');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/student-daily-checkin');
        break;
    }
  }

  Widget _buildExerciseView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: _showStopDialog,
              ),
              const SizedBox(width: 16),
              ValueListenableBuilder<int>(
                valueListenable: _controller.remainingSeconds,
                builder: (context, seconds, child) {
                  if (seconds <= 0 && _controller.isExerciseActive.value) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.all(24),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Exercise Complete!',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Great job! You\'ve completed your breathing exercise.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF5D5D72),
                                ),
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF7C83FD),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _controller.isExerciseActive.value = false;
                                  },
                                  child: Text(
                                    'Done',
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
                    });
                  }
                  return Text(
                    'Time Remaining: ${_controller.formatDuration(seconds)}',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: _buildBreathingCircle(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreathingCircle() {
    return ValueListenableBuilder<String>(
      valueListenable: _controller.currentPhase,
      builder: (context, phase, child) {
        return AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            double size;
            if (phase == 'inhale') {
              size = _minCircleSize +
                  (_maxCircleSize - _minCircleSize) * _animationController.value;
            } else if (phase == 'exhale') {
              size = _maxCircleSize -
                  (_maxCircleSize - _minCircleSize) *
                      (1 - _animationController.value);
            } else if (phase == 'hold2') {
              size = _minCircleSize;
            } else {
              size = _maxCircleSize;
            }

            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF7C83FD).withOpacity(0.2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          phase == 'hold2' ? 'HOLD' : phase.toUpperCase(),
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF7C83FD),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<int>(
                          valueListenable: _controller.phaseSecondsLeft,
                          builder: (context, seconds, child) {
                            return phase.isNotEmpty
                                ? Text(
                                    '$seconds s',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF7C83FD),
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 8),
                        if (phase == 'inhale')
                          Text(
                            'Breathe in through nose',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF7C83FD),
                            ),
                          )
                        else if (phase == 'exhale')
                          Text(
                            'Breathe out through mouth',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF7C83FD),
                            ),
                          )
                        else if (phase == 'hold' || phase == 'hold2')
                          Text(
                            'Hold your breath',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF7C83FD),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildExerciseList() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose an exercise to begin:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _controller.exercises,
              builder: (context, exercises, child) {
                if (exercises.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.self_improvement,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No exercises available',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Check back later for new exercises',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = exercises[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: exercise['color'],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Icon(
                          exercise['icon'],
                          size: 32,
                          color: Colors.white,
                        ),
                        title: Text(
                          exercise['name'],
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        subtitle: Text(
                          exercise['description'],
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: const Color(0xFF3A3A50),
                          ),
                        ),
                        trailing: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                        ),
                        onTap: () => _startExercise(exercise),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
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
          "Breathing Exercises",
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
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: _controller.isLoading,
          builder: (context, isLoading, child) {
            if (isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ValueListenableBuilder<bool>(
              valueListenable: _controller.isExerciseActive,
              builder: (context, isActive, child) {
                return isActive ? _buildExerciseView() : _buildExerciseList();
              },
            );
          },
        ),
      ),
      
    );
  }
}
