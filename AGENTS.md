# AGENTS.md

Contracts every agent (human or LLM) contributing to this repo must uphold.

If you are a coding agent that was not briefed on this project, **read this entire file before writing or modifying code**. The invariants below are not stylistic preferences — they are load-bearing. Violating them silently breaks guarantees the rest of the system depends on.

---

## 0. Orient first

Before any change, know where you are:

1. **`README.md`** — what the project is.
2. **`docs/composition-architecture.md`** — why the toolkit composes (the four layers).
3. **`docs/trait-composition-contract.md`** — normative rules for traits.
4. **`docs/glossary.md`** — JGDL term and type reference. Consult whenever you read or write a JGDL document.
5. **`roadmap.md`** — the phased plan and exit criteria.
6. **`tasks.md`** — the concrete work, grouped by phase.

If your intended change isn't in `tasks.md` for the *current* phase, stop and check with the human. Don't build Phase 4 features when Phase 1 isn't done.

---

## 1. Non-negotiable contracts

### 1.1 Provenance integrity

- Every `Solution` carries a **non-empty** `provenance_chain`. The `Solution` constructor in `strategic-jl/src/core/types.jl` rejects empty chains — do not weaken it.
- Every `with_trait(world, trait; …)` call appends exactly one `ProvenanceNode` describing the operation, chapter reference, rationale, and parent world id. Do not bypass `with_trait` by constructing `WithTrait{G, T}` directly outside `core/traits.jl`.
- Every inverse hypothesis mutation (Phase 2) appends a `ProvenanceNode` explaining why the hypothesis was proposed, ruled in, or pruned.
- Every surprise detection, player discovery, or hedge activation (Phase 3) appends a `ProvenanceNode` citing the evidence.

**Why:** the LLM explanation layer reads *only* from provenance. If the chain is thin, lies, or is missing, explanations hallucinate and the toolkit loses its grounding guarantee.

### 1.2 Dispatch-target registry

- Adding a new `GameTrait` requires a corresponding `register_trait!(T, Set([…]))` call in the same chapter file.
- A trait may override **only** the dispatch targets listed in its registry entry.
- A trait may override **only** dispatch targets from `DISPATCH_TARGETS` (defined in `core/traits.jl`). Adding a new dispatch target is a core change, not a trait change — it requires updating `docs/trait-composition-contract.md` §2 first.
- If two traits in a world touch the same target, order is semantically significant and must be preserved in the JGDL `traits` array.

**Why:** without the registry, a new trait can silently clobber dispatch a previous trait was relying on. The solver returns wrong numbers and nobody notices.

### 1.3 Explanation grounding

- The LLM explanation layer (Phase 4: MCP `explain_from_provenance` tool; Phase 6: web explainer) must render content that traces to `ProvenanceNode` citations.
- Tool responses in `strategic-rs/crates/strategic-mcp/` must not return free-form strategic claims. Every claim is accompanied by the provenance chain that justifies it.
- Do not introduce "helpful" text generation that bypasses this contract — even for tutorials, even for error messages. If a user-facing string makes a strategic claim, it must cite a provenance node.

**Why:** provenance-grounded explanation is what makes the toolkit trustworthy. An LLM layer that invents reasons the engine didn't produce is worse than no explanation at all.

### 1.4 JGDL is load-bearing

- `jgdl/schema/v1.0.0.schema.json` is the canonical serialization contract. Every implementation (Julia, Rust, TypeScript) must accept and produce documents validating against it.
- Additive changes (new optional fields) → minor version bump.
- Breaking changes → major version bump, migration script required.
- Cross-language serialization must be **byte-identical**: Julia and Rust must produce the same JGDL bytes for the same world, and therefore the same content hash.

**Why:** JGDL is the substrate that lets composition cross process, language, and tool boundaries. Drift between implementations corrupts content addressing and breaks reproducibility.

### 1.5 Foundation before modifiers

- Chapters 1–4 (Ten Tales corpus, sequential reasoning, dominance analysis, reciprocity strategies) are the **substrate**.
- Chapters 5–13 are **modifiers** (traits) that stack on the substrate.
- Do not implement a Chapter 5+ trait that depends on a Chapter 1–4 primitive that doesn't exist yet. If the trait needs it, finish the foundation first.

**Why:** modifiers without foundations produce features that demo well and fail silently on real compositions.

### 1.6 Tales are ground truth

