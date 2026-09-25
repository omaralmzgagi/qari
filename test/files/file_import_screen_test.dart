import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qari/features/files/data/providers/file_engine_providers.dart';
import 'package:qari/features/files/data/services/local_import_storage.dart';
import 'package:qari/features/files/domain/sources/file_source.dart';
import 'package:qari/features/files/presentation/file_import_screen.dart';
import 'package:qari/localization/generated/app_localizations.dart';

import 'fixtures.dart';

const _arabic = 'الحمد لله رب العالمين الرحمن الرحيم مالك يوم الدين';

class _SequenceSource implements FileSource {
  _SequenceSource(this.items);

  final List<PickedFile?> items;
  var _index = 0;

  @override
  Future<PickedFile?> pick() async {
    final value = _index < items.length ? items[_index] : null;
    _index++;
    return value;
  }
}

void main() {
  Future<void> useTabletViewport(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget buildScreen({FileSource? source}) {
    return ProviderScope(
      overrides: [
        if (source != null) fileSourceProvider.overrideWithValue(source),
        importStorageProvider.overrideWithValue(
          const PassthroughImportStorage(),
        ),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const FileImportScreen(),
      ),
    );
  }

  testWidgets('idle screen explains the feature and lists the formats',
      (tester) async {
    await useTabletViewport(tester);
    await tester.pumpWidget(buildScreen());
    await tester.pumpAndSettle();

    expect(find.text('Import a file'), findsOneWidget);
    expect(find.textContaining('Nothing is uploaded'), findsOneWidget);
    expect(find.text('Ready to import'), findsOneWidget);
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.textContaining('prepares it for the Reader'), findsOneWidget);
    expect(find.text('Supported formats'), findsOneWidget);
    expect(find.text('Legacy Office files'), findsOneWidget);
    expect(find.text('Maximum size'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'dismissing the picker stays on the idle screen without '
      'crashing', (tester) async {
    await useTabletViewport(tester);
    final source = _SequenceSource([null]);
    await tester.pumpWidget(buildScreen(source: source));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Ready to import'), findsOneWidget);
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.text('This file type is not supported.'), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('an unsupported file shows the translated error and a retry',
      (tester) async {
    await useTabletViewport(tester);
    final source = _SequenceSource([
      PickedFile(name: 'holiday.gif', bytes: utf8Of('picture')),
    ]);
    await tester.pumpWidget(buildScreen(source: source));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('This file type is not supported.'), findsOneWidget);
    expect(find.text('Ready to import'), findsNothing);
    expect(find.text('Back'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a failed import can be reset back to the idle screen',
      (tester) async {
    await useTabletViewport(tester);
    final source = _SequenceSource([
      PickedFile(name: 'holiday.gif', bytes: utf8Of('picture')),
    ]);
    await tester.pumpWidget(buildScreen(source: source));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();
    expect(find.text('This file type is not supported.'), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pumpAndSettle();

    expect(find.text('Ready to import'), findsOneWidget);
    expect(find.text('Choose a file'), findsOneWidget);
    expect(find.text('This file type is not supported.'), findsNothing);
  });

  testWidgets('a successful import renders the result card', (tester) async {
    await useTabletViewport(tester);
    final source = _SequenceSource([
      PickedFile(
        name: 'notes.txt',
        size: utf8Of(_arabic).length,
        bytes: utf8Of(_arabic),
      ),
    ]);
    await tester.pumpWidget(buildScreen(source: source));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('File imported'), findsOneWidget);
    expect(find.text('notes.txt'), findsOneWidget);
    expect(find.text('Detected language'), findsOneWidget);
    expect(find.text('Arabic'), findsOneWidget);
    expect(find.text('Text extraction'), findsOneWidget);
    expect(find.text('Import another file'), findsOneWidget);
    expect(find.text('Ready to import'), findsNothing);
  });

  testWidgets('importing another file from the result returns to idle',
      (tester) async {
    await useTabletViewport(tester);
    final source = _SequenceSource([
      PickedFile(name: 'notes.txt', bytes: utf8Of(_arabic)),
      null,
    ]);
    await tester.pumpWidget(buildScreen(source: source));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Choose a file'));
    await tester.pumpAndSettle();

    expect(find.text('Supported formats'), findsOneWidget);
    expect(find.text('Legacy Office files'), findsOneWidget);

    await tester.tap(find.text('Import another file'));
    await tester.pumpAndSettle();

    expect(find.text('Ready to import'), findsOneWidget);
    expect(find.text('File imported'), findsNothing);
  });
}
