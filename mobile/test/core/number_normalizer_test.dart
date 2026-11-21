import 'package:flutter_test/flutter_test.dart';
import 'package:bolkhata/core/number_normalizer.dart';

void main() {
  final cases = <String, int?>{
    '340': 340,
    '₹430': 430,
    'Rs. 1,200': 1200,
    '430rs': 430,
    'teen sau chalees': 340,
    'do hazaar paanch sau': 2500,
    'dedh sau': 150,
    'dhai sau': 250,
    'saade teen sau': 350,
    'paune do sau': 175,
    'ek lakh': 100000,
    '2 hazaar 500': 2500,
    'three hundred and forty': 340,
    'two thousand five hundred': 2500,
    'तीन सौ चालीस': 340,
    'दो हज़ार': 2000,
    '३४०': 340,
    'Ramesh ne 340 udhaar liya': 340,
    '2 kilo chawal 120 rupaye': 120,
    'Ramesh': null,
    '': null,
  };

  cases.forEach((input, expected) {
    test('"$input" -> $expected', () {
      expect(NumberNormalizer.parse(input), expected);
    });
  });
}
