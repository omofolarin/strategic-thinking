//! MCP server skeleton. Every tool response is built from a provenance chain;
//! the server never emits free-form strategic claims.
//!
//! Phase 4 — tasks.md 4.3 / 4.4.

use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::Mutex;

use strategic_core::StrategicWorld;

#[derive(Default)]
pub struct Session {
    pub world: Option<StrategicWorld>,
    pub observation_history: Vec<serde_json::Value>,
}

pub struct McpServer {
    pub sessions: Arc<Mutex<HashMap<String, Session>>>,
}

impl McpServer {
    pub fn new() -> Self {
        Self {
            sessions: Arc::new(Mutex::new(HashMap::new())),
        }
    }
}

impl Default for McpServer {
    fn default() -> Self {
        Self::new()
    }
}
