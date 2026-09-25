/// Shared fixtures for the File Engine test-suite.
///
/// Every fixture is built in memory (or written to a temp file) so the tests
/// never depend on assets, the network or the platform picker.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qari/features/files/data/parsers/byte_text_decoder.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

/// UTF-8 bytes without a BOM.
Uint8List utf8Of(String text) => Uint8List.fromList(utf8.encode(text));

/// UTF-16 Little Endian bytes prefixed with the standard BOM.
Uint8List utf16LeBomOf(String text) {
  final bytes = <int>[0xFF, 0xFE];
  for (final unit in text.codeUnits) {
    bytes.add(unit & 0xFF);
    bytes.add((unit >> 8) & 0xFF);
  }
  return Uint8List.fromList(bytes);
}

/// Windows-1252 bytes (Latin-1 range + the `0x80` Euro slot).
Uint8List cp1252Of(String text) {
  final bytes = <int>[];
  for (final rune in text.runes) {
    if (rune < 0x80 || (rune >= 0xA0 && rune <= 0xFF)) {
      bytes.add(rune);
    } else if (rune == 0x20AC) {
      bytes.add(0x80);
    } else {
      throw FormatException(
        'U+${rune.toRadixString(16)} is not representable in cp1252',
      );
    }
  }
  return Uint8List.fromList(bytes);
}

/// Windows-1256 bytes produced from the production code page table.
Uint8List cp1256Of(String text) {
  final reverse = <int, int>{};
  for (var byte = 0x80; byte <= 0xFF; byte++) {
    final decoded = DocumentByteDecoder.decodeWithCodePage(
      Uint8List.fromList(<int>[byte]),
      DocumentByteDecoder.cp1256,
    );
    if (decoded.isEmpty) continue;
    reverse.putIfAbsent(decoded.codeUnitAt(0), () => byte);
  }

  final bytes = <int>[];
  for (final rune in text.runes) {
    if (rune < 0x80) {
      bytes.add(rune);
      continue;
    }
    final byte = reverse[rune];
    if (byte == null) {
      throw FormatException(
        'U+${rune.toRadixString(16)} is not representable in cp1256',
      );
    }
    bytes.add(byte);
  }
  return Uint8List.fromList(bytes);
}

