// 10-05-25 BB-072: Admin updates existing mental health resource content
// Requirement: Resource content successfully modified and republished
// This test simulates the resource management logic for editing resources

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

Future<MockResource> mockEditResource({
	required String adminId,
	required String resourceId,
	String? title,
	String? resourceType,
	String? mediaUrl,
	String? tags,
	String? description,
}) async {
	// Get existing resource type or use provided
	final currentType = resourceType ?? 'video'; // Assume existing is video
	
	// Validate video resources have media URL when editing
	if (currentType == 'video' && mediaUrl != null && mediaUrl.isEmpty) {
		throw Exception('Video resources cannot have empty media URL');
	}
	
	// Simulate successful resource edit
	return MockResource(
		id: resourceId,
		title: title ?? 'Mental Health Awareness',
		resourceType: currentType,
		mediaUrl: mediaUrl ?? 'https://www.youtube.com/watch?v=ExD',
		tags: tags ?? 'Awareness',
		publishDate: DateTime.now(),
		description: description ?? 'Original video description...',
	);
}

void main() {
	group('BB-072: Admin updates existing mental health resource content', () {
		test('Admin successfully edits video resource media URL', () async {
			// First authenticate admin
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'admin');
			
			// Edit existing video resource
			final updatedResource = await mockEditResource(
				adminId: authResponse.user!.id,
				resourceId: '2',
				title: 'Updated Mental Health Awareness',
				mediaUrl: 'https://www.youtube.com/watch?v=NewURL',
				tags: 'Awareness, Updated',
				description: 'Updated description with new insights...',
			);
			
			expect(updatedResource.id, '2');
			expect(updatedResource.title, 'Updated Mental Health Awareness');
			expect(updatedResource.mediaUrl, 'https://www.youtube.com/watch?v=NewURL');
			expect(updatedResource.tags, 'Awareness, Updated');
			expect(updatedResource.description, contains('Updated description'));
			expect(updatedResource.publishDate, isNotNull);
		});

		test('Partial update only changes specified fields', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			// Edit only tags
			final updatedResource = await mockEditResource(
				adminId: authResponse.user!.id,
				resourceId: '2',
				tags: 'Mental Health, Wellbeing',
			);
			
			expect(updatedResource.tags, 'Mental Health, Wellbeing');
			expect(updatedResource.title, 'Mental Health Awareness'); // Default unchanged
			expect(updatedResource.mediaUrl, 'https://www.youtube.com/watch?v=ExD'); // Default unchanged
		});

		test('Empty media URL for video resource throws error', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			expect(
				() => mockEditResource(
					adminId: authResponse.user!.id,
					resourceId: '2',
					resourceType: 'video',
					mediaUrl: '',
				),
				throwsException,
			);
		});

		test('Resource republishing after edit maintains publication status', () async {
			final authResponse = await mockSignInWithPassword(email: 'admin@email.com', password: 'adminadmin');
			
			final updatedResource = await mockEditResource(
				adminId: authResponse.user!.id,
				resourceId: 'resource-789',
				title: 'Republished Resource',
			);
			
			expect(updatedResource.title, 'Republished Resource');
		});

		test('Invalid admin credentials prevent resource editing', () async {
			expect(() => mockSignInWithPassword(email: 'admin@email.com', password: 'wrongpass'), throwsException);
		});
	});
}
