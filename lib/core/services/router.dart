import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/domain/entity/delivery_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/delivery_data/presentation/bloc/delivery_data_event.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/src/app_logs/view/app_logs_screen_view.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/src/auth/view/auth_screen_view.dart';
import 'package:x_pro_delivery_app/src/checklist_and_delivery_list/presentation/view/checklist_and_delivery_view.dart';
import 'package:x_pro_delivery_app/src/deliveries_and_timeline/presentation/view/delivery_and_timeline_view.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/add_delivery_status_dialog.dart';
import 'package:x_pro_delivery_app/src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/undeliverable_screen.dart';
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

import '../../src/deliveries_and_timeline/presentation/screens/syncing_screen.dart';
import '../../src/deliveries_and_timeline/presentation/widgets/add_trip_update_screen.dart';
import '../../src/delivery_and_invoice/presentation/screens/delivery_main_screen/utils/update_remarks_screen.dart';
import '../../src/delivery_and_invoice/presentation/screens/invoice_screen/view/invoice_cancellation_screen.dart';
import '../../src/final_screen/presentation/specific_screens/final_collection_spec_screen.dart';
import '../../src/final_screen/presentation/specific_screens/final_undelivered_spec_screen.dart';
import '../../src/finalize_delivery_screeen/presentation/screens/undelivered_customer/widget/specific_undelivered_customer.dart';
import '../../src/summary_trip/presentation/specific_screens/customers_undelivered_screen.dart';
import '../../src/transaction_screen/presentation/view/transaction_view.dart';
import '../../src/user_performance/view/user_performance_screen.dart';
import '../common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_bloc.dart';
import '../common/app/features/delivery_data/invoice_items/presentation/bloc/invoice_items_event.dart';
import '../common/app/features/delivery_status_choices/domain/entity/delivery_status_choices_entity.dart';

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
    GoRoute(
      path: '/',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const OnBoardingView(), state),
    ),

    GoRoute(
      path: '/sign-in',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const AuthScreenView(), state),
    ),

    GoRoute(
      path: '/homepage',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const HomepageView(), state),
    ),

    GoRoute(
      path: '/user-performance',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const UserPerformanceScreen(), state),
    ),

    GoRoute(
      path: '/delivery-team',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const DeliveryTeamView(), state),
    ),

    GoRoute(
      path: '/trip-ticket/:tripNumberId',
      pageBuilder:
          (context, state) => AppTransitions.fadeSlide(
            GetTripTickerView(
              tripNumber: state.pathParameters['tripNumberId']!,
            ),
            state,
          ),
    ),

    GoRoute(
      path: '/accepting-trip/:tripId',
      pageBuilder:
          (context, state) => AppTransitions.fadeSlide(
            AcceptingTripLoadingScreen(tripId: state.pathParameters['tripId']!),
            state,
          ),
    ),

    GoRoute(
      path: '/checklist',
      name: 'checklist',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const ChecklistAndDeliveryView(), state),
    ),

    GoRoute(
      path: '/first-otp',
      name: 'first-otp',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const FirstOtpScreenView(), state),
    ),

    GoRoute(
      path: '/delivery-and-timeline',
      name: 'delivery-and-timeline',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const DeliveryAndTimeline(), state),
    ),

    GoRoute(
      path: '/add-trip-update/:tripId',
      name: 'add-trip-update',
      pageBuilder: (context, state) {
        final tripId = state.pathParameters['tripId']!;
        return AppTransitions.fadeSlide(
          AddTripUpdateScreen(tripId: tripId),
          state,
        );
      },
    ),

    GoRoute(
      path: '/delivery-and-invoice/:customerId',
      pageBuilder: (context, state) {
        final customerId = state.pathParameters['customerId']!;

        final customer = state.extra as DeliveryDataEntity?;

        context.read<DeliveryDataBloc>()
          ..add(GetLocalDeliveryDataByIdEvent(customerId))
          ..add(GetDeliveryDataByIdEvent(customerId));

        return AppTransitions.fadeSlide(
          DeliveryAndInvoiceView(selectedCustomer: customer),
          state,
        );
      },
    ),

    GoRoute(
      path: '/undelivered-customer-details/:cancelledInvoiceId',
      name: 'undelivered-customer-details',
      pageBuilder: (context, state) {
        final id = state.pathParameters['cancelledInvoiceId']!;
        return AppTransitions.fadeSlide(
          SpecificUndeliveredCustomerScreen(cancelledInvoiceId: id),
          state,
        );
      },
    ),

    GoRoute(
      path: '/customer-undelivered-screen/:cancelledInvoiceId',
      name: 'customer-undelivered-screen',
      pageBuilder: (context, state) {
        final id = state.pathParameters['cancelledInvoiceId']!;
        return AppTransitions.fadeSlide(
          CustomersUndeliveredScreen(cancelledInvoiceId: id),
          state,
        );
      },
    ),

    GoRoute(
      path: '/final-undelivered-screen/:cancelledInvoiceId',
      name: 'final-undelivered-screen',
      pageBuilder: (context, state) {
        final id = state.pathParameters['cancelledInvoiceId']!;
        return AppTransitions.fadeSlide(
          FinalUndeliveredSpecScreen(cancelledInvoiceId: id),
          state,
        );
      },
    ),

    GoRoute(
      path: '/add-delivery-status',
      name: 'add-delivery-status',
      pageBuilder:
          (context, state) => AppTransitions.fadeSlide(
            AddDeliveryStatusScreen(
              customer: state.extra as DeliveryDataEntity,
            ),
            state,
          ),
    ),

    GoRoute(
      path: '/undeliverable/:customerId',
      name: 'undeliverable',
      pageBuilder: (context, state) {
        final extra = state.extra;

        if (extra == null || extra is! Map<String, dynamic>) {
          return AppTransitions.fadeSlide(
            const Scaffold(
              body: Center(child: Text('Invalid navigation data')),
            ),
            state,
          );
        }

        final customer = extra['customerId'];
        final statusId = extra['statusId'];

        if (customer is! DeliveryDataEntity ||
            statusId is! DeliveryStatusChoicesEntity) {
          return AppTransitions.fadeSlide(
            const Scaffold(body: Center(child: Text('Missing required data'))),
            state,
          );
        }

        return AppTransitions.fadeSlide(
          UndeliverableScreen(customer: customer, statusId: statusId),
          state,
        );
      },
    ),

    GoRoute(
      path: '/update-remark/:statusId',
      name: 'updateRemark',
      pageBuilder:
          (context, state) => AppTransitions.fadeSlide(
            UpdateRemarkScreen(statusId: state.pathParameters['statusId']!),
            state,
          ),
    ),

    GoRoute(
      path: '/loading',
      name: 'loading',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const LoadingScreen(), state),
    ),

    GoRoute(
      path: '/product-list/:invoiceId/:invoiceNumber',
      name: 'product-list',
      pageBuilder: (context, state) {
        context.read<InvoiceItemsBloc>().add(
          GetInvoiceItemsByInvoiceDataIdEvent(
            state.pathParameters['invoiceId']!,
          ),
        );

        return AppTransitions.fadeSlide(
          ProductListScreen(
            invoiceId: state.pathParameters['invoiceId']!,
            invoiceNumber: state.pathParameters['invoiceNumber']!,
            customer: state.extra as DeliveryDataEntity,
          ),
          state,
        );
      },
    ),

    GoRoute(
      path: '/transaction',
      pageBuilder: (context, state) {
        final extra = state.extra as Map<String, dynamic>;

        return AppTransitions.fadeSlide(
          TransactionView(
            deliveryData: extra['deliveryData'],
            generatedPdf: extra['generatedPdf'],
          ),
          state,
        );
      },
    ),

    GoRoute(
      path: '/confirm-order/:invoiceId/:deliveryDataId',
      name: 'confirm-order',
      pageBuilder: (context, state) {
        final invoiceId = state.pathParameters['invoiceId']!;
        final deliveryDataId = state.pathParameters['deliveryDataId']!;
        final extra = state.extra as Map<String, dynamic>?;

        context.read<InvoiceItemsBloc>().add(
          GetInvoiceItemsByInvoiceDataIdEvent(invoiceId),
        );

        return AppTransitions.fadeSlide(
          ConfirmOrderProductScreen(
            invoiceId: invoiceId,
            invoiceNumber: extra?['invoiceNumber'] ?? 'Unknown',
            deliveryDataId: deliveryDataId,
          ),
          state,
        );
      },
    ),

    GoRoute(
      path: '/finalize-deliveries',
      name: 'finalize-deliveries',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const FinalizeDeliveriesView(), state),
    ),

    GoRoute(
      path: '/collection-screen',
      name: 'collection-screen',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const CollectionScreen(), state),
    ),

    GoRoute(
      path: '/collection-details/:customerId',
      name: 'collection-details',
      pageBuilder:
          (context, state) => AppTransitions.fadeSlide(
            CompletedCustomerDetailsScreen(
              collectionId: state.pathParameters['customerId']!,
            ),
            state,
          ),
    ),

    GoRoute(
      path: '/summary-collection/:customerId',
      pageBuilder:
          (context, state) => AppTransitions.fadeSlide(
            CustomersCollectionScreen(
              collectionId: state.pathParameters['customerId']!,
            ),
            state,
          ),
    ),

    GoRoute(
      path: '/final-spec-collection/:customerId',
      pageBuilder:
          (context, state) => AppTransitions.fadeSlide(
            FinalCollectionSpecScreen(
              collectionId: state.pathParameters['customerId']!,
            ),
            state,
          ),
    ),

    GoRoute(
      path: '/view-uc',
      name: '/view-uc',
      pageBuilder:
          (context, state) => AppTransitions.fadeSlide(
            const UndeliveredCustomersScreen(),
            state,
          ),
    ),

    GoRoute(
      path: '/end-trip-otp',
      name: '/end-trip-otp',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const EndTripOtpScreen(), state),
    ),

    GoRoute(
      path: '/greeting-page',
      name: '/greeting-page',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const GreetingView(), state),
    ),

    GoRoute(
      path: '/summary-trip',
      name: '/summary-trip',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const SummaryTripView(), state),
    ),

    GoRoute(
      path: '/final-screen',
      name: '/final-screen',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const FinalScreenView(), state),
    ),

    GoRoute(
      path: '/app-logs',
      name: '/app-logs',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const AppLogsScreenView(), state),
    ),

    GoRoute(
      path: '/cancel-invoice/:deliveryDataId/:invoiceId',
      name: 'cancel-invoice',
      pageBuilder: (context, state) {
        final deliveryDataId = state.pathParameters['deliveryDataId'];
        final invoiceId = state.pathParameters['invoiceId'];

        if (deliveryDataId == null || invoiceId == null) {
          return AppTransitions.fadeSlide(
            const Scaffold(
              body: Center(child: Text('Missing required parameters')),
            ),
            state,
          );
        }

        return AppTransitions.fadeSlide(
          InvoiceCancellationScreen(
            deliveryDataId: deliveryDataId,
            invoiceId: invoiceId,
          ),
          state,
        );
      },
    ),
    GoRoute(
      path: '/sync-loading',
      name: 'sync-loading',
      pageBuilder:
          (context, state) =>
              AppTransitions.fadeSlide(const SyncScreen(), state),
    ),
  ],
);

class AppTransitions {
  static CustomTransitionPage fadeSlide(Widget child, GoRouterState state) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionDuration: const Duration(milliseconds: 300),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.05),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
    );
  }
}
