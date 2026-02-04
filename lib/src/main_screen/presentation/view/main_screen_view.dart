import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/entity/users_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_state.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/default_drawer.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/common/app/features/notfication/domain/entity/notification_entity.dart';
import '../../../../core/common/app/features/notfication/presentation/bloc/notification_bloc.dart';
import '../../../../core/common/app/features/notfication/presentation/bloc/notification_event.dart';
import '../../../../core/common/app/features/notfication/presentation/bloc/notification_state.dart';

class MainScreenView extends StatefulWidget {
  const MainScreenView({super.key});

  @override
  State<MainScreenView> createState() => _MainScreenViewState();
}

class _MainScreenViewState extends State<MainScreenView> {
  // Theme mode state

  final GlobalKey _themeSelection = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Check authentication state when main screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentState = context.read<GeneralUserBloc>().state;
      debugPrint(
        '🏠 MainScreen initState - Current auth state: ${currentState.runtimeType}',
      );

      // If user is not authenticated, don't do anything - let the app handle it
      if (currentState is UserAuthenticated) {
        debugPrint('✅ User is authenticated: ${currentState.user.email}');
      } else {
        debugPrint('⚠️ User is not authenticated in MainScreen');
      }
    });
  }
Future<void> _showNotificationMenu({
  required BuildContext context,
  required NotificationState state,
  required List<NotificationEntity> notifications,
//  required VoidCallback onNotificationTap,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final box = context.findRenderObject() as RenderBox;
  final position = box.localToGlobal(Offset.zero, ancestor: overlay);

  // Where the popup should appear (below the bell)
  final relativeRect = RelativeRect.fromLTRB(
    position.dx,
    position.dy + box.size.height,
    overlay.size.width - position.dx - box.size.width,
    overlay.size.height - position.dy,
  );

  // Build menu items (NO ListView inside PopupMenuItem)
  List<PopupMenuEntry<int>> items;

  if (state is NotificationLoading) {
    items = [
      const PopupMenuItem<int>(
        enabled: false,
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('Loading notifications...'),
          ],
        ),
      ),
    ];
  } else if (state is NotificationError) {
    items = [
      PopupMenuItem<int>(
        enabled: false,
        child: Text('Error: ${state.message}'),
      ),
    ];
  } else if (notifications.isEmpty) {
    items = const [
      PopupMenuItem<int>(
        enabled: false,
        child: Text('No notifications'),
      ),
    ];
  } else {
    final showList = notifications.take(30).toList();

    items = [
      PopupMenuItem<int>(
        enabled: false,
        padding: EdgeInsets.zero,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: 380,
            maxWidth: 460,
            maxHeight: 420,
          ),
          child: Scrollbar(
            thumbVisibility: true,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(showList.length, (index) {
                  final notif = showList[index];

                  final tripName = notif.trip?.name ??
                      (notif.trip?.id != null ? notif.trip!.id : 'unknown');

                  final statusText = notif.status?.title ??
                      (notif.trip?.tripNumberId != null
                          ? notif.trip!.tripNumberId
                          : 'unknown');

                  final message =
                      "The Trip $tripName set status of $statusText "
                      "in the ${notif.delivery?.customer?.name ?? 'delivery'}";

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context); // close menu

                      final id = notif.id;
                      if (id != null && id.isNotEmpty) {
                        context.read<NotificationBloc>().add(MarkAsReadEvent(id));
                      }

                      context.go('/delivery-monitoring');
                    //  onNotificationTap();
                    },
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          leading: Icon(
                            (notif.isRead ?? false)
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color: (notif.isRead ?? false)
                                ? Colors.grey
                                : Colors.red,
                            size: 22,
                          ),
                          title: Text(
                            message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: (notif.isRead ?? false)
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: (notif.body != null &&
                                  notif.body!.trim().isNotEmpty)
                              ? Text(
                                  notif.body!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                )
                              : null,
                        ),
                        const Divider(height: 1),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    ];
  }

  await showMenu<int>(
    context: context,
    position: relativeRect,
    items: items,
  );
}

  // Load saved theme mode preference

  @override
  Widget build(BuildContext context) {
    // Get screen size for responsive design
    final screenSize = MediaQuery.of(context).size;
    final isLargeScreen = screenSize.width > 1200;
    final isMediumScreen = screenSize.width > 800 && screenSize.width <= 1200;

    // Calculate grid cross axis count based on screen width
    int crossAxisCount = isLargeScreen ? 4 : (isMediumScreen ? 3 : 2);

    // Calculate card size to ensure they're not too large on big screens
    double maxCardWidth = 320;
    double cardWidth = (screenSize.width - 48) / crossAxisCount;
    cardWidth = cardWidth > maxCardWidth ? maxCardWidth : cardWidth;

    // Calculate icon size based on screen width
    double iconSize = isLargeScreen ? 56 : (isMediumScreen ? 48 : 40);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(
          color:
              Theme.of(
                context,
              ).colorScheme.surface, // This sets the drawer icon color
        ),
        title: Text(
          'X-Pro Delivery Admin App',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.surface,
          ),
        ),
        actions: [
          // ✅ Updated Notifications UI (with debug + reliable tap handling)
          BlocConsumer<NotificationBloc, NotificationState>(
            listener: (context, state) {
              debugPrint('🔔 NotificationBloc state => ${state.runtimeType}');

              if (state is NotificationLoaded) {
                debugPrint('✅ NotificationLoaded');
                debugPrint('   🔴 unreadCount: ${state.unreadCount}');
                debugPrint(
                  '   📦 notifications: ${state.notifications.length}',
                );

                if (state.notifications.isNotEmpty) {
                  final first = state.notifications.first;
                  debugPrint('   🧪 first notif id: ${first.id}');
                  debugPrint('   🧪 first notif createdAt: ${first.createdAt}');
                  debugPrint('   🧪 first notif type: ${first.type}');
                }
              } else if (state is NotificationError) {
                debugPrint('❌ NotificationError: ${state.message}');
              } else if (state is NotificationLoading) {
                debugPrint('⏳ NotificationLoading...');
              } else if (state is NotificationInitial) {
                debugPrint('🟦 NotificationInitial');
              }
            },
            builder: (context, state) {
              // ✅ Auto-load once
              if (state is NotificationInitial) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  debugPrint(
                    '🚀 Dispatching LoadAllNotificationsEvent() from UI',
                  );
                  context.read<NotificationBloc>().add(
                    LoadAllNotificationsEvent(),
                  );
                });
              }

              int unreadCount = 0;
              List<NotificationEntity> notifications = [];

              if (state is NotificationLoaded) {
                unreadCount = state.unreadCount;
                notifications = state.notifications;
              }

              return Stack(
                alignment: Alignment.center,
                children: [
                  // inside your Stack children (replaces PopupMenuButton)
IconButton(
  tooltip: 'Notifications',
  icon: Icon(
    Icons.notifications_outlined,
    color: unreadCount > 0
        ? Colors.red
        : Theme.of(context).colorScheme.surface,
  ),
  onPressed: () => _showNotificationMenu(
    context: context,
    state: state,
    notifications: notifications,
  //  onNotificationTap: onNotificationTap,
  ),
),

                  if (unreadCount > 0)
                    Positioned(
                      right: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),

          BlocBuilder<GeneralUserBloc, GeneralUserState>(
            builder: (context, state) {
              debugPrint('🏠 MainScreen - Auth state: ${state.runtimeType}');

              // Extract user info from various authenticated states
              GeneralUserEntity? currentUser;

              if (state is UserAuthenticated) {
                currentUser = state.user;
              } else if (state is AllUsersLoaded) {
                // Get authenticated user from AllUsersLoaded state
                currentUser = state.authenticatedUser;
                debugPrint(
                  '✅ User is authenticated (AllUsersLoaded state): ${currentUser?.email ?? "unknown"}',
                );
              } else if (state is GeneralUserLoaded) {
                currentUser = state.user;
              } else if (state is UserByIdLoaded) {
                currentUser = state.user;
              }

              // Show user profile if we have current user
              if (currentUser != null) {
                // Get the user's name or email
                final userName =
                    currentUser.name ?? currentUser.email ?? 'User';
                final firstLetter =
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 40),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          child: Text(
                            firstLetter,
                            style: TextStyle(
                              color: Colors.blue.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          userName,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                        Icon(
                          Icons.arrow_drop_down,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                      ],
                    ),
                    itemBuilder:
                        (context) => [
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(currentUser!.email ?? 'N/A'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'settings',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.settings,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 8),
                                Text('Settings'),
                              ],
                            ),
                          ),
                          const PopupMenuDivider(),
                          const PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, size: 20, color: Colors.red),
                                SizedBox(width: 8),
                                Text(
                                  'Logout',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        ],
                    onSelected: (value) {
                      if (value == 'logout') {
                        // Show confirmation dialog
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('Confirm Logout'),
                                content: const Text(
                                  'Are you sure you want to log out?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      context.read<GeneralUserBloc>().add(
                                        UserSignOutEvent(),
                                      );
                                      // Navigate to login screen
                                      context.go('/');
                                    },
                                    child: const Text(
                                      'Logout',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                        );
                      } else if (value == 'profile') {
                        // Navigate to profile page or show profile dialog
                        showDialog(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: const Text('User Profile'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ListTile(
                                      leading: const Icon(Icons.person),
                                      title: const Text('Name'),
                                      subtitle: Text(
                                        currentUser!.name ?? 'Not set',
                                      ),
                                    ),
                                    ListTile(
                                      leading: const Icon(Icons.email),
                                      title: const Text('Email'),
                                      subtitle: Text(
                                        currentUser.email ?? 'Not set',
                                      ),
                                    ),
                                    // ListTile(
                                    //   leading: const Icon(Icons.badge),
                                    //   title: const Text('Role'),
                                    //   subtitle: Text(currentUser?.role ?? 'User'),
                                    // ),
                                  ],
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                        );
                      } else if (value == 'settings') {
                        // Navigate to settings page or show settings dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Settings coming soon')),
                        );
                      }
                    },
                  ),
                );
              } else {
                // Show a simple icon for unauthenticated users
                return IconButton(
                  icon: Icon(
                    Icons.account_circle,
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  onPressed: () {
                    // Navigate to login page if not authenticated
                    context.go('/');
                  },
                );
              }
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: const DefaultDrawer(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Set minimum width constraint

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dashboard',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Welcome to the X-Pro Delivery Admin Dashboard',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 32),
                  GridView.count(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 24,
                    mainAxisSpacing: 24,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildCategoryCard(
                        context,
                        icon: Icons.receipt_long,
                        title: 'Trip Tickets',
                        subtitle: 'Create and manage delivery trips',
                        color: Colors.blue,
                        onTap:
                            () => context.go(
                              '/trip-overview',
                            ), // Using context.go for GoRouter
                        iconSize: iconSize,
                      ),
                      _buildCategoryCard(
                        context,
                        icon: Icons.monitor,
                        title: 'Delivery Monitoring',
                        subtitle: 'View customer\'s status',
                        color: Colors.green,
                        onTap: () => context.go('/delivery-monitoring'),
                        iconSize: iconSize,
                      ),
                      _buildCategoryCard(
                        context,
                        icon: Icons.map_outlined,
                        title: 'Vehicle Monitoring',
                        subtitle: 'View vehicle status and location',
                        color: Colors.orange,
                        onTap: () => context.go('/vehicle-map'),

                        iconSize: iconSize,
                      ),
                      _buildCategoryCard(
                        context,
                        icon: Icons.receipt_long_outlined,
                        title: 'Collections',
                        subtitle: 'View and Manage transactions',
                        color: Colors.purple,
                        onTap: () => context.go('/collections-overview'),
                        iconSize: iconSize,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildOtherModules(context, isLargeScreen),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
    required double iconSize,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: iconSize, color: color),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtherModules(BuildContext context, bool isLargeScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Others',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _buildActivityCard(
                context,
                onTap: () => context.go('/all-users'),
                icon: Icons.verified_user,
                title: 'Users Management',
                description: 'Manage User Account and Access',
                color: Colors.red,
                width: isLargeScreen ? 320 : 280,
              ),
              _buildActivityCard(
                context,
                onTap: () => context.go('/undeliverable-customers'),

                icon: Icons.free_cancellation,
                title: 'Cancelled Deliveries',
                description: 'Process and Review Cancelled Deliveries',
                color: Colors.blue,
                width: isLargeScreen ? 320 : 280,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActivityCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required double width,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(right: 16, bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
