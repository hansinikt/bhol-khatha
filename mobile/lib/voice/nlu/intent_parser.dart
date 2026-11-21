import 'number_normalizer.dart';

enum Intent { addCredit, recordPayment, queryBalance, correction, unknown }

class ParsedUtterance {
  final Intent intent;
  final String? customerName;
  final int? amount;
  const ParsedUtterance(this.intent, {this.customerName, this.amount});
  @override
  String toString() => 'ParsedUtterance($intent, $customerName, $amount)';
}

class IntentParser {
  static const _credit = {
    'udhaar', 'udhar', 'credit', 'baaki', 'liya', 'took', 'saala', 'kadan', 'appu',
  };
  static const _payment = {
    'diya', 'paid', 'payment', 'jama', 'returned', 'kattinaru', 'kattaru',
    'kodutha', 'ichcharu', 'kuduthaanga',
  };
  static const _query = {
    'balance', 'kitna', 'ethna', 'entha', 'evvalavu', 'baki',
  };
  static const _correctionStart = {'nahi', 'nahin', 'no', 'illa', 'kaadu', 'illai'};
  static const _stop = {
    'ka', 'ki', 'ko', 'ne', 'hai', 'the', 'is', 'of', 'rupees', 'rupaye', 'rs',
    'ye', 'woh', 'how', 'much',
  };

  static ParsedUtterance parse(String text) {
    final t = text.toLowerCase().trim();
    if (t.isEmpty) return const ParsedUtterance(Intent.unknown);
    final words = t.split(RegExp(r'\s+'));
    final amount = NumberNormalizer.parse(t);

    if (_correctionStart.contains(words.first) && amount != null) {
      return ParsedUtterance(Intent.correction, amount: amount);
    }
    final name = _guessName(words);
    if (_hasWord(words, _query) && amount == null) {
      return ParsedUtterance(Intent.queryBalance, customerName: name);
    }
    if (_hasWord(words, _payment)) {
      return ParsedUtterance(Intent.recordPayment, customerName: name, amount: amount);
    }
    if (_hasWord(words, _credit)) {
      return ParsedUtterance(Intent.addCredit, customerName: name, amount: amount);
    }
    return const ParsedUtterance(Intent.unknown);
  }

  static bool _hasWord(List<String> words, Set<String> keys) =>
      words.any(keys.contains);

  static String? _guessName(List<String> words) {
    final skip = {..._credit, ..._payment, ..._query, ..._stop, ..._correctionStart};
    for (final w in words) {
      if (skip.contains(w) || NumberNormalizer.parse(w) != null) continue;
      if (RegExp(r'^[a-z\u0900-\u097F\u0C80-\u0CFF\u0C00-\u0C7F\u0B80-\u0BFF]+$').hasMatch(w)) {
        return w[0].toUpperCase() + w.substring(1);
      }
    }
    return null;
  }
}