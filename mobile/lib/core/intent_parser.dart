// Rule-based intent parser for BolKhata. Pure Dart: no Flutter imports.
// The enum is called LedgerIntent (NOT Intent) because Flutter already has
// a class called Intent.

import 'number_normalizer.dart';

enum LedgerIntent {
  addCredit, // customer took goods/money on credit -> balance goes UP
  recordPayment, // customer paid the shop -> balance goes DOWN
  queryBalance, // "Ramesh ka balance kitna"
  correction, // "nahi 430" -> replace pending amount
  yes, // "haan" -> confirm
  no, // "nahi" / "cancel" -> cancel
  unknown,
}

class ParsedUtterance {
  final LedgerIntent intent;
  final String? customerName;
  final int? amount;
  final String rawText;

  const ParsedUtterance(
    this.intent, {
    this.customerName,
    this.amount,
    this.rawText = '',
  });

  @override
  String toString() => 'ParsedUtterance($intent, $customerName, $amount)';
}

class IntentParser {
  // Keywords match a token exactly, OR as a prefix when the keyword has
  // 3+ characters (so 'ಕೊಟ್ಟ' matches 'ಕೊಟ್ಟರು').
  static const Set<String> creditWords = <String>{
    // Hinglish
    'udhaar', 'udhar', 'udhari', 'credit', 'liya', 'liye', 'le', 'lekar',
    'likh', 'likho', 'khate', 'khata', 'baaki', 'baki',
    // English
    'took', 'borrowed', 'owes',
    // Devanagari
    'उधार', 'उधारी', 'लिया', 'लिए', 'लिये', 'ले', 'लिख', 'लिखो', 'खाते',
    'खाता', 'बाकी',
    // Kannada (VERIFY)
    'saala', 'tagond', 'ಸಾಲ', 'ತಗೊಂಡ', 'ತೆಗೆದುಕೊಂಡ',
    // Telugu (VERIFY)
    'appu', 'teesukunn', 'అప్పు', 'తీసుకున్న',
    // Tamil (VERIFY)
    'kadan', 'vaangin', 'கடன்', 'வாங்கின',
  };

  static const Set<String> paymentWords = <String>{
    // Hinglish
    'diya', 'diye', 'de', 'jama', 'chukaya', 'chuka', 'wapas', 'waapas',
    'mila', 'mile',
    // English
    'paid', 'payment', 'returned', 'gave', 'deposited',
    // Devanagari
    'दिया', 'दिए', 'दिये', 'जमा', 'चुकाया', 'चुकाए', 'वापस', 'मिला', 'मिले',
    // Kannada (VERIFY)
    'kotta', 'ಕೊಟ್ಟ', 'ಪಾವತಿ', 'ಜಮಾ',
    // Telugu (VERIFY)
    'ichcha', 'chellinch', 'ఇచ్చా', 'ఇచ్చి', 'చెల్లించ',
    // Tamil (VERIFY)
    'koduth', 'kattin', 'கொடுத்த', 'செலுத்தின',
  };

  static const Set<String> queryWords = <String>{
    'balance', 'kitna', 'kitne', 'kitni', 'bakaya', 'hisab', 'hisaab',
    'outstanding', 'owe', 'much',
    'बैलेंस', 'कितना', 'कितने', 'कितनी', 'बकाया', 'हिसाब', 'बाकी',
    'baaki', 'baki',
    'eshtu', 'ಎಷ್ಟು', 'ಬಾಕಿ',
    'entha', 'ఎంత', 'బాకీ',
    'evvalavu', 'baakki', 'எவ்வளவு', 'பாக்கி',
  };

  // yes/no are matched EXACTLY (no prefix), so names like "Sarita" never match "sari".
  static const Set<String> yesWords = <String>{
    'haan', 'haa', 'ha', 'han', 'hanji', 'yes', 'yeah', 'yep', 'ok', 'okay',
    'theek', 'thik', 'sahi', 'save', 'confirm',
    'हाँ', 'हां', 'हा', 'ठीक', 'सही',
    'houdu', 'haudu', 'sari', 'ಹೌದು', 'ಸರಿ',
    'avunu', 'sare', 'అవును', 'సరే',
    'aamaa', 'aama', 'seri', 'ஆமா', 'ஆம்', 'சரி',
  };

  static const Set<String> noWords = <String>{
    'nahi', 'nahin', 'nai', 'na', 'no', 'nope', 'cancel', 'mat', 'galat',
    'rehne', 'ruko',
    'नहीं', 'नही', 'ना', 'मत', 'गलत', 'रहने',
    'illa', 'beda', 'ಇಲ್ಲ', 'ಬೇಡ',
    'kaadu', 'vaddu', 'కాదు', 'వద్దు',
    'illai', 'venam', 'vendam', 'இல்லை', 'வேண்டாம்',
  };

  /// Hindi postpositions. The word BEFORE one of these is usually the name.
  static const Set<String> particles = <String>{
    'ne', 'se', 'ko', 'ka', 'ki', 'ke', 'ने', 'से', 'को', 'का', 'की', 'के',
  };

  static const Set<String> stopWords = <String>{
    'rupees', 'rupee', 'rupaye', 'rupaiye', 'rupay', 'rs', 'ru', 'inr',
    'aaj', 'kal', 'abhi', 'today', 'yesterday', 'now',
    'the', 'a', 'an', 'is', 'was', 'of', 'on', 'for', 'to', 'from', 'did',
    'does', 'how', 'has', 'have', 'i', 'me', 'my', 'mujhe', 'maine',
    'hai', 'tha', 'thi', 'hain', 'ji', 'wala', 'wale', 'total', 'kul',
    'sab', 'sabka', 'mein', 'please', 'saman', 'samaan', 'kiye', 'kiya',
    'gaya', 'gaye', 'sir', 'bhai', 'bhaiya', 'didi', 'aunty', 'uncle',
    'रुपये', 'रुपए', 'रुपया', 'आज', 'कल', 'अभी', 'है', 'था', 'थी', 'जी',
    'में', 'कुल', 'सामान', 'किए', 'किये', 'किया', 'गया', 'भाई',
    'ರೂಪಾಯಿ', 'రూపాయలు', 'ரூபாய்',
  };

