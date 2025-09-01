import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_data/data/model/invoice_data_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/presentation/bloc/invoice_status_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/presentation/bloc/invoice_status_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice_status/presentation/bloc/invoice_status_state.dart';
import 'package:x_pro_delivery_app/core/enums/invoice_status.dart';
import 'package:x_pro_delivery_app/core/services/app_debug_logger.dart';

class InvoiceList extends StatefulWidget {
  final DeliveryDataEntity deliveryData;
  final InvoiceDataModel invoice;
  final InvoiceStatus? invoiceStatus;
  final bool isStatusLoading;
  final VoidCallback? onTap;

  const InvoiceList({
    super.key, 
    required this.deliveryData, 
    required this.invoice,
    this.invoiceStatus,
    this.isStatusLoading = false,
    this.onTap,
  });

  @override
  State<InvoiceList> createState() => _InvoiceListState();
}

class _InvoiceListState extends State<InvoiceList> {
  InvoiceStatus? _cachedInvoiceStatus;
  InvoiceStatusState? _cachedBlocState;
  bool _isStatusLoaded = false;

  @override
  void initState() {
    super.initState();
    AppDebugLogger.instance.logInfo('📄 Invoice List initialized for invoice: ${widget.invoice.refId ?? widget.invoice.id}');
    _loadInvoiceStatusOfflineFirst();
  }

