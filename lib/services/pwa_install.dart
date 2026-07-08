import 'package:shared_preferences/shared_preferences.dart';

import 'pwa_install_stub.dart'
    if (dart.library.js_interop) 'pwa_install_web.dart' as impl;

/// PWA install helper. On the web it drives the browser's install prompt
/// (Chrome/Edge/Android); everywhere else it's a no-op.
class PwaInstall {
  PwaInstall._();

  static const _autoPromptDismissedKey = 'pwa_install_prompt_dismissed';

  /// The browser can show a native install prompt right now.
  static bool get canInstall => impl.canInstall();

  /// The app is already running as an installed PWA.
  static bool get isInstalled => impl.isInstalled();

  /// Shows the native install prompt; returns true if the user accepted.
  static Future<bool> promptInstall() => impl.promptInstall();

  /// Whether the one-time auto banner should still be offered (installable,
  /// not installed, and not previously dismissed).
  static Future<bool> shouldOfferAutoPrompt() async {
    if (!canInstall || isInstalled) return false;
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_autoPromptDismissedKey) ?? false);
  }

  /// Remember that the user has seen (and dismissed) the one-time banner, so it
  /// is never shown automatically again.
  static Future<void> markAutoPromptDismissed() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoPromptDismissedKey, true);
  }
}
