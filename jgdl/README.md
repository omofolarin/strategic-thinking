# JGDL — JSON Game Description Language

The serialization contract that binds every implementation (Julia, Rust, TypeScript) together.

For a term-by-term reference of every type and field, see **`docs/glossary.md`**.

**The schema is load-bearing.** Every other artifact in this repo regenerates from it. Lock it down early; version it hard.

## Layout

```
schema/       Versioned JSON Schema. v1.0.0 is the initial baseline.
examples/     Hand-authored reference JGDL documents, one per chapter concept.
compliance/   Cross-language compliance suite (test skeleton).
```

## Versioning rules

- `v1.0.0` is the initial baseline (forward-only).
- Additive changes (new optional fields) → minor bump (`v1.1.0`).
- Breaking changes → major bump, migration script required.
- `open_world` and `hedges` are already present as optional in `v1.0.0` so Phase 3 does not require a bump.

## Compliance suite

Every case has either an inline `jgdl` block or a `jgdl_ref` pointing to an `examples/` file. Every case has an `expected` block describing what a conforming implementation must produce.

Both the Julia and Rust implementations run the same suite on every PR.
