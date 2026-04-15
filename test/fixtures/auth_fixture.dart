import 'dart:convert';

import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/models/trip_models.dart';

class AuthFixture {
  AuthFixture._();

  // Mock user data JSON
  static const String tUserJson = '''
  {
    "id": "test-user-id-123",
    "collectionId": "users_collection_id",
    "collectionName": "users",
    "email": "test@example.com",
    "name": "Test User",
    "tripNumberId": "trip-123",
    "tokenKey": "test-auth-token-12345"
  }
  ''';

  static Map<String, dynamic> get userJson => jsonDecode(tUserJson);

  static LocalUsersModel get tUser => LocalUsersModel(
        id: 'test-user-id-123',
        collectionId: 'users_collection_id',
        collectionName: 'users',
        email: 'test@example.com',
        name: 'Test User',
        tripNumberId: 'trip-123',
        token: 'test-auth-token-12345',
      );

  static const String tEmail = 'test@example.com';
  static const String tPassword = 'password123';
  static const String tToken = 'test-auth-token-12345';
  static const String tUserId = 'test-user-id-123';

  // Mock trip data
  static const String tTripJson = '''
  {
    "id": "trip-id-123",
    "collectionId": "tripticket_collection_id",
    "collectionName": "tripticket",
    "name": "Test Trip",
    "tripNumberId": "trip-123",
    "qrCode": "qr-code-string",
    "isAccepted": false,
    "isEndTrip": false,
    "deliveryDate": "2024-01-01T00:00:00Z",
    "latitude": 14.5995,
    "longitude": 120.9842
  }
  ''';

  static Map<String, dynamic> get tripJson => jsonDecode(tTripJson);

  static TripModel get tTrip => TripModel(
        id: 'trip-id-123',
        name: 'Test Trip',
        tripNumberId: 'trip-123',
        qrCode: 'qr-code-string',
        isAccepted: false,
        isEndTrip: false,
        deliveryDate: DateTime(2024, 1, 1),
        latitude: 14.5995,
        longitude: 120.9842,
      );

  // Error messages
  static const String tServerErrorMessage = 'Authentication failed';
  static const String tCacheErrorMessage = 'No stored user data found';
  static const String tServerErrorCode = '500';
  static const String tNotFoundErrorCode = '404';
}
