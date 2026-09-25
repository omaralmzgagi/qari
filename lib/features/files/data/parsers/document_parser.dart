import 'dart:typed_data';

import '../../domain/entities/extraction_result.dart';

/// Strategy that knows how to turn one family of formats into text.
///
/// Adding a format means registering another parser in `ParserRegistry` —
/// no widget or service ever contains format-specific branching.
abstract interface class DocumentParser {
  /// Extensions (without dot) this parser claims ownership of.
  Set<String> get extensions;

  /// Parses [bytes] into text.
  ///
  /// Implementations throw [FileImportException] with the appropriate
  /// [FileImportErrorKind]; the registry makes sure a raw `FormatException`
  /// never escapes.
  ExtractionResult parse({
    required String extension,
    required Uint8List bytes,
  });
}
