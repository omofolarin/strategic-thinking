use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use crate::provenance::ProvenanceNode;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StrategicWorld {
    pub id: String, // sha256:...
    #[serde(default)]
    pub metadata: Metadata,
    pub players: Vec<Player>,
    pub actions: Vec<Action>,
    pub structure: Structure,
    pub payoffs: Payoffs,
    #[serde(default)]
    pub traits: Vec<Trait>,
    pub initial_state: State,
    pub provenance: Vec<ProvenanceNode>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub open_world: Option<OpenWorld>,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub hedges: Vec<Hedge>,
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct Metadata {
    #[serde(default)]
    pub name: String,
    #[serde(default)]
    pub description: String,
    #[serde(default)]
    pub chapter_references: Vec<String>,
    #[serde(default)]
    pub created: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Player {
    pub id: String,
    #[serde(default)]
    pub name: String,
    #[serde(rename = "type")]
    pub player_type: PlayerType,
    #[serde(default)]
    pub parameters: PlayerParameters,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PlayerType {
    Rational,
    BoundedRational,
    HumanOracle,
    LlmDriven,
    Shadow,
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct PlayerParameters {
    #[serde(default)]
    pub rationality_factor: Option<f64>,
    #[serde(default)]
    pub discount_rate: Option<f64>,
    #[serde(default)]
    pub risk_aversion: Option<f64>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Action {
    pub id: String,
    #[serde(default)]
    pub name: String,
    pub player_id: String,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cost: Option<String>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub observability: Option<Observability>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum Observability {
    Public,
    Private,
    Delayed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Structure {
    Simultaneous,
    Sequential {
        order: Vec<String>,
    },
    Repeated {
        repetitions: Repetitions,
        #[serde(default)]
        discount_factor: Option<f64>,
    },
    Stochastic {
        #[serde(default)]
        transition_probs: HashMap<String, f64>,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(untagged)]
pub enum Repetitions {
    Finite(u32),
    Infinite(String),
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Payoffs {
    TerminalMatrix {
        matrix: HashMap<String, HashMap<String, f64>>,
    },
    Function {
        function: String,
        #[serde(default)]
        dependencies: Vec<String>,
    },
    Cached,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Trait {
    pub id: String,
    #[serde(rename = "type")]
    pub trait_type: TraitType,
    pub chapter: String,
    #[serde(default)]
    pub applies_to: Option<String>,
    #[serde(default)]
    pub parameters: serde_json::Value,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum TraitType {
    Commitment,
    CredibleThreat,
    BurnedBridge,
    MixedStrategy,
    Brinkmanship,
    CoordinationDevice,
    VotingRule,
    BargainingProtocol,
    TournamentIncentive,
    BayesianBelief,
    LearningRule,
}

#[derive(Debug, Default, Clone, Serialize, Deserialize)]
pub struct State {
    #[serde(default)]
    pub variables: serde_json::Value,
    #[serde(default)]
    pub history: Vec<serde_json::Value>,
    #[serde(default)]
    pub current_player: Option<String>,
    #[serde(default)]
    pub round: u32,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct OpenWorld {
    #[serde(default)]
    pub emergence_rate: f64,
    #[serde(default)]
    pub unknown_player_pool: Option<serde_json::Value>,
    #[serde(default)]
    pub shadow_player: Option<serde_json::Value>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Hedge {
    pub id: String,
    pub trigger: String,
    pub payoff_profile: serde_json::Value,
    #[serde(default)]
    pub cost: f64,
    #[serde(default)]
    pub optionality_value: f64,
    #[serde(default)]
    pub chapter_reference: String,
}