- Chapter 1's Ten Tales (`jgdl/examples/tales/`) are the canonical exemplars.
- The compliance suite is anchored on the Tales. If the primitives can't model all ten, the primitives are wrong.
- When adding a new primitive, ask: which Tale does this make expressible that wasn't before? If the answer is "none," question whether the primitive belongs.

---

## 2. Repository layout: where does X go?

| You're adding… | It goes in… | See also |
|---|---|---|
| A new chapter primitive (e.g. new trait) | `strategic-jl/src/chapters/chNN_*.jl` | `docs/trait-composition-contract.md` §6 |
| A new dispatch target | `strategic-jl/src/core/traits.jl` `DISPATCH_TARGETS` + contract doc §2 | requires version bump discussion |
| A new solver | `strategic-jl/src/solvers/forward/` or `inverse/` | `roadmap.md` Phase 1 or 2 |
| A new Tale (Ch 1 corpus entry) | `jgdl/examples/tales/<name>.json` + `TALES` registry entry | `strategic-jl/src/chapters/ch01_tales.jl` |
| A compliance test case | `jgdl/compliance/compliance_suite.json` | covers both languages |
| A Rust type mirroring JGDL | `strategic-rs/crates/strategic-core/src/game.rs` | must round-trip with Julia |
| An MCP tool | `strategic-rs/crates/strategic-mcp/src/tools.rs` | every response carries provenance |
| TypeScript JGDL type | `strategic-web/src/jgdl/types.ts` | manual mirror until schema codegen lands |
| An antifragile primitive | `strategic-jl/src/antifragile/` | Phase 3 |
| Architecture rationale | `docs/` | link from `README.md` |

Anything that doesn't fit these slots warrants a conversation before you start writing.

---

## 3. Workflows

### 3.1 Adding a new trait (Chapters 5–13)

1. Read `docs/trait-composition-contract.md` §§1–3.
2. Identify which dispatch targets the trait needs to override. Must be a subset of `DISPATCH_TARGETS`. If you need a new target, stop — see §3.5 below.
3. In `strategic-jl/src/chapters/chNN_*.jl`:
   - Define the struct `<ChapterName>Trait <: GameTrait`.
   - Override only the declared dispatch targets on `WithTrait{<:AbstractGame, <YourTrait>}`.
   - Immediately after the struct definition, call `register_trait!(YourTrait, Set([:target1, :target2]))`.
4. Add a JGDL `TraitType` variant if the enum doesn't already cover it (`jgdl/schema/v1.0.0.schema.json` §`Trait`).
5. Implement serialize / deserialize symmetry. A round-trip test must pass: `from_jgdl(to_jgdl(world)) == world`.
6. Add a compliance case in `jgdl/compliance/compliance_suite.json`:
   - One case exercising the trait alone.
   - One case stacked with a trait touching a **disjoint** target (orthogonal composition).
   - If the trait collides with an existing one on the same target, one case stacked in both orders, asserting the known order-dependent difference.
7. Update `docs/trait-composition-contract.md` §4 trait-to-target matrix.
8. If the trait commutes with any existing trait, file a follow-up to add the Phase-2 commutativity annotation.
9. Run the test suite. The composition test will fail if the registry entry is inconsistent with the overrides.

### 3.2 Adding a Tale (Chapter 1 corpus)

1. Read `strategic-jl/src/chapters/ch01_tales.jl` for the `Tale` schema.
2. Write the JGDL fixture: `jgdl/examples/tales/<tale_name>.json` with:
   - A placeholder `world.id` (hash computed by tests).
   - Populated `metadata.chapter_references` listing all chapters the tale illustrates.
   - A `provenance` entry citing the theoretical origin (usually Schelling, Dixit & Nalebuff, or Axelrod).
3. Add the `Tale(...)` entry to the `TALES` registry with concept tags.
4. Add a compliance case in `jgdl/compliance/compliance_suite.json` with the `jgdl_ref` pointing to the fixture and an `expected` block describing the expected solver output.
5. Verify the tale round-trips through JGDL and that the expected outcome is produced once the solver is implemented.

### 3.3 Writing solver code

1. Every solver returns a `Solution` whose `provenance_chain` is non-empty and captures every meaningful step.
2. Memoize on `state_key(s)` (see `core/tree.jl`). Never materialize the full game tree — the tree is lazy.
3. If the solver reduces the strategy space (e.g. iterated dominance), append a `ProvenanceNode` for every elimination with a chapter citation.
4. Do not emit free-form explanation strings from the solver. Return data (structured records); let downstream layers render.

