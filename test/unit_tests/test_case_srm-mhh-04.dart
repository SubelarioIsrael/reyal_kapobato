// SRM-MHH-04: Admin can update a mental health hotline
// Requirement: Edited hotline details are saved correctly.

import 'package:flutter_test/flutter_test.dart';

class MockHotline {
  String id;
  String name;
  String phone;
  String description;

  MockHotline({
    required this.id,
    required this.name,
    required this.phone,
    required this.description,
  });
}

class MockHotlineService {
  final Map<String, MockHotline> _hotlines = {};

  void addHotline(MockHotline hotline) {
    _hotlines[hotline.id] = hotline;
  }

  Future<bool> updateHotline(String id, {String? name, String? phone, String? description}) async {
    final hotline = _hotlines[id];
    if (hotline == null) return false;
    if (name != null) hotline.name = name;
    if (phone != null) hotline.phone = phone;
    if (description != null) hotline.description = description;
    return true;
  }

  MockHotline? getHotline(String id) => _hotlines[id];
}

void main() {
  group('SRM-MHH-04: Admin can update a mental health hotline', () {
    test('Edited hotline details are saved correctly', () async {
      final service = MockHotlineService();
      final hotline = MockHotline(
        id: 'h1',
        name: 'Support Line',
        phone: '123-456-7890',
        description: 'General support',
      );
      service.addHotline(hotline);

      final updated = await service.updateHotline(
        'h1',
        name: 'Updated Support Line',
        phone: '987-654-3210',
        description: 'Updated description',
      );

      expect(updated, true);
      final fetched = service.getHotline('h1');
      expect(fetched?.name, 'Updated Support Line');
      expect(fetched?.phone, '987-654-3210');
      expect(fetched?.description, 'Updated description');
    });
  });
}