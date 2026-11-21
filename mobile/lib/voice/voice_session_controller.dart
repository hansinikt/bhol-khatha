import 'nlu/intent_parser.dart';
import 'nlu/number_normalizer.dart';

enum VoiceState { idle, listening, parsing, clarifying, confirming, saved }

/// Nothing is written to the ledger until confirm() is called.
class VoiceSessionController {
  VoiceState state = VoiceState.idle;
  ParsedUtterance? pending;
  String? clarifyQuestion; // 'amount' | 'name' | 'unclear'

  void onTranscript(String text) {
    state = VoiceState.parsing;
    final parsed = IntentParser.parse(text);

    // "Nahi, 430": fix the amount of the pending entry.
    if (parsed.intent == Intent.correction && pending != null) {
      _route(ParsedUtterance(pending!.intent,
          customerName: pending!.customerName, amount: parsed.amount));
      return;
    }
    // Answer to a clarification question: fill the missing field.
    if (clarifyQuestion != null &&
        pending != null &&
        pending!.intent != Intent.unknown &&
        parsed.intent == Intent.unknown) {
      _route(ParsedUtterance(pending!.intent,
          customerName: pending!.customerName ?? parsed.customerName,
          amount: pending!.amount ?? NumberNormalizer.parse(text)));
      return;
    }
    _route(parsed);
  }

  void _route(ParsedUtterance p) {
    pending = p;
    if (p.intent == Intent.unknown) {
      clarifyQuestion = 'unclear';
      state = VoiceState.clarifying;
    } else if (p.customerName == null) {
      clarifyQuestion = 'name';
      state = VoiceState.clarifying;
    } else if (p.intent != Intent.queryBalance && p.amount == null) {
      clarifyQuestion = 'amount';
      state = VoiceState.clarifying;
    } else {
      clarifyQuestion = null;
      state = VoiceState.confirming;
    }
  }

  /// Returns the entry for the caller to persist, then resets.
  ParsedUtterance? confirm() {
    if (state != VoiceState.confirming) return null;
    final result = pending;
    pending = null;
    state = VoiceState.saved;
    return result;
  }

  void cancel() {
    pending = null;
    clarifyQuestion = null;
    state = VoiceState.idle;
  }
}