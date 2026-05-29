import 'package:pocketbase/pocketbase.dart';

abstract class EndTripChecklistRemoteBase {
  final PocketBase pocketBaseClient;

  const EndTripChecklistRemoteBase({required this.pocketBaseClient});
}
