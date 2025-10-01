import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/widgets/ifields.dart';

class SignInForm extends StatefulWidget {
  const SignInForm(
      {super.key,
      required this.emailController,
      required this.passwordController,
      required this.formKey});

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
        child: Column(children: [
          IField(
            controller: widget.emailController,
            hintText: 'Email Address',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(
            height: 10,
          ),
          IField(
            controller: widget.passwordController,
            hintText: 'Password',
            suffixIcon: IconButton(
              onPressed: () {
                obscurePassword = !obscurePassword;
                setState(() {});
              },
              icon: Icon(
                  obscurePassword ? Icons.visibility : Icons.visibility_off),
            ),
            obscureText: obscurePassword,
          ),
        ]));
  }
}
