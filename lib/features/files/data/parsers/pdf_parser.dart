import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../../domain/entities/extraction_result.dart';
import '../../domain/entities/file_import_error.dart';
import 'document_parser.dart';

/// PDF text extraction via Syncfusion's pure-Dart parser.
///
/// No native rendering and no network: the document is parsed in memory and
/// disposed immediately afterwards.
class PdfDocumentParser implements DocumentParser {
  const PdfDocumentParser();

  @override
  Set<String> get extensions => const {'pdf'};

  @override
  ExtractionResult parse({
    required String extension,
    required Uint8List bytes,
  }) {
    PdfDocument? document;
    try {
      document = PdfDocument(inputBytes: bytes);
      final pageCount = document.pages.count;
      final text = PdfTextExtractor(document).extractText();
      return ExtractionResult(text: text, pageCount: pageCount);
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.extractionFailed,
        'pdf: $error',
      );
    } finally {
      document?.dispose();
    }
  }
}

/// Recognises the legacy binary Office formats (DOC / PPT / XLS).
///
/// The library available to this build cannot decode these containers, so the
/// engine reports a dedicated, translated error instead of claiming support
/// or failing with a generic parse error.
class LegacyOfficeParser implements DocumentParser {
  const LegacyOfficeParser();

  @override
  Set<String> get extensions => const {'doc', 'ppt', 'xls'};

  @override
  ExtractionResult parse({
    required String extension,
    required Uint8List bytes,
  }) {
    throw FileImportException(
      FileImportErrorKind.legacyFormatUnsupported,
      'legacy binary format: .$extension',
    );
  }
}
