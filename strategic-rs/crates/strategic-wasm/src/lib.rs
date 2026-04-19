//! strategic-wasm — Browser-native strategic reasoning.
//!
//! Phase 6 — only compiled once server round-trip or deployment friction
//! justifies it.

use wasm_bindgen::prelude::*;

#[wasm_bindgen]
pub fn version() -> String {
    env!("CARGO_PKG_VERSION").to_string()
}
