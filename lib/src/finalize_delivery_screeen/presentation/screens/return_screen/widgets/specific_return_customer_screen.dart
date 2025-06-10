// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_bloc.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_event.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_state.dart';
// class SpecificReturnCustomerScreen extends StatefulWidget {
//   final String customerId;

//   const SpecificReturnCustomerScreen({
//     super.key,
//     required this.customerId,
//   });

//   @override
//   State<SpecificReturnCustomerScreen> createState() =>
//       _SpecificReturnCustomerScreenState();
// }

// class _SpecificReturnCustomerScreenState
//     extends State<SpecificReturnCustomerScreen> {
//   @override
//   void initState() {
//     super.initState();
//     context
//         .read<ReturnBloc>()
//         .add(GetReturnByCustomerIdEvent(widget.customerId));
//   }

//   Widget _buildQuantitySection(ReturnEntity returnItem) {
//     List<Widget> quantityRows = [];

//     if (returnItem.isCase == true && (returnItem.productQuantityCase ?? 0) > 0) {
//       quantityRows.add(_buildInfoRow(
//           'Quantity Case', returnItem.productQuantityCase.toString()));
//     }
//     if (returnItem.isPcs == true && (returnItem.productQuantityPcs ?? 0) > 0) {
//       quantityRows.add(_buildInfoRow(
//           'Quantity Pcs', returnItem.productQuantityPcs.toString()));
//     }
//     if (returnItem.isPack == true && (returnItem.productQuantityPack ?? 0) > 0) {
//       quantityRows.add(_buildInfoRow(
//           'Quantity Pack', returnItem.productQuantityPack.toString()));
//     }
//     if (returnItem.isBox == true && (returnItem.productQuantityBox ?? 0) > 0) {
//       quantityRows.add(_buildInfoRow(
//           'Quantity Box', returnItem.productQuantityBox.toString()));
//     }

//     return Column(children: quantityRows);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back),
//           onPressed: () {
//             context.pushReplacement('/view-returns');
//           },
//         ),
//         title: const Text('Return Details'),
//       ),
//       body: BlocBuilder<ReturnBloc, ReturnState>(
//         builder: (context, state) {
//           if (state is ReturnByCustomerLoaded) {
//             final returnItem = state.returnItem;
//             return SingleChildScrollView(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Store Information',
//                             style: Theme.of(context).textTheme.titleLarge,
//                           ),
//                           const Divider(),
//                           _buildInfoRow('Store Name',
//                               returnItem.customer?.storeName ?? ''),
//                           _buildInfoRow(
//                               'Return Date',
//                               returnItem.returnDate?.toString().split(' ')[0] ??
//                                   ''),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 16),
//                   Card(
//                     child: Padding(
//                       padding: const EdgeInsets.all(16),
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             'Return Details',
//                             style: Theme.of(context).textTheme.titleLarge,
//                           ),
//                           const Divider(),
//                           _buildInfoRow(
//                               'Product Name', returnItem.productName ?? ''),
//                           _buildInfoRow('Description',
//                               returnItem.productDescription ?? ''),
//                           _buildQuantitySection(returnItem),
//                           _buildInfoRow(
//                               'Reason',
//                               returnItem.reason?.toString().split('.').last ??
//                                   ''),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             );
//           }
//           return const Center(child: CircularProgressIndicator());
//         },
//       ),
//     );
//   }

//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(vertical: 8),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//         children: [
//           Text(
//             label,
//             style: const TextStyle(fontWeight: FontWeight.bold),
//           ),
//           Text(
//             value,
//             overflow: TextOverflow.clip,
//           ),
//         ],
//       ),
//     );
//   }
// }
