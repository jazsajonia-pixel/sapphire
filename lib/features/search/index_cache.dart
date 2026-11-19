import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import '../../core/vault/hashing.dart';

/// One cached note: enough to skip re-reading an unchanged file.
class CachedNote {
  const CachedNote({
    required this.path,
    required this.text,
    required this.lastModified,
    required this.size,
  });

  final String path;
  final String text;
  final int lastModified;
  final int size;
}

/// Stores the search/link index between launches so opening the app only
/// re-reads notes that changed. The cache is derived data: it lives in the
/// app's private files, never in the vault, and losing it only costs one
/// full re-read.
abstract interface class IndexCache {
  Future<List<CachedNote>> load(String vaultId);
  Future<void> save(String vaultId, Iterable<CachedNote> notes);
}

class MemoryIndexCache implements IndexCache {
  final Map<String, List<CachedNote>> data = {};

  @override
  Future<List<CachedNote>> load(String vaultId) async =>
      List.of(data[vaultId] ?? const []);

  @override
  Future<void> save(String vaultId, Iterable<CachedNote> notes) async =>
      data[vaultId] = List.of(notes);
}

class FileIndexCache implements IndexCache {
  FileIndexCache(this._baseDir);
  final Future<Directory> Function() _baseDir;

  static const _version = 1;

  Future<File> _file(String vaultId) async {
    final d = Directory('${(await _baseDir()).path}/index');
    await d.create(recursive: true);
    return File(
      '${d.path}/${sha256Hex(utf8.encode(vaultId)).substring(0, 24)}.json',
    );
  }

  @override
  Future<List<CachedNote>> load(String vaultId) async {
    try {
      final f = await _file(vaultId);
      if (!await f.exists()) return const [];
      final raw = await f.readAsString();
      // Decoding a large vault can take a moment; keep the UI thread free.
      return await Isolate.run(() => _decode(raw));
    } on Object {
      return const []; // Unreadable or old cache: rebuild from the files.
    }
  }

  static List<CachedNote> _decode(String raw) {
    final j = jsonDecode(raw);
    if (j is! Map || j['v'] != _version || j['notes'] is! List) return const [];
    return [
      for (final n in j['notes'] as List)
        if (n is Map &&
            n['p'] is String &&
            n['t'] is String &&
            n['m'] is int &&
            n['s'] is int)
          CachedNote(
            path: n['p'] as String,
            text: n['t'] as String,
            lastModified: n['m'] as int,
            size: n['s'] as int,
          ),
    ];
  }

  @override
  Future<void> save(String vaultId, Iterable<CachedNote> notes) async {
    try {
      final f = await _file(vaultId);
      final payload = [
        for (final n in notes)
          {'p': n.path, 't': n.text, 'm': n.lastModified, 's': n.size},
      ];
      final raw = await Isolate.run(
        () => jsonEncode({'v': _version, 'notes': payload}),
      );
      final tmp = File('${f.path}.tmp');
      await tmp.writeAsString(raw, flush: true);
      await tmp.rename(f.path);
    } on Object {
      // A missing cache only makes the next start slower.
    }
  }
}
