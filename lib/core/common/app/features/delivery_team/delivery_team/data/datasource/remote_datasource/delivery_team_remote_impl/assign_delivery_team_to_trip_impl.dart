import 'package:x_pro_delivery_app/core/common/app/features/delivery_team/delivery_team/data/datasource/remote_datasource/delivery_team_remote_impl/delivery_team_remote_base.dart';
import '../../../models/delivery_team_model.dart';

mixin AssignDeliveryTeamToTripImpl on DeliveryTeamRemoteBase {
  Future<DeliveryTeamModel> assignDeliveryTeamToTrip({
    required String tripId,
    required String deliveryTeamId,
  }) {
    // TODO: implement assignDeliveryTeamToTrip
    throw UnimplementedError();
  }
}
