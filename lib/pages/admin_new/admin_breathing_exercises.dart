import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/admin_breathing_exercises_controller.dart';

class AdminBreathingExercises extends StatefulWidget {
  const AdminBreathingExercises({super.key});

  @override
  State<AdminBreathingExercises> createState() => _AdminBreathingExercisesState();
}

class _AdminBreathingExercisesState extends State<AdminBreathingExercises> {
  final _controller = AdminBreathingExercisesController();
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
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
  List<Map<String, dynamic>> _exercises = [];
  List<Map<String, dynamic>> _filteredExercises = [];

  final List<String> _iconOptions = [
    'air',
    'square_outlined',
    'waves',
    'self_improvement',
  ];

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    _inhaleController.dispose();
    _holdController.dispose();
    _exhaleController.dispose();
    _hold2Controller.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _controller.loadExercises();

    if (result.success) {
      setState(() {
        _exercises = result.exercises;
        _applyFilters();
      });
    } else {
      if (mounted) {
        _showErrorDialog(result.errorMessage ?? 'Failed to load exercises');
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _applyFilters() {
    setState(() {
      final search = _searchController.text.toLowerCase();
      _filteredExercises = _exercises.where((exercise) {
        final matchesSearch = search.isEmpty ||
            (exercise['name']?.toLowerCase().contains(search) ?? false) ||
            (exercise['description']?.toLowerCase().contains(search) ?? false);
        return matchesSearch;
      }).toList();
    });
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

  void _showAddExerciseModal() {
    _nameController.clear();
    _descriptionController.clear();
    _durationController.clear();
    _inhaleController.clear();
    _holdController.clear();
    _exhaleController.clear();
    _hold2Controller.clear();
    _hasSecondHold = false;
    _selectedIconName = 'air';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C83FD).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C83FD).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.air,
                            color: Color(0xFF7C83FD),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add New Exercise',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Create a new breathing exercise',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF5D5D72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Basic Information
                            Text(
                              'Basic Information',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Exercise Name',
                                hintText: 'e.g., Box Breathing, 4-7-8 Breathing',
                                prefixIcon: const Icon(Icons.title, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              validator: _controller.validateName,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Describe the exercise and its benefits',
                                prefixIcon: const Icon(Icons.description, color: Color(0xFF7C83FD)),
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              validator: _controller.validateDescription,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _durationController,
                              decoration: InputDecoration(
                                labelText: 'Duration (seconds)',
                                hintText: 'Total duration in seconds',
                                prefixIcon: const Icon(Icons.timer, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              keyboardType: TextInputType.number,
                              validator: _controller.validateDuration,
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _selectedIconName,
                              decoration: InputDecoration(
                                labelText: 'Icon Style',
                                prefixIcon: const Icon(Icons.image, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                              ),
                              style: GoogleFonts.poppins(color: const Color(0xFF3A3A50)),
                              items: _iconOptions
                                  .map((icon) => DropdownMenuItem(
                                        value: icon,
                                        child: Row(
                                          children: [
                                            Icon(_getIconFromName(icon), size: 18, color: const Color(0xFF7C83FD)),
                                            const SizedBox(width: 8),
                                            Text(icon.replaceAll('_', ' ').toUpperCase()),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedIconName = value ?? 'air';
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            // Breathing Pattern
                            Text(
                              'Breathing Pattern',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _inhaleController,
                                    decoration: InputDecoration(
                                      labelText: 'Inhale (s)',
                                      hintText: 'Seconds',
                                      prefixIcon: const Icon(Icons.arrow_upward, color: Color(0xFF7C83FD)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                      ),
                                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    keyboardType: TextInputType.number,
                                    validator: _controller.validatePatternNumber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _holdController,
                                    decoration: InputDecoration(
                                      labelText: 'Hold 1 (s)',
                                      hintText: 'Seconds',
                                      prefixIcon: const Icon(Icons.pause, color: Color(0xFF7C83FD)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                      ),
                                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    keyboardType: TextInputType.number,
                                    validator: _controller.validatePatternNumber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _exhaleController,
                                    decoration: InputDecoration(
                                      labelText: 'Exhale (s)',
                                      hintText: 'Seconds',
                                      prefixIcon: const Icon(Icons.arrow_downward, color: Color(0xFF7C83FD)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                      ),
                                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    keyboardType: TextInputType.number,
                                    validator: _controller.validatePatternNumber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _hold2Controller,
                                    decoration: InputDecoration(
                                      labelText: 'Hold 2 (s)',
                                      hintText: _hasSecondHold ? 'Seconds' : 'Optional',
                                      prefixIcon: const Icon(Icons.pause, color: Color(0xFF7C83FD)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                      ),
                                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    keyboardType: TextInputType.number,
                                    enabled: _hasSecondHold,
                                    validator: (value) => _controller.validateOptionalPatternNumber(value, _hasSecondHold),
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
                                  setModalState(() {
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
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF7C83FD)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C83FD),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _handleAddExercise(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Add Exercise',
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleAddExercise(BuildContext context) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    final pattern = {
      'inhale': int.parse(_inhaleController.text),
      'hold': int.parse(_holdController.text),
      'exhale': int.parse(_exhaleController.text),
    };
    if (_hasSecondHold && _hold2Controller.text.isNotEmpty) {
      pattern['hold2'] = int.parse(_hold2Controller.text);
    }

    final result = await _controller.createExercise(
      name: _nameController.text,
      description: _descriptionController.text,
      duration: int.parse(_durationController.text),
      pattern: pattern,
      colorHex: '#7C83FD',
      iconName: _selectedIconName,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pop(context);

      if (result.success) {
        _showSuccessDialog('Exercise added successfully');
        _loadExercises();
      } else {
        _showErrorDialog(result.errorMessage ?? 'Failed to add exercise');
      }
    }
  }

  void _showEditExerciseModal(Map<String, dynamic> exercise) {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF7C83FD).withOpacity(0.1),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C83FD).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: Color(0xFF7C83FD),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Edit Exercise',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF3A3A50),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Update exercise information',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xFF5D5D72),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // Content - Same as Add but with edit
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Basic Information',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Exercise Name',
                                hintText: 'e.g., Box Breathing, 4-7-8 Breathing',
                                prefixIcon: const Icon(Icons.title, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              validator: _controller.validateName,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                labelText: 'Description',
                                hintText: 'Describe the exercise and its benefits',
                                prefixIcon: const Icon(Icons.description, color: Color(0xFF7C83FD)),
                                alignLabelWithHint: true,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              validator: _controller.validateDescription,
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _durationController,
                              decoration: InputDecoration(
                                labelText: 'Duration (seconds)',
                                hintText: 'Total duration in seconds',
                                prefixIcon: const Icon(Icons.timer, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                                hintStyle: GoogleFonts.poppins(color: Colors.grey[400]),
                              ),
                              style: GoogleFonts.poppins(),
                              keyboardType: TextInputType.number,
                              validator: _controller.validateDuration,
                            ),
                            const SizedBox(height: 20),
                            DropdownButtonFormField<String>(
                              value: _selectedIconName,
                              decoration: InputDecoration(
                                labelText: 'Icon Style',
                                prefixIcon: const Icon(Icons.image, color: Color(0xFF7C83FD)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                ),
                                labelStyle: GoogleFonts.poppins(),
                              ),
                              style: GoogleFonts.poppins(color: const Color(0xFF3A3A50)),
                              items: _iconOptions
                                  .map((icon) => DropdownMenuItem(
                                        value: icon,
                                        child: Row(
                                          children: [
                                            Icon(_getIconFromName(icon), size: 18, color: const Color(0xFF7C83FD)),
                                            const SizedBox(width: 8),
                                            Text(icon.replaceAll('_', ' ').toUpperCase()),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                setModalState(() {
                                  _selectedIconName = value ?? 'air';
                                });
                              },
                            ),
                            const SizedBox(height: 32),
                            Text(
                              'Breathing Pattern',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF3A3A50),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _inhaleController,
                                    decoration: InputDecoration(
                                      labelText: 'Inhale (s)',
                                      hintText: 'Seconds',
                                      prefixIcon: const Icon(Icons.arrow_upward, color: Color(0xFF7C83FD)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                      ),
                                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    keyboardType: TextInputType.number,
                                    validator: _controller.validatePatternNumber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _holdController,
                                    decoration: InputDecoration(
                                      labelText: 'Hold 1 (s)',
                                      hintText: 'Seconds',
                                      prefixIcon: const Icon(Icons.pause, color: Color(0xFF7C83FD)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                      ),
                                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    keyboardType: TextInputType.number,
                                    validator: _controller.validatePatternNumber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _exhaleController,
                                    decoration: InputDecoration(
                                      labelText: 'Exhale (s)',
                                      hintText: 'Seconds',
                                      prefixIcon: const Icon(Icons.arrow_downward, color: Color(0xFF7C83FD)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                      ),
                                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    keyboardType: TextInputType.number,
                                    validator: _controller.validatePatternNumber,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextFormField(
                                    controller: _hold2Controller,
                                    decoration: InputDecoration(
                                      labelText: 'Hold 2 (s)',
                                      hintText: _hasSecondHold ? 'Seconds' : 'Optional',
                                      prefixIcon: const Icon(Icons.pause, color: Color(0xFF7C83FD)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                                      ),
                                      labelStyle: GoogleFonts.poppins(fontSize: 13),
                                    ),
                                    style: GoogleFonts.poppins(),
                                    keyboardType: TextInputType.number,
                                    enabled: _hasSecondHold,
                                    validator: (value) => _controller.validateOptionalPatternNumber(value, _hasSecondHold),
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
                                  setModalState(() {
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
                    ),
                  ),
                  // Footer
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF7C83FD)),
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7C83FD),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading 
                                ? null 
                                : () => _handleUpdateExercise(context, exercise['id'] as int, exercise['color_hex'] ?? '#7C83FD'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7C83FD),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Save Changes',
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleUpdateExercise(BuildContext context, int exerciseId, String colorHex) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isLoading = true;
    });

    final pattern = {
      'inhale': int.parse(_inhaleController.text),
      'hold': int.parse(_holdController.text),
      'exhale': int.parse(_exhaleController.text),
    };
    if (_hasSecondHold && _hold2Controller.text.isNotEmpty) {
      pattern['hold2'] = int.parse(_hold2Controller.text);
    }

    final result = await _controller.updateExercise(
      exerciseId: exerciseId,
      name: _nameController.text,
      description: _descriptionController.text,
      duration: int.parse(_durationController.text),
      pattern: pattern,
      colorHex: colorHex,
      iconName: _selectedIconName,
    );

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      Navigator.pop(context);

      if (result.success) {
        _showSuccessDialog('Exercise updated successfully');
        _loadExercises();
      } else {
        _showErrorDialog(result.errorMessage ?? 'Failed to update exercise');
      }
    }
  }

  void _confirmDeleteExercise(int exerciseId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.delete_forever,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Delete Exercise',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete this breathing exercise? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        side: BorderSide(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF5D5D72),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _handleDeleteExercise(context, exerciseId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Delete',
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
      ),
    );
  }

  Future<void> _handleDeleteExercise(BuildContext context, int exerciseId) async {
    Navigator.pop(context);

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.deleteExercise(exerciseId);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      if (result.success) {
        _showSuccessDialog('Exercise deleted successfully');
        _loadExercises();
      } else {
        _showErrorDialog(result.errorMessage ?? 'Failed to delete exercise');
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Error',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
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
                'Success',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: const Color(0xFF5D5D72),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C83FD),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 242, 241, 248),
      appBar: AppBar(
        title: Text(
          'Breathing Exercises',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            
          ),
          
        ),
        centerTitle: true,
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
            child: TextField(
              controller: _searchController,
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
              onChanged: (value) => _applyFilters(),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExercises.isEmpty
                    ? Center(
                        child: Text(
                          'No exercises found',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _filteredExercises[index];
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
                                      fontSize: 13,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 8),
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
                                      Expanded(
                                        child: Text(
                                          _controller.formatPattern(exercise['pattern']),
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton<String>(
                                icon: Icon(
                                  Icons.more_vert,
                                  color: Colors.grey[600],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditExerciseModal(exercise);
                                  } else if (value == 'delete') {
                                    _confirmDeleteExercise(exercise['id'] as int);
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.edit,
                                          color: Color(0xFF7C83FD),
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Edit Exercise',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFF3A3A50),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.delete,
                                          color: Colors.red,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          'Delete Exercise',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFF3A3A50),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddExerciseModal,
        backgroundColor: const Color(0xFF7C83FD),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
