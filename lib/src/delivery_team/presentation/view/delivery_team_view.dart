import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/src/delivery_team/initial_screens/view_personel_screen.dart';
import 'package:x_pro_delivery_app/src/delivery_team/initial_screens/view_trips_screens.dart';
import 'package:x_pro_delivery_app/src/delivery_team/initial_screens/view_vehicle_screen.dart';
import 'package:x_pro_delivery_app/src/delivery_team/presentation/widget/delivery_team_header.dart';
import 'package:x_pro_delivery_app/src/delivery_team/presentation/widget/delivery_team_members.dart';

class DeliveryTeamView extends StatefulWidget {
  const DeliveryTeamView({super.key});

  @override
  State<DeliveryTeamView> createState() => _DeliveryTeamViewState();
}

class _DeliveryTeamViewState extends State<DeliveryTeamView>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const DeliveryTeamProfileHeader(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  DeliveryTeamActions(
                    onViewPersonnel: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const ViewPersonelScreen()));
                    },
                    onViewTripTicket: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ViewTripsScreen()));
                    },
                    onViewVehicle: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ViewVehicleScreen()));
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