  void _loadInvoiceStatusOfflineFirst() {
    if (widget.invoice.id != null) {
      AppDebugLogger.instance.logInfo('📡 Loading invoice status (offline-first) for invoice: ${widget.invoice.id}');
      debugPrint('📡 Loading invoice status for invoice: ${widget.invoice.id}');
      
      // Offline-first approach: Load local data first, then remote
      context.read<InvoiceStatusBloc>().add(
        GetLocalInvoiceStatusByInvoiceIdEvent(widget.invoice.id!),
      );
      
      // Then fetch remote data to sync
      context.read<InvoiceStatusBloc>().add(
        GetInvoiceStatusByInvoiceIdEvent(widget.invoice.id!),
      );
    } else {
      AppDebugLogger.instance.logWarning('⚠️ Cannot load invoice status: Invoice ID is null');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the passed invoice directly
    final invoice = widget.invoice;

    // Debug: Check data structure
    _debugDataStructure();

    // Calculate product count from delivery data invoice items
    final productCount = _getProductCount();

    debugPrint('🎯 Building invoice tile with data:');
    debugPrint('   📝 Invoice ID: ${invoice.id}');
    debugPrint('   📝 Invoice #: ${invoice.refId ?? invoice.name}');
    debugPrint('   📦 Products Count: $productCount');

    return BlocListener<InvoiceStatusBloc, InvoiceStatusState>(
      listener: (context, state) {
        AppDebugLogger.instance.logInfo('📋 Invoice status state changed: ${state.runtimeType}');
        
        // Handle both remote and local loaded states
        if ((state is InvoiceStatusByInvoiceIdLoaded || state is LocalInvoiceStatusByInvoiceIdLoaded) && 
            _getStateInvoiceId(state) == widget.invoice.id) {
          
          final invoiceStatusList = _getInvoiceStatusFromState(state);
          final stateType = state.runtimeType.toString();
          
          debugPrint('📋 LISTENER: Processing ${stateType} for invoice ${widget.invoice.id}');
          debugPrint('   📋 Status records received: ${invoiceStatusList.length}');
          
          AppDebugLogger.instance.logInfo('📋 Invoice status loaded for ${widget.invoice.id}: ${invoiceStatusList.length} records (${stateType})');
          
          // Cache the status from the first record (if any)
          if (invoiceStatusList.isNotEmpty) {
            final statusRecord = invoiceStatusList.first;
            final newStatus = statusRecord.tripStatus;
            
            debugPrint('📋 LISTENER: Status record details:');
            debugPrint('   📋 Record Type: ${statusRecord.runtimeType}');
            debugPrint('   📋 Trip Status: ${newStatus?.name} (index: ${newStatus?.index})');
            debugPrint('   📋 Previous Cached: ${_cachedInvoiceStatus?.name}');
            debugPrint('   📋 Status Changed: ${_cachedInvoiceStatus != newStatus}');
            
            AppDebugLogger.instance.logInfo('✅ Caching invoice status: ${newStatus?.name} for invoice: ${widget.invoice.id} (from $stateType)');
            
            setState(() {
              _cachedInvoiceStatus = newStatus;
              _cachedBlocState = state;
              _isStatusLoaded = true;
            });
            debugPrint('✅ LISTENER: Invoice status cached successfully: ${_cachedInvoiceStatus?.name}');
          } else {
            debugPrint('⚠️ LISTENER: Empty status list received');
            AppDebugLogger.instance.logWarning('⚠️ No invoice status records found for invoice: ${widget.invoice.id}');
          }
        } else {
          debugPrint('🔄 LISTENER: State ignored - not for our invoice (ours: ${widget.invoice.id}, state: ${_getStateInvoiceId(state)})');
        }
        
        if (state is InvoiceStatusError) {
          AppDebugLogger.instance.logError('❌ Invoice status error: ${state.message}');
        }
        
        if (state is InvoiceStatusLoading) {
          AppDebugLogger.instance.logInfo('🔄 Invoice status loading...');
        }
      },
      child: BlocBuilder<InvoiceStatusBloc, InvoiceStatusState>(
        buildWhen: (previous, current) {
          // Only rebuild when:
          // 1. We get status data for this specific invoice
          // 2. Or there's an error
          // 3. Or initial loading
          
          if (current is InvoiceStatusByInvoiceIdLoaded || current is LocalInvoiceStatusByInvoiceIdLoaded) {
            final stateInvoiceId = _getStateInvoiceId(current);
            final shouldRebuild = stateInvoiceId == widget.invoice.id;
            debugPrint('🔄 buildWhen check: ${current.runtimeType} for invoice ${stateInvoiceId} (ours: ${widget.invoice.id}) -> rebuild: $shouldRebuild');
            return shouldRebuild;
          }
          
          if (current is InvoiceStatusError || current is InvoiceStatusLoading) {
            debugPrint('🔄 buildWhen: ${current.runtimeType} -> rebuild: true');
            return true;
          }
          
          debugPrint('🔄 buildWhen: ${current.runtimeType} -> rebuild: false');
          return false;
        },
        builder: (context, state) {
          debugPrint('🎨 BUILDER: Building with state: ${state.runtimeType}');
          debugPrint('   Status loaded: $_isStatusLoaded, Cached status: ${_cachedInvoiceStatus?.name}');
          
          // Determine invoice status to display
          String invoiceStatusText = _getInvoiceStatusText();
          Color statusColor = _getStatusColor(invoiceStatusText);
          
          debugPrint('🎨 FINAL UI STATUS: "$invoiceStatusText" with color: $statusColor');

          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text('Invoice #${invoice.refId ?? invoice.name ?? 'Unknown'}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  Text('$productCount Products'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      invoiceStatusText.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              leading: CircleAvatar(
                backgroundColor: statusColor.withOpacity(0.1),
                child: Icon(
                  Icons.receipt_long,
                  color: statusColor,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (state is InvoiceStatusLoading && !_isStatusLoaded)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ],
              ),
              onTap: widget.onTap,
            ),
          );
        },
      ),
    );
  }

  int _getProductCount() {
    try {
      // Try multiple approaches to get the correct count
      debugPrint('📊 Invoice Items Analysis - Starting multiple approaches:');
      debugPrint('   🔗 Invoice ID: ${widget.invoice.id}');
      debugPrint('   🔗 Delivery Data ID: ${widget.deliveryData.id}');
      
      AppDebugLogger.instance.logInfo('📊 Calculating product count for invoice: ${widget.invoice.id}');
      
      // Approach 1: Filter from delivery data invoice items
      final invoiceSpecificItemsCount = _getInvoiceSpecificItemsCount();
      debugPrint('   📦 Approach 1 (Filtered from delivery): $invoiceSpecificItemsCount items');
      AppDebugLogger.instance.logInfo('   📦 Filtered count: $invoiceSpecificItemsCount items');
      
      // Approach 2: Try to get count from invoice itself (fallback)
      int fallbackCount = 0;
      // If the invoice-specific filtering didn't work, we might need a fallback
      if (invoiceSpecificItemsCount == 0 && widget.deliveryData.invoiceItems.isNotEmpty) {
        // Check if this is the primary invoice (first one in the list)
        final allInvoices = widget.deliveryData.invoices;
        if (allInvoices.isNotEmpty) {
          final isFirstInvoice = allInvoices.first.id == widget.invoice.id;
          if (isFirstInvoice && allInvoices.length == 1) {
            // If there's only one invoice, assume all items belong to it
            fallbackCount = widget.deliveryData.invoiceItems.length;
            debugPrint('   📦 Approach 2 (Single invoice fallback): $fallbackCount items');
            AppDebugLogger.instance.logInfo('   📦 Single invoice fallback: $fallbackCount items');
          } else if (allInvoices.length > 1) {
            // Multiple invoices: distribute items evenly as fallback
            fallbackCount = (widget.deliveryData.invoiceItems.length / allInvoices.length).ceil();
            debugPrint('   📦 Approach 2 (Multi-invoice distribution): $fallbackCount items');
            AppDebugLogger.instance.logInfo('   📦 Multi-invoice distribution: $fallbackCount items');
          }
        }
      }
      
      final finalCount = invoiceSpecificItemsCount > 0 ? invoiceSpecificItemsCount : fallbackCount;
      debugPrint('   ✅ Final count: $finalCount items');
      AppDebugLogger.instance.logInfo('✅ Final product count: $finalCount items');
      
      return finalCount;
    } catch (e) {
      debugPrint('❌ Error getting product count: $e');
      AppDebugLogger.instance.logError('❌ Error getting product count: $e');
      return 0;
    }
  }

  int _getInvoiceSpecificItemsCount() {
    try {
      debugPrint('🔍 Debug: Starting invoice-specific items analysis');
      debugPrint('   🎯 Target Invoice ID: ${widget.invoice.id}');
      debugPrint('   📦 Total Invoice Items in Delivery: ${widget.deliveryData.invoiceItems.length}');
      
      // Debug: Log all invoice items and their relations
      debugPrint('   📋 All Invoice Items in Delivery:');
      for (int i = 0; i < widget.deliveryData.invoiceItems.length; i++) {
        final item = widget.deliveryData.invoiceItems[i];
        debugPrint('     ${i + 1}. Item: ${item.name ?? 'Unknown'} (ID: ${item.id})');
        debugPrint('         - Related Invoice ID: ${item.invoiceData.target?.id ?? 'NULL'}');
        debugPrint('         - Invoice Relation Exists: ${item.invoiceData.target != null}');
        debugPrint('         - Raw Invoice Data ID: ${item.invoiceDataId ?? 'NULL'}');
        
        // Check if the item has any reference to our target invoice
        final targetInvoiceId = widget.invoice.id;
        if (item.invoiceDataId == targetInvoiceId) {
          debugPrint('         - ✅ MATCH FOUND via invoiceDataId!');
        }
        if (item.invoiceData.target?.id == targetInvoiceId) {
          debugPrint('         - ✅ MATCH FOUND via invoiceData.target!');
        }
      }
      
      // Filter invoice items that belong to this specific invoice
      final invoiceSpecificItems = widget.deliveryData.invoiceItems
          .where((item) {
            final itemInvoiceId = item.invoiceData.target?.id;
            final rawInvoiceDataId = item.invoiceDataId;
            final targetInvoiceId = widget.invoice.id;
            
            debugPrint('🔍 Comparing:');
            debugPrint('   - Item Invoice ID (via target): "$itemInvoiceId"');
            debugPrint('   - Item Invoice ID (via rawId): "$rawInvoiceDataId"');
            debugPrint('   - Target Invoice ID: "$targetInvoiceId"');
            
            // Check both the relation target and the direct ID field
            final matchesTarget = itemInvoiceId == targetInvoiceId;
            final matchesRawId = rawInvoiceDataId == targetInvoiceId;
            
            debugPrint('   - Matches via target: $matchesTarget');
            debugPrint('   - Matches via rawId: $matchesRawId');
            
            return matchesTarget || matchesRawId;
          })
          .toList();
      
      debugPrint('📊 Invoice-Specific Items Analysis:');
      debugPrint('   🎯 Target Invoice ID: ${widget.invoice.id}');
      debugPrint('   📦 Total Invoice Items in Delivery: ${widget.deliveryData.invoiceItems.length}');
      debugPrint('   📦 Items for this Invoice: ${invoiceSpecificItems.length}');
      
      // Log individual matching items for debugging
      if (invoiceSpecificItems.isNotEmpty) {
        debugPrint('   📋 Matching Invoice-Specific Items Details:');
        for (int i = 0; i < invoiceSpecificItems.length; i++) {
          final item = invoiceSpecificItems[i];
          debugPrint('     ${i + 1}. ${item.name ?? 'Unknown'} (ID: ${item.id})');
          debugPrint('         - Quantity: ${item.quantity}');
          debugPrint('         - Total Amount: ${item.totalAmount}');
        }
      } else {
        debugPrint('   ⚠️ No items found for this specific invoice');
        debugPrint('   🔍 This might indicate:');
        debugPrint('      - Invoice items are not properly related to invoices');
        debugPrint('      - Data is not properly expanded when fetching');
        debugPrint('      - Invoice items belong to a different invoice ID');
      }
      
      return invoiceSpecificItems.length;
    } catch (e) {
      debugPrint('❌ Error getting invoice-specific items count: $e');
      return 0;
    }
  }
  void _debugDataStructure() {
    debugPrint('🔍 Data Structure Debug:');
    debugPrint('   📊 Delivery Data ID: ${widget.deliveryData.id}');
    debugPrint('   📊 Delivery Data has ${widget.deliveryData.invoices.length} invoices');
    debugPrint('   📊 Delivery Data has ${widget.deliveryData.invoiceItems.length} invoice items');
    
    AppDebugLogger.instance.logInfo('🔍 Invoice data structure analysis');
    AppDebugLogger.instance.logInfo('   📊 Delivery: ${widget.deliveryData.id} | Invoices: ${widget.deliveryData.invoices.length} | Items: ${widget.deliveryData.invoiceItems.length}');
    
    // Log all invoices in this delivery
    debugPrint('   📋 All Invoices in Delivery:');
    for (int i = 0; i < widget.deliveryData.invoices.length; i++) {
      final inv = widget.deliveryData.invoices[i];
      debugPrint('     ${i + 1}. Invoice: ${inv.refId ?? inv.name} (ID: ${inv.id})');
      AppDebugLogger.instance.logInfo('   📋 Invoice ${i + 1}: ${inv.refId ?? inv.name} (${inv.id})');
    }
    
    debugPrint('   🎯 Current Invoice: ${widget.invoice.refId ?? widget.invoice.name} (ID: ${widget.invoice.id})');
    AppDebugLogger.instance.logInfo('🎯 Current invoice: ${widget.invoice.refId ?? widget.invoice.name} (${widget.invoice.id})');
  }

  // Helper method to extract invoice ID from different state types
  String? _getStateInvoiceId(InvoiceStatusState state) {
    if (state is InvoiceStatusByInvoiceIdLoaded) {
      return state.invoiceId;
    }
    if (state is LocalInvoiceStatusByInvoiceIdLoaded) {
      return state.invoiceId;
    }
    return null;
  }

  // Helper method to extract invoice status list from different state types
  List<dynamic> _getInvoiceStatusFromState(InvoiceStatusState state) {
    if (state is InvoiceStatusByInvoiceIdLoaded) {
      return state.invoiceStatus;
    }
    if (state is LocalInvoiceStatusByInvoiceIdLoaded) {
      return state.invoiceStatus;
    }
    return [];
  }

  // Helper method to get status color based on status text
  Color _getStatusColor(String statusText) {
    switch (statusText.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'in transit':
        return Colors.blue;
      case 'unloading':
        return Colors.orange;
      case 'unloaded':
        return Colors.deepOrange;
      case 'cancelled':
        return Colors.red;
      case 'pending':
      case 'draft':
        return Colors.grey;
      case 'ready for delivery':
        return Colors.teal;
      case 'pending items':
      case 'pending payment':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _getInvoiceStatusText() {
    try {
      final invoice = widget.invoice;
      final itemsCount = _getInvoiceSpecificItemsCount();
      
      debugPrint('🏷️ DETAILED Status Analysis for Invoice: ${invoice.id}');
      debugPrint('==========================================');
      debugPrint('📊 INVOICE DATA:');
      debugPrint('   💰 Total Amount: ${invoice.totalAmount}');
      debugPrint('   📦 Items Count: $itemsCount');
      debugPrint('   📝 Invoice Ref: ${invoice.refId}');
      debugPrint('   📝 Invoice Name: ${invoice.name}');
      debugPrint('');
      debugPrint('📊 DELIVERY DATA:');
      debugPrint('   🚚 Has Trip: ${widget.deliveryData.hasTrip}');
      debugPrint('   📋 Delivery Invoice Status Enum: ${widget.deliveryData.invoiceStatus?.name}');
      debugPrint('   📋 Delivery Invoice Status Index: ${widget.deliveryData.invoiceStatus?.index}');
      debugPrint('');
      debugPrint('📊 BLOC STATUS DATA:');
      debugPrint('   📋 Status Loaded: $_isStatusLoaded');
      debugPrint('   📋 Cached Bloc State Type: ${_cachedBlocState.runtimeType}');
      debugPrint('   📋 Cached Invoice Status Enum: ${_cachedInvoiceStatus?.name}');
      debugPrint('   📋 Cached Invoice Status Index: ${_cachedInvoiceStatus?.index}');
      debugPrint('');
      debugPrint('📊 STATUS PRIORITY CHECK:');
      debugPrint('   1️⃣ InvoiceStatusBloc cached: ${_cachedInvoiceStatus != null ? _cachedInvoiceStatus!.name : 'NULL'}');
      debugPrint('   2️⃣ DeliveryData.invoiceStatus: ${widget.deliveryData.invoiceStatus != null ? widget.deliveryData.invoiceStatus!.name : 'NULL'}');
      debugPrint('   3️⃣ Would use fallback logic if both above are null');
      debugPrint('==========================================');
      
      AppDebugLogger.instance.logInfo('🏷️ Status Analysis for invoice: ${invoice.id}');
      AppDebugLogger.instance.logInfo('   📊 Status sources - Cached BLoC: ${_cachedInvoiceStatus?.name}, Delivery Data: ${widget.deliveryData.invoiceStatus?.name}');
      
      String statusText;
      String statusSource;
      
      // Priority 1: Use cached status from InvoiceStatusBloc (most accurate)
      if (_cachedInvoiceStatus != null) {
        statusText = _mapInvoiceStatusToText(_cachedInvoiceStatus!);
        statusSource = 'InvoiceStatusBloc (Cached)';
        debugPrint('✅ PRIORITY 1: Using cached bloc status: $_cachedInvoiceStatus -> $statusText');
        AppDebugLogger.instance.logInfo('✅ Using cached bloc status: $statusText (from $statusSource)');
        return statusText;
      }
      
      // Priority 2: Use delivery data invoice status
      final deliveryInvoiceStatus = widget.deliveryData.invoiceStatus;
      if (deliveryInvoiceStatus != null) {
        statusText = _mapInvoiceStatusToText(deliveryInvoiceStatus);
        statusSource = 'DeliveryData.invoiceStatus';
        debugPrint('✅ PRIORITY 2: Using delivery data status: $deliveryInvoiceStatus -> $statusText');
        AppDebugLogger.instance.logInfo('✅ Using delivery data status: $statusText (from $statusSource)');
        return statusText;
      }
      
      // Note: InvoiceDataModel doesn't have a direct status field.
      // Status information comes from InvoiceStatusModel via InvoiceStatusBloc.
      debugPrint('ℹ️ PRIORITY 2.5: Skipped - InvoiceDataModel has no direct status field');
      debugPrint('   Status comes from separate InvoiceStatusModel via InvoiceStatusBloc');
      
      // Priority 3: Fallback logic based on delivery state and invoice content
      statusText = _determineFallbackStatus(itemsCount, invoice);
      statusSource = 'Fallback Logic';
      debugPrint('✅ PRIORITY 3: Using fallback status logic: $statusText');
      AppDebugLogger.instance.logInfo('✅ Using fallback status logic: $statusText (from $statusSource)');
      return statusText;
      
    } catch (e) {
      debugPrint('❌ Error determining invoice status: $e');
      AppDebugLogger.instance.logError('❌ Error determining invoice status: $e');
      return 'Unknown';
    }
  }

  String _mapInvoiceStatusToText(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.none:
        return 'Pending';
      case InvoiceStatus.truck:
        return 'In Transit';
      case InvoiceStatus.unloading:
        return 'Unloading';
      case InvoiceStatus.unloaded:
        return 'Unloaded';
      case InvoiceStatus.delivered:
        return 'Delivered';
      case InvoiceStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _determineFallbackStatus(int itemsCount, InvoiceDataModel invoice) {
    // Priority 3: Fallback logic based on delivery state
    if (widget.deliveryData.hasTrip == true) {
      return 'In Transit';
    }
    
    // Priority 4: Status based on invoice content
    if (itemsCount > 0 && invoice.totalAmount != null && invoice.totalAmount! > 0) {
      return 'Ready for Delivery';
    }
    
    if (invoice.totalAmount != null && invoice.totalAmount! > 0 && itemsCount == 0) {
      return 'Pending Items';
    }
    
    if (itemsCount > 0 && (invoice.totalAmount == null || invoice.totalAmount! <= 0)) {
      return 'Pending Payment';
    }
    
    return 'Draft';
  }

}
