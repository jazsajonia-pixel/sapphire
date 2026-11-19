import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/saf_vault_storage.dart';
import '../../data/vault_storage.dart';
import '../notes/note_codec.dart';
import '../vault/vault_controller.dart';
import 'index_cache.dart';
import 'vault_index.dart';

/// Where the index is kept between launches (app-private, not the vault).
final indexCacheProvider = Provider<IndexCache>((ref) {
  final storage = ref.watch(vaultStorageProvider);
  if (storage is! SafVaultStorage) return MemoryIndexCache();
  return FileIndexCache(() async => Directory(await storage.appFilesDir()));
});

class IndexState {
  const IndexState(
    this.index, {
    this.building = false,
    this.done = 0,
    this.total = 0,
    this.ready = true,
  });

  final VaultIndex index;
  final bool building;

  /// The index matches the current vault listing (false until the first
  /// pass after start-up finished).
  final bool ready;
  final int done;
  final int total;
}

final indexControllerProvider = NotifierProvider<IndexController, IndexState>(
  IndexController.new,
);

/// Keeps a [VaultIndex] in sync with the vault listing. Only files whose
/// size or modification time changed are re-read. The index lives in memory
/// and is derived entirely from the Markdown files.
class IndexController extends Notifier<IndexState> {
  final Map<String, IndexedNote> _cache = {};
  final Set<String> _unreadable = {};
  String? _vaultId;
  int _generation = 0;

  /// Loads the saved index for [_vaultId] once per vault.
  Future<List<CachedNote>>? _restoring;
  bool _restored = false;

  @override
  IndexState build() {
    ref.listen<VaultState>(vaultControllerProvider, (_, next) => _sync(next));
    Future.microtask(() => _sync(ref.read(vaultControllerProvider)));
    return IndexState(VaultIndex.empty, ready: false);
  }

  void _persist() {
    final id = _vaultId;
    if (id == null) return;
    unawaited(
      ref.read(indexCacheProvider).save(id, [
        for (final n in _cache.values)
          CachedNote(
            path: n.path,
            text: n.text,
            lastModified: n.lastModified,
            size: n.size,
          ),
      ]),
    );
  }

  /// Discards everything and re-reads all notes from the vault.
  Future<void> rebuild() async {
    _cache.clear();
    _unreadable.clear();
    await _sync(ref.read(vaultControllerProvider), force: true);
  }

  /// Called after Sapphire itself wrote a note, so it does not need re-reading.
  void updateNote(String path, String text, FileStamp stamp) {
    if (_vaultId == null) return;
    _cache[path] = IndexedNote(
      path: path,
      text: text,
      lastModified: stamp.lastModified,
      size: stamp.size,
    );
    _unreadable.remove(path);
    state = IndexState(_build(), building: state.building);
  }

  VaultIndex _build() =>
      VaultIndex(Map.of(_cache), unreadable: _unreadable.toList()..sort());

  Future<void> _sync(VaultState s, {bool force = false}) async {
    final gen = ++_generation;
    if (s is! VaultReady) {
      if (s is VaultNone || s is VaultAccessLost) {
        _cache.clear();
        _unreadable.clear();
        _vaultId = null;
        state = IndexState(VaultIndex.empty);
      }
      return;
    }
    if (_vaultId != s.vault.id) {
      _cache.clear();
      _unreadable.clear();
      _vaultId = s.vault.id;
      _restoring = null;
      _restored = false;
    }
    if (!_restored) {
      final id = s.vault.id;
      state = IndexState(state.index, building: true, ready: false);
      final saved = await (_restoring ??= ref
          .read(indexCacheProvider)
          .load(id));
      if (!ref.mounted || _vaultId != id) return;
      if (!_restored) {
        _restored = true;
        for (final n in saved) {
          _cache.putIfAbsent(
            n.path,
            () => IndexedNote(
              path: n.path,
              text: n.text,
              lastModified: n.lastModified,
              size: n.size,
            ),
          );
        }
      }
      if (gen != _generation) return; // a newer pass continues from here
    }
    final current = {for (final e in s.notes) e.path: e};
    var changed = force;
    for (final p in _cache.keys.toList()) {
      if (!current.containsKey(p)) {
        _cache.remove(p);
        changed = true;
      }
    }
    _unreadable.removeWhere((p) => !current.containsKey(p));
    final toRead = [
      for (final e in current.values)
        if (_cache[e.path] == null ||
            _cache[e.path]!.lastModified != e.lastModified ||
            _cache[e.path]!.size != e.size)
          e,
    ];
    if (toRead.isEmpty) {
      if (changed ||
          !state.ready ||
          state.building ||
          state.index.notes.length != _cache.length) {
        state = IndexState(_build());
      }
      if (changed) _persist();
      return;
    }
    final storage = ref.read(vaultStorageProvider);
    state = IndexState(state.index, building: true, total: toRead.length);
    for (var i = 0; i < toRead.length; i++) {
      final e = toRead[i];
      try {
        final c = await storage.readFile(s.vault, e.path);
        if (!ref.mounted || gen != _generation) return; // superseded
        _cache[e.path] = IndexedNote(
          path: e.path,
          text: NoteCodec.decode(c.bytes).text,
          lastModified: e.lastModified,
          size: e.size,
        );
        _unreadable.remove(e.path);
      } on VaultException catch (err) {
        if (!ref.mounted || gen != _generation) return;
        if (err.code == VaultErrorCode.permissionDenied) {
          state = IndexState(_build());
          return;
        }
        _cache.remove(e.path);
        _unreadable.add(e.path);
      }
      if (i % 25 == 24) {
        state = IndexState(
          state.index,
          building: true,
          done: i + 1,
          total: toRead.length,
        );
      }
    }
    if (!ref.mounted || gen != _generation) return;
    state = IndexState(_build());
    _persist();
  }
}
