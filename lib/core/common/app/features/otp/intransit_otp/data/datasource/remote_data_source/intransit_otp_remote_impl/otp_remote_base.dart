import 'package:pocketbase/pocketbase.dart';

abstract class OtpRemoteBase {
  final PocketBase pocketBaseClient;

  const OtpRemoteBase({required this.pocketBaseClient});
}
