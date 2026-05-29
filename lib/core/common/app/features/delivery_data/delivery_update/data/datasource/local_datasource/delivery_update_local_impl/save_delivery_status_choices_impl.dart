import 'package:flutter/foundation.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/models/delivery_update_model.dart';
import 'package:x_pro_delivery_app/core/common/app/features/delivery_data/delivery_update/data/datasource/local_datasource/delivery_update_local_impl/delivery_update_local_base.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';
import 'package:x_pro_delivery_app/objectbox.g.dart';

mixin SaveDeliveryStatusChoicesImpl on DeliveryUpdateLocalBase {
  Future<void> saveDeliveryStatusChoices(
    String customerId,
    List<DeliveryUpdateModel> choices,
  ) async {
    try {
      debugPrint(
        '💾 [LOCAL] Caching ${choices.length} status choices for: $customerId',
      );

      final choicesKey = 'choices_$customerId';

      final oldQuery =
          deliveryUpdateBox
              .query(DeliveryUpdateModel_.customer.equals(choicesKey))
              .build();
      final oldCount = oldQuery.remove();
      debugPrint('🧹 Removed $oldCount old cached choices');

      for (final choice in choices) {
        choice.customer = choicesKey;
        choice.isAssigned = false;
        choice.created = DateTime.now();

        deliveryUpdateBox.put(choice);
        debugPrint('✅ Cached choice: ${choice.title}');
      }

      debugPrint('✅ Cached ${choices.length} status choices for $customerId');
    } catch (e) {
      debugPrint('❌ Failed to cache status choices: $e');
      throw CacheException(message: e.toString());
    }
  }
}
