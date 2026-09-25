import 'dart:convert';
import 'dart:typed_data';

/// Byte → character decoding for documents that are not valid UTF-8.
///
/// Covers the encodings a document can realistically carry without a network
/// round-trip: BOM-marked UTF-8 / UTF-16, strict UTF-8, and the two Windows
/// code pages the RTF and legacy text paths actually declare
/// (1256 – Windows Arabic, 1252 – Windows Latin‑1).
abstract final class DocumentByteDecoder {
  /// Windows-1252 specials for `0x80`–`0x9F`; `0xA0`–`0xFF` equal Latin-1.
  static const List<int> _cp1252High = [
    0x20AC, 0x0081, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
    0x02C6, 0x2030, 0x0160, 0x2039, 0x0152, 0x008D, 0x017D, 0x008F, //
    0x0090, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, //
    0x02DC, 0x2122, 0x0161, 0x203A, 0x0153, 0x009D, 0x017E, 0x0178,
  ];

  /// Windows-1256 mapping for `0x80`–`0xFF` (index `byte - 0x80`).
  static const List<int> _cp1256 = [
    0x20AC, 0x067E, 0x201A, 0x0192, 0x201E, 0x2026, 0x2020, 0x2021, //
    0x02C6, 0x2030, 0x0679, 0x2039, 0x0152, 0x0686, 0x0698, 0x0688, //
    0x06AF, 0x2018, 0x2019, 0x201C, 0x201D, 0x2022, 0x2013, 0x2014, //
    0x06A9, 0x2122, 0x0691, 0x203A, 0x0153, 0x200C, 0x200D, 0x06BA, //
    0x00A0, 0x060C, 0x00A2, 0x00A3, 0x00A4, 0x00A5, 0x00A6, 0x00A7, //
    0x00A8, 0x00A9, 0x06BE, 0x00AB, 0x00AC, 0x00AD, 0x00AE, 0x00AF, //
    0x00B0, 0x00B1, 0x00B2, 0x00B3, 0x00B4, 0x00B5, 0x00B6, 0x00B7, //
    0x00B8, 0x00B9, 0x061B, 0x00BB, 0x00BC, 0x00BD, 0x00BE, 0x061F, //
    0x06C1, 0x0621, 0x0622, 0x0623, 0x0624, 0x0625, 0x0626, 0x0627, //
    0x0628, 0x0629, 0x062A, 0x062B, 0x062C, 0x062D, 0x062E, 0x062F, //
    0x0630, 0x0631, 0x0632, 0x0633, 0x0634, 0x0635, 0x0636, 0x00D7, //
    0x0637, 0x0638, 0x0639, 0x063A, 0x0640, 0x0641, 0x0642, 0x0643, //
    0x00E0, 0x0644, 0x00E2, 0x0645, 0x0646, 0x0647, 0x0648, 0x00E7, //
    0x00E8, 0x00E9, 0x00EA, 0x00EB, 0x0649, 0x064A, 0x00EE, 0x00EF, //
    0x064B, 0x064C, 0x064D, 0x064E, 0x00F4, 0x064F, 0x0650, 0x00F7, //
    0x0651, 0x00F9, 0x0652, 0x00FB, 0x00FC, 0x200E, 0x200F, 0x06D2,
  ];

  static const int cp1252 = 1252;
  static const int cp1256 = 1256;
  static const int utf8CodePage = 65001;

  /// Decodes [bytes] using the Windows code page [codePage].
  ///
  /// Unknown code pages fall back to Windows‑1252.
  static String decodeWithCodePage(Uint8List bytes, int codePage) {
    if (codePage == utf8CodePage) {
      return utf8.decode(bytes, allowMalformed: true);
    }
    final arabic = codePage == cp1256;
    final buffer = StringBuffer();
    for (final byte in bytes) {
      if (byte < 0x80) {
        buffer.writeCharCode(byte);
      } else if (arabic) {
        buffer.writeCharCode(_cp1256[byte - 0x80]);
      } else if (byte < 0xA0) {
        buffer.writeCharCode(_cp1252High[byte - 0x80]);
      } else {
        buffer.writeCharCode(byte);
      }
    }
    return buffer.toString();
  }

  /// Decodes [bytes] honouring BOMs, UTF-8 and finally a heuristic ANSI
  /// fallback (1256 when the bytes decode to Arabic, 1252 otherwise).
  static String decodeAuto(Uint8List bytes) {
    if (bytes.isEmpty) return '';

    // BOM sniffing.
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      return _decodeUtf16(bytes, littleEndian: true);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      return _decodeUtf16(bytes, littleEndian: false);
    }

    try {
      return utf8.decode(bytes);
    } on FormatException {
      final arabic = decodeWithCodePage(bytes, cp1256);
      if (_arabicRatio(arabic) >= 0.3) return arabic;
      return decodeWithCodePage(bytes, cp1252);
    }
  }

  /// Fraction of non-whitespace Latin/Arabic script letters that are Arabic.
  static double _arabicRatio(String value) {
    var letters = 0;
    var arabic = 0;
    for (final unit in value.runes) {
      if (_isArabicLetter(unit)) {
        arabic++;
        letters++;
      } else if (_isLatinLetter(unit)) {
        letters++;
      }
    }
    if (letters == 0) return 0;
    return arabic / letters;
  }

  /// `true` for the Arabic and Arabic Supplement / Extended-A blocks.
  static bool _isArabicLetter(int rune) {
    return (rune >= 0x0600 && rune <= 0x06FF) ||
        (rune >= 0x0750 && rune <= 0x077F) ||
        (rune >= 0x08A0 && rune <= 0x08FF);
  }

  static bool _isLatinLetter(int rune) =>
      (rune >= 0x41 && rune <= 0x5A) || (rune >= 0x61 && rune <= 0x7A);

  static String _decodeUtf16(Uint8List bytes, {required bool littleEndian}) {
    final units = <int>[];
    // Index 0 and 1 hold the BOM itself.
    for (var i = 2; i + 1 < bytes.length; i += 2) {
      units.add(littleEndian
          ? bytes[i] | (bytes[i + 1] << 8)
          : (bytes[i] << 8) | bytes[i + 1]);
    }
    return String.fromCharCodes(units);
  }
}
