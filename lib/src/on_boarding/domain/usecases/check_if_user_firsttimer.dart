import 'package:x_pro_delivery_app/core/usecases/usecase.dart';
import 'package:x_pro_delivery_app/core/utils/typedefs.dart';
import 'package:x_pro_delivery_app/src/on_boarding/domain/repo/onboarding_repo.dart';

class CheckIfUserIsFirstimer extends UsecaseWithoutParams<bool> {
  const CheckIfUserIsFirstimer(this._repo);

  final OnboardingRepo _repo;

  @override
  ResultFuture<bool> call() async => _repo.checkIfUserIsFirstTimer();
}
