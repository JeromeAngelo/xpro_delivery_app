import 'package:mockito/annotations.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/auth_local_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/auth_remote_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repo/auth_repo.dart';
import 'package:x_pro_delivery_app/core/services/offline_sync_service.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';



@GenerateMocks([
  AuthRemoteDataSrc,
  AuthLocalDataSrc,
  AuthRepo,
  OfflineSyncService,
  ConnectivityProvider,
  SharedPreferences,
  PocketBase,
])
void main() {}
