import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/data/model/customer_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer/presentation/bloc/customer_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/data/models/invoice_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/domain/entity/invoice_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/invoice/presentation/bloc/invoice_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/data/model/product_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/products/presentation/bloc/products_event.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/src/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/view/auth_screen_view.dart';
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
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/return_screen/widgets/specific_return_customer_screen.dart';
import 'package:x_pro_delivery_app/src/greetings/presentation/view/greeting_view.dart';
import 'package:x_pro_delivery_app/src/homepage/presentation/view/homepage_view.dart';
import 'package:x_pro_delivery_app/src/loader/presentation/view/loading_screen.dart';
import 'package:x_pro_delivery_app/src/on_boarding/presentation/view/onboarding_view.dart';
import 'package:x_pro_delivery_app/src/start_trip_otp_screen/presentation/view/first_otp_screen_view.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/collection_screen/view/collection_screen.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/return_screen/view/return_screen.dart';
import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/screens/undelivered_customer/view/undelivered_customers_screen.dart';

import 'package:x_pro_delivery_app/src/finalize_delivery_screeen/presentation/view/finalize_deliveries_view.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/specific_screens/customers_collection_screen.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/specific_screens/customers_return_screen.dart';
import 'package:x_pro_delivery_app/src/summary_trip/presentation/view/summary_trip_view.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_page/presentation/view/get_trip_ticket_view.dart';
import 'package:x_pro_delivery_app/src/trip_ticket_page/presentation/widgets/accepting_trip_loading_screen.dart';

import '../../src/transcation_screeen/presentation/view/transaction_view.dart';
import '../common/app/features/Trip_Ticket/customer/domain/entity/customer_entity.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
  final prefs = await SharedPreferences.getInstance();
  final hasToken = prefs.containsKey('auth_token');

  if (hasToken && state.uri.path == '/') {
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
        
        context.read<UserProvider>().initUser(LocalUsersModel.fromJson(userMap));
      } catch (e) {
        debugPrint('📝 Data parsing handled: $e');
      }
    }
    return '/loading';
  }
  return null;
},


  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const OnBoardingView(),
    ),
    GoRoute(
      path: '/sign-in',
      builder: (context, state) => const AuthScreenView(),
    ),
    GoRoute(
      path: '/homepage',
      builder: (context, state) => const HomepageView(),
    ),
    GoRoute(
      path: '/delivery-team',
      builder: (context, state) => const DeliveryTeamView(),
    ),
    GoRoute(
      path: '/trip-ticket/:tripNumberId',
      builder: (context, state) => GetTripTickerView(
        tripNumber: state.pathParameters['tripNumberId']!,
      ),
    ),
    GoRoute(
  path: '/accepting-trip',
  builder: (context, state) => const AcceptingTripLoadingScreen(),
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
    GoRoute(
      path: '/delivery-and-invoice/:customerId',
      builder: (context, state) {
        // Load local data immediately
        context.read<CustomerBloc>().add(LoadLocalCustomerLocationEvent(
            state.pathParameters['customerId']!));

        context.read<InvoiceBloc>().add(const LoadLocalInvoiceEvent());

        // Use the customer from extra data while local loads
        final customer = state.extra as CustomerEntity;

        return DeliveryAndInvoiceView(
          selectedCustomer: customer,
        );
      },
    ),
    GoRoute(
      path: '/add-delivery-status',
      name: 'add-delivery-status',
      builder: (context, state) => AddDeliveryStatusScreen(
        customer: state.extra as CustomerEntity,
      ),
    ),

    GoRoute(
  path: '/undeliverable/:customerId',
  name: 'undeliverable',
  builder: (context, state) {
    final Map<String, dynamic> extra = state.extra as Map<String, dynamic>;
    return UndeliverableScreen(
      customer: extra['customer'] as CustomerEntity,
      statusId: extra['statusId'] as String,
    );
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
    debugPrint('🔄 Navigating to product list with params: ${state.pathParameters}');
    
    // Load products for this invoice immediately
    context.read<ProductsBloc>().add(
      LoadLocalProductsByInvoiceIdEvent(state.pathParameters['invoiceId']!)
    );

    return ProductListScreen(
      invoiceId: state.pathParameters['invoiceId']!,
      invoiceNumber: state.pathParameters['invoiceNumber']!,
      customer: state.extra as CustomerEntity,
    );
  },
),

    GoRoute(
      path: '/transaction/:id',
      builder: (context, state) {
        final extraData = state.extra as Map<String, dynamic>;
        return TransactionView(
          customer: extraData['customer'] as CustomerEntity,
          selectedInvoices:
              extraData['selectedInvoices'] as List<InvoiceEntity>,
          generatedPdf: extraData['generatedPdf'] as Uint8List,
        );
      },
    ),
    GoRoute(
      path: '/confirm-order/:invoiceId',
      name: 'confirm-order',
      builder: (context, state) {
        final Map<String, dynamic> extraData =
            state.extra as Map<String, dynamic>;
        return ConfirmOrderProductScreen(
          invoice: extraData['invoice'] as InvoiceModel,
          products: extraData['products'] as List<ProductModel>,
          customer: extraData['customer'] as CustomerModel,
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
        return CompletedCustomerDetailsScreen(
          customerId: customerId,
        );
      },
    ),
    GoRoute(
      path: '/view-returns',
      name: 'view-returns',
      builder: (context, state) => const ReturnScreen(),
    ),
    GoRoute(
      path: '/return-details/:customerId',
      name: 'return-details',
      builder: (context, state) {
        final customerId = state.pathParameters['customerId']!;
        return SpecificReturnCustomerScreen(
          customerId: customerId,
        );
      },
    ),
    GoRoute(
  path: '/summary-collection/:customerId',
  builder: (context, state) {
    final customerId = state.pathParameters['customerId']!;
    return CustomersCollectionScreen(customerId: customerId);
  },
),
GoRoute(
  path: '/summary-return/:customerId',
  builder: (context, state) {
    final customerId = state.pathParameters['customerId']!;
    return CustomersReturnScreen(customerId: customerId);
  },
),

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
    )
  ],
);
