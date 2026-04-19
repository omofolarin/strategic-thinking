# Changelog

All notable changes to this project will be documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Initial scaffold across Julia core (`strategic-jl/`), Rust workspace (`strategic-rs/`), and TypeScript frontend (`strategic-web/`).
- JGDL v1.0.0 JSON Schema (`jgdl/schema/v1.0.0.schema.json`).
- Compliance suite skeleton with 20 cases (`jgdl/compliance/compliance_suite.json`).
- Foundation chapter scaffolds (Ch 1–4) — reference tales corpus, sequential-reasoning primitives, iterated dominance solver, reciprocity strategies.
- Modifier chapter scaffolds (Ch 5–13) — Commitment, CredibleThreat, BurnedBridge, MixedStrategy, Brinkmanship, CoordinationDevice, VotingRule, BargainingProtocol, TournamentIncentive, BayesianBelief, LearningRule.
- Trait-composition contract (`docs/trait-composition-contract.md`) with dispatch-target registry and collision resolution rules.
- Composition architecture document (`docs/composition-architecture.md`).
- JGDL glossary (`docs/glossary.md`).
- Chicken tale as first reference JGDL fixture.
- Apache 2.0 license.

### Notes
- All solvers, DSL macros, and JGDL serialize/deserialize functions are stubs that throw `"Phase N: not yet implemented"` errors. Scaffolding is complete; Phase 0 (JGDL contract) is the next deliverable.
- Rust workspace compiles clean against latest crate versions (Cargo 1.94; dependencies pinned to latest as of April 2026).
