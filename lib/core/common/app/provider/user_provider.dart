import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/models/delivery_team_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/entity/users_entity.dart';
class UserProvider extends ChangeNotifier {
  LocalUser? _user;
  bool _isLoading = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  // Core user data
  LocalUser? get user => _user;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

   void initUser(LocalUser? user) async {
    debugPrint('🔄 Initializing user from provider');
    
    if (_user != user) {
      // Try to get stored data if user is null
      if (user == null) {
        final prefs = await SharedPreferences.getInstance();
        final storedData = prefs.getString('user_data');
        
        if (storedData != null) {
          final userData = jsonDecode(storedData);
          _user = LocalUsersModel(
            id: userData['id'],
            collectionId: userData['collectionId'],
            collectionName: userData['collectionName'],
            email: userData['email'],
            name: userData['name'],
            tripNumberId: userData['tripNumberId'],
            token: userData['tokenKey'],
          );
        }
      } else {
        _user = user;
      }
      
      debugPrint('✅ User initialized');
      debugPrint('   👤 Name: ${_user?.name}');
      debugPrint('   📧 Email: ${_user?.email}');
      debugPrint('   🎫 Trip Number: ${_user?.tripNumberId}');
      
      notifyListeners();
    }
  }

  // User profile data with real-time updates
  String? get tripNumberId {
    debugPrint('🎫 Getting Trip Number: ${_user?.tripNumberId}');
    return _user?.tripNumberId;
  }
  
  String? get userName {
    debugPrint('👤 Getting User Name: ${_user?.name}');
    return _user?.name;
  }
  
  String? get userEmail => _user?.email;
  String? get profilePic => _user?.profilePic;
  String? get userId => _user?.id;
  String? get collectionId => _user?.collectionId;
  
  // Related data with real-time updates
DeliveryTeamModel? get deliveryTeam {
  debugPrint('🚛 Getting Delivery Team: ${_user?.deliveryTeam.target?.id}');
  return _user?.deliveryTeam.target;
}

  
 TripModel? get trip {
    debugPrint('🎫 Getting Trip: ${_user?.trip.target?.tripNumberId}');
    return _user?.trip.target;
  }



  Future<void> updateUser(LocalUser? user) async {
    if (_user != user) {
      debugPrint('📝 Updating user data');
      debugPrint('   👤 Name: ${user?.name}');
      debugPrint('   🎫 Trip Number: ${user?.tripNumberId}');
      _user = user;
      notifyListeners();
    }
  }

  Future<void> refreshUser(Future<LocalUser?> Function() refreshFunction) async {
    try {
      _isLoading = true;
      _isSyncing = true;
      notifyListeners();

      debugPrint('🔄 Starting user refresh');
      final updatedUser = await refreshFunction();
      
      if (updatedUser != null) {
        debugPrint('✅ User refresh successful');
        debugPrint('   👤 Name: ${updatedUser.name}');
        debugPrint('   🎫 Trip Number: ${updatedUser.tripNumberId}');
        _user = updatedUser;
        _lastSyncTime = DateTime.now();
      }

    } catch (e) {
      debugPrint('❌ Error refreshing user: $e');
    } finally {
      _isLoading = false;
      _isSyncing = false;
      notifyListeners();
    }
  }

  bool get hasActiveTrip {
    final hasTrip = tripNumberId != null && tripNumberId!.isNotEmpty;
    debugPrint('🎫 Has Active Trip: $hasTrip');
    return hasTrip;
  }
  

  bool get needsSync {
    final shouldSync = _lastSyncTime == null || 
        DateTime.now().difference(_lastSyncTime!) > const Duration(minutes: 5);
    debugPrint('🔄 Needs Sync: $shouldSync');
    return shouldSync;
  }
}
