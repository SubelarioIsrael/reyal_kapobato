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
                    child: const Icon(
                      Icons.contact_emergency,
                      color: Color(0xFF7C83FD),
                      size: 28,
                    ),
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
            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Information',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'Enter contact name',
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF7C83FD)),
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: GoogleFonts.poppins(),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: relationshipController,
                        decoration: InputDecoration(
                          labelText: 'Relationship *',
                          hintText: 'e.g., Parent, Sibling, Friend',
                          prefixIcon: const Icon(Icons.people_outline, color: Color(0xFF7C83FD)),
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        style: GoogleFonts.poppins(),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Relationship is required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: numberController,
                        decoration: InputDecoration(
                          labelText: 'Contact Number *',
                          hintText: '09XXXXXXXXX',
                          prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFF7C83FD)),
                          labelStyle: GoogleFonts.poppins(color: const Color(0xFF5D5D72)),
                          helperText: 'Enter exactly 11 digits',
                          helperStyle: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF7C83FD), width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        keyboardType: TextInputType.phone,
                        maxLength: 11,
                        style: GoogleFonts.poppins(),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Contact number is required';
                          final digitsOnly = v.replaceAll(RegExp(r'\D'), '');
                          if (digitsOnly.length != 11) return 'Must be exactly 11 digits';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'This contact will be notified in case of emergencies.',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF5D5D72),
                                ),
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
            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
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
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey[300]!, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: const Color(0xFF7C83FD),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        isEdit ? 'Save Changes' : 'Add Contact',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
  }

  Future<void> _deleteContact(int contactId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                'Delete Contact',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3A3A50),
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Text(
              'Are you sure you want to delete this emergency contact?',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: const Color(0xFF3A3A50),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.shade200,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This action cannot be undone. The contact will be permanently removed.',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: const Color(0xFF5D5D72),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(
                      color: Color(0xFF7C83FD),
                      width: 2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF7C83FD),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: Text(
                    'Delete',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Contact deleted successfully',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildEmergencyContactCard(Map<String, dynamic> contact) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF81C784).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                color: Color(0xFF81C784),
                size: 24,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (contact['relationship'] != null && contact['relationship'].toString().isNotEmpty)
                    Text(
                      contact['relationship'],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact['contact_number'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Call button
            Container(
              margin: const EdgeInsets.only(right: 8),
              child: Material(
                color: const Color(0xFF81C784).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                child: InkWell(
                  onTap: () => _launchContact(contact['contact_number']),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      Icons.call_rounded,
                      color: const Color(0xFF81C784),
                      size: 20,
                    ),
                  ),
                ),
              ),
            ),
            // Popup menu for edit/delete
            PopupMenuButton<String>(
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Color(0xFF3A3A50),
                size: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 3,
              offset: const Offset(0, 40),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Color(0xFF7C83FD),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Edit Contact',
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
                        Icons.delete_outline_rounded,
                        size: 18,
                        color: Colors.red,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Delete Contact',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xFF3A3A50),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) async {
                if (value == 'edit') {
                  _showContactDialog(contact: contact);
                } else if (value == 'delete') {
                  await _deleteContact(contact['contact_id']);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact, {bool isEmergency = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            HotlineAvatar(
              profilePictureUrl: contact['profile_picture'],
              size: 48,
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF3A3A50),
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (contact['notes'] != null && contact['notes'].toString().isNotEmpty)
                    Text(
                      contact['notes'],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[600],
                        height: 1.3,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.phone,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        contact['phone'] ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  if (contact['city_or_region'] != null && contact['city_or_region'].toString().isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 14,
                          color: Colors.grey[500],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          contact['city_or_region'],
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Call button
            Material(
              color: const Color(0xFF7C83FD).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: () => _launchContact(contact['phone']),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.call_rounded,
                    color: const Color(0xFF7C83FD),
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Map<String, dynamic>> contacts, {bool isEmergency = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF3A3A50),
            ),
          ),
        ),
        if (contacts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey.withOpacity(0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isEmergency ? Icons.support_agent_rounded : Icons.person_add_outlined,
                    size: 40,
                    color: Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  isEmergency
                      ? 'No mental health hotlines available'
                      : 'No emergency contacts added yet',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: const Color(0xFF3A3A50),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isEmergency
                      ? 'Check back later for updates'
                      : 'Tap the + button to add your first contact',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
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
        elevation: 2,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }
}


