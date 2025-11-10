import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentContactsController {
  final ValueNotifier<bool> isLoading = ValueNotifier(true);
  final ValueNotifier<List<Map<String, dynamic>>> emergencyContacts = ValueNotifier([]);
  final ValueNotifier<List<Map<String, dynamic>>> mentalHealthHotlines = ValueNotifier([]);

  Future<void> loadContacts() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        isLoading.value = false;
        return;
      }

      final contactsResponse = await Supabase.instance.client
          .from('emergency_contacts')
          .select()
          .eq('user_id', userId)
          .order('contact_name');
      emergencyContacts.value = List<Map<String, dynamic>>.from(contactsResponse);

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
      mentalHealthHotlines.value = hotlinesData;
    } catch (e) {
      print('Error loading contacts: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteEmergencyContact(int contactId) async {
    await Supabase.instance.client
        .from('emergency_contacts')
        .delete()
        .eq('contact_id', contactId);
    await loadContacts();
  }

  Future<void> addOrUpdateEmergencyContact({
    required String name,
    required String relationship,
    required String contactNumber,
    int? contactId,
  }) async {
    final cleanedNumber = contactNumber.replaceAll(RegExp(r'\D'), '');
    if (contactId != null) {
      await Supabase.instance.client
          .from('emergency_contacts')
          .update({
            'contact_name': name.trim(),
            'relationship': relationship.trim(),
            'contact_number': cleanedNumber,
          })
          .eq('contact_id', contactId);
    } else {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
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
  }

  Future<void> launchCall(String phoneNumber) async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      print('Cannot launch phone call to $phoneNumber');
    }
  }
}
