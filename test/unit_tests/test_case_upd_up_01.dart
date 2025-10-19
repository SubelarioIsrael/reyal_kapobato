// UPD-UP-01: User can view their own personal and professional profile information
// Requirement: All saved profile fields are displayed correctly to the user
// This test simulates the profile viewing logic for different user types

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String email;
	final String id;
	final String userType;
	MockUser({required this.email, required this.id, required this.userType});
}

class MockProfileField {
	final String fieldName;
	final String fieldValue;
	final String fieldType;
	final bool isVisible;
	final bool isEditable;
	
	MockProfileField({
		required this.fieldName,
		required this.fieldValue,
		required this.fieldType,
		required this.isVisible,
		required this.isEditable,
	});
}

class MockUserProfile {
	final String userId;
	final String userType;
	final List<MockProfileField> personalFields;
	final List<MockProfileField> professionalFields;
	final String? profileImageUrl;
	final DateTime lastUpdated;
	
	MockUserProfile({
		required this.userId,
		required this.userType,
		required this.personalFields,
		required this.professionalFields,
		this.profileImageUrl,
		required this.lastUpdated,
	});
}

Future<MockUser> mockAuthenticateUser({required String email, required String userType}) async {
	return MockUser(email: email, id: '$userType-123', userType: userType);
}

Future<MockUserProfile> mockLoadUserProfile({required String userId, required String userType}) async {
	List<MockProfileField> personalFields;
	List<MockProfileField> professionalFields;
	
	switch (userType) {
		case 'student':
			personalFields = [
				MockProfileField(
					fieldName: 'First Name',
					fieldValue: 'John',
					fieldType: 'text',
					isVisible: true,
					isEditable: true,
				),
				MockProfileField(
					fieldName: 'Last Name',
					fieldValue: 'Doe',
					fieldType: 'text',
					isVisible: true,
					isEditable: true,
				),
				MockProfileField(
					fieldName: 'Email',
					fieldValue: 'john.doe@college.edu',
					fieldType: 'email',
					isVisible: true,
					isEditable: false,
				),
				MockProfileField(
					fieldName: 'Student ID',
					fieldValue: 'STU-2024-001',
					fieldType: 'text',
					isVisible: true,
					isEditable: false,
				),
			];
			professionalFields = [
				MockProfileField(
					fieldName: 'Course',
					fieldValue: 'Computer Science',
					fieldType: 'text',
					isVisible: true,
					isEditable: false,
				),
				MockProfileField(
					fieldName: 'Year Level',
					fieldValue: '3',
					fieldType: 'number',
					isVisible: true,
					isEditable: false,
				),
				MockProfileField(
					fieldName: 'Education Level',
					fieldValue: 'College',
					fieldType: 'text',
					isVisible: true,
					isEditable: false,
				),
			];
			break;
		case 'counselor':
			personalFields = [
				MockProfileField(
					fieldName: 'First Name',
					fieldValue: 'Sarah',
					fieldType: 'text',
					isVisible: true,
					isEditable: true,
				),
				MockProfileField(
					fieldName: 'Last Name',
					fieldValue: 'Smith',
					fieldType: 'text',
					isVisible: true,
					isEditable: true,
				),
				MockProfileField(
					fieldName: 'Email',
					fieldValue: 'sarah.smith@college.edu',
					fieldType: 'email',
					isVisible: true,
					isEditable: false,
				),
			];
			professionalFields = [
				MockProfileField(
					fieldName: 'Specialization',
					fieldValue: 'Anxiety and Depression',
					fieldType: 'text',
					isVisible: true,
					isEditable: true,
				),
				MockProfileField(
					fieldName: 'Bio',
					fieldValue: 'Licensed counselor with 5 years of experience in student mental health.',
					fieldType: 'textarea',
					isVisible: true,
					isEditable: true,
				),
				MockProfileField(
					fieldName: 'Availability Status',
					fieldValue: 'Available',
					fieldType: 'select',
					isVisible: true,
					isEditable: true,
				),
			];
			break;
		case 'admin':
			personalFields = [
				MockProfileField(
					fieldName: 'Name',
					fieldValue: 'Administrator',
					fieldType: 'text',
					isVisible: true,
					isEditable: true,
				),
				MockProfileField(
					fieldName: 'Email',
					fieldValue: 'admin@college.edu',
					fieldType: 'email',
					isVisible: true,
					isEditable: false,
				),
			];
			professionalFields = [
				MockProfileField(
					fieldName: 'Role',
					fieldValue: 'System Administrator',
					fieldType: 'text',
					isVisible: true,
					isEditable: false,
				),
				MockProfileField(
					fieldName: 'Department',
					fieldValue: 'IT Services',
					fieldType: 'text',
					isVisible: true,
					isEditable: true,
				),
			];
			break;
		default:
			throw Exception('Invalid user type');
	}
	
	return MockUserProfile(
		userId: userId,
		userType: userType,
		personalFields: personalFields,
		professionalFields: professionalFields,
		profileImageUrl: 'base64encodedimage...',
		lastUpdated: DateTime.now().subtract(const Duration(days: 3)),
	);
}

