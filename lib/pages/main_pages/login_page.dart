import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:settly_mobile/const/app_texts.dart';
import 'package:settly_mobile/services/auth_service.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  bool _isBusy = false;
  String? _errorMessage;

  Future<void> _startLogin() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      final authUrl = _authService.buildAuthUrl();

      // Opens a Chrome Custom Tab (Android) / ASWebAuthenticationSession (iOS).
      // Google requires a real browser — embedded WebViews are rejected.
      final resultUrl = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: 'settly',
      );

      final uri = Uri.parse(resultUrl);
      final code = uri.queryParameters['code'];

      if (code == null) {
        if (!mounted) return;
        setState(() {
          _isBusy = false;
          _errorMessage =
              uri.queryParameters['error_description'] ??
              'Brak kodu autoryzacji w odpowiedzi.';
        });
        return;
      }

      final (success, error) = await _authService.exchangeCode(code);

      if (!mounted) return;

      if (success) {
        widget.onLoginSuccess();
      } else {
        setState(() {
          _isBusy = false;
          _errorMessage = error;
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      // User closed the Custom Tab / ASWebAuthenticationSession — not an error.
      final isCancel = e.code == 'CANCELED' || e.code == 'CANCELLED';
      setState(() {
        _isBusy = false;
        _errorMessage = isCancel ? null : (e.message ?? e.code);
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isBusy = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final texts = AppTexts.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Text(
                'Settly',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                texts.loginSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
              const Spacer(),
              if (_errorMessage != null) ...[
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
                const SizedBox(height: 16),
              ],
              FilledButton(
                onPressed: _isBusy ? null : _startLogin,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isBusy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        texts.loginButton,
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
