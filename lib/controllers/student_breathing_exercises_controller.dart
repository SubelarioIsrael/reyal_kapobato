import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/activity_service.dart';

class StudentBreathingExercisesController with ChangeNotifier {
  final isLoading = ValueNotifier<bool>(true);
  final exercises = ValueNotifier<List<Map<String, dynamic>>>([]);
  final isExerciseActive = ValueNotifier<bool>(false);
  final remainingSeconds = ValueNotifier<int>(0);
  final phaseSecondsLeft = ValueNotifier<int>(0);
  final currentPhase = ValueNotifier<String>('');
  
  Timer? _exerciseTimer;
  Timer? _phaseTimer;
  AnimationController? _animationController;

  void init() {
    loadExercises();
  }

  void setAnimationController(AnimationController controller) {
    _animationController = controller;
  }

  Future<Map<String, dynamic>> loadExercises() async {
    isLoading.value = true;

    try {
      final response = await Supabase.instance.client
          .from('breathing_exercises')
          .select()
          .order('name');

      exercises.value = (response as List)
          .map((exercise) => {
                ...(exercise as Map<String, dynamic>),
                'color': _getColorFromHex(exercise['color_hex']),
                'icon': _getIconFromName(exercise['icon_name']),
              })
          .toList();
      
      isLoading.value = false;

      return {
        'success': true,
      };
    } catch (e) {
      print('Error loading exercises: $e');
      isLoading.value = false;
      return {
        'success': false,
        'message': 'Error loading exercises. Please try again later.',
      };
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

  void startExercise(Map<String, dynamic> exercise) {
    stopExercise();
    remainingSeconds.value = exercise['duration'];
    isExerciseActive.value = true;
  }

  void runBreathingPattern(Map<String, dynamic> pattern) {
    int totalCycleDuration = 0;
    pattern.forEach((key, value) => totalCycleDuration += value as int);

    final phaseOrder = ['inhale', 'hold', 'exhale', 'hold2'];
    final phases = <MapEntry<String, dynamic>>[];
    for (final phase in phaseOrder) {
      if (pattern.containsKey(phase)) {
        phases.add(MapEntry(phase, pattern[phase]));
      } else if (phase == 'hold2' && pattern.containsKey('hold')) {
        phases.add(MapEntry('hold2', pattern['hold']));
      }
    }
    int currentPhaseIndex = 0;

    void startPhase(int index) {
      if (!isExerciseActive.value) return;
      if (index >= phases.length) {
        currentPhaseIndex = 0;
        startPhase(0);
        return;
      }

      var phase = phases[index];
      currentPhase.value = phase.key;
      phaseSecondsLeft.value = phase.value as int;

      if (_animationController != null) {
        _animationController!.duration = Duration(seconds: phase.value as int);
        if (phase.key == 'inhale') {
          // forward(from: x) atomically resets value + starts — never gets stuck
          _animationController!.forward(from: 0.0);
        } else if (phase.key == 'exhale') {
          _animationController!.reverse(from: 1.0);
        } else if (phase.key == 'hold') {
          // Instant snap to max (fully expanded), then stop
          _animationController!.animateTo(1.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear);
        } else {
          // hold2 — instant snap to min (fully contracted)
          _animationController!.animateTo(0.0,
              duration: const Duration(milliseconds: 100),
              curve: Curves.linear);
        }
      }
    }

    startPhase(0);

    _exerciseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (remainingSeconds.value <= 0) {
        stopExercise();
        ActivityService.recordActivityCompletion('breathing_exercise');
        return;
      }

      remainingSeconds.value--;
      phaseSecondsLeft.value--;

      if (phaseSecondsLeft.value <= 0) {
        currentPhaseIndex = (currentPhaseIndex + 1) % phases.length;
        startPhase(currentPhaseIndex);
      }
    });
  }

  void stopExercise() {
    isExerciseActive.value = false;
    currentPhase.value = '';
    phaseSecondsLeft.value = 0;
    remainingSeconds.value = 0;
    _exerciseTimer?.cancel();
    _phaseTimer?.cancel();
    _animationController?.reset();
  }

  String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSecs = seconds % 60;
    return '$minutes:${remainingSecs.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    stopExercise();
    isLoading.dispose();
    exercises.dispose();
    isExerciseActive.dispose();
    remainingSeconds.dispose();
    phaseSecondsLeft.dispose();
    currentPhase.dispose();
    super.dispose();
  }
}
