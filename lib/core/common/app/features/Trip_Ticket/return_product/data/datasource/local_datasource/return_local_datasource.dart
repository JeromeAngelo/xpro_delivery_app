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
        '🔍 Processing return: ${returnItem.productName} (PocketBase ID: ${returnItem.pocketbaseId})',
      );

      final existingReturn =
          _returnBox
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
    final invalidReturns =
        _returnBox
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
      // Validate input
      if (tripId.isEmpty) {
        debugPrint('⚠️ Warning: Empty tripId provided to getReturns');
        return [];
      }

      // Clean up invalid entries first
      await cleanupInvalidEntries();

      debugPrint('🔍 Fetching local returns for trip: $tripId');

      // Build and execute query
      final query =
          _returnBox.query(ReturnModel_.tripId.equals(tripId)).build();

      try {
        final rawReturns = query.find();

        // Filter out invalid entries
        final returns =
            rawReturns
                .where(
                  (r) => r.productName != null && r.pocketbaseId.isNotEmpty,
                )
                .toList();

        // Log statistics
        debugPrint('📊 Local Returns Stats:');
        debugPrint('   📦 Total Returns Found: ${rawReturns.length}');
        debugPrint('   📦 Total Valid Returns: ${returns.length}');

        // Log details of each return for debugging
        if (returns.isNotEmpty) {
          debugPrint('   📝 Return Details:');
          for (var returnItem in returns) {
            try {
              debugPrint('      🏷️ ID: ${returnItem.id ?? 'N/A'}');
              debugPrint(
                '      🏷️ Product: ${returnItem.productName ?? 'N/A'}',
              );
              debugPrint(
                '      📦 Quantity Case: ${returnItem.productQuantityCase ?? 0}',
              );
              debugPrint(
                '      📦 Quantity Pcs: ${returnItem.productQuantityPcs ?? 0}',
              );
              debugPrint(
                '      📦 Quantity Pack: ${returnItem.productQuantityPack ?? 0}',
              );
              debugPrint(
                '      📦 Quantity Box: ${returnItem.productQuantityBox ?? 0}',
              );
              debugPrint(
                '      ❌ Reason: ${returnItem.reason?.toString() ?? 'N/A'}',
              );
              debugPrint(
                '      👤 Customer: ${returnItem.customer?.storeName ?? 'N/A'}',
              );
              debugPrint(
                '      📅 Return Date: ${returnItem.returnDate?.toString() ?? 'N/A'}',
              );
              debugPrint('      -------------------');
            } catch (logError) {
              debugPrint('      ⚠️ Error logging return details: $logError');
            }
          }
        } else {
          debugPrint('   ℹ️ No valid returns found for this trip');
        }

        // Close the query to free resources
        query.close();

        return returns;
      } finally {
        // Ensure query is closed even if an exception occurs
        query.close();
      }
    } catch (e) {
      debugPrint(
        '❌ Error fetching returns from local storage: ${e.toString()}',
      );
      debugPrint('   Stack trace: ${StackTrace.current}');

      // Rethrow as CacheException with detailed message
      throw CacheException(
        message:
            'Failed to retrieve returns from local storage: ${e.toString()}',
      );
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

      final returnItem =
          _returnBox
              .query(ReturnModel_.pocketbaseId.equals(customerId))
              .build()
              .findFirst();

      if (returnItem == null) {
        throw const CacheException(
          message: 'Return not found in local storage',
        );
      }

      debugPrint(
        '✅ Found return for customer: ${returnItem.customer?.storeName}',
      );
      return returnItem;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
