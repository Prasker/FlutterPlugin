
import 'dart:async';

import 'package:flutter/services.dart';

class FlutterPlugin {
  static const MethodChannel _channel =
      const MethodChannel('flutter_plugin');

  static Future<int> get platformTextureID async {
    final int textureId = await _channel.invokeMethod('getTextureId');
    return textureId;
  }

  static void platformStop() {
    _channel.invokeListMethod("stop");
  }

}
