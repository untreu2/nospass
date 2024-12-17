import 'package:flutter/material.dart';
import 'package:nostr_tools/nostr_tools.dart';
import 'password_manager_screen.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _privkeyController = TextEditingController();
  String _message = '';
  final _secureStorage = const FlutterSecureStorage();
  final Nip19 nip19 = Nip19();

  @override
  void initState() {
    super.initState();
    _loadStoredPrivkey();
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
        _message = 'Invalid private key. Must be 64 hex characters.';
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

  Future<void> _attemptLogin(String input) async {
    if (input.startsWith('nsec1')) {
      try {
        final decoded = nip19.decode(input);
        if (decoded['type'] == 'nsec' && decoded['data'] is String) {
          final privkeyHex = decoded['data'] as String;
          await _login(privkeyHex);
          return;
        } else {
          setState(() {
            _message = 'Invalid NIP-19 nsec format.';
          });
        }
      } catch (e) {
        setState(() {
          _message = 'Error decoding NIP-19 key: $e';
        });
      }
    } else {
      await _login(input);
    }
  }

  Future<void> _generateNewNsec() async {
    try {
      final keyApi = KeyApi();
      final privkeyHex = keyApi.generatePrivateKey();
      final nsec = nip19.nsecEncode(privkeyHex);

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Account created'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Please save the following nsec securely. You will not be able to access your account without it.',
              ),
              const SizedBox(height: 20),
              SelectableText(
                nsec,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: nsec));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('nsec copied to clipboard!')),
                );
              },
              child: const Text('Copy'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() {
        _message = 'Error creating NSEC: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('welcome to nospass!'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextField(
              controller: _privkeyController,
              decoration: const InputDecoration(
                labelText: 'Enter your nsec...',
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _attemptLogin(_privkeyController.text.trim());
                },
                child: const Text('LOGIN'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _generateNewNsec,
                child: const Text('SIGNUP'),
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
