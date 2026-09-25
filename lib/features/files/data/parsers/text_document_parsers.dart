import 'dart:typed_data';

import '../../domain/entities/extraction_result.dart';
import '../../domain/entities/file_import_error.dart';
import 'byte_text_decoder.dart';
import 'document_parser.dart';

/// TXT / CSV / LOG / MD: bytes → text with encoding sniffing.
class PlainTextParser implements DocumentParser {
  const PlainTextParser();

  @override
  Set<String> get extensions => const {'txt', 'csv', 'log', 'md'};

  @override
  ExtractionResult parse({
    required String extension,
    required Uint8List bytes,
  }) {
    try {
      final raw = DocumentByteDecoder.decodeAuto(bytes);
      return ExtractionResult(text: normalizeExtractedText(raw));
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.extractionFailed,
        'text decode failed: $error',
      );
    }
  }
}

/// HTML / RTF: markup is stripped, real content is kept.
class MarkupDocumentParser implements DocumentParser {
  const MarkupDocumentParser();

  @override
  Set<String> get extensions => const {'html', 'htm', 'rtf'};

  @override
  ExtractionResult parse({
    required String extension,
    required Uint8List bytes,
  }) {
    try {
      final raw = DocumentByteDecoder.decodeAuto(bytes);
      final text = extension == 'rtf' ? rtfToText(raw) : htmlToText(raw);
      return ExtractionResult(text: normalizeExtractedText(text));
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.extractionFailed,
        '$extension parse failed: $error',
      );
    }
  }
}

// ---------------------------------------------------------------------------
// HTML
// ---------------------------------------------------------------------------

/// Turns an HTML document into readable plain text.
String htmlToText(String source) {
  var value = source.replaceAllMapped(
    RegExp(r'<!--.*?-->', dotAll: true),
    (_) => ' ',
  );
  value = value.replaceAllMapped(
    RegExp(r'<(script|style)\b.*?</\1\s*>', caseSensitive: false, dotAll: true),
    (_) => ' ',
  );
  value = value.replaceAllMapped(
    RegExp(
      r'</?(?:p|div|br|tr|li|h[1-6]|section|article|aside|header|footer|'
      r'blockquote|table|thead|tbody|tfoot|ul|ol|dl|dt|dd|figure|nav)\b[^>]*>',
      caseSensitive: false,
    ),
    (_) => '\n',
  );
  value = value.replaceAllMapped(RegExp(r'<[^>]+>'), (_) => ' ');
  value = decodeHtmlEntities(value);
  value = value.replaceAll('\u00A0', ' ');
  return value;
}

const Map<String, String> _namedEntities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': '\u00A0',
  'mdash': '\u2014',
  'ndash': '\u2013',
  'hellip': '\u2026',
  'lsquo': '\u2018',
  'rsquo': '\u2019',
  'ldquo': '\u201C',
  'rdquo': '\u201D',
  'copy': '\u00A9',
  'reg': '\u00AE',
  'trade': '\u2122',
  'deg': '\u00B0',
  'plusmn': '\u00B1',
  'frac12': '\u00BD',
  'laquo': '\u00AB',
  'raquo': '\u00BB',
  'bull': '\u2022',
  'middot': '\u00B7',
  'sect': '\u00A7',
  'para': '\u00B6',
  'euro': '\u20AC',
  'pound': '\u00A3',
  'yen': '\u00A5',
  'cent': '\u00A2',
  'times': '\u00D7',
  'divide': '\u00F7',
};

/// Resolves named, decimal and hexadecimal HTML entities.
String decodeHtmlEntities(String value) {
  return value.replaceAllMapped(
    RegExp(r'&(?:#x([0-9a-fA-F]+)|#(\d+)|([a-zA-Z]+));'),
    (match) {
      final hex = match[1];
      final dec = match[2];
      final named = match[3];
      if (hex != null) {
        final code = int.tryParse(hex, radix: 16);
        return code == null ? match[0]! : String.fromCharCode(code);
      }
      if (dec != null) {
        final code = int.tryParse(dec);
        return code == null ? match[0]! : String.fromCharCode(code);
      }
      return _namedEntities[named!.toLowerCase()] ?? match[0]!;
    },
  );
}

// ---------------------------------------------------------------------------
// RTF
// ---------------------------------------------------------------------------

const Set<String> _rtfSkipDestinations = {
  'fonttbl',
  'stylesheet',
  'colortbl',
  'info',
  'pict',
  'listtable',
  'listoverridetable',
  'revtbl',
  'themedata',
  'colorschememapping',
  'datastore',
  'latentstyles',
  'rsids',
  'generator',
  'xmlnstbl',
  'nonshppict',
  'shppict',
  'header',
  'footer',
  'headerl',
  'headerr',
  'headerf',
  'footerl',
  'footerr',
  'footerf',
};

const Map<String, String> _rtfWordOutput = {
  'par': '\n',
  'sect': '\n',
  'page': '\n',
  'line': '\n',
  'row': '\n',
  'cell': '\t',
  'nestcell': '\t',
  'tab': '\t',
  'emspace': ' ',
  'enspace': ' ',
  'qmspace': ' ',
  'lquote': '\u2018',
  'rquote': '\u2019',
  'ldblquote': '\u201C',
  'rdblquote': '\u201D',
  'bullet': '\u2022',
  'emdash': '\u2014',
  'endash': '\u2013',
};

