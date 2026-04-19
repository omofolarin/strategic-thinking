//! strategic-solver — Fast backward induction and Nash solvers in Rust.
//!
//! Validates every output against the Julia oracle via the shared JGDL
//! compliance suite. The inverse solver lives in Julia for v1.

pub mod backward;
pub mod inverse;

pub use backward::{backward_induction, ValueCache};
