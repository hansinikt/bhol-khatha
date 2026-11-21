import '../../data/local/database.dart';
import '../../voice/nlu/intent_parser.dart';
import '../entities/ledger_entry.dart';
import '../services/balance_calculator.dart';

class LedgerService {
  final AppDatabase db;
  LedgerService(this.db);

  Future<int> balanceOf(int customerId) async {
    final rows = await db.historyFor(customerId);
    return BalanceCalculator.balance(rows.map((t) => LedgerEntry(
          id: t.id,
          customerId: t.customerId,
          type: t.type == 'credit' ? EntryType.credit : EntryType.payment,
          amountRupees: t.amountRupees,
          createdAt: t.createdAt,
          note: t.note,
        )));
  }

  /// null = customer not found.
  Future<int?> balanceByName(String name) async {
    final c = await db.findByName(name);
    return c == null ? null : balanceOf(c.id);
  }

  /// Saves a confirmed entry; returns the customer's new balance.
  Future<int> save(ParsedUtterance u, {String lang = 'hi'}) async {
    final existing = await db.findByName(u.customerName!);
    final id = existing?.id ?? await db.addCustomer(u.customerName!, lang: lang);
    await db.addTransaction(
        id, u.intent == Intent.addCredit ? 'credit' : 'payment', u.amount!);
    return balanceOf(id);
  }
}