# strategic-web

TypeScript frontend. Owns the visual composer, provenance graph viz, and explanation panel.

**Conditional on Phase 4 proving that a browser surface is worth building.** Until then, this package exists as a scaffold so the JGDL type definitions and UI contracts are reviewable from the start.

## Structure

```
src/
  jgdl/types.ts       Hand-maintained TypeScript mirror of JGDL schema v1.0.0.
  composer/           Drag-and-drop world construction, emits JGDL.
  explainer/          Renders provenance-grounded explanations from MCP.
  provenance/         Graph visualization over ProvenanceNode chains.
```

## Contract

The explainer may render **only** content that traces to provenance nodes returned by `strategic-mcp`. No free-form LLM narration at this layer.
