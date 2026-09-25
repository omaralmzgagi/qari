import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

import '../../domain/entities/extraction_result.dart';
import '../../domain/entities/file_import_error.dart';
import 'document_parser.dart';
import 'text_document_parsers.dart';

/// DOCX / XLSX / PPTX / EPUB: these are all ZIP containers whose content
/// lives in XML parts, so one parser covers the whole family.
class OoxmlDocumentParser implements DocumentParser {
  const OoxmlDocumentParser();

  @override
  Set<String> get extensions => const {'docx', 'xlsx', 'pptx', 'epub'};

  @override
  ExtractionResult parse({
    required String extension,
    required Uint8List bytes,
  }) {
    try {
      final archive = _openArchive(bytes);
      switch (extension) {
        case 'docx':
          return _parseDocx(archive);
        case 'xlsx':
          return _parseXlsx(archive);
        case 'pptx':
          return _parsePptx(archive);
        case 'epub':
          return _parseEpub(archive);
        default:
          throw const FileImportException(FileImportErrorKind.unsupportedFile);
      }
    } on FileImportException {
      rethrow;
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.extractionFailed,
        '$extension: $error',
      );
    }
  }

  Archive _openArchive(Uint8List bytes) {
    try {
      return ZipDecoder().decodeBytes(bytes);
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.extractionFailed,
        'container is not a readable ZIP: $error',
      );
    }
  }

  String? _readXmlText(Archive archive, String name) {
    final file = archive.findFile(name);
    if (file == null || file.isDirectory) return null;
    try {
      return utf8.decode(file.content, allowMalformed: true);
    } catch (error) {
      throw FileImportException(
        FileImportErrorKind.extractionFailed,
        'unreadable part $name: $error',
      );
    }
  }

  // ---------------------------------------------------------------------
  // Word
  // ---------------------------------------------------------------------

  ExtractionResult _parseDocx(Archive archive) {
    final xml = _readXmlText(archive, 'word/document.xml');
    if (xml == null) {
      throw const FileImportException(
        FileImportErrorKind.extractionFailed,
        'DOCX has no word/document.xml',
      );
    }
    final document = XmlDocument.parse(xml);
    final buffer = StringBuffer();
    for (final paragraph in document.descendantElements
        .where((element) => element.name.local == 'p')) {
      final text = paragraph.innerText.replaceAll(RegExp(r'\s+'), ' ').trim();
      if (text.isNotEmpty) buffer.writeln(text);
    }
    return ExtractionResult(text: buffer.toString());
  }

  // ---------------------------------------------------------------------
  // Excel
  // ---------------------------------------------------------------------

  ExtractionResult _parseXlsx(Archive archive) {
    final shared = _readSharedStrings(archive);
    final sheetNames = _readSheetNames(archive);
    final sheetFiles = archive.files
        .where((file) =>
            file.isFile &&
            RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(file.name))
        .toList()
      ..sort((a, b) => _sheetNumber(a.name).compareTo(_sheetNumber(b.name)));

    if (sheetFiles.isEmpty) {
      throw const FileImportException(
        FileImportErrorKind.extractionFailed,
        'XLSX has no worksheets',
      );
    }

    final buffer = StringBuffer();
    for (var index = 0; index < sheetFiles.length; index++) {
      final xml = _readXmlText(archive, sheetFiles[index].name);
      if (xml == null) continue;
      final sheet = XmlDocument.parse(xml);
      if (index > 0) buffer.writeln();

      if (index < sheetNames.length && sheetNames[index].trim().isNotEmpty) {
        buffer.writeln(sheetNames[index].trim());
      }
      for (final row in sheet.descendantElements
          .where((element) => element.name.local == 'row')) {
        final cells = <String>[];
        for (final cell in row.children.whereType<XmlElement>().where(
              (element) => element.name.local == 'c',
            )) {
          cells.add(_cellValue(cell, shared));
        }
        final line = cells.join('\t').trim();
        if (line.trim().replaceAll('\t', '').isNotEmpty) buffer.writeln(line);
      }
    }
    return ExtractionResult(
        text: buffer.toString(), pageCount: sheetFiles.length);
  }

  String _cellValue(XmlElement cell, List<String> shared) {
    final type = cell.getAttribute('t');
    if (type == 'inlineStr') {
      return cell.innerText.replaceAll(RegExp(r'\s+'), ' ').trim();
    }
    String? raw;
    for (final value in cell.descendantElements
        .where((element) => element.name.local == 'v')) {
      raw = value.innerText;
      break;
    }
    if (raw == null) return '';
    if (type == 's') {
      final index = int.tryParse(raw);
      if (index == null || index < 0 || index >= shared.length) return '';
      return shared[index];
    }
    return raw.trim();
  }

  List<String> _readSharedStrings(Archive archive) {
    final xml = _readXmlText(archive, 'xl/sharedStrings.xml');
    if (xml == null) return const [];
    final document = XmlDocument.parse(xml);
    return document.descendantElements
        .where((element) => element.name.local == 'si')
        .map((element) =>
            element.innerText.replaceAll(RegExp(r'\s+'), ' ').trim())
        .toList();
  }

  List<String> _readSheetNames(Archive archive) {
    final xml = _readXmlText(archive, 'xl/workbook.xml');
    if (xml == null) return const [];
    final document = XmlDocument.parse(xml);
    return document.descendantElements
        .where((element) => element.name.local == 'sheet')
        .map((element) => element.getAttribute('name') ?? '')
        .toList();
  }

  // ---------------------------------------------------------------------
  // PowerPoint
  // ---------------------------------------------------------------------

  ExtractionResult _parsePptx(Archive archive) {
    final slideFiles = archive.files
        .where((file) =>
            file.isFile &&
            RegExp(r'^ppt/slides/slide(\d+)\.xml$').hasMatch(file.name))
        .toList()
      ..sort((a, b) => _slideNumber(a.name).compareTo(_slideNumber(b.name)));

    if (slideFiles.isEmpty) {
      throw const FileImportException(
        FileImportErrorKind.extractionFailed,
        'PPTX has no slides',
      );
    }

    final buffer = StringBuffer();
    for (var index = 0; index < slideFiles.length; index++) {
      final xml = _readXmlText(archive, slideFiles[index].name);
      if (xml == null) continue;
      final slide = XmlDocument.parse(xml);
      final parts = <String>[];
      for (final text in slide.descendantElements
          .where((element) => element.name.local == 't')
          .map((element) => element.innerText.trim())) {
        if (text.isNotEmpty) parts.add(text);
      }
      if (parts.isNotEmpty) {
        if (index > 0) buffer.writeln();
        buffer.writeln(parts.join(' '));
      }
    }
    return ExtractionResult(
      text: buffer.toString(),
      pageCount: slideFiles.length,
    );
  }

  static int _slideNumber(String name) =>
      int.tryParse(
          RegExp(r'slide(\d+)\.xml$').firstMatch(name)?.group(1) ?? '') ??
      0;

  static int _sheetNumber(String name) =>
      int.tryParse(
        RegExp(r'sheet(\d+)\.xml$').firstMatch(name)?.group(1) ?? '',
      ) ??
      0;

  // ---------------------------------------------------------------------
  // EPUB
  // ---------------------------------------------------------------------

  ExtractionResult _parseEpub(Archive archive) {
    final opfPath = _findOpfPath(archive);
    if (opfPath == null) {
      throw const FileImportException(
        FileImportErrorKind.extractionFailed,
        'EPUB has no OPF package file',
      );
    }
    final opfXml = _readXmlText(archive, opfPath);
    if (opfXml == null) {
      throw const FileImportException(
        FileImportErrorKind.extractionFailed,
        'EPUB package file is unreadable',
      );
    }
    final opf = XmlDocument.parse(opfXml);

    final manifest = <String, String>{};
    for (final item in opf.descendantElements
        .where((element) => element.name.local == 'item')) {
      final id = item.getAttribute('id');
      final href = item.getAttribute('href');
      if (id != null && href != null) manifest[id] = href;
    }

    final spine = opf.descendantElements
        .where((element) => element.name.local == 'itemref')
        .map((element) => element.getAttribute('idref'))
        .whereType<String>()
        .toList();

    final opfDir = opfPath.contains('/')
        ? opfPath.substring(0, opfPath.lastIndexOf('/'))
        : '';

    final buffer = StringBuffer();
    var chapters = 0;

    void append(String html) {
      final text = htmlToText(html).trim();
      if (text.isEmpty) return;
      if (chapters > 0) buffer.writeln();
      buffer.writeln(text);
      chapters++;
    }

    for (final id in spine) {
      final href = manifest[id];
      if (href == null) continue;
      final target = _resolveHref(opfDir, href);
      final html = _readXmlText(archive, target);
      if (html != null) append(html);
    }

    // Fallback when the spine is missing or empty.
    if (chapters == 0) {
      final candidates = archive.files
          .where((file) =>
              file.isFile && RegExp(r'\.(xhtml|html)$').hasMatch(file.name))
          .toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      for (final file in candidates) {
        final html = _readXmlText(archive, file.name);
        if (html != null) append(html);
      }
    }

    if (chapters == 0) {
      throw const FileImportException(
        FileImportErrorKind.extractionFailed,
        'EPUB contains no readable chapters',
      );
    }
    return ExtractionResult(text: buffer.toString(), pageCount: chapters);
  }

  String? _findOpfPath(Archive archive) {
    final container = _readXmlText(archive, 'META-INF/container.xml');
    if (container != null) {
      final document = XmlDocument.parse(container);
      final rootfile = document.descendantElements
          .where((element) => element.name.local == 'rootfile')
          .map((element) => element.getAttribute('full-path'))
          .firstWhere((value) => value != null && value.isNotEmpty,
              orElse: () => null);
      if (rootfile != null) return rootfile;
    }
    final opfs = archive.files
        .where((file) => file.isFile && file.name.endsWith('.opf'))
        .toList();
    return opfs.isEmpty ? null : opfs.first.name;
  }

  static String _resolveHref(String baseDir, String href) {
    var clean = href.split('#').first.split('?').first;
    if (clean.startsWith('/')) clean = clean.substring(1);
    final combined = baseDir.isEmpty ? clean : '$baseDir/$clean';
    final segments = <String>[];
    for (final segment in combined.split('/')) {
      if (segment.isEmpty || segment == '.') continue;
      if (segment == '..') {
        if (segments.isNotEmpty) segments.removeLast();
      } else {
        segments.add(segment);
      }
    }
    return segments.join('/');
  }
}
