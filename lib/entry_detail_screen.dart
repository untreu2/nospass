import 'package:flutter/material.dart';
import 'models.dart';
import 'package:flutter/services.dart';

class EntryDetailScreen extends StatefulWidget {
  final PasswordItem entry;

  const EntryDetailScreen({Key? key, required this.entry}) : super(key: key);

  @override
  State<EntryDetailScreen> createState() => _EntryDetailScreenState();
}

class _EntryDetailScreenState extends State<EntryDetailScreen> {
  bool _isPasswordVisible = false;

  void _copyToClipboard(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$label not available.")),
      );
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$label copied to clipboard.")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    _getIcon(entry.type),
                    size: 30,
                    color: _getColor(entry.type),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _getTitle(entry.type),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _buildDetailRow(
                label: "Name",
                value: entry.name,
                onCopy: () => _copyToClipboard(context, "Name", entry.name),
              ),
              const SizedBox(height: 10),
              if (entry.type == EntryType.password) ...[
                _buildDetailRow(
                  label: "URI",
                  value: entry.uri,
                  onCopy: () => _copyToClipboard(context, "URI", entry.uri),
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  label: "Username",
                  value: entry.username,
                  onCopy: () => _copyToClipboard(context, "Username", entry.username),
                ),
                const SizedBox(height: 10),
                _buildPasswordRow(
                  label: "Password",
                  value: entry.password,
                ),
              ] else if (entry.type == EntryType.creditCard) ...[
                _buildDetailRow(
                  label: "Card Number",
                  value: entry.cardNumber,
                  onCopy: () => _copyToClipboard(context, "Card Number", entry.cardNumber),
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  label: "Expiration Date",
                  value: entry.expirationDate,
                  onCopy: () => _copyToClipboard(context, "Expiration Date", entry.expirationDate),
                ),
                const SizedBox(height: 10),
                _buildDetailRow(
                  label: "CVV",
                  value: entry.cvv,
                  onCopy: () => _copyToClipboard(context, "CVV", entry.cvv),
                ),
              ] else if (entry.type == EntryType.note) ...[
                _buildDetailRow(
                  label: "Notes",
                  value: entry.notes,
                  onCopy: () => _copyToClipboard(context, "Notes", entry.notes),
                ),
              ],
              const SizedBox(height: 20),
              if (entry.customFields.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Custom Fields",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...entry.customFields.map((field) => _buildDetailRow(
                          label: field.name,
                          value: field.value,
                          onCopy: () => _copyToClipboard(context, field.name, field.value),
                        )),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordRow({required String label, required String? value}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.indigo.shade800,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$label: ${_isPasswordVisible ? (value ?? '••••••••') : '••••••••'}",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isPasswordVisible = !_isPasswordVisible;
              });
            },
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            color: Colors.white,
            onPressed: () {
              _copyToClipboard(context, label, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({required String label, required String? value, required VoidCallback onCopy}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[850],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "$label: ${value ?? 'Not Available'}",
              style: const TextStyle(fontSize: 16, color: Colors.white),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy),
            color: Colors.white,
            onPressed: onCopy,
          ),
        ],
      ),
    );
  }

  IconData _getIcon(EntryType type) {
    switch (type) {
      case EntryType.password:
        return Icons.lock;
      case EntryType.creditCard:
        return Icons.credit_card;
      case EntryType.note:
        return Icons.note;
      default:
        return Icons.lock;
    }
  }

  String _getTitle(EntryType type) {
    switch (type) {
      case EntryType.password:
        return "Password";
      case EntryType.creditCard:
        return "Credit Card";
      case EntryType.note:
        return "Note";
      default:
        return "Password";
    }
  }

  Color _getColor(EntryType type) {
    switch (type) {
      case EntryType.password:
        return Colors.indigo;
      case EntryType.creditCard:
        return Colors.teal;
      case EntryType.note:
        return Colors.amber;
      default:
        return Colors.indigo;
    }
  }
}