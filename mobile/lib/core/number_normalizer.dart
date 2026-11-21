// Finds the rupee amount in a spoken/typed sentence.
// Handles digits, Indian-script digits, Hindi/English number words,
// and dedh/dhai/saade/paune. Pure Dart: no Flutter imports.

import 'dart:math';

class NumberNormalizer {
  // Values for single words. Hindi words are listed WITHOUT nukta
  // because tokenize() strips nukta (ज़ -> ज, ढ़ -> ढ).
  static const Map<String, double> _units = <String, double>{
    // Hindi / Hinglish in Latin script
    'ek': 1, 'do': 2, 'teen': 3, 'char': 4, 'chaar': 4, 'paanch': 5,
    'panch': 5, 'chhe': 6, 'chhah': 6, 'saat': 7, 'aath': 8, 'nau': 9,
    'das': 10, 'gyarah': 11, 'barah': 12, 'baarah': 12, 'terah': 13,
    'chaudah': 14, 'pandrah': 15, 'solah': 16, 'satrah': 17,
    'atharah': 18, 'unnis': 19, 'bees': 20, 'pachchees': 25,
    'pachis': 25, 'tees': 30, 'chalees': 40, 'chalis': 40,
    'pachaas': 50, 'pachas': 50, 'sattar': 70, 'assi': 80, 'nabbe': 90,
    'dedh': 1.5, 'dhai': 2.5, 'dhaai': 2.5,
    // Hindi in Devanagari
    'एक': 1, 'दो': 2, 'तीन': 3, 'चार': 4, 'पांच': 5, 'पाँच': 5,
    'छह': 6, 'सात': 7, 'आठ': 8, 'नौ': 9, 'दस': 10, 'बीस': 20,
    'पच्चीस': 25, 'तीस': 30, 'चालीस': 40, 'पचास': 50, 'साठ': 60,
    'सत्तर': 70, 'अस्सी': 80, 'नब्बे': 90, 'डेढ': 1.5, 'ढाई': 2.5,
    // English
    'one': 1, 'two': 2, 'three': 3, 'four': 4, 'five': 5, 'six': 6,
    'seven': 7, 'eight': 8, 'nine': 9, 'ten': 10, 'eleven': 11,
    'twelve': 12, 'thirteen': 13, 'fourteen': 14, 'fifteen': 15,
    'sixteen': 16, 'seventeen': 17, 'eighteen': 18, 'nineteen': 19,
    'twenty': 20, 'thirty': 30, 'forty': 40, 'fifty': 50, 'sixty': 60,
    'seventy': 70, 'eighty': 80, 'ninety': 90,
  };

  static const Map<String, int> _multipliers = <String, int>{
    'sau': 100, 'sou': 100, 'सौ': 100, 'hundred': 100,
    'hazaar': 1000, 'hazar': 1000, 'hajar': 1000, 'हजार': 1000,
    'thousand': 1000,
    'lakh': 100000, 'lac': 100000, 'लाख': 100000,
    // Kannada / Telugu / Tamil (Latin + native script). VERIFY with native speakers.
    'nooru': 100, 'saavira': 1000, 'vanda': 100, 'veyyi': 1000,
    'aayiram': 1000,
    'ನೂರು': 100, 'ಸಾವಿರ': 1000, 'వంద': 100, 'వెయ్యి': 1000,
    'நூறு': 100, 'ஆயிரம்': 1000,
  };

  /// saade = +0.5 to the next number, paune = -0.25.
  static const Map<String, double> _modifiers = <String, double>{
    'saade': 0.5, 'sadhe': 0.5, 'साढे': 0.5,
    'paune': -0.25, 'पौने': -0.25,
  };

  static const Set<String> _connectors = <String>{'and', 'aur', 'और'};

  /// Indian-script digits -> ASCII digits (Devanagari, Kannada, Telugu, Tamil).
  static String normalizeDigits(String s) {
    const bases = [0x0966, 0x0CE6, 0x0C66, 0x0BE6];
    final b = StringBuffer();
    for (final r in s.runes) {
      int? digit;
      for (final base in bases) {
        if (r >= base && r <= base + 9) {
          digit = r - base;
          break;
        }
      }
      b.write(digit != null ? digit.toString() : String.fromCharCode(r));
    }
    return b.toString();
  }

  /// Lowercase, ASCII digits, no punctuation, no nukta, digits split from letters.
  static List<String> tokenize(String text) {
    var s = normalizeDigits(text.toLowerCase());
    s = s.replaceAllMapped(RegExp(r'(\d),(?=\d)'), (m) => m[1]!); // 1,200 -> 1200
    s = s
        .replaceAll('ज़', 'ज') // ज़ -> ज
        .replaceAll('ढ़', 'ढ') // ढ़ -> ढ
        .replaceAll('़', ''); // combining nukta
    s = s.replaceAll(RegExp(r'[₹,.?!।|:;"()\-]'), ' ');
    s = s.replaceAllMapped(RegExp(r'(\d)([^\d\s])'), (m) => '${m[1]} ${m[2]}');
    s = s.replaceAllMapped(RegExp(r'([^\d\s])(\d)'), (m) => '${m[1]} ${m[2]}');
    return s.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
  }

  static bool isNumberWord(String token) =>
      int.tryParse(token) != null ||
      _units.containsKey(token) ||
      _multipliers.containsKey(token) ||
      _modifiers.containsKey(token);

  /// Returns the amount in rupees, or null if there is none.
  /// If several numbers appear, returns the LARGEST
  /// ("2 kilo chawal 120 rupaye" -> 120).
  static int? parse(String text) {
    final tokens = tokenize(text);
    final found = <int>[];
    double total = 0;
    double current = 0;
    double adjust = 0;
    var inNumber = false;

    void flush() {
      if (inNumber) {
        final v = (total + current).round();
        if (v > 0) found.add(v);
      }
      total = 0;
      current = 0;
      adjust = 0;
      inNumber = false;
    }

    for (final t in tokens) {
      final digit = int.tryParse(t);
      final unit = digit?.toDouble() ?? _units[t];
      if (unit != null) {
        // "3 340" are two separate numbers.
        if (inNumber && digit != null && current != 0) flush();
        current += unit + adjust;
        adjust = 0;
        inNumber = true;
        continue;
      }
      final mod = _modifiers[t];
      if (mod != null) {
        adjust = mod;
        continue;
      }
      final mult = _multipliers[t];
      if (mult != null) {
        if (current == 0) current = 1; // "sau" alone = 100
        if (mult == 100) {
          current *= 100;
        } else {
          total += current * mult;
          current = 0;
        }
        adjust = 0;
        inNumber = true;
        continue;
      }
      if (inNumber && _connectors.contains(t)) continue;
      flush();
    }
    flush();
    if (found.isEmpty) return null;
    return found.reduce(max);
  }
}
