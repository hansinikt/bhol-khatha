import 'package:flutter/material.dart';

import '../core/ledger_store.dart';
import '../core/models.dart';
import '../core/voice_session.dart';
import '../l10n/languages.dart';
import '../l10n/prompts.dart';
import '../voice/gnani_client.dart';
import '../voice/gnani_speech_input.dart';
import '../voice/speech_input.dart';
import '../voice/speech_output.dart';
import '../voice/voice_input.dart';
import 'customers_screen.dart';

class HomeScreen extends StatefulWidget {
  final LedgerStore store;

  const HomeScreen({super.key, required this.store});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final VoiceSession _session = VoiceSession(widget.store);
  // Gnani when the app is run with --dart-define=GNANI_API_KEY=..., else phone.
  static final GnaniClient? _gnani =
      GnaniConfig.enabled ? GnaniClient(GnaniConfig.apiKey) : null;
  final VoiceInput _phoneMic = SpeechInput();
  late final VoiceInput? _gnaniMic =
      _gnani == null ? null : GnaniSpeechInput(_gnani!);
  bool _useGnani = GnaniConfig.enabled;
  VoiceInput get _mic => (_useGnani ? _gnaniMic : null) ?? _phoneMic;
  final SpeechOutput _voice = SpeechOutput(gnani: _gnani);
  final TextEditingController _typed = TextEditingController();

  AppLanguage _lang = kLanguages.first;
  SessionReply? _reply;
  String _replyText = '';
  String _heard = '';
  bool _listening = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _voice.init();
  }

  @override
  void dispose() {
    _typed.dispose();
    _mic.stop();
    _voice.stop();
    super.dispose();
  }

  String _t(String key, [Map<String, String> args = const {}]) =>
      Prompts.render(_lang.code, key, args);

  Future<void> _show(SessionReply reply) async {
    final text = _t(reply.promptKey, reply.args);
    if (!mounted) return;
    setState(() {
      _reply = reply;
      _replyText = text;
    });
    await _voice.speak(text, _lang.ttsLocale);
  }

  Future<void> _submit(String text) async {
    final clean = text.trim();
    if (clean.isEmpty || _busy) return;
    _busy = true;
    try {
      setState(() => _heard = clean);
      final reply = await _session.handle(clean);
      await _show(reply);
    } finally {
      _busy = false;
    }
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      setState(() {
        _listening = false;
        _heard = '…'; // Gnani is uploading/transcribing
      });
      await _mic.stop(); // the final result arrives via onResult
      return;
    }
    await _voice.stop();
    setState(() {
      _listening = true;
      _heard = '';
    });
    var submitted = false;
    final mic = _mic;
    final ok = await mic.start(
      lang: _lang,
      onResult: (words, isFinal) {
        if (!mounted) return;
        setState(() => _heard = words);
        if (isFinal && !submitted) {
          submitted = true;
          setState(() => _listening = false);
          if (words.trim().isEmpty) {
            _showError(mic.lastError);
            _show(SessionReply('notUnderstood', stage: _session.stage));
          } else {
            _submit(words);
          }
        }
      },
      onDone: () {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (!ok && mounted) {
      setState(() => _listening = false);
      _showError(mic.lastError ?? _t('uiSttUnavailable'));
    }
  }

  void _showError(String? message) {
    if (message == null || message.isEmpty || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 6)),
    );
  }

  Future<void> _confirm() async => _show(await _session.confirm());

  Future<void> _cancel() async => _show(_session.cancel());

  void _sendTyped() {
    final v = _typed.text;
    _typed.clear();
    _submit(v);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pending =
        _reply?.stage == SessionStage.confirming ? _reply?.pending : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BolKhata'),
        actions: [
          // Tap to switch engine live (e.g. if venue network blocks Gnani).
          if (_gnaniMic != null)
            TextButton(
              onPressed: _listening
                  ? null
                  : () => setState(() => _useGnani = !_useGnani),
              child: Text(_mic.engineName),
            ),
          DropdownButton<AppLanguage>(
            value: _lang,
            underline: const SizedBox.shrink(),
            items: [
              for (final l in kLanguages)
                DropdownMenuItem(value: l, child: Text(l.label)),
            ],
            onChanged: (l) {
              if (l != null) setState(() => _lang = l);
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            tooltip: _t('uiCustomers'),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    CustomersScreen(store: widget.store, langCode: _lang.code),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _replyText.isEmpty ? _t('uiExample') : _replyText,
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ),
              if (pending != null)
                _ConfirmCard(
                  pending: pending,
                  t: _t,
                  onSave: _confirm,
                  onCancel: _cancel,
                ),
              const SizedBox(height: 12),
              Text(
                _heard,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
              Center(
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: FloatingActionButton(
                    heroTag: 'mic',
                    shape: const CircleBorder(),
                    backgroundColor:
                        _listening ? Colors.red : theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    onPressed: _toggleMic,
                    child: Icon(_listening ? Icons.stop : Icons.mic, size: 52),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _listening ? _t('uiListening') : _t('uiTapToSpeak'),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _typed,
                      decoration: InputDecoration(
                        hintText: _t('uiTypeHint'),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _sendTyped(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendTyped,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmCard extends StatelessWidget {
  final PendingEntry pending;
  final String Function(String key, [Map<String, String> args]) t;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const _ConfirmCard({
    required this.pending,
    required this.t,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = pending.type == EntryType.credit;
    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(pending.customerName ?? '',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              isCredit ? t('uiCredit') : t('uiPayment'),
              style: TextStyle(
                color: isCredit ? Colors.red.shade700 : Colors.green.shade700,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '₹${pending.amount ?? 0}',
              style: theme.textTheme.displaySmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FilledButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.check),
                  label: Text(t('uiSave')),
                ),
                OutlinedButton.icon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.close),
                  label: Text(t('uiCancel')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
