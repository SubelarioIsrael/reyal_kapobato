import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

class StudentBreathingExercises extends StatefulWidget {
  const StudentBreathingExercises({super.key});

  @override
  State<StudentBreathingExercises> createState() =>
      _StudentBreathingExercisesState();
}

class _StudentBreathingExercisesState extends State<StudentBreathingExercises>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExerciseActive = false;
  Timer? _exerciseTimer;
  Timer? _phaseTimer;
  int _remainingSeconds = 0;
  int _phaseSecondsLeft = 0;
  String _currentPhase = '';
  double _currentCircleSize = 200.0;

  final double _minCircleSize = 200.0;
  final double _maxCircleSize = 300.0;

  final List<Map<String, dynamic>> _exercises = [
    {
      'name': '4-7-8 Breathing',
      'description':
          'Inhale for 4 seconds, hold for 7 seconds, exhale for 8 seconds',
      'color': Colors.blue.shade100,
      'icon': Icons.air,
      'duration': 180, // 3 minutes
      'pattern': {
        'inhale': 4,
        'hold': 7,
        'exhale': 8,
      },
    },
    {
      'name': 'Box Breathing',
      'description': 'Inhale, hold, exhale, and hold again, each for 4 seconds',
      'color': Colors.green.shade100,
      'icon': Icons.square_outlined,
      'duration': 240, // 4 minutes
      'pattern': {
        'inhale': 4,
        'hold': 4,
        'exhale': 4,
        'hold2': 4,
      },
    },
    {
      'name': 'Deep Breathing',
      'description':
          'Simple deep breaths - inhale for 5 seconds, exhale for 5 seconds',
      'color': Colors.purple.shade100,
      'icon': Icons.waves,
      'duration': 300, // 5 minutes
      'pattern': {
        'inhale': 5,
        'exhale': 5,
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
  }

  @override
  void dispose() {
    _stopExercise();
    _animationController.dispose();
    super.dispose();
  }

  void _startExercise(Map<String, dynamic> exercise) {
    // Reset all states before starting new exercise
    _stopExercise();

    setState(() {
      _remainingSeconds = exercise['duration'];
    });

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Start ${exercise['name']}?',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'This exercise will take ${exercise['duration'] ~/ 60} minutes. Find a comfortable position and make sure you won\'t be disturbed.',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _beginExercise(exercise);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FD),
            ),
            child: Text(
              'Begin',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _beginExercise(Map<String, dynamic> exercise) {
    // Reset all states before starting
    _stopExercise();

    setState(() {
      _isExerciseActive = true;
      _remainingSeconds = exercise['duration'];
      _currentPhase = '';
      _phaseSecondsLeft = 0;
    });
    _runBreathingPattern(exercise['pattern']);
  }

  void _runBreathingPattern(Map<String, dynamic> pattern) {
    int totalCycleDuration = 0;
    pattern.forEach((key, value) => totalCycleDuration += value as int);

    List<MapEntry<String, dynamic>> phases = pattern.entries.toList();
    int currentPhaseIndex = 0;

    void startPhase(int index) {
      if (!_isExerciseActive) return;
      if (index >= phases.length) {
        currentPhaseIndex = 0;
        startPhase(0);
        return;
      }

      var phase = phases[index];
      setState(() {
        _currentPhase = phase.key;
        _phaseSecondsLeft = phase.value as int;

        // Set up animation based on phase
        _animationController.duration = Duration(seconds: phase.value as int);
        if (phase.key == 'inhale') {
          _animationController.forward(from: 0);
        } else if (phase.key == 'exhale') {
          _animationController.reverse(from: 1);
        } else {
          // For hold phases, keep the current size
          _animationController.stop();
        }
      });
    }

    // Start the first phase
    startPhase(0);

    // Update main timer every second
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _stopExercise();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Exercise Complete!',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Great job! You\'ve completed your breathing exercise.',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                ),
                child: Text(
                  'Done',
                  style: GoogleFonts.poppins(color: Colors.white),
                ),
              ),
            ],
          ),
        );
        return;
      }

      setState(() {
        _remainingSeconds--;
        _phaseSecondsLeft--;

        // Check if current phase is complete
        if (_phaseSecondsLeft <= 0) {
          currentPhaseIndex = (currentPhaseIndex + 1) % phases.length;
          startPhase(currentPhaseIndex);
        }
      });
    });
  }

  void _stopExercise() {
    setState(() {
      _isExerciseActive = false;
      _currentPhase = '';
      _phaseSecondsLeft = 0;
      _remainingSeconds = 0;
    });
    _exerciseTimer?.cancel();
    _phaseTimer?.cancel();
    _animationController.reset();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      body: SafeArea(
        child: _isExerciseActive ? _buildExerciseView() : _buildExerciseList(),
      ),
    );
  }

  Widget _buildExerciseView() {
    if (!_isExerciseActive) {
      return Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Get Ready',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Instructions:',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '1. Find a comfortable position\n'
              '2. Close your eyes or maintain a soft gaze\n'
              '3. Follow the breathing pattern shown on screen\n'
              '4. Breathe in through your nose\n'
              '5. Breathe out through your mouth',
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.8,
                color: const Color(0xFF5D5D72),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isExerciseActive = true;
                    _startBreathing();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C83FD),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Start Exercise',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(
                        'Stop Exercise?',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      content: Text(
                        'Are you sure you want to stop the exercise?',
                        style: GoogleFonts.poppins(fontSize: 16),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Continue',
                            style: GoogleFonts.poppins(color: Colors.grey),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _stopExercise();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C83FD),
                          ),
                          child: Text(
                            'Stop',
                            style: GoogleFonts.poppins(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 16),
              Text(
                'Time Remaining: ${_formatDuration(_remainingSeconds)}',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
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

  void _startBreathing() {
    // Reset all states before starting
    _stopExercise();

    final currentExercise = _exercises.firstWhere(
      (exercise) => exercise['duration'] == _remainingSeconds,
      orElse: () => _exercises[0], // Default to first exercise if none found
    );
    setState(() {
      _remainingSeconds = currentExercise['duration'];
    });
    _runBreathingPattern(currentExercise['pattern']);
  }

  Widget _buildBreathingCircle() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double size;
        if (_currentPhase == 'inhale') {
          size = _minCircleSize +
              (_maxCircleSize - _minCircleSize) * _animationController.value;
        } else if (_currentPhase == 'exhale') {
          size = _maxCircleSize -
              (_maxCircleSize - _minCircleSize) *
                  (1 - _animationController.value);
        } else {
          // For hold phases, maintain the size from the last inhale
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
                      _currentPhase.toUpperCase(),
                      style: GoogleFonts.poppins(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF7C83FD),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_currentPhase.isNotEmpty)
                      Text(
                        '$_phaseSecondsLeft s',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF7C83FD),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (_currentPhase == 'inhale')
                      Text(
                        'Breathe in through nose',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF7C83FD),
                        ),
                      )
                    else if (_currentPhase == 'exhale')
                      Text(
                        'Breathe out through mouth',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF7C83FD),
                        ),
                      )
                    else if (_currentPhase == 'hold')
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
  }

  Widget _buildExerciseList() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF3A3A50),
                  size: 26,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Breathing Exercises',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Choose an exercise to begin:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
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
                      color: Color(0xFF7C83FD),
                    ),
                    onTap: () => _startExercise(exercise),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
