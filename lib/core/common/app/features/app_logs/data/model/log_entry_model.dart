import 'package:objectbox/objectbox.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/common/app/features/app_logs/domain/entity/log_entry_entity.dart';

@Entity()
class LogEntryModel extends LogEntryEntity {
  @Id()
  int objectBoxId = 0;

  @Property()
  String pocketbaseId;

  @Property()
  int levelIndex;

  @Property()
  int categoryIndex;

  LogEntryModel({
    required String id,
    required String message,
    required LogLevel level,
    required LogCategory category,
    required DateTime timestamp,
    String? details,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? stackTrace,
  }) : pocketbaseId = id,
       levelIndex = level.index,
       categoryIndex = category.index,
       super(
         id: id,
         message: message,
         level: level,
         category: category,
         timestamp: timestamp,
         details: details,
         userId: userId,
         tripId: tripId,
         deliveryId: deliveryId,
         stackTrace: stackTrace,
       );

  factory LogEntryModel.fromJson(DataMap json) {
    return LogEntryModel(
      id: json['id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      level: _parseLogLevel(json['level']),
      category: _parseLogCategory(json['category']),
      timestamp: DateTime.parse(json['timestamp']?.toString() ?? DateTime.now().toIso8601String()),
      details: json['details']?.toString(),
      userId: json['userId']?.toString(),
      tripId: json['tripId']?.toString(),
      deliveryId: json['deliveryId']?.toString(),
      stackTrace: json['stackTrace']?.toString(),
    );
  }

  static LogLevel _parseLogLevel(dynamic level) {
    if (level is int) {
      return LogLevel.values[level];
    } else if (level is String) {
      return LogLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == level.toLowerCase(),
        orElse: () => LogLevel.debug,
      );
    }
    return LogLevel.debug;
  }

  static LogCategory _parseLogCategory(dynamic category) {
    if (category is int) {
      return LogCategory.values[category];
    } else if (category is String) {
      return LogCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == category.toLowerCase(),
        orElse: () => LogCategory.general,
      );
    }
    return LogCategory.general;
  }

  DataMap toJson() {
    return {
      'id': pocketbaseId,
      'message': message,
      'level': level.name,
      'category': category.name,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
      'userId': userId,
      'tripId': tripId,
      'deliveryId': deliveryId,
      'stackTrace': stackTrace,
    };
  }

  LogEntryModel copyWith({
    String? id,
    String? message,
    LogLevel? level,
    LogCategory? category,
    DateTime? timestamp,
    String? details,
    String? userId,
    String? tripId,
    String? deliveryId,
    String? stackTrace,
  }) {
    return LogEntryModel(
      id: id ?? this.id,
      message: message ?? this.message,
      level: level ?? this.level,
      category: category ?? this.category,
      timestamp: timestamp ?? this.timestamp,
      details: details ?? this.details,
      userId: userId ?? this.userId,
      tripId: tripId ?? this.tripId,
      deliveryId: deliveryId ?? this.deliveryId,
      stackTrace: stackTrace ?? this.stackTrace,
    );
  }
}
