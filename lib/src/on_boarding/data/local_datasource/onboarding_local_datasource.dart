import 'package:shared_preferences/shared_preferences.dart';
import 'package:x_pro_delivery_app/core/errors/exceptions.dart';

abstract class OnboardingLocalDatasource {
  Future<void> cacheFirstTimer();
  Future<bool> checkIfUserIsFirstTimer();
}

const kFirstTimerKey = 'firstTimeUser';

class OnboardingLocalDatasourceImpl implements OnboardingLocalDatasource {
  final SharedPreferences _prefs;

  OnboardingLocalDatasourceImpl(this._prefs);
  
  @override
  Future<void> cacheFirstTimer() async {
     try {
      await _prefs.setBool(kFirstTimerKey, false);
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
  
  @override
  Future<bool> checkIfUserIsFirstTimer() async {
    try {
      return _prefs.getBool(kFirstTimerKey) ?? true;
    } catch (e) {
      throw CacheException(message: e.toString());
    }
  }
}
