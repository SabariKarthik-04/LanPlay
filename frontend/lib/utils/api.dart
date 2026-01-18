
class ApiConfig {
  static String? _serverBase;

  static void setServerBase(String base) {
    _serverBase = base;
  }

  static String get serverBase {
    if (_serverBase == null) {
      throw Exception("Server base not initialized");
    }
    return _serverBase!;
  }

  static bool get isInitialized => _serverBase != null;
}

String buildStreamUrl(String relativePath) {
  return "${ApiConfig._serverBase}/stream/${Uri.encodeComponent(relativePath)}";
}

String buildThumbnailUrl(String path) {
  return "${ApiConfig._serverBase}$path";
}
