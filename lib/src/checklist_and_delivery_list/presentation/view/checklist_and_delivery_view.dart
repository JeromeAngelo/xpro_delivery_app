import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/refractors/checklist_tile.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/refractors/confirm_button.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/refractors/delivery_list.dart';

import '../../../../core/common/app/features/checklist/data/model/checklist_model.dart';
import '../../../../core/utils/route_utils.dart';

class ChecklistAndDeliveryView extends StatefulWidget {
  const ChecklistAndDeliveryView({super.key});

  @override
  State<ChecklistAndDeliveryView> createState() =>
      _ChecklistAndDeliveryViewState();
}

class _ChecklistAndDeliveryViewState extends State<ChecklistAndDeliveryView> {
  DeliveryDataState? _cachedDeliveryDataState;
  ChecklistState? _cachedChecklistState;
  late final AuthBloc _authBloc;
  late final ChecklistBloc _checklistBloc;
  late final DeliveryDataBloc _customerBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
    RouteUtils.saveCurrentRoute('/checklist');
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _checklistBloc = context.read<ChecklistBloc>();
    _customerBloc = context.read<DeliveryDataBloc>();
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      SharedPreferences.getInstance().then((prefs) {
        final storedData = prefs.getString('user_data');
        if (storedData != null) {
          final userData = jsonDecode(storedData);
          final userId = userData['id'];
          final tripData = userData['trip'] as Map<String, dynamic>?;
          debugPrint('🆔 User ID from storage: $userId');
          debugPrint('🎫 Trip data from storage: $tripData');

          if (userId != null) {
            _authBloc.add(LoadLocalUserByIdEvent(userId));

            if (tripData != null && tripData['id'] != null) {
              _authBloc.add(GetUserTripEvent(tripData['id']));
              _authBloc.add(LoadLocalUserTripEvent(tripData['id']));

              // Load checklist and customers for this trip
              _customerBloc
                ..add(GetLocalDeliveryDataByTripIdEvent(tripData['id']))
                ..add(GetDeliveryDataByTripIdEvent(tripData['id']));
              _checklistBloc
                ..add(LoadLocalChecklistByTripIdEvent(tripData['id']))
                ..add(LoadChecklistByTripIdEvent(tripData['id']));
            }
          }
        }
      });

      // Listen for successful trip loading
      _authBloc.stream.listen((state) {
        if (state is UserTripLoaded) {
          debugPrint('✅ Trip loaded: ${state.trip.id}');
          _customerBloc
            ..add(GetLocalDeliveryDataByTripIdEvent(state.trip.id!))
            ..add(GetDeliveryDataByTripIdEvent(state.trip.id!));
          _checklistBloc
            ..add(LoadLocalChecklistByTripIdEvent(state.trip.id!))
            ..add(LoadChecklistByTripIdEvent(state.trip.id!));
        }
      });

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: MultiBlocListener(
        listeners: [
          BlocListener<ChecklistBloc, ChecklistState>(
            listener: (context, state) {
              if (state is ChecklistLoaded) {
                setState(() => _cachedChecklistState = state);
                bool allChecked = state.checklist.every(
                  (item) => item.isChecked ?? false,
                );
                if (allChecked) {
                  CoreUtils.showSnackBar(
                    context,
                    "All checklist items are checked",
                  );
                }
              }
            },
          ),
          BlocListener<DeliveryDataBloc, DeliveryDataState>(
            listener: (context, state) {
              if (state is DeliveryDataByTripLoaded) {
                setState(() => _cachedDeliveryDataState = state);
              }
            },
          ),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Checklist and Delivery List'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async {
                    SharedPreferences.getInstance().then((prefs) {
                      final storedData = prefs.getString('user_data');
                      if (storedData != null) {
                        final userData = jsonDecode(storedData);
                        final userId = userData['id'];
                        final tripData =
                            userData['trip'] as Map<String, dynamic>?;

                        if (userId != null) {
                          _authBloc.add(LoadLocalUserByIdEvent(userId));
                        }

                        if (tripData != null && tripData['id'] != null) {
                          // Refresh checklist data
                          _checklistBloc.add(
                            LoadChecklistByTripIdEvent(tripData['id']),
                          );

                          // Refresh delivery data
                          _customerBloc.add(
                            GetDeliveryDataByTripIdEvent(tripData['id']),
                          );
                        }
                      }
                    });
                  },
                  child:
                      _cachedDeliveryDataState == null &&
                              _cachedChecklistState == null
                          ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.local_shipping_outlined,
                                  size: 64,
                                  color:
                                      Theme.of(context).colorScheme.secondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No trip assigned yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Accept a trip to view deliveries and checklist',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          )
                          : ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 16),
                                    _buildSectionHeader("Checklist Items"),
                                    _buildChecklistSection(),
                                    const SizedBox(height: 24),
                                    _buildSectionHeader("Delivery List"),
                                    _buildDeliverySection(context),
                                    const SizedBox(
                                      height: 80,
                                    ), // Extra space at bottom
                                  ],
                                ),
                              ),
                            ],
                          ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.all(16),
                child: ConfirmButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
