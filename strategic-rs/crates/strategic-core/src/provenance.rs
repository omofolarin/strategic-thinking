use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProvenanceNode {
    pub operation: String,
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
