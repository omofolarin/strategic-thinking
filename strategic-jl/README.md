# Strategic.jl

Julia core engine. Owns Phases 1–3 (forward toolkit, inverse toolkit, antifragile affordances).

## Layout

```
src/
  Strategic.jl              Top-level module
  core/                     Types, traits, provenance, lazy tree
  chapters/                 One file per Dixit–Nalebuff chapter primitive
  solvers/
    forward/                Backward induction, Nash
    inverse/                Bayesian inference, hypothesis narrowing
  antifragile/              Open world, surprise, player discovery, hedges
  jgdl/                     Serialize / deserialize / validate
  dsl/                      @strategic macro

test/                       Compliance suite runner
notebooks/                  Pluto explorer
```

## Running tests

```
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Non-goals for this package

- No HTTP / MCP server (that lives in `strategic-rs`).
- No browser / visualization code (that lives in `strategic-web`).
- No hosted LLM calls from the engine itself.
