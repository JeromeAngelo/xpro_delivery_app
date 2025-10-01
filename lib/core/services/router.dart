import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/src/app_logs/view/app_logs_screen_view.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/src/auth/view/auth_screen_view.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/view/checklist_and_delivery_view.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/view/delivery_and_timeline_view.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/add_delivery_status_dialog.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/undeliverable_dialog.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/view/confirm_order_product_screen.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/invoice_screen/view/product_list_screen.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/view/delivery_and_invoice_view.dart';
import 'package:x_pro_delivery_app/src/delivery_team/presentation/view/delivery_team_view.dart';
import 'package:x_pro_delivery_app/src/end_trip_otp/presentation/view/end_trip_otp_screen.dart';
import 'package:x_pro_delivery_app/src/final_screen/presentation/view/final_screen_view.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/collection_screen/widgets/specific_completed_customer_screen.dart';
import 'package:x_pro_delivery_app/src/greetings/presentation/view/greeting_view.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/view/homepage_view.dart';
import 'package:x_pro_delivery_app/src/loader/presentation/view/loading_screen.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/view/onboarding_view.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/view/first_otp_screen_view.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/collection_screen/view/collection_screen.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/undelivered_customer/view/undelivered_customers_screen.dart';

import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/view/finalize_deliveries_view.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/specific_screens/customers_collection_screen.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/view/summary_trip_view.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_screen/presentation/view/get_trip_ticket_view.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_screen/presentation/widgets/accepting_trip_loading_screen.dart';

