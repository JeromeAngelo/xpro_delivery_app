import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_update/presentation/bloc/delivery_update_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';

class AddDeliveryStatusScreen extends StatefulWidget {
  final DeliveryDataEntity customer;

  const AddDeliveryStatusScreen({
    super.key,
    required this.customer,
  });

  @override
  State<AddDeliveryStatusScreen> createState() =>
      _AddDeliveryStatusScreenState();
}

class _AddDeliveryStatusScreenState extends State<AddDeliveryStatusScreen> {
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();
  final _titleController = TextEditingController();
  final _subtitleController = TextEditingController();

  bool _isFormValid() {
    return _images.isNotEmpty &&
        _titleController.text.isNotEmpty &&
        _subtitleController.text.isNotEmpty;
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
      final XFile? photo = await _picker.pickImage(source: source);
      if (photo != null) {
        setState(() => _images.add(photo));
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
      child: _images.isEmpty
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
                    'Add Photo',
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
                            onPressed: () =>
                                setState(() => _images.removeAt(index)),
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
                    mini: true,
                    onPressed: _pickImages,
                    child: const Icon(Icons.add_a_photo),
                  ),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Delivery Status'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.customer.customer.target!.name ?? 'Customer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Status Title',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _subtitleController,
              decoration: InputDecoration(
                labelText: 'Status Description',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildImageContainer(),
            const SizedBox(height: 24),
            BlocBuilder<DeliveryUpdateBloc, DeliveryUpdateState>(
              builder: (context, state) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: state is DeliveryUpdateLoading
                        ? null
                        : () async {
                            if (_isFormValid()) {
                              context.read<DeliveryUpdateBloc>().add(
                                    CreateDeliveryStatusEvent(
                                      customerId: widget.customer.id ?? '',
                                      title: _titleController.text,
                                      subtitle: _subtitleController.text,
                                      time: DateTime.now(),
                                      isAssigned: true,
                                      image: _images.first.path,
                                    ),
                                  );

                              // Update delivery status to Mark as Received
                              // context.read<DeliveryUpdateBloc>().add(
                              //       UpdateDeliveryStatusEvent(
                              //         customerId: widget.customer.id ?? '',
                              //         statusId: '',
                              //       ),
                              //     );

                              final customerBloc = context.read<DeliveryDataBloc>();
                              await Future.wait<void>([
                                customerBloc.stream.firstWhere(
                                    (state) => state is DeliveryDataLoaded),
                                Future(() => customerBloc.add(
                                    GetLocalDeliveryDataByIdEvent(
                                        widget.customer.id ?? ''))),
                                Future(() => customerBloc.add(
                                    GetDeliveryDataByIdEvent(
                                        widget.customer.id ?? ''))),
                              ]);

                              // Navigate after data is refreshed
                              context.pushReplacement(
                                '/delivery-and-invoice/${widget.customer.id}',
                                extra: widget.customer,
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _isFormValid()
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.surfaceVariant,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (state is DeliveryUpdateLoading)
                          const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                          ),
                        Text(
                          state is DeliveryUpdateLoading
                              ? 'Processing...'
                              : 'Save Status',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }
}
