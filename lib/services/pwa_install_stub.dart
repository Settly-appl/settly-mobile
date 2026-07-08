// Non-web fallback: PWA install is a web-only concept.
bool canInstall() => false;

bool isInstalled() => false;

Future<bool> promptInstall() async => false;
