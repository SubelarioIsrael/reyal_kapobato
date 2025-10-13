import 'dart:convert';
import 'package:flutter/material.dart';

class HotlineAvatar extends StatelessWidget {
  final String? profilePictureUrl; // Now expects base64 data, not URL
  final double size;
  final bool isEmergency;
  final Color? backgroundColor;
  final Color? iconColor;

  const HotlineAvatar({
    super.key,
    this.profilePictureUrl,
    this.size = 60,
    this.isEmergency = false,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? 
        const Color(0xFF7C83FD).withOpacity(0.1);
    
    final iColor = iconColor ?? 
        const Color(0xFF7C83FD);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: profilePictureUrl != null && profilePictureUrl!.isNotEmpty
          ? ClipOval(
              child: _buildImageFromBase64(profilePictureUrl!, size, iColor, isEmergency),
            )
          : Icon(
              Icons.support_agent,
              color: iColor,
              size: size * 0.5,
            ),
    );
  }

  Widget _buildImageFromBase64(String base64Data, double size, Color iconColor, bool isEmergency) {
    try {
      // Decode base64 to bytes
      final bytes = base64Decode(base64Data);
      return Image.memory(
        bytes,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.support_agent,
          color: iconColor,
          size: size * 0.5,
        ),
      );
    } catch (e) {
      // If base64 decoding fails, show the default icon
      return Icon(
        Icons.support_agent,
        color: iconColor,
        size: size * 0.5,
      );
    }
  }
}