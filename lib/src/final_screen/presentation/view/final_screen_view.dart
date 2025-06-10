import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/widgets/default_drawer.dart';
import 'package:x_pro_delivery_app/core/common/widgets/rounded_%20button.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/final_screen/presentation/widget/confirmation_dialog.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/screen/summary_collection_screen.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/screen/summary_undeliverable_screen.dart';

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
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState!.openDrawer(),
        ),
        title: const Text('Final Summary'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  icon: Icon(Icons.receipt_long_outlined),
                  text: 'Collections',
                ),
                Tab(
                  icon: Icon(Icons.keyboard_return_sharp),
                  text: 'Returns',
                ),
                Tab(
                  icon: Icon(Icons.cancel_presentation_rounded),
                  text: 'Undelivered',
                ),
              ],
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Theme.of(context).colorScheme.primary,
              unselectedLabelColor: Colors.black,
              indicatorColor: Theme.of(context).colorScheme.primary,
              indicator: UnderlineTabIndicator(
                borderSide: BorderSide(
                  width: 3,
                  color: Theme.of(context).colorScheme.primary,
                ),
                insets: const EdgeInsets.symmetric(horizontal: 16),
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
          SummaryCollectionScreen(),
         // SummaryReturnScreen(),
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
              barrierDismissible: false, // Prevent dismissing by tapping outside
              builder: (context) => ConfirmationDialog(
                onConfirm: () {
                  debugPrint('🎫 Ending trip with ID: ${state.trip.id}');
                  context
                      .read<TripBloc>()
                      .add(EndTripEvent(state.trip.id!));
                  context
                      .read<TripBloc>()
                      .add(const StopLocationTrackingEvent());
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
