// Provenance graph visualization: each ProvenanceNode is a vertex,
// parent_id edges give the graph structure. Chapter-ref groups provide
// color/cluster hints.
//
// Phase 6 skeleton — tasks.md Phase 6 / conditional.

import type { ProvenanceNode } from "../jgdl/types.js";

export interface ProvenanceGraph {
  nodes: ProvenanceNode[];
  edges: Array<{ from: string; to: string }>;
}

export function buildGraph(nodes: ProvenanceNode[]): ProvenanceGraph {
  const edges = nodes
    .filter((n) => n.parent_id !== "")
    .map((n) => ({ from: n.parent_id, to: n.operation }));
  return { nodes, edges };
}
