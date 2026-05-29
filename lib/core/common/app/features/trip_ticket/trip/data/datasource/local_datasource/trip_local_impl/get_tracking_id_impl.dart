import 'package:flutter/material.dart';
import 'package:x_pro_delivery_app/core/common/app/features/trip_ticket/trip/data/datasource/local_datasource/trip_local_impl/trip_local_base.dart';

mixin GetTrackingIdImpl on TripLocalBase {
  Future<String?> getTrackingId() async {
    debugPrint('🔍 Retrieving tracking ID');
    return trackingId;
  }
}
