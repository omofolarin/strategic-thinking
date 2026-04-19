# CLAUDE.md

Claude Code instructions for this repo.

## Read this first

**`AGENTS.md` is the canonical contract document for this project.** Read it before writing or modifying any code. It defines:

- Non-negotiable invariants (provenance integrity, dispatch-target registry, explanation grounding, JGDL contract)
- Repo layout and where new files belong
- Workflows for adding traits, Tales, solvers, and MCP tools
- Anti-patterns and when to ask before acting

Do not proceed with code changes without having internalized it.

## Load-bearing documents, in reading order

1. **`AGENTS.md`** — what every contributing agent must uphold.
2. **`docs/composition-architecture.md`** — why the toolkit composes (the four layers: wrapper+dispatch, provenance append, JGDL, orthogonality).
3. **`docs/trait-composition-contract.md`** — normative rules for trait authors, including the dispatch-target matrix.
4. **`docs/glossary.md`** — JGDL term and type reference.
5. **`roadmap.md`** — phased plan with exit criteria. Don't build Phase N+1 before Phase N exits.
6. **`tasks.md`** — concrete checklist. If your intended change isn't here, check with the human.
7. **`jgdl/schema/v1.0.0.schema.json`** — the serialization contract. Changes require version bump discussion.

## Claude Code specific notes

### Tools to prefer

- **`TaskCreate` / `TaskUpdate`** — use for multi-step work (e.g. adding a trait involves 9 steps per AGENTS.md §3.1; track them).
- **`Skill` — `update-config`** — for repo settings, hooks, permissions.
- **`Skill` — `fewer-permission-prompts`** — after a session accumulates read-only allowlist candidates.

### Tools to avoid by default

- **`Agent` subagent spawning** — most workflows in this repo are linear enough to handle in-thread. Reach for subagents only for genuinely independent parallel work (e.g. "scaffold Ch 10 while I finish Ch 4").
- **Any tool that generates explanation text bypassing the provenance chain.** If you're about to emit strategic claims not traceable to `ProvenanceNode` entries, stop.

### Tool patterns that fit this repo

- Reading: `Read` for known paths (roadmap, contract, specific chapter files). `Grep` for symbol lookups. Reserve `Explore` agent for broad unfamiliar searches.
- Parallel file writes during scaffolding: batch independent `Write` calls in a single message.
- Verifying the module loads after a change: `julia --project=strategic-jl -e 'using Strategic'`.
- Running the composition test: `julia --project=strategic-jl -e 'using Pkg; Pkg.test()'` — the composition test will catch most registry violations.

### Don't repeat the scaffolding

Every directory and stub file is already in place. When implementing Phase 1 tasks, edit the existing stub rather than create new files. Stubs carry `tasks.md` references in their error messages — that's how to find them.

### Provenance rule (emphasized because it's the easiest to forget)

When you write solver code, inverse inference code, or MCP tool handlers:

- The return value is data, not prose.
- If the function makes a strategic claim (e.g. "threat is credible"), that claim is a `ProvenanceNode` entry, not a string in a response body.
- Explanation rendering is a downstream layer (`explain_from_provenance` MCP tool, web explainer). It reads provenance; it doesn't invent.

An LLM that cannot cite provenance should not emit strategic claims from this codebase. That includes Claude Code while implementing features — don't smuggle freeform explanations into code comments presented as if they were provenance.

### Phase discipline

The roadmap phases are not suggestions. Each phase earns the next through demonstrated value:

- Phase 0: JGDL contract. (Current.)
- Phase 1: forward toolkit including foundation (Ch 1–4) and modifiers (Ch 5–8).
- Phase 2: inverse toolkit.
- Phase 3: antifragile affordances.
- Phase 4: MCP server (Rust).
- Phase 5: systems-thinking layer (conditional).
- Phase 6: WASM + web composer (conditional).

Before starting work, confirm the task is in the current phase's section of `tasks.md`. If the human asked for something cross-phase, note the phase jump and confirm before proceeding.

## When to ask before acting

From `AGENTS.md` §6, the gates where you must check in first:

- Changes to the JGDL schema.
- New dispatch targets.
- Changes to the provenance contract.
- Jumping phases.
- Bypassing the trait composition contract.
- Adding LLM explanation surfaces that don't read from provenance.

These aren't bureaucracy. Each gate is a point where architectural guarantees live. Shortcutting any of them removes a property the rest of the system depends on.

## Local session conventions

- Keep end-of-turn summaries to one or two sentences.
- When writing Julia, Rust, or TypeScript code, prefer editing the existing stub file over creating a new one — the scaffold is deliberate.
- Don't emit emojis into source files or docs unless the human explicitly requests them.
- Don't create documentation files (*.md) beyond the ones already specified in `AGENTS.md` without being asked.
