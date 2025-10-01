// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/presentation/bloc/vehicle_bloc.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/vehicle/presentation/bloc/vehicle_state.dart';

// class DeliveryTeamVehicle extends StatelessWidget {
//   const DeliveryTeamVehicle({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<VehicleBloc, VehicleState>(
//       builder: (context, state) {
//         if (state is VehicleByTripLoaded) {
//           return Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0),
//             child: Card(
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Vehicle Details',
//                       style: Theme.of(context).textTheme.titleLarge,
//                     ),
//                     const SizedBox(height: 16),
//                     ListTile(
//                       leading: const Icon(Icons.local_shipping),
//                       title: Text(state.vehicle.vehiclePlateNumber ?? 'N/A'),
//                       subtitle: Text(state.vehicle.vehicleType ?? 'Unknown Type'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           );
//         }
//         return const SizedBox.shrink();
//       },
//     );
//   }
// }
