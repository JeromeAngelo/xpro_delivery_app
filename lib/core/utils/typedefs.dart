import 'package:dartz/dartz.dart';
import 'package:x_pro_delivery_app/core/errors/failures.dart';

typedef ResultFuture<T> = Future<Either<Failure, T>>;

typedef DataMap = Map<String, dynamic>;

typedef ResultStream<T> = Stream<T>; // 👈 Add this line