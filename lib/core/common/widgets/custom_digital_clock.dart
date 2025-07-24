import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomDigitalClock extends StatefulWidget {
  final Curve digitAnimationStyle;
  final bool showSecondsDigit;
  final AlignmentDirectional areaAligment;
  final double areaWidth;
  final double areaHeight;
  final bool is24HourTimeFormat;
  final TextStyle hourMinuteDigitTextStyle;
  final TextStyle secondDigitTextStyle;
  final TextStyle amPmDigitTextStyle;
  final Widget colon;

  const CustomDigitalClock({
    super.key,
    this.digitAnimationStyle = Curves.easeInOut,
    this.showSecondsDigit = true,
    this.areaAligment = AlignmentDirectional.center,
    this.areaWidth = double.infinity,
    this.areaHeight = 100,
    this.is24HourTimeFormat = false,
    required this.hourMinuteDigitTextStyle,
    required this.secondDigitTextStyle,
    required this.amPmDigitTextStyle,
    required this.colon,
  });

  @override
  State<CustomDigitalClock> createState() => _CustomDigitalClockState();
}

class _CustomDigitalClockState extends State<CustomDigitalClock>
    with TickerProviderStateMixin {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: widget.digitAnimationStyle,
    );

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentTime = DateTime.now();
      });
      _animationController.forward(from: 0);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.areaWidth,
      height: widget.areaHeight,
      alignment: widget.areaAligment,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTimeDisplay(),
              if (!widget.is24HourTimeFormat) ...[
                const SizedBox(width: 8),
                _buildAmPmDisplay(),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimeDisplay() {
    final format = widget.is24HourTimeFormat
        ? (widget.showSecondsDigit ? 'HH:mm:ss' : 'HH:mm')
        : (widget.showSecondsDigit ? 'hh:mm:ss' : 'hh:mm');
    
    final timeString = DateFormat(format).format(_currentTime);
    final parts = timeString.split(':');
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(parts[0], style: widget.hourMinuteDigitTextStyle),
        widget.colon,
        Text(parts[1], style: widget.hourMinuteDigitTextStyle),
        if (widget.showSecondsDigit && parts.length > 2) ...[
          widget.colon,
          Text(parts[2], style: widget.secondDigitTextStyle),
        ],
      ],
    );
  }

  Widget _buildAmPmDisplay() {
    if (widget.is24HourTimeFormat) return const SizedBox.shrink();
    
    final amPm = DateFormat('a').format(_currentTime);
    return Text(amPm, style: widget.amPmDigitTextStyle);
  }
}