/// Builds an in-memory ZIP archive from `path -> xml/text content`.
Uint8List zipOf(Map<String, String> entries) {
  final archive = Archive();
  entries.forEach((name, content) {
    archive.addFile(ArchiveFile.string(name, content));
  });
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// Minimal but valid DOCX package.
Uint8List docxOf(List<String> paragraphs) {
  final body = paragraphs
      .map((text) =>
          '<w:p><w:r><w:t xml:space="preserve">$text</w:t></w:r></w:p>')
      .join();
  return zipOf({
    'word/document.xml':
        '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<w:document xmlns:w="http://schemas.openxmlformats.org/'
            'wordprocessingml/2006/main"><w:body>$body</w:body></w:document>',
  });
}

/// Minimal but valid XLSX package with one worksheet.
Uint8List xlsxOf({
  required String sheetName,
  required List<List<String>> rows,
}) {
  final shared = <String>[];
  final sheetRows = <String>[];
  for (var index = 0; index < rows.length; index++) {
    final rowNumber = index + 1;
    final cells = <String>[];
    for (var column = 0; column < rows[index].length; column++) {
      final value = rows[index][column];
      final reference = '${_columnName(column)}$rowNumber';
      final isNumber = int.tryParse(value) != null;
      if (isNumber) {
        cells.add('<c r="$reference"><v>$value</v></c>');
      } else {
        final sharedIndex = shared.length;
        shared.add(value);
        cells.add('<c r="$reference" t="s"><v>$sharedIndex</v></c>');
      }
    }
    sheetRows.add('<row r="$rowNumber">${cells.join()}</row>');
  }

  final sharedItems = shared.map((value) => '<si><t>$value</t></si>').join();
  final sheetNameXml = sheetName
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('"', '&quot;');

  return zipOf({
    'xl/workbook.xml': '<?xml version="1.0" encoding="UTF-8"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/'
        '2006/main"><sheets><sheet name="$sheetNameXml" sheetId="1" '
        'r:id="rId1"/></sheets></workbook>',
    'xl/sharedStrings.xml': '<?xml version="1.0" encoding="UTF-8"?>'
        '<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/'
        'main" count="${shared.length}" uniqueCount="${shared.length}">'
        '$sharedItems</sst>',
    'xl/worksheets/sheet1.xml': '<?xml version="1.0" encoding="UTF-8"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/'
        '2006/main"><sheetData>${sheetRows.join()}</sheetData></worksheet>',
  });
}

String _columnName(int index) {
  var value = index;
  var name = '';
  do {
    name = String.fromCharCode(65 + (value % 26)) + name;
    value = value ~/ 26 - 1;
  } while (value >= 0);
  return name;
}

/// Minimal but valid PPTX package with one slide per entry.
Uint8List pptxOf(List<String> slides) {
  final files = <String, String>{};
  for (var index = 0; index < slides.length; index++) {
    final number = index + 1;
    files['ppt/slides/slide$number.xml'] =
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<p:sld xmlns:p="http://schemas.openxmlformats.org/presentationml/'
        '2006/main" xmlns:a="http://schemas.openxmlformats.org/drawingml/'
        '2006/main"><p:cSld><p:spTree><p:sp><p:txBody><a:p><a:r>'
        '<a:t>${slides[index]}</a:t></a:r></a:p></p:txBody></p:sp>'
        '</p:spTree></p:cSld></p:sld>';
  }
  return zipOf(files);
}

/// Minimal but valid EPUB package with one XHTML chapter per entry.
Uint8List epubOf(List<String> chapters) {
  final files = <String, String>{};
  final manifest = <String>[];
  final spine = <String>[];
  for (var index = 0; index < chapters.length; index++) {
    final id = 'ch${index + 1}';
    manifest.add(
      '<item id="$id" href="$id.xhtml" media-type="application/xhtml+xml"/>',
    );
    spine.add('<itemref idref="$id"/>');
    files['OEBPS/$id.xhtml'] = '<?xml version="1.0" encoding="UTF-8"?>'
        '<html xmlns="http://www.w3.org/1999/xhtml"><head>'
        '<title>Chapter ${index + 1}</title></head><body>'
        '<p>${chapters[index]}</p></body></html>';
  }

  files['META-INF/container.xml'] = '<?xml version="1.0" encoding="UTF-8"?>'
      '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:'
      'xmlns:container"><rootfiles><rootfile full-path="OEBPS/content.opf" '
      'media-type="application/oebps-package+xml"/></rootfiles></container>';

  files['OEBPS/content.opf'] = '<?xml version="1.0" encoding="UTF-8"?>'
      '<package xmlns="http://www.idpf.org/2007/opf" version="3.0" '
      'unique-identifier="bookid"><metadata/><manifest>${manifest.join()}'
      '</manifest><spine>${spine.join()}</spine></package>';

  return zipOf(files);
}

/// Builds a real PDF containing [text] using the same library the parser
/// uses, so the PDF path is exercised against a genuine document.
Future<Uint8List> pdfFixture(String text) async {
  final document = PdfDocument();
  final page = document.pages.add();
  page.graphics.drawString(
    text,
    PdfStandardFont(PdfFontFamily.helvetica, 14),
  );
  final bytes = await document.save();
  document.dispose();
  return Uint8List.fromList(bytes);
}

/// Writes [content] to a throw-away file and returns its path.
///
/// The directory is registered for deletion when the test finishes.
String writeTempFile(Uint8List content, {String extension = 'txt'}) {
  final directory = Directory.systemTemp.createTempSync('qari_file_engine');
  final file = File(
    '${directory.path}${Platform.pathSeparator}fixture.$extension',
  );
  file.writeAsBytesSync(content);
  addTearDown(() async {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });
  return file.path;
}
