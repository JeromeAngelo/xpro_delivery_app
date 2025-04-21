// import 'package:flutter/material.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/data/models/trip_models.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/domain/usecase/search_trip.dart';
// import 'package:x_pro_delivery_app/core/services/injection_container.dart';

// class TripCodeProvider extends ChangeNotifier {
//   final SearchTrip _searchTrip = sl<SearchTrip>();
//   TripModel? _trip;
//   bool _isLoading = false;
//   String _error = '';

//   TripModel? get trip => _trip;
//   bool get isLoading => _isLoading;
//   String get error => _error;

//   Future<bool> searchTripByCode(String tripCode) async {
//     _isLoading = true;
//     _error = '';
//     notifyListeners();

//     final result = await _searchTrip(tripCode);
    
//     return result.fold(
//       (failure) {
//         _error = failure.message;
//         _trip = null;
//         _isLoading = false;
//         notifyListeners();
//         return false;
//       },
//       (tripData) {
//         _trip = tripData as TripModel;
//         // Make sure we have all expanded data
//         if (_trip != null) {
//           print('Found trip with ID: ${_trip!.id}');
//           print('Customers: ${_trip!.customers.length}');
//           }
//         _error = '';
//         _isLoading = false;
//         notifyListeners();
//         return true;
//       },
//     );
//   }
// }
