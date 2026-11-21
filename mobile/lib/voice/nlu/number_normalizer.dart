class NumberNormalizer {
  static const _ones = <String, int>{
    'zero': 0,
    'ek': 1,
    'one': 1,
    'do': 2,
    'two': 2,
    'teen': 3,
    'three': 3,
    'char': 4,
    'chaar': 4,
    'four': 4,
    'paanch': 5,
    'five': 5,
    'chhe': 6,
    'six': 6,
    'saat': 7,
    'seven': 7,
    'aath': 8,
    'eight': 8,
    'nau': 9,
    'nine': 9,
    'das': 10,
    'ten': 10,
    'gyarah': 11,
    'eleven': 11,
    'barah': 12,
    'twelve': 12,
    'terah': 13,
    'chaudah': 14,
    'pandrah': 15,
    'solah': 16,
    'satrah': 17,
    'atharah': 18,
    'unnis': 19,
    'bees': 20,
    'twenty': 20,
    'chalees': 40,
    'chalis': 40,
  };

  static int? parse(String text) {
    final normalized = text.toLowerCase();
    final digits = RegExp(r'\d[\d,]*')
        .allMatches(normalized)
        .map((m) => m.group(0)!.replaceAll(',', ''))
        .toList();
    if (digits.isNotEmpty) {
      return int.tryParse(digits.join());
    }

    final words = normalized.split(RegExp(r'[^a-zA-Z\u0900-\u097F]+'));
    var total = 0;
    var section = 0;
    var found = false;
    for (final word in words) {
      final value = _ones[word];
      if (value != null) {
        found = true;
        section += value;
      } else if (word == 'sau' || word == 'hundred') {
        found = true;
        section = (section == 0 ? 1 : section) * 100;
      } else if (word == 'hazar' || word == 'hazaar' || word == 'thousand') {
        found = true;
        total += (section == 0 ? 1 : section) * 1000;
        section = 0;
      } else if (word == 'lakh' || word == 'lacs' || word == 'lakhh') {
        found = true;
        total += (section == 0 ? 1 : section) * 100000;
        section = 0;
      }
    }
    if (!found) return null;
    return total + section;
  }
}
