# strategic-rs

Rust workspace. Owns Phase 4 (MCP server) and Phase 6 (WASM) of the roadmap.

## Crates

| Crate | Responsibility |
|---|---|
| `strategic-core` | JGDL types, schema validation, content addressing. Mirrors `Strategic.jl` semantics. |
| `strategic-solver` | Fast forward solver (backward induction). Validates against Julia oracle via compliance suite. |
| `strategic-mcp` | MCP server binary. Tools: `instantiate_world`, `solve_world`, `mutate_world`, `infer_from_observations`, `detect_surprise`, `explain_from_provenance`. |
| `strategic-wasm` | Browser-native compile target (Phase 6, conditional). |

## Build

```
cargo build --workspace
cargo test --workspace
```

## Design constraints

- `strategic-core` serialization must be byte-for-byte identical to `Strategic.jl`'s JGDL output for the same world.
- No tool in `strategic-mcp` may return free-form strategic claims; every response is built from a provenance chain produced by the core engine.
- The inverse solver in Rust is intentionally empty for v1; inverse calls route to Julia.