  static final RegExp _letters =
      RegExp(r'^[\p{L}\p{M}‌‍]+$', unicode: true);

  static bool _matches(String token, Set<String> words) {
    if (words.contains(token)) return true;
    for (final w in words) {
      if (_allowsPrefix(w) && token.startsWith(w)) return true;
    }
    return false;
  }

  /// Prefix matching is needed for Kannada/Telugu/Tamil verb endings
  /// (ಕೊಟ್ಟ -> ಕೊಟ್ಟರು) and long Latin stems (tagond -> tagondru).
  /// Short Latin and Devanagari keywords match EXACTLY, so names like
  /// "Jamal" / "जमाल" are not mistaken for "jama" / "जमा".
  static bool _allowsPrefix(String w) {
    final r = w.runes.first;
    final isDravidian = r >= 0x0B80 && r <= 0x0CFF;
    if (isDravidian) return w.runes.length >= 3;
    final isAscii = r < 0x80;
    return isAscii && w.length >= 5;
  }

  static ParsedUtterance parse(String text) {
    final tokens = NumberNormalizer.tokenize(text);
    if (tokens.isEmpty) return ParsedUtterance(LedgerIntent.unknown, rawText: text);

    final amount = NumberNormalizer.parse(text);
    final first = tokens.first;

    // 1. "nahi 430" = correction; "nahi" / "cancel" = no.
    if (noWords.contains(first)) {
      if (amount != null) {
        return ParsedUtterance(LedgerIntent.correction, amount: amount, rawText: text);
      }
      if (tokens.length <= 3) return ParsedUtterance(LedgerIntent.no, rawText: text);
    }

    // 2. "haan" / "haan save karo" = yes.
    if (amount == null && tokens.length <= 3 && yesWords.contains(first)) {
      return ParsedUtterance(LedgerIntent.yes, rawText: text);
    }

    final name = _guessName(tokens);
    final hasQuery = tokens.any((t) => _matches(t, queryWords));
    final hasPayment = tokens.any((t) => _matches(t, paymentWords));
    final hasCredit = tokens.any((t) => _matches(t, creditWords));
    final hasSe = tokens.any((t) => t == 'se' || t == 'से');
    final hasKo = tokens.any((t) => t == 'ko' || t == 'को');
    final hasJama = tokens.any((t) => t == 'jama' || t == 'जमा');
    const receiveVerbs = {'liya', 'liye', 'लिया', 'लिए', 'लिये', 'mila', 'mile', 'मिला', 'मिले'};
    const giveVerbs = {'diya', 'diye', 'de', 'दिया', 'दिए', 'दिये'};
    final hasReceive = tokens.any(receiveVerbs.contains);
    final hasGive = tokens.any(giveVerbs.contains);

    // 3. Balance question (only when no amount was said).
    if (hasQuery && amount == null) {
      return ParsedUtterance(LedgerIntent.queryBalance, customerName: name, rawText: text);
    }
    // 4. "Ramesh SE 200 liya/mila" = shop received money = payment.
    if (hasSe && hasReceive) {
      return ParsedUtterance(LedgerIntent.recordPayment,
          customerName: name, amount: amount, rawText: text);
    }
    // 5. "Ramesh KO 150 ka saman diya" = shop gave goods = credit.
    if (hasKo && hasGive && !hasJama) {
      return ParsedUtterance(LedgerIntent.addCredit,
          customerName: name, amount: amount, rawText: text);
    }
    // 6. Plain keywords. Payment is checked before credit.
    if (hasPayment) {
      return ParsedUtterance(LedgerIntent.recordPayment,
          customerName: name, amount: amount, rawText: text);
    }
    if (hasCredit) {
      return ParsedUtterance(LedgerIntent.addCredit,
          customerName: name, amount: amount, rawText: text);
    }
    // 7. Unknown, but keep name/amount (the session may ask "credit or payment?").
    return ParsedUtterance(LedgerIntent.unknown,
        customerName: name, amount: amount, rawText: text);
  }

  static bool _isNameCandidate(String w) =>
      w.runes.length >= 2 &&
      _letters.hasMatch(w) &&
      !stopWords.contains(w) &&
      !particles.contains(w) &&
      !yesWords.contains(w) &&
      !noWords.contains(w) &&
      !NumberNormalizer.isNumberWord(w) &&
      !_matches(w, creditWords) &&
      !_matches(w, paymentWords) &&
      !_matches(w, queryWords);

  static String? _guessName(List<String> tokens) {
    // Prefer the word right before ne/se/ko/ka/ki/ke (skipping "ji", "bhai").
    for (var i = 1; i < tokens.length; i++) {
      if (!particles.contains(tokens[i])) continue;
      var j = i - 1;
      while (j >= 0 && stopWords.contains(tokens[j])) {
        j--;
      }
      if (j >= 0 && _isNameCandidate(tokens[j])) return _titleCase(tokens[j]);
    }
    // Otherwise the first word that looks like a name.
    for (final t in tokens) {
      if (_isNameCandidate(t)) return _titleCase(t);
    }
    return null;
  }

  static String _titleCase(String w) {
    final c = w.codeUnitAt(0);
    final isAsciiLower = c >= 0x61 && c <= 0x7A;
    return isAsciiLower ? w[0].toUpperCase() + w.substring(1) : w;
  }
}
