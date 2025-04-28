import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_state.dart';
import 'package:x_pro_delivery_app/core/common/widgets/status_icons.dart';

class CustomerDetailsDashboard extends StatefulWidget {
  final CustomerEntity customer;
  final void Function()? onTap;

  const CustomerDetailsDashboard({
    super.key,
    required this.customer,
    this.onTap,
  });

  @override
  State<CustomerDetailsDashboard> createState() =>
      _CustomerDetailsDashboardState();
}

class _CustomerDetailsDashboardState extends State<CustomerDetailsDashboard> {
  CustomerState? _cachedState;

  @override
  void initState() {
    super.initState();
    _loadLocalCustomerData();
  }

  void _loadLocalCustomerData() {
    debugPrint('📱 Loading local customer data: ${widget.customer.id}');
    context.read<CustomerBloc>().add(
      LoadLocalCustomerLocationEvent(widget.customer.id ?? ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CustomerBloc, CustomerState>(
      listenWhen:
          (previous, current) =>
              current is CustomerLocationLoaded || current is CustomerLoaded,
      listener: (context, state) {
        setState(() {
          _cachedState = state;
        });
      },
      buildWhen:
          (previous, current) =>
              current is CustomerLocationLoaded ||
              current is CustomerLoaded ||
              current is CustomerLoading ||
              _cachedState == null,
      builder: (context, state) {
        final effectiveState = _cachedState ?? state;

        // Show skeleton loading UI when in loading state and no cached data
        if ((state is CustomerLoading || state is CustomerInitial) &&
            _cachedState == null) {
          return _buildLoadingDashboard(context);
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          child: _buildDashboard(context, effectiveState),
        );
      },
    );
  }

  Widget _buildLoadingDashboard(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Skeleton header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Store name skeleton
                      Container(
                        height: 24,
                        width: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Address skeleton
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
                // More icon skeleton
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
            // Skeleton info grid
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
            // Icon skeleton
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
                  // Title skeleton
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Subtitle skeleton
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

  Widget _buildDashboard(BuildContext context, CustomerState state) {
    final customer =
        (state is CustomerLocationLoaded) ? state.customer : widget.customer;

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 30),
            _buildInfoGrid(context, state, customer),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.customer.storeName ?? '',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge!.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: widget.onTap,
                child: Text(
                  widget.customer.address ?? '',
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

  Widget _buildInfoGrid(
    BuildContext context,
    CustomerState state,
    CustomerEntity customer,
  ) {
    final invoiceCount = customer.invoicesList.length;
    final totalAmount = customer.totalAmount ?? 0.0;
    final status =
        customer.deliveryStatus.isNotEmpty
            ? customer.deliveryStatus.last.title ?? "No Status"
            : "No Status";

    debugPrint('📊 Building dashboard with:');
    debugPrint('   🧾 Invoices count: ${customer.invoicesList.length}');
    debugPrint('   💰 Total amount: $totalAmount');

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.8,
      crossAxisSpacing: 5,
      mainAxisSpacing: 22,
      children: [
        _buildInfoItem(
          context,
          StatusIcons.getStatusIcon(status),
          status,
          "Delivery Status",
        ),
        _buildInfoItem(
          context,
          Icons.person,
          customer.ownerName ?? "",
          "Contact Person",
        ),
        _buildContactNumbers(context, customer.contactNumber ?? []),
        _buildInfoItem(
          context,
          Icons.receipt,
          invoiceCount.toString(),
          "Invoice/Invoices",
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
          customer.modeOfPayment ?? "",
          "Payment Mode",
        ),
      ],
    );
  }

  Widget _buildContactNumbers(BuildContext context, List<String> phoneNumbers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInfoItem(
          context,
          Icons.phone,
          phoneNumbers.take(2).join('\n'),
          "Contact Numbers",
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
