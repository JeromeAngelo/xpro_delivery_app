import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/domain/entity/users_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/provider/theme_provider.dart';

import '../../app/features/notfication/domain/entity/notification_entity.dart';
import '../../app/features/notfication/presentation/bloc/notification_bloc.dart';
import '../../app/features/notfication/presentation/bloc/notification_event.dart';
import '../../app/features/notfication/presentation/bloc/notification_state.dart';

class DesktopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback onThemeToggle;
  final VoidCallback onNotificationTap;
  final VoidCallback onProfileTap;

  const DesktopAppBar({
    super.key,
    required this.onThemeToggle,
    required this.onNotificationTap,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GeneralUserBloc, GeneralUserState>(
      buildWhen: (previous, current) {
        // Only rebuild when authentication state actually changes
        // Don't rebuild for loading states or other non-auth states
        if (current is UserAuthenticated || current is GeneralUserLoaded) {
          return true;
        }
        if (current is UserUnauthenticated || current is GeneralUserInitial) {
          return true;
        }
        // Also rebuild for error states that might affect authentication
        if (current is GeneralUserError) {
          return true;
        }
        // Keep previous authentication state during loading
        return false;
      },
      builder: (context, state) {
        // Enhanced authentication state handling
        String userName = 'Guest';
        String? userEmail;
        String? userAvatar;
        String? userRole;
        bool isAuthenticated = false;
        bool isLoading = false;
        bool hasError = false;
        String? errorMessage;
        GeneralUserEntity? currentUser;

        // Comprehensive state checking
        if (state is UserAuthenticated) {
          currentUser = state.user;
          userName =
              state.user.name ?? state.user.email?.split('@')[0] ?? 'User';
          userEmail = state.user.email;
          userAvatar = state.user.profilePic;
          userRole = state.user.role?.name;
          isAuthenticated = true;
          debugPrint(
            '🔐 Desktop AppBar: User authenticated - ${state.user.email}',
          );
        } else if (state is AllUsersLoaded) {
          // Get authenticated user from AllUsersLoaded state
          currentUser = state.authenticatedUser;
          if (currentUser != null) {
            userName =
                currentUser.name ?? currentUser.email?.split('@')[0] ?? 'User';
            userEmail = currentUser.email;
            userAvatar = currentUser.profilePic;
            userRole = currentUser.role?.name;
            isAuthenticated = true;
            debugPrint(
              '✅ Desktop AppBar: User authenticated (AllUsersLoaded) - ${currentUser.email}',
            );
          } else {
            userName = 'Guest';
            isAuthenticated = false;
            debugPrint(
              '⚠️ Desktop AppBar: AllUsersLoaded but no authenticated user',
            );
          }
        } else if (state is GeneralUserLoaded) {
          currentUser = state.user;
          userName =
              state.user.name ?? state.user.email?.split('@')[0] ?? 'User';
          userEmail = state.user.email;
          userAvatar = state.user.profilePic;
          userRole = state.user.role?.name;
          isAuthenticated = true;
          debugPrint('✅ Desktop AppBar: User loaded - ${state.user.email}');
        } else if (state is UserByIdLoaded) {
          currentUser = state.user;
          userName =
              state.user.name ?? state.user.email?.split('@')[0] ?? 'User';
          userEmail = state.user.email;
          userAvatar = state.user.profilePic;
          userRole = state.user.role?.name;
          isAuthenticated = true;
          debugPrint(
            '✅ Desktop AppBar: User by ID loaded - ${state.user.email}',
          );
        } else if (state is GeneralUserLoading) {
          isLoading = true;
          userName = 'Loading...';
          debugPrint('⏳ Desktop AppBar: User loading...');
        } else if (state is GeneralUserError) {
          hasError = true;
          errorMessage = state.message;
          userName = 'Error';
          debugPrint('❌ Desktop AppBar: User error - ${state.message}');
        } else if (state is UserUnauthenticated ||
            state is GeneralUserInitial) {
          userName = 'Guest';
          isAuthenticated = false;
          debugPrint('🚫 Desktop AppBar: User not authenticated');
        }

        return Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              // App Logo
              InkWell(
                onTap: () => context.go('/main-screen'),
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Image.asset(
                    'assets/images/company-logo.png',
                    height: 40,
                    // If you don't have a logo yet, use a placeholder
                    errorBuilder:
                        (context, error, stackTrace) => const Text(
                          'X-Pro Delivery',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                  ),
                ),
              ),

              // Search Bar
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search...',
                      prefixIcon: const Icon(Icons.search),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      isDense: true,
                    ),
                  ),
                ),
              ),

              // Theme Toggle with Choices
              _buildThemeSelector(context),
              // Notifications
              BlocConsumer<NotificationBloc, NotificationState>(
                listener: (context, state) {
                  debugPrint(
                    '🔔 NotificationBloc state => ${state.runtimeType}',
                  );

                  if (state is NotificationLoaded) {
                    debugPrint('✅ NotificationLoaded');
                    debugPrint('   🔴 unreadCount: ${state.unreadCount}');
                    debugPrint(
                      '   📦 notifications: ${state.notifications.length}',
                    );

                    if (state.notifications.isNotEmpty) {
                      final first = state.notifications.first;
                      debugPrint('   🧪 first notif id: ${first.id}');
                      debugPrint(
                        '   🧪 first notif createdAt: ${first.createdAt}',
                      );
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
                  // ✅ Auto-load once (and debug it)
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
                      IconButton(
  tooltip: 'Notifications',
  icon: Icon(
    Icons.notifications_outlined,
    color: unreadCount > 0
        ? Colors.red
        : Theme.of(context).colorScheme.surface,
  ),
  onPressed: () {
    onNotificationTap(); // ✅ now included
    _showNotificationMenu(
      context: context,
      anchorContext: context, // ✅ important (see below)
      state: state,
      notifications: notifications,
      onNotificationTap: onNotificationTap,
    );
  },
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

              // Enhanced User Profile Section
              _buildUserProfileSection(
                context: context,
                userName: userName,
                userEmail: userEmail,
                userAvatar: userAvatar,
                userRole: userRole,
                isAuthenticated: isAuthenticated,
                isLoading: isLoading,
                hasError: hasError,
                errorMessage: errorMessage,
                onProfileTap: onProfileTap,
              ),
            ],
          ),
        );
      },
    );
  }

  // Enhanced User Profile Section Widget
  Widget _buildUserProfileSection({
    required BuildContext context,
    required String userName,
    required String? userEmail,
    required String? userAvatar,
    required String? userRole,
    required bool isAuthenticated,
    required bool isLoading,
    required bool hasError,
    required String? errorMessage,
    required VoidCallback onProfileTap,
  }) {
    return InkWell(
      onTap: isAuthenticated ? onProfileTap : null,
      borderRadius: BorderRadius.circular(30),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Profile Avatar with Status Indicator
            Stack(
              children: [
                _buildProfileAvatar(userName, userAvatar),
                // Authentication Status Indicator
                if (isAuthenticated)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  )
                else if (hasError)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        border: Border.all(color: Colors.white, width: 2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  )
                else if (isLoading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.surface,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            // User Information
            Flexible(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.surface,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isAuthenticated && userRole != null)
                    Text(
                      userRole,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.8),
                      ),
                      overflow: TextOverflow.ellipsis,
                    )
                  else if (hasError)
                    Text(
                      'Auth Error',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red.shade200,
                      ),
                    )
                  else if (!isAuthenticated && !isLoading)
                    Text(
                      'Not Signed In',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
            // Enhanced Popup Menu
            _buildUserMenu(
              context: context,
              isAuthenticated: isAuthenticated,
              hasError: hasError,
              errorMessage: errorMessage,
              userEmail: userEmail,
              userRole: userRole,
              onProfileTap: onProfileTap,
            ),
          ],
        ),
      ),
    );
  }

  // Theme selector widget with choices
  Widget _buildThemeSelector(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        // Get current theme mode
        final currentTheme = themeProvider.themeMode;

        // Determine the appropriate icon based on current theme
        IconData themeIcon;
        String themeTooltip;

        switch (currentTheme) {
          case ThemeMode.light:
            themeIcon = Icons.light_mode;
            themeTooltip = 'Light Mode';
            break;
          case ThemeMode.dark:
            themeIcon = Icons.dark_mode;
            themeTooltip = 'Dark Mode';
            break;
          case ThemeMode.system:
            themeIcon = Icons.brightness_auto;
            themeTooltip = 'System Mode';
            break;
        }

        return PopupMenuButton<ThemeMode>(
          icon: Icon(themeIcon, color: Theme.of(context).colorScheme.surface),
          tooltip: themeTooltip,
          offset: const Offset(0, 40),
          onSelected: (ThemeMode selectedTheme) {
            themeProvider.setThemeMode(selectedTheme);
          },
          itemBuilder:
              (context) => [
                const PopupMenuItem<ThemeMode>(
                  enabled: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      'Theme Selection',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                PopupMenuItem<ThemeMode>(
                  value: ThemeMode.light,
                  child: Row(
                    children: [
                      Icon(
                        Icons.light_mode,
                        size: 18,
                        color:
                            currentTheme == ThemeMode.light
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Light Mode',
                        style: TextStyle(
                          fontWeight:
                              currentTheme == ThemeMode.light
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          color:
                              currentTheme == ThemeMode.light
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                      ),
                      if (currentTheme == ThemeMode.light) ...[
                        const Spacer(),
                        Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem<ThemeMode>(
                  value: ThemeMode.dark,
                  child: Row(
                    children: [
                      Icon(
                        Icons.dark_mode,
                        size: 18,
                        color:
                            currentTheme == ThemeMode.dark
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontWeight:
                              currentTheme == ThemeMode.dark
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          color:
                              currentTheme == ThemeMode.dark
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                      ),
                      if (currentTheme == ThemeMode.dark) ...[
                        const Spacer(),
                        Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuItem<ThemeMode>(
                  value: ThemeMode.system,
                  child: Row(
                    children: [
                      Icon(
                        Icons.brightness_auto,
                        size: 18,
                        color:
                            currentTheme == ThemeMode.system
                                ? Theme.of(context).colorScheme.primary
                                : null,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'System Mode',
                        style: TextStyle(
                          fontWeight:
                              currentTheme == ThemeMode.system
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                          color:
                              currentTheme == ThemeMode.system
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                        ),
                      ),
                      if (currentTheme == ThemeMode.system) ...[
                        const Spacer(),
                        Icon(
                          Icons.check,
                          size: 18,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
        );
      },
    );
  }

  // Add this method to the class:
  Widget _buildProfileAvatar(String userName, String? avatarUrl) {
    return Builder(
      builder: (context) {
        if (avatarUrl == null || avatarUrl.isEmpty) {
          // No avatar URL, show initials
          return CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        // Try to validate the URL
        bool isValidUrl = false;
        try {
          final uri = Uri.parse(avatarUrl);
          isValidUrl =
              uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
        } catch (e) {
          debugPrint('Invalid avatar URL: $e');
        }

        if (!isValidUrl) {
          // Invalid URL, show initials
          return CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blue.shade100,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
              style: TextStyle(
                color: Colors.blue.shade800,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        // Valid URL, try to load image with error handling
        return ClipOval(
          child: Image.network(
            avatarUrl,
            width: 32,
            height: 32,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              debugPrint('Error loading avatar: $error');
              // On error, show initials
              return CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: Colors.blue.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return child;
              }
              // Show a loading indicator while the image is loading
              return CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey[200],
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    value:
                        loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // Enhanced User Menu Widget
  Widget _buildUserMenu({
    required BuildContext context,
    required bool isAuthenticated,
    required bool hasError,
    required String? errorMessage,
    required String? userEmail,
    required String? userRole,
    required VoidCallback onProfileTap,
  }) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.keyboard_arrow_down,
        color: Theme.of(context).colorScheme.surface,
        size: 16,
      ),
      offset: const Offset(0, 40),
      onSelected: (String value) {
        switch (value) {
          case 'profile':
            onProfileTap();
            break;
          case 'settings':
            context.go('/settings');
            break;
          case 'logout':
            _handleLogout(context);
            break;
          case 'retry_auth':
            _retryAuthentication(context);
            break;
        }
      },
      itemBuilder: (context) {
        List<PopupMenuEntry<String>> items = [];

        // Header
        items.add(
          PopupMenuItem<String>(
            enabled: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (userEmail != null)
                    Text(
                      userEmail,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  if (userRole != null)
                    Text(
                      userRole,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );

        items.add(const PopupMenuDivider());

        if (isAuthenticated) {
          // Authenticated user options
          items.addAll([
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(Icons.person_outline, size: 18),
                  const SizedBox(width: 12),
                  Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings_outlined, size: 18),
                  const SizedBox(width: 12),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: Colors.red),
                  const SizedBox(width: 12),
                  Text('Logout', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ]);
        } else if (hasError) {
          // Error state options
          items.addAll([
            PopupMenuItem<String>(
              enabled: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  errorMessage ?? 'Authentication Error',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'retry_auth',
              child: Row(
                children: [
                  Icon(Icons.refresh, size: 18, color: Colors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Retry Authentication',
                    style: TextStyle(color: Colors.blue),
                  ),
                ],
              ),
            ),
          ]);
        } else {
          // Guest user options
          items.add(
            PopupMenuItem<String>(
              enabled: false,
              child: Text(
                'Please sign in to access your account',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          );
        }

        return items;
      },
    );
  }

  // Handle logout
  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<GeneralUserBloc>().add(const UserSignOutEvent());
                  context.go('/');
                },
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
Future<void> _showNotificationMenu({
  required BuildContext context,
  required BuildContext anchorContext, // ✅ use icon context for position
  required NotificationState state,
  required List<NotificationEntity> notifications,
  required VoidCallback onNotificationTap,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
  final box = anchorContext.findRenderObject() as RenderBox;

  final position = box.localToGlobal(Offset.zero, ancestor: overlay);

  final relativeRect = RelativeRect.fromLTRB(
    position.dx,
    position.dy + box.size.height,
    overlay.size.width - position.dx - box.size.width,
    overlay.size.height - position.dy,
  );

  List<PopupMenuEntry<int>> items;

  if (state is NotificationLoading) {
    items = const [
      PopupMenuItem<int>(
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
                      "The $tripName set status of $statusText "
                      "in the ${notif.delivery?.customer?.name ?? 'delivery'}";

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context); // close menu

                      final id = notif.id;
                      if (id != null && id.isNotEmpty) {
                        context
                            .read<NotificationBloc>()
                            .add(MarkAsReadEvent(id));
                      }

                      // ✅ navigate
                      context.go('/delivery-monitoring');

                      // ✅ callback exists again
                      onNotificationTap();
                    },
                    child: Column(
                      children: [
                        ListTile(
                          dense: true,
                          leading: Icon(
                            (notif.isRead ?? false)
                                ? Icons.notifications_none
                                : Icons.notifications_active,
                            color:
                                (notif.isRead ?? false) ? Colors.grey : Colors.red,
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

  // Retry authentication
  void _retryAuthentication(BuildContext context) {
    // Trigger a refresh by getting all users again
    context.read<GeneralUserBloc>().add(const GetAllUsersEvent());
  }

  @override
  Size get preferredSize => const Size.fromHeight(60);
}
