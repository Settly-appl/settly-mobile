class ProjectApiConst {
  /// Base host for the backend + Keycloak. Overridable at build time:
  ///   flutter build web --dart-define=SETTLY_HOST=https://settly.duckdns.org
  /// Defaults to localhost for local dev (and the mobile builds keep using it
  /// unless a define is passed).
  static const String host = String.fromEnvironment(
    'SETTLY_HOST',
    defaultValue: 'http://localhost',
  );
  static const String baseUrl = '$host/api';
  static const String keycloakBase = '$host/auth/realms/settly';
}
