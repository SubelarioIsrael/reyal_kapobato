import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class RoundedButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const RoundedButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  // @override
  // Widget build(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
  //     child: InkWell(
  //       onTap: onTap,
  //       borderRadius: BorderRadius.circular(20),
  //       child: Container(
  //         width: 400,
  //         height: 200,
  //         decoration: BoxDecoration(
  //           color: Colors.white,
  //           borderRadius: BorderRadius.circular(20),
  //           boxShadow: [
  //             BoxShadow(
  //               color: Colors.grey.shade300,
  //               blurRadius: 10,
  //               offset: const Offset(0, 5),
  //             ),
  //           ],
  //         ),
  //         child: Column(
  //           mainAxisAlignment: MainAxisAlignment.center,
  //           children: [
  //             Icon(icon, color: const Color(0xFF81C784), size: 50),
  //             const SizedBox(height: 12),
  //             Text(
  //               label,
  //               textAlign: TextAlign.center,
  //               style: const TextStyle(
  //                 fontSize: 18,
  //                 fontWeight: FontWeight.w600,
  //                 color: Colors.black87,
  //               ),
  //             ),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveUtils.getResponsiveHorizontalPadding(context),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(25),
        child: Container(
          width: double.infinity, // Full width
          height: ResponsiveUtils.getResponsiveCardHeight(context),
          decoration: BoxDecoration(
            color: const Color.fromARGB(
              255,
              105,
              176,
              110,
            ), // Soft pastel green color
            borderRadius: BorderRadius.circular(25),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: Colors.white,
                size: ResponsiveUtils.getResponsiveIconSize(
                  context,
                  small: 40.0,
                  medium: 45.0,
                  large: 50.0,
                ),
              ),
              SizedBox(height: ResponsiveUtils.getResponsiveSpacing(context)),
              ResponsiveUtils.responsiveText(
                context,
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: ResponsiveUtils.getResponsiveFontSize(
                    context,
                    small: 16.0,
                    medium: 18.0,
                    large: 20.0,
                  ),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
