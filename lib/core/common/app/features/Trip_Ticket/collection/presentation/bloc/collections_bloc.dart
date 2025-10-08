import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/delete_collection.dart';
import '../../domain/usecases/filter_collection_by_date.dart';
import '../../domain/usecases/get_all_collections.dart';
import '../../domain/usecases/get_collection_by_id.dart';
import '../../domain/usecases/get_collection_by_trip_id.dart';
import 'collections_event.dart';
import 'collections_state.dart';

class CollectionsBloc extends Bloc<CollectionsEvent, CollectionsState> {
  final GetCollectionsByTripId _getCollectionsByTripId;
  final GetCollectionById _getCollectionById;
  final DeleteCollection _deleteCollection;
  final GetAllCollections _getAllCollections;
  final FilterCollectionsByDate _filterCollectionsByDate; // Add this line

  CollectionsState? _cachedState;

  CollectionsBloc({
    required GetCollectionsByTripId getCollectionsByTripId,
    required GetCollectionById getCollectionById,
    required DeleteCollection deleteCollection,
    required GetAllCollections getAllCollections,
    required FilterCollectionsByDate filterCollectionsByDate, // Add this line
  })  : _getCollectionsByTripId = getCollectionsByTripId,
        _getCollectionById = getCollectionById,
        _deleteCollection = deleteCollection,
        _getAllCollections = getAllCollections,
        _filterCollectionsByDate = filterCollectionsByDate, // Add this line
        super(const CollectionsInitial()) {
    on<GetCollectionsByTripIdEvent>(_onGetCollectionsByTripId);
    on<GetCollectionByIdEvent>(_onGetCollectionById);
    on<DeleteCollectionEvent>(_onDeleteCollection);
    on<RefreshCollectionsEvent>(_onRefreshCollections);
    on<GetAllCollectionsEvent>(_onGetAllCollections);
    on<FilterCollectionsByDateEvent>(_onFilterCollectionsByDate); // Add this line
  }


  Future<void> _onGetAllCollections(
  GetAllCollectionsEvent event,
  Emitter<CollectionsState> emit,
) async {
  debugPrint('🔄 BLoC: Fetching all collections');
  
  emit(const CollectionsLoading());

  final result = await _getAllCollections();

  result.fold(
    (failure) {
      debugPrint('❌ BLoC: Failed to fetch all collections: ${failure.message}');
      emit(CollectionsError(
        message: failure.message,
        errorCode: failure.statusCode,
      ));
    },
    (collections) {
      debugPrint('✅ BLoC: Successfully loaded ${collections.length} collections');
      
      if (collections.isEmpty) {
        emit(const CollectionsError(message: 'No collections found'));
      } else {
        final newState = AllCollectionsLoaded(
          collections: collections,
          isFromCache: false,
        );
        emit(newState);
        _cachedState = newState;
      }
    },
  );
}


  Future<void> _onGetCollectionsByTripId(
    GetCollectionsByTripIdEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('🔄 BLoC: Fetching collections for trip: ${event.tripId}');
    
    emit(const CollectionsLoading());

    final result = await _getCollectionsByTripId(event.tripId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to fetch collections: ${failure.message}');
        emit(CollectionsError(
          message: failure.message,
          errorCode: failure.statusCode,
        ));
      },
      (collections) {
        debugPrint('✅ BLoC: Successfully loaded ${collections.length} collections');
        
        if (collections.isEmpty) {
          emit(CollectionLoadedByTrip(event.tripId, collections: collections ));
        } else {
          final newState = CollectionsLoaded(
            collections: collections,
            isFromCache: false,
          );
          emit(newState);
          _cachedState = newState;
        }
      },
    );
  }

  Future<void> _onGetCollectionById(
    GetCollectionByIdEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('🔄 BLoC: Fetching collection by ID: ${event.collectionId}');
    
    emit(const CollectionsLoading());

    final result = await _getCollectionById(event.collectionId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to fetch collection: ${failure.message}');
        emit(CollectionsError(
          message: failure.message,
          errorCode: failure.statusCode,
        ));
      },
      (collection) {
        debugPrint('✅ BLoC: Successfully loaded collection: ${collection.id}');
        emit(CollectionLoaded(
          collection: collection,
          isFromCache: false,
        ));
      },
    );
  }

  Future<void> _onDeleteCollection(
    DeleteCollectionEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('🗑️ BLoC: Deleting collection: ${event.collectionId}');
    
    emit(const CollectionsLoading());

    final result = await _deleteCollection(event.collectionId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Failed to delete collection: ${failure.message}');
        emit(CollectionsError(
          message: failure.message,
          errorCode: failure.statusCode,
        ));
      },
      (success) {
        debugPrint('✅ BLoC: Successfully deleted collection');
        emit(CollectionDeleted(event.collectionId));
      },
    );
  }

  Future<void> _onRefreshCollections(
    RefreshCollectionsEvent event,
    Emitter<CollectionsState> emit,
  ) async {
    debugPrint('🔄 BLoC: Refreshing collections for trip: ${event.tripId}');
    
    // Don't emit loading state for refresh to avoid UI flicker
    final result = await _getCollectionsByTripId(event.tripId);

    result.fold(
      (failure) {
        debugPrint('❌ BLoC: Refresh failed: ${failure.message}');
        // Keep current state if refresh fails
        if (_cachedState != null) {
          emit(_cachedState!);
        } else {
          emit(CollectionsError(
            message: failure.message,
            errorCode: failure.statusCode,
          ));
        }
      },
      (collections) {
        debugPrint('✅ BLoC: Successfully refreshed ${collections.length} collections');
        
        if (collections.isEmpty) {
          emit(CollectionsEmpty(event.tripId));
        } else {
          final newState = CollectionsLoaded(
            collections: collections,
            isFromCache: false,
          );
          emit(newState);
          _cachedState = newState;
        }
      },
    );
  }

  Future<void> _onFilterCollectionsByDate(
  FilterCollectionsByDateEvent event,
  Emitter<CollectionsState> emit,
) async {
  debugPrint('🔄 BLoC: Filtering collections by date range');
  debugPrint('📅 BLoC: Start Date: ${event.startDate.toIso8601String()}');
  debugPrint('📅 BLoC: End Date: ${event.endDate.toIso8601String()}');
  
  emit(const CollectionsLoading());

  final result = await _filterCollectionsByDate(
    FilterCollectionsByDateParams(
      startDate: event.startDate,
      endDate: event.endDate,
    ),
  );

  result.fold(
    (failure) {
      debugPrint('❌ BLoC: Failed to filter collections by date: ${failure.message}');
      emit(CollectionsError(
        message: failure.message,
        errorCode: failure.statusCode,
      ));
    },
    (collections) {
      debugPrint('✅ BLoC: Successfully filtered ${collections.length} collections by date');
      
      if (collections.isEmpty) {
        emit(CollectionsError(
          message: 'No collections found for the selected date range',
        ));
      } else {
        final newState = CollectionsFilteredByDate(
          collections: collections,
          startDate: event.startDate,
          endDate: event.endDate,
          isFromCache: false,
        );
        emit(newState);
        _cachedState = newState;
      }
    },
  );
}


  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
