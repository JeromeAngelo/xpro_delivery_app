import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/local_datasource/checklist_local_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/data/datasource/remote_datasource/checklist_datasource.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/domain/entity/checklist_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/domain/repo/checklist_repo.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';

class ChecklistRepoImpl extends ChecklistRepo {
  final ChecklistDatasource _remoteDatasource;
  final ChecklistLocalDatasource _localDatasource;

  ChecklistRepoImpl(this._remoteDatasource, this._localDatasource);

  @override
ResultFuture<bool> checkItem(String id) async {
  final itemId = id.trim();
  if (itemId.isEmpty) {
    return Left(
      CacheFailure(message: 'Checklist item ID is required', statusCode: 400),
    );
  }

  // 📱 OFFLINE FIRST — try local immediately (fast UI)
  try {
    debugPrint('📱 Checking item locally (offline-first): $itemId');
    final localResult = await _localDatasource.checkItem(itemId);

    // 🌐 Sync remote in the background flow (awaited here to keep consistent result)
    try {
      debugPrint('🌐 Syncing item remotely: $itemId');
      final remoteResult = await _remoteDatasource.checkItem(itemId);

      // ✅ If remote succeeds, reflect it locally (source of truth)
      try {
        debugPrint('💾 Syncing remote result to local: $itemId');
        await _localDatasource.checkItem(itemId);
      } catch (e) {
        debugPrint('⚠️ Local sync after remote success failed: $e');
      }

      return Right(remoteResult);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote sync failed, keeping local result: ${e.message}');
      return Right(localResult);
    }
  } on CacheException catch (ce) {
    debugPrint('⚠️ Local check failed, trying remote: ${ce.message}');

    // 🌐 fallback to remote if local fails
    try {
      debugPrint('🌐 Checking item remotely (fallback): $itemId');
      final remoteResult = await _remoteDatasource.checkItem(itemId);

      // ✅ Save result locally if remote works
      try {
        debugPrint('💾 Saving remote result locally: $itemId');
        await _localDatasource.checkItem(itemId);
      } catch (e) {
        debugPrint('⚠️ Failed saving remote result locally: $e');
      }

      return Right(remoteResult);
    } on ServerException catch (e) {
      debugPrint('❌ Remote also failed: ${e.message}');
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    }
  }
}

@override
ResultFuture<List<ChecklistEntity>> loadChecklist() async {
  // 📱 OFFLINE FIRST — return local immediately if possible
  try {
    debugPrint('📱 Loading checklist locally (offline-first)');
    final localChecklist = await _localDatasource.getChecklist();

    // 🌐 Try remote refresh
    try {
      debugPrint('🌐 Refreshing checklist remotely');
      final remoteChecklist = await _remoteDatasource.getChecklist();

      // ✅ Update local cache with fresh remote data
      // try {
      //   debugPrint('💾 Updating local checklist cache from remote');
      //   await _localDatasource.saveChecklist(remoteChecklist);
      // } catch (e) {
      //   debugPrint('⚠️ Failed to update local checklist cache: $e');
      // }

      return Right(remoteChecklist);
    } on ServerException catch (e) {
      debugPrint('⚠️ Remote load failed, using local: ${e.message}');
      return Right(localChecklist);
    }
  } on CacheException catch (e) {
    debugPrint('⚠️ Local load failed, trying remote: ${e.message}');

    // 🌐 Fallback to remote if local fails
    try {
      debugPrint('🌐 Loading checklist remotely (fallback)');
      final remoteChecklist = await _remoteDatasource.getChecklist();

      // ✅ Save to local for next offline usage
      // try {
      //   debugPrint('💾 Saving remote checklist locally');
      //   await _localDatasource.saveChecklist(remoteChecklist);
      // } catch (err) {
      //   debugPrint('⚠️ Failed saving remote checklist locally: $err');
      // }

      return Right(remoteChecklist);
    } on ServerException catch (se) {
      debugPrint('❌ Remote also failed: ${se.message}');
      return Left(ServerFailure(message: se.message, statusCode: se.statusCode));
    }
  }
}

  @override
ResultFuture<List<ChecklistEntity>> loadChecklistByTripId(String? tripId) async {
  final tId = (tripId ?? '').trim();

  debugPrint('🔍 REPO: loadChecklistByTripId($tId) called');

  if (tId.isEmpty) {
    return Left(
      CacheFailure(message: 'Trip ID is required', statusCode: 400),
    );
  }

  // ---------------------------------------------------
  // 1️⃣ LOCAL FIRST
  // ---------------------------------------------------
  try {
    debugPrint('📋 Checking local checklist for trip: $tId');

    // ✅ Use your local "force reload" or "get by trip" method
    // Replace this with your actual local method name if different
    final localChecklist =
        await _localDatasource.loadChecklistByTripId(tId);

    if (localChecklist.isNotEmpty) {
      debugPrint('✅ Local checklist found: ${localChecklist.length} items');

      // ✅ Start/watch stream (same idea as deliveryData repo)
      _localDatasource.watchChecklistByTripId(tId);

      return Right(localChecklist);
    } else {
      debugPrint('⚠️ Local checklist empty');
    }
  } catch (e) {
    debugPrint('⚠️ Local lookup failed: $e');
  }

  // ---------------------------------------------------
  // 2️⃣ REMOTE FALLBACK
  // ---------------------------------------------------
  try {
    debugPrint('🌐 Fetching checklist remotely for trip: $tId');

    final remoteChecklist = await _remoteDatasource.loadChecklistByTripId(tId);

    debugPrint('✅ Remote checklist retrieved: ${remoteChecklist.length} items');

    // ❌ NO WATCHER HERE (same as your delivery pattern)
    // Remote sync/caching should update ObjectBox and streams emit automatically.

    // ✅ Cache remote in local (keep this ONLY if remote datasource does NOT already do it)
    try {
      await _localDatasource.cacheChecklist(remoteChecklist);
      debugPrint('💾 Cached remote checklist locally');
    } catch (cacheError) {
      debugPrint('⚠️ Failed saving remote checklist locally: $cacheError');
      // Continue even if local cache fails
    }

    return Right(remoteChecklist);
  } on ServerException catch (e) {
    debugPrint('❌ Remote fetch failed: ${e.message}');
    return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
  }
}

@override
ResultFuture<List<ChecklistEntity>> loadLocalChecklistByTripId(String? tripId) async {
  try {
    debugPrint('📱 Loading checklist from local storage for trip: $tripId');
    final localChecklist = await _localDatasource.loadChecklistByTripId(tripId!);
    return Right(localChecklist);
  } on CacheException catch (e) {
    return Left(CacheFailure(message: e.message, statusCode: e.statusCode));
  }
}

  
  
}