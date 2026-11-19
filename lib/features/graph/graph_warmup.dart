import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../search/vault_index.dart';
import 'graph_layout.dart';
import 'graph_model.dart';

/// A finished global-graph layout for one exact [VaultIndex].
class WarmGraph {
  const WarmGraph(this.index, this.data, this.layout);
  final VaultIndex index;
  final GraphData data;
  final GraphLayout layout;
}

/// The global graph laid out ahead of time (by the loading screen), so the
/// Graph tab opens without "Arranging graph…".
final warmGraphProvider = NotifierProvider<WarmGraphCache, WarmGraph?>(
  WarmGraphCache.new,
);

class WarmGraphCache extends Notifier<WarmGraph?> {
  @override
  WarmGraph? build() => null;

  /// The cached layout if it was made from exactly [index].
  WarmGraph? forIndex(VaultIndex index) {
    final w = state;
    return w != null && identical(w.index, index) ? w : null;
  }

  /// Lays out the global graph (isolated notes included, the Graph tab's
  /// default) for [index] and keeps it.
  Future<void> warm(VaultIndex index) async {
    if (forIndex(index) != null) return;
    final data = GraphData.global(index);
    final edges = Int32List(data.edges.length * 2);
    for (var i = 0; i < data.edges.length; i++) {
      edges[2 * i] = data.edges[i].source;
      edges[2 * i + 1] = data.edges[i].target;
    }
    final layout = await GraphLayouter.layout(
      LayoutInput(data.nodes.length, edges),
    );
    if (!ref.mounted) return;
    state = WarmGraph(index, data, layout);
  }
}
