use std::collections::HashMap;
use strategic_core::{StrategicWorld, State};

pub struct ValueCache {
    cache: HashMap<u64, HashMap<String, f64>>,
}

impl ValueCache {
    pub fn new() -> Self {
        Self { cache: HashMap::new() }
    }
}

impl Default for ValueCache {
    fn default() -> Self {
        Self::new()
    }
}

/// Memoized backward induction.
///
/// Phase 4 skeleton — tasks.md 4.2.
pub fn backward_induction(
    _world: &StrategicWorld,
    _state: &State,
    _cache: &mut ValueCache,
) -> HashMap<String, f64> {
    // TODO: walk the lazy tree, memoize on state hash, return payoffs.
    HashMap::new()
}
