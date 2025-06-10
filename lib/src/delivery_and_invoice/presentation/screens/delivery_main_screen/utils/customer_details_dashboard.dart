import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/status_icons.dart';

class CustomerDetailsDashboard extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final void Function()? onTap;

  const CustomerDetailsDashboard({
    super.key,
    required this.deliveryData,
    this.onTap,
  });

  @override
  State<CustomerDetailsDashboard> createState() =>
      _CustomerDetailsDashboardState();
}

class _CustomerDetailsDashboardState extends State<CustomerDetailsDashboard> {
  DeliveryDataState? _cachedState;

  @override
  void initState() {
    super.initState();
    _loadLocalDeliveryData();
  }

  void _loadLocalDeliveryData() {
    if (widget.deliveryData.id != null) {
      debugPrint('📱 Loading local delivery data: ${widget.deliveryData.id}');
      context.read<DeliveryDataBloc>().add(
        GetLocalDeliveryDataByIdEvent(widget.deliveryData.id!),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<DeliveryDataBloc, DeliveryDataState>(
      listenWhen:
          (previous, current) =>
              current is DeliveryDataLoaded || current is DeliveryDataError,
      listener: (context, state) {
        setState(() {
          _cachedState = state;
        });
      },
      buildWhen:
          (previous, current) =>
              current is DeliveryDataLoaded ||
              current is DeliveryDataLoading ||
              current is DeliveryDataError ||
              _cachedState == null,
      builder: (context, state) {
        final effectiveState = _cachedState ?? state;

        // Show skeleton loading UI when in loading state and no cached data
        if ((state is DeliveryDataLoading || state is DeliveryDataInitial) &&
            _cachedState == null) {
          return _buildLoadingDashboard(context);
        }

        // Use the current delivery data or the loaded one
        final deliveryData =
            (effectiveState is DeliveryDataLoaded)
                ? effectiveState.deliveryData
                : widget.deliveryData;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: _buildDashboard(context, deliveryData),
        );
      },
    );
  }

    Widget _buildDashboard(
    BuildContext context,
    DeliveryDataEntity deliveryData,
  ) {
    final customer = deliveryData.customer.target;
    final invoice = deliveryData.invoice.target;

    // ADDED: Show shimmer loading when customer is null
    if (customer == null) {
      return Card(
        elevation: 0,
        color: Theme.of(context).colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildShimmerHeader(context),
              const SizedBox(height: 30),
              _buildShimmerInfoGrid(context),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, customer),
            const SizedBox(height: 30),
            _buildInfoGrid(context, deliveryData, customer, invoice),
          ],
        ),
      ),
    );
  }

  // ADDED: Shimmer header when customer is null
  Widget _buildShimmerHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Shimmer customer name
              Container(
                height: 24,
                width: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 10),
              // Shimmer address
              Container(
                height: 16,
                width: 250,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        // Shimmer more icon
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }

  // ADDED: Shimmer info grid when customer is null
  Widget _buildShimmerInfoGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      crossAxisSpacing: 15,
      mainAxisSpacing: 22,
      children: List.generate(
        6,
        (index) => _buildShimmerInfoItem(context),
      ),
    );
  }

  // ADDED: Individual shimmer info item
  Widget _buildShimmerInfoItem(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Shimmer icon
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              margin: const EdgeInsets.only(right: 5, top: 2, bottom: 15),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Shimmer title
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Shimmer subtitle
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // UPDATED: Enhanced existing shimmer methods for consistency
  Widget _buildLoadingDashboard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced shimmer header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store name shimmer
                      Container(
                        height: 24,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Address shimmer
                      Container(
                        height: 16,
                        width: 250,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
                // More icon shimmer
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // Enhanced shimmer info grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.9,
              crossAxisSpacing: 8,
              mainAxisSpacing: 25,
              children: List.generate(
                6,
                (index) => _buildSkeletonInfoItem(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonInfoItem(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon shimmer
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              margin: const EdgeInsets.only(right: 5, top: 2, bottom: 15),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title shimmer
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle shimmer
                  Container(
                    height: 12,
                    width: 80,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }


  Widget _buildHeader(BuildContext context, dynamic customer) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                customer?.name ?? 'Unknown Customer',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: widget.onTap,
                child: Text(
                  _buildAddressString(customer),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ],
          ),
        ),
        IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
      ],
    );
  }

  String _buildAddressString(dynamic customer) {
    if (customer == null) return 'No address available';

    final addressParts = <String>[];

    if (customer.barangay != null && customer.barangay!.isNotEmpty) {
      addressParts.add(customer.barangay!);
    }
    if (customer.municipality != null && customer.municipality!.isNotEmpty) {
      addressParts.add(customer.municipality!);
    }
    if (customer.province != null && customer.province!.isNotEmpty) {
      addressParts.add(customer.province!);
    }

    return addressParts.isNotEmpty
        ? addressParts.join(', ')
        : 'No address available';
  }

  Widget _buildInfoGrid(
    BuildContext context,
    DeliveryDataEntity deliveryData,
    dynamic customer,
    dynamic invoice,
  ) {
    // Get delivery status from delivery updates
    final deliveryUpdates = deliveryData.deliveryUpdates.toList();
    final latestStatus =
        deliveryUpdates.isNotEmpty
            ? deliveryUpdates.last.title ?? "Pending"
            : "Pending";

    // Calculate total amount from invoice
    final totalAmount = invoice?.totalAmount ?? 0.0;

    // Since CustomerDataEntity doesn't have contact numbers, we'll use placeholder
    //  final contactNumbers = <String>['No contact available'];

    debugPrint('📊 Building dashboard with:');
    debugPrint('   🏪 Customer: ${customer?.name}');
    debugPrint('   🧾 Invoice: ${invoice?.name}');
    debugPrint('   💰 Total amount: $totalAmount');
    debugPrint('   📦 Delivery status: $latestStatus');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      crossAxisSpacing: 15,
      mainAxisSpacing: 22,
      children: [
        _buildInfoItem(
          context,
          Icons.person,
          customer?.ownerName ?? "No User Available",
          "Contact Person",
        ),
        _buildInfoItem(
          context,
          StatusIcons.getStatusIcon(latestStatus),
          latestStatus,
          "Delivery Status",
        ),

        // _buildContactNumbers(context, contactNumbers),
        _buildInfoItem(
          context,
          Icons.receipt,
          invoice?.refId ?? invoice?.name ?? "No Invoice",
          "Invoice Number",
        ),
        _buildInfoItem(
          context,
          Icons.contact_phone,
          customer?.contactNumber ?? "",
          "Contact Number",
        ),

        _buildInfoItem(
          context,
          Icons.attach_money,
          "₱${totalAmount.toStringAsFixed(2)}",
          "Total Amount",
        ),
        _buildInfoItem(
          context,
          Icons.payment,
          customer?.paymentMode ?? "Not specified",
          "Payment Mode",
        ),
      ],
    );
  }

  Widget _buildInfoItem(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 5, top: 2, bottom: 15),
              child: Icon(
                icon,
                color: Theme.of(context).primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subtitle == "Contact Numbers")
                    ...title
                        .split('\n')
                        .where((number) => number.isNotEmpty)
                        .map(
                          (number) => GestureDetector(
                            onTap: () => _launchPhoneCall(number),
                            child: Text(
                              number,
                              style: TextStyle(
                                color: Theme.of(context).primaryColor,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        )
                  else
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _launchPhoneCall(String phoneNumber) async {
    final url = 'tel:$phoneNumber';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }
}
