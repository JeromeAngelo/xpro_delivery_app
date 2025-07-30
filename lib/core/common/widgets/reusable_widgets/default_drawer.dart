import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/provider/theme_provider.dart';

class DefaultDrawer extends StatefulWidget {
  const DefaultDrawer({super.key});

  @override
  State<DefaultDrawer> createState() => _DefaultDrawerState();
}

class _DefaultDrawerState extends State<DefaultDrawer> {
  bool _isThemeExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 10,
      child: Column(
        children: [
          _buildDrawerHeader(context),
          _buildDrawerBody(context),
          const Spacer(),
          _buildLogoutButton(context),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context) {
    return DrawerHeader(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/company-logo.png', height: 80, width: 80),
          const SizedBox(height: 10),
          Text(
            'X-Pro Delivery Admin',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerBody(BuildContext context) {
    return Column(
      children: [
        // Main Dashboard
        ListTile(
          leading: const Icon(Icons.dashboard),
          title: const Text('Main Dashboard'),
          onTap: () {
            context.go('/main-screen');
          },
        ),
        const Divider(),

        // Reports
        ListTile(
          leading: const Icon(Icons.bar_chart),
          title: const Text('Reports'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/reports');
          },
        ),

        // Settings
        ListTile(
          leading: const Icon(Icons.settings),
          title: const Text('Settings'),
          onTap: () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/settings');
          },
        ),

        // Theme Settings - Collapsible
        ExpansionTile(
          leading: const Icon(Icons.color_lens),
          title: const Text('Theme'),
          initiallyExpanded: _isThemeExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _isThemeExpanded = expanded;
            });
          },
          children: [_buildThemeOptions(context)],
        ),
      ],
    );
  }

  Widget _buildThemeOptions(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Column(
      children: [
        RadioListTile<ThemeMode>(
          title: Row(
            children: [
              Icon(
                Icons.light_mode,
                size: 20,
                color:
                    themeProvider.themeMode == ThemeMode.light
                        ? Theme.of(context).colorScheme.primary
                        : null,
              ),
              const SizedBox(width: 12),
              const Text('Light'),
            ],
          ),
          value: ThemeMode.light,
          groupValue: themeProvider.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
          activeColor: Theme.of(context).colorScheme.primary,
          dense: true,
        ),
        RadioListTile<ThemeMode>(
          title: Row(
            children: [
              Icon(
                Icons.brightness_auto,
                size: 20,
                color:
                    themeProvider.themeMode == ThemeMode.system
                        ? Theme.of(context).colorScheme.primary
                        : null,
              ),
              const SizedBox(width: 12),
              const Text('System'),
            ],
          ),
          value: ThemeMode.system,
          groupValue: themeProvider.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
          activeColor: Theme.of(context).colorScheme.primary,
          dense: true,
        ),

        RadioListTile<ThemeMode>(
          title: Row(
            children: [
              Icon(
                Icons.dark_mode,
                size: 20,
                color:
                    themeProvider.themeMode == ThemeMode.dark
                        ? Theme.of(context).colorScheme.primary
                        : null,
              ),
              const SizedBox(width: 12),
              const Text('Dark'),
            ],
          ),
          value: ThemeMode.dark,
          groupValue: themeProvider.themeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeProvider.setThemeMode(value);
            }
          },
          activeColor: Theme.of(context).colorScheme.primary,
          dense: true,
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BlocBuilder<GeneralUserBloc, GeneralUserState>(
        builder: (context, state) {
          return ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Confirm Logout'),
                      content: const Text('Are you sure you want to logout?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context); // Close dialog
                            context.read<GeneralUserBloc>().add(
                              const UserSignOutEvent(),
                            );
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    ),
              );
            },
          );
        },
      ),
    );
  }
}
