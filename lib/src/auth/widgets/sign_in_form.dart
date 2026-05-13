import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/widgets/ifields.dart';

class SignInForm extends StatefulWidget {
  const SignInForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.formKey,
  });

  final TextEditingController emailController;
  final TextEditingController passwordController;
  final GlobalKey<FormState> formKey;

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  bool obscurePassword = true;
  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email Address',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          IField(
            controller: widget.emailController,
            hintText: 'Enter your email',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            'Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          IField(
            controller: widget.passwordController,
            hintText: 'Enter your password',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            suffixIcon: IconButton(
              onPressed: () {
                obscurePassword = !obscurePassword;
                setState(() {});
              },
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
              ),
            ),
            obscureText: obscurePassword,
          ),
        ],
      ),
    );
  }
}
