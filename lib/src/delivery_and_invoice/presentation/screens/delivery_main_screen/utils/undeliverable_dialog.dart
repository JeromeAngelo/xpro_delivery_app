import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/cancelled_invoices/presentation/bloc/cancelled_invoice_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';

class UndeliverableScreen extends StatefulWidget {
  final DeliveryDataEntity customer;
  final String statusId;

  const UndeliverableScreen({
    super.key,
    required this.customer,
    required this.statusId,
  });

  @override
  State<UndeliverableScreen> createState() => _UndeliverableScreenState();
}

class _UndeliverableScreenState extends State<UndeliverableScreen> {
  final List<XFile> _images = [];
  UndeliverableReason _selectedReason = UndeliverableReason.none;
  final ImagePicker _picker = ImagePicker();

  bool _isFormValid() {
    return _images.isNotEmpty && _selectedReason != UndeliverableReason.none;
  }

  Future<void> _pickImages() async {
    final ImageSource? source = await showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      if (source == ImageSource.camera) {
        final XFile? photo = await _picker.pickImage(source: source);
        if (photo != null) {
          setState(() => _images.add(photo));
        }
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
  }

  Widget _buildImageContainer() {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline),
        borderRadius: BorderRadius.circular(12),
      ),
      child:
          _images.isEmpty
              ? InkWell(
                onTap: _pickImages,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 48,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add Photos',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              )
              : Stack(
                children: [
                  ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _images.length,
                    itemBuilder: (context, index) {
                      return Stack(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(_images[index].path),
                                width: 180,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              icon: const Icon(Icons.remove_circle),
                              color: Colors.red,
                              onPressed:
                                  () => setState(() => _images.removeAt(index)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FloatingActionButton(
                      backgroundColor: Colors.white,
                      mini: true,
                      onPressed: _pickImages,
                      child: Icon(
                        Icons.add_a_photo,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildReasonDropdown() {
    return DropdownButtonFormField<UndeliverableReason>(
      value: _selectedReason,
      decoration: InputDecoration(
        labelText: 'Reason',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items:
          UndeliverableReason.values.map((reason) {
            return DropdownMenuItem(
              value: reason,
              child: Text(_formatReason(reason.name)),
            );
          }).toList(),
      onChanged: (value) {
        setState(() => _selectedReason = value!);
      },
    );
  }

  String _formatReason(String reason) {
    return reason
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .trim()
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<CancelledInvoiceBloc, CancelledInvoiceState>(
          listener: (context, state) {
            if (state is CancelledInvoiceCreated) {
              debugPrint('🔄 Processing cancelled invoice creation success');

              // Navigate immediately after local creation
              debugPrint(
                '🚀 Navigating to target screen while background sync continues',
              );
              // Navigate immediately - don't wait for delivery data refresh
              context.go(
                '/delivery-and-invoice/${widget.customer.id}',
                extra: widget.customer,
              );

              // Update delivery status
              context.read<DeliveryUpdateBloc>().add(
                UpdateDeliveryStatusEvent(
                  customerId: widget.customer.id ?? '',
                  statusId: widget.statusId,
                ),
              );

              // Refresh delivery data in background (optional)
              Future.delayed(const Duration(milliseconds: 500), () {
                if (context.mounted) {
                  final deliveryDataBloc = context.read<DeliveryDataBloc>();
                  deliveryDataBloc.add(
                    GetLocalDeliveryDataByIdEvent(widget.customer.id ?? ''),
                  );
                  deliveryDataBloc.add(
                    GetDeliveryDataByIdEvent(widget.customer.id ?? ''),
                  );
                }
              });
            } else if (state is CancelledInvoiceError) {
              debugPrint(
                '❌ Cancelled invoice creation failed: ${state.message}',
              );
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to create cancelled invoice: ${state.message}',
                  ),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mark as Undelivered'),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customer.customer.target?.name ?? 'Customer',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildImageContainer(),
              const SizedBox(height: 16),
              _buildReasonDropdown(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        () => context.go(
                          '/delivery-and-invoice/${widget.customer.id}',
                        ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<CancelledInvoiceBloc, CancelledInvoiceState>(
                    builder: (context, state) {
                      final isLoading = state is CancelledInvoiceLoading;

                      return ElevatedButton(
                        onPressed:
                            _isFormValid() && !isLoading
                                ? () {
                                  debugPrint('📝 Creating cancelled invoice');
                                  debugPrint(
                                    '🏪 Customer: ${widget.customer.customer.target?.name}',
                                  );
                                  debugPrint(
                                    '📋 Reason: ${_selectedReason.toString().split('.').last}',
                                  );
                                  debugPrint('📷 Images: ${_images.length}');

                                  final deliveryDataId = widget.customer.id;

                                  if (deliveryDataId != null) {
                                    // Show immediate feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Row(
                                          children: [
                                            SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 12),
                                            Text('Saving cancelled invoice...'),
                                          ],
                                        ),
                                        duration: Duration(seconds: 2),
                                        backgroundColor: Colors.orange,
                                      ),
                                    );

                                    // Create cancelled invoice
                                    context.read<CancelledInvoiceBloc>().add(
                                      CreateCancelledInvoiceByDeliveryDataIdEvent(
                                        deliveryDataId: deliveryDataId,
                                        reason: _selectedReason,
                                        image:
                                            _images.isNotEmpty
                                                ? _images.first.path
                                                : null,
                                      ),
                                    );
                                  } else {
                                    debugPrint(
                                      '⚠️ No delivery data ID available',
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Unable to create cancelled invoice: Missing delivery data',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                                : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _isFormValid() && !isLoading
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerHighest,
                        ),
                        child:
                            isLoading
                                ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  'Save',
                                  style: TextStyle(
                                    color:
                                        Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
