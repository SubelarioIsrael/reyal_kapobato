import 'package:breathe_better/constant/constant.dart';
import 'package:flutter/material.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CallPage extends StatelessWidget {
  const CallPage({
    Key? key, 
    required this.callID,
    required this.userID,
    required this.userName,
    this.appointmentId,
    this.studentUserId,
    this.counselorId,
  }) : super(key: key);
  
  final String callID;
  final String userID;
  final String userName;
  final int? appointmentId;
  final String? studentUserId;
  final int? counselorId;


  @override
  Widget build(BuildContext context) {
    final config = ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall();

    return ZegoUIKitPrebuiltCall(
      appID: AppInfo.appId, // Fill in the appID that you get from ZEGOCLOUD Admin Console.
      appSign: AppInfo.appSign, // Fill in the appSign that you get from ZEGOCLOUD Admin Console.
      userID: userID,
      userName: userName,
      callID: callID,
      config: config,
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (event, defaultAction) {
          // Handle our logic first, then call defaultAction
          _handleCallEnd(context, callID, defaultAction);
        },
      ),
    );
  }

  Future<void> _handleCallEnd(BuildContext context, String callID, VoidCallback defaultAction) async {
    try {
      // Check if current user is a counselor
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        return;
      }

      // Update video call status for all users
      await _updateVideoCallStatus(callID);
      defaultAction.call();
    } catch (e) {
      // Still update call status even if there's an error
      await _updateVideoCallStatus(callID);
    }
  }

  Future<void> _updateVideoCallStatus(String callID) async {
    try {
      await Supabase.instance.client
          .from('video_calls')
          .update({
            'status': 'ended',
            'ended_at': DateTime.now().toIso8601String(),
          })
          .eq('call_code', callID);
    } catch (e) {
      print('Error updating video call status: $e');
    }
  }
}