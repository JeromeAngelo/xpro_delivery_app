import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/usecases/get_customer.dart';
import 'package:x_pro_delivery_app/core/services/injection_container.dart';
class CustomerProvider extends ChangeNotifier {
  final GetCustomer _getCustomer = sl<GetCustomer>();
  List<CustomerModel> _customers = [];
  bool _isLoading = false;
  String _error = '';
  String? _currentTripId;

  List<CustomerModel> get customers => _customers;
  bool get isLoading => _isLoading;
  String get error => _error;
  String? get currentTripId => _currentTripId;

  Future<void> fetchCustomers(String tripId) async {
    _isLoading = true;
    _error = '';
    _currentTripId = tripId;
    notifyListeners();

    debugPrint('🔄 Loading customers for trip: $tripId');
    final result = await _getCustomer(tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load customers: ${failure.message}');
        _error = failure.message;
        _customers = [];
      },
      (customersList) {
        debugPrint('✅ Loaded ${customersList.length} customers');
        _customers = customersList.cast<CustomerModel>();
        _error = '';
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadLocalCustomers(String tripId) async {
    _isLoading = true;
    _error = '';
    _currentTripId = tripId;
    notifyListeners();

    debugPrint('📱 Loading local customers for trip: $tripId');
    final result = await _getCustomer.loadFromLocal(tripId);
    
    result.fold(
      (failure) {
        debugPrint('❌ Failed to load local customers: ${failure.message}');
        _error = failure.message;
        _customers = [];
      },
      (customersList) {
        debugPrint('✅ Loaded ${customersList.length} local customers');
        _customers = customersList.cast<CustomerModel>();
        _error = '';
      },
    );

    _isLoading = false;
    notifyListeners();
  }

  void clearCustomers() {
    _customers = [];
    _error = '';
    _currentTripId = null;
    notifyListeners();
  }
}
