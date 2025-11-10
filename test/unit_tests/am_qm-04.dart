// AM-QM-04: Admin can add and delete a new version of questionnaire
// Requirement: Changes work as expected with validation to prevent duplication and deleting currently activated versions
// This test simulates the version creation and deletion logic

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final String userType;
	MockUser({required this.email, required this.id, required this.userType});
}

class MockValidationResult {
	final bool isValid;
	final String? errorMessage;
	
	MockValidationResult({
		required this.isValid,
		this.errorMessage,
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

Future<MockUser> mockAuthenticateAdmin() async {
	return MockUser(email: 'admin@email.com', id: 'admin-123', userType: 'admin');
}

Future<MockValidationResult> mockValidateVersionName({required String versionName}) async {
	// Validate version name is not empty
	if (versionName.trim().isEmpty) {
		return MockValidationResult(
			isValid: false,
			errorMessage: 'Version name is required',
		);
	}
	
	// Additional validation rules
	if (versionName.trim().length < 3) {
		return MockValidationResult(
			isValid: false,
			errorMessage: 'Version name must be at least 3 characters long',
		);
	}
	
	return MockValidationResult(isValid: true);
}

Future<MockQuestionnaireVersion> mockCreateVersion({
	required String adminId,
	required String versionName,
	List<MockQuestionnaireVersion>? versionList,
}) async {
	// Validate before creating
	final validation = await mockValidateVersionName(versionName: versionName);
	if (!validation.isValid) {
		throw Exception(validation.errorMessage);
	}
	
	// Check for duplicate version name
	final versions = versionList ?? _existingVersions;
	final isDuplicate = await mockCheckDuplicateVersionName(versionName: versionName, versionList: versions);
	if (isDuplicate) {
		throw Exception('Version name already exists');
	}
	
	// Create new version
	final newVersion = MockQuestionnaireVersion(
		versionId: DateTime.now().millisecondsSinceEpoch,
		versionName: versionName.trim(),
		isActive: false, // New versions start as inactive
		createdAt: DateTime.now(),
	);
	versions.add(newVersion);
	return newVersion;
}

Future<bool> mockDeleteVersion({
	required String adminId,
	required int versionId,
	List<MockQuestionnaireVersion>? versionList,
}) async {
	final versions = versionList ?? _existingVersions;
	final version = versions.firstWhere((v) => v.versionId == versionId, orElse: () => throw Exception('Version not found'));
	if (version == null) throw Exception('Version not found');
	if (version.isActive) throw Exception('Cannot delete currently activated version');
	versions.removeWhere((v) => v.versionId == versionId);
	return true;
}

Future<bool> mockCheckDuplicateVersionName({
	required String versionName,
	List<MockQuestionnaireVersion>? versionList,
}) async {
	final versions = versionList ?? _existingVersions;
	return versions.any((v) => v.versionName.trim().toLowerCase() == versionName.trim().toLowerCase());
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

void main() {
	group('AM-QM-04: Admin can add and delete a new version of questionnaire', () {
		test('Empty version name fails validation with required message', () async {
			final admin = await mockAuthenticateAdmin();
			
			// Validate empty version name
			final validation = await mockValidateVersionName(versionName: '');
			
			expect(validation.isValid, false);
			expect(validation.errorMessage, 'Version name is required');
		});

		test('Whitespace-only version name fails validation', () async {
			final admin = await mockAuthenticateAdmin();
			
			// Test with spaces only
			final validation = await mockValidateVersionName(versionName: '   ');
			
			expect(validation.isValid, false);
			expect(validation.errorMessage, 'Version name is required');
		});

		test('Version creation with empty name throws exception', () async {
			final admin = await mockAuthenticateAdmin();
			
			expect(
				() => mockCreateVersion(
					adminId: admin.id,
					versionName: '',
				),
				throwsA(predicate((e) => e.toString().contains('Version name is required'))),
			);
		});

		test('Version creation with whitespace name throws exception', () async {
			final admin = await mockAuthenticateAdmin();
			
			expect(
				() => mockCreateVersion(
					adminId: admin.id,
					versionName: '  \t  ',
				),
				throwsA(predicate((e) => e.toString().contains('Version name is required'))),
			);
		});

		test('Very short version name fails validation', () async {
			final admin = await mockAuthenticateAdmin();
			
			final validation = await mockValidateVersionName(versionName: 'v1');
			
			expect(validation.isValid, false);
			expect(validation.errorMessage, 'Version name must be at least 3 characters long');
		});

		test('Valid version name passes validation', () async {
			final admin = await mockAuthenticateAdmin();
			
			final validation = await mockValidateVersionName(
				versionName: 'Student Mental Health Questionnaire v3'
			);
			
			expect(validation.isValid, true);
			expect(validation.errorMessage, isNull);
		});

		test('Valid version creation succeeds after validation', () async {
			final admin = await mockAuthenticateAdmin();
			
			final version = await mockCreateVersion(
				adminId: admin.id,
				versionName: 'New Mental Health Assessment',
			);
			
			expect(version.versionName, 'New Mental Health Assessment');
			expect(version.isActive, false);
			expect(version.versionId, isNotNull);
			expect(version.createdAt, isNotNull);
		});

		test('Version creation trims whitespace from valid names', () async {
			final admin = await mockAuthenticateAdmin();
			
			final version = await mockCreateVersion(
				adminId: admin.id,
				versionName: '  Mental Health Survey v4  ',
			);
			
			expect(version.versionName, 'Mental Health Survey v4');
		});

		test('Duplicate version name fails validation', () async {
			final admin = await mockAuthenticateAdmin();
			final versionName = 'Student Mental Health Questionnaire v1';
			final isDuplicate = await mockCheckDuplicateVersionName(versionName: versionName, versionList: _existingVersions);
			expect(isDuplicate, true);
		});

		test('Deleting active version fails', () async {
			final admin = await mockAuthenticateAdmin();
			expect(
				() => mockDeleteVersion(adminId: admin.id, versionId: 1, versionList: _existingVersions),
				throwsA(predicate((e) => e.toString().contains('Cannot delete currently activated version'))),
			);
		});

		test('Deleting inactive version succeeds', () async {
			final admin = await mockAuthenticateAdmin();
			final result = await mockDeleteVersion(adminId: admin.id, versionId: 2, versionList: _existingVersions);
			expect(result, true);
		});
	});
}