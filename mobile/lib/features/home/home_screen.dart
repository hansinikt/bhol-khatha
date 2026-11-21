import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../data/local/database.dart';
import '../../domain/usecases/ledger_service.dart';
import '../../voice/audio/recorder.dart';
import '../../voice/nlu/intent_parser.dart';
import '../../voice/stt/gnani_stt_provider.dart';
import '../../voice/stt/ondevice_stt_provider.dart';
import '../../voice/stt/stt_router.dart';
import '../../voice/voice_session_controller.dart';

class HomeScreen extends StatefulWidget {
  final AppDatabase db;
  const HomeScreen({super.key, required this.db});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _langs = {
    'en': 'English',
    'hi': 'हिन्दी',
    'kn': 'ಕನ್ನಡ',
    'te': 'తెలుగు',
    'ta': 'தமிழ்',
  };

  final _recorder = VoiceRecorder();
  final _session = VoiceSessionController();
  final _textCtrl = TextEditingController();
  late final LedgerService _ledger = LedgerService(widget.db);
  late final SttRouter _router = SttRouter(
    online: [GnaniSttProvider(apiKey: AppConfig.gnaniApiKey, baseUrl: AppConfig.gnaniBaseUrl)],
    offline: OnDeviceSttProvider(),
  );

  String _lang = 'hi';
  bool _recording = false;
  bool _busy = false;
  String _transcript = '';
  String _message = 'Hold the mic and speak';

  @override
  void dispose() {
    _recorder.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    final ok = await _recorder.start();
    if (!ok) {
      setState(() => _message = 'Microphone permission needed');
      return;
    }
    setState(() {
      _recording = true;
      _message = 'Listening...';
    });
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;
    setState(() {
      _recording = false;
      _busy = true;
      _message = 'Understanding...';
    });
    try {
      final audio = await _recorder.stop();
      if (audio == null || audio.isEmpty) throw Exception('No audio captured');
      final text = await _router.transcribe(audio, lang: _lang);
      await _handleText(text);
    } catch (e) {
      setState(() => _message = 'Could not understand: $e');
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _handleText(String text) async {
    _transcript = text;
    _session.onTranscript(text);

    if (_session.state == VoiceState.confirming &&
        _session.pending!.intent == Intent.queryBalance) {
      final name = _session.pending!.customerName!;
      final bal = await _ledger.balanceByName(name);
      _session.cancel();
      setState(() => _message =
          bal == null ? '$name not found' : '$name owes ₹$bal');
      return;
    }
    setState(() => _message = switch (_session.state) {
          VoiceState.clarifying => switch (_session.clarifyQuestion) {
              'amount' => 'How much? (speak the amount)',
              'name' => 'Which customer?',
              _ => 'Sorry, say that again',
            },
          VoiceState.confirming => 'Please confirm',
          _ => _message,
        });
  }

  Future<void> _confirm() async {
    final p = _session.confirm();
    if (p == null) return;
    final bal = await _ledger.save(p, lang: _lang);
    _session.cancel();
    setState(() => _message = 'Saved. ${p.customerName} balance: ₹$bal');
  }

  void _cancel() {
    _session.cancel();
    setState(() => _message = 'Cancelled');
  }

  String _describe(ParsedUtterance p) {
    final kind = p.intent == Intent.addCredit ? 'Credit given' : 'Payment received';
    return '${p.customerName}: $kind ₹${p.amount}';
  }

  @override
  Widget build(BuildContext context) {
    final confirming = _session.state == VoiceState.confirming;
    return Scaffold(
      appBar: AppBar(
        title: const Text('BolKhata'),
        actions: [
          DropdownButton<String>(
            value: _lang,
            underline: const SizedBox(),
            items: _langs.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _lang = v!),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_transcript.isNotEmpty)
              Text('"$_transcript"', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Text(_message, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
            if (confirming) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  title: Text(_describe(_session.pending!)),
                  subtitle: const Text('Say "nahi, 430" to correct the amount'),
                ),
              ),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: _cancel, child: const Text('Cancel'))),
                const SizedBox(width: 12),
                Expanded(child: FilledButton(onPressed: _confirm, child: const Text('Confirm'))),
              ]),
            ],
            const Spacer(),
            GestureDetector(
              onLongPressStart: (_) => _busy ? null : _startRecording(),
              onLongPressEnd: (_) => _stopRecording(),
              child: CircleAvatar(
                radius: 56,
                backgroundColor: _recording ? Colors.red : Theme.of(context).colorScheme.primary,
                child: _busy
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.mic, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: 24),
            // Testing without voice/Gnani: type what you would say.
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _textCtrl,
                  decoration: const InputDecoration(
                      hintText: 'Or type: Ramesh ne 340 udhaar liya',
                      border: OutlineInputBorder()),
                  onSubmitted: (v) {
                    if (v.trim().isEmpty) return;
                    _handleText(v);
                    _textCtrl.clear();
                  },
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}