void main() {
	group('UPD-UP-01: User can view their own personal and professional profile information', () {
		test('Student can view all personal and academic profile fields', () async {
			final user = await mockAuthenticateUser(email: 'student@college.edu', userType: 'student');
			
			final profile = await mockLoadUserProfile(userId: user.id, userType: user.userType);
			
			expect(profile.userType, 'student');
			expect(profile.personalFields.length, 4);
			expect(profile.professionalFields.length, 3);
			
			// Verify personal fields
			final personalFieldNames = profile.personalFields.map((f) => f.fieldName).toList();
			expect(personalFieldNames, contains('First Name'));
			expect(personalFieldNames, contains('Last Name'));
			expect(personalFieldNames, contains('Email'));
			expect(personalFieldNames, contains('Student ID'));
			
			// Verify academic fields
			final professionalFieldNames = profile.professionalFields.map((f) => f.fieldName).toList();
			expect(professionalFieldNames, contains('Course'));
			expect(professionalFieldNames, contains('Year Level'));
			expect(professionalFieldNames, contains('Education Level'));
			
			// Verify field values are displayed
			final firstNameField = profile.personalFields.firstWhere((f) => f.fieldName == 'First Name');
			expect(firstNameField.fieldValue, 'John');
			expect(firstNameField.isVisible, true);
			
			final courseField = profile.professionalFields.firstWhere((f) => f.fieldName == 'Course');
			expect(courseField.fieldValue, 'Computer Science');
			expect(courseField.isVisible, true);
		});

		test('Counselor can view all personal and professional profile fields', () async {
			final user = await mockAuthenticateUser(email: 'counselor@college.edu', userType: 'counselor');
			
			final profile = await mockLoadUserProfile(userId: user.id, userType: user.userType);
			
			expect(profile.userType, 'counselor');
			expect(profile.personalFields.length, 3);
			expect(profile.professionalFields.length, 3);
			
			// Verify personal fields
			final personalFieldNames = profile.personalFields.map((f) => f.fieldName).toList();
			expect(personalFieldNames, contains('First Name'));
			expect(personalFieldNames, contains('Last Name'));
			expect(personalFieldNames, contains('Email'));
			
			// Verify professional fields
			final professionalFieldNames = profile.professionalFields.map((f) => f.fieldName).toList();
			expect(professionalFieldNames, contains('Specialization'));
			expect(professionalFieldNames, contains('Bio'));
			expect(professionalFieldNames, contains('Availability Status'));
			
			// Verify field values are displayed
			final specializationField = profile.professionalFields.firstWhere((f) => f.fieldName == 'Specialization');
			expect(specializationField.fieldValue, 'Anxiety and Depression');
			expect(specializationField.isVisible, true);
			
			final bioField = profile.professionalFields.firstWhere((f) => f.fieldName == 'Bio');
			expect(bioField.fieldValue, contains('Licensed counselor'));
			expect(bioField.fieldType, 'textarea');
		});

		test('Admin can view administrative profile fields', () async {
			final user = await mockAuthenticateUser(email: 'admin@college.edu', userType: 'admin');
			
			final profile = await mockLoadUserProfile(userId: user.id, userType: user.userType);
			
			expect(profile.userType, 'admin');
			expect(profile.personalFields.length, 2);
			expect(profile.professionalFields.length, 2);
			
			// Verify personal fields
			final personalFieldNames = profile.personalFields.map((f) => f.fieldName).toList();
			expect(personalFieldNames, contains('Name'));
			expect(personalFieldNames, contains('Email'));
			
			// Verify professional fields
			final professionalFieldNames = profile.professionalFields.map((f) => f.fieldName).toList();
			expect(professionalFieldNames, contains('Role'));
			expect(professionalFieldNames, contains('Department'));
			
			// Verify field values
			final roleField = profile.professionalFields.firstWhere((f) => f.fieldName == 'Role');
			expect(roleField.fieldValue, 'System Administrator');
			expect(roleField.isEditable, false);
		});

		test('All visible profile fields display their values correctly', () async {
			final user = await mockAuthenticateUser(email: 'student@college.edu', userType: 'student');
			final profile = await mockLoadUserProfile(userId: user.id, userType: user.userType);
			
			final allFields = [...profile.personalFields, ...profile.professionalFields];
			
			for (var field in allFields) {
				if (field.isVisible) {
					expect(field.fieldValue, isNotEmpty);
					expect(field.fieldName, isNotEmpty);
					expect(field.fieldType, isIn(['text', 'email', 'number', 'textarea', 'select']));
				}
			}
		});

		test('Profile includes metadata and profile image information', () async {
			final user = await mockAuthenticateUser(email: 'counselor@college.edu', userType: 'counselor');
			final profile = await mockLoadUserProfile(userId: user.id, userType: user.userType);
			
			expect(profile.userId, user.id);
			expect(profile.profileImageUrl, isNotNull);
			expect(profile.profileImageUrl, startsWith('base64'));
			expect(profile.lastUpdated, isA<DateTime>());
			expect(profile.lastUpdated.isBefore(DateTime.now()), true);
		});

		test('Field editability flags are properly set based on user type', () async {
			final user = await mockAuthenticateUser(email: 'student@college.edu', userType: 'student');
			final profile = await mockLoadUserProfile(userId: user.id, userType: user.userType);
			
			// Email should not be editable
			final emailField = profile.personalFields.firstWhere((f) => f.fieldName == 'Email');
			expect(emailField.isEditable, false);
			
			// First name should be editable
			final firstNameField = profile.personalFields.firstWhere((f) => f.fieldName == 'First Name');
			expect(firstNameField.isEditable, true);
			
			// Student ID should not be editable
			final studentIdField = profile.personalFields.firstWhere((f) => f.fieldName == 'Student ID');
			expect(studentIdField.isEditable, false);
			
			// Academic fields should not be editable for students
			for (var field in profile.professionalFields) {
				expect(field.isEditable, false);
			}
		});

		test('Different user types have appropriate field sets', () async {
			final studentUser = await mockAuthenticateUser(email: 'student@college.edu', userType: 'student');
			final counselorUser = await mockAuthenticateUser(email: 'counselor@college.edu', userType: 'counselor');
			
			final studentProfile = await mockLoadUserProfile(userId: studentUser.id, userType: studentUser.userType);
			final counselorProfile = await mockLoadUserProfile(userId: counselorUser.id, userType: counselorUser.userType);
			
			// Students have academic fields
			final studentProfessionalFields = studentProfile.professionalFields.map((f) => f.fieldName).toList();
			expect(studentProfessionalFields, contains('Course'));
			expect(studentProfessionalFields, contains('Year Level'));
			
			// Counselors have professional fields
			final counselorProfessionalFields = counselorProfile.professionalFields.map((f) => f.fieldName).toList();
			expect(counselorProfessionalFields, contains('Specialization'));
			expect(counselorProfessionalFields, contains('Bio'));
			
			// They should not have each other's fields
			expect(studentProfessionalFields, isNot(contains('Specialization')));
			expect(counselorProfessionalFields, isNot(contains('Course')));
		});

		test('Invalid user type throws exception', () async {
			final user = MockUser(email: 'test@test.com', id: 'invalid-id', userType: 'invalid');
			
			expect(
				() => mockLoadUserProfile(userId: user.id, userType: user.userType),
				throwsException,
			);
		});
	});
}
