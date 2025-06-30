import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool useSafeArea;
  final bool scrollable;
  final ScrollPhysics? scrollPhysics;
  final bool maintainBottomViewPadding;

  const ResponsiveWrapper({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.useSafeArea = true,
    this.scrollable = false,
    this.scrollPhysics,
    this.maintainBottomViewPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = child;

    // Add padding if specified
    if (padding != null) {
      wrappedChild = Padding(
        padding: padding!,
        child: wrappedChild,
      );
    }

    // Add margin if specified
    if (margin != null) {
      wrappedChild = Padding(
        padding: margin!,
        child: wrappedChild,
      );
    }

    // Make scrollable if requested
    if (scrollable) {
      wrappedChild = ResponsiveUtils.scrollableWrapper(
        context,
        child: wrappedChild,
        physics: scrollPhysics,
      );
    }

    // Add SafeArea if requested
    if (useSafeArea) {
      wrappedChild = ResponsiveUtils.safeAreaWrapper(
        context,
        child: wrappedChild,
        maintainBottomViewPadding: maintainBottomViewPadding,
      );
    }

    return wrappedChild;
  }
}

class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? width;
  final double? height;
  final BoxDecoration? decoration;
  final AlignmentGeometry? alignment;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.width,
    this.height,
    this.decoration,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.responsiveContainer(
      context,
      child: child,
      padding: padding,
      margin: margin,
      width: width,
      height: height,
      decoration: decoration,
    );
  }
}

class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.responsiveText(
      context,
      text,
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;

  const ResponsiveButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.responsiveButton(
      context,
      text: text,
      onPressed: onPressed,
      icon: icon,
      backgroundColor: backgroundColor,
      textColor: textColor,
      width: width,
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final double? elevation;
  final BorderRadius? borderRadius;

  const ResponsiveCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.responsiveCard(
      context,
      child: child,
      padding: padding,
      margin: margin,
      color: color,
      elevation: elevation,
      borderRadius: borderRadius,
    );
  }
}

class ResponsiveListView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;

  const ResponsiveListView({
    super.key,
    required this.children,
    this.padding,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.responsiveListView(
      context,
      children: children,
      padding: padding,
      physics: physics,
    );
  }
}

class ResponsiveGridView extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;
  final double? childAspectRatio;

  const ResponsiveGridView({
    super.key,
    required this.children,
    this.padding,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
    this.childAspectRatio,
  });

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.responsiveGridView(
      context,
      children: children,
      padding: padding,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio,
    );
  }
}
