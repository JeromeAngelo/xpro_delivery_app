import 'package:pocketbase/pocketbase.dart';

abstract class ChecklistRemoteBase {
  final PocketBase pocketBaseClient;

  ChecklistRemoteBase({required this.pocketBaseClient});
}
