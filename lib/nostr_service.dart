import 'dart:async';
import 'dart:convert';
import 'package:nostr_tools/nostr_tools.dart';
import 'models.dart';

class NostrService {
  final String privkeyHex;
  final String pubkeyHex;

  RelayPoolApi? relayPool;
  bool isConnected = false;
  int connectedCount = 0;

  List<PasswordItem> passwords = [];
  final _passwordController = StreamController<List<PasswordItem>>.broadcast();
  Stream<List<PasswordItem>> get passwordsStream => _passwordController.stream;

  final nip04 = Nip04();
  final eventApi = EventApi();

  final relaysList = [
    'wss://strfry.iris.to',
    'wss://relay.damus.io',
    'wss://relay.nostr.band',
    'wss://relay.snort.social',
    'wss://vitor.nostr1.com',
    'wss://nos.lol',
    'wss://untreu.me',
  ];

  NostrService({
    required this.privkeyHex,
    required this.pubkeyHex,
  });

  Future<void> connect() async {
    relayPool = RelayPoolApi(relaysList: relaysList);
    final stream = await relayPool!.connect();

    relayPool!.on((event) {
      if (event == RelayEvent.connect) {
        connectedCount = relayPool!.connectedRelays.length;
        if (connectedCount > 0) {
          isConnected = true;
          relayPool!.sub([
            Filter(
              kinds: [4],
              since: 0,
              limit: 10000,
              p: [pubkeyHex],
            )
          ]);
        }
      } else if (event == RelayEvent.error) {
        connectedCount = relayPool!.connectedRelays.length;
        isConnected = connectedCount > 0;
      }
    });

    stream.listen((Message message) {
      _onMessage(message);
    });
  }

  void _onMessage(Message message) {
    if (message.type == "EVENT") {
      final event = message.message as Event;
      if (event.kind == 4 && event.content.isNotEmpty) {
        String? receiver;
        for (var t in event.tags) {
          if (t.isNotEmpty && t[0] == 'p') {
            receiver = t[1];
            break;
          }
        }

        if (receiver == pubkeyHex) {
          try {
            final decryptedContent =
                nip04.decrypt(privkeyHex, event.pubkey, event.content);
            final Map<String, dynamic> jsonData = jsonDecode(decryptedContent);
            final PasswordItem newItem = PasswordItem.fromJson(jsonData);

            if (!passwords.any((item) => item.id == newItem.id)) {
              passwords.add(newItem);
              _passwordController.add(List.from(passwords));
            }
          } catch (e) {
            print("Decryption or parsing error: $e");
          }
        }
      }
    } else if (message.type == "EOSE") {
      _passwordController.add(List.from(passwords));
    }
  }

  void addPassword(PasswordItem password) {
    final String jsonString = jsonEncode(password.toJson());
    final String ciphertext = nip04.encrypt(privkeyHex, pubkeyHex, jsonString);

    var newEvent = Event(
      kind: 4,
      tags: [
        ["p", pubkeyHex]
      ],
      content: ciphertext,
      created_at: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      pubkey: pubkeyHex,
    );

    newEvent = eventApi.finishEvent(newEvent, privkeyHex);
    relayPool?.publish(newEvent);

    passwords.add(password);
    _passwordController.add(List.from(passwords));
  }

  void sendLoginEvent() {
    final now = DateTime.now().toUtc().toIso8601String();
    final loginMessage = "Password manager opened at $now";

    final loginEvent = Event(
      kind: 1000,
      tags: [
        ["p", pubkeyHex]
      ],
      content: loginMessage,
      created_at: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      pubkey: pubkeyHex,
    );

    final finishedEvent = eventApi.finishEvent(loginEvent, privkeyHex);
    relayPool?.publish(finishedEvent);
  }

  void dispose() {
    _passwordController.close();
    relayPool?.close();
  }
}
