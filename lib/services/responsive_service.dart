// services/responsive_service.dart
import 'package:flutter/material.dart';

class ResponsiveService {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 800;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 800 &&
      MediaQuery.of(context).size.width < 1100;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1100;

  static double getValue(
    BuildContext context, {
    required double mobile,
    double? tablet,
    required double desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? desktop;
    return desktop;
  }

  static T getValueForScreenType<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? desktop;
    return desktop;
  }
}

// Extension method for easier access
extension ResponsiveExtension on BuildContext {
  bool get isMobile => ResponsiveService.isMobile(this);
  bool get isTablet => ResponsiveService.isTablet(this);
  bool get isDesktop => ResponsiveService.isDesktop(this);

  double responsiveValue({
    required double mobile,
    double? tablet,
    required double desktop,
  }) => ResponsiveService.getValue(
    this,
    mobile: mobile,
    tablet: tablet,
    desktop: desktop,
  );
}
