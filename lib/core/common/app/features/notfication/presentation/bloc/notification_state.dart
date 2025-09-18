import 'package:equatable/equatable.dart';
import '../../domain/entity/notification_entity.dart';

abstract class NotificationState extends Equatable {
  const NotificationState();

  @override
  List<Object?> get props => [];
}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationLoaded extends NotificationState {
  final List<NotificationEntity> notifications;
  final int unreadCount;

  const NotificationLoaded({
    required this.notifications,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, unreadCount];
}

class NotificationSuccess extends NotificationState {
  final String message;
  const NotificationSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class NotificationError extends NotificationState {
  final String message;
  final String? statusCode;
  const NotificationError({
    required this.message, 
    this.statusCode,});

  @override
  List<Object?> get props => [message];
}
