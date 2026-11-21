// In-memory ledger. Subclasses override persist() to save to disk.
// Pure Dart: no Flutter imports allowed in lib/core/.

import 'models.dart';

class LedgerStore {
  final List<Customer> _customers = [];
  final List<LedgerEntry> _entries = [];
  int _seq = 0;

  /// Called after every change. Override to save. Default: do nothing.
  Future<void> persist() async {}

  List<Customer> get customers => List.unmodifiable(_customers);
  List<LedgerEntry> get entries => List.unmodifiable(_entries);

  /// Replace everything (used when loading from disk).
  void loadAll(List<Customer> customers, List<LedgerEntry> entries) {
    _customers
      ..clear()
      ..addAll(customers);
    _entries
      ..clear()
      ..addAll(entries);
  }

  static String normalizeName(String name) => name.trim().toLowerCase();

  /// Exact, case-insensitive match. No fuzzy matching on purpose:
  /// "Ramesh" and "Rajesh" must never be merged in a money ledger.
  Customer? findCustomer(String name) {
    final key = normalizeName(name);
    if (key.isEmpty) return null;
    for (final c in _customers) {
      if (normalizeName(c.name) == key) return c;
    }
    return null;
  }

  Future<Customer> getOrCreateCustomer(String name) async {
    final existing = findCustomer(name);
    if (existing != null) return existing;
    final c = Customer(
      id: _newId(),
      name: name.trim(),
      createdAt: DateTime.now(),
    );
    _customers.add(c);
    await persist();
    return c;
  }

  Future<LedgerEntry> addEntry({
    required String customerName,
    required EntryType type,
    required int amount,
    String? rawText,
  }) async {
    if (amount <= 0) {
      throw ArgumentError.value(amount, 'amount', 'must be greater than 0');
    }
    final c = await getOrCreateCustomer(customerName);
    final e = LedgerEntry(
      id: _newId(),
      customerId: c.id,
      type: type,
      amount: amount,
      createdAt: DateTime.now(),
      rawText: rawText,
    );
    _entries.add(e);
    await persist();
    return e;
  }

  Customer? customerById(String id) {
    for (final c in _customers) {
      if (c.id == id) return c;
    }
    return null;
  }

  /// Newest first.
  List<LedgerEntry> entriesFor(String customerId) =>
      _entries.where((e) => e.customerId == customerId).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Positive = customer owes the shop. Negative = customer paid in advance.
  int balanceOf(String customerId) {
    var total = 0;
    for (final e in _entries) {
      if (e.customerId != customerId) continue;
      total += e.type == EntryType.credit ? e.amount : -e.amount;
    }
    return total;
  }

  /// Sum of all positive balances.
  int totalOutstanding() {
    var total = 0;
    for (final c in _customers) {
      final b = balanceOf(c.id);
      if (b > 0) total += b;
    }
    return total;
  }

  String _newId() => '${DateTime.now().microsecondsSinceEpoch}-${_seq++}';
}
