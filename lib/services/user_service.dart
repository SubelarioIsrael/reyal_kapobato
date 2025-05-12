import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  static Future<String> getUsername() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 'Guest';

    final response =
        await Supabase.instance.client
            .from('users')
            .select('username')
            .eq('user_id', user.id)
            .single();

    return response['username'] ?? 'Guest';
  }
}
