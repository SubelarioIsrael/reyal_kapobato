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
  late Animation<double> _breathAnimation;

  // Responsive sizes computed in _buildBreathingCircle via MediaQuery
  static const double _minCircleFraction = 0.38; // 38% of screen width
  static const double _maxCircleFraction = 0.72; // 72% of screen width

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _breathAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _controller.setAnimationController(_animationController);
    _controller.init();
  }

  Color _getPhaseColor(String phase) {
    switch (phase) {
      case 'inhale':  return const Color(0xFF7C83FD);
      case 'hold':    return const Color(0xFF5B6AF5);
      case 'exhale':  return const Color(0xFF46B5C7);
      case 'hold2':   return const Color(0xFF8E97FD);
      default:        return const Color(0xFF7C83FD);
    }
  }

  String _getPhaseInstruction(String phase) {
    switch (phase) {
      case 'inhale':  return 'Breathe in through your nose';
      case 'hold':    return 'Hold your breath';
      case 'exhale':  return 'Breathe out through your mouth';
      case 'hold2':   return 'Hold your breath';
      default:        return '';
    }
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

    final Color cardColor = exercise['color'] as Color;
    final pattern = exercise['pattern'] as Map<String, dynamic>;
    final phaseOrder = ['inhale', 'hold', 'exhale', 'hold2'];
    final phases = phaseOrder.where((p) => pattern.containsKey(p)).toList();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Exercise icon
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.14),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(exercise['icon'] as IconData, color: cardColor, size: 40),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    exercise['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    exercise['description'],
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[600], height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  // Pattern visual guide
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5FB),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'How it works',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.center,
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(phases.length, (i) {
                            final p = phases[i];
                            final pColor = _getPhaseColor(p);
                            final label = p == 'hold2' ? 'HOLD' : p.toUpperCase();
                            final secs = pattern[p];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: pColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.85),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  Text(
                                    '$secs s',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Duration badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.timer_outlined, size: 13, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          '${exercise['duration'] ~/ 60} min session · Find a comfortable position',
                          style: GoogleFonts.poppins(fontSize: 11, color: Colors.grey[500]),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _controller.isExerciseActive.value = false;
                          },
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: cardColor,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                            _controller.runBreathingPattern(exercise['pattern']);
                          },
                          child: Text(
                            'Begin',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
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
          ),
        );
      },
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

  Widget _buildPhaseProgressBar() {
    return ValueListenableBuilder<String>(
      valueListenable: _controller.currentPhase,
      builder: (context, phase, _) {
        final phases = ['inhale', 'hold', 'exhale', 'hold2'];
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: phases.map((p) {
            final isActive = phase == p;
            final color = _getPhaseColor(p);
            final label = p == 'hold2' ? 'HOLD' : p.toUpperCase();
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isActive ? color : color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isActive ? Colors.white : color.withOpacity(0.6),
                  letterSpacing: 0.5,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildExerciseView() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
      child: Column(
        children: [
          // Top row: close + timer
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                onPressed: _showStopDialog,
              ),
              const SizedBox(width: 8),
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
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle_outline,
                                  color: Colors.green,
                                  size: 52,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Exercise Complete! 🎉',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Great job! You\'ve completed your breathing exercise. Take a moment to notice how you feel.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  color: const Color(0xFF5D5D72),
                                  height: 1.5,
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
                                    elevation: 0,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  );
                },
              ),
            ],
          ),
          // Breathing circle
          Expanded(
            child: Center(
              child: _buildBreathingCircle(),
            ),
          ),
          // Phase progress bar at bottom
          _buildPhaseProgressBar(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBreathingCircle() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenW = MediaQuery.of(context).size.width;
        final minSize = screenW * _minCircleFraction;
        final maxSize = screenW * _maxCircleFraction;

        return ValueListenableBuilder<String>(
          valueListenable: _controller.currentPhase,
          builder: (context, phase, child) {
            final phaseColor = _getPhaseColor(phase);
            return AnimatedBuilder(
              animation: _breathAnimation,
              builder: (context, child) {
                // v goes 0→1 on inhale (forward) and 1→0 on exhale (reverse)
                final v = _breathAnimation.value.clamp(0.0, 1.0);
                final double size;
                if (phase == 'inhale' || phase == 'exhale') {
                  size = minSize + (maxSize - minSize) * v;
                } else if (phase == 'hold2') {
                  size = minSize;
                } else {
                  size = maxSize;
                }
                // Ripple rings also driven by v (same frame, no lag mismatch)
                final ring1 = size + (screenW * 0.10);
                final ring2 = size + (screenW * 0.20);

                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow ring 2
                    Container(
                      width: ring2,
                      height: ring2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: phaseColor.withOpacity(0.06),
                      ),
                    ),
                    // Outer glow ring 1
                    Container(
                      width: ring1,
                      height: ring1,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: phaseColor.withOpacity(0.12),
                      ),
                    ),
                    // Main animated circle — solid enough to clearly see growth
                    Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            phaseColor.withOpacity(0.70),
                            phaseColor.withOpacity(0.40),
                          ],
                          center: const Alignment(-0.2, -0.2),
                        ),
                        border: Border.all(
                          color: phaseColor.withOpacity(0.80),
                          width: 2.5,
                        ),
                      ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            phase == 'hold2' ? 'HOLD' : phase.toUpperCase(),
                            key: ValueKey(phase),
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: phaseColor,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ValueListenableBuilder<int>(
                          valueListenable: _controller.phaseSecondsLeft,
                          builder: (context, seconds, _) {
                            return phase.isNotEmpty
                                ? Text(
                                    '$seconds s',
                                    style: GoogleFonts.poppins(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: phaseColor,
                                    ),
                                  )
                                : const SizedBox.shrink();
                          },
                        ),
                        const SizedBox(height: 6),
                        if (phase.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              _getPhaseInstruction(phase),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: phaseColor.withOpacity(0.85),
                                height: 1.3,
                              ),
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
                    final Color cardColor = exercise['color'] as Color;
                    final pattern = exercise['pattern'] as Map<String, dynamic>;
                    final patternKeys = ['inhale', 'hold', 'exhale', 'hold2'];
                    final patternStr = patternKeys
                        .where((k) => pattern.containsKey(k))
                        .map((k) => '${pattern[k]}s')
                        .join(' · ');
                    final durationMin = (exercise['duration'] as int) ~/ 60;

                    return GestureDetector(
                      onTap: () => _startExercise(exercise),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: cardColor.withOpacity(0.35),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  exercise['icon'] as IconData,
                                  size: 26,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      exercise['name'],
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF3A3A50),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      exercise['description'],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                        height: 1.4,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: cardColor.withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            patternStr,
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: cardColor,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[200],
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Text(
                                            '$durationMin min',
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: cardColor.withOpacity(0.7),
                                size: 18,
                              ),
                            ],
                          ),
                        ),
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
          onPressed: () async {
            await Navigator.of(context).maybePop();
          },
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
    