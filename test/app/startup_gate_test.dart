import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sapphire/app/app.dart';
import 'package:sapphire/data/memory_vault_storage.dart';
import 'package:sapphire/data/vault_storage.dart';
import 'package:sapphire/features/search/index_controller.dart';
import 'package:sapphire/features/sync/sync_controller.dart';
import 'package:sapphire/features/ai/ai_config.dart';
import 'package:sapphire/features/vault/vault_controller.dart';

const _vault = VaultHandle(id: 'memory://vault', name: 'Vault');

void main() {
  testWidgets('loading screen stays up until the vault is indexed', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final storage = MemoryVaultStorage(
      files: {for (var i = 0; i < 60; i++) 'Note $i.md': 'Body $i [[Note 0]]'},
      remembered: _vault,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaultStorageProvider.overrideWithValue(storage),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          autoSyncRuntimeProvider.overrideWithValue(false),
        ],
        child: const SapphireApp(reduceMotion: true),
      ),
    );
    expect(find.byKey(const Key('startup-loading')), findsOneWidget);
    expect(find.byKey(const Key('startup-status')), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);

    await tester.pumpAndSettle();
    expect(find.byKey(const Key('startup-loading')), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(NavigationBar)),
    );
    final idx = container.read(indexControllerProvider);
    expect(idx.ready, isTrue);
    expect(idx.index.notes, hasLength(60));
    expect(idx.index.backlinks('Note 0.md'), hasLength(59));
  });

  testWidgets('with no vault chosen the loader gets out of the way', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vaultStorageProvider.overrideWithValue(MemoryVaultStorage()),
          secretStoreProvider.overrideWithValue(MemorySecretStore()),
          autoSyncRuntimeProvider.overrideWithValue(false),
        ],
        child: const SapphireApp(reduceMotion: true),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('startup-loading')), findsNothing);
    expect(find.text('No vault selected'), findsWidgets);
  });
}
