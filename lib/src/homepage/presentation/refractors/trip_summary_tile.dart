import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';

class TripSummaryTile extends StatelessWidget {
  const TripSummaryTile({super.key});

  @override
  Widget build(BuildContext context) {
    return CommonListTiles(
      leading: Icon(Icons.trip_origin_sharp,
          color: Theme.of(context).colorScheme.primary),
      title: 'Trip Summary',
      subtitle: 'Returns, Collections and etc.',
      trailing: Icon(
        Icons.arrow_forward_ios,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      onTap: () => context.pushReplacement('/summary-trip'),
    );
  }
}
