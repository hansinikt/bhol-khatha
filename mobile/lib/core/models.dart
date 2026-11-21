// BolKhata core models. Pure Dart: no Flutter imports allowed in lib/core/.

enum EntryType { credit, payment }

class Customer {
  final String id;
  final String name;
  final DateTime createdAt;

  const Customer({
    required this.id,
    required this.name,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Customer.fromJson(Map<String, dynamic> j) => Customer(
        id: j['id'] as String,
        name: j['name'] as String,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

class LedgerEntry {
  final String id;
  final String customerId;
  final EntryType type;

  /// Whole rupees. Always > 0. Never use double for money.
  final int amount;
  final DateTime createdAt;

  /// What the shopkeeper actually said or typed.
  final String? rawText;

  const LedgerEntry({
    required this.id,
    required this.customerId,
    required this.type,
    required this.amount,
    required this.createdAt,
    this.rawText,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'customerId': customerId,
        'type': type.name,
        'amount': amount,
        'createdAt': createdAt.toIso8601String(),
        'rawText': rawText,
      };

  factory LedgerEntry.fromJson(Map<String, dynamic> j) => LedgerEntry(
        id: j['id'] as String,
        customerId: j['customerId'] as String,
        type: EntryType.values.byName(j['type'] as String),
        amount: j['amount'] as int,
        createdAt: DateTime.parse(j['createdAt'] as String),
        rawText: j['rawText'] as String?,
      );
}
