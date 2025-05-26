import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminExercises extends StatefulWidget {
  const AdminExercises({super.key});

  @override
  State<AdminExercises> createState() => _AdminExercisesState();
}

class _AdminExercisesState extends State<AdminExercises> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();
  final _inhaleController = TextEditingController();
  final _holdController = TextEditingController();
  final _exhaleController = TextEditingController();
  final _hold2Controller = TextEditingController();
  bool _isLoading = false;
  bool _hasSecondHold = false;

  // Mock data - Replace with actual data from your backend
  final List<Map<String, dynamic>> _exercises = [
    {
      'name': '4-7-8 Breathing',
      'description':
          'Inhale for 4 seconds, hold for 7 seconds, exhale for 8 seconds',
      'duration': 180,
      'pattern': {
        'inhale': 4,
        'hold': 7,
        'exhale': 8,
      },
      'color': Colors.blue.shade100,
      'icon': Icons.air,
    },
    {
      'name': 'Box Breathing',
      'description': 'Inhale, hold, exhale, and hold again, each for 4 seconds',
      'duration': 240,
      'pattern': {
        'inhale': 4,
        'hold': 4,
        'exhale': 4,
        'hold2': 4,
      },
      'color': Colors.green.shade100,
      'icon': Icons.square_outlined,
    },
    {
      'name': 'Deep Breathing',
      'description':
          'Simple deep breaths - inhale for 5 seconds, exhale for 5 seconds',
      'duration': 300,
      'pattern': {
        'inhale': 5,
        'exhale': 5,
      },
      'color': Colors.purple.shade100,
      'icon': Icons.waves,
    },
  ];

  void _showAddExerciseDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Add New Exercise',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Exercise Name',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter a description'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _durationController,
                  decoration: const InputDecoration(
                    labelText: 'Duration (seconds)',
                    prefixIcon: Icon(Icons.timer),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter duration';
                    }
                    if (int.tryParse(value!) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Text(
                  'Breathing Pattern',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF3A3A50),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _inhaleController,
                        decoration: const InputDecoration(
                          labelText: 'Inhale (s)',
                          prefixIcon: Icon(Icons.arrow_upward),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          if (int.tryParse(value!) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _holdController,
                        decoration: const InputDecoration(
                          labelText: 'Hold (s)',
                          prefixIcon: Icon(Icons.pause),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          if (int.tryParse(value!) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _exhaleController,
                        decoration: const InputDecoration(
                          labelText: 'Exhale (s)',
                          prefixIcon: Icon(Icons.arrow_downward),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Required';
                          }
                          if (int.tryParse(value!) == null) {
                            return 'Invalid';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _hold2Controller,
                        decoration: const InputDecoration(
                          labelText: 'Hold 2 (s)',
                          prefixIcon: Icon(Icons.pause),
                        ),
                        keyboardType: TextInputType.number,
                        enabled: _hasSecondHold,
                        validator: _hasSecondHold
                            ? (value) {
                                if (value?.isEmpty ?? true) {
                                  return 'Required';
                                }
                                if (int.tryParse(value!) == null) {
                                  return 'Invalid';
                                }
                                return null;
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('Include second hold phase'),
                  value: _hasSecondHold,
                  onChanged: (value) {
                    setState(() {
                      _hasSecondHold = value ?? false;
                      if (!_hasSecondHold) {
                        _hold2Controller.clear();
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _isLoading
                ? null
                : () async {
                    if (_formKey.currentState?.validate() ?? false) {
                      setState(() {
                        _isLoading = true;
                      });

                      // TODO: Implement exercise creation logic
                      await Future.delayed(const Duration(seconds: 1));

                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Exercise added successfully'),
                          ),
                        );
                      }

                      setState(() {
                        _isLoading = false;
                        _nameController.clear();
                        _descriptionController.clear();
                        _durationController.clear();
                        _inhaleController.clear();
                        _holdController.clear();
                        _exhaleController.clear();
                        _hold2Controller.clear();
                        _hasSecondHold = false;
                      });
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C83FD),
              foregroundColor: Colors.white,
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Add Exercise'),
          ),
        ],
      ),
    );
  }

  void _showExerciseActions(Map<String, dynamic> exercise) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exercise Actions',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF3A3A50),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Exercise'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit exercise
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Exercise'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete exercise
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Exercise deleted'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        title: Text(
          "Breathing Exercises",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF3A3A50),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search exercises...",
                      hintStyle: GoogleFonts.poppins(
                        color: Colors.grey[400],
                      ),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showAddExerciseDialog,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Exercise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _exercises.length,
              itemBuilder: (context, index) {
                final exercise = _exercises[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor: exercise['color'].withOpacity(0.1),
                      child: Icon(
                        exercise['icon'],
                        color: exercise['color'],
                      ),
                    ),
                    title: Text(
                      exercise['name'],
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          exercise['description'],
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: exercise['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${exercise['duration']}s',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: exercise['color'],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pattern: ${_formatPattern(exercise['pattern'])}',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.more_vert),
                      onPressed: () => _showExerciseActions(exercise),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatPattern(Map<String, dynamic> pattern) {
    final parts = <String>[];
    if (pattern.containsKey('inhale')) {
      parts.add('Inhale: ${pattern['inhale']}s');
    }
    if (pattern.containsKey('hold')) {
      parts.add('Hold: ${pattern['hold']}s');
    }
    if (pattern.containsKey('exhale')) {
      parts.add('Exhale: ${pattern['exhale']}s');
    }
    if (pattern.containsKey('hold2')) {
      parts.add('Hold: ${pattern['hold2']}s');
    }
    return parts.join(' → ');
  }
}
