import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RouteUtils {
  static const String _lastRouteKey = 'last_active_route';
  
  // Save the current route
  static Future<void> saveCurrentRoute(String route) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastRouteKey, route);
    debugPrint('📝 Saved current route: $route');
  }
  
  // Get the last active route
  static Future<String?> getLastActiveRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final route = prefs.getString(_lastRouteKey);
    debugPrint('🔍 Retrieved last active route: $route');
    return route;
  }
  
  // Clear the saved route
  static Future<void> clearSavedRoute() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastRouteKey);
    debugPrint('🧹 Cleared saved route');
  }
}
