import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/datasource/local_datasource/invoice_items_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/datasource/remote_datasource/invoice_items_remote_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/data/model/invoice_items_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/domain/entity/invoice_items_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/invoice_items/domain/repo/invoice_items_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class InvoiceItemsRepoImpl implements InvoiceItemsRepo {
  const InvoiceItemsRepoImpl(this._remoteDataSource, this._localDataSource);

  final InvoiceItemsRemoteDataSource _remoteDataSource;
  final InvoiceItemsLocalDataSource _localDataSource;

  @override
  ResultFuture<List<InvoiceItemsEntity>> getInvoiceItemsByInvoiceDataId(String invoiceDataId) async {
    try {
      debugPrint('🌐 Fetching invoice items for invoice data ID: $invoiceDataId');
      final remoteInvoiceItems = await _remoteDataSource.getInvoiceItemsByInvoiceDataId(invoiceDataId);
      debugPrint('✅ Retrieved ${remoteInvoiceItems.length} invoice items for invoice data ID: $invoiceDataId');
      
      // Cache the remote data locally
      debugPrint('💾 Caching invoice items locally');
      await _localDataSource.cacheInvoiceItems(remoteInvoiceItems);
      
      return Right(remoteInvoiceItems);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      
      try {
        debugPrint('📦 Attempting to load from local storage');
        final localInvoiceItems = await _localDataSource.getInvoiceItemsByInvoiceDataId(invoiceDataId);
        debugPrint('✅ Retrieved ${localInvoiceItems.length} invoice items from local storage');
        return Right(localInvoiceItems);
      } on CacheException catch (cacheError) {
        debugPrint('❌ Local storage error: ${cacheError.message}');
      }
      
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<List<InvoiceItemsEntity>> getAllInvoiceItems() async {
    try {
      debugPrint('🌐 Fetching all invoice items from remote');
      final remoteInvoiceItems = await _remoteDataSource.getAllInvoiceItems();
      debugPrint('✅ Retrieved ${remoteInvoiceItems.length} invoice items');
      
      // Cache the remote data locally
      debugPrint('💾 Caching all invoice items locally');
      await _localDataSource.cacheInvoiceItems(remoteInvoiceItems);
      
      return Right(remoteInvoiceItems);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      
      try {
        debugPrint('📦 Attempting to load all from local storage');
        final localInvoiceItems = await _localDataSource.getAllInvoiceItems();
        debugPrint('✅ Retrieved ${localInvoiceItems.length} invoice items from local storage');
        return Right(localInvoiceItems);
      } on CacheException catch (cacheError) {
        debugPrint('❌ Local storage error: ${cacheError.message}');
      }
      
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }

  @override
  ResultFuture<InvoiceItemsEntity> updateInvoiceItemById(InvoiceItemsEntity invoiceItem) async {
    try {
      debugPrint('🌐 Updating invoice item: ${invoiceItem.id}');
      
      // Convert entity to model if it's not already a model
      final invoiceItemModel = invoiceItem is InvoiceItemsModel 
          ? invoiceItem 
          : InvoiceItemsModel(
              id: invoiceItem.id,
              collectionId: invoiceItem.collectionId,
              collectionName: invoiceItem.collectionName,
              name: invoiceItem.name,
              brand: invoiceItem.brand,
              refId: invoiceItem.refId,
              uom: invoiceItem.uom,
              quantity: invoiceItem.quantity,
              totalBaseQuantity: invoiceItem.totalBaseQuantity,
              uomPrice: invoiceItem.uomPrice,
              totalAmount: invoiceItem.totalAmount,
              invoiceData: invoiceItem.invoiceData as InvoiceDataModel,
              created: invoiceItem.created,
              updated: invoiceItem.updated,
            );
      
      final updatedInvoiceItem = await _remoteDataSource.updateInvoiceItemById(invoiceItemModel);
      
      // Update in local storage
      debugPrint('💾 Updating invoice item in local storage');
      await _localDataSource.updateInvoiceItem(updatedInvoiceItem);
      
      debugPrint('✅ Successfully updated invoice item');
      return Right(updatedInvoiceItem);
    } on ServerException catch (e) {
      debugPrint('⚠️ API Error: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<List<InvoiceItemsEntity>> getAllLocalInvoiceItems() async {
    try {
      debugPrint('📦 Fetching all invoice items from local storage');
      final localInvoiceItems = await _localDataSource.getAllInvoiceItems();
      debugPrint('✅ Retrieved ${localInvoiceItems.length} invoice items from local storage');
      return Right(localInvoiceItems);
    } on CacheException catch (e) {
      debugPrint('❌ Local storage error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
  
  @override
  ResultFuture<List<InvoiceItemsEntity>> getLocalInvoiceItemsByInvoiceDataId(String invoiceDataId) async {
    try {
      debugPrint('📦 Fetching local invoice items for invoice data ID: $invoiceDataId');
      final localInvoiceItems = await _localDataSource.getInvoiceItemsByInvoiceDataId(invoiceDataId);
      debugPrint('✅ Retrieved ${localInvoiceItems.length} local invoice items for invoice data ID: $invoiceDataId');
      return Right(localInvoiceItems);
    } on CacheException catch (e) {
      debugPrint('❌ Local storage error: ${e.message}');
      return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}
