import 'dart:math';

class IdGenerator {
  /// Generates a short numeric ID with fixed length
  /// Example output: 483920
  static String generateShortNumericId({int length = 6}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    final max = pow(10, length).toInt();
    final short = (timestamp % max).toString().padLeft(length, '0');

    return short;
  }
}