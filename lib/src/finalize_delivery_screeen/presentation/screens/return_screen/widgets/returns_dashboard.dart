import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/presentation/bloc/return_state.dart';

import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/src/auth/presentation/bloc/auth_state.dart';

import '../../../../../auth/presentation/bloc/auth_event.dart';
class ReturnsDashboard extends StatefulWidget {
  const ReturnsDashboard({super.key});

  @override
  State<ReturnsDashboard> createState() => _ReturnsDashboardState();
}

class _ReturnsDashboardState extends State<ReturnsDashboard> {
  ReturnState? _cachedState;
  late final AuthBloc _authBloc;
  late final ReturnBloc _returnBloc;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeBlocs();
    _setupDataListeners();
  }

  void _initializeBlocs() {
    _authBloc = context.read<AuthBloc>();
    _returnBloc = context.read<ReturnBloc>();
  }

  void _setupDataListeners() {
    if (!_isInitialized) {
      final userId = context.read<UserProvider>().userId;
      if (userId != null) {
        debugPrint('🔄 Loading user trip data for ID: $userId');
        _authBloc
          ..add(LoadLocalUserTripEvent(userId))
          ..add(GetUserTripEvent(userId));
      }

      _authBloc.stream.listen((state) {
        if (state is UserTripLoaded && state.trip.id != null) {
          debugPrint('✅ User trip loaded: ${state.trip.id}');
          _returnBloc
            ..add(LoadLocalReturnsEvent(state.trip.id!))
            ..add(GetReturnsEvent(state.trip.id!));
        }
      });

      _isInitialized = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ReturnBloc, ReturnState>(
      listener: (context, state) {
        if (state is ReturnLoaded) {
          setState(() => _cachedState = state);
        }
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            children: [
              _buildHeader(context),
              const SizedBox(height: 30),
              _buildDashboardContent(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Returns Summary',
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                'Returns Overview',
                style: Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              )
            ],
          ),
        )
      ],
    );
  }

  Widget _buildDashboardContent(BuildContext context) {
    return BlocBuilder<ReturnBloc, ReturnState>(
      builder: (context, state) {
        final effectiveState = _cachedState ?? state;

        if (effectiveState is ReturnLoaded) {
          final returns = effectiveState.returns;
          
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 3,
            crossAxisSpacing: 5,
            mainAxisSpacing: 22,
            children: [
              _buildInfoItem(
                context,
                Icons.assignment_return,
                returns.length.toString(),
                'Total Returns',
              ),
              _buildInfoItem(
                context,
                Icons.calendar_today,
                returns.isNotEmpty
                    ? returns.first.returnDate?.toLocal().toString().split(' ')[0] ?? 'Today'
                    : 'Today',
                'Return Date',
              ),
              _buildInfoItem(
                context,
                Icons.inventory_2,
                _calculateTotalItems(returns).toString(),
                'Total Items',
              ),
              _buildInfoItem(
                context,
                Icons.store,
                _calculateUniqueCustomers(returns).toString(),
                'Customers',
              ),
            ],
          );
        }

        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  int _calculateTotalItems(List<ReturnEntity> returns) {
    return returns.fold(0, (sum, item) {
      return sum + 
        (item.productQuantityCase ?? 0) +
        (item.productQuantityPcs ?? 0) +
        (item.productQuantityPack ?? 0) +
        (item.productQuantityBox ?? 0);
    });
  }

  int _calculateUniqueCustomers(List<ReturnEntity> returns) {
    return returns.map((r) => r.customer?.id).toSet().length;
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
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            )
          ],
        )
      ],
    );
  }

  @override
  void dispose() {
    _cachedState = null;
    super.dispose();
  }
}
