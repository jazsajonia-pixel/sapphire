import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapphire/data/memory_vault_storage.dart';
import 'package:sapphire/data/vault_storage.dart';
import 'package:sapphire/features/notes/note_find.dart';

import '../helpers/app_harness.dart';

const _vault = VaultHandle(id: 'memory://vault', name: 'Vault');

MemoryVaultStorage _storage() => MemoryVaultStorage(
  files: {
    'Garden.md':
        '# Garden\n\nTomatoes like sun. Water the **tomatoes** daily.\n\n'
        'Basil grows next to tomatoes.\n',
  },
  vaultToPick: _vault,
  remembered: _vault,
);

Future<void> _openGarden(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byType(NavigationBar),
      matching: find.text('Brain'),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Garden'));
  await tester.pumpAndSettle();
}

String _count(WidgetTester tester) =>
    tester.widget<Text>(find.byKey(const Key('note-find-count'))).data!;

void main() {
  test('findMatches is case-insensitive and non-overlapping', () {
    expect(findMatches('Aaa aA', 'aa'), [0, 4]);
    expect(findMatches('abc', ''), isEmpty);
    expect(findMatches('abc', 'z'), isEmpty);
  });

  testWidgets('find in a note while viewing it', (tester) async {
    await pumpSapphire(tester, storage: _storage());
    await _openGarden(tester);
    expect(find.byKey(const Key('note-view')), findsOneWidget);
    await tester.tap(find.byTooltip('Find in note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-find-field')), 'tomato');
    await tester.pumpAndSettle();
    expect(_count(tester), '1 of 3');
    await tester.tap(find.byTooltip('Next match'));
    await tester.pumpAndSettle();
    expect(_count(tester), '2 of 3');
    await tester.tap(find.byTooltip('Previous match'));
    await tester.tap(find.byTooltip('Previous match'));
    await tester.pumpAndSettle();
    expect(_count(tester), '3 of 3', reason: 'wraps around');
    await tester.enterText(find.byKey(const Key('note-find-field')), 'cactus');
    await tester.pumpAndSettle();
    expect(_count(tester), 'No matches');
    await tester.tap(find.byTooltip('Close find'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-find-field')), findsNothing);
    expect(find.byKey(const Key('note-view')), findsOneWidget);
  });

  testWidgets('find in a note while editing highlights the raw text', (
    tester,
  ) async {
    await pumpSapphire(tester, storage: _storage());
    await _openGarden(tester);
    await tester.tap(find.byKey(const Key('note-edit-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-editor')), findsOneWidget);
    await tester.tap(find.byTooltip('Find in note'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('note-find-field')), 'TOMATO');
    await tester.pumpAndSettle();
    expect(_count(tester), '1 of 3');
    final editor = tester.widget<TextField>(
      find.byKey(const Key('note-editor')),
    );
    final ctrl = editor.controller! as HighlightingTextController;
    expect(ctrl.query, 'TOMATO');
  });

  testWidgets('opening a search result starts find with the query', (
    tester,
  ) async {
    await pumpSapphire(tester, storage: _storage());
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Brain'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('search-field')), 'basil');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Garden'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('note-view')), findsOneWidget);
    expect(_count(tester), '1 of 1');
  });
}
