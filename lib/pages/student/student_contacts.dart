import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../components/student_drawer.dart';
import '../../components/student_notification_button.dart';
import '../../widgets/hotline_avatar.dart';

class StudentContactsPage extends StatefulWidget {
  const StudentContactsPage({super.key});

  @override
  State<StudentContactsPage> createState() => _StudentContactsPageState();
}

class _StudentContactsPageState extends State<StudentContactsPage> {
  bool isLoading = true;
  List<Map<String, dynamic>> emergencyContacts = [];
  List<Map<String, dynamic>> mentalHealthHotlines = []; // Changed name

  @override
  void initState() {
    super.initState();
    _loadContacts();
    // Check for auto-open dialog argument after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAutoOpenDialog();
    });
  }

  void _checkAutoOpenDialog() {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    if (args != null && args['autoOpenAddDialog'] == true) {
      // Automatically open the add emergency contact dialog
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _showContactDialog();
        }
      });
    }
  }

  Future<void> _loadContacts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('User not logged in. Please log in to view contacts.'),
            ),
          );
        }
        return;
      }
      
      // Load emergency contacts
      final contactsResponse = await Supabase.instance.client
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .order('contact_name');
      
      // Try to load mental health hotlines
      List<Map<String, dynamic>> hotlinesData = [];
      try {
        final hotlinesResponse = await Supabase.instance.client
            .from('mental_health_hotlines') // Updated table name
            .select()
            .order('name');
        hotlinesData = List<Map<String, dynamic>>.from(hotlinesResponse);
      } catch (e) {
        print('Mental health hotlines table not found: $e');
        // Continue without hotlines data
      }

      if (mounted) {
        setState(() {
          emergencyContacts = List<Map<String, dynamic>>.from(contactsResponse);
          mentalHealthHotlines = hotlinesData; // Updated variable name
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading contacts: $e'); // Debug log
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading contacts: $e'),
          ),
        );
      }
    }
  }

  Future<void> _launchContact(String contactNumber) async {
    final uri = Uri(scheme: 'tel', path: contactNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not call the contact')),
        );
      }
    }
  }

  Future<void> _showContactDialog({Map<String, dynamic>? contact}) async {
    final nameController = TextEditingController(text: contact?['contact_name'] ?? '');
    final relationshipController = TextEditingController(text: contact?['relationship'] ?? '');
    final numberController = TextEditingController(text: contact?['contact_number'] ?? '');
    final isEdit = contact != null;

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEdit ? 'Edit Emergency Contact' : 'Add Emergency Contact'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: relationshipController,
                decoration: const InputDecoration(labelText: 'Relationship'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number (11 digits)',
                  helperText: 'Enter exactly 11 digits',
                ),
                keyboardType: TextInputType.phone,
                maxLength: 11,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                  if (digitsOnly.length != 11) return 'Must be exactly 11 digits';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() != true) return;
              final userId = Supabase.instance.client.auth.currentUser?.id;
              if (userId == null) return;
              
              // Clean phone number to digits only
              final cleanedNumber = numberController.text.replaceAll(RegExp(r'\D'), '');
              
              if (isEdit) {
                await Supabase.instance.client
                    .from('emergency_contacts')
                    .update({
                      'contact_name': nameController.text.trim(),
                      'relationship': relationshipController.text.trim(),
                      'contact_number': cleanedNumber,
                    })
                    .eq('contact_id', contact['contact_id']);
              } else {
                await Supabase.instance.client
                    .from('emergency_contacts')
                    .insert({
                      'user_id': userId,
                      'contact_name': nameController.text.trim(),
                      'relationship': relationshipController.text.trim(),
                      'contact_number': cleanedNumber,
                    });
              }
              Navigator.pop(context);
              _loadContacts();
            },
            child: Text(isEdit ? 'Save' : 'Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContact(int contactId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: const Text('Are you sure you want to delete this contact?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await Supabase.instance.client
          .from('emergency_contacts')
          .delete()
          .eq('contact_id', contactId);
      _loadContacts();
    }
  }

  Widget _buildEmergencyContactCard(Map<String, dynamic> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchContact(contact['contact_number']),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: const Color(0xFF81C784).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person,
                    color: Color(0xFF81C784),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['contact_name'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      if (contact['relationship'] != null && contact['relationship'].toString().isNotEmpty)
                        Text(
                          contact['relationship'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        contact['contact_number'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF7C83FD)),
                  tooltip: 'Edit',
                  onPressed: () => _showContactDialog(contact: contact),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _deleteContact(contact['contact_id']),
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: Color(0xFF81C784)),
                  onPressed: () => _launchContact(contact['contact_number']),
                  tooltip: 'Call',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, {bool isEmergency = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _launchContact(contact['phone']),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                HotlineAvatar(
                  profilePictureUrl: contact['profile_picture'],
                  size: 60,
                  isEmergency: isEmergency,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact['name'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      if (contact['notes'] != null && contact['notes'].toString().isNotEmpty)
                        Text(
                          contact['notes'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      Text(
                        contact['phone'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (contact['city_or_region'] != null && contact['city_or_region'].toString().isNotEmpty)
                        Text(
                          contact['city_or_region'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: Color(0xFF7C83FD)),
                  onPressed: () => _launchContact(contact['phone']),
                  tooltip: 'Call',
                ),
              ],
            ),
          ),
        ),
      )
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> contacts, {bool isEmergency = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF3A3A50),
          ),
        ),
        const SizedBox(height: 16),
        if (contacts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
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
              children: [
                Icon(
                  isEmergency ? Icons.support_agent : Icons.person_off,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  isEmergency
                      ? 'No mental health hotlines available yet' // Updated message
                      : 'No emergency contacts available yet',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Check back later for new contacts',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        else if (!isEmergency)
          ...contacts.map((contact) => _buildEmergencyContactCard(contact))
        else
          ...contacts.map((contact) => _buildContactCard(contact, isEmergency: true)),
        const SizedBox(height: 24),
      ],
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
          "Support Contacts",
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection('Emergency Contacts', emergencyContacts),
                    _buildSection('Mental Health Hotlines', mentalHealthHotlines, isEmergency: true),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showContactDialog(),
        backgroundColor: const Color(0xFF7C83FD),
        child: const Icon(Icons.add),
        tooltip: 'Add Emergency Contact',
      ),
    );
  }
}

