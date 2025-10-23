import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../services/activity_service.dart';

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
  bool _isLoading = true;
  List<Map<String, dynamic>> _exercises = [];

  final double _minCircleSize = 200.0;
  final double _maxCircleSize = 300.0;

  int _selectedIndex = 0; // Set initial index to Breathing Exercises (index 0)

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _loadExercises();
  }

  @override
  void dispose() {
    _stopExercise();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    try {
      final response = await Supabase.instance.client
          .from('breathing_exercises')
          .select()
          .order('name');

      if (mounted) {
        setState(() {
          _exercises = (response as List)
              .map((exercise) => {
                    ...(exercise as Map<String, dynamic>),
                    'color': _getColorFromHex(exercise['color_hex']),
                    'icon': _getIconFromName(exercise['icon_name']),
                  })
              .toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading exercises. Please try again later.'),
          ),
        );
      }
    }
  }

  Color _getColorFromHex(String hexColor) {
    hexColor = hexColor.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }

  IconData _getIconFromName(String iconName) {
    switch (iconName) {
      case 'air':
        return Icons.air;
      case 'square_outlined':
        return Icons.square_outlined;
      case 'waves':
        return Icons.waves;
      default:
        return Icons.self_improvement;
    }
  }

  void _startExercise(Map<String, dynamic> exercise) {
    // Reset all states before starting new exercise
    _stopExercise();

    setState(() {
      _remainingSeconds = exercise['duration'];
      _isExerciseActive = true;
    });

    showDialog(
      // Keep the dialog before starting the exercise view
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
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _isExerciseActive = false;
              }); // Go back to list if cancelled
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runBreathingPattern(
                  exercise['pattern']); // Start pattern after dialog
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

  void _runBreathingPattern(Map<String, dynamic> pattern) {
    int totalCycleDuration = 0;
    pattern.forEach((key, value) => totalCycleDuration += value as int);

    // Always use the correct phase order
    final phaseOrder = ['inhale', 'hold', 'exhale', 'hold2'];
    final phases = <MapEntry<String, dynamic>>[];
    for (final phase in phaseOrder) {
      if (pattern.containsKey(phase)) {
        phases.add(MapEntry(phase, pattern[phase]));
      } else if (phase == 'hold2' && pattern.containsKey('hold')) {
        // If hold2 is not present but hold is, use hold duration for hold2
        phases.add(MapEntry('hold2', pattern['hold']));
      }
    }
    int currentPhaseIndex = 0;

    void startPhase(int index) {
      if (!_isExerciseActive) return;
      if (index >= phases.length) {
        currentPhaseIndex = 0;
        startPhase(0); // Loop the pattern
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
          _animationController.stop(); // Stop animation for hold phases
        }
      });
    }

    // Start the first phase
    startPhase(0);

    // Update main timer every second
    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        _stopExercise();
        // Record activity completion
        ActivityService.recordActivityCompletion('breathing_exercise');
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
                  // Stay on the breathing exercises page after completing the exercise
                  setState(() {
                    _isExerciseActive = false;
                  }); // Go back to the exercise list
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    switch (index) {
      case 0: // Breathing Exercises
        // Stay on this page
        break;
      case 1: // Home
        Navigator.pushReplacementNamed(context, 'student-home');
        break;
      case 2: // Track Mood (Daily Check-in)
        Navigator.pushReplacementNamed(context, '/student-daily-checkin');
        break;
    }
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
        actions: [
          const StudentNotificationButton(),
        ],
      ),
      drawer: const StudentDrawer(),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isExerciseActive
                ? _buildExerciseView()
                : _buildExerciseList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFF7C83FD), // Adjust color as needed
        unselectedItemColor: const Color(0xFFB0B0C3), // Adjust color as needed
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.self_improvement), // Breathing Exercises Icon
              label: 'Breathing Exercises'),
          BottomNavigationBarItem(
              icon: Icon(Icons.home), // Home Icon
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(
                  Icons.emoji_emotions), // Track Mood Icon (Daily Check-in)
              label: 'Track Mood'),
        ],
      ),
    );
  }

  Widget _buildExerciseView() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.close), // Use close icon to stop exercise
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

  Widget _buildBreathingCircle() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        double size;
        // Animation logic based on phase
        if (_currentPhase == 'inhale') {
          size = _minCircleSize +
              (_maxCircleSize - _minCircleSize) * _animationController.value;
        } else if (_currentPhase == 'exhale') {
          size = _maxCircleSize -
              (_maxCircleSize - _minCircleSize) *
                  (1 - _animationController.value);
        } else if (_currentPhase == 'hold2') {
          // After exhale, for hold2, maintain the minimum size
          size = _minCircleSize;
        } else {
          // For the first hold phase, keep the size from the end of inhale (max size)
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
                      _currentPhase == 'hold2'
                          ? 'HOLD'
                          : _currentPhase.toUpperCase(),
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
                    else if (_currentPhase == 'hold' ||
                        _currentPhase == 'hold2')
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
          Text(
            'Choose an exercise to begin:',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _exercises.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
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
                          onTap: () => _startExercise(
                              exercise), // Call _startExercise here
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
