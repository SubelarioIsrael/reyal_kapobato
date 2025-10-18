// 10-05-25 BB-071: Admin uploads new mental health resource article
// Requirement: Resource successfully added and categorized for student access
// This test simulates the resource management logic for adding resources

import 'package:flutter_test/flutter_test.dart';

class MockResource {
	final String id;
	final String title;
	final String resourceType;
	final String? mediaUrl;
	final String tags;
	final DateTime publishDate;
	final String description;
	
	MockResource({
		required this.id,
		required this.title,
		required this.resourceType,
		this.mediaUrl,
		required this.tags,
		required this.publishDate,
		required this.description,
	});
}

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

Future<MockAuthResponse> mockSignInWithPassword({required String email, required String password}) async {
	// Simulate admin credentials
	if (email == 'admin@email.com' && password == 'adminadmin') {
		return MockAuthResponse(MockUser(email: email, id: 'admin-id', userType: 'admin', emailConfirmedAt: DateTime.now()));
	}
	throw Exception('Invalid login credentials');
}

Future<MockResource> mockAddResource({
	required String adminId,
	required String title,
	required String resourceType,
	String? mediaUrl,
	required String tags,
	required String description,
}) async {
	// Validate video resources have media URL
	if (resourceType == 'video' && (mediaUrl == null || mediaUrl.isEmpty)) {
		throw Exception('Video resources must have a media URL');
	}
	
	// Simulate successful resource addition
	return MockResource(
		id: '${DateTime.now().millisecondsSinceEpoch}',
		title: title,
		resourceType: resourceType,
		mediaUrl: mediaUrl,
		tags: tags,
		publishDate: DateTime.now(),
		description: description,
	);
}

void main() {
	group('BB-071: Admin uploads new mental health resource', () {
		test('Admin successfully adds video resource with media URL', () async {
			// First authenticate admin
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'admin');
			
			// Add new video resource
			final resource = await mockAddResource(
				adminId: authResponse.user!.id,
				title: 'Mental Health Awareness',
				resourceType: 'video',
				mediaUrl: 'https://www.youtube.com/watch?v=ExD',
				tags: 'Awareness',
				description: 'Kumusta ka? Maaring ikaw ay masaya, nerbiyoso',
			);
			
			expect(resource.title, 'Mental Health Awareness');
			expect(resource.resourceType, 'video');
			expect(resource.mediaUrl, 'https://www.youtube.com/watch?v=ExD');
			expect(resource.tags, 'Awareness');
			expect(resource.description, contains('Kumusta ka?'));
			expect(resource.id, isNotNull);
			expect(resource.publishDate, isNotNull);
		});

		test('Admin successfully adds article resource without media URL', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Add article resource
			final resource = await mockAddResource(
				adminId: authResponse.user!.id,
				title: 'Managing Stress in College',
				resourceType: 'article',
				tags: 'Stress, Coping',
				description: 'Practical strategies for managing academic stress...',
			);
			
			expect(resource.resourceType, 'article');
			expect(resource.mediaUrl, isNull);
			expect(resource.tags, 'Stress, Coping');
		});

		test('Video resource without media URL throws error', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			expect(
				() => mockAddResource(
					adminId: authResponse.user!.id,
					title: 'Video Without URL',
					resourceType: 'video',
					tags: 'Test',
					description: 'This should fail',
				),
				throwsException,
			);
		});

		test('Multiple resource categories are supported', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Add stress management resource
			final stressResource = await mockAddResource(
				adminId: authResponse.user!.id,
				title: 'Stress Management Techniques',
				resourceType: 'guide',
				tags: 'Stress',
				description: 'Learn effective stress management methods...',
			);
			
			expect(stressResource.resourceType, 'guide');
			expect(stressResource.tags, 'Stress');
		});

		test('Invalid admin credentials prevent resource addition', () async {
			expect(() => mockSignInWithPassword(email: 'admin@email.com', password: 'wrongpass'), throwsException);
		});
	});
}
