import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentSupportContactsController with ChangeNotifier {
  final isLoading = ValueNotifier<bool>(true);
  final emergencyContacts = ValueNotifier<List<Map<String, dynamic>>>([]);
  final mentalHealthHotlines = ValueNotifier<List<Map<String, dynamic>>>([]);

  void init() {
    loadContacts();
  }

  Future<Map<String, dynamic>> loadContacts() async {
    isLoading.value = true;

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        isLoading.value = false;
        return {
          'success': false,
          'message': 'User not logged in. Please log in to view contacts.',
        };
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
            .from('mental_health_hotlines')
            .select()
            .order('name');
        hotlinesData = List<Map<String, dynamic>>.from(hotlinesResponse);
      } catch (e) {
        print('Mental health hotlines table not found: $e');
      }

      emergencyContacts.value = List<Map<String, dynamic>>.from(contactsResponse);
      mentalHealthHotlines.value = hotlinesData;
      isLoading.value = false;

      return {'success': true};
    } catch (e) {
      print('Error loading contacts: $e');
      isLoading.value = false;
      return {
        'success': false,
        'message': 'Error loading contacts. Please try again later.',
      };
    }
  }

  String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    // Check for numbers
    if (RegExp(r'\d').hasMatch(value)) {
      return 'Name cannot contain numbers';
    }
    // Check for special characters (allow spaces, hyphens, apostrophes)
    if (RegExp(r"[^a-zA-Z\s\-']").hasMatch(value)) {
      return 'Name cannot contain special characters';
    }
    return null;
  }

  String? validateRelationship(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Relationship is required';
    }
    // Check for numbers
    if (RegExp(r'\d').hasMatch(value)) {
      return 'Relationship cannot contain numbers';
    }
    // Check for special characters (allow spaces, hyphens)
    if (RegExp(r'[^a-zA-Z\s\-]').hasMatch(value)) {
      return 'Relationship cannot contain special characters';
    }
    return null;
  }

  String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Contact number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length != 11) {
      return 'Must be exactly 11 digits';
    }
    if (!digitsOnly.startsWith('0')) {
      return 'Contact number must start with 0';
    }
    return null;
  }

  Future<Map<String, dynamic>> saveContact({
    required String name,
    required String relationship,
    required String phoneNumber,
    int? contactId,
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        return {
          'success': false,
          'message': 'User not logged in',
        };
      }

      // Clean phone number to digits only
      final cleanedNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');

      // Check for duplicate phone number
      final duplicateCheck = await Supabase.instance.client
          .from('emergency_contacts')
          .select('contact_id, contact_name')
          .eq('user_id', userId)
          .eq('contact_number', cleanedNumber)
          .maybeSingle();

      // If duplicate exists and it's not the current contact being edited
      if (duplicateCheck != null && duplicateCheck['contact_id'] != contactId) {
        return {
          'success': false,
          'message': 'duplicate',
          'isDuplicate': true,
        };
      }

      if (contactId != null) {
        // Update existing contact
        await Supabase.instance.client
            .from('emergency_contacts')
            .update({
              'contact_name': name.trim(),
              'relationship': relationship.trim(),
              'contact_number': cleanedNumber,
            })
            .eq('contact_id', contactId);
      } else {
        // Insert new contact
        await Supabase.instance.client
            .from('emergency_contacts')
            .insert({
              'user_id': userId,
              'contact_name': name.trim(),
              'relationship': relationship.trim(),
              'contact_number': cleanedNumber,
            });
      }

      await loadContacts();

      return {
        'success': true,
        'message': contactId != null
            ? 'Contact updated successfully'
            : 'Contact added successfully',
      };
    } catch (e) {
      print('Error saving contact: $e');
      return {
        'success': false,
        'message': 'Error saving contact. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> deleteContact(int contactId) async {
    try {
      await Supabase.instance.client
          .from('emergency_contacts')
          .delete()
          .eq('contact_id', contactId);

      await loadContacts();

      return {
        'success': true,
        'message': 'Contact deleted successfully',
      };
    } catch (e) {
      print('Error deleting contact: $e');
      return {
        'success': false,
        'message': 'Error deleting contact. Please try again.',
      };
    }
  }

  @override
  void dispose() {
    isLoading.dispose();
    emergencyContacts.dispose();
    mentalHealthHotlines.dispose();
    super.dispose();
  }
}
