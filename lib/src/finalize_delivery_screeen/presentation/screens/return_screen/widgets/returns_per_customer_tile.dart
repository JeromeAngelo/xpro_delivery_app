// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:go_router/go_router.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_bloc.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_state.dart';
// import 'package:x_pro_delivery_app/core/common/widgets/list_tiles.dart';
// class ReturnsPerCustomerTile extends StatelessWidget {
//   const ReturnsPerCustomerTile({super.key});

//   String _getReturnQuantityText(ReturnEntity returnItem) {
//     List<String> quantities = [];

//     if (returnItem.isCase == true && (returnItem.productQuantityCase ?? 0) > 0) {
//       quantities.add('${returnItem.productQuantityCase} case');
//     }
//     if (returnItem.isPcs == true && (returnItem.productQuantityPcs ?? 0) > 0) {
//       quantities.add('${returnItem.productQuantityPcs} pcs');
//     }
//     if (returnItem.isPack == true && (returnItem.productQuantityPack ?? 0) > 0) {
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
//                 child: CommonListTiles(
//                   onTap: () {
//                     context.push(
//                       '/return-details/${returnItem.customer?.id}',
//                       extra: returnItem,
//                     );
//                   },
//                   title: returnItem.customer?.storeName ?? 'No Store Name',
//                   subtitle: quantityText,
//                   leading: CircleAvatar(
//                     backgroundColor:
//                         Theme.of(context).colorScheme.primary.withOpacity(0.1),
//                     child: Icon(
//                       Icons.assignment_return,
//                       color: Theme.of(context).colorScheme.primary,
//                     ),
//                   ),
//                   trailing: Icon(
//                     Icons.arrow_forward_ios,
//                     color: Theme.of(context).colorScheme.onSurface,
//                   ),
//                   elevation: 2,
//                   shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   contentPadding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                   backgroundColor: Theme.of(context).colorScheme.surface,
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
