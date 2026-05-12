import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/refractors/delivery_timline_tile.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/refractors/trip_summary_tile.dart';

class HomepageBody extends StatelessWidget {
  const HomepageBody({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DeliveryTimelineTile(),
          SizedBox(height: 8),
          TripSummaryTile(),
        ],
      ),
    );
  }

 
}
