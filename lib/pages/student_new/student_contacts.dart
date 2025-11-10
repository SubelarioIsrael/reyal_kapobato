import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../widgets/hotline_avatar.dart';
import '../../controllers/student_contacts_controller.dart';

class StudentContactsPage extends StatefulWidget {
  const StudentContactsPage({super.key});

  @override
  State<StudentContactsPage> createState() => _StudentContactsPageState();
}

class _StudentContactsPageState extends State<StudentContactsPage> {
  final StudentContactsController controller = StudentContactsController();

  @override
  void initState() {
    super.initState();
    controller.loadContacts();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoOpenDialog();
    });
  }

  void _checkAutoOpenDialog() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['autoOpenAddDialog'] == true) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _showContactDialog();
      });
    }
  }

  Future<void> _showContactDialog({Map<String, dynamic>? contact}) async {
    final nameController = TextEditingController(text: contact?['contact_name'] ?? '');
    final relationshipController = TextEditingController(text: contact?['relationship'] ?? '');
    final numberController = TextEditingController(text: contact?['contact_number'] ?? '');
    final formKey = GlobalKey<FormState>();
    final isEdit = contact != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
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
                    child: const Icon(Icons.contact_emergency, color: Color(0xFF7C83FD), size: 28),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      isEdit ? 'Edit Emergency Contact' : 'Add Emergency Contact',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3A3A50),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF5D5D72)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Contact Information', style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600, color: const Color(0xFF3A3A50))),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7C83FD)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: relationshipController,
                        decoration: InputDecoration(
                          labelText: 'Relationship *',
                          prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF7C83FD)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Relationship is required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: numberController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number *',
                          prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF7C83FD)),
                          helperText: 'Enter exactly 11 digits',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Contact number is required';
                          final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                          if (digitsOnly.length != 11) return 'Must be exactly 11 digits';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (formKey.currentState?.validate() != true) return;
                        await controller.addOrUpdateEmergencyContact(
                          name: nameController.text,
                          relationship: relationshipController.text,
                          contactNumber: numberController.text,
                          contactId: contact?['contact_id'],
                        );
                        Navigator.pop(context);
                      },
                      child: Text(isEdit ? 'Save Changes' : 'Add Contact', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyContactCard(Map<String, dynamic> contact) {
    return ListTile(
      leading: const Icon(Icons.person, color: Color(0xFF81C784)),
      title: Text(contact['contact_name'] ?? ''),
      subtitle: Text(contact['relationship'] ?? ''),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF7C83FD)),
            onPressed: () => _showContactDialog(contact: contact),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () => controller.deleteEmergencyContact(contact['contact_id']),
          ),
        ],
      ),
      onTap: () => controller.launchCall(contact['contact_number']),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, {bool isEmergency = false}) {
    return ListTile(
      leading: HotlineAvatar(profilePictureUrl: contact['profile_picture'], size: 60, isEmergency: isEmergency),
      title: Text(contact['name'] ?? ''),
      subtitle: Text(contact['notes'] ?? ''),
      onTap: () => controller.launchCall(contact['phone']),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> contacts, {bool isEmergency = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        const SizedBox(height: 16),
        if (contacts.isEmpty)
          Center(child: Text(isEmergency ? 'No mental health hotlines yet' : 'No emergency contacts yet'))
        else
          ...contacts.map((c) => isEmergency ? _buildContactCard(c, isEmergency: true) : _buildEmergencyContactCard(c)),
        const SizedBox(height: 24),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: controller.isLoading,
      builder: (context, loading, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Support Contacts'),
          centerTitle: true,
          actions: const [StudentNotificationButton()],
        ),
        drawer: const StudentDrawer(),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: controller.emergencyContacts,
                      builder: (context, contacts, _) => _buildSection('Emergency Contacts', contacts),
                    ),
                    ValueListenableBuilder<List<Map<String, dynamic>>>(
                      valueListenable: controller.mentalHealthHotlines,
                      builder: (context, contacts, _) => _buildSection('Mental Health Hotlines', contacts, isEmergency: true),
                    ),
                  ],
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _showContactDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
