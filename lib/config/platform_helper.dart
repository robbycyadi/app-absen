import 'package:flutter/foundation.dart' show kIsWeb;

class PlatformHelper {
  PlatformHelper._();

  static bool get isWeb => kIsWeb;
  static bool get isMobile => !kIsWeb;
}
