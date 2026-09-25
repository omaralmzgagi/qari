import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:qari/features/files/data/parsers/parser_registry.dart';
import 'package:qari/features/files/domain/entities/extraction_result.dart';
import 'package:qari/features/files/domain/entities/file_import_error.dart';

import 'fixtures.dart';

void main() {
  final registry = ParserRegistry();

  ExtractionResult parse(String extension, Uint8List bytes) =>
      registry.parse(extension: extension, bytes: bytes);

  FileImportErrorKind failureOf(void Function() body) {
    try {
      body();
    } on FileImportException catch (error) {
      return error.kind;
    }
    fail('expected a FileImportException to be thrown');
  }

  group('registry routing', () {
    test('knows every supported extension and rejects unknown ones', () {
      expect(registry.find('pdf'), isNotNull);
      expect(registry.find('docx'), isNotNull);
      expect(registry.find('epub'), isNotNull);
      expect(registry.find('gif'), isNull);
      expect(
        failureOf(() => parse('gif', utf8Of('anything'))),
        FileImportErrorKind.unsupportedFile,
      );
    });
  });

  group('plain text encodings', () {
    const english = 'The quick brown fox jumps over the lazy dog.';

    test('UTF-8 decodes without a BOM', () {
      expect(parse('txt', utf8Of(english)).text, english);
    });

    test('UTF-16 with BOM decodes to the same text', () {
      expect(parse('txt', utf16LeBomOf(english)).text, english);
    });

    test('Windows-1252 decodes Latin text', () {
      const text = 'Le café est prêt à servir.';
      expect(parse('txt', cp1252Of(text)).text, text);
    });

    test('Windows-1256 decodes Arabic text written as ANSI', () {
      const text = 'مرحبا بالعالم';
      final decoded = parse('txt', cp1256Of(text)).text;
      expect(decoded, text);
    });

    test('CSV keeps rows and separators intact', () {
      const csv = 'name,city\nSara,Riyadh\nOmar,Jeddah';
      final result = parse('csv', utf8Of(csv));
      expect(result.text, contains('name,city'));
      expect(result.text, contains('Sara,Riyadh'));
      expect(result.text, contains('Omar,Jeddah'));
    });

    test('empty file yields empty text instead of throwing', () {
      expect(parse('txt', Uint8List(0)).text, isEmpty);
    });
  });

  group('markup documents', () {
    test('HTML strips tags, keeps blocks and decodes entities', () {
      const html = '<html><head><style>p{color:red}</style></head>'
          '<body><h1>Title</h1><p>Tom &amp; Jerry &#39;show&#39;</p>'
          '<script>console.log(1)</script><p>Second line</p></body></html>';
      final text = parse('html', utf8Of(html)).text;

      expect(text, contains('Title'));
      expect(text, contains("Tom & Jerry 'show'"));
      expect(text, contains('Second line'));
      expect(text, isNot(contains('color:red')));
      expect(text, isNot(contains('console.log')));
      expect(text, isNot(contains('<')));
    });

    test('RTF keeps content and drops fonttbl and generator groups', () {
      const rtf = '{\\rtf1\\ansi\\ansicpg1256'
          '{\\fonttbl{\\f0 Arial;}}'
          '{\\*\\generator QARI Test;}'
          '\\f0 \\pard Hello\\par caf\\\'e9\\par \\u1575?\\u1604?}';
      final text = parse('rtf', utf8Of(rtf)).text;

      expect(text, contains('Hello'));
      expect(text, contains('café'));
      expect(text, contains('ال'));
      expect(text, isNot(contains('Arial')));
      expect(text, isNot(contains('QARI Test')));
    });
  });

  group('OOXML containers', () {
    test('DOCX extracts every paragraph in order', () {
      final docx = docxOf([
        'الكتاب مفيد للطلاب.',
        'The quick brown fox jumps over the lazy dog.',
      ]);
      final result = parse('docx', docx);
      expect(
        result.text,
        contains('The quick brown fox jumps over the lazy dog.'),
      );
      expect(result.text, contains('الكتاب مفيد للطلاب.'));
      expect(
        result.text.indexOf('الكتاب'),
        lessThan(result.text.indexOf('quick')),
      );
    });

    test('XLSX extracts shared strings, numbers and the sheet name', () {
      final xlsx = xlsxOf(
        sheetName: 'Grades',
        rows: [
          ['Name', 'Sara'],
          ['Score', '95'],
        ],
      );
      final result = parse('xlsx', xlsx);
      expect(result.text, contains('Grades'));
      expect(result.text, contains('Name'));
      expect(result.text, contains('Sara'));
      expect(result.text, contains('Score'));
      expect(result.text, contains('95'));
      expect(result.pageCount, 1);
    });

    test('PPTX extracts one block per slide and reports the slide count', () {
      final pptx = pptxOf(['First slide text', 'الشريحة الثانية']);
      final result = parse('pptx', pptx);
      expect(result.text, contains('First slide text'));
      expect(result.text, contains('الشريحة الثانية'));
      expect(result.pageCount, 2);
    });

    test('EPUB walks the spine and reports the chapter count', () {
      final epub = epubOf(['Chapter one body text.', 'نص الفصل الثاني.']);
      final result = parse('epub', epub);
      expect(result.text, contains('Chapter one body text.'));
      expect(result.text, contains('نص الفصل الثاني.'));
      expect(result.pageCount, 2);
      expect(result.text, isNot(contains('<p>')));
    });

    test('a corrupt ZIP inside a DOCX fails with extractionFailed', () {
      expect(
        failureOf(() => parse('docx', utf8Of('definitely not a zip'))),
        FileImportErrorKind.extractionFailed,
      );
    });

    test('a corrupt ZIP inside an EPUB fails with extractionFailed', () {
      expect(
        failureOf(() => parse('epub', utf8Of('definitely not a zip'))),
        FileImportErrorKind.extractionFailed,
      );
    });
  });

  group('legacy binary Office formats', () {
    test('DOC/PPT/XLS are reported as not readable instead of faking it', () {
      for (final extension in ['doc', 'ppt', 'xls']) {
        expect(
          failureOf(() => parse(extension, utf8Of('binary'))),
          FileImportErrorKind.legacyFormatUnsupported,
          reason: '.$extension should not claim extraction support',
        );
      }
    });
  });

  group('PDF', () {
    test('extracts text written by a real PDF writer', () async {
      final bytes = await pdfFixture('QARI file engine PDF text');
      final result = parse('pdf', bytes);

      expect(result.pageCount, 1);
      expect(result.text, contains('QARI'));
      expect(result.text, contains('PDF'));
    });

    test('a non-PDF payload fails with extractionFailed', () {
      expect(
        failureOf(() => parse('pdf', utf8Of('%PDF-1.7 broken payload'))),
        FileImportErrorKind.extractionFailed,
      );
    });
  });
}
