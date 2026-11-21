// Confirm-before-save conversation state machine. Pure Dart: no Flutter imports.
// The UI feeds every transcript (spoken or typed) into handle(), and the
// Save/Cancel buttons call confirm()/cancel(). Each call returns a SessionReply
// with a promptKey that lib/l10n/prompts.dart turns into text + speech.

import 'intent_parser.dart';
import 'ledger_store.dart';
import 'models.dart';

enum SessionStage { idle, askAmount, askName, askType, confirming }

class PendingEntry {
  EntryType? type;
  String? customerName;
  int? amount;
  String rawText;

  PendingEntry({this.type, this.customerName, this.amount, this.rawText = ''});

  bool get isComplete =>
      type != null && customerName != null && amount != null && amount! > 0;
}

class SessionReply {
  /// Key into Prompts (e.g. 'confirmCredit'). Never show this raw to users.
  final String promptKey;

  /// Values for {placeholders} in the prompt: name, amount, balance.
  final Map<String, String> args;
  final SessionStage stage;

  /// The entry waiting for confirmation (only when stage == confirming / ask*).
  final PendingEntry? pending;

  /// True only on the reply right after something was written to the ledger.
  final bool savedNow;

  const SessionReply(
    this.promptKey, {
    this.args = const {},
    required this.stage,
    this.pending,
    this.savedNow = false,
  });
}

class VoiceSession {
  final LedgerStore store;
  SessionStage stage = SessionStage.idle;
  PendingEntry? pending;

  VoiceSession(this.store);

  Future<SessionReply> handle(String text) async {
    final p = IntentParser.parse(text);

    // "nahi" / "cancel" at any point in a conversation cancels it.
    if (stage != SessionStage.idle && p.intent == LedgerIntent.no) {
      return cancel();
    }

    switch (stage) {
      case SessionStage.confirming:
        if (p.intent == LedgerIntent.yes) return confirm();
        final isBareNumber =
            p.intent == LedgerIntent.unknown && p.customerName == null;
        if (p.amount != null &&
            (p.intent == LedgerIntent.correction || isBareNumber)) {
          pending!.amount = p.amount;
          return _askConfirm();
        }
        break; // anything else is treated as a brand-new command
      case SessionStage.askAmount:
        if (p.amount != null) {
          pending!.amount = p.amount;
          return _next();
        }
        return _reply('askAmount', {'name': pending!.customerName ?? ''});
      case SessionStage.askName:
        if (p.customerName != null) {
          pending!.customerName = p.customerName;
          return _next();
        }
        return _reply('askName');
      case SessionStage.askType:
        if (p.intent == LedgerIntent.addCredit) {
          pending!.type = EntryType.credit;
          return _next();
        }
        if (p.intent == LedgerIntent.recordPayment) {
          pending!.type = EntryType.payment;
          return _next();
        }
        return _reply('askType', {
          'name': pending!.customerName ?? '',
          'amount': '${pending!.amount ?? ''}',
        });
      case SessionStage.idle:
        break;
    }
    return _fresh(p);
  }

  /// Writes the pending entry. The ONLY place that writes to the ledger.
  Future<SessionReply> confirm() async {
    final e = pending;
    if (stage != SessionStage.confirming || e == null || !e.isComplete) {
      return _reply('notUnderstood');
    }
    final entry = await store.addEntry(
      customerName: e.customerName!,
      type: e.type!,
      amount: e.amount!,
      rawText: e.rawText,
    );
    final customer = store.customerById(entry.customerId)!;
    final balance = store.balanceOf(customer.id);
    _reset();
    return SessionReply(
      'saved',
      args: {'name': customer.name, 'balance': '$balance'},
      stage: stage,
      savedNow: true,
    );
  }

  SessionReply cancel() {
    _reset();
    return _reply('cancelled');
  }

  Future<SessionReply> _fresh(ParsedUtterance p) async {
    _reset();
    switch (p.intent) {
      case LedgerIntent.queryBalance:
        final name = p.customerName;
        if (name == null) {
          return _reply('totalDue', {'amount': '${store.totalOutstanding()}'});
        }
        final c = store.findCustomer(name);
        if (c == null) return _reply('customerNotFound', {'name': name});
        return _reply('balanceIs', {'name': c.name, 'balance': '${store.balanceOf(c.id)}'});
      case LedgerIntent.addCredit:
      case LedgerIntent.recordPayment:
        pending = PendingEntry(
          type: p.intent == LedgerIntent.addCredit ? EntryType.credit : EntryType.payment,
          customerName: p.customerName,
          amount: p.amount,
          rawText: p.rawText,
        );
        return _next();
      case LedgerIntent.unknown:
        if (p.amount != null && p.customerName != null) {
          pending = PendingEntry(
            customerName: p.customerName,
            amount: p.amount,
            rawText: p.rawText,
          );
          return _next(); // will ask "credit or payment?"
        }
        return _reply('notUnderstood');
      case LedgerIntent.no:
        return _reply('cancelled');
      case LedgerIntent.yes:
      case LedgerIntent.correction:
        return _reply('notUnderstood');
    }
  }

  /// Ask for whatever is missing, in order: name, amount, type. Then confirm.
  SessionReply _next() {
    final e = pending!;
    if (e.customerName == null) {
      stage = SessionStage.askName;
      return _reply('askName');
    }
    if (e.amount == null) {
      stage = SessionStage.askAmount;
      return _reply('askAmount', {'name': e.customerName!});
    }
    if (e.type == null) {
      stage = SessionStage.askType;
      return _reply('askType', {'name': e.customerName!, 'amount': '${e.amount}'});
    }
    return _askConfirm();
  }

  SessionReply _askConfirm() {
    stage = SessionStage.confirming;
    final e = pending!;
    final existing = store.findCustomer(e.customerName!);
    final String key;
    if (e.type == EntryType.payment) {
      key = 'confirmPayment';
    } else {
      key = existing == null ? 'confirmCreditNew' : 'confirmCredit';
    }
    return _reply(key, {
      'name': existing?.name ?? e.customerName!,
      'amount': '${e.amount}',
    });
  }

  SessionReply _reply(String key, [Map<String, String> args = const {}]) =>
      SessionReply(key, args: args, stage: stage, pending: pending);

  void _reset() {
    stage = SessionStage.idle;
    pending = null;
  }
}
