import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double screenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double screenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  static bool isSmallScreen(BuildContext context) {
    return screenWidth(context) < 360;
  }

  static bool isMediumScreen(BuildContext context) {
    return screenWidth(context) >= 360 && screenWidth(context) < 600;
  }

  static bool isLargeScreen(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  static double getResponsivePaddingValue(BuildContext context) {
    if (isSmallScreen(context)) return 12.0;
    if (isMediumScreen(context)) return 16.0;
    return 24.0;
  }

  static double getResponsiveFontSize(
    BuildContext context, {
    double small = 12.0,
    double medium = 14.0,
    double large = 16.0,
  }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }

  static double getResponsiveIconSize(
    BuildContext context, {
    double small = 20.0,
    double medium = 24.0,
    double large = 28.0,
  }) {
    if (isSmallScreen(context)) return small;
    if (isMediumScreen(context)) return medium;
    return large;
  }

  static EdgeInsets getResponsivePadding(BuildContext context) {
    double padding = getResponsivePaddingValue(context);
    return EdgeInsets.all(padding);
  }

  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    double padding = getResponsivePaddingValue(context);
    return EdgeInsets.symmetric(horizontal: padding);
  }

  static double getResponsiveButtonHeight(BuildContext context) {
    if (isSmallScreen(context)) return 45.0;
    if (isMediumScreen(context)) return 50.0;
    return 56.0;
  }

  static double getResponsiveCardHeight(BuildContext context) {
    if (isSmallScreen(context)) return 120.0;
    if (isMediumScreen(context)) return 140.0;
    return 160.0;
  }

  static int getResponsiveGridCrossAxisCount(BuildContext context) {
    if (isSmallScreen(context)) return 1;
    if (isMediumScreen(context)) return 2;
    return 3;
  }

  static double getResponsiveChildAspectRatio(BuildContext context) {
    if (isSmallScreen(context)) return 1.0;
    if (isMediumScreen(context)) return 1.2;
    return 1.4;
  }

  static double getResponsiveSpacing(BuildContext context) {
    if (isSmallScreen(context)) return 8.0;
    if (isMediumScreen(context)) return 12.0;
    return 16.0;
  }

  static Widget responsiveText(
    BuildContext context,
    String text, {
    TextStyle? style,
    TextAlign? textAlign,
    int? maxLines,
    TextOverflow? overflow,
  }) {
    return Text(
      text,
      style: style?.copyWith(
        fontSize: getResponsiveFontSize(
          context,
          small: style?.fontSize ?? 14.0,
          medium: (style?.fontSize ?? 14.0) + 1,
          large: (style?.fontSize ?? 14.0) + 2,
        ),
      ),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.ellipsis,
    );
  }

  static Widget responsiveContainer(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    double? width,
    double? height,
    BoxDecoration? decoration,
  }) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: padding ?? getResponsivePadding(context),
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }

  static Widget responsiveButton(
    BuildContext context, {
    required String text,
    required VoidCallback onPressed,
    IconData? icon,
    Color? backgroundColor,
    Color? textColor,
    double? width,
  }) {
    return SizedBox(
      width: width ?? double.infinity,
      height: getResponsiveButtonHeight(context),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: getResponsiveIconSize(context)),
              SizedBox(width: getResponsiveSpacing(context)),
            ],
            responsiveText(
              context,
              text,
              style: TextStyle(
                fontSize: getResponsiveFontSize(
                  context,
                  small: 14.0,
                  medium: 16.0,
                  large: 18.0,
                ),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget responsiveCard(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Color? color,
    double? elevation,
    BorderRadius? borderRadius,
  }) {
    return Card(
      margin: margin ?? EdgeInsets.all(getResponsiveSpacing(context)),
      elevation: elevation ?? 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
      ),
      color: color,
      child: Padding(
        padding: padding ?? getResponsivePadding(context),
        child: child,
      ),
    );
  }

  static Widget responsiveListView(
    BuildContext context, {
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
  }) {
    return ListView(
      padding: padding ?? getResponsivePadding(context),
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      children: children,
    );
  }

  static Widget responsiveGridView(
    BuildContext context, {
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
    double? crossAxisSpacing,
    double? mainAxisSpacing,
    double? childAspectRatio,
  }) {
    return GridView.count(
      crossAxisCount: getResponsiveGridCrossAxisCount(context),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: padding ?? getResponsivePadding(context),
      crossAxisSpacing: crossAxisSpacing ?? getResponsiveSpacing(context),
      mainAxisSpacing: mainAxisSpacing ?? getResponsiveSpacing(context),
      childAspectRatio:
          childAspectRatio ?? getResponsiveChildAspectRatio(context),
      children: children,
    );
  }

  static Widget safeAreaWrapper(
    BuildContext context, {
    required Widget child,
    bool maintainBottomViewPadding = true,
  }) {
    return SafeArea(
      maintainBottomViewPadding: maintainBottomViewPadding,
      child: child,
    );
  }

  static Widget scrollableWrapper(
    BuildContext context, {
    required Widget child,
    EdgeInsetsGeometry? padding,
    ScrollPhysics? physics,
  }) {
    return SingleChildScrollView(
      padding: padding ?? getResponsivePadding(context),
      physics: physics ?? const AlwaysScrollableScrollPhysics(),
      child: child,
    );
  }

  static Widget flexibleWrapper(
    BuildContext context, {
    required Widget child,
    int flex = 1,
  }) {
    return Flexible(
      flex: flex,
      child: child,
    );
  }

  static Widget expandedWrapper(
    BuildContext context, {
    required Widget child,
    int flex = 1,
  }) {
    return Expanded(
      flex: flex,
      child: child,
    );
  }
}
