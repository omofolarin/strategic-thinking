use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProvenanceNode {
    /// Optional UUID v4. Populated when the producing engine wants
    /// downstream layers (LLM explanations, web composer) to be able
    /// to reference this specific node by id.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub id: Option<String>,
    pub operation: String,
    /// Populated iff `operation == "applied_trait"`. One of the
    /// TraitType enum values. Split from `operation` so explanation
    /// layers can group by trait family without string parsing.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub trait_type: Option<String>,
    pub chapter_ref: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub theoretical_origin: Option<String>,
    #[serde(default)]
    pub rationale: String,
    pub parent_id: String,
    pub timestamp: String,
    pub author: Author,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Author {
    User,
    Llm,
    System,
}
