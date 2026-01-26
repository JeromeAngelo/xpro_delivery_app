import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';

import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/presentation/bloc/delivery_update_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/presentation/bloc/trip_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';

class QRScannerView extends StatefulWidget {
  const QRScannerView({super.key});

  @override
  State<QRScannerView> createState() => _QRScannerViewState();
}

class _QRScannerViewState extends State<QRScannerView>
    with WidgetsBindingObserver {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool _isProcessing = false;
  bool _flashOn = false;
  bool _frontCamera = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // App lifecycle state has changed, check if we need to pause/resume camera
    if (state == AppLifecycleState.resumed) {
      controller?.resumeCamera();
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      controller?.pauseCamera();
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Trip QR Code'),
        actions: [
          IconButton(
            icon: Icon(_flashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _isProcessing ? null : _toggleFlash,
            tooltip: 'Toggle flash',
          ),
          IconButton(
            icon: Icon(_frontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: _isProcessing ? null : _toggleCamera,
            tooltip: 'Switch camera',
          ),
        ],
      ),
      body: BlocConsumer<TripBloc, TripState>(
        listener: (context, state) {
  debugPrint('🔔 BLoC Listener triggered with state: ${state.runtimeType}');

  if (state is TripQRScanned) {
    setState(() => _isProcessing = false);

    final trip = state.trip;
    debugPrint('✅ TripQRScanned received');
    debugPrint('   Trip ID: ${trip.id}');
    debugPrint('   Trip Number ID: ${trip.tripNumberId}');
    debugPrint('   QR Code: ${trip.qrCode}');
    debugPrint('   Delivery Data Count: ${trip.deliveryData.length}');
    debugPrint('   Personnel Count: ${trip.personels.length}');
    debugPrint('   Checklist Count: ${trip.checklist.length}');
    debugPrint('   Delivery Team ID: ${trip.deliveryTeam.target?.id}');
    debugPrint('   OTP ID: ${trip.otp.target?.id}');
    debugPrint('   EndTrip OTP ID: ${trip.endTripOtp.target?.id}');

    if (trip.id != null && trip.tripNumberId != null) {
      debugPrint('🎯 Trip data valid, proceeding with initialization');

      // Initialize delivery updates
      final deliveryIds = trip.deliveryData
          .map((customer) => customer.id ?? '')
          .where((id) => id.isNotEmpty)
          .toList();
      debugPrint('📦 Delivery IDs for initialization: $deliveryIds');

      context.read<DeliveryUpdateBloc>().add(
        InitializePendingStatusEvent(deliveryIds),
      );

      // Get customer data
      context.read<DeliveryDataBloc>().add(
        GetDeliveryDataByTripIdEvent(trip.id!),
      );

      // Close scanner and navigate
      debugPrint('➡ Navigating to trip ticket view for ${trip.tripNumberId}');
      Navigator.pop(context);
      context.go('/trip-ticket/${trip.tripNumberId}');
    } else {
      debugPrint('❌ Trip data invalid: Missing ID or tripNumberId');
      CoreUtils.showSnackBar(
        context,
        'Invalid QR code: Missing trip information',
      );
      controller?.resumeCamera();
    }
  } else if (state is TripError) {
    setState(() => _isProcessing = false);
    debugPrint('❌ TripError: ${state.message}');
    CoreUtils.showSnackBar(context, 'Error: ${state.message}');
    controller?.resumeCamera();
  } else if (state is TripQRScanning) {
    setState(() => _isProcessing = true);
    debugPrint('⏳ TripQRScanning: Scanner is active');
  } else {
    debugPrint('⚠️ Unexpected state: ${state.runtimeType}');
  }
},

        builder: (context, state) {
          return Stack(
            children: [
              // Use LayoutBuilder to get available height
              LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          children: [
                            // QR Scanner view - fixed height to prevent resizing
                            SizedBox(
                              height: constraints.maxHeight * 0.8,
                              child: QRView(
                                key: qrKey,
                                onQRViewCreated: _onQRViewCreated,
                                overlay: QrScannerOverlayShape(
                                  borderColor:
                                      Theme.of(context).colorScheme.primary,
                                  borderRadius: 10,
                                  borderLength: 30,
                                  borderWidth: 10,
                                  cutOutSize:
                                      MediaQuery.of(context).size.width * 0.8,
                                ),
                              ),
                            ),
                            // Bottom section - scrollable if needed
                            Container(
                              color: Colors.white,
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              child: SafeArea(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Position the QR code within the frame to scan',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton.icon(
                                      onPressed:
                                          _isProcessing
                                              ? null
                                              : _showManualEntryDialog,
                                      icon: const Icon(Icons.edit),
                                      label: const Text(
                                        'Enter Trip Number Manually',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          'Processing QR Code...',
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    // Set initial flash state
    controller.getFlashStatus().then((value) {
      if (mounted) setState(() => _flashOn = value ?? false);
    });

    // Set initial camera direction
    controller.getCameraInfo().then((value) {
      if (mounted) setState(() => _frontCamera = value == CameraFacing.front);
    });

    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !_isProcessing) {
        setState(() => _isProcessing = true);
        debugPrint('🔍 QR Code detected: ${scanData.code}');

        // Pause camera while processing
        controller.pauseCamera();

        // Process the QR code using the TripBloc
        context.read<TripBloc>().add(ScanTripQREvent(scanData.code!));
      }
    });
  }

  void _toggleFlash() async {
    if (controller != null) {
      await controller!.toggleFlash();
      final isFlashOn = await controller!.getFlashStatus() ?? false;
      if (mounted) setState(() => _flashOn = isFlashOn);
    }
  }

  void _toggleCamera() async {
    if (controller != null) {
      await controller!.flipCamera();
      final cameraFacing = await controller!.getCameraInfo();
      if (mounted)
        setState(() => _frontCamera = cameraFacing == CameraFacing.front);
    }
  }

  void _showManualEntryDialog() {
    final TextEditingController textController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Trip Number'),
            content: TextField(
              controller: textController,
              decoration: const InputDecoration(
                hintText: 'Trip Number',
                prefixIcon: Icon(Icons.numbers),
                border: OutlineInputBorder(),
              ),
              autofocus: true,
              keyboardType: TextInputType.text,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final tripNumber = textController.text.trim();
                  if (tripNumber.isNotEmpty) {
                    Navigator.pop(context);
                    // Use SearchTripEvent to match the search trip function
                    context.read<TripBloc>().add(SearchTripEvent(tripNumber));
                  }
                },
                child: const Text('Search'),
              ),
            ],
          ),
    ).then((_) => textController.dispose());
  }

  // @override
  // void dispose() {
  //   controller?.dispose();
  //   WidgetsBinding.instance.removeObserver(this);
  //   super.dispose();
  // }
}
