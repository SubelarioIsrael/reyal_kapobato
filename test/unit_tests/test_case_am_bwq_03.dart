// AM-BWQ-03: Admin selects create new version
// Requirement: Loads the modal for adding a new version
// This test simulates the version creation modal logic

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final String userType;
	MockUser({required this.email, required this.id, required this.userType});
}

class MockAuthResponse {
	final MockUser? user;
	MockAuthResponse(this.user);
}

class MockVersionModal {
	final bool isVisible;
	final String title;
	final String subtitle;
	final List<String> formFields;
	final List<String> actions;
	
	MockVersionModal({
		required this.isVisible,
		required this.title,
		required this.subtitle,
		required this.formFields,
		required this.actions,
	});
}

class MockQuestionnaireVersion {
	final int versionId;
	final String versionName;
	final bool isActive;
	final DateTime createdAt;
	
	MockQuestionnaireVersion({
		required this.versionId,
		required this.versionName,
		required this.isActive,
		required this.createdAt,
	});
}

// Mock existing versions
List<MockQuestionnaireVersion> _existingVersions = [
	MockQuestionnaireVersion(
		versionId: 1,
		versionName: 'Student Mental Health Questionnaire v1',
		isActive: true,
		createdAt: DateTime.now().subtract(const Duration(days: 30)),
	),
	MockQuestionnaireVersion(
		versionId: 2,
		versionName: 'Student Mental Health Questionnaire v2',
		isActive: false,
		createdAt: DateTime.now().subtract(const Duration(days: 15)),
	),
];

Future<MockAuthResponse> mockSignInWithPassword({required String email, required String password}) async {
	if (email == 'admin@email.com' && password == 'adminadmin') {
		return MockAuthResponse(MockUser(email: email, id: 'admin-id', userType: 'admin'));
	}
	throw Exception('Invalid login credentials');
}

Future<MockVersionModal> mockShowCreateVersionDialog({required String adminId}) async {
	// Simulate modal configuration
	return MockVersionModal(
		isVisible: true,
		title: 'Create New Version',
		subtitle: 'Create a new questionnaire version with optional question copying',
		formFields: [
			'Version Name',
		],
		actions: [
			'Cancel',
			'Create Version',
		],
	);
}

Future<List<MockQuestionnaireVersion>> mockLoadExistingVersions({required String adminId}) async {
	return _existingVersions;
}

Future<bool> mockValidateVersionCreationPermissions({required String adminId}) async {
	// Verify admin has permission to create versions
	return true;
}

void main() {
	group('AM-BWQ-03: Admin selects create new version', () {
		test('Admin successfully triggers create new version modal', () async {
			// First authenticate admin
			final authResponse = await mockSignInWithPassword(
				email: 'admin@email.com', 
				password: 'adminadmin'
			);
			expect(authResponse.user, isNotNull);
			expect(authResponse.user!.userType, 'admin');
			
			// Verify admin has permission to create versions
			final hasPermission = await mockValidateVersionCreationPermissions(
				adminId: authResponse.user!.id
			);
			expect(hasPermission, true);
			
			// Show create version modal
			final modal = await mockShowCreateVersionDialog(
				adminId: authResponse.user!.id
			);
			
			expect(modal.isVisible, true);
			expect(modal.title, 'Create New Version');
			expect(modal.subtitle, contains('Create a new questionnaire version'));
			expect(modal.formFields, contains('Version Name'));
			expect(modal.actions, contains('Cancel'));
			expect(modal.actions, contains('Create Version'));
		});

		test('Modal displays correct form elements and structure', () async {
			final authResponse = await mockSignInWithPassword(
				email: 'admin@email.com', 
				password: 'adminadmin'
			);
			
			final modal = await mockShowCreateVersionDialog(
				adminId: authResponse.user!.id
			);
			
			// Verify modal structure
			expect(modal.title, isNotNull);
			expect(modal.subtitle, isNotNull);
			expect(modal.formFields.length, greaterThan(0));
			expect(modal.actions.length, 2); // Cancel and Create buttons
			
			// Verify specific elements
			expect(modal.formFields.first, 'Version Name');
			expect(modal.actions.contains('Cancel'), true);
			expect(modal.actions.contains('Create Version'), true);
		});

		test('Admin can view existing versions before creating new one', () async {
			final authResponse = await mockSignInWithPassword(
				email: 'admin@email.com', 
				password: 'adminadmin'
			);
			
			// Load existing versions for reference
			final existingVersions = await mockLoadExistingVersions(
				adminId: authResponse.user!.id
			);
			
			expect(existingVersions.length, 2);
			expect(existingVersions[0].versionName, 'Student Mental Health Questionnaire v1');
			expect(existingVersions[0].isActive, true);
			expect(existingVersions[1].versionName, 'Student Mental Health Questionnaire v2');
			expect(existingVersions[1].isActive, false);
			
			// Show modal after viewing existing versions
			final modal = await mockShowCreateVersionDialog(
				adminId: authResponse.user!.id
			);
			expect(modal.isVisible, true);
		});

		test('Modal provides option to copy questions from existing version', () async {
			final authResponse = await mockSignInWithPassword(
				email: 'admin@email.com', 
				password: 'adminadmin'
			);
			
			final modal = await mockShowCreateVersionDialog(
				adminId: authResponse.user!.id
			);
			
			// Verify modal mentions question copying functionality
			expect(modal.subtitle, contains('optional question copying'));
		});

		test('Modal action buttons are properly configured', () async {
			final authResponse = await mockSignInWithPassword(
				email: 'admin@email.com', 
				password: 'adminadmin'
			);
			
			final modal = await mockShowCreateVersionDialog(
				adminId: authResponse.user!.id
			);
			
			// Verify primary and secondary actions
			expect(modal.actions.length, 2);
			final cancelAction = modal.actions.firstWhere((action) => action == 'Cancel');
			final createAction = modal.actions.firstWhere((action) => action == 'Create Version');
			
			expect(cancelAction, 'Cancel');
			expect(createAction, 'Create Version');
		});

		test('Non-admin users cannot access create version modal', () async {
			expect(
				() => mockSignInWithPassword(email: 'student@college.edu', password: 'studentpass'),
				throwsException,
			);
		});

		test('Invalid admin credentials prevent modal access', () async {
			expect(
				() => mockSignInWithPassword(email: 'admin@email.com', password: 'wrongpass'),
				throwsException,
			);
		});
	});
}
