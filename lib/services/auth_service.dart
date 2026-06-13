import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:settly_mobile/const/api_url.dart';

class AuthService {
  AuthService._internal();
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  static const _clientId = 'settly';
  static const _redirectUrl = 'settly://callback';
  static const _authEndpoint =
      '${ProjectApiConst.keycloakBase}/protocol/openid-connect/auth';
  static const _tokenEndpoint =
      '${ProjectApiConst.keycloakBase}/protocol/openid-connect/token';
  static const _logoutEndpoint =
      '${ProjectApiConst.keycloakBase}/protocol/openid-connect/logout';
  static const _scopes = 'openid profile email';

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _idTokenKey = 'id_token';

  final _storage = const FlutterSecureStorage();

  String _codeVerifier = '';
  Future<bool>? _refreshInFlight;

  String buildAuthUrl() {
    _codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(_codeVerifier);

    final params = {
      'client_id': _clientId,
      'redirect_uri': _redirectUrl,
      'response_type': 'code',
      'scope': _scopes,
      'code_challenge': codeChallenge,
      'code_challenge_method': 'S256',
    };

    return Uri.parse(_authEndpoint).replace(queryParameters: params).toString();
  }

  Future<(bool, String?)> exchangeCode(String code) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'authorization_code',
          'client_id': _clientId,
          'redirect_uri': _redirectUrl,
          'code': code,
          'code_verifier': _codeVerifier,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveTokens(
          data['access_token'] as String?,
          data['refresh_token'] as String?,
          data['id_token'] as String?,
        );
        return (true, null);
      }
      return (
        false,
        'Token exchange failed: ${response.statusCode} ${response.body}',
      );
    } catch (e) {
      return (false, e.toString());
    }
  }

  Future<bool> isLoggedIn() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;
    return refreshAccessToken();
  }

  /// Refresh the access token using the stored refresh token.
  /// Concurrent callers share a single in-flight refresh so we don't
  /// hammer Keycloak when several API calls 401 at the same time.
  Future<bool> refreshAccessToken() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return false;
    return _refreshTokens(refreshToken);
  }

  Future<void> logout() async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken != null) {
      try {
        await http.post(
          Uri.parse(_logoutEndpoint),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'client_id': _clientId, 'refresh_token': refreshToken},
        );
      } catch (_) {}
    }
    await _storage.deleteAll();
  }

  Future<String?> getAccessToken() async {
    return _storage.read(key: _accessTokenKey);
  }

  Future<Map<String, dynamic>?> getUserInfo() async {
    final idToken = await _storage.read(key: _idTokenKey);
    if (idToken == null) return null;
    return _decodeJwtPayload(idToken);
  }

  /// True if the access token carries the `admin` client role for this app.
  Future<bool> isAdmin() async {
    final accessToken = await _storage.read(key: _accessTokenKey);
    if (accessToken == null) return false;
    try {
      final payload = _decodeJwtPayload(accessToken);
      final resourceAccess = payload['resource_access'] as Map<String, dynamic>?;
      final client = resourceAccess?[_clientId] as Map<String, dynamic>?;
      final roles = (client?['roles'] as List?)?.cast<String>() ?? const [];
      return roles.contains('admin');
    } catch (_) {
      return false;
    }
  }

  Future<bool> _refreshTokens(String refreshToken) async {
    try {
      final response = await http.post(
        Uri.parse(_tokenEndpoint),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'grant_type': 'refresh_token',
          'client_id': _clientId,
          'refresh_token': refreshToken,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        await _saveTokens(
          data['access_token'] as String?,
          data['refresh_token'] as String?,
          data['id_token'] as String?,
        );
        return true;
      }
      return false;
    } catch (_) {
      await logout();
      return false;
    }
  }

  Future<void> _saveTokens(
    String? accessToken,
    String? refreshToken,
    String? idToken,
  ) async {
    if (accessToken != null) {
      await _storage.write(key: _accessTokenKey, value: accessToken);
    }
    if (refreshToken != null) {
      await _storage.write(key: _refreshTokenKey, value: refreshToken);
    }
    if (idToken != null) {
      await _storage.write(key: _idTokenKey, value: idToken);
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 3) return {};
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  String _generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }
}
