import 'package:equatable/equatable.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/entity/customer_data_entity.dart';
import 'package:x_pro_delivery_app/core/common/app/features/Trip_Ticket/customer_data/domain/repo/customer_data_repo.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';


class UpdateCustomerData extends UsecaseWithParams<CustomerDataEntity, UpdateCustomerDataParams> {
  final CustomerDataRepo _repo;

  const UpdateCustomerData(this._repo);

  @override
  ResultFuture<CustomerDataEntity> call(UpdateCustomerDataParams params) async {
    return _repo.updateCustomerData(
      id: params.id,
      name: params.name,
      refId: params.refId,
      province: params.province,
      municipality: params.municipality,
      barangay: params.barangay,
      longitude: params.longitude,
      latitude: params.latitude,
    );
  }
}

class UpdateCustomerDataParams extends Equatable {
  final String id;
  final String? name;
  final String? refId;
  final String? province;
  final String? municipality;
  final String? barangay;
  final double? longitude;
  final double? latitude;

  const UpdateCustomerDataParams({
    required this.id,
    this.name,
    this.refId,
    this.province,
    this.municipality,
    this.barangay,
    this.longitude,
    this.latitude,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        refId,
        province,
        municipality,
        barangay,
        longitude,
        latitude,
      ];
}
