// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_event.dart';
// import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_state.dart';
// import 'package:x_pro_delivery_app/core/common/widgets/rounded_ button.dart';
// import 'package:x_pro_delivery_app/core/enums/product_return_reason.dart';
// import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
// class AddProductToReturnScreen extends StatefulWidget {
//   final ProductModel product;
//   final VoidCallback onReturnAdded;

//   const AddProductToReturnScreen({
//     super.key,
//     required this.product,
//     required this.onReturnAdded,
//   });

//   @override
//   State<AddProductToReturnScreen> createState() => _AddProductToReturnScreenState();
// }

// class _AddProductToReturnScreenState extends State<AddProductToReturnScreen> {
//   ProductReturnReason selectedReason = ProductReturnReason.none;
//   final TextEditingController caseController = TextEditingController();
//   final TextEditingController pcsController = TextEditingController();
//   final TextEditingController packController = TextEditingController();
//   final TextEditingController boxController = TextEditingController();

//   @override
//   void initState() {
//     super.initState();
//     caseController.text = '0';
//     pcsController.text = '0';
//     packController.text = '0';
//     boxController.text = '0';
//   }

//   String _formatReason(String reason) {
//     return reason
//         .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
//         .trim()
//         .split(' ')
//         .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
//         .join(' ');
//   }

//   Widget _buildQuantityInput({
//     required String label,
//     required TextEditingController controller,
//     required int maxQuantity,
//   }) {
//     return Column(
//       children: [
//         Container(
//           width: 80,
//           height: 40,
//           decoration: BoxDecoration(
//             border: Border.all(color: Colors.grey.shade300),
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: TextFormField(
//             controller: controller,
//             textAlign: TextAlign.center,
//             decoration: const InputDecoration(
//               isDense: true,
//               border: InputBorder.none,
//               contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
//             ),
//             keyboardType: TextInputType.number,
//             style: Theme.of(context).textTheme.titleMedium,
//             onChanged: (value) {
//               final inputQuantity = int.tryParse(value) ?? 0;
//               if (inputQuantity > maxQuantity) {
//                 controller.text = maxQuantity.toString();
//               }
//             },
//           ),
//         ),
//         Text(label, style: Theme.of(context).textTheme.bodySmall)
//       ],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<ProductsBloc, ProductsState>(
//       listener: (context, state) {
//         if (state is ProductAddedToReturn) {
//           widget.onReturnAdded();
//           Navigator.pop(context);
//           CoreUtils.showSnackBar(context, 'Return added successfully');
//         }
//       },
//       child: Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         child: SingleChildScrollView(
//           child: Container(
//             width: MediaQuery.of(context).size.width * 0.8,
//             padding: const EdgeInsets.all(16),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 Text(
//                   'Add Product to Returns',
//                   style: Theme.of(context).textTheme.titleLarge,
//                 ),
//                 const SizedBox(height: 16),

//                 // Product Details Card
//                 Card(
//                   elevation: 2,
//                   child: Padding(
//                     padding: const EdgeInsets.all(12),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           widget.product.name ?? 'No Name',
//                           style: Theme.of(context).textTheme.titleMedium!.copyWith(
//                             fontWeight: FontWeight.bold,
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Text(
//                           widget.product.description ?? 'No Description',
//                           style: Theme.of(context).textTheme.bodyMedium,
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Return Reason Dropdown
//                 Text(
//                   'Select Return Reason:',
//                   style: Theme.of(context).textTheme.titleMedium,
//                 ),
//                 const SizedBox(height: 8),
//                 Container(
//                   decoration: BoxDecoration(
//                     border: Border.all(color: Theme.of(context).colorScheme.outline),
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                   child: DropdownButtonHideUnderline(
//                     child: DropdownButton<ProductReturnReason>(
//                       value: selectedReason,
//                       isExpanded: true,
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                       items: ProductReturnReason.values.map((reason) {
//                         return DropdownMenuItem(
//                           value: reason,
//                           child: Text(_formatReason(reason.name)),
//                         );
//                       }).toList(),
//                       onChanged: (value) {
//                         if (value != null) {
//                           setState(() => selectedReason = value);
//                         }
//                       },
//                     ),
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 // Return Quantities
//                 Text(
//                   'Return Quantity:',
//                   style: Theme.of(context).textTheme.titleMedium,
//                 ),
//                 const SizedBox(height: 10),

//                 // Quantity Inputs
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                   children: [
//                     if (widget.product.isCase == true)
//                       _buildQuantityInput(
//                         label: 'CASE',
//                         controller: caseController,
//                         maxQuantity: widget.product.case_ ?? 0,
//                       ),
//                     if (widget.product.isPc == true)
//                       _buildQuantityInput(
//                         label: 'PCS',
//                         controller: pcsController,
//                         maxQuantity: widget.product.pcs ?? 0,
//                       ),
//                     if (widget.product.isPack == true)
//                       _buildQuantityInput(
//                         label: 'PACK',
//                         controller: packController,
//                         maxQuantity: widget.product.pack ?? 0,
//                       ),
//                     if (widget.product.isBox == true)
//                       _buildQuantityInput(
//                         label: 'BOX',
//                         controller: boxController,
//                         maxQuantity: widget.product.box ?? 0,
//                       ),
//                   ],
//                 ),

//                 const SizedBox(height: 24),

//                 // Confirm Button
//                 RoundedButton(
//                   label: 'Confirm Return',
//                   onPressed: () {
//                     context.read<ProductsBloc>().add(
//                       AddToReturnEvent(
//                         productId: widget.product.id!,
//                         reason: selectedReason,
//                         returnProductCase: int.tryParse(caseController.text) ?? 0,
//                         returnProductPc: int.tryParse(pcsController.text) ?? 0,
//                         returnProductPack: int.tryParse(packController.text) ?? 0,
//                         returnProductBox: int.tryParse(boxController.text) ?? 0,
//                       ),
//                     );
                    
//                     context.read<ProductsBloc>().add(const GetProductsEvent());
//                   },
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   @override
//   void dispose() {
//     caseController.dispose();
//     pcsController.dispose();
//     packController.dispose();
//     boxController.dispose();
//     super.dispose();
//   }
// }
