import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SignInLogo extends StatelessWidget {
  final double size;

  const SignInLogo({super.key, this.size = 150});

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/images/smartphone-sms.svg',
      width: size,
      height: size,
    );
  }
}
