import '../entities/ledger_entry.dart';

class BalanceCalculator {
  /// Positive = customer owes the shopkeeper. Negative = customer has advance.
  static int balance(Iterable<LedgerEntry> entries) {
    var total = 0;
    for (final e in entries) {
      total += e.type == EntryType.credit ? e.amountRupees : -e.amountRupees;
    }
    return total;
  }
}
