import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/domain/entity/personel_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Delivery_Team/personels/presentation/bloc/personel_state.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_bloc.dart';
import 'package:x_pro_delivery_app/core/enums/user_role.dart';

import '../../../../core/common/app/features/Trip_Ticket/trip/presentation/bloc/trip_state.dart';

class ViewPersonelScreen extends StatefulWidget {
  const ViewPersonelScreen({super.key});

  @override
  State<ViewPersonelScreen> createState() => _ViewPersonelScreenState();
}

class _ViewPersonelScreenState extends State<ViewPersonelScreen> {
  PersonelState? _cachedState;
  bool _isDataInitialized = false;

  @override
  void initState() {
    super.initState();
    _loadPersonelData();
  }

  void _loadPersonelData() {
    if (!_isDataInitialized) {
      final tripState = context.read<TripBloc>().state;
      if (tripState is TripLoaded && tripState.trip.id != null) {
        debugPrint(
            '📱 Loading local personnel data for trip: ${tripState.trip.id}');
        context.read<PersonelBloc>()
          ..add(LoadLocalPersonelsByTripIdEvent(tripState.trip.id!))
          ..add(LoadPersonelsByTripIdEvent(tripState.trip.id!));
        _isDataInitialized = true;
      }
    }
  }

  Future<void> _refreshData() async {
    final tripState = context.read<TripBloc>().state;
    if (tripState is TripLoaded && tripState.trip.id != null) {
      context.read<PersonelBloc>().add(
            LoadPersonelsByTripIdEvent(tripState.trip.id!),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Team Personnel'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: BlocBuilder<PersonelBloc, PersonelState>(
          buildWhen: (previous, current) =>
              current is PersonelsByTripLoaded || _cachedState == null,
          builder: (context, state) {
            if (state is PersonelsByTripLoaded) {
              _cachedState = state;
              return _buildPersonelList(state.personel);
            }

            final cachedState = _cachedState;
            if (cachedState is PersonelsByTripLoaded) {
              return _buildPersonelList(cachedState.personel);
            }

            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildPersonelList(List<PersonelEntity> personels) {
    if (personels.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: personels.length,
      itemBuilder: (context, index) {
        final personel = personels[index];
        return _PersonelCard(personel: personel);
      },
    );
  }
}

class _PersonelCard extends StatelessWidget {
  final PersonelEntity personel;

  const _PersonelCard({required this.personel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    personel.name?.substring(0, 1).toUpperCase() ?? 'N/A',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personel.name ?? 'No Name',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor(personel.role),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          personel.role?.name.toUpperCase() ?? 'UNKNOWN',
                          style:
                              Theme.of(context).textTheme.labelSmall!.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              context,
              Icons.calendar_today,
              'Joined: ${_formatDate(personel.created)}',
            ),
            if (personel.updated != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(
                context,
                Icons.update,
                'Last Updated: ${_formatDate(personel.updated)}',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Color _getRoleColor(UserRole? role) {
    switch (role) {
      case UserRole.teamLeader:
        return Colors.blue;
      case UserRole.helper:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }
}
