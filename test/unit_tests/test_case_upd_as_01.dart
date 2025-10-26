// UPD-AS-01: User can enable or disable push notifications
// Requirement: Users should be able to toggle notification settings and have them persist

import 'package:flutter_test/flutter_test.dart';

class MockSharedPreferences {
  final Map<String, dynamic> _storage = {};
  
  Future<bool> setBool(String key, bool value) async {
    await Future.delayed(Duration(milliseconds: 50)); // Simulate async operation
    _storage[key] = value;
    return true;
  }
  
  bool? getBool(String key) {
    return _storage[key] as bool?;
  }
}

class MockSupabaseClient {
  final Map<String, Map<String, dynamic>> _tables = {
    'users': {},
    'counselors': {},
  };
  
  MockTable from(String table) {
    return MockTable(table, _tables[table]!);
  }
}

class MockTable {
  final String tableName;
  final Map<String, dynamic> data;
  
  MockTable(this.tableName, this.data);
  
  MockTable update(Map<String, dynamic> updates) {
    // Simulate database update
    Future.delayed(Duration(milliseconds: 100)).then((_) {
      data.addAll(updates);
    });
    return this;
  }
  
  Future<void> eq(String column, dynamic value) async {
    // Simulate the final execution of the query
    await Future.delayed(Duration(milliseconds: 100));
    // In a real implementation, this would filter by the column/value
    // For our mock, we just complete the chain
  }
}

class MockNotificationService {
  final MockSharedPreferences prefs;
  final MockSupabaseClient supabase;
  bool _notificationsEnabled = true;
  String _userType = 'student';
  String _userId = 'user123';
  
  MockNotificationService(this.prefs, this.supabase);
  
  void setUserType(String userType) {
    _userType = userType;
  }
  
  bool get notificationsEnabled => _notificationsEnabled;
  
  Future<void> loadSettings() async {
    final notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    _notificationsEnabled = notificationsEnabled;
  }
  
  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    
    // Save to SharedPreferences
    await prefs.setBool('notifications_enabled', value);
    
    // Update database based on user type
    if (_userType == 'counselor') {
      await supabase
          .from('counselors')
          .update({'notifications_enabled': value})
          .eq('user_id', _userId);
    } else {
      await supabase
          .from('users')
          .update({'notifications_enabled': value})
          .eq('user_id', _userId);
    }
  }
}

void main() {
  group('UPD-AS-01: User can enable or disable push notifications', () {
    late MockSharedPreferences prefs;
    late MockSupabaseClient supabase;
    late MockNotificationService notificationService;
    
    setUp(() {
      prefs = MockSharedPreferences();
      supabase = MockSupabaseClient();
      notificationService = MockNotificationService(prefs, supabase);
    });

    test('User can enable notifications', () async {
      // Start with notifications disabled
      await prefs.setBool('notifications_enabled', false);
      await notificationService.loadSettings();
      
      expect(notificationService.notificationsEnabled, isFalse);
      
      // Enable notifications
      await notificationService.toggleNotifications(true);
      
      expect(notificationService.notificationsEnabled, isTrue);
      expect(prefs.getBool('notifications_enabled'), isTrue);
    });

    test('User can disable notifications', () async {
      // Start with notifications enabled
      await prefs.setBool('notifications_enabled', true);
      await notificationService.loadSettings();
      
      expect(notificationService.notificationsEnabled, isTrue);
      
      // Disable notifications
      await notificationService.toggleNotifications(false);
      
      expect(notificationService.notificationsEnabled, isFalse);
      expect(prefs.getBool('notifications_enabled'), isFalse);
    });

    test('Notification settings persist in SharedPreferences', () async {
      // Enable notifications
      await notificationService.toggleNotifications(true);
      expect(prefs.getBool('notifications_enabled'), isTrue);
      
      // Disable notifications
      await notificationService.toggleNotifications(false);
      expect(prefs.getBool('notifications_enabled'), isFalse);
      
      // Enable again
      await notificationService.toggleNotifications(true);
      expect(prefs.getBool('notifications_enabled'), isTrue);
    });

    test('Default notification setting is enabled', () async {
      // No previous setting stored
      await notificationService.loadSettings();
      
      expect(notificationService.notificationsEnabled, isTrue);
    });

    test('Student notification settings update users table', () async {
      notificationService.setUserType('student');
      
      await notificationService.toggleNotifications(true);
      
      // Verify database would be updated (in mock, data is stored)
      final usersTable = supabase._tables['users']!;
      expect(usersTable['notifications_enabled'], isTrue);
    });

    test('Counselor notification settings update counselors table', () async {
      notificationService.setUserType('counselor');
      
      await notificationService.toggleNotifications(false);
      
      // Verify database would be updated (in mock, data is stored)
      final counselorsTable = supabase._tables['counselors']!;
      expect(counselorsTable['notifications_enabled'], isFalse);
    });

    test('Multiple notification toggles work correctly', () async {
      // Toggle multiple times
      await notificationService.toggleNotifications(true);
      expect(notificationService.notificationsEnabled, isTrue);
      
      await notificationService.toggleNotifications(false);
      expect(notificationService.notificationsEnabled, isFalse);
      
      await notificationService.toggleNotifications(true);
      expect(notificationService.notificationsEnabled, isTrue);
      
      // Final state should be enabled
      expect(prefs.getBool('notifications_enabled'), isTrue);
    });

    test('Loading settings from SharedPreferences works correctly', () async {
      // Set initial state in SharedPreferences
      await prefs.setBool('notifications_enabled', false);
      
      // Load settings
      await notificationService.loadSettings();
      
      expect(notificationService.notificationsEnabled, isFalse);
      
      // Change SharedPreferences value
      await prefs.setBool('notifications_enabled', true);
      
      // Load settings again
      await notificationService.loadSettings();
      
      expect(notificationService.notificationsEnabled, isTrue);
    });
  });
}
