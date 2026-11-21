import 'package:flutter_test/flutter_test.dart';
import 'package:bolkhata/core/intent_parser.dart';

void check(String text, LedgerIntent intent, {String? name, int? amount}) {
  test(text, () {
    final r = IntentParser.parse(text);
    expect(r.intent, intent, reason: r.toString());
    if (name != null) expect(r.customerName, name, reason: r.toString());
    if (amount != null) expect(r.amount, amount, reason: r.toString());
  });
}

void main() {
  group('Hinglish', () {
    check('Ramesh ne 340 udhaar liya', LedgerIntent.addCredit, name: 'Ramesh', amount: 340);
    check('aaj Ramesh ne 50 udhaar liya', LedgerIntent.addCredit, name: 'Ramesh', amount: 50);
    check('Ramesh se 200 liya', LedgerIntent.recordPayment, name: 'Ramesh', amount: 200);
    check('Ramesh se 100 mile', LedgerIntent.recordPayment, name: 'Ramesh', amount: 100);
    check('Ramesh ko 150 ka saman diya', LedgerIntent.addCredit, name: 'Ramesh', amount: 150);
    check('Ramesh ne 200 jama kiye', LedgerIntent.recordPayment, name: 'Ramesh', amount: 200);
    check('Ramesh ka balance kitna', LedgerIntent.queryBalance, name: 'Ramesh');
    check('kitna baaki hai', LedgerIntent.queryBalance);
    check('nahi 430', LedgerIntent.correction, amount: 430);
    check('haan', LedgerIntent.yes);
    check('cancel', LedgerIntent.no);
    check('Ramesh 500', LedgerIntent.unknown, name: 'Ramesh', amount: 500);
  });

  group('English', () {
    check('Ramesh took 340 on credit', LedgerIntent.addCredit, name: 'Ramesh', amount: 340);
    check('Ramesh paid 200', LedgerIntent.recordPayment, name: 'Ramesh', amount: 200);
    check('How much does Ramesh owe', LedgerIntent.queryBalance, name: 'Ramesh');
    check('yes', LedgerIntent.yes);
  });

  group('Devanagari', () {
    check('रमेश ने 340 उधार लिया', LedgerIntent.addCredit, name: 'रमेश', amount: 340);
    check('रमेश ने 200 जमा किए', LedgerIntent.recordPayment, name: 'रमेश', amount: 200);
    check('रमेश का बाकी कितना है', LedgerIntent.queryBalance, name: 'रमेश');
    check('हाँ', LedgerIntent.yes);
  });

  group('Kannada / Telugu / Tamil (happy path)', () {
    check('ರಮೇಶ್ 300 ಸಾಲ ತಗೊಂಡರು', LedgerIntent.addCredit, name: 'ರಮೇಶ್', amount: 300);
    check('ರಮೇಶ್ 200 ಕೊಟ್ಟರು', LedgerIntent.recordPayment, name: 'ರಮೇಶ್', amount: 200);
    check('రమేష్ 340 అప్పు తీసుకున్నారు', LedgerIntent.addCredit, name: 'రమేష్', amount: 340);
    check('రమేష్ 200 ఇచ్చారు', LedgerIntent.recordPayment, name: 'రమేష్', amount: 200);
    check('ரமேஷ் 340 கடன் வாங்கினார்', LedgerIntent.addCredit, name: 'ரமேஷ்', amount: 340);
    check('ரமேஷ் 200 கொடுத்தார்', LedgerIntent.recordPayment, name: 'ரமேஷ்', amount: 200);
  });
}
