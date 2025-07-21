import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ResponsiveUtils {
  // Screen breakpoints
  static bool isMobile(BuildContext context) => 
      MediaQuery.of(context).size.width <= 450;
  
  static bool isTablet(BuildContext context) => 
      MediaQuery.of(context).size.width > 450 && 
      MediaQuery.of(context).size.width <= 800;
  
  static bool isDesktop(BuildContext context) => 
      MediaQuery.of(context).size.width > 800;

  // Responsive sizing using ScreenUtil
  static double responsiveWidth(double width) => width.w;
  static double responsiveHeight(double height) => height.h;
  static double responsiveFontSize(double fontSize) => fontSize.sp;
  static double responsiveRadius(double radius) => radius.r;

  // Adaptive padding based on screen size
  static EdgeInsets adaptivePadding(BuildContext context, {
    double mobile = 16.0,
    double tablet = 24.0,
    double desktop = 32.0,
  }) {
    if (isMobile(context)) return EdgeInsets.all(mobile.w);
    if (isTablet(context)) return EdgeInsets.all(tablet.w);
    return EdgeInsets.all(desktop.w);
  }

  // Adaptive font size based on screen size
  static double adaptiveFontSize(BuildContext context, {
    double mobile = 14.0,
    double tablet = 16.0,
    double desktop = 18.0,
  }) {
    if (isMobile(context)) return mobile.sp;
    if (isTablet(context)) return tablet.sp;
    return desktop.sp;
  }

  // Grid columns based on screen size
  static int getGridColumns(BuildContext context) {
    if (isMobile(context)) return 1;
    if (isTablet(context)) return 2;
    return 3;
  }

  // App bar height based on screen size
  static double getAppBarHeight(BuildContext context) {
    if (isMobile(context)) return 56.h;
    if (isTablet(context)) return 64.h;
    return 72.h;
  }
}
