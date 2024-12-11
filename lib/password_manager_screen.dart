import 'dart:math';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'nostr_service.dart';
import 'models.dart';
import 'entry_detail_screen.dart';
import 'package:uuid/uuid.dart';

class AddEntryScreen extends StatefulWidget {
  final EntryType? preselectedType;

  const AddEntryScreen({Key? key, this.preselectedType}) : super(key: key);

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late EntryType _selectedType;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _uriController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expirationDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final List<CustomField> _customFields = [];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.preselectedType ?? EntryType.password;
  }

  void _addCustomField() {
    setState(() {
      _customFields.add(CustomField(name: '', value: ''));
    });
  }

  void _removeCustomField(int index) {
    setState(() {
      _customFields.removeAt(index);
    });
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      PasswordItem newEntry;
      if (_selectedType == EntryType.password) {
        newEntry = PasswordItem(
          id: const Uuid().v4(),
          type: EntryType.password,
          name: _nameController.text.trim(),
          uri: _uriController.text.trim(),
          username: _usernameController.text.trim(),
          password: _passwordController.text.trim(),
          notes: _notesController.text.trim(),
          customFields: _customFields.where((f) => f.name.isNotEmpty).toList(),
        );
      } else if (_selectedType == EntryType.creditCard) {
        newEntry = PasswordItem(
          id: const Uuid().v4(),
          type: EntryType.creditCard,
          name: _nameController.text.trim(),
          cardNumber: _cardNumberController.text.trim(),
          expirationDate: _expirationDateController.text.trim(),
          cvv: _cvvController.text.trim(),
          notes: _notesController.text.trim(),
          customFields: _customFields.where((f) => f.name.isNotEmpty).toList(),
        );
      } else {
        newEntry = PasswordItem(
          id: const Uuid().v4(),
          type: EntryType.note,
          name: _nameController.text.trim(),
          notes: _notesController.text.trim(),
          customFields: _customFields.where((f) => f.name.isNotEmpty).toList(),
        );
      }
      Navigator.pop(context, newEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add new entry'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<EntryType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Entry Type',
                  labelStyle: TextStyle(color: Colors.white),
                  border: UnderlineInputBorder(),
                ),
                dropdownColor: Colors.black,
                style: const TextStyle(color: Colors.white),
                items: EntryType.values.map((EntryType type) {
                  return DropdownMenuItem<EntryType>(
                    value: type,
                    child: Text(
                      type
                          .toString()
                          .split('.')
                          .last
                          .replaceAll('creditCard', 'Card')
                          .replaceAll('password', 'Login')
                          .replaceAll('note', 'Secure note'),
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (EntryType? newType) {
                  if (newType != null) {
                    setState(() {
                      _selectedType = newType;
                    });
                  }
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                style: const TextStyle(color: Colors.white),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              if (_selectedType == EntryType.password) ...[
                TextFormField(
                  controller: _uriController,
                  decoration: const InputDecoration(
                    labelText: 'URI',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Login password',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                ),
              ] else if (_selectedType == EntryType.creditCard) ...[
                TextFormField(
                  controller: _cardNumberController,
                  decoration: const InputDecoration(
                    labelText: 'Card Number',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a card number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _expirationDateController,
                  decoration: const InputDecoration(
                    labelText: 'Expiration Date (MM/YY)',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  keyboardType: TextInputType.datetime,
                  style: const TextStyle(color: Colors.white),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the expiration date';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _cvvController,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the CVV';
                    }
                    return null;
                  },
                ),
              ] else if (_selectedType == EntryType.note) ...[
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes',
                    labelStyle: TextStyle(color: Colors.white),
                  ),
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                ),
              ],
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Custom fields',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addCustomField,
                    tooltip: 'Add custom field',
                  ),
                ],
              ),
              ..._customFields.asMap().entries.map((entry) {
                int index = entry.key;
                CustomField field = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: field.name,
                          decoration: const InputDecoration(
                            labelText: 'Field Name',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            _customFields[index].name = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          initialValue: field.value,
                          decoration: const InputDecoration(
                            labelText: 'Field Value',
                            labelStyle: TextStyle(color: Colors.white),
                          ),
                          style: const TextStyle(color: Colors.white),
                          onChanged: (value) {
                            _customFields[index].value = value;
                          },
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove_circle, color: Colors.red),
                        onPressed: () => _removeCustomField(index),
                        tooltip: 'Remove Custom Field',
                      ),
                    ],
                  ),
                );
              }).toList(),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text(
                      'Add',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.blueGrey.shade500,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

class PasswordGeneratorScreen extends StatefulWidget {
  const PasswordGeneratorScreen({Key? key}) : super(key: key);

  @override
  State<PasswordGeneratorScreen> createState() =>
      _PasswordGeneratorScreenState();
}

class _PasswordGeneratorScreenState extends State<PasswordGeneratorScreen> {
  final TextEditingController _lengthController = TextEditingController();
  String? _generatedPassword;

  String _generateRandomPassword(int length) {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    Random rnd = Random.secure();
    return List.generate(length, (index) => chars[rnd.nextInt(chars.length)])
        .join();
  }

  void _generatePassword() {
    final length = int.tryParse(_lengthController.text.trim());
    if (length != null && length > 0) {
      setState(() {
        _generatedPassword = _generateRandomPassword(length);
      });
    }
  }

  void _copyPassword() {
    if (_generatedPassword != null) {
      Clipboard.setData(ClipboardData(text: _generatedPassword!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password copied to clipboard!')),
      );
    }
  }

  @override
  void dispose() {
    _lengthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password generator'),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _lengthController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Password Length',
                labelStyle: TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _generatePassword,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueGrey.shade500,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Generate',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(height: 20),
            if (_generatedPassword != null) ...[
              SelectableText(
                _generatedPassword!,
                style: const TextStyle(color: Colors.white, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _copyPassword,
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Copy',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class PasswordManagerScreen extends StatefulWidget {
  final String privkeyHex;
  final String pubkeyHex;

  const PasswordManagerScreen({
    Key? key,
    required this.privkeyHex,
    required this.pubkeyHex,
  }) : super(key: key);

  @override
  State<PasswordManagerScreen> createState() => _PasswordManagerScreenState();
}

class _PasswordManagerScreenState extends State<PasswordManagerScreen> {
  NostrService? nostrService;
  List<PasswordItem> passwords = [];
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Future<void> _savePasswordsToSecureStorage(List<PasswordItem> items) async {
    final jsonString = jsonEncode(items.map((i) => i.toJson()).toList());
    await _secureStorage.write(key: 'password_items', value: jsonString);
  }

  Future<List<PasswordItem>> _loadPasswordsFromSecureStorage() async {
    final jsonStr = await _secureStorage.read(key: 'password_items');
    if (jsonStr != null) {
      final List decoded = jsonDecode(jsonStr);
      return decoded.map((item) => PasswordItem.fromJson(item)).toList();
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _loadPasswordsFromSecureStorage().then((localItems) {
      setState(() {
        passwords = localItems;
      });
      nostrService = NostrService(
        privkeyHex: widget.privkeyHex,
        pubkeyHex: widget.pubkeyHex,
      );
      nostrService!.connect().then((_) {
        nostrService!.sendLoginEvent();
        nostrService!.passwordsStream.listen((pwList) {
          setState(() {
            passwords = pwList;
          });
          _savePasswordsToSecureStorage(passwords);
        });
      });
    });
  }

  @override
  void dispose() {
    nostrService?.dispose();
    super.dispose();
  }

  void _addPassword() async {
    final newEntry = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddEntryScreen(preselectedType: EntryType.password),
      ),
    );
    if (newEntry is PasswordItem) {
      nostrService?.addPassword(newEntry);
    }
  }

  Map<EntryType, List<PasswordItem>> _groupEntries() {
    Map<EntryType, List<PasswordItem>> grouped = {
      EntryType.password: [],
      EntryType.creditCard: [],
      EntryType.note: [],
    };
    for (var item in passwords) {
      grouped[item.type]?.add(item);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final connectedCount = nostrService?.connectedCount ?? 0;
    final statusText = (nostrService?.isConnected ?? false)
        ? "Connected to $connectedCount Relay${connectedCount == 1 ? '' : 's'}"
        : "No Connection";
    final groupedEntries = _groupEntries();
    final Map<EntryType, Color> groupColors = {
      EntryType.password: const Color.fromARGB(255, 52, 77, 89),
      EntryType.creditCard: Colors.redAccent,
      EntryType.note: const Color.fromARGB(255, 193, 182, 62),
    };
    final Map<EntryType, IconData> groupIcons = {
      EntryType.password: Icons.lock,
      EntryType.creditCard: Icons.credit_card,
      EntryType.note: Icons.note,
    };

    List<Widget> tiles = [];
    if (groupedEntries[EntryType.password]!.isNotEmpty) {
      tiles.add(_buildGroupTile(
        type: EntryType.password,
        displayName: "Login",
        color: groupColors[EntryType.password]!,
        icon: groupIcons[EntryType.password]!,
        items: groupedEntries[EntryType.password]!,
      ));
    }
    if (groupedEntries[EntryType.creditCard]!.isNotEmpty) {
      tiles.add(_buildGroupTile(
        type: EntryType.creditCard,
        displayName: "Card",
        color: groupColors[EntryType.creditCard]!,
        icon: groupIcons[EntryType.creditCard]!,
        items: groupedEntries[EntryType.creditCard]!,
      ));
    }
    if (groupedEntries[EntryType.note]!.isNotEmpty) {
      tiles.add(_buildGroupTile(
        type: EntryType.note,
        displayName: "Secure note",
        color: groupColors[EntryType.note]!,
        icon: groupIcons[EntryType.note]!,
        items: groupedEntries[EntryType.note]!,
      ));
    }

    tiles.add(
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PasswordGeneratorScreen()),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.green.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.build, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text(
                'Password\ngenerator',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    tiles.add(
      GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SearchPage(allItems: passwords),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade500,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.search, color: Colors.white, size: 40),
              SizedBox(height: 8),
              Text(
                'Search',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("nospass"),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  color: (nostrService?.isConnected ?? false)
                      ? Colors.purple.shade400
                      : Colors.red.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      (nostrService?.isConnected ?? false)
                          ? Icons.check_circle
                          : Icons.error,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Status: $statusText",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: tiles,
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        color: Colors.black,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _addPassword,
            icon: const Text(
              '+',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            label: const Text(
              'Add new item',
              style: TextStyle(fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey.shade500,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupTile({
    required EntryType type,
    required String displayName,
    required Color color,
    required IconData icon,
    required List<PasswordItem> items,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryListPage(
              type: type,
              items: items,
              groupColor: color,
              groupIcon: icon,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 8),
            Text(
              displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryListPage extends StatelessWidget {
  final EntryType type;
  final List<PasswordItem> items;
  final Color groupColor;
  final IconData groupIcon;

  const CategoryListPage({
    Key? key,
    required this.type,
    required this.items,
    required this.groupColor,
    required this.groupIcon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final displayName = type
        .toString()
        .split('.')
        .last
        .replaceAll('creditCard', 'Card')
        .replaceAll('password', 'Login')
        .replaceAll('note', 'Secure note');

    return Scaffold(
      appBar: AppBar(
        title: Text(displayName),
        backgroundColor: Colors.black,
      ),
      body: ListView(
        children: items.map((item) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EntryDetailScreen(entry: item),
                ),
              );
            },
            child: Card(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: ListTile(
                leading: Icon(
                  groupIcon,
                  color: Colors.white,
                  size: 30,
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  displayName,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class SearchPage extends StatefulWidget {
  final List<PasswordItem> allItems;

  const SearchPage({Key? key, required this.allItems}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  List<PasswordItem> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.allItems;
    _searchController.addListener(_filterResults);
  }

  void _filterResults() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.allItems;
      } else {
        _filteredItems = widget.allItems
            .where((item) => item.name.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterResults);
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<EntryType, IconData> entryIcons = {
      EntryType.password: Icons.lock_outline,
      EntryType.creditCard: Icons.credit_card_outlined,
      EntryType.note: Icons.note_outlined,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search by name...',
            hintStyle: TextStyle(color: Colors.white54),
            border: InputBorder.none,
          ),
        ),
      ),
      body: ListView.builder(
        itemCount: _filteredItems.length,
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EntryDetailScreen(entry: item),
                ),
              );
            },
            child: Card(
              color: Colors.grey[850],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
              child: ListTile(
                leading: Icon(
                  entryIcons[item.type],
                  color: Colors.white,
                  size: 30,
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  item.type
                      .toString()
                      .split('.')
                      .last
                      .replaceAll('creditCard', 'Card')
                      .replaceAll('password', 'Login')
                      .replaceAll('note', 'Secure note'),
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
