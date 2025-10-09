import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../components/modern_form_dialog.dart';

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
  String _selectedIconName = 'air';
  final List<String> _iconOptions = [
    'air',
    'square_outlined',
    'waves',
    'self_improvement',
  ];

  List<Map<String, dynamic>> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await Supabase.instance.client
          .from('breathing_exercises')
          .select()
          .order('name');
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
    } catch (e) {
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

  void _showExerciseDialog({Map<String, dynamic>? exercise}) {
    final isEdit = exercise != null;
    if (isEdit) {
      _nameController.text = exercise['name'] ?? '';
      _descriptionController.text = exercise['description'] ?? '';
      _durationController.text = exercise['duration']?.toString() ?? '';
      final pattern = exercise['pattern'] as Map<String, dynamic>? ?? {};
      _inhaleController.text = pattern['inhale']?.toString() ?? '';
      _holdController.text = pattern['hold']?.toString() ?? '';
      _exhaleController.text = pattern['exhale']?.toString() ?? '';
      _hold2Controller.text = pattern['hold2']?.toString() ?? '';
      _hasSecondHold = pattern.containsKey('hold2');
      _selectedIconName = exercise['icon_name'] ?? 'air';
    } else {
      _nameController.clear();
      _descriptionController.clear();
      _durationController.clear();
      _inhaleController.clear();
      _holdController.clear();
      _exhaleController.clear();
      _hold2Controller.clear();
      _hasSecondHold = false;
      _selectedIconName = 'air';
    }
    
    ModernFormDialog.show(
      context: context,
      title: isEdit ? 'Edit Breathing Exercise' : 'Add New Breathing Exercise',
      subtitle: isEdit ? 'Update the selected breathing exercise' : 'Create a new breathing exercise for students',
      content: StatefulBuilder(
        builder: (context, localSetState) => Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FormSection(
                    title: 'Basic Information',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        ModernTextFormField(
                          controller: _nameController,
                          labelText: 'Exercise Name',
                          hintText: 'e.g., Box Breathing, 4-7-8 Breathing',
                          prefixIcon: Icons.title,
                          validator: (value) =>
                              value?.isEmpty ?? true ? 'Please enter a name' : null,
                        ),
                        const SizedBox(height: 20),
                        ModernTextFormField(
                          controller: _descriptionController,
                          labelText: 'Description',
                          hintText: 'Describe the exercise and its benefits',
                          prefixIcon: Icons.description,
                          maxLines: 3,
                          validator: (value) => value?.isEmpty ?? true
                              ? 'Please enter a description'
                              : null,
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ModernTextFormField(
                                controller: _durationController,
                                labelText: 'Duration',
                                hintText: 'Total seconds',
                                prefixIcon: Icons.timer,
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ModernDropdownFormField<String>(
                                value: _selectedIconName,
                                labelText: 'Icon Style',
                                prefixIcon: Icons.image,
                                items: _iconOptions
                                    .map((icon) => DropdownMenuItem(
                                          value: icon,
                                          child: Row(
                                            children: [
                                              Icon(_getIconFromName(icon), size: 18),
                                              const SizedBox(width: 8),
                                              Text(icon.replaceAll('_', ' ').toUpperCase()),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  localSetState(() {
                                    _selectedIconName = value ?? 'air';
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FormSection(
                    title: 'Breathing Pattern',
                    icon: Icons.air,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ModernTextFormField(
                                controller: _inhaleController,
                                labelText: 'Inhale',
                                hintText: 'Seconds',
                                prefixIcon: Icons.arrow_upward,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: ModernTextFormField(
                                controller: _holdController,
                                labelText: 'Hold (1st)',
                                hintText: 'Seconds',
                                prefixIcon: Icons.pause,
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
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ModernTextFormField(
                                controller: _exhaleController,
                                labelText: 'Exhale',
                                hintText: 'Seconds',
                                prefixIcon: Icons.arrow_downward,
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
                            const SizedBox(width: 12),
                            Expanded(
                              child: ModernTextFormField(
                                controller: _hold2Controller,
                                labelText: 'Hold (2nd)',
                                hintText: _hasSecondHold ? 'Seconds' : 'Optional',
                                prefixIcon: Icons.pause,
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
                        const SizedBox(height: 16),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              width: 1.5,
                            ),
                          ),
                          child: CheckboxListTile(
                            title: Text(
                              'Include second hold phase',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            subtitle: Text(
                              'For patterns like 4-7-8-2 breathing',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: _hasSecondHold,
                            onChanged: (value) {
                              localSetState(() {
                                _hasSecondHold = value ?? false;
                                if (!_hasSecondHold) {
                                  _hold2Controller.clear();
                                }
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ),
      ),
      actions: [
            ModernActionButton(
              text: 'Cancel',
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 12),
            ModernActionButton(
              text: isEdit ? 'Save Changes' : 'Add Exercise',
              isPrimary: true,
              isLoading: _isLoading,
              icon: isEdit ? Icons.save : Icons.add,
              onPressed: () async {
                if (_formKey.currentState?.validate() ?? false) {
                  setState(() {
                    _isLoading = true;
                  });
                  final pattern = {
                    'inhale': int.parse(_inhaleController.text),
                    'hold': int.parse(_holdController.text),
                    'exhale': int.parse(_exhaleController.text),
                  };
                  if (_hasSecondHold &&
                      _hold2Controller.text.isNotEmpty) {
                    pattern['hold2'] = int.parse(_hold2Controller.text);
                  }
                  // For demo, use a default color/icon
                  final colorHex = exercise?['color_hex'] ?? '#7C83FD';
                  final iconName = _selectedIconName;
                  try {
                    if (isEdit) {
                      // Update
                      await Supabase.instance.client
                          .from('breathing_exercises')
                          .update({
                        'name': _nameController.text.trim(),
                        'description': _descriptionController.text.trim(),
                        'duration': int.parse(_durationController.text),
                        'pattern': pattern,
                        'color_hex': colorHex,
                        'icon_name': iconName,
                      }).eq('id', exercise['id']);
                    } else {
                      // Insert
                      await Supabase.instance.client
                          .from('breathing_exercises')
                          .insert({
                        'name': _nameController.text.trim(),
                        'description': _descriptionController.text.trim(),
                        'duration': int.parse(_durationController.text),
                        'pattern': pattern,
                        'color_hex': colorHex,
                        'icon_name': iconName,
                      });
                    }
                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(isEdit
                                  ? 'Exercise updated successfully'
                                  : 'Exercise added successfully'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                      await _loadExercises();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.error, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('Failed to save exercise: $e'),
                            ],
                          ),
                          backgroundColor: Colors.red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      );
                    }
                  } finally {
                    setState(() {
                      _isLoading = false;
                    });
                    _nameController.clear();
                    _descriptionController.clear();
                    _durationController.clear();
                    _inhaleController.clear();
                    _holdController.clear();
                    _exhaleController.clear();
                    _hold2Controller.clear();
                    _hasSecondHold = false;
                    _selectedIconName = 'air';
                  }
                }
              },
            ),
          ],
    );
  }

  void _showAddExerciseDialog() {
    _showExerciseDialog();
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
                _showExerciseDialog(exercise: exercise);
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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
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
                                softWrap: true,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  return Container(
                                    width: constraints.maxWidth,
                                    child: Wrap(
                                      crossAxisAlignment:
                                          WrapCrossAlignment.center,
                                      spacing: 8,
                                      runSpacing: 4,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: exercise['color']
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(12),
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
                                        Text(
                                          'Pattern: ${_formatPattern(exercise['pattern'])}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                          softWrap: true,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  );
                                },
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
