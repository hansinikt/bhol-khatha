// The 5 supported languages and the exact locale IDs each engine needs.
// speech_to_text uses underscore IDs (hi_IN); flutter_tts uses hyphen IDs (hi-IN).

class AppLanguage {
  final String code; // key used by Prompts: en, hi, kn, te, ta
  final String label; // shown in the language picker
  final String sttLocale; // speech_to_text localeId
  final String ttsLocale; // flutter_tts setLanguage()

  const AppLanguage(this.code, this.label, this.sttLocale, this.ttsLocale);
}

const List<AppLanguage> kLanguages = [
  AppLanguage('hi', 'हिन्दी', 'hi_IN', 'hi-IN'),
  AppLanguage('en', 'English', 'en_IN', 'en-IN'),
  AppLanguage('kn', 'ಕನ್ನಡ', 'kn_IN', 'kn-IN'),
  AppLanguage('te', 'తెలుగు', 'te_IN', 'te-IN'),
  AppLanguage('ta', 'தமிழ்', 'ta_IN', 'ta-IN'),
];
