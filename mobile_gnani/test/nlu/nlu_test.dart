import 'package:flutter_test/flutter_test.dart';
import 'package:bolkhata/voice/nlu/number_normalizer.dart';
import 'package:bolkhata/voice/nlu/intent_parser.dart';

void main() {
  test('numbers', () {
    expect(NumberNormalizer.parse('teen sau chalees'), 340);
    expect(NumberNormalizer.parse('₹430'), 430);
    expect(NumberNormalizer.parse('do hazaar paanch sau'), 2500);
  });

  test('intents', () {
    final r = IntentParser.parse('Ramesh ne 340 udhaar liya');
    expect(r.intent, Intent.addCredit);
    expect(r.customerName, 'Ramesh');
    expect(r.amount, 340);
    expect(IntentParser.parse('nahi 430').intent, Intent.correction);
  });
}
