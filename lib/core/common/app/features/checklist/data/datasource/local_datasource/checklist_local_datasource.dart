import 'package:x_pro_delivery_app/core/common/app/features/checklist/data/model/checklist_model.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';
import 'package:flutter/foundation.dart';


abstract class ChecklistLocalDatasource {
  Future<List<ChecklistModel>> getChecklist();
  Future<bool> checkItem(String id);
  Future<List<ChecklistModel>> loadChecklistByTripId(String tripId);
  Future<void> cacheChecklist(List<ChecklistModel> checklist);
}

class ChecklistLocalDatasourceImpl implements ChecklistLocalDatasource {
  final Box<ChecklistModel> _checklistBox;
  List<ChecklistModel>? _cachedChecklist;

  ChecklistLocalDatasourceImpl(this._checklistBox);

  @override
  Future<List<ChecklistModel>> getChecklist() async {
    try {
      return _checklistBox.getAll();
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }

 @override
Future<bool> checkItem(String id) async {
  try {
    final query = _checklistBox.query(ChecklistModel_.pocketBaseId.equals(id)).build();
    final checklist = query.findFirst();
    query.close();

    if (checklist != null) {
      checklist.isChecked = !checklist.isChecked!;
      _checklistBox.put(checklist);
      debugPrint('✅ Updated checklist item: ${checklist.objectName} - Checked: ${checklist.isChecked}');
      return checklist.isChecked!;
    }
    return false;
  } catch (e) {
    throw CacheException(message: e.toString());
  }
}


  @override
  Future<List<ChecklistModel>> loadChecklistByTripId(String tripId) async {
    try {
      debugPrint('📱 Loading checklist from local storage for trip: $tripId');
      
      final query = _checklistBox.query(ChecklistModel_.tripId.equals(tripId)).build();
      final checklists = query.find();
      query.close();
      
      debugPrint('📊 Found ${checklists.length} checklist items for trip');
      return checklists;
    } catch (e) {
      debugPrint('❌ Local checklist fetch failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }

  @override
  Future<void> cacheChecklist(List<ChecklistModel> checklist) async {
    try {
      debugPrint('💾 Caching ${checklist.length} checklist items');
      _checklistBox.removeAll();
      _checklistBox.putMany(checklist);
      _cachedChecklist = checklist;
      debugPrint('✅ Checklist cached successfully');
    } catch (e) {
      debugPrint('❌ Caching failed: ${e.toString()}');
      throw CacheException(message: e.toString());
    }
  }
}
