import 'package:flutter/material.dart';
import 'package:settly_mobile/services/auth_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class LoginPage extends StatefulWidget {
  final VoidCallback onLoginSuccess;

  const LoginPage({super.key, required this.onLoginSuccess});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  bool _showWebView = false;
  bool _isExchanging = false;
  String? _errorMessage;
  late final WebViewController _webViewController;

  void _startLogin() {
    final authUrl = _authService.buildAuthUrl();

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (request.url.startsWith('settly://callback')) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(authUrl));

    setState(() {
      _showWebView = true;
      _errorMessage = null;
    });
  }

  Future<void> _handleCallback(String url) async {
    final uri = Uri.parse(url);
    final code = uri.queryParameters['code'];

    if (code == null) {
      setState(() {
        _showWebView = false;
        _errorMessage = uri.queryParameters['error_description'] ??
            'Brak kodu autoryzacji w odpowiedzi.';
      });
      return;
    }

    setState(() {
      _isExchanging = true;
    });

    final (success, error) = await _authService.exchangeCode(code);

    if (!mounted) return;

    if (success) {
      widget.onLoginSuccess();
    } else {
      setState(() {
        _showWebView = false;
        _isExchanging = false;
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_showWebView) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _showWebView = false),
          ),
          title: const Text('Logowanie'),
        ),
        body: _isExchanging
            ? const Center(child: CircularProgressIndicator())
            : WebViewWidget(controller: _webViewController),
      );
    }

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
                'Zarządzaj wydatkami razem',
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
                onPressed: _startLogin,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Zaloguj się',
                  style: TextStyle(fontSize: 16),
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
