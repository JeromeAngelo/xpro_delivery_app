import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/end_trip_checklist/data/model/end_trip_checklist_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
abstract class EndTripChecklistLocalDataSource {
  Future<List<EndTripChecklistModel>> generateEndTripChecklist(String tripId);
  Future<bool> checkEndTripChecklistItem(String id);
  Future<List<EndTripChecklistModel>> loadEndTripChecklist(String tripId);
  Future<void> cacheChecklists(List<EndTripChecklistModel> checklists);
}

class EndTripChecklistLocalDataSourceImpl implements EndTripChecklistLocalDataSource {
  final Box<EndTripChecklistModel> _endTripChecklistBox;
  List<EndTripChecklistModel>? _cachedChecklists;

  EndTripChecklistLocalDataSourceImpl(this._endTripChecklistBox,);

  Future<void> _autoSave(List<EndTripChecklistModel> checklists) async {
    try {
      debugPrint('🔍 Processing ${checklists.length} checklist items');
      
      // Clear existing data
      _endTripChecklistBox.removeAll();
      debugPrint('🧹 Cleared previous checklist items');
      
      // Filter out duplicates by ID
      final uniqueChecklists = checklists.fold<Map<String, EndTripChecklistModel>>(
        {},
        (map, checklist) {
          map[checklist.id] = checklist;
          return map;
        },
      ).values.toList();
      
      _endTripChecklistBox.putMany(uniqueChecklists);
      _cachedChecklists = uniqueChecklists;
      debugPrint('📊 Stored ${uniqueChecklists.length} unique valid checklist items');
    } catch (e) {
      debugPrint('❌ Save operation failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<List<EndTripChecklistModel>> generateEndTripChecklist(String tripId) async {
    try {
      debugPrint('🔄 LOCAL: Starting checklist generation for trip: $tripId');
      
      final checklistItems = [
        EndTripChecklistModel(
          objectName: 'Collections',
          isChecked: false,
          status: 'pending',
          trip: tripId,
        ),
        EndTripChecklistModel(
          objectName: 'Pushcarts',
          isChecked: false,
          status: 'pending',
          trip: tripId,
        ),
        EndTripChecklistModel(
          objectName: 'Remittance',
          isChecked: false,
          status: 'pending',
          trip: tripId,
        )
      ];

      await _autoSave(checklistItems);
      debugPrint('✅ LOCAL: Generated ${checklistItems.length} checklist items for trip: $tripId');
      
      return checklistItems;
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to generate checklist - $e');
      throw CacheException(message: e.toString());
    }
  }
@override
Future<bool> checkEndTripChecklistItem(String id) async {
  try {
    debugPrint('🔄 LOCAL: Updating checklist item $id');
    
    final items = _endTripChecklistBox.getAll();
    final item = items.firstWhere(
      (item) => item.id == id,
      orElse: () {
        debugPrint('⚠️ LOCAL: Item not found with ID: $id');
        throw const CacheException(message: 'Checklist item not found', statusCode: 404);
      },
    );
    
    item.isChecked = true;
    item.status = 'completed';
    item.timeCompleted = DateTime.now();
    
    _endTripChecklistBox.put(item);
    debugPrint('✅ LOCAL: Item updated successfully');
    return true;
    
  } catch (e) {
    debugPrint('❌ LOCAL: Update failed - $e');
    throw CacheException(message: e.toString());
  }
}


  @override
  Future<List<EndTripChecklistModel>> loadEndTripChecklist(String tripId) async {
    try {
      debugPrint('🔄 LOCAL: Loading end trip checklist for trip: $tripId');
      
      final items = _endTripChecklistBox
          .query(EndTripChecklistModel_.trip.equals(tripId))
          .build()
          .find();
          
      debugPrint('✅ LOCAL: Loaded ${items.length} checklist items');
      return items;
    } catch (e) {
      debugPrint('❌ LOCAL: Failed to load checklist - $e');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheChecklists(List<EndTripChecklistModel> checklists) async {
    try {
      debugPrint('💾 Caching checklists from remote');
      await _autoSave(checklists);
      debugPrint('✅ Checklists cached successfully');
    } catch (e) {
      debugPrint('❌ Failed to cache checklists: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