/// Minimal but honest RTF tokenizer: groups, suppressed destinations,
/// control words, `\uNNNN` escapes and `\'XX` code-page escapes are handled.
String rtfToText(String source) {
  final codePage = ansiCodePageOf(source);
  final buffer = StringBuffer();
  final skipStack = <bool>[];
  var uc = 1;
  var index = 0;
  final length = source.length;

  bool skipping() => skipStack.isNotEmpty && skipStack.last;

  void write(String value) {
    if (!skipping()) buffer.write(value);
  }

  while (index < length) {
    final char = source[index];

    if (char == '\\' && index + 1 < length) {
      index = _consumeControl(
        source,
        index,
        codePage: codePage,
        uc: uc,
        onUc: (value) => uc = value,
        write: write,
        skip: skipping(),
      );
      continue;
    }

    if (char == '{') {
      final inherited = skipping();
      skipStack.add(inherited || _isSkipDestination(source, index));
      index++;
      continue;
    }
    if (char == '}') {
      if (skipStack.isNotEmpty) skipStack.removeLast();
      index++;
      continue;
    }

    write(char);
    index++;
  }

  return buffer.toString();
}

/// Consumes the control sequence starting at [start] (`\`) and returns the
/// next index to read.
int _consumeControl(
  String source,
  int start, {
  required int codePage,
  required int uc,
  required void Function(int) onUc,
  required void Function(String) write,
  required bool skip,
}) {
  final length = source.length;
  final next = source[start + 1];

  if (next == '\\' || next == '{' || next == '}') {
    if (!skip) write(next);
    return start + 2;
  }

  if (next == "'") {
    if (!skip && start + 3 < length) {
      final byte =
          int.tryParse(source.substring(start + 2, start + 4), radix: 16);
      if (byte != null) {
        write(
          DocumentByteDecoder.decodeWithCodePage(
            Uint8List.fromList(<int>[byte]),
            codePage,
          ),
        );
      }
    }
    return start + 4;
  }

  if (next == '*') return start + 2;

  var cursor = start + 1;
  final wordStart = cursor;
  while (cursor < length && _isAsciiLetter(source[cursor])) {
    cursor++;
  }
  final word = source.substring(wordStart, cursor);

  var number = '';
  if (cursor < length &&
      (source[cursor] == '-' || _isAsciiDigit(source[cursor]))) {
    final negative = source[cursor] == '-';
    if (negative) cursor++;
    final digitsStart = cursor;
    while (cursor < length && _isAsciiDigit(source[cursor])) {
      cursor++;
    }
    number = source.substring(digitsStart, cursor);
    if (negative) number = '-$number';
  }
  if (cursor < length && source[cursor] == ' ') cursor++;

  if (word == 'u' && number.isNotEmpty) {
    if (!skip) {
      var code = int.tryParse(number) ?? 0;
      if (code < 0) code += 0x10000;
      if (code > 0 && code <= 0x10FFFF) write(String.fromCharCode(code));
    }
    return _skipFallbackChar(source, cursor, uc);
  }

  if (word == 'bin') {
    final count = int.tryParse(number) ?? 0;
    return (cursor + count).clamp(0, length);
  }

  if (word == 'uc') {
    onUc(int.tryParse(number) ?? 1);
    return cursor;
  }

  final replacement = _rtfWordOutput[word];
  if (replacement != null) write(replacement);
  return cursor;
}

/// True when the group opening at [openBrace] is a suppressed destination
/// (`\*` or one of [_rtfSkipDestinations]).
bool _isSkipDestination(String source, int openBrace) {
  var cursor = openBrace + 1;
  if (cursor >= source.length || source[cursor] != '\\') return false;
  cursor++;
  if (cursor < source.length && source[cursor] == '*') return true;
  final start = cursor;
  while (cursor < source.length && _isAsciiLetter(source[cursor])) {
    cursor++;
  }
  return _rtfSkipDestinations.contains(source.substring(start, cursor));
}

/// Skips the [uc] fallback characters that follow a `\uNNNN` escape.
int _skipFallbackChar(String source, int cursor, int uc) {
  var position = cursor;
  for (var count = 0; count < uc && position < source.length; count++) {
    if (source[position] == '\\') {
      if (position + 1 < source.length && source[position + 1] == "'") {
        position += 4;
      } else {
        position += 2;
        while (position < source.length && _isAsciiLetter(source[position])) {
          position++;
        }
        while (position < source.length && _isAsciiDigit(source[position])) {
          position++;
        }
        if (position < source.length && source[position] == ' ') position++;
      }
    } else {
      position++;
    }
  }
  return position;
}

/// Reads `\ansicpgN` from an RTF header; defaults to Windows‑1252.
int ansiCodePageOf(String source) {
  final match = RegExp(r'\\ansicpg(\d+)').firstMatch(source);
  if (match == null) return DocumentByteDecoder.cp1252;
  return int.tryParse(match.group(1)!) ?? DocumentByteDecoder.cp1252;
}

bool _isAsciiLetter(String value) {
  final code = value.codeUnitAt(0);
  return (code >= 0x41 && code <= 0x5A) || (code >= 0x61 && code <= 0x7A);
}

bool _isAsciiDigit(String value) {
  final code = value.codeUnitAt(0);
  return code >= 0x30 && code <= 0x39;
}

// ---------------------------------------------------------------------------
// Shared
// ---------------------------------------------------------------------------

/// Collapses blank-line runs and trims trailing spaces so downstream
/// consumers (and the language detector) see clean text.
String normalizeExtractedText(String value) {
  final singleBreaks = value.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
  final trimmedLines =
      singleBreaks.split('\n').map((line) => line.trimRight()).join('\n');
  return trimmedLines.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}
