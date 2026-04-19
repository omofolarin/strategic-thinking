// Explainer: renders MCP `explain_from_provenance` output, strictly
// scoped to the provenance nodes cited by the engine. No free-form
// narration allowed at this layer.
//
// Phase 6 skeleton — tasks.md Phase 6 / conditional.

import type { ProvenanceNode } from "../jgdl/types.js";

export interface Explanation {
  summary: string;
  citations: ProvenanceNode[];
}

export function render(_explanation: Explanation): string {
  return "";
}
