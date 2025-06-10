// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';


// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_state.dart';
// import 'package:x_pro_delivery_app/core/common/app/new_entity_updates/delivery_data/presentation/bloc/delivery_data_bloc.dart';

// class UpdateQueueRemarkDialog extends StatefulWidget {
//   final DeliveryDataBloc customer;
//   final String statusId;

//   const UpdateQueueRemarkDialog({
//     super.key,
//     required this.customer,
//     required this.statusId,
//   });

//   @override
//   State<UpdateQueueRemarkDialog> createState() =>
//       _UpdateQueueRemarkDialogState();
// }

// class _UpdateQueueRemarkDialogState extends State<UpdateQueueRemarkDialog> {
//   late final TextEditingController _queueController;

//   @override
//   void initState() {
//     super.initState();
//     // Extract number from remarks if exists, otherwise use '0'
//     final currentRemarks = widget.customer.remarks ?? '';
//     final numberMatch = RegExp(r'\d+').firstMatch(currentRemarks);
//     _queueController =
//         TextEditingController(text: numberMatch?.group(0) ?? '0');

//     // Highlight all text for easy editing
//     _queueController.selection = TextSelection(
//       baseOffset: 0,
//       extentOffset: _queueController.text.length,
//     );
//   }

//   @override
//   void dispose() {
//     _queueController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<DeliveryUpdateBloc, DeliveryUpdateState>(
//       listener: (context, state) {
//         if (state is QueueRemarksUpdated) {
//           if (widget.customer.id != null) {
//             context
//                 .read<DeliveryUpdateBloc>()
//                 .add(LoadLocalDeliveryStatusChoicesEvent(widget.customer.id!));
//             context.pop();
//           }
//         }
//       },
//       child: Scaffold(
//         appBar: AppBar(
//           title: const Text('Queue Information'),
//           centerTitle: true,
//         ),
//         body: SingleChildScrollView(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 widget.customer.storeName ?? 'Customer',
//                 style: Theme.of(context).textTheme.titleMedium?.copyWith(
//                       fontWeight: FontWeight.bold,
//                     ),
//               ),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: _queueController,
//                 keyboardType: TextInputType.number,
//                 autofocus: true,
//                 decoration: InputDecoration(
//                   labelText: 'Number of trucks in queue',
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   prefixIcon: const Icon(Icons.queue),
//                 ),
//               ),
//               const SizedBox(height: 24),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 children: [
//                   TextButton(
//                     onPressed: () => context.pop(),
//                     child: const Text('Cancel'),
//                   ),
//                   const SizedBox(width: 8),
//                   ElevatedButton(
//                     onPressed: () async {
//                       // First update queue remarks
//                       context.read<DeliveryUpdateBloc>().add(
//                             UpdateQueueRemarksEvent(
//                               customerId: widget.customer.id ?? '',
//                               queueCount: _queueController.text,
//                             ),
//                           );

//                       context
//                           .read<DeliveryUpdateBloc>()
//                           .add(UpdateDeliveryStatusEvent(
//                             customerId: widget.customer.id ?? '',
//                             statusId: 'oqnmalxuycacvrp',
//                           ));

//                       // Pre-load data for target screen
//                       final customerBloc = context.read<CustomerBloc>();

// // Explicitly type the Future.wait
//                       await Future.wait<void>([
//                         customerBloc.stream.firstWhere(
//                             (state) => state is CustomerLocationLoaded),
//                         Future(() => customerBloc.add(
//                             LoadLocalCustomerLocationEvent(
//                                 widget.customer.id ?? ''))),
//                         Future(() => customerBloc.add(GetCustomerLocationEvent(
//                             widget.customer.id ?? ''))),
//                       ]);

//                       // Navigate to target screen
//                       if (mounted) {
//                         context.pushReplacement(
//                           '/delivery-and-invoice/${widget.customer.id}',
//                           extra: widget.customer,
//                         );
//                       }
//                     },
//                     child: const Text('Save'),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
