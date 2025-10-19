// UPD-UP-02: User can edit and save changes to their profile information
// Requirement: Changes are successfully validated and saved to the database
// This test simulates the profile editing and saving logic

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final String userType;
	MockUser({required this.email, required this.id, required this.userType});
}

class MockProfileUpdate {
	final String fieldName;
	final String oldValue;
	final String newValue;
	final String fieldType;
	
	MockProfileUpdate({
		required this.fieldName,
		required this.oldValue,
		required this.newValue,
		required this.fieldType,
	});
}

class MockValidationResult {
	final bool isValid;
	final String? errorMessage;
	final List<String> validationRules;
	
	MockValidationResult({
		required this.isValid,
		this.errorMessage,
		required this.validationRules,
	});
}

class MockSaveResult {
	final bool success;
	final DateTime timestamp;
	final List<MockProfileUpdate> updatedFields;
	final String? errorMessage;
	
	MockSaveResult({
		required this.success,
		required this.timestamp,
		required this.updatedFields,
		this.errorMessage,
	});
}

Future<MockUser> mockAuthenticateUser({required String userType}) async {
	return MockUser(email: '$userType@college.edu', id: '$userType-123', userType: userType);
}

Future<MockValidationResult> mockValidateFieldUpdate({
	required String fieldName,
	required String newValue,
	required String fieldType,
	required String userType,
}) async {
	List<String> validationRules = [];
	
	switch (fieldName) {
		case 'First Name':
		case 'Last Name':
			validationRules = ['Required', 'Min length: 2', 'Max length: 50', 'Letters only'];
			if (newValue.trim().isEmpty) {
				return MockValidationResult(
					isValid: false,
					errorMessage: 'Name cannot be empty',
					validationRules: validationRules,
				);
			}
			if (newValue.length < 2) {
				return MockValidationResult(
					isValid: false,
					errorMessage: 'Name must be at least 2 characters',
					validationRules: validationRules,
				);
			}
			if (newValue.length > 50) {
				return MockValidationResult(
					isValid: false,
					errorMessage: 'Name cannot exceed 50 characters',
					validationRules: validationRules,
				);
			}
			if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(newValue)) {
				return MockValidationResult(
					isValid: false,
					errorMessage: 'Name can only contain letters and spaces',
					validationRules: validationRules,
				);
			}
			break;
		case 'Bio':
			validationRules = ['Max length: 500'];
			if (newValue.length > 500) {
				return MockValidationResult(
					isValid: false,
					errorMessage: 'Bio cannot exceed 500 characters',
					validationRules: validationRules,
				);
			}
			break;
		case 'Specialization':
			validationRules = ['Required', 'Min length: 3'];
			if (newValue.trim().isEmpty) {
				return MockValidationResult(
					isValid: false,
					errorMessage: 'Specialization is required',
					validationRules: validationRules,
				);
			}
			if (newValue.length < 3) {
				return MockValidationResult(
					isValid: false,
					errorMessage: 'Specialization must be at least 3 characters',
					validationRules: validationRules,
				);
			}
			break;
		case 'Department':
			validationRules = ['Required'];
			if (newValue.trim().isEmpty) {
				return MockValidationResult(
					isValid: false,
					errorMessage: 'Department is required',
					validationRules: validationRules,
				);
			}
			break;
	}
	
	return MockValidationResult(
		isValid: true,
		validationRules: validationRules,
	);
}

Future<MockSaveResult> mockSaveProfileChanges({
	required String userId,
	required String userType,
	required List<MockProfileUpdate> updates,
}) async {
	List<MockProfileUpdate> validatedUpdates = [];
	
	// Validate all updates
	for (var update in updates) {
		final validation = await mockValidateFieldUpdate(
			fieldName: update.fieldName,
			newValue: update.newValue,
			fieldType: update.fieldType,
			userType: userType,
		);
		
		if (!validation.isValid) {
			return MockSaveResult(
				success: false,
				timestamp: DateTime.now(),
				updatedFields: [],
				errorMessage: validation.errorMessage,
			);
		}
		
		// Only add if value actually changed
		if (update.oldValue != update.newValue) {
			validatedUpdates.add(update);
		}
	}
	
	// Simulate database save
	await Future.delayed(const Duration(milliseconds: 100));
	
	return MockSaveResult(
		success: true,
		timestamp: DateTime.now(),
		updatedFields: validatedUpdates,
	);
}

