use serde_json::Value;
use thiserror::Error;

use crate::game::StrategicWorld;

#[derive(Debug, Error)]
pub enum JgdlError {
    #[error("JSON parse error: {0}")]
    Parse(#[from] serde_json::Error),
    #[error("schema validation failed: {0:?}")]
    Schema(Vec<ValidationError>),
    #[error("integrity hash mismatch: expected {expected}, got {actual}")]
    HashMismatch { expected: String, actual: String },
}

#[derive(Debug, Clone)]
pub struct ValidationError {
    pub path: String,
    pub message: String,
}

/// Parse a JGDL JSON string into a StrategicWorld, running schema validation
/// and integrity-hash verification.
///
/// Phase 0/1 skeleton — tasks.md 0.1 and 4.1.
pub fn parse(json_str: &str) -> Result<StrategicWorld, JgdlError> {
    let _value: Value = serde_json::from_str(json_str)?;
    // TODO: run jsonschema validation against schema/v1.0.0.schema.json
    // TODO: verify world.id matches hash::compute(&world)
    Err(JgdlError::Schema(vec![ValidationError {
        path: "$".into(),
        message: "parse() not yet implemented".into(),
    }]))
}

/// Serialize a StrategicWorld to a canonical JGDL JSON string.
pub fn serialize(_world: &StrategicWorld) -> Result<String, JgdlError> {
    // TODO: canonicalize and serialize; must match Julia byte-for-byte.
    Ok(String::new())
}
