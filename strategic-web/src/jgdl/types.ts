/**
 * TypeScript types mirroring jgdl/schema/v1.1.0.schema.json.
 * Hand-maintained for v1; generate from JSON Schema once the schema stabilizes.
 */

export type Author = "user" | "llm" | "system";

export interface ProvenanceNode {
  /** Optional UUID v4 — stable reference for downstream explanation layers. */
  id?: string;
  /** Canonical values: initial_construction, applied_trait, inferred_hypothesis,
   *  ruled_out_hypothesis, detected_surprise, discovered_player, activated_hedge,
   *  elicited_payoff_layer, elicited_world. Free-form strings allowed. */
  operation: string;
  /** Populated iff operation === "applied_trait". */
  trait_type?: TraitType;
  chapter_ref: string;
  theoretical_origin?: string;
  rationale: string;
  /** world.id before this operation. Empty string for initial_construction. */
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
  /** 1.0 = fully rational; lower values model bounded rationality (Chapter 7). */
  rationality_factor?: number;
  /** Chapter 11 patience parameter. 1.0 = no time discount. */
  discount_rate?: number;
  /** Chapter 8 sensitivity to catastrophic payoffs. */
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
  /** Expression subtracted from player payoff if action is taken. */
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
  /** Probability that an unobserved player or action emerges in a given round. */
  emergence_rate?: number;
  unknown_player_pool?: Record<string, unknown>;
  shadow_player?: Record<string, unknown>;
}

export interface Hedge {
  id: string;
  /** Boolean expression over observations and state. See docs/expression-language.md. */
  trigger: string;
  payoff_profile: Record<string, unknown>;
  cost?: number;
  optionality_value?: number;
  chapter_reference?: string;
}

export interface World {
  /** sha256:<64 hex chars> — content hash excluding this field. */
  id: string;
  metadata?: Metadata;
  players: Player[];
  actions: Action[];
  structure: Structure;
  payoffs: Payoffs;
  /** Ordered. Composition order is semantically significant. */
  traits?: Trait[];
  initial_state: State;
  provenance: ProvenanceNode[];
  open_world?: OpenWorld;
  hedges?: Hedge[];
  /** v1.1.0. Present when payoffs were constructed via LLM-assisted elicitation. */
  elicitation?: ElicitationRecord;
}

export interface JgdlDocument {
  version: "1.0.0" | "1.1.0";
  world: World;
}

// ── v1.1.0 — LLM-assisted payoff elicitation ─────────────────────────────────

/** The five value layers used in context-driven payoff elicitation.
 *  See docs/context-driven-payoff-design.md. */
export type PayoffLayer = "material" | "social" | "temporal" | "identity" | "uncertainty";

export interface PayoffLayerEstimate {
  layer: PayoffLayer;
  point_estimate: number;
  /** 0–1. Below 0.5 signals the estimate should be treated as a weak prior. */
  confidence: number;
  /** One sentence justifying the estimate. Cited by the LLM explanation layer. */
  reasoning: string;
}

export interface ElicitedOutcomePayoff {
  player_id: string;
  /** e.g. "cooperate_1.cooperate_2" */
  outcome_key: string;
  /** Sum of all layer point_estimates. This is the value used in the payoff matrix. */
  total: number;
  mean_confidence: number;
  layers: PayoffLayerEstimate[];
}

export interface ElicitationRecord {
  /** The natural language description the LLM was given. */
  description: string;
  /** Average confidence across all layer estimates. */
  mean_confidence: number;
  entries: ElicitedOutcomePayoff[];
}
