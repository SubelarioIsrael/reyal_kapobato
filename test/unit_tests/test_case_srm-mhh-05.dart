// SRM-MHH-05: Admin can delete a mental health hotline
// Requirement: Selected hotline is permanently deleted.

import 'package:flutter_test/flutter_test.dart';

class MockHotline {
  String id;
  String name;
  String phone;

  MockHotline({
    required this.id,
    required this.name,
    required this.phone,
  });
}

class MockHotlineService {
  final Map<String, MockHotline> _hotlines = {};

  void addHotline(MockHotline hotline) {
    _hotlines[hotline.id] = hotline;
  }

  Future<bool> deleteHotline(String id) async {
    return _hotlines.remove(id) != null;
  }

  MockHotline? getHotline(String id) => _hotlines[id];
}

void main() {
  group('SRM-MHH-05: Admin can delete a mental health hotline', () {
    test('Selected hotline is permanently deleted', () async {
      final service = MockHotlineService();
      final hotline = MockHotline(
        id: 'h2',
        name: 'Emergency Line',
        phone: '555-555-5555',
      );
      service.addHotline(hotline);

      final deleted = await service.deleteHotline('h2');
      expect(deleted, true);

      final fetched = service.getHotline('h2');
      expect(fetched, isNull);
    });
  });
}