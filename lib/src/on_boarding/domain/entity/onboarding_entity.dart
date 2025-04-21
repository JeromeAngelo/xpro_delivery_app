import 'package:equatable/equatable.dart';

class SplashEntity extends Equatable {
  final String appName;
  final String logoPath;
  final int splashDuration;

  const SplashEntity({
    required this.appName,
    required this.logoPath,
    required this.splashDuration,
  });

  @override
  List<Object?> get props => [appName, logoPath, splashDuration];
}
