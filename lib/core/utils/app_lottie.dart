import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class AppLottie extends StatefulWidget {
  final String path;
  final bool isNetwork;
  final bool repeat;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final double speed;

  const AppLottie({
    super.key,
    required this.path,
    this.isNetwork = false,
    this.repeat = true,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.speed = 1.0,
  });

  @override
  State<AppLottie> createState() => _AppLottieState();
}

class _AppLottieState extends State<AppLottie>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lottie = widget.isNetwork
        ? Lottie.network(
            widget.path,
            controller: _controller,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
            onLoaded: (composition) {
              _controller.duration = composition.duration;

              if (widget.repeat) {
                _controller.repeat(
                  period: composition.duration * (1 / widget.speed),
                );
              } else {
                _controller.forward();
              }
            },
            errorBuilder: (_, __, ___) => _errorWidget(context),
          )
        : Lottie.asset(
            widget.path,
            controller: _controller,
            width: widget.width,
            height: widget.height,
            fit: widget.fit,
            alignment: widget.alignment,
            onLoaded: (composition) {
              _controller.duration = composition.duration;

              if (widget.repeat) {
                _controller.repeat(
                  period: composition.duration * (1 / widget.speed),
                );
              } else {
                _controller.forward();
              }
            },
            errorBuilder: (_, __, ___) => _errorWidget(context),
          );

    return lottie;
  }

  Widget _errorWidget(BuildContext context) {
    return Center(
      child: Icon(
        Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
        size: 40,
      ),
    );
  }
}