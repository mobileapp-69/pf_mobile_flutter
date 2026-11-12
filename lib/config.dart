// lib/config.dart
class Config {
  static const String backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://mobile-s11.iecmu.com',
  );
}
