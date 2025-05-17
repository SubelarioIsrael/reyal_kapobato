import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class UserService {
  static final _usernameController = StreamController<String>.broadcast();
  static Stream<String> get usernameStream => _usernameController.stream;

  static Future<String> getUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Guest';

    final response = await Supabase.instance.client
        .from('users')
        .select('username')
        .eq('user_id', user.id)
        .single();

    final username = response['username'] ?? 'Guest';
    _usernameController.add(username); // Add the username to the stream
    return username;
  }

  static Future<void> updateUsername(String newUsername) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    await Supabase.instance.client
        .from('users')
        .update({'username': newUsername}).eq('user_id', user.id);

    _usernameController.add(newUsername);
  }

  static void dispose() {
    _usernameController.close();
  }
}
