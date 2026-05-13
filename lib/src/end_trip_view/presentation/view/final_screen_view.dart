import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/widgets/default_drawer.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/end_trip_view/presentation/widget/confirmation_dialog.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/screen/summary_undeliverable_screen.dart';

import '../screens/final_collection_screen.dart';
import '../screens/final_return_screen.dart';

class FinalScreenView extends StatefulWidget {
  const FinalScreenView({super.key});

  @override
  State<FinalScreenView> createState() => _FinalScreenViewState();
}

class _FinalScreenViewState extends State<FinalScreenView>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _buildTabItem(String label, int index, IconData icon) {
    final isSelected = _tabController.index == index;
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isSelected
                        ? Colors.white
                        : colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color:
                      isSelected
                          ? Colors.white
                          : colorScheme.onSurface.withOpacity(0.6),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu, color: Theme.of(context).colorScheme.primary),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        title: Text(
          'Final Summary',
          style: TextStyle(color: Theme.of(context).colorScheme.primary),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withOpacity(0.15),
                ),
              ),
              child: Row(
                children: [
                  _buildTabItem('Collections', 0, Icons.receipt_long_outlined),
                  _buildTabItem('Returns', 1, Icons.keyboard_return_sharp),
                  _buildTabItem(
                    'Undelivered',
                    2,
                    Icons.cancel_presentation_rounded,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      key: _scaffoldKey,
      drawer: const DefaultDrawer(),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FinalCollectionScreen(),
          // SummaryReturnScreen(),
          FinalReturnScreen(),
          SummaryUndeliverableScreen(),
        ],
      ),

      // In the build method, update the bottom navigation bar:
      bottomNavigationBar: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          if (state is UserTripLoaded && state.trip.id != null) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: RoundedButton(
                label: 'End Trip',
                onPressed: () {
                  showDialog(
                    context: context,
                    barrierDismissible:
                        false, // Prevent dismissing by tapping outside
                    builder:
                        (context) => ConfirmationDialog(
                          onConfirm: () {
                            debugPrint(
                              '🎫 Ending trip with ID: ${state.trip.id}',
                            );
                            context.read<TripBloc>().add(
                              EndTripEvent(state.trip.id ?? ''),
                            );
                            context.read<TripBloc>().add(
                              const StopLocationTrackingEvent(),
                            );
                            // Don't navigate here, let the dialog's BlocListener handle it
                          },
                        ),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
