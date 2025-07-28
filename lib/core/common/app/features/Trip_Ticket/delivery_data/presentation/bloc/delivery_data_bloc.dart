import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/add_delivery_data_to_trip.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/delete_delivery_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_all_delivery_data.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_all_delivery_data_with_trips.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_delivery_data_by_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/domain/usecases/get_delivery_data_by_trip_id.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

class DeliveryDataBloc extends Bloc<DeliveryDataEvent, DeliveryDataState> {
  final GetAllDeliveryData _getAllDeliveryData;
  final GetAllDeliveryDataWithTrips _getAllDeliveryDataWithTrips;
  final GetDeliveryDataByTripId _getDeliveryDataByTripId;
  final GetDeliveryDataById _getDeliveryDataById;
  final DeleteDeliveryData _deleteDeliveryData;
  final AddDeliveryDataToTrip _addDeliveryDataToTrip;

  DeliveryDataState? _cachedState;

  DeliveryDataBloc({
    required GetAllDeliveryData getAllDeliveryData,
    required GetAllDeliveryDataWithTrips getAllDeliveryDataWithTrips,
    required GetDeliveryDataByTripId getDeliveryDataByTripId,
    required GetDeliveryDataById getDeliveryDataById,
    required DeleteDeliveryData deleteDeliveryData,
    required AddDeliveryDataToTrip addDeliveryDataToTrip,
  })  : _getAllDeliveryData = getAllDeliveryData,
        _getAllDeliveryDataWithTrips = getAllDeliveryDataWithTrips,
        _getDeliveryDataByTripId = getDeliveryDataByTripId,
        _getDeliveryDataById = getDeliveryDataById,
        _deleteDeliveryData = deleteDeliveryData,
        _addDeliveryDataToTrip = addDeliveryDataToTrip,
        super(const DeliveryDataInitial()) {
    on<GetAllDeliveryDataEvent>(_onGetAllDeliveryData);
    on<GetAllDeliveryDataWithTripsEvent>(_onGetAllDeliveryDataWithTrips);
    on<GetDeliveryDataByTripIdEvent>(_onGetDeliveryDataByTripId);
    on<GetDeliveryDataByIdEvent>(_onGetDeliveryDataById);
    on<DeleteDeliveryDataEvent>(_onDeleteDeliveryData);
    on<AddDeliveryDataToTripEvent>(_onAddDeliveryDataToTrip);
  }

  Future<void> _onGetAllDeliveryData(
    GetAllDeliveryDataEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    emit(const DeliveryDataLoading());
    debugPrint('🔄 BLOC: Getting all delivery data');

    final result = await _getAllDeliveryData();
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get delivery data: ${failure.message}');
        emit(DeliveryDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (deliveryData) {
        debugPrint('✅ BLOC: Successfully retrieved ${deliveryData.length} delivery data records');
        final newState = AllDeliveryDataLoaded(deliveryData);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetAllDeliveryDataWithTrips(
    GetAllDeliveryDataWithTripsEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    emit(const DeliveryDataLoading());
    debugPrint('🔄 BLOC: Getting all delivery data with trips');

    final result = await _getAllDeliveryDataWithTrips();
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get delivery data with trips: ${failure.message}');
        emit(DeliveryDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (deliveryData) {
        debugPrint('✅ BLOC: Successfully retrieved ${deliveryData.length} delivery data records with trips');
        final newState = AllDeliveryDataWithTripsLoaded(deliveryData);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  // Add this new event handler method
  Future<void> _onDeleteDeliveryData(
    DeleteDeliveryDataEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    emit(const DeliveryDataLoading());
    debugPrint('🔄 BLOC: Deleting delivery data with ID: ${event.id}');

    final result = await _deleteDeliveryData(event.id);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to delete delivery data: ${failure.message}');
        emit(DeliveryDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (success) {
        debugPrint('✅ BLOC: Successfully deleted delivery data with ID: ${event.id}');
        emit(DeliveryDataDeleted(event.id));
        
        // Optionally refresh the list after deletion
        add(const GetAllDeliveryDataEvent());
      },
    );
  }

  Future<void> _onAddDeliveryDataToTrip(
    AddDeliveryDataToTripEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    emit(const DeliveryDataLoading());
    debugPrint('🔄 BLOC: Adding delivery data to trip ID: ${event.tripId}');

    final result = await _addDeliveryDataToTrip(event.tripId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to add delivery data to trip: ${failure.message}');
        emit(DeliveryDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (success) {
        debugPrint('✅ BLOC: Successfully added delivery data to trip ID: ${event.tripId}');
        emit(DeliveryDataAddedToTrip(event.tripId));
        
        // Optionally refresh the list after adding
        add(const GetAllDeliveryDataWithTripsEvent());
      },
    );
  }

  Future<void> _onGetDeliveryDataByTripId(
    GetDeliveryDataByTripIdEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    emit(const DeliveryDataLoading());
    debugPrint('🔄 BLOC: Getting delivery data for trip ID: ${event.tripId}');

    final result = await _getDeliveryDataByTripId(event.tripId);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get delivery data by trip ID: ${failure.message}');
        emit(DeliveryDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (deliveryData) {
        debugPrint('✅ BLOC: Successfully retrieved ${deliveryData.length} delivery data records for trip ID: ${event.tripId}');
        final newState = DeliveryDataByTripLoaded(
          deliveryData: deliveryData,
          tripId: event.tripId,
        );
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  Future<void> _onGetDeliveryDataById(
    GetDeliveryDataByIdEvent event,
    Emitter<DeliveryDataState> emit,
  ) async {
    emit(const DeliveryDataLoading());
    debugPrint('🔄 BLOC: Getting delivery data with ID: ${event.id}');

    final result = await _getDeliveryDataById(event.id);
    result.fold(
      (failure) {
        debugPrint('❌ BLOC: Failed to get delivery data by ID: ${failure.message}');
        emit(DeliveryDataError(message: failure.message, statusCode: failure.statusCode));
      },
      (deliveryData) {
        debugPrint('✅ BLOC: Successfully retrieved delivery data with ID: ${event.id}');
        final newState = DeliveryDataLoaded(deliveryData);
        _cachedState = newState;
        emit(newState);
      },
    );
  }

  @override
  Future<void> close() {
    _cachedState = null;
    return super.close();
  }
}
