import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/data/models/auth_models.dart'; // Import the model
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_bloc.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_event.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/general_auth/presentation/bloc/auth_state.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/users_roles/data/model/user_role_model.dart';
import 'package:xpro_delivery_admin_app/core/common/app/features/users_roles/domain/entity/user_role_entity.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/app_structure/desktop_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/create_screen_widgets/form_layout.dart';
import 'package:xpro_delivery_admin_app/core/common/widgets/reusable_widgets/app_navigation_items.dart';
import 'package:xpro_delivery_admin_app/core/enums/user_status_enum.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/create_&_update_user_widgets/user_forms_button.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/create_&_update_user_widgets/user_info_fields.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/create_&_update_user_widgets/user_role_drop_down.dart';
import 'package:xpro_delivery_admin_app/src/users/presentation/widgets/create_&_update_user_widgets/user_status_drop_down.dart';

class CreateUserView extends StatefulWidget {
  const CreateUserView({super.key});

  @override
  State<CreateUserView> createState() => _CreateUserViewState();
}

class _CreateUserViewState extends State<CreateUserView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  // Selected values
  UserRoleEntity? _selectedRole;
  UserStatusEnum _selectedStatus = UserStatusEnum.active;
  bool _isLoading = false;
  String? _errorMessage;
  bool _createAnother =
      false; // Track whether to create another user after this one

  @override
  void initState() {
    super.initState();
    // Load delivery users when the screen initializes
    // Only load if not already loading or loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final currentState = context.read<GeneralUserBloc>().state;
      debugPrint(
        '📱 AllUsersView initState - Current state: ${currentState.runtimeType}',
      );

      // Trigger loading for appropriate states
      if (currentState is GeneralUserInitial ||
          currentState is GeneralUserError ||
          currentState is UserAuthenticated) {
        debugPrint(
          '🔄 Triggering GetAllUsersEvent from initState - State: ${currentState.runtimeType}',
        );
        context.read<GeneralUserBloc>().add(const GetAllUsersEvent());
      } else if (currentState is AllUsersLoaded) {
        debugPrint('✅ Users already loaded, skipping API call');
      } else if (currentState is GeneralUserLoading) {
        debugPrint('⏳ Users currently loading, skipping API call');
      } else {
        debugPrint(
          '⚠️ Unexpected state in initState: ${currentState.runtimeType}',
        );
        // Trigger loading anyway for unexpected states
        context.read<GeneralUserBloc>().add(const GetAllUsersEvent());
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Function to create a user
  void _createUser({bool createAnother = false}) {
    if (!_formKey.currentState!.validate()) {
      // Form validation failed
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate required selections
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a user role'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Create the user model directly instead of entity
    final user = GeneralUserModel(
      name: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      passwordConfirm: _passwordConfirmController.text,
      roleModel: _selectedRole as UserRoleModel,
      roleId: _selectedRole?.id, // Add this line to set the roleId
      status: _selectedStatus,
    );

    // Set loading state and track whether to create another
    setState(() {
      _errorMessage = null;
      _createAnother = createAnother; // Store the createAnother value
    });

    // Dispatch the create event
    context.read<GeneralUserBloc>().add(CreateUserEvent(user));

    // The rest of the flow is handled in the BlocListener
  }

  void _resetForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _passwordConfirmController.clear();
    setState(() {
      _selectedRole = null;
      _selectedStatus = UserStatusEnum.active;
      _isLoading = false;
      _errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define navigation items
    final navigationItems = AppNavigationItems.usersNavigationItems();

    return BlocListener<GeneralUserBloc, GeneralUserState>(
      listener: (context, state) {
        if (state is GeneralUserLoading) {
          if (mounted) {
            setState(() {
              _isLoading = true;
              _errorMessage = null;
            });
          }
        } else if (state is UserCreated) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = null;
            });

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User ${state.user.name} created successfully'),
                backgroundColor: Colors.green,
              ),
            );

            // Either reset form for another user or navigate back
            if (_createAnother) {
              _resetForm();
            } else {
              // Navigate to the users list screen
              context.go('/all-users'); // Make sure this route exists
            }
          }
        } else if (state is GeneralUserError) {
          if (mounted) {
            setState(() {
              _isLoading = false;
              _errorMessage = state.message;
            });

            // Show error message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Handle any other state by ensuring loading is false
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      },
      child: DesktopLayout(
        navigationItems: navigationItems,
        currentRoute: '/all-users',
        onNavigate: (route) {
          // Handle navigation
          context.go(route);
        },
        onThemeToggle: () {
          // Handle theme toggle
        },
        onNotificationTap: () {
          // Handle notification tap
        },
        onProfileTap: () {
          // Handle profile tap
        },
        child: FormLayout(
          title: 'Create New User',
          isLoading: _isLoading,
          actions: [
            UserFormButtons(
              onCancel: () {
                // Navigate back to users list
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/all-users');
                }
              },
              onSave: () => _createUser(createAnother: false),
              onSaveAndCreateAnother: () => _createUser(createAnother: true),
              isLoading: _isLoading,
            ),
          ],
          children: [
            // User Information Form Fields
            UserInfoFormFields(
              nameController: _nameController,
              emailController: _emailController,
              passwordController: _passwordController,
              formKey: _formKey,
              passwordConfirmController: _passwordConfirmController,
            ),

            const SizedBox(height: 24),

            // User Role Dropdown
            UserRoleDropdown(
              onRoleSelected: (role) {
                setState(() {
                  _selectedRole = role;
                });
              },
              initialValue: _selectedRole,
            ),

            const SizedBox(height: 24),

            // User Status Dropdown
            UserStatusDropdown(
              onStatusSelected: (status) {
                setState(() {
                  _selectedStatus = status;
                });
              },
              initialValue: _selectedStatus,
            ),

            // Display error message if any
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
