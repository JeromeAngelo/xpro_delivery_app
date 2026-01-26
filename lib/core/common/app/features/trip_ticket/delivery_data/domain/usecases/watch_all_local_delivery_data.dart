import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import '../repo/delivery_data_repo.dart';
import '../entity/delivery_data_entity.dart';

class WatchAllLocalDeliveryData
    implements StreamUsecaseWithoutParams<List<DeliveryDataEntity>> {
  const WatchAllLocalDeliveryData(this._repo);

  final DeliveryDataRepo _repo;

  @override
  ResultStream<List<DeliveryDataEntity>> call() {
    return _repo.watchAllLocalDeliveryData();
  }
}
