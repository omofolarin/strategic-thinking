//! MCP tool definitions. Every tool operates on (or produces) JGDL and
//! returns provenance-grounded responses.
//!
//! Phase 4 — tasks.md 4.3.

use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolDefinition {
    pub name: &'static str,
    pub description: &'static str,
}

pub const TOOLS: &[ToolDefinition] = &[
    ToolDefinition {
        name: "instantiate_world",
        description: "Create a session world from a JGDL JSON document.",
    },
    ToolDefinition {
        name: "solve_world",
        description: "Compute equilibrium; response carries its provenance chain.",
    },
    ToolDefinition {
        name: "mutate_world",
        description: "Apply a trait (Commitment, BurnedBridge, Brinkmanship, ...) to the session world.",
    },
    ToolDefinition {
        name: "infer_from_observations",
        description: "Run the inverse solver over observations; returns ranked hypothesis worlds.",
    },
    ToolDefinition {
        name: "detect_surprise",
        description: "Flag whether recent observations violate the current world model.",
    },
    ToolDefinition {
        name: "explain_from_provenance",
        description: "Natural-language explanation grounded strictly in the provenance chain.",
    },
];
