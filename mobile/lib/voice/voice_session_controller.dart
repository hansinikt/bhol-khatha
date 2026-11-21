import 'nlu/intent_parser.dart';

enum VoiceState { idle, listening, parsing, clarifying, confirming, saved }

/// Nothing is written to the ledger until confirm() is called.
class VoiceSessionController {
  VoiceState state = VoiceState.idle;
  ParsedUtterance? pending;
  String? clarifyQuestion; // 'amount' | 'name' | 'unclear'

  void onTranscript(String text) {
    state = VoiceState.parsing;
    final parsed = IntentParser.parse(text);

    if (parsed.intent == Intent.correction && pending != null) {
      pending = ParsedUtterance(pending!.intent,
          customerName: pending!.customerName, amount: parsed.amount);
      state = VoiceState.confirming;
      return;
    }
    pending = parsed;
    if (parsed.intent == Intent.unknown) {
      clarifyQuestion = 'unclear';
      state = VoiceState.clarifying;
    } else if (parsed.intent != Intent.queryBalance &&
        (parsed.amount == null || parsed.customerName == null)) {
      clarifyQuestion = parsed.amount == null ? 'amount' : 'name';
      state = VoiceState.clarifying;
    } else {
      state = VoiceState.confirming;
    }
  }

  /// Returns the parsed entry for the caller to persist, then resets.
  ParsedUtterance? confirm() {
    if (state != VoiceState.confirming) return null;
    final result = pending;
    state = VoiceState.saved;
    pending = null;
    return result;
  }

  void cancel() {
    pending = null;
    clarifyQuestion = null;
    state = VoiceState.idle;
  }
}