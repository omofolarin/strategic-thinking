//! strategic-core — JGDL types, schema validation, content addressing.
//!
//! This crate mirrors the semantics of `Strategic.jl` for the serialized
//! world layer. It does not contain solvers (see `strategic-solver`) or
//! network code (see `strategic-mcp`).

pub mod game;
pub mod jgdl;
pub mod provenance;
pub mod hash;

pub use game::*;
pub use jgdl::{parse, serialize, ValidationError};
pub use provenance::ProvenanceNode;
