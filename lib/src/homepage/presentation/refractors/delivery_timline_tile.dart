import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class DeliveryTimelineTile extends StatelessWidget {
  const DeliveryTimelineTile({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonListTiles(
      onTap: () => context.go('/delivery-and-timeline'),
      leading: Icon(Icons.route, color: Theme.of(context).colorScheme.primary),
      title: "View Deliveries",
      subtitle: "Delivery Routes",
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
