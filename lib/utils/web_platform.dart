import 'package:flutter/foundation.dart';

bool get isDesktopWeb =>
    kIsWeb &&
    defaultTargetPlatform != TargetPlatform.iOS &&
    defaultTargetPlatform != TargetPlatform.android;
