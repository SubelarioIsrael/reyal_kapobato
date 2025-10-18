// 10-05-25 BB-073: Admin removes outdated or incorrect mental health resource
// Requirement: Resource successfully removed from student-accessible library
// This test simulates the resource management logic for deleting resources

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final String userType;
	final DateTime? emailConfirmedAt;
	MockUser({required this.email, required this.id, required this.userType, this.emailConfirmedAt});
}

class MockAuthResponse {
	final MockUser? user;
	MockAuthResponse(this.user);
}

// Mock database to track resources with more detailed structure
Map<String, Map<String, dynamic>> _resourceDatabase = {
	'1': {
		'exists': true,
		'title': 'Mental Health Awareness',
		'resourceType': 'video',
		'mediaUrl': 'https://www.youtube.com/watch?v=ExD',
		'tags': 'Awareness',
	},
	'2': {
		'exists': true,
		'title': 'Stress Management Guide',
		'resourceType': 'article',
		'mediaUrl': null,
		'tags': 'Stress, Coping',
	},
	'3': {
		'exists': true,
		'title': 'Anxiety Relief Techniques',
		'resourceType': 'video',
		'mediaUrl': 'https://www.youtube.com/watch?v=AnxietyHelp',
		'tags': 'Anxiety, Relief',
	},
};

Future<MockAuthResponse> mockSignInWithPassword({required String email, required String password}) async {
	// Simulate admin credentials
	if (email == 'admin@email.com' && password == 'adminadmin') {
		return MockAuthResponse(MockUser(email: email, id: 'admin-id', userType: 'admin', emailConfirmedAt: DateTime.now()));
	}
	throw Exception('Invalid login credentials');
}

Future<bool> mockDeleteResource({
	required String adminId,
	required String resourceId,
}) async {
	// Check if resource exists
	if (!_resourceDatabase.containsKey(resourceId) || !_resourceDatabase[resourceId]!['exists']) {
		throw Exception('Resource not found');
	}
	
	// Simulate successful deletion
	_resourceDatabase[resourceId]!['exists'] = false;
	return true;
}

Future<bool> mockCheckResourceExists(String resourceId) async {
	return _resourceDatabase[resourceId]?['exists'] ?? false;
}

Future<Map<String, dynamic>?> mockGetResourceDetails(String resourceId) async {
	if (_resourceDatabase[resourceId]?['exists'] == true) {
		return _resourceDatabase[resourceId];
	}
	return null;
}

void main() {
	group('BB-073: Admin removes outdated or incorrect mental health resource', () {
		setUp(() {
			// Reset database state before each test
			_resourceDatabase = {
				'1': {
					'exists': true,
					'title': 'Mental Health Awareness',
					'resourceType': 'video',
					'mediaUrl': 'https://www.youtube.com/watch?v=ExD',
					'tags': 'Awareness',
				},
				'2': {
					'exists': true,
					'title': 'Stress Management Guide',
					'resourceType': 'article',
					'mediaUrl': null,
					'tags': 'Stress, Coping',
				},
				'3': {
					'exists': true,
					'title': 'Anxiety Relief Techniques',
					'resourceType': 'video',
					'mediaUrl': 'https://www.youtube.com/watch?v=AnxietyHelp',
					'tags': 'Anxiety, Relief',
				},
			};
		});

		test('Admin successfully removes video resource from student library', () async {
			// First authenticate admin
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'admin');
			
			// Verify video resource exists before deletion
			final resourceBefore = await mockGetResourceDetails('1');
			expect(resourceBefore, isNotNull);
			expect(resourceBefore!['resourceType'], 'video');
			expect(resourceBefore['mediaUrl'], 'https://www.youtube.com/watch?v=ExD');
			
			// Delete the video resource
			final deleteResult = await mockDeleteResource(
				adminId: authResponse.user!.id,
				resourceId: '1',
			);
			
			expect(deleteResult, true);
			
			// Verify resource no longer exists in student-accessible library
			final existsAfter = await mockCheckResourceExists('1');
			expect(existsAfter, false);
		});

		test('Attempting to delete non-existent resource throws error', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			expect(
				() => mockDeleteResource(adminId: authResponse.user!.id, resourceId: 'non-existent'),
				throwsException,
			);
		});

		test('Multiple resources can be deleted independently', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Delete first resource
			await mockDeleteResource(adminId: authResponse.user!.id, resourceId: '1');
			expect(await mockCheckResourceExists('1'), false);
			expect(await mockCheckResourceExists('2'), true);
			
			// Delete second resource
			await mockDeleteResource(adminId: authResponse.user!.id, resourceId: '2');
			expect(await mockCheckResourceExists('2'), false);
			expect(await mockCheckResourceExists('3'), true);
		});

		test('Different resource types can be deleted independently', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Delete video resource
			await mockDeleteResource(adminId: authResponse.user!.id, resourceId: '1');
			expect(await mockCheckResourceExists('1'), false);
			
			// Article resource should still exist
			final articleExists = await mockCheckResourceExists('2');
			expect(articleExists, true);
			
			// Another video resource should still exist
			final otherVideoExists = await mockCheckResourceExists('3');
			expect(otherVideoExists, true);
		});

		test('Invalid admin credentials prevent resource deletion', () async {
			expect(() => mockSignInWithPassword(email: 'admin@email.com', password: 'wrongpass'), throwsException);
		});
	});
}
