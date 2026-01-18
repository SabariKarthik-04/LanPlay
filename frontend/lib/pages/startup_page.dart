import 'package:flutter/material.dart';
import 'package:frontend/utils/api.dart';
import 'package:frontend/utils/server_discover.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'package:http/http.dart' as http;

// Constants for better maintainability
class ServerConfig {
  static const String serverBaseKey = "server_base";
  static const int connectionTimeout = 5;
  static const int validationTimeout = 2;
}

// Service class for server operations
class ServerService {
  static Future<void> saveServerBase(String base) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(ServerConfig.serverBaseKey, base);
    ApiConfig.setServerBase(base);
  }

  static Future<String?> loadSavedServer() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(ServerConfig.serverBaseKey);
    
    if (saved != null) {
      ApiConfig.setServerBase(saved);
    }
    return saved;
  }

  static Future<void> clearServer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(ServerConfig.serverBaseKey);
  }

  static Future<bool> validateServer(String base) async {
    try {
      final res = await http
          .get(Uri.parse("$base/ping"))
          .timeout(Duration(seconds: ServerConfig.validationTimeout));
      return res.statusCode == 200;
    } catch (e) {
      debugPrint("Server validation failed: $e");
      return false;
    }
  }
}

class StartupPage extends StatefulWidget {
  const StartupPage({super.key});

  @override
  State<StartupPage> createState() => _StartupPageState();
}

class _StartupPageState extends State<StartupPage> with SingleTickerProviderStateMixin {
  bool _loading = false;
  bool _navigated = false;
  String _status = "";
  String? _errorMessage;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _autoConnect();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _autoConnect() async {
    final savedServer = await ServerService.loadSavedServer();

    if (savedServer != null) {
      setState(() {
        _loading = true;
        _status = "Connecting to saved server...";
      });

      if (await ServerService.validateServer(ApiConfig.serverBase)) {
        if (mounted) _goHome();
      } else {
        if (mounted) {
          setState(() {
            _loading = false;
            _status = "Saved server unavailable";
            _errorMessage = "Previous server connection failed";
          });
        }
      }
    }
  }

  void _goHome() {
    if (_navigated) return;
    _navigated = true;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  Future<void> _discoverServer() async {
    setState(() {
      _loading = true;
      _status = "Searching on LAN...";
      _errorMessage = null;
    });

    try {
      final server = await ServerDiscovery.discoverViaMDNS() ??
          await ServerDiscovery.discoverViaScan();

      if (!mounted) return;

      if (server != null && await ServerService.validateServer(server)) {
        await ServerService.saveServerBase(server);
        _goHome();
      } else {
        setState(() {
          _loading = false;
          _status = "No server found";
          _errorMessage = "Make sure the server is running on your LAN";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _status = "Discovery failed";
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _manualIp() async {
    final ip = await _showIpDialog();
    if (ip == null || !mounted) return;

    setState(() {
      _loading = true;
      _status = "Connecting to $ip...";
      _errorMessage = null;
    });

    try {
      if (await ServerService.validateServer(ip)) {
        await ServerService.saveServerBase(ip);
        _goHome();
      } else {
        setState(() {
          _loading = false;
          _status = "Connection failed";
          _errorMessage = "Server not responding at $ip";
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _status = "Connection error";
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<String?> _showIpDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Enter Server IP"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: "192.168.1.10",
                  labelText: "IP Address",
                  prefixIcon: Icon(Icons.computer),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Please enter an IP address";
                  }
                  final ipRegex = RegExp(
                    r'^(\d{1,3}\.){3}\d{1,3}$',
                  );
                  if (!ipRegex.hasMatch(value.trim())) {
                    return "Invalid IP format";
                  }
                  return null;
                },
                autofocus: true,
              ),
              const SizedBox(height: 8),
              const Text(
                "Port 8080 will be used automatically",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                final ip = controller.text.trim();
                Navigator.pop(context, "http://$ip:8080");
              }
            },
            child: const Text("Connect"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App icon/logo
                    Icon(
                      Icons.router,
                      size: 80,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    
                    // App title
                    Text(
                      "LANPlay",
                      style: theme.textTheme.headlineLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Connect to your local server",
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Action buttons
                    SizedBox(
                      width: 280,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _loading ? null : _discoverServer,
                            icon: const Icon(Icons.search),
                            label: const Text("Discover Server"),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            onPressed: _loading ? null : _manualIp,
                            icon: const Icon(Icons.edit),
                            label: const Text("Manual IP Entry"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Loading indicator
                    if (_loading) ...[
                      const SizedBox(height: 32),
                      const CircularProgressIndicator(),
                    ],

                    // Status message
                    if (_status.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Card(
                        color: _errorMessage != null
                            ? theme.colorScheme.errorContainer
                            : theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _errorMessage != null
                                        ? Icons.error_outline
                                        : Icons.info_outline,
                                    size: 20,
                                    color: _errorMessage != null
                                        ? theme.colorScheme.error
                                        : theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      _status,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: _errorMessage != null
                                            ? theme.colorScheme.error
                                            : theme.colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  _errorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onErrorContainer,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}