import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentWellnessResourcesController with ChangeNotifier {
  final isLoading = ValueNotifier<bool>(true);
  final videos = ValueNotifier<List<Map<String, dynamic>>>([]);
  final articles = ValueNotifier<List<Map<String, dynamic>>>([]);

  void init() {
    loadResources();
  }

  Future<Map<String, dynamic>> loadResources() async {
    isLoading.value = true;

    try {
      final response = await Supabase.instance.client
          .from('mental_health_resources')
          .select()
          .order('title');

      final resourcesList = response as List;

      videos.value = resourcesList
          .where((resource) => resource['resource_type'] == 'video')
          .map((resource) => resource as Map<String, dynamic>)
          .toList();

      articles.value = resourcesList
          .where((resource) => resource['resource_type'] == 'article')
          .map((resource) => resource as Map<String, dynamic>)
          .toList();

      isLoading.value = false;

      return {'success': true};
    } catch (e) {
      print('Error loading resources: $e');
      isLoading.value = false;
      return {
        'success': false,
        'message': 'Error loading resources. Please try again later.',
      };
    }
  }

  @override
  void dispose() {
    isLoading.dispose();
    videos.dispose();
    articles.dispose();
    super.dispose();
  }
}
