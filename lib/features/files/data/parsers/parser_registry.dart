import 'dart:typed_data';

import '../../domain/entities/extraction_result.dart';
import '../../domain/entities/file_import_error.dart';
import 'document_parser.dart';
import 'ooxml_parser.dart';
import 'pdf_parser.dart';
import 'text_document_parsers.dart';

/// Extension → parser lookup (the Adapter/Parser layer of the File Engine).
///
/// Format knowledge lives here and in the [DocumentParser] implementations;
/// no service, controller or widget ever switches on a file extension.
class ParserRegistry {
  ParserRegistry({List<DocumentParser>? parsers})
      : _parsers = parsers ?? defaultParsers();

  final List<DocumentParser> _parsers;

  /// Production set: plain text, markup, OOXML, PDF and legacy Office.
  static List<DocumentParser> defaultParsers() => [
        const PlainTextParser(),
        const MarkupDocumentParser(),
        const OoxmlDocumentParser(),
        const PdfDocumentParser(),
        const LegacyOfficeParser(),
      ];

  /// Returns the parser claiming [extension] or `null`.
  DocumentParser? find(String extension) {
    final normalized = extension.toLowerCase();
    for (final parser in _parsers) {
      if (parser.extensions.contains(normalized)) return parser;
    }
    return null;
  }

  /// Extensions this registry knows how to route.
  Set<String> get knownExtensions =>
      _parsers.expand((parser) => parser.extensions).toSet();

  /// Extracts [bytes] or throws a typed [FileImportException].
  ///
  /// Unexpected parser crashes are normalised to
  /// [FileImportErrorKind.extractionFailed] so a `FormatException` from a
  /// third-party library never reaches the UI.
  ExtractionResult parse({
    required String extension,
    required Uint8List bytes,
  }) {
    final normalized = extension.toLowerCase();
    final parser = find(normalized);
    if (parser == null) {
      throw FileImportException(
        FileImportErrorKind.unsupportedFile,
        'no parser for .$normalized',
      );
    }
    try {
      return parser.parse(extension: normalized, bytes: bytes);
    } on FileImportException {
      rethrow;
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.extractionFailed,
        '.$normalized: $error',
      );
    }
  }
}
