import 'package:flutter_test/flutter_test.dart';
import 'package:bolkhata/core/ledger_store.dart';
import 'package:bolkhata/core/voice_session.dart';

void main() {
  late LedgerStore store;
  late VoiceSession s;

  setUp(() {
    store = LedgerStore();
    s = VoiceSession(store);
  });

  test('P0 demo script: credit, correct, confirm, balance, payment', () async {
    var r = await s.handle('Ramesh ne 340 udhaar liya');
    expect(r.promptKey, 'confirmCreditNew');
    expect(r.args['amount'], '340');
    expect(store.entries, isEmpty, reason: 'nothing saved before confirm');

    r = await s.handle('nahi 430');
    expect(r.promptKey, 'confirmCreditNew');
    expect(r.args['amount'], '430');

    r = await s.handle('haan');
    expect(r.promptKey, 'saved');
    expect(r.savedNow, isTrue);
    expect(r.args['balance'], '430');

    r = await s.handle('Ramesh ka balance kitna');
    expect(r.promptKey, 'balanceIs');
    expect(r.args['balance'], '430');

    r = await s.handle('Ramesh se 100 mile');
    expect(r.promptKey, 'confirmPayment');
    r = await s.confirm();
    expect(r.promptKey, 'saved');
    expect(r.args['balance'], '330');
  });

  test('missing amount is asked for', () async {
    var r = await s.handle('Suresh ne udhaar liya');
    expect(r.promptKey, 'askAmount');
    expect(r.stage, SessionStage.askAmount);
    r = await s.handle('teen sau chalees');
    expect(r.promptKey, 'confirmCreditNew');
    expect(r.args['amount'], '340');
  });

  test('missing name is asked for', () async {
    var r = await s.handle('udhaar 200');
    expect(r.promptKey, 'askName');
    r = await s.handle('Mahesh');
    expect(r.promptKey, 'confirmCreditNew');
    expect(r.args['name'], 'Mahesh');
  });

  test('missing type is asked for', () async {
    var r = await s.handle('Ramesh 500');
    expect(r.promptKey, 'askType');
    r = await s.handle('udhaar');
    expect(r.promptKey, 'confirmCreditNew');
  });

  test('cancel never saves', () async {
    await s.handle('Ramesh ne 340 udhaar liya');
    final r = await s.handle('cancel');
    expect(r.promptKey, 'cancelled');
    expect(store.entries, isEmpty);
    expect(s.stage, SessionStage.idle);
  });

  test('existing customer gets confirmCredit (not New)', () async {
    await s.handle('Ramesh ne 100 udhaar liya');
    await s.confirm();
    final r = await s.handle('Ramesh ne 50 udhaar liya');
    expect(r.promptKey, 'confirmCredit');
  });

  test('total due when no name', () async {
    await s.handle('Ramesh ne 100 udhaar liya');
    await s.confirm();
    await s.handle('Suresh ne 250 udhaar liya');
    await s.confirm();
    final r = await s.handle('kitna baaki hai');
    expect(r.promptKey, 'totalDue');
    expect(r.args['amount'], '350');
  });

  test('unknown customer balance', () async {
    final r = await s.handle('Ganesh ka balance kitna');
    expect(r.promptKey, 'customerNotFound');
  });
}
