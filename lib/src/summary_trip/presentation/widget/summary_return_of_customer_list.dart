// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';


// class SummaryReturnOfCustomerList extends StatelessWidget {
//   const SummaryReturnOfCustomerList({super.key});

//   String _getReturnQuantityText(ReturnEntity returnItem) {
//     List<String> quantities = [];

//     if (returnItem.isCase == true &&
//         (returnItem.productQuantityCase ?? 0) > 0) {
//       quantities.add('${returnItem.productQuantityCase} case');
//     }
//     if (returnItem.isPcs == true && (returnItem.productQuantityPcs ?? 0) > 0) {
//       quantities.add('${returnItem.productQuantityPcs} pcs');
//     }
//     if (returnItem.isPack == true &&
//         (returnItem.productQuantityPack ?? 0) > 0) {
//       quantities.add('${returnItem.productQuantityPack} pack');
//     }
//     if (returnItem.isBox == true && (returnItem.productQuantityBox ?? 0) > 0) {
//       quantities.add('${returnItem.productQuantityBox} box');
//     }

//     return quantities.isEmpty ? '0' : quantities.join(', ');
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<ReturnBloc, ReturnState>(
//       builder: (context, state) {
//         if (state is ReturnLoaded) {
//           return ListView.builder(
//             shrinkWrap: true,
//             physics: const NeverScrollableScrollPhysics(),
//             itemCount: state.returns.length,
//             itemBuilder: (context, index) {
//               final returnItem = state.returns[index];
//               final quantityText = _getReturnQuantityText(returnItem);

//               return Padding(
//                 padding: const EdgeInsets.symmetric(vertical: 4),
//                 child: Card(
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   child: ListTile(
//                     onTap: () {
//                       context.push(
//                         '/summary-return/${returnItem.customer?.id}',
//                         extra: returnItem,
//                       );
//                     },
//                     title:
//                         Text(returnItem.customer?.storeName ?? 'No Store Name'),
//                     subtitle: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(quantityText),
//                         Text(
//                           returnItem.productName ?? 'No Product Name',
//                           style: Theme.of(context).textTheme.bodySmall,
//                         ),
//                       ],
//                     ),
//                     leading: CircleAvatar(
//                       backgroundColor: Theme.of(context)
//                           .colorScheme
//                           .primary
//                           .withOpacity(0.1),
//                       child: Icon(
//                         Icons.assignment_return,
//                         color: Theme.of(context).colorScheme.primary,
//                       ),
//                     ),
//                     trailing: Icon(
//                       Icons.arrow_forward_ios,
//                       color: Theme.of(context).colorScheme.onSurface,
//                     ),
//                     contentPadding:
//                         const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   ),
//                 ),
//               );
//             },
//           );
//         }
//         return const SizedBox.shrink();
//       },
//     );
//   }
// }