Widget _buildChecklistSection() {
  return BlocBuilder<ChecklistBloc, ChecklistState>(
    buildWhen: (previous, current) {
      if (current is ChecklistLoaded && previous is ChecklistLoaded) {
        return current.checklist.length != previous.checklist.length;
      }
      return current is ChecklistLoaded;
    },
    builder: (context, state) {
      final effectiveState = _cachedChecklistState ?? state;

      if (effectiveState is ChecklistLoaded) {
        return Column(
          children: effectiveState.checklist.map((item) {
            debugPrint('🔍 Rendering checklist item: ${item.objectName}');

            return BlocBuilder<ChecklistBloc, ChecklistState>(
              buildWhen: (previous, current) {
                if (current is ChecklistLoaded && previous is ChecklistLoaded) {
                  // Find items without using firstWhere to avoid type issues
                  ChecklistModel? prevItem;
                  ChecklistModel? currentItem;

                  try {
                    prevItem = previous.checklist
                        .cast<ChecklistModel>()
                        .where((i) => i.id == item.id)
                        .firstOrNull ?? item as ChecklistModel;
                    currentItem = current.checklist
                        .cast<ChecklistModel>()
                        .where((i) => i.id == item.id)
                        .firstOrNull ?? item as ChecklistModel;
                  } catch (e) {
                    debugPrint('⚠️ Type casting error: $e');
                    return false;
                  }

                  return prevItem.isChecked != currentItem.isChecked;
                }
                return false;
              },
              builder: (context, itemState) {
                ChecklistModel currentItem;

                try {
                  if (itemState is ChecklistLoaded) {
                    currentItem = itemState.checklist
                        .cast<ChecklistModel>()
                        .where((i) => i.id == item.id)
                        .firstOrNull ?? item as ChecklistModel;
                  } else {
                    currentItem = item as ChecklistModel;
                  }
                } catch (e) {
                  debugPrint('⚠️ Error getting current item: $e');
                  currentItem = item as ChecklistModel;
                }

                // Get the actual checked state from the current item
                final actualCheckedState = currentItem.isChecked ?? false;
                
                debugPrint('🔍 Item ${currentItem.objectName}: actualCheckedState=$actualCheckedState');

                return ChecklistTile(
                  key: ValueKey('checklist_${item.id}'),
                  checklist: currentItem,
                  isChecked: actualCheckedState, // Pass the actual checked state
                  onChanged: (value) {
                    debugPrint('🔄 Checkbox changed for ${currentItem.objectName}: $value');
                    _checklistBloc.add(CheckItemEvent(item.id));
                  },
                );
              },
            );
          }).toList(),
        );
      }
      return const SizedBox.shrink();
    },
  );
}


  Widget _buildDeliverySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<DeliveryDataBloc, DeliveryDataState>(
          builder: (context, state) {
            debugPrint('🔍 Current DeliveryDataState: ${state.runtimeType}');

            if (state is DeliveryDataLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            // Use cached state if available
            final deliveryState =
                state is DeliveryDataByTripLoaded
                    ? state
                    : _cachedDeliveryDataState;

            if (deliveryState is DeliveryDataByTripLoaded) {
              debugPrint(
                '📋 Delivery data loaded: ${deliveryState.deliveryData.length} items',
              );

              if (deliveryState.deliveryData.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No deliveries found for this trip',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                );
              }

              // Convert loaded delivery data to a map for quick lookup
              final Map<String, dynamic> loadedData = {};
              for (final delivery in deliveryState.deliveryData) {
                if (delivery.id != null) {
                  loadedData[delivery.id!] = delivery;
                }
              }

              return DeliveryList(
                deliveries: deliveryState.deliveryData,
                loadedDeliveryData: loadedData,
                isLoading: false,
              );
            }

            // Show empty state if no data is available
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.local_shipping_outlined,
                    size: 48,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No deliveries available',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  void dispose() {
    _cachedDeliveryDataState = null;
    _cachedChecklistState = null;
    super.dispose();
  }
}
