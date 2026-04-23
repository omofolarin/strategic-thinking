{
  "suite": "Strategic Compliance Tests",
  "version": "1.0.0",
  "description": "Cross-language compliance suite. Every JGDL implementation (Julia, Rust, TypeScript) must produce the expected result for every authored case. Skeleton cases are placeholders awaiting Phase 1–3 implementation.",
  "convention": {
    "authored_cases": "Individual JSON files under tests/. Each contains an embedded jgdl block + expected block.",
    "skeleton_cases": "Inline entries with jgdl_ref = null. Become authored when their phase lands."
  },
  "cases": [
    {
      "id": "compliance_ch02_001",
      "status": "authored",
      "test_path": "tests/chapter02_entry_game.json",
      "chapter": "Chapter 2",
      "description": "Sequential market entry — threat of fight is not subgame-perfect."
    },
    {
      "id": "compliance_ch04_001",
      "status": "authored",
      "test_path": "tests/chapter04_prisoners_dilemma.json",
      "chapter": "Chapter 4",
      "description": "One-shot PD — strict dominance gives (Defect, Defect)."
    },
    {
      "id": "compliance_ch06_001",
      "status": "authored",
      "test_path": "tests/chapter06_credible_commitment.json",
      "chapter": "Chapter 6",
      "description": "Burned bridge — removing own action makes the threat credible; equilibrium flips to StayOut."
    },
    {
      "id": "ch04_pd_repeated_tft",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Chapter 4",
      "description": "Repeated PD under Tit-for-Tat. Cooperation sustained at high discount factor."
    },
    {
      "id": "ch05_commitment",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Chapter 5",
      "description": "Commitment device alters payoff; outcome shifts vs. baseline."
    },
    {
      "id": "ch07_matching_pennies",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Chapter 7",
      "description": "Zero-sum matching pennies. Unique mixed equilibrium at 0.5/0.5."
    },
    {
      "id": "ch08_brinkmanship",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Chapter 8",
      "description": "Escalation carries stochastic catastrophic risk."
    },
    {
      "id": "ch09_focal_point",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Chapter 9",
      "description": "Coordination with focal point."
    },
    {
      "id": "ch10_condorcet",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Chapter 10",
      "description": "Condorcet paradox in three-option voting."
    },
    {
      "id": "ch11_alternating_offers",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Chapter 11",
      "description": "Rubinstein alternating-offers bargaining."
    },
    {
      "id": "ch12_tournament",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Chapter 12",
      "description": "Relative-payoff incentive dominates absolute."
    },
    {
      "id": "ch13_bayesian_auction",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Chapter 13",
      "description": "Bidder strategy depends on prior over opponent value."
    },
    {
      "id": "composition_three_traits",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Composition",
      "description": "Commitment + Brinkmanship + Bayesian stacked. Dispatch must resolve unambiguously."
    },
    {
      "id": "composition_sequential_mixed",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Composition",
      "description": "Sequential + MixedStrategy. Information sets respected."
    },
    {
      "id": "inverse_ranks_pd_over_coordination",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Inverse",
      "description": "Defection-heavy observations rank PD above coordination."
    },
    {
      "id": "inverse_detects_payoff_shift",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Inverse",
      "description": "Mid-stream behavioral change flagged as objective-function-changed."
    },
    {
      "id": "antifragile_new_player",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Antifragile",
      "description": "Actions not attributable to known players trigger player discovery."
    },
    {
      "id": "antifragile_latent_confounder",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Antifragile",
      "description": "Correlated actions without direct causation flag a latent confounder."
    },
    {
      "id": "antifragile_hedge_activation",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Antifragile",
      "description": "Surprise event triggers hedge per its trigger condition."
    },
    {
      "id": "provenance_integrity",
      "status": "skeleton",
      "test_path": null,
      "chapter": "Cross-cutting",
      "description": "Every Solution returned carries a non-empty provenance chain."
    }
  ]
}
