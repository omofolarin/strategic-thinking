# Contributing

Thank you for looking at this. This project is pre-alpha — the scaffolding is in place, but most Phase 1 tasks are open. Contributions are welcome.

## Before you start

Please read these in order:

1. **[`AGENTS.md`](./AGENTS.md)** — the contracts every contribution must uphold. Non-negotiable. The provenance, trait-composition, and JGDL invariants are load-bearing; violating them silently breaks guarantees the rest of the system depends on.
2. **[`docs/composition-architecture.md`](./docs/composition-architecture.md)** — why the toolkit composes. The four layers.
3. **[`docs/trait-composition-contract.md`](./docs/trait-composition-contract.md)** — normative rules for trait authors.
4. **[`docs/glossary.md`](./docs/glossary.md)** — JGDL term and type reference.
5. **[`roadmap.md`](./roadmap.md)** + **[`tasks.md`](./tasks.md)** — what needs doing and in what order.

If your change isn't in the current phase's task list, please open an issue first.

## How to contribute

### Reporting a bug

Open an issue with:
- A minimal JGDL document (or code) reproducing the problem
- Expected behavior per `docs/glossary.md` or the trait contract
- Actual behavior
- Which implementation (Julia, Rust, TypeScript)

### Proposing a new trait, Tale, or primitive

Open an issue first. A proposal should answer:
- Which Dixit–Nalebuff chapter does this draw from?
- Which dispatch target does it need to override? (Must be listed in `DISPATCH_TARGETS`.)
- Which Tale would this make expressible that wasn't before?
- Does it collide on a dispatch target with any existing trait?

If accepted, the implementation workflow is in `AGENTS.md` §3.1 (traits) or §3.2 (Tales).

### Submitting a pull request

Mergeable PRs must:

- [ ] Keep the compliance suite green in both Julia (`strategic-jl/`) and Rust (`strategic-rs/`) where applicable.
- [ ] Pass the composition test (`strategic-jl/test/composition.jl`).
- [ ] Preserve provenance integrity: no `Solution` returned without a non-empty `provenance_chain`; no trait bypassing `with_trait()`.
- [ ] Update `docs/trait-composition-contract.md` §4 (trait-to-target matrix) when adding or changing a trait.
- [ ] Update `docs/glossary.md` when adding or changing a JGDL field or type.
- [ ] Include tests. The compliance suite is the canonical test surface.
- [ ] Describe the change in one paragraph in the PR body, citing the chapter(s) it draws from and the tasks.md item it closes.

### Commit style

Short, imperative first line. Scope prefix optional but helpful: `core:`, `jgdl:`, `mcp:`, `docs:`, `test:`.

Examples:
```
core: add IteratedDominance solver

jgdl: tighten Expression grammar to exclude module access

docs: clarify provenance invariant in composition architecture
```

## Architectural rules that matter

These come from `AGENTS.md` but are worth highlighting:

1. **Composition is the product.** Changes that add features but don't compose cleanly — e.g. special-case paths that bypass the trait system — will be rejected even if they work in isolation.
2. **Provenance is the substrate for explanation.** Don't generate strategic claims outside the provenance chain. If you find yourself writing explanatory text in a solver or tool handler, stop.
3. **Foundation before modifiers.** Chapters 1–4 are the substrate. A Chapter 5+ trait that depends on an unimplemented Ch 1–4 primitive is not yet ready.
4. **Forward and inverse are peers.** When adding a primitive, consider how it participates in both directions. Inverse is not a sidecar.
5. **Phase discipline.** Don't build Phase 4 features when Phase 1 has stubs. Check `roadmap.md`.

## Code of conduct

Be kind. Assume good intent. Disagreements about architecture are welcome; disagreements about people are not.

This project follows the [Contributor Covenant](https://www.contributor-covenant.org/) v2.1 in spirit. Report conduct issues to folarinshonibare@gmail.com.

## License

By contributing, you agree that your contributions will be licensed under the Apache License, Version 2.0 — the same license as the project. See [`LICENSE`](./LICENSE).
