import 'package:mocktail/mocktail.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/local_datasource/auth_local_data_source.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/data/datasources/remote_data_source/auth_remote_data_src.dart';
import 'package:x_pro_delivery_app/core/common/app/features/users/auth/domain/repo/auth_repo.dart';
import 'package:x_pro_delivery_app/core/services/offline_sync_service.dart';
import 'package:x_pro_delivery_app/core/common/app/provider/check_connectivity_provider.dart';

// ============================================================================
// MOCKTAIL CUSTOM MOCKS
// ============================================================================

/// Custom mocktail mock for [AuthRemoteDataSrc]
class MockAuthRemoteDataSrc extends Mock implements AuthRemoteDataSrc {}

/// Custom mocktail mock for [AuthLocalDataSrc]
class MockAuthLocalDataSrc extends Mock implements AuthLocalDataSrc {}

/// Custom mocktail mock for [AuthRepo]
class MockAuthRepo extends Mock implements AuthRepo {}

/// Custom mocktail mock for [OfflineSyncService]
class MockOfflineSyncService extends Mock implements OfflineSyncService {}

/// Custom mocktail mock for [ConnectivityProvider]
class MockConnectivityProvider extends Mock implements ConnectivityProvider {}
