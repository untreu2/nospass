import 'package:flutter/material.dart';
import 'nostr_service.dart';
import 'models.dart';
import 'entry_detail_screen.dart';
import 'package:uuid/uuid.dart';

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

  @override
  void initState() {
    super.initState();
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
      });
    });
  }

  void _addPassword() {
    showDialog(
      context: context,
      builder: (context) {
        return AddEntryDialog(
          onAdd: (PasswordItem item) {
            nostrService?.addPassword(item);
          },
          preselectedType: EntryType.password,
        );
      },
    );
  }

  @override
  void dispose() {
    nostrService?.dispose();
    super.dispose();
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
      EntryType.creditCard: Colors.red.shade300,
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
              'Add New Item',
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

class AddEntryDialog extends StatefulWidget {
  final Function(PasswordItem) onAdd;
  final EntryType? preselectedType;

  const AddEntryDialog({
    Key? key,
    required this.onAdd,
    this.preselectedType,
  }) : super(key: key);

  @override
  State<AddEntryDialog> createState() => _AddEntryDialogState();
}

class _AddEntryDialogState extends State<AddEntryDialog> {
  final _formKey = GlobalKey<FormState>();
  late EntryType _selectedType;

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _uriController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expirationDateController =
      TextEditingController();
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

  @override
  void dispose() {
    _nameController.dispose();
    _uriController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _cardNumberController.dispose();
    _expirationDateController.dispose();
    _cvvController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.grey[850],
      title: const Text(
        'Add New Entry',
        style: TextStyle(color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<EntryType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Entry Type',
                  labelStyle: TextStyle(color: Colors.white),
                ),
                dropdownColor: Colors.grey[850],
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
                    labelText: 'Login',
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
                    'Custom Fields',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: _addCustomField,
                    tooltip: 'Add Custom Field',
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
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text(
            'Cancel',
            style: TextStyle(color: Colors.white),
          ),
        ),
        ElevatedButton(
          onPressed: () {
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
                  customFields:
                      _customFields.where((f) => f.name.isNotEmpty).toList(),
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
                  customFields:
                      _customFields.where((f) => f.name.isNotEmpty).toList(),
                );
              } else {
                newEntry = PasswordItem(
                  id: const Uuid().v4(),
                  type: EntryType.note,
                  name: _nameController.text.trim(),
                  notes: _notesController.text.trim(),
                  customFields:
                      _customFields.where((f) => f.name.isNotEmpty).toList(),
                );
              }

              widget.onAdd(newEntry);
              Navigator.of(context).pop();
            }
          },
          child: const Text(
            'Add',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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