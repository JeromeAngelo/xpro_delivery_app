import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/user_provider.dart';
import 'package:x_pro_delivery_app/core/utils/core_utils.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/models/auth_models.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_bloc.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_event.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/bloc/auth_state.dart';
import 'package:x_pro_delivery_app/src/auth/widgets/sign_in_form.dart';
import 'package:x_pro_delivery_app/src/auth/widgets/sign_in_logo.dart';

class AuthScreenView extends StatefulWidget {
  const AuthScreenView({super.key});

  static const routeName = '/sign-in';

  @override
  State<AuthScreenView> createState() => _AuthScreenViewState();
}

class _AuthScreenViewState extends State<AuthScreenView> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  void _markUserAsNotFirstTimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isFirstTimer', false);
    debugPrint(
      '✅ Marked user as no longer first timer after successful authentication',
    );
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (_, state) {
          if (state is AuthError) {
            CoreUtils.showSnackBar(context, state.message);
            debugPrint("State: $state");
          } else if (state is SignedIn) {
            debugPrint("State: $state");
            debugPrint("State.users: ${state.users}");
            debugPrint("State.users runtimeType: ${state.users.runtimeType}");

            context.read<UserProvider>().initUser(
              state.users as LocalUsersModel,
            );

            // Mark user as no longer first timer after successful authentication
            _markUserAsNotFirstTimer();

            context.go('/loading');
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    const SignInLogo(size: 64),

                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'Transport Management System',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: const Color(0xFF1565C0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Subtitle
                    Text(
                      'Reliability in Every Mile',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Welcome Back
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // Subtitle
                          Text(
                            'Please enter your credentials to access the dashboard',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.5),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Form
                          SignInForm(
                            emailController: emailController,
                            passwordController: passwordController,
                            formKey: formKey,
                          ),

                          const SizedBox(height: 12),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Color(0xFF1565C0),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Login Button
                          if (state is AuthLoading)
                            const Center(child: CircularProgressIndicator())
                          else
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  if (formKey.currentState!.validate()) {
                                    context.read<AuthBloc>().add(
                                      SignInEvent(
                                        email: emailController.text.trim(),
                                        password:
                                            passwordController.text.trim(),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.login, size: 18),
                                label: const Text(
                                  'Login',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1565C0),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ),

                          const SizedBox(height: 24),

                          // Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: Colors.grey.shade300,
                                  thickness: 1,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Need assistance
                          Center(
                            child: Text(
                              'Need assistance with your account?',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black.withOpacity(0.5),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Contact Support Button
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF1565C0),
                                side: const BorderSide(
                                  color: Color(0xFF1565C0),
                                  width: 1.5,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              child: Text(
                                'Contact Support',
                                style: TextStyle(color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // URL
                    Text(
                      'https://delivery-app.winganmarketing.com',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
