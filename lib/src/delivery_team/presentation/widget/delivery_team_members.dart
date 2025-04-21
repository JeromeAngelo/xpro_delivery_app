import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class DeliveryTeamActions extends StatelessWidget {
  final VoidCallback onViewPersonnel;
  final VoidCallback onViewTripTicket;
  final VoidCallback onViewVehicle;

  const DeliveryTeamActions({
    super.key,
    required this.onViewPersonnel,
    required this.onViewTripTicket,
    required this.onViewVehicle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CommonListTiles(
          leading: Icon(Icons.people,
              color: Theme.of(context).colorScheme.primary),
          title: 'View Personnel',
          subtitle: 'Manage delivery team members',
          onTap: onViewPersonnel,
        ),
        const SizedBox(height: 8),
        CommonListTiles(
          leading: Icon(Icons.assignment,
              color: Theme.of(context).colorScheme.primary),
          title: 'Trip Ticket',
          subtitle: 'View trip details and status',
          onTap: onViewTripTicket,
        ),
        const SizedBox(height: 8),
        CommonListTiles(
          leading: Icon(Icons.local_shipping,
              color: Theme.of(context).colorScheme.primary),
          title: 'View Vehicle',
          subtitle: 'Vehicle details and information',
          onTap: onViewVehicle,
        ),
      ],
    );
  }
}
