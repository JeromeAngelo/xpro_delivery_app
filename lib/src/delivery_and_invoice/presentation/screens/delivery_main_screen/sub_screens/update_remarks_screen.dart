import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_state.dart';

class UpdateRemarkScreen extends StatefulWidget {
  final String statusId;

  const UpdateRemarkScreen({
    super.key,
    required this.statusId,
  });

  @override
  State<UpdateRemarkScreen> createState() => _UpdateRemarkScreenState();
}

class _UpdateRemarkScreenState extends State<UpdateRemarkScreen> {
  final TextEditingController _remarkController = TextEditingController();
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() => _images.add(photo));
    }
  }

  void _submitRemark() {
    if (_remarkController.text.isEmpty || _images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a remark and at least one photo'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final imagePath = _images.first.path;

    context.read<DeliveryUpdateBloc>().add(
          UpdateQueueRemarksEvent(
            statusId: widget.statusId,
            remarks: _remarkController.text.trim(),
            image: imagePath,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeliveryUpdateBloc, DeliveryUpdateState>(
      listener: (context, state) {
        if (state is QueueRemarksUpdated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Remarks updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // Go back after success
        } else if (state is DeliveryUpdateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update remarks: ${state.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Update Remark'),
          centerTitle: true,
          actions: [
            Consumer<ConnectivityProvider>(
              builder: (context, connectivity, child) {
                if (!connectivity.isOnline) {
                  return Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.wifi_off, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text('Offline', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _remarkController,
                decoration: InputDecoration(
                  labelText: 'Remarks',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _images.isEmpty
                    ? InkWell(
                        onTap: _pickImage,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 48, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(height: 8),
                            Text(
                              'Add Photo',
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary),
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
                                      icon: const Icon(Icons.remove_circle,
                                          color: Colors.red),
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
                              backgroundColor: Colors.white,
                              mini: true,
                              onPressed: _pickImage,
                              child: Icon(Icons.add_a_photo,
                                  color: Theme.of(context).colorScheme.primary),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => context.pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  BlocBuilder<DeliveryUpdateBloc, DeliveryUpdateState>(
                    builder: (context, state) {
                      final isLoading = state is DeliveryUpdateLoading;
                      return ElevatedButton(
                        onPressed: isLoading ? null : _submitRemark,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isLoading
                              ? Colors.grey
                              : Theme.of(context).colorScheme.primary,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            :  Text('Save', style: TextStyle(color: Theme.of(context).colorScheme.surface)),
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
