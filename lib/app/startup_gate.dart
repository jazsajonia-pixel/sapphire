import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/graph/graph_warmup.dart';
import '../features/search/index_controller.dart';
import '../features/sync/sync_controller.dart';
import '../features/vault/vault_controller.dart';
import 'theme.dart';

enum StartupStep { opening, syncing, indexing, arranging, ready }

/// The loading screen. It stays up while Sapphire does the real start-up
/// work — open the vault, run the first GitHub sync, index every note and
/// lay out the graph — so the app is ready the moment it appears. There is
/// no artificial delay: with nothing to do it is gone after one frame.
/// "Open now" appears if something takes long (e.g. a slow network).
class StartupGate extends ConsumerStatefulWidget {
  const StartupGate({super.key, required this.child});
  final Widget child;

  /// Hard limits so a stuck network never traps the user on this screen.
  static const syncLimit = Duration(seconds: 40);
  static const skipAfter = Duration(seconds: 4);
  static const overallLimit = Duration(seconds: 90);

  @override
  ConsumerState<StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends ConsumerState<StartupGate> {
  bool _entered = false;
  bool _syncStarted = false;
  bool _syncDone = false;
  bool _graphStarted = false;
  bool _graphDone = false;
  bool _canSkip = false;
  Timer? _skipTimer;
  Timer? _limitTimer;

  @override
  void initState() {
    super.initState();
    _skipTimer = Timer(StartupGate.skipAfter, () {
      if (mounted) setState(() => _canSkip = true);
    });
    _limitTimer = Timer(StartupGate.overallLimit, _enter);
  }

  @override
  void dispose() {
    _skipTimer?.cancel();
    _limitTimer?.cancel();
    super.dispose();
  }

  void _enter() {
    if (!mounted || _entered) return;
    _skipTimer?.cancel();
    _limitTimer?.cancel();
    setState(() => _entered = true);
  }

  void _startSync() {
    if (_syncStarted) return;
    _syncStarted = true;
    ref
        .read(syncControllerProvider.notifier)
        .startupSync()
        .timeout(StartupGate.syncLimit, onTimeout: () {})
        .catchError((Object _) {})
        .whenComplete(() {
          if (mounted) setState(() => _syncDone = true);
        });
  }

  void _startGraph(IndexState idx) {
    if (_graphStarted) return;
    _graphStarted = true;
    ref
        .read(warmGraphProvider.notifier)
        .warm(idx.index)
        .catchError((Object _) {})
        .whenComplete(() {
          if (mounted) setState(() => _graphDone = true);
        });
  }

  StartupStep _step(VaultState vault, IndexState idx) {
    if (vault is VaultLoading) return StartupStep.opening;
    if (vault is! VaultReady) return StartupStep.ready; // nothing to prepare
    if (!_syncDone) {
      // Start after this frame: providers must not change during build.
      scheduleMicrotask(_startSync);
      return StartupStep.syncing;
    }
    if (vault.scanning || idx.building || !idx.ready) {
      return StartupStep.indexing;
    }
    if (!_graphDone) {
      scheduleMicrotask(() => _startGraph(idx));
      return StartupStep.arranging;
    }
    return StartupStep.ready;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedSwitcher(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: _entered
          ? KeyedSubtree(key: const ValueKey('app'), child: widget.child)
          : KeyedSubtree(
              key: const ValueKey('loading'),
              child: _loading(reduce),
            ),
    );
  }

  Widget _loading(bool reduce) {
    final vault = ref.watch(vaultControllerProvider);
    final idx = ref.watch(indexControllerProvider);
    final sync = ref.watch(syncControllerProvider);
    final step = _step(vault, idx);
    if (step == StartupStep.ready) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _enter());
    }
    return LoadingScreen(
      step: step,
      sync: sync,
      index: idx,
      reduceMotion: reduce,
      onSkip: _canSkip ? _enter : null,
    );
  }
}

/// Full-screen ink canvas, the mark and wordmark centred, and one thin
/// progress line near the bottom that reports the real step.
class LoadingScreen extends StatelessWidget {
  const LoadingScreen({
    super.key,
    required this.step,
    required this.sync,
    required this.index,
    this.reduceMotion = false,
    this.onSkip,
  });

  final StartupStep step;
  final SyncUiState sync;
  final IndexState index;
  final bool reduceMotion;
  final VoidCallback? onSkip;

  (String, double?) _status() {
    switch (step) {
      case StartupStep.opening:
        return ('Opening your vault', null);
      case StartupStep.syncing:
        if (sync.total > 0) {
          return (
            'Syncing with GitHub · ${sync.done} of ${sync.total}',
            sync.done / sync.total,
          );
        }
        return ('Syncing with GitHub', null);
      case StartupStep.indexing:
        if (index.total > 0) {
          return (
            'Indexing notes · ${index.done} of ${index.total}',
            index.done / index.total,
          );
        }
        return ('Indexing notes', null);
      case StartupStep.arranging:
        return ('Arranging the graph', null);
      case StartupStep.ready:
        return ('Ready', 1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (label, value) = _status();
    return Scaffold(
      key: const Key('startup-loading'),
      backgroundColor: SapphireTheme.ink,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(width: double.infinity),
            const Spacer(flex: 5),
            const SapphireMark(size: 88),
            const SizedBox(height: 20),
            Text(
              'Sapphire',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: SapphireTheme.onSurface,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
            const Spacer(flex: 6),
            SizedBox(
              width: 168,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  minHeight: 2,
                  // Under reduced motion show a still line instead of the
                  // moving indeterminate one.
                  value: value ?? (reduceMotion ? 0.35 : null),
                  backgroundColor: SapphireTheme.surfaceHigh,
                  color: SapphireTheme.sapphire,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Semantics(
              liveRegion: true,
              child: Text(
                label,
                key: const Key('startup-status'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: SapphireTheme.onSurfaceVariant,
                ),
              ),
            ),
            SizedBox(
              height: 56,
              child: onSkip == null
                  ? null
                  : Center(
                      child: TextButton(
                        onPressed: onSkip,
                        child: const Text('Open now'),
                      ),
                    ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
