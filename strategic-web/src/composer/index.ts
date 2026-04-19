// Visual composer: drag-and-drop world construction, emits JGDL.
// Phase 6 skeleton — tasks.md Phase 6 / conditional.

import type { JgdlDocument } from "../jgdl/types.js";

export function emptyWorld(): JgdlDocument {
  return {
    version: "1.0.0",
    world: {
      id: "sha256:0000000000000000000000000000000000000000000000000000000000000000",
      players: [],
      actions: [],
      structure: { type: "simultaneous" },
      payoffs: { type: "terminal_matrix", matrix: {} },
      initial_state: {},
      provenance: [],
    },
  };
}