void main() {
	group('UPD-UP-02: User can edit and save changes to their profile information', () {
		test('Student successfully updates editable personal information', () async {
			final user = await mockAuthenticateUser(userType: 'student');
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'First Name',
					oldValue: 'John',
					newValue: 'Jonathan',
					fieldType: 'text',
				),
				MockProfileUpdate(
					fieldName: 'Last Name',
					oldValue: 'Doe',
					newValue: 'Smith',
					fieldType: 'text',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			expect(result.success, true);
			expect(result.updatedFields.length, 2);
			expect(result.errorMessage, isNull);
			expect(result.timestamp, isA<DateTime>());
			
			// Verify the specific updates
			final firstNameUpdate = result.updatedFields.firstWhere((u) => u.fieldName == 'First Name');
			expect(firstNameUpdate.newValue, 'Jonathan');
			
			final lastNameUpdate = result.updatedFields.firstWhere((u) => u.fieldName == 'Last Name');
			expect(lastNameUpdate.newValue, 'Smith');
		});

		test('Counselor successfully updates professional information', () async {
			final user = await mockAuthenticateUser(userType: 'counselor');
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'Specialization',
					oldValue: 'General Counseling',
					newValue: 'Anxiety and Depression Therapy',
					fieldType: 'text',
				),
				MockProfileUpdate(
					fieldName: 'Bio',
					oldValue: 'Experienced counselor.',
					newValue: 'Licensed counselor with 10 years of experience specializing in anxiety, depression, and student mental health support.',
					fieldType: 'textarea',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			expect(result.success, true);
			expect(result.updatedFields.length, 2);
			expect(result.errorMessage, isNull);
			
			final bioUpdate = result.updatedFields.firstWhere((u) => u.fieldName == 'Bio');
			expect(bioUpdate.newValue, contains('Licensed counselor'));
		});

		test('Admin successfully updates administrative information', () async {
			final user = await mockAuthenticateUser(userType: 'admin');
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'Department',
					oldValue: 'IT Services',
					newValue: 'Student Affairs Technology',
					fieldType: 'text',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			expect(result.success, true);
			expect(result.updatedFields.length, 1);
			expect(result.updatedFields[0].newValue, 'Student Affairs Technology');
		});

		test('Validation prevents saving invalid name with special characters', () async {
			final user = await mockAuthenticateUser(userType: 'student');
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'First Name',
					oldValue: 'John',
					newValue: 'John@123',
					fieldType: 'text',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			expect(result.success, false);
			expect(result.updatedFields.length, 0);
			expect(result.errorMessage, 'Name can only contain letters and spaces');
		});

		test('Validation prevents saving empty required fields', () async {
			final user = await mockAuthenticateUser(userType: 'counselor');
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'Specialization',
					oldValue: 'General Counseling',
					newValue: '',
					fieldType: 'text',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			expect(result.success, false);
			expect(result.errorMessage, 'Specialization is required');
		});

		test('Validation prevents saving names that are too short', () async {
			final user = await mockAuthenticateUser(userType: 'student');
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'First Name',
					oldValue: 'John',
					newValue: 'J',
					fieldType: 'text',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			expect(result.success, false);
			expect(result.errorMessage, 'Name must be at least 2 characters');
		});

		test('Validation prevents saving bio that exceeds character limit', () async {
			final user = await mockAuthenticateUser(userType: 'counselor');
			
			final longBio = 'This is a very long bio that exceeds the maximum character limit. ' * 10;
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'Bio',
					oldValue: 'Short bio',
					newValue: longBio,
					fieldType: 'textarea',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			expect(result.success, false);
			expect(result.errorMessage, 'Bio cannot exceed 500 characters');
		});

		test('No changes are saved when values remain the same', () async {
			final user = await mockAuthenticateUser(userType: 'student');
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'First Name',
					oldValue: 'John',
					newValue: 'John', // Same value
					fieldType: 'text',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			expect(result.success, true);
			expect(result.updatedFields.length, 0); // No actual changes
		});

		test('Multiple valid updates are processed together successfully', () async {
			final user = await mockAuthenticateUser(userType: 'counselor');
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'First Name',
					oldValue: 'Sarah',
					newValue: 'Sarah Jane',
					fieldType: 'text',
				),
				MockProfileUpdate(
					fieldName: 'Specialization',
					oldValue: 'General',
					newValue: 'Cognitive Behavioral Therapy',
					fieldType: 'text',
				),
				MockProfileUpdate(
					fieldName: 'Bio',
					oldValue: 'Counselor',
					newValue: 'Experienced CBT specialist focusing on student anxiety and academic stress.',
					fieldType: 'textarea',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			expect(result.success, true);
			expect(result.updatedFields.length, 3);
			expect(result.errorMessage, isNull);
			
			// Verify all fields were updated
			final fieldNames = result.updatedFields.map((u) => u.fieldName).toList();
			expect(fieldNames, contains('First Name'));
			expect(fieldNames, contains('Specialization'));
			expect(fieldNames, contains('Bio'));
		});

		test('Field validation rules are appropriate for each field type', () async {
			// Test First Name validation
			final nameValidation = await mockValidateFieldUpdate(
				fieldName: 'First Name',
				newValue: 'Valid Name',
				fieldType: 'text',
				userType: 'student',
			);
			
			expect(nameValidation.isValid, true);
			expect(nameValidation.validationRules, contains('Required'));
			expect(nameValidation.validationRules, contains('Min length: 2'));
			expect(nameValidation.validationRules, contains('Letters only'));
			
			// Test Bio validation
			final bioValidation = await mockValidateFieldUpdate(
				fieldName: 'Bio',
				newValue: 'Valid bio text',
				fieldType: 'textarea',
				userType: 'counselor',
			);
			
			expect(bioValidation.isValid, true);
			expect(bioValidation.validationRules, contains('Max length: 500'));
		});

		test('Save operation includes proper timestamp for audit trail', () async {
			final user = await mockAuthenticateUser(userType: 'student');
			final beforeSave = DateTime.now();
			
			final updates = [
				MockProfileUpdate(
					fieldName: 'First Name',
					oldValue: 'John',
					newValue: 'Johnny',
					fieldType: 'text',
				),
			];
			
			final result = await mockSaveProfileChanges(
				userId: user.id,
				userType: user.userType,
				updates: updates,
			);
			
			final afterSave = DateTime.now();
			
			expect(result.success, true);
			expect(result.timestamp.isAfter(beforeSave), true);
			expect(result.timestamp.isBefore(afterSave), true);
		});
	});
}
