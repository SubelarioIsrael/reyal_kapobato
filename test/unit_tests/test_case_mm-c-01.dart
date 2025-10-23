// MM-C-01: User chat list generation
// Requirement: When user has accepted appointments, chat list shows counselor name and last message
// Mirrors logic in `student_chat_list.dart` (group by counselor, fallback message if none)

import 'package:flutter_test/flutter_test.dart';

class MockUser {
	final String id;
	MockUser(this.id);
}

class MockDatabase {
	final List<Map<String, dynamic>> counselingAppointments = [];
	final List<Map<String, dynamic>> messages = [];
	final List<Map<String, dynamic>> counselors = [];

	void seedAppointments(List<Map<String, dynamic>> a) => counselingAppointments.addAll(a);
	void seedMessages(List<Map<String, dynamic>> m) => messages.addAll(m);
	void seedCounselors(List<Map<String, dynamic>> c) => counselors.addAll(c);

	List<Map<String, dynamic>> fetchAcceptedAppointments(String userId) {
		return counselingAppointments.where((a) => a['user_id'] == userId && a['status'] == 'accepted').toList();
	}

	List<Map<String, dynamic>> fetchMessagesForAppointments(List<int> appointmentIds, String userId) {
		return messages.where((m) => appointmentIds.contains(m['appointment_id']) && (m['sender_id'] == userId || m['receiver_id'] == userId)).toList()
			..sort((a, b) => b['created_at'].compareTo(a['created_at']));
	}

	Map<String, String>? fetchCounselorName(int counselorId) {
		final c = counselors.firstWhere((c) => c['counselor_id'] == counselorId, orElse: () => {});
		if (c.isEmpty) return null;
		return {'first_name': c['first_name'], 'last_name': c['last_name']};
	}
}

List<Map<String, dynamic>> buildChatList(MockDatabase db, String userId) {
	final accepted = db.fetchAcceptedAppointments(userId);
	if (accepted.isEmpty) return [];

	final appointmentIds = accepted.map((a) => a['appointment_id'] as int).toList();
	final msgs = db.fetchMessagesForAppointments(appointmentIds, userId);

	final Map<int, Map<String, dynamic>> map = {};

		for (var appt in accepted) {
			final apptId = appt['appointment_id'] as int;
			final counselorId = appt['counselor_id'] as int;
			if (map.containsKey(counselorId)) continue;

			final apptMessages = msgs.where((m) => m['appointment_id'] == apptId).toList();
			String lastMessage;
			String? lastMessageTime;
			bool isRead = true;

			if (apptMessages.isNotEmpty) {
					final latest = apptMessages.first;
					lastMessage = latest['message'];
					lastMessageTime = latest['created_at'];
					isRead = (latest['is_read'] ?? true) || latest['receiver_id'] != userId;
				} else {
					lastMessage = 'Appointment accepted - Start chatting!';
					lastMessageTime = appt['appointment_date'];
				}

				final counselorName = db.fetchCounselorName(counselorId);
				map[counselorId] = {
					'counselor_id': counselorId,
					'counselor_name': counselorName != null ? '${counselorName['first_name']} ${counselorName['last_name']}' : 'Unknown Counselor',
					'appointment_id': apptId,
					'last_message': lastMessage,
					'last_message_time': lastMessageTime,
					'is_read': isRead,
				};
			}

			return map.values.toList();
		}

		void main() {
			group('MM-C-01: Student chat list', () {
				final user = MockUser('student-1');
				final db = MockDatabase();

				db.seedCounselors([
					{'counselor_id': 1, 'first_name': 'Alice', 'last_name': 'Smith'},
					{'counselor_id': 2, 'first_name': 'Bob', 'last_name': 'Jones'},
				]);

				db.seedAppointments([
					{'appointment_id': 101, 'counselor_id': 1, 'user_id': user.id, 'status': 'accepted', 'appointment_date': DateTime(2025,10,20).toIso8601String()},
					{'appointment_id': 102, 'counselor_id': 2, 'user_id': user.id, 'status': 'accepted', 'appointment_date': DateTime(2025,10,19).toIso8601String()},
				]);

				db.seedMessages([
					{'id': 1, 'message': 'Hello from counselor', 'created_at': DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(), 'is_read': false, 'appointment_id': 101, 'sender_id': 1, 'receiver_id': user.id},
					{'id': 2, 'message': 'Student reply', 'created_at': DateTime.now().subtract(Duration(minutes: 4)).toIso8601String(), 'is_read': true, 'appointment_id': 101, 'sender_id': user.id, 'receiver_id': 1},
				]);

				test('Chat list includes counselor names and last messages', () {
					final chats = buildChatList(db, user.id);
					expect(chats.length, 2);
					final aliceChat = chats.firstWhere((c) => c['counselor_id'] == 1);
					expect(aliceChat['counselor_name'], 'Alice Smith');
					expect(aliceChat['last_message'], 'Student reply');

					final bobChat = chats.firstWhere((c) => c['counselor_id'] == 2);
					expect(bobChat['counselor_name'], 'Bob Jones');
					expect(bobChat['last_message'], 'Appointment accepted - Start chatting!');
				});
			});
		}
