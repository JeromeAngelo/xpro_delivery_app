import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';

import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklist/presentation/bloc/checklist_state.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/refractors/checklist_tile.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/refractors/confirm_button.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/widgets/delivery_list_tile.dart';

class ChecklistAndDeliveryView extends StatefulWidget {
  const ChecklistAndDeliveryView({super.key});

  @override
  State<ChecklistAndDeliveryView> createState() =>
      _ChecklistAndDeliveryViewState();
}

class _ChecklistAndDeliveryViewState extends State<ChecklistAndDeliveryView> {
  CustomerState? _cachedState;
  ChecklistState? _cachedChecklistState;
  late final AuthBloc _authBloc;
  late final ChecklistBloc _checklistBloc;
  late final CustomerBloc _customerBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _checklistBloc = context.read<ChecklistBloc>();
    _customerBloc = context.read<CustomerBloc>();
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
                ..add(LoadLocalCustomersEvent(tripData['id']))
                ..add(GetCustomerEvent(tripData['id']));
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
            ..add(LoadLocalCustomersEvent(state.trip.id!))
            ..add(GetCustomerEvent(state.trip.id!));
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
          BlocListener<CustomerBloc, CustomerState>(
            listener: (context, state) {
              if (state is CustomerLoaded) {
                setState(() => _cachedState = state);
              }
            },
          ),
        ],
        child: Scaffold(
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
                        if (userId != null) {
                          _authBloc.add(LoadLocalUserByIdEvent(userId));
                        }
                      }
                    });
                  },
                  child:
                      _cachedState == null && _cachedChecklistState == null
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
                          : CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverAppBar(
                                title: const Text(
                                  'Checklist and Delivery List',
                                ),
                                centerTitle: true,
                                floating: true,
                                snap: true,
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                              ),
                              _buildSectionHeader("Checklist Items"),
                              _buildChecklistSection(),
                              _buildSectionHeader("Delivery List"),
                              _buildDeliveryListSection(),
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
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverToBoxAdapter(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistSection() {
    return BlocBuilder<ChecklistBloc, ChecklistState>(
      buildWhen: (previous, current) {
        // Only rebuild the entire list when the list structure changes
        // Not when individual items are checked/unchecked
        if (current is ChecklistLoaded && previous is ChecklistLoaded) {
          return current.checklist.length != previous.checklist.length;
        }
        return current is ChecklistLoaded;
      },
      builder: (context, state) {
        final effectiveState = _cachedChecklistState ?? state;

        if (effectiveState is ChecklistLoaded) {
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = effectiveState.checklist[index];
                debugPrint('🔍 Rendering checklist item: ${item.objectName}');

                // Use a separate BlocBuilder for each item to avoid rebuilding the entire list
                return BlocBuilder<ChecklistBloc, ChecklistState>(
                  buildWhen: (previous, current) {
                    // Only rebuild this specific item when its checked state changes
                    if (current is ChecklistLoaded &&
                        previous is ChecklistLoaded) {
                      final prevItem = previous.checklist.firstWhere(
                        (i) => i.id == item.id,
                        orElse: () => item,
                      );
                      final currentItem = current.checklist.firstWhere(
                        (i) => i.id == item.id,
                        orElse: () => item,
                      );
                      return prevItem.isChecked != currentItem.isChecked;
                    }
                    return false;
                  },
                  builder: (context, itemState) {
                    // If we have a newer state, use it to get the latest checked status
                    final currentItem =
                        (itemState is ChecklistLoaded)
                            ? itemState.checklist.firstWhere(
                              (i) => i.id == item.id,
                              orElse: () => item,
                            )
                            : item;

                    return ChecklistTile(
                      key: ValueKey(item.id),
                      checklist: currentItem,
                      isChecked: currentItem.isChecked ?? false,
                      onChanged: (value) {
                        _checklistBloc.add(CheckItemEvent(item.id));
                      },
                    );
                  },
                );
              },
              childCount: effectiveState.checklist.length,
              addAutomaticKeepAlives: true,
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }

  Widget _buildDeliveryListSection() {
    return BlocBuilder<CustomerBloc, CustomerState>(
      builder: (context, state) {
        final effectiveState = _cachedState ?? state;

        if (effectiveState is CustomerLoaded) {
          if (effectiveState.customer.isEmpty) {
            return SliverToBoxAdapter(
              child: Center(
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
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            );
          }

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final customer = effectiveState.customer[index];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: DeliveryListTile(
                  customer: customer,
                  isFromLocal: true,
                  onTap: () {
                    // _customerBloc
                    //     .add(LoadLocalCustomerLocationEvent(customer.id!));
                    // context.go('/delivery-and-invoice/${customer.id}',
                    //     extra: customer);
                  },
                ),
              );
            }, childCount: effectiveState.customer.length),
          );
        }

        if (state is CustomerLoading) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        return const SliverToBoxAdapter(
          child: Center(child: Text('No customers available')),
        );
      },
    );
  }

  @override
  void dispose() {
    _cachedState = null;
    _cachedChecklistState = null;
    super.dispose();
  }
}
