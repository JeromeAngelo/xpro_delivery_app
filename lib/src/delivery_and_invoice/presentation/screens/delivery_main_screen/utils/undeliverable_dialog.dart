import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/data/model/undeliverable_customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/undeliverable_customer/presentation/bloc/undeliverable_customer_state.dart';
import 'package:x_pro_delivery_app/core/enums/undeliverable_reason.dart';

class UndeliverableScreen extends StatefulWidget {
  final CustomerEntity customer;
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
    return BlocListener<UndeliverableCustomerBloc, UndeliverableCustomerState>(
      listener: (context, state) {
        if (state is UndeliverableCustomerLoaded) {
          if (widget.customer.id != null) {
            debugPrint('🔄 Processing undeliverable status update');
            context.read<DeliveryUpdateBloc>().add(
              UpdateDeliveryStatusEvent(
                customerId: widget.customer.id ?? '',
                statusId: widget.statusId,
              ),
            );

            final customerBloc = context.read<CustomerBloc>();
            Future.wait<void>([
              customerBloc.stream.firstWhere(
                (state) => state is CustomerLocationLoaded,
              ),
              Future(
                () => customerBloc.add(
                  LoadLocalCustomerLocationEvent(widget.customer.id ?? ''),
                ),
              ),
              Future(
                () => customerBloc.add(
                  GetCustomerLocationEvent(widget.customer.id ?? ''),
                ),
              ),
            ]).then((_) {
              if (mounted) {
                context.go(
                  '/delivery-and-invoice/${widget.customer.id}',
                  extra: widget.customer,
                );
              }
            });
          }
        }
      },
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
                widget.customer.storeName ?? 'Customer',
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
                  ElevatedButton(
                    onPressed:
                        _isFormValid()
                            ? () {
                              debugPrint('📝 Creating undeliverable record');

                              // Ensure customer is properly cast
                              if (widget.customer is CustomerModel) {
                                context.read<UndeliverableCustomerBloc>().add(
                                  CreateUndeliverableCustomerEvent(
                                    UndeliverableCustomerModel(
                                      customer:
                                          widget.customer as CustomerModel,
                                      reason: _selectedReason,
                                      time: DateTime.now().toUtc(),
                                      customerImage: _images
                                          .map((image) => image.path)
                                          .join(','),
                                    ),
                                    widget.customer.id ?? '',
                                  ),
                                );

                                // Update delivery status
                                context.read<DeliveryUpdateBloc>().add(
                                  UpdateDeliveryStatusEvent(
                                    customerId: widget.customer.id ?? '',
                                    statusId: widget.statusId,
                                  ),
                                );

                                // Navigate after data is refreshed
                                context.pushReplacement(
                                  '/delivery-and-invoice/${widget.customer.id}',
                                  extra: widget.customer,
                                );
                              } else {
                                debugPrint(
                                  '⚠️ Invalid customer type: ${widget.customer.runtimeType}',
                                );
                              }
                            }
                            : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isFormValid()
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                    ),
                    child: Text(
                      'Save',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
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
