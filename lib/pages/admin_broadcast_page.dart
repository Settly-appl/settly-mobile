import 'package:flutter/material.dart';
import 'package:settly_mobile/projectColors/app_colors.dart';
import 'package:settly_mobile/services/api_service/api_service_request.dart';

/// Admin-only screen to push a notification to every user.
class AdminBroadcastPage extends StatefulWidget {
  const AdminBroadcastPage({super.key});

  @override
  State<AdminBroadcastPage> createState() => _AdminBroadcastPageState();
}

class _AdminBroadcastPageState extends State<AdminBroadcastPage> {
  final _api = ApiServiceRequest();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  bool _sending = false;

  bool get isDark => Theme.of(context).brightness == Brightness.dark;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final body = _bodyController.text.trim();
    if (title.isEmpty || body.isEmpty) {
      _showSnack('Podaj tytuł i treść');
      return;
    }

    setState(() => _sending = true);
    final response = await _api.request(
      endpoint: 'notifications/broadcast',
      method: HttpMethod.post,
      body: {'title': title, 'body': body},
    );
    if (!mounted) return;
    setState(() => _sending = false);

    final ok =
        response != null &&
        response.statusCode >= 200 &&
        response.statusCode < 300;
    if (ok) {
      _showSnack('Wysłano powiadomienie');
      Navigator.of(context).pop();
    } else {
      _showSnack('Nie udało się wysłać (${response?.statusCode ?? 'brak połączenia'})');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold(isDark),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Powiadomienie do wszystkich',
          style: TextStyle(color: AppColors.username(isDark)),
        ),
        iconTheme: IconThemeData(color: AppColors.username(isDark)),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                maxLength: 100,
                decoration: const InputDecoration(
                  labelText: 'Tytuł',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bodyController,
                maxLength: 500,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Treść',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _sending ? null : _send,
                icon: _sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_sending ? 'Wysyłanie…' : 'Wyślij do wszystkich'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
