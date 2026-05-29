import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

abstract class EndTripOtpRemoteBase {
  final PocketBase pocketBaseClient;

  const EndTripOtpRemoteBase({required this.pocketBaseClient});

  void debugPrintMessage(String message) => debugPrint(message);
}