### 3.4 Writing an MCP tool (Phase 4)

1. Read `strategic-rs/crates/strategic-mcp/src/tools.rs` for the existing tool definitions.
2. Every tool response is a structured record plus a provenance chain. Do not emit free-form text that makes strategic claims.
3. The tool must operate on session state stored in `McpServer::sessions`, keyed by content-addressable world id.
4. If the tool produces a new world (mutation), it must compute the new hash and append a `ProvenanceNode` citing the cause.

### 3.5 Adding a new dispatch target

This is a **core change**, not a trait change. Rare.

1. File an issue describing why the existing targets are insufficient. Include at least one concrete trait the new target would enable.
2. Update `DISPATCH_TARGETS` in `strategic-jl/src/core/traits.jl`.
3. Update `docs/trait-composition-contract.md` §2 table with the new target.
4. Add a default implementation on `AbstractGame` (usually an `error("…")` that says which trait must override it).
5. Add a delegation through `WithTrait` so inner traits still get reached.
6. Only then proceed with the trait that motivated the change.

### 3.6 Adding an explanation surface

The only correct answer: **don't add one that bypasses provenance.**

- If you're tempted to generate strategic text outside the provenance chain, stop. That's exactly the hallucination surface this architecture exists to prevent.
- If the provenance chain is missing information that an explanation needs, the fix is to make the engine record more provenance — not to invent text at the rendering layer.
- Surface-level niceties (headings, formatting, layout) are fine. Strategic claims are not.

---

## 4. Testing expectations

- Every PR that touches `strategic-jl/` runs `julia --project=strategic-jl -e 'using Pkg; Pkg.test()'`.
- Every PR that touches `strategic-rs/` runs `cargo test --workspace`.
- Every PR that touches the JGDL schema, a chapter trait, or a solver must pass the compliance suite in both languages.
- The composition test (`strategic-jl/test/composition.jl`) enumerates trait pairs; adding a trait without a registry entry fails module load.

---

## 5. Anti-patterns (do not do these)

| Anti-pattern | Why it breaks things |
|---|---|
| Constructing `WithTrait{G, T}` directly, bypassing `with_trait()` | Skips provenance append; explanation layer loses its grounding |
| Returning a `Solution` with an empty `provenance_chain` | Constructor will throw; don't try to work around it |
| Generating explanation text in a solver | Solvers return data; rendering is a downstream concern |
| Adding a trait without calling `register_trait!` | Composition test fails; module-load check will eventually catch it |
| Overriding a dispatch target not declared in the trait's registry entry | Same as above |
| Modifying `jgdl/schema/v1.0.0.schema.json` casually | Schema version is the contract. Bump it, don't edit in place |
| Implementing Phase 4 features when Phase 1 has stubs | Respect the dependency order; foundation-before-modifiers applies across phases too |
| Adding a Chapter 5–13 trait that needs a Ch 1–4 primitive still stubbed | Finish the foundation first |
| Building a case-study catalog | Case studies are tests, not features. See `roadmap.md` non-goals |
| Introducing a chat wrapper around the engine | The LLM layer explains; it doesn't substitute for the engine |
| Adding ergonomic sugar that doesn't round-trip through JGDL | JGDL is the canonical form; sugar that can't serialize fractures composition |

---

## 6. When to ask the human

- Any change to the JGDL schema.
- Any new dispatch target.
- Any change to the provenance contract.
- Any phase you're about to start that isn't the current phase in `roadmap.md`.
- Any bypass of the trait composition contract, even "just for this one case."
- Any LLM explanation surface that isn't reading strictly from provenance.

These are not bureaucratic gates. Each of them is where the architecture's guarantees live. A well-meaning shortcut at any of these points silently removes the property the rest of the system is built to preserve.

---

## 7. Spirit, not just letter

The rules above are concrete. The spirit behind them is simpler:

- **Composition is the product.** Don't add anything that doesn't cleanly compose.
- **Provenance is the substrate.** Don't claim anything the engine didn't produce.
- **The user composes; the toolkit explains; neither substitutes for the other.**

When a rule doesn't obviously apply to your case, ask: does my change preserve those three? If yes, proceed. If no, or if you're unsure, ask the human.