import '../../src/deliveries_and_timeline/presentation/widgets/add_trip_update_screen.dart';
import '../../src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/update_remarks_screen.dart';
import '../../src/final_screen/presentation/specific_screens/final_collection_spec_screen.dart';
import '../../src/final_screen/presentation/specific_screens/final_undelivered_spec_screen.dart';
import '../../src/finalize_delivery_screeen/presentation/screens/undelivered_customer/widget/specific_undelivered_customer.dart';
import '../../src/summary_trip/presentation/specific_screens/customers_undelivered_screen.dart';
import '../../src/transaction_screen/presentation/view/transaction_view.dart';
import '../../src/user_performance/view/user_performance_screen.dart';
import '../common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import '../common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_event.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final hasToken = prefs.containsKey('auth_token');
    final isFirstTimer =
        prefs.getBool('isFirstTimer') ??
        true; // Default to true for fresh installs

    debugPrint('🔄 Router redirect check:');
    debugPrint('   🔑 Has auth token: $hasToken');
    debugPrint('   👤 Is first timer: $isFirstTimer');
    debugPrint('   🛣️ Current path: ${state.uri.path}');

    // If user is first timer, only redirect to onboarding from deep links or protected routes
    // Allow normal onboarding flow: / → /sign-in
    final protectedRoutes = ['/homepage', '/loading', '/delivery-and-timeline'];
    if (isFirstTimer && protectedRoutes.contains(state.uri.path)) {
      debugPrint(
        '🆕 First timer accessing protected route, redirecting to onboarding',
      );
      return '/';
    }

    // If not first timer and has valid token, proceed to loading
    if (!isFirstTimer && hasToken && state.uri.path == '/') {
      final userData = prefs.getString('user_data');
      if (userData != null) {
        try {
          // Convert stored data to Map
          Map<String, dynamic> userMap = {};
          final cleanData = userData.replaceAll('{', '').replaceAll('}', '');
          final pairs = cleanData.split(',');

          for (var pair in pairs) {
            final keyValue = pair.split(':');
            if (keyValue.length == 2) {
              userMap[keyValue[0].trim()] = keyValue[1].trim();
            }
          }

          context.read<UserProvider>().initUser(
            LocalUsersModel.fromJson(userMap),
          );
          debugPrint('✅ Auto-signin successful, redirecting to loading');
          return '/loading';
        } catch (e) {
          debugPrint('❌ Data parsing error: $e');
          // If parsing fails, clear the corrupted data and show sign-in
          await prefs.remove('auth_token');
          await prefs.remove('user_data');
          return '/sign-in';
        }
      }
    }

    // If has token but is first timer, clear token and show onboarding
    if (hasToken && isFirstTimer) {
      debugPrint('⚠️ Found token but user is first timer, clearing token');
      await prefs.remove('auth_token');
      await prefs.remove('user_data');
    }

    return null;
  },

  routes: [
    GoRoute(path: '/', builder: (context, state) => const OnBoardingView()),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const AuthScreenView(),
    ),
    GoRoute(
      path: '/homepage',
      builder: (context, state) => const HomepageView(),
    ),
    GoRoute(
      path: '/user-performance',
      builder: (context, state) => const UserPerformanceScreen(),
    ),
    GoRoute(
      path: '/delivery-team',
      builder: (context, state) => const DeliveryTeamView(),
    ),
    GoRoute(
      path: '/trip-ticket/:tripNumberId',
      builder:
          (context, state) => GetTripTickerView(
            tripNumber: state.pathParameters['tripNumberId']!,
          ),
    ),
    GoRoute(
      path: '/accepting-trip/:tripId',
      builder:
          (context, state) => AcceptingTripLoadingScreen(
            tripId: state.pathParameters['tripId']!,
          ),
    ),

    GoRoute(
      path: '/checklist',
      name: 'checklist', // Add name for the route
      builder: (context, state) => const ChecklistAndDeliveryView(),
    ),
    GoRoute(
      path: '/first-otp',
      name: 'first-otp', // Add name for the route
      builder: (context, state) => const FirstOtpScreenView(),
    ),
    GoRoute(
      path: '/delivery-and-timeline',
      name: 'delivery-and-timeline', // Add name for the route
      builder: (context, state) => const DeliveryAndTimeline(),
    ),
    // Add this route after the existing routes
    GoRoute(
      path: '/add-trip-update/:tripId',
      name: 'add-trip-update',
      builder: (context, state) {
        final tripId = state.pathParameters['tripId']!;
        return AddTripUpdateScreen(tripId: tripId);
      },
    ),

    GoRoute(
      path: '/delivery-and-invoice/:customerId',
      builder: (context, state) {
        final customerId = state.pathParameters['customerId']!;
        debugPrint(
          '🔄 Router: Navigating to delivery-and-invoice for customer: $customerId',
        );

        // Use the customer from extra data if available, otherwise use a placeholder
        final customer = state.extra as DeliveryDataEntity?;

        // Always load fresh data to ensure we have complete information
        debugPrint('📡 Router: Loading fresh data for customer: $customerId');
        context.read<DeliveryDataBloc>()
          ..add(GetLocalDeliveryDataByIdEvent(customerId))
          ..add(GetDeliveryDataByIdEvent(customerId));

        return DeliveryAndInvoiceView(selectedCustomer: customer);
      },
    ),
    GoRoute(
      path: '/undelivered-customer-details/:cancelledInvoiceId',
      name: 'undelivered-customer-details',
      builder: (context, state) {
        final cancelledInvoiceId = state.pathParameters['cancelledInvoiceId']!;
        debugPrint(
          '🔄 Navigating to undelivered customer details: $cancelledInvoiceId',
        );

        return SpecificUndeliveredCustomerScreen(
          cancelledInvoiceId: cancelledInvoiceId,
        );
      },
    ),

    GoRoute(
      path: '/customer-undelivered-screen/:cancelledInvoiceId',
      name: 'customer-undelivered-screen',
      builder: (context, state) {
        final cancelledInvoiceId = state.pathParameters['cancelledInvoiceId']!;
        debugPrint(
          '🔄 Navigating to undelivered customer details: $cancelledInvoiceId',
        );

        return CustomersUndeliveredScreen(
          cancelledInvoiceId: cancelledInvoiceId,
        );
      },
    ),

    GoRoute(
      path: '/final-undelivered-screen/:cancelledInvoiceId',
      name: 'final-undelivered-screen',
      builder: (context, state) {
        final cancelledInvoiceId = state.pathParameters['cancelledInvoiceId']!;
        debugPrint(
          '🔄 Navigating to undelivered customer details: $cancelledInvoiceId',
        );

        return FinalUndeliveredSpecScreen(
          cancelledInvoiceId: cancelledInvoiceId,
        );
      },
    ),

    GoRoute(
      path: '/add-delivery-status',
      name: 'add-delivery-status',
      builder:
          (context, state) => AddDeliveryStatusScreen(
            customer: state.extra as DeliveryDataEntity,
          ),
    ),

    GoRoute(
      path: '/undeliverable/:customerId',
      name: 'undeliverable',
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
        return UndeliverableScreen(
          customer: extra['customer'] as DeliveryDataEntity,
          statusId: extra['statusId'] as String,
        );
      },
    ),

    GoRoute(
      path: '/update-remark/:statusId',
      name: 'updateRemark',
      builder: (context, state) {
        return UpdateRemarkScreen(statusId: state.pathParameters['statusId']!);
      },
    ),

    GoRoute(
      path: '/loading',
      name: 'loading',
      builder: (context, state) => const LoadingScreen(),
    ),
    GoRoute(
      path: '/product-list/:invoiceId/:invoiceNumber',
      name: 'product-list',
      builder: (context, state) {
        debugPrint(
          '🔄 Navigating to product list with params: ${state.pathParameters}',
        );

        // Load products for this invoice immediately
        context.read<InvoiceItemsBloc>().add(
          GetInvoiceItemsByInvoiceDataIdEvent(
            state.pathParameters['invoiceId']!,
          ),
        );

        return ProductListScreen(
          invoiceId: state.pathParameters['invoiceId']!,
          invoiceNumber: state.pathParameters['invoiceNumber']!,
          customer: state.extra as DeliveryDataEntity,
        );
      },
    ),

    GoRoute(
      path: '/transaction',
      builder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>;

        return TransactionView(
          deliveryData: extraData['deliveryData'] as DeliveryDataEntity,
          generatedPdf: extraData['generatedPdf'] as Uint8List?, // Allow null
        );
      },
    ),

    GoRoute(
      path: '/confirm-order/:invoiceId/:deliveryDataId',
      name: 'confirm-order',
      builder: (context, state) {
        final invoiceId = state.pathParameters['invoiceId']!;
        final deliveryDataId = state.pathParameters['deliveryDataId']!;
        final extra = state.extra as Map<String, dynamic>?;
        final invoiceNumber = extra?['invoiceNumber'] ?? 'Unknown';

        debugPrint(
          '🔄 Navigating to confirm order with invoiceId: $invoiceId, deliveryDataId: $deliveryDataId',
        );

        // Load invoice items for this confirmation screen
        context.read<InvoiceItemsBloc>().add(
          GetInvoiceItemsByInvoiceDataIdEvent(invoiceId),
        );

        return ConfirmOrderProductScreen(
          invoiceId: invoiceId,
          invoiceNumber: invoiceNumber,
          deliveryDataId: deliveryDataId,
        );
      },
    ),
    GoRoute(
      path: '/finalize-deliveries',
      name: 'finalize-deliveries',
      builder: (context, state) => const FinalizeDeliveriesView(),
    ),
    GoRoute(
      path: '/collection-screen',
      name: 'collection-screen',
      builder: (context, state) => const CollectionScreen(),
    ),
    GoRoute(
      path: '/collection-details/:customerId',
      name: 'collection-details',
      builder: (context, state) {
        final customerId = state.pathParameters['customerId']!;
        return CompletedCustomerDetailsScreen(collectionId: customerId);
      },
    ),
    // GoRoute(
    //   path: '/view-returns',
    //   name: 'view-returns',
    //   builder: (context, state) => const ReturnScreen(),
    // ),
    // GoRoute(
    //   path: '/return-details/:customerId',
    //   name: 'return-details',
    //   builder: (context, state) {
    //     final customerId = state.pathParameters['customerId']!;
    //     return SpecificReturnCustomerScreen(
    //       customerId: customerId,
    //     );
    //   },
    // ),
    GoRoute(
      path: '/summary-collection/:customerId',
      builder: (context, state) {
        final customerId = state.pathParameters['customerId']!;
        return CustomersCollectionScreen(collectionId: customerId);
      },
    ),

    GoRoute(
      path: '/final-spec-collection/:customerId',
      builder: (context, state) {
        final customerId = state.pathParameters['customerId']!;
        return FinalCollectionSpecScreen(collectionId: customerId);
      },
    ),

    // GoRoute(
    //   path: '/summary-return/:customerId',
    //   builder: (context, state) {
    //     final customerId = state.pathParameters['customerId']!;
    //     return CustomersReturnScreen(customerId: customerId);
    //   },
    // ),
    GoRoute(
      path: '/view-uc',
      name: '/view-uc',
      builder: (context, state) => const UndeliveredCustomersScreen(),
    ),
    GoRoute(
      path: '/end-trip-otp',
      name: '/end-trip-otp',
      builder: (context, state) => const EndTripOtpScreen(),
    ),
    GoRoute(
      path: '/greeting-page',
      name: '/greeting-page',
      builder: (context, state) => const GreetingView(),
    ),
    GoRoute(
      path: '/summary-trip',
      name: '/summary-trip',
      builder: (context, state) => const SummaryTripView(),
    ),
    GoRoute(
      path: '/final-screen',
      name: '/final-screen',
      builder: (context, state) => const FinalScreenView(),
    ),
    GoRoute(
      path: '/app-logs',
      name: '/app-logs',
      builder: (context, state) => const AppLogsScreenView(),
    ),
  ],
);
