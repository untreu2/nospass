import 'package:flutter/material.dart';
import 'package:nostr_tools/nostr_tools.dart';
import 'password_manager_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _privkeyController = TextEditingController();
  String _message = '';
  final _secureStorage = const FlutterSecureStorage();
  final LocalAuthentication auth = LocalAuthentication();
  bool _isBiometricAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkBiometric();
    _loadStoredPrivkey();
  }

  Future<void> _checkBiometric() async {
    bool canCheckBiometrics = await auth.canCheckBiometrics;
    bool isDeviceSupported = await auth.isDeviceSupported();
    setState(() {
      _isBiometricAvailable = canCheckBiometrics && isDeviceSupported;
    });
  }

  Future<void> _loadStoredPrivkey() async {
    String? storedPrivkey = await _secureStorage.read(key: 'privkeyHex');
    if (storedPrivkey != null) {
      setState(() {
        _privkeyController.text = storedPrivkey;
      });
      _login(storedPrivkey);
    }
  }

  Future<void> _login(String privkeyHex) async {
    if (privkeyHex.length != 64 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(privkeyHex)) {
      setState(() {
        _message = 'Invalid private key. Must be 64 hex chars.';
      });
      return;
    }

    try {
      final keyApi = KeyApi();
      final pubkeyHex = keyApi.getPublicKey(privkeyHex);

      await _secureStorage.write(key: 'privkeyHex', value: privkeyHex);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordManagerScreen(
            privkeyHex: privkeyHex,
            pubkeyHex: pubkeyHex,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _message = 'Error: $e';
      });
    }
  }

  Future<void> _authenticateAndLogin() async {
    bool authenticated = false;
    try {
      authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to login',
        options: const AuthenticationOptions(
          stickyAuth: true,
        ),
      );
    } catch (e) {
      print(e);
    }

    if (authenticated) {
      String? storedPrivkey = await _secureStorage.read(key: 'privkeyHex');
      if (storedPrivkey != null) {
        _login(storedPrivkey);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login with Hex Private Key'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _privkeyController,
              decoration: const InputDecoration(
                labelText: 'Enter your 64-char hex private key...',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _login(_privkeyController.text.trim());
                },
                child: const Text('LOGIN'),
              ),
            ),
            if (_isBiometricAvailable)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Login with Biometrics'),
                  onPressed: _authenticateAndLogin,
                ),
              ),
            const SizedBox(height: 20),
            Text(_message, style: const TextStyle(color: Colors.red)),
          ],
        ),
      ),
    );
  }
}
