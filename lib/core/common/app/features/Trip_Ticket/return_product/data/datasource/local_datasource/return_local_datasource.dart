import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/data/model/return_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

abstract class ReturnLocalDatasource {
  Future<List<ReturnModel>> getReturns(String tripId);
  Future<ReturnModel> getReturnByCustomerId(String customerId);
  Future<void> updateReturn(ReturnModel returnItem);
  Future<void> cleanupInvalidEntries();
}

class ReturnLocalDatasourceImpl implements ReturnLocalDatasource {
  final Box<ReturnModel> _returnBox;

  ReturnLocalDatasourceImpl(this._returnBox);

  Future<void> _autoSave(ReturnModel returnItem) async {
    try {
      if (returnItem.productName == null || returnItem.pocketbaseId.isEmpty) {
        debugPrint('⚠️ Skipping invalid return data');
        return;
      }

      debugPrint(
          '🔍 Processing return: ${returnItem.productName} (PocketBase ID: ${returnItem.pocketbaseId})');

      final existingReturn = _returnBox
          .query(ReturnModel_.pocketbaseId.equals(returnItem.pocketbaseId))
          .build()
          .findFirst();

      if (existingReturn != null) {
        debugPrint('🔄 Updating existing return: ${returnItem.productName}');
        returnItem.objectBoxId = existingReturn.objectBoxId;
      } else {
        debugPrint('➕ Adding new return: ${returnItem.productName}');
      }

      _returnBox.put(returnItem);
      final totalReturns = _returnBox.count();
      debugPrint('📊 Current total valid returns: $totalReturns');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cleanupInvalidEntries() async {
    final invalidReturns = _returnBox
        .getAll()
        .where((r) => r.productName == null || r.pocketbaseId.isEmpty)
        .toList();

    if (invalidReturns.isNotEmpty) {
      debugPrint('🧹 Removing ${invalidReturns.length} invalid returns');
      _returnBox.removeMany(invalidReturns.map((r) => r.objectBoxId).toList());
    }
  }
@override
Future<List<ReturnModel>> getReturns(String tripId) async {
  try {
    await cleanupInvalidEntries();
    
    debugPrint('🔍 Fetching local returns for trip: $tripId');
    
    final returns = _returnBox
        .query(ReturnModel_.tripId.equals(tripId))
        .build()
        .find()
        .where((r) => r.productName != null && r.pocketbaseId.isNotEmpty)
        .toList();

    debugPrint('📊 Local Returns Stats:');
    debugPrint('   📦 Total Valid Returns: ${returns.length}');

    for (var returnItem in returns) {
      debugPrint('   📝 Return Details:');
      debugPrint('      🏷️ Product: ${returnItem.productName}');
      debugPrint('      📦 Quantity: ${returnItem.productQuantityCase}');
      debugPrint('      ❌ Reason: ${returnItem.reason}');
    }

    return returns;
  } catch (e) {
    throw CacheException(message: e.toString());
  }
}


  @override
  Future<void> updateReturn(ReturnModel returnItem) async {
    try {
      debugPrint('💾 Processing return: ${returnItem.productName}');
      debugPrint('   📦 Quantity: ${returnItem.productQuantityCase}');
      debugPrint('   ❌ Reason: ${returnItem.reason}');
      await _autoSave(returnItem);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<ReturnModel> getReturnByCustomerId(String customerId) async {
    try {
      debugPrint('🔍 Fetching local return data for customer ID: $customerId');

      await cleanupInvalidEntries();

      final returnItem = _returnBox
          .query(ReturnModel_.pocketbaseId.equals(customerId))
          .build()
          .findFirst();

      if (returnItem == null) {
        throw const CacheException(message: 'Return not found in local storage');
      }

      debugPrint(
          '✅ Found return for customer: ${returnItem.customer?.storeName}');
      return returnItem;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
