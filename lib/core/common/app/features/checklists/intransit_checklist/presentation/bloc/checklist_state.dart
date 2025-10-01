import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/checklists/intransit_checklist/domain/entity/checklist_entity.dart';
abstract class ChecklistState extends Equatable {
  const ChecklistState();

  @override
  List<Object?> get props => [];
}

class ChecklistInitial extends ChecklistState {}

class ChecklistLoading extends ChecklistState {}

class ChecklistLoaded extends ChecklistState {
  final List<ChecklistEntity> checklist;
  final bool isFromLocal;

  const ChecklistLoaded(this.checklist, {this.isFromLocal = false});

  @override
  List<Object?> get props => [checklist, isFromLocal];
}

class ChecklistError extends ChecklistState {
  final String message;
  final bool isLocalError;

  const ChecklistError(this.message, {this.isLocalError = false});

  @override
  List<Object?> get props => [message, isLocalError];
}

class ChecklistItemChecked extends ChecklistState {
  final bool isChecked;
  final String id;

  const ChecklistItemChecked({
    required this.isChecked,
    required this.id,
  });

  @override
  List<Object?> get props => [isChecked, id];
}
