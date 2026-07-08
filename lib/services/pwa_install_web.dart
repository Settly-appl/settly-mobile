import 'dart:js_interop';

// Global helpers defined in web/index.html.
@JS('settlyCanInstall')
external bool _settlyCanInstall();

@JS('settlyIsInstalled')
external bool _settlyIsInstalled();

@JS('settlyPromptInstall')
external JSPromise<JSString> _settlyPromptInstall();

/// True when the browser captured a Chromium install prompt and the app isn't
/// already installed (Chrome/Edge/Android). Always false on iOS Safari.
bool canInstall() {
  try {
    return _settlyCanInstall();
  } catch (_) {
    return false;
  }
}

bool isInstalled() {
  try {
    return _settlyIsInstalled();
  } catch (_) {
    return false;
  }
}

/// Triggers the native install prompt. Returns true if the user accepted.
Future<bool> promptInstall() async {
  try {
    final outcome = (await _settlyPromptInstall().toDart).toDart;
    return outcome == 'accepted';
  } catch (_) {
    return false;
  }
}
