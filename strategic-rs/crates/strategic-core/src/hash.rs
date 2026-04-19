use sha2::{Digest, Sha256};

use crate::game::StrategicWorld;

/// Canonical content hash for a StrategicWorld. The id field is excluded
/// from the hash input so that `world.id` always equals the hash of the
/// rest of the document.
///
/// Phase 1 — must match Strategic.jl byte-for-byte. See tasks.md 1.5.
pub fn compute(_world: &StrategicWorld) -> String {
    // TODO: canonicalize JSON, hash, match Julia's implementation exactly.
    let mut hasher = Sha256::new();
    hasher.update(b"placeholder");
    let digest = hasher.finalize();
    let hex: String = digest.iter().map(|b| format!("{:02x}", b)).collect();
    format!("sha256:{}", hex)
}
