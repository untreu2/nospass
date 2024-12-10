import 'package:uuid/uuid.dart';

enum EntryType { password, creditCard, note }

class PasswordItem {
  final String id;
  final EntryType type;
  final String name;
  final String? uri;
  final String? username;
  final String? password;
  final String? cardNumber;
  final String? expirationDate;
  final String? cvv;
  final String? notes;
  final List<CustomField> customFields;

  PasswordItem({
    required this.id,
    required this.type,
    required this.name,
    this.uri,
    this.username,
    this.password,
    this.cardNumber,
    this.expirationDate,
    this.cvv,
    this.notes,
    required this.customFields,
  });

  factory PasswordItem.fromJson(Map<String, dynamic> json) {
    return PasswordItem(
      id: json['id'] ?? const Uuid().v4(),
      type: EntryType.values.firstWhere(
          (e) => e.toString() == 'EntryType.${json['type']}',
          orElse: () => EntryType.password),
      name: json['name'] ?? '',
      uri: json['uri'],
      username: json['username'],
      password: json['password'],
      cardNumber: json['cardNumber'],
      expirationDate: json['expirationDate'],
      cvv: json['cvv'],
      notes: json['notes'],
      customFields: (json['customFields'] as List<dynamic>?)
              ?.map((field) => CustomField.fromJson(field))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString().split('.').last,
      'name': name,
      'uri': uri,
      'username': username,
      'password': password,
      'cardNumber': cardNumber,
      'expirationDate': expirationDate,
      'cvv': cvv,
      'notes': notes,
      'customFields': customFields.map((f) => f.toJson()).toList(),
    };
  }
}

class CustomField {
  String name;
  String value;

  CustomField({required this.name, required this.value});

  factory CustomField.fromJson(Map<String, dynamic> json) {
    return CustomField(
      name: json['name'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
    };
  }
}
