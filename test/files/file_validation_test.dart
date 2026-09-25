import 'package:flutter_test/flutter_test.dart';
import 'package:qari/core/config/file_engine_config.dart';
import 'package:qari/features/files/domain/entities/file_import_error.dart';
import 'package:qari/features/files/domain/services/file_validation_service.dart';

void main() {
  const validator = FileValidationService();

  FileImportErrorKind failureOf({required String name, required int size}) {
    try {
      validator.validate(fileName: name, sizeBytes: size);
    } on FileImportException catch (error) {
      return error.kind;
    }
    fail('expected validation to reject $name');
  }

  group('rejections', () {
    test('a blank file name is invalid', () {
      expect(
        failureOf(name: '   ', size: 10),
        FileImportErrorKind.invalidFile,
      );
    });

    test('a name without an extension is invalid', () {
      expect(
        failureOf(name: 'README', size: 10),
        FileImportErrorKind.invalidFile,
      );
      expect(
        failureOf(name: 'notes.', size: 10),
        FileImportErrorKind.invalidFile,
      );
    });

    test('an unsupported extension is reported as unsupported', () {
      expect(
        failureOf(name: 'holiday.gif', size: 10),
        FileImportErrorKind.unsupportedFile,
      );
      expect(
        failureOf(name: 'archive.zip', size: 10),
        FileImportErrorKind.unsupportedFile,
      );
      expect(
        failureOf(name: 'video.mp4', size: 10),
        FileImportErrorKind.unsupportedFile,
      );
    });

    test('an empty file is invalid', () {
      expect(
        failureOf(name: 'notes.txt', size: 0),
        FileImportErrorKind.invalidFile,
      );
      expect(
        failureOf(name: 'notes.txt', size: -5),
        FileImportErrorKind.invalidFile,
      );
    });

    test('a document over 64 MB is too large', () {
      expect(
        failureOf(name: 'big.pdf', size: 64 * 1024 * 1024 + 1),
        FileImportErrorKind.fileTooLarge,
      );
    });

    test('an image over the image limit is too large', () {
      expect(
        failureOf(name: 'scan.png', size: 24 * 1024 * 1024 + 1),
        FileImportErrorKind.fileTooLarge,
      );
      expect(
        failureOf(name: 'scan.jpg', size: 64 * 1024 * 1024),
        FileImportErrorKind.fileTooLarge,
        reason: 'images use the smaller image ceiling, not the document one',
      );
    });
  });

  group('acceptances', () {
    test('a plain text file is accepted with the right metadata', () {
      final result = validator.validate(fileName: 'notes.txt', sizeBytes: 12);
      expect(result.name, 'notes.txt');
      expect(result.extension, 'txt');
      expect(result.sizeBytes, 12);
      expect(result.mimeType, 'text/plain');
      expect(result.isImage, isFalse);
      expect(result.isLegacyOffice, isFalse);
    });

    test('extensions are normalised regardless of case', () {
      final result = validator.validate(fileName: 'REPORT.PDF', sizeBytes: 4);
      expect(result.extension, 'pdf');
      expect(result.mimeType, 'application/pdf');
    });

    test('every required format is accepted', () {
      const formats = [
        'a.pdf',
        'b.doc',
        'c.docx',
        'd.txt',
        'e.epub',
        'f.rtf',
        'g.html',
        'h.csv',
        'i.ppt',
        'j.pptx',
        'k.xls',
        'l.xlsx',
        'm.jpg',
        'n.jpeg',
        'o.png',
        'p.webp',
      ];
      for (final name in formats) {
        expect(
          validator.validate(fileName: name, sizeBytes: 8).extension,
          isNotEmpty,
          reason: '$name must be accepted',
        );
      }
    });

    test('images are flagged for the OCR path', () {
      for (final name in ['a.jpg', 'a.jpeg', 'a.png', 'a.webp']) {
        final result = validator.validate(fileName: name, sizeBytes: 8);
        expect(result.isImage, isTrue, reason: '$name should be an image');
        expect(result.isLegacyOffice, isFalse);
      }
      expect(
        validator.validate(fileName: 'a.docx', sizeBytes: 8).isImage,
        isFalse,
      );
    });

    test('legacy Office formats validate but stay marked as legacy', () {
      for (final name in ['old.doc', 'old.ppt', 'old.xls']) {
        final result = validator.validate(fileName: name, sizeBytes: 8);
        expect(result.isLegacyOffice, isTrue, reason: '$name is legacy');
        expect(result.isImage, isFalse);
      }
    });

    test('the limit differs between documents and images', () {
      final config = FileEngineConfig.defaults;
      expect(config.maxBytesFor('pdf'), config.maxFileSizeBytes);
      expect(config.maxBytesFor('png'), config.maxImageSizeBytes);
      expect(
        config.maxImageSizeBytes,
        lessThan(config.maxFileSizeBytes),
        reason: 'the image ceiling must be the stricter one',
      );
    });
  });

  group('format catalogue', () {
    test('every required format is in the supported set', () {
      expect(
        FileEngineConfig.supportedExtensions,
        containsAll(<String>[
          'pdf',
          'doc',
          'docx',
          'txt',
          'epub',
          'rtf',
          'html',
          'csv',
          'ppt',
          'pptx',
          'xls',
          'xlsx',
          'jpg',
          'jpeg',
          'png',
          'webp',
        ]),
      );
    });

    test('the only extras are sibling text and markup formats', () {
      const required = <String>{
        'pdf',
        'doc',
        'docx',
        'txt',
        'epub',
        'rtf',
        'html',
        'csv',
        'ppt',
        'pptx',
        'xls',
        'xlsx',
        'jpg',
        'jpeg',
        'png',
        'webp',
      };
      final extras = FileEngineConfig.supportedExtensions.difference(required);
      expect(extras, {'log', 'md', 'htm'});
      expect(
        extras.every(
          (extension) =>
              FileEngineConfig.plainTextExtensions.contains(extension) ||
              FileEngineConfig.markupExtensions.contains(extension),
        ),
        isTrue,
        reason: 'extras must stay inside the plain-text/markup families',
      );
    });

    test('the picker is offered the same list, sorted and de-duplicated', () {
      final picker = FileEngineConfig.pickerExtensions;
      expect(picker, FileEngineConfig.supportedExtensions.toList()..sort());
      expect(picker.toSet().length, picker.length);
    });

    test('legacy formats are never counted as directly extractable', () {
      for (final extension in ['doc', 'ppt', 'xls']) {
        expect(FileEngineConfig.defaults.isDirectlyExtractable(extension),
            isFalse);
        expect(FileEngineConfig.defaults.supports(extension), isTrue);
      }
      expect(
        FileEngineConfig.defaults.isDirectlyExtractable('docx'),
        isTrue,
      );
    });
  });
}
