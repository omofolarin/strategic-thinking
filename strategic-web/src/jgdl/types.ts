// TypeScript types mirroring jgdl/schema/v1.0.0.schema.json.
// For v1 these are hand-maintained; once the schema stabilizes,
// generate these from the JSON Schema.

export type Author = "user" | "llm" | "system";

export interface ProvenanceNode {
  /** Optional UUID v4 — stable reference for downstream explanation layers. */
  id?: string;
  operation: string;
  /** Populated iff operation === "applied_trait". */
  trait_type?: TraitType;
  chapter_ref: string;
  theoretical_origin?: string;
  rationale: string;
  parent_id: string;
  timestamp: string;
  author: Author;
}

export type PlayerType =
  | "rational"
  | "bounded_rational"
  | "human_oracle"
  | "llm_driven"
  | "shadow";

export interface PlayerParameters {
  rationality_factor?: number;
  discount_rate?: number;
  risk_aversion?: number;
}

export interface Player {
  id: string;
  name?: string;
  type: PlayerType;
  parameters?: PlayerParameters;
}

export interface Action {
  id: string;
  name?: string;
  player_id: string;
  cost?: string;
  observability?: "public" | "private" | "delayed";
}

export type Structure =
  | { type: "simultaneous" }
  | { type: "sequential"; order: string[] }
  | { type: "repeated"; repetitions: number | "infinite"; discount_factor?: number }
  | { type: "stochastic"; transition_probs?: Record<string, number> };

export type Payoffs =
  | { type: "terminal_matrix"; matrix: Record<string, Record<string, number>> }
  | { type: "function"; function: string; dependencies?: string[] }
  | { type: "cached" };

export type TraitType =
  | "Commitment"
  | "CredibleThreat"
  | "BurnedBridge"
  | "MixedStrategy"
  | "Brinkmanship"
  | "CoordinationDevice"
  | "VotingRule"
  | "BargainingProtocol"
  | "TournamentIncentive"
  | "BayesianBelief"
  | "LearningRule";

export interface Trait {
  id: string;
  type: TraitType;
  chapter: string;
  applies_to?: "player" | "game" | "payoff" | "action";
  parameters?: Record<string, unknown>;
}

export interface State {
  variables?: Record<string, unknown>;
  history?: unknown[];
  current_player?: string | null;
  round?: number;
}

export interface Metadata {
  name?: string;
  description?: string;
  chapter_references?: string[];
  created?: string;
}

export interface OpenWorld {
  emergence_rate?: number;
  unknown_player_pool?: Record<string, unknown>;
  shadow_player?: Record<string, unknown>;
}

export interface Hedge {
  id: string;
  trigger: string;
  payoff_profile: Record<string, unknown>;
  cost?: number;
  optionality_value?: number;
  chapter_reference?: string;
}

export interface World {
  id: string;
  metadata?: Metadata;
  players: Player[];
  actions: Action[];
  structure: Structure;
  payoffs: Payoffs;
  traits?: Trait[];
  initial_state: State;
  provenance: ProvenanceNode[];
  open_world?: OpenWorld;
  hedges?: Hedge[];
  elicitation?: ElicitationRecord;
}

export interface JgdlDocument {
  version: "1.0.0" | "1.1.0";
  world: World;
}

// v1.1.0 — LLM-assisted payoff elicitation types

export type PayoffLayer = "material" | "social" | "temporal" | "identity" | "uncertainty";

export interface PayoffLayerEstimate {
  layer: PayoffLayer;
  point_estimate: number;
  confidence: number;  // 0–1
  reasoning: string;
}

export interface ElicitedOutcomePayoff {
  player_id: string;
  outcome_key: string;
  total: number;
  mean_confidence: number;
  layers: PayoffLayerEstimate[];
}

export interface ElicitationRecord {
  description: string;
  mean_confidence: number;
  entries: ElicitedOutcomePayoff[];
}
