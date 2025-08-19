import 'package:equatable/equatable.dart';

import '../../../../../../enums/log_level.dart';



class LogEntryEntity extends Equatable {
  const LogEntryEntity({
    this.id,
    this.message,
    this.level,
    this.category,
    this.timestamp,
    this.details,
    this.userId,
    this.tripId,
    this.deliveryId,
    this.stackTrace,
  });

  final String? id;
  final String? message;
  final LogLevel? level;
  final LogCategory? category;
  final DateTime? timestamp;
  final String? details;
  final String? userId;
  final String? tripId;
  final String? deliveryId;
  final String? stackTrace;

  @override
  List<Object?> get props => [
        id,
        message,
        level,
        category,
        timestamp,
        details,
        userId,
        tripId,
        deliveryId,
        stackTrace,
      ];
}
