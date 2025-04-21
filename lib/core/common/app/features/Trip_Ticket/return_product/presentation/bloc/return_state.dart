import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/return_product/domain/entity/return_entity.dart';
abstract class ReturnState extends Equatable {
  const ReturnState();
}

class ReturnInitial extends ReturnState {
  const ReturnInitial();
  
  @override
  List<Object?> get props => [];
}

class ReturnLoading extends ReturnState {
  const ReturnLoading();
  
  @override
  List<Object?> get props => [];
}

class ReturnLoaded extends ReturnState {
  final List<ReturnEntity> returns;
  const ReturnLoaded(this.returns);
  
  @override
  List<Object?> get props => [returns];
}

class ReturnByCustomerLoaded extends ReturnState {
  final ReturnEntity returnItem;
  const ReturnByCustomerLoaded(this.returnItem);
  
  @override
  List<Object?> get props => [returnItem];
}

class ReturnError extends ReturnState {
  final String message;
  const ReturnError(this.message);
  
  @override
  List<Object?> get props => [message];
}

