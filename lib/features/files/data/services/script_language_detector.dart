import '../../../../core/config/file_engine_config.dart';
import '../../domain/entities/file_import_error.dart';
import '../../domain/language/detected_language.dart';
import '../../domain/services/language_detector.dart';

/// Offline, dependency-free language detection.
///
/// Strategy:
///  1. **Script pass** – Arabic, Devanagari and CJK blocks are unambiguous, so
///     they decide `ar`, `hi` and `zh` immediately.
///  2. **Stop-word pass** – for Latin-script text every supported language is
///     scored against its own stop-word list plus a small accent/character
///     bonus, and the best score wins when it clears
///     `FileEngineConfig.minLanguageConfidence`.
///  3. Anything unreliable returns [DetectedLanguage.unknown] rather than a
///     guess.
class ScriptLanguageDetector implements LanguageDetector {
  const ScriptLanguageDetector({this.config = FileEngineConfig.defaults});

  final FileEngineConfig config;

  @override
  DetectedLanguage detect(String text) {
    try {
      final trimmed = text.trim();
      if (trimmed.length < config.minLanguageSampleLength) {
        return DetectedLanguage.unknown;
      }

      final sample = _sample(trimmed);
      final counts = _countScripts(sample);

      final scriptTotal = counts.arabic +
          counts.devanagari +
          counts.cjk +
          counts.latin +
          counts.other;

      if (scriptTotal > 0) {
        if (counts.arabic > 0 && counts.arabic / scriptTotal >= 0.15) {
          return _confident('ar', counts.arabic / scriptTotal);
        }
        if (counts.devanagari > 0 && counts.devanagari / scriptTotal >= 0.15) {
          return _confident('hi', counts.devanagari / scriptTotal);
        }
        if (counts.cjk > 0 && counts.cjk / scriptTotal >= 0.15) {
          return _confident('zh', counts.cjk / scriptTotal);
        }
      }

      if (counts.latin == 0) return DetectedLanguage.unknown;

      final score = _scoreLatin(sample);
      if (score.best == null ||
          score.best!.confidence < config.minLanguageConfidence) {
        return DetectedLanguage(
          code: DetectedLanguage.unknownCode,
          confidence: score.best?.confidence ?? 0,
        );
      }
      return score.best!;
    } on FileImportException {
      rethrow;
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.languageDetectionFailed,
        '$error',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Sampling
  // ---------------------------------------------------------------------

  /// Head + middle + tail so a long document is judged on more than page one.
  static String _sample(String text) {
    const head = 3000;
    const tail = 1500;
    const middle = 1500;
    if (text.length <= head + middle + tail) return text;
    final midStart = (text.length ~/ 2) - (middle ~/ 2);
    final buffer = StringBuffer()
      ..write(text.substring(0, head))
      ..write(text.substring(midStart, midStart + middle))
      ..write(text.substring(text.length - tail));
    return buffer.toString();
  }

  // ---------------------------------------------------------------------
  // Script pass
  // ---------------------------------------------------------------------

  static _ScriptCounts _countScripts(String sample) {
    var arabic = 0;
    var devanagari = 0;
    var cjk = 0;
    var latin = 0;
    var other = 0;

    for (final rune in sample.runes) {
      if (_isArabic(rune)) {
        arabic++;
      } else if (rune >= 0x0900 && rune <= 0x097F) {
        devanagari++;
      } else if ((rune >= 0x4E00 && rune <= 0x9FFF) ||
          (rune >= 0x3400 && rune <= 0x4DBF)) {
        cjk++;
      } else if ((rune >= 0x41 && rune <= 0x5A) ||
          (rune >= 0x61 && rune <= 0x7A) ||
          (rune >= 0xC0 && rune <= 0x24F)) {
        latin++;
      } else if (_isLetter(rune)) {
        other++;
      }
    }
    return _ScriptCounts(
      arabic: arabic,
      devanagari: devanagari,
      cjk: cjk,
      latin: latin,
      other: other,
    );
  }

  static bool _isArabic(int rune) {
    return (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF) ||
        (rune >= 0xFB50 && rune <= 0xFDFF) ||
        (rune >= 0xFE70 && rune <= 0xFEFF);
  }

  static bool _isLetter(int rune) {
    if (_isArabic(rune)) return true;
    if (rune >= 0x0900 && rune <= 0x097F) return true;
    if ((rune >= 0x4E00 && rune <= 0x9FFF) ||
        (rune >= 0x3400 && rune <= 0x4DBF)) {
      return true;
    }
    return (rune >= 0x41 && rune <= 0x5A) ||
        (rune >= 0x61 && rune <= 0x7A) ||
        (rune >= 0xC0 && rune <= 0x24F);
  }

  static DetectedLanguage _confident(String code, double ratio) {
    // Script evidence is strong; never report a weaker number than "solid".
    return DetectedLanguage(
        code: code, confidence: ratio.clamp(0.6, 1.0).toDouble());
  }

  // ---------------------------------------------------------------------
  // Stop-word pass
  // ---------------------------------------------------------------------

  _LatinScore _scoreLatin(String sample) {
    final tokens = RegExp(r"[a-z\u00C0-\u024F']+")
        .allMatches(sample.toLowerCase())
        .map((match) => match.group(0)!)
        .where((token) => token.length > 1 || token == 'a' || token == 'i')
        .toList();

    if (tokens.isEmpty) return const _LatinScore(null);

    final total = tokens.length;
    DetectedLanguage? best;

    for (final entry in _stopWords.entries) {
      var hits = 0;
      for (final token in tokens) {
        if (entry.value.contains(token)) hits++;
      }
      final bonus = _hasMarker(sample, _markers[entry.key]) ? 0.10 : 0.0;
      final score = hits / total + bonus;
      if (best == null || score > best.confidence) {
        best = DetectedLanguage(code: entry.key, confidence: score);
      }
    }
    return _LatinScore(best);
  }

  static bool _hasMarker(String sample, Set<String>? markers) {
    if (markers == null || markers.isEmpty) return false;
    for (final rune in sample.runes) {
      if (markers.contains(String.fromCharCode(rune))) return true;
    }
    return false;
  }

  static const Map<String, Set<String>> _markers = {
    'en': {},
    'fr': {
      'à',
      'â',
      'æ',
      'ç',
      'é',
      'è',
      'ê',
      'ë',
      'î',
      'ï',
      'ô',
      'œ',
      'û',
      'ù',
      'ü',
      'ÿ',
      '\u2019'
    },
    'es': {'ñ', '¿', '¡', 'á', 'é', 'í', 'ó', 'ú', 'ü'},
    'de': {'ä', 'ö', 'ü', 'ß'},
    'tr': {'ğ', 'ı', 'ş', 'İ', 'Ç', 'Ö', 'Ü'},
    'it': {'à', 'è', 'é', 'ì', 'ò', 'ù'},
    'pt': {'ã', 'õ', 'ç', 'ê', 'ô', 'á', 'é', 'í', 'ó', 'ú', 'à'},
  };

  static const Map<String, Set<String>> _stopWords = {
    'en': {
      'the',
      'and',
      'of',
      'to',
      'in',
      'is',
      'that',
      'for',
      'it',
      'with',
      'as',
      'was',
      'on',
      'be',
      'at',
      'this',
      'by',
      'from',
      'but',
      'not',
      'are',
      'or',
      'an',
      'have',
      'has',
      'they',
      'you',
      'we',
      'she',
      'he',
      'will',
      'can',
      'all',
      'which',
      'there',
      'their',
      'been',
      'would',
      'when',
      'who',
      'what',
      'about',
      'into',
      'than',
      'then',
      'them',
      'its',
      'our',
      'your',
      'more',
      'some',
      'such',
      'only',
      'over',
    },
    'fr': {
      'le',
      'la',
      'les',
      'des',
      'une',
      'est',
      'pour',
      'avec',
      'dans',
      'que',
      'qui',
      'pas',
      'sur',
      'mais',
      'plus',
      'très',
      'nous',
      'vous',
      'ils',
      'ont',
      'été',
      'cette',
      'tout',
      'fait',
      'son',
      'ses',
      'par',
      'aux',
      'ces',
      'entre',
      'comme',
      'aussi',
      'leur',
      'sont',
      'être',
      'avoir',
      'deux',
      'même',
      'encore',
    },
    'es': {
      'el',
      'la',
      'los',
      'las',
      'una',
      'es',
      'por',
      'con',
      'del',
      'al',
      'que',
      'no',
      'se',
      'como',
      'más',
      'pero',
      'sus',
      'ya',
      'este',
      'sí',
      'porque',
      'esta',
      'entre',
      'cuando',
      'muy',
      'sin',
      'sobre',
      'también',
      'hasta',
      'hay',
      'donde',
      'quien',
      'desde',
      'todo',
      'nos',
      'durante',
      'todos',
      'uno',
      'les',
      'ni',
      'contra',
      'otros',
    },
    'de': {
      'der',
      'die',
      'das',
      'und',
      'ist',
      'ich',
      'nicht',
      'ein',
      'eine',
      'zu',
      'den',
      'mit',
      'auf',
      'für',
      'im',
      'dem',
      'sie',
      'von',
      'aus',
      'dass',
      'bei',
      'noch',
      'wie',
      'auch',
      'über',
      'nach',
      'wird',
      'kann',
      'gegen',
      'vom',
      'können',
      'nur',
      'oder',
      'aber',
      'bereits',
      'sehr',
      'schon',
      'wenn',
      'hat',
      'dann',
    },
    'tr': {
      've',
      'bir',
      'bu',
      'için',
      'ile',
      'çok',
      'da',
      'daha',
      'ama',
      'ne',
      'gibi',
      'olarak',
      'en',
      'ki',
      'veya',
      'tüm',
      'ya',
      'şu',
      'göre',
      'diye',
      'kadar',
      'sonra',
      'mi',
      'her',
      'yani',
      'oldu',
      'böyle',
      'ise',
      'hem',
      'değil',
    },
    'it': {
      'il',
      'lo',
      'la',
      'i',
      'gli',
      'le',
      'di',
      'che',
      'un',
      'una',
      'per',
      'con',
      'non',
      'sono',
      'del',
      'più',
      'anche',
      'questa',
      'tutto',
      'quando',
      'molto',
      'senza',
      'sulla',
      'dove',
      'come',
      'dopo',
      'prima',
      'già',
      'suo',
      'sua',
      'nelle',
      'degli',
      'questo',
      'ogni',
      'poi',
      'perché',
      'finché',
    },
    'pt': {
      'de',
      'que',
      'não',
      'uma',
      'os',
      'as',
      'com',
      'para',
      'mais',
      'por',
      'você',
      'mas',
      'já',
      'está',
      'são',
      'foi',
      'também',
      'até',
      'isso',
      'essa',
      'esse',
      'entre',
      'quando',
      'muito',
      'sem',
      'sobre',
      'tem',
      'ser',
      'seu',
      'sua',
      'dos',
      'como',
      'após',
      'onde',
      'cada',
      'pela',
      'melhor',
      'antes',
    },
  };
}

class _ScriptCounts {
  const _ScriptCounts({
    required this.arabic,
    required this.devanagari,
    required this.cjk,
    required this.latin,
    required this.other,
  });

  final int arabic;
  final int devanagari;
  final int cjk;
  final int latin;
  final int other;
}

class _LatinScore {
  const _LatinScore(this.best);

  final DetectedLanguage? best;
}
