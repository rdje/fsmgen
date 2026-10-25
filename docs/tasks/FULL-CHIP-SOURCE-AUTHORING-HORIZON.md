# FULL-CHIP-SOURCE-AUTHORING-HORIZON: Complete digital-chip source authoring

## Metadata

- Tree ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON`
- Status: `proposed`
- Roadmap lane: `R14 / long-term full-chip source authoring`
- Created: `2026-10-25`
- Last updated: `2026-10-25`
- Owner: repo-local workflow

## Goal

FSMGen becomes an elegant, efficient and credible end-to-end authoring environment
for complete real digital CPU, DSP, MCU, ASIC and SoC designs. Both IAL1 and IAL2
are intended entry points with the necessary capability for that outcome. The
end product is complete implementation-ready source code. VIAL supports initial
functional verification. The director's DBIQNP clarifications below own the objective.
Every IAL1 and IAL2 design feature must have a beautiful, elegant, expressive,
efficient Lispish/S-expression form without useless verbosity.

## Non-Goals

- No activation or implementation pivot from the 2026-10-25 DBIQNP discussion.
- No claim that present IAL1, IAL2 or VIAL already has full-chip completeness.
- No synthesis, physical implementation, fabrication or backend signoff engine.
- No requirement that authors handwrite RTL to fill permanent IAL feature gaps.
- No promise of identical syntax at both intent layers or an unmeasured speedup.

## Acceptance Criteria

- Each layer can serve as an authoring entry point for a complete digital chip,
  with explicit composition/refinement and faithful IAL2 -> IAL1 -> IAL0 lowering.
- Every HIAL and VIAL construct has a defined, reviewable path through
  IAL2 -> IAL1 -> IAL0 -> SystemVerilog/VHDL. Each adjacent lowering preserves
  its specified semantics and source identity; no upper-layer feature can be
  complete while its required lower-layer realization remains missing.
- Every design feature has a complete Lispish/S-expression authoring surface:
  concise common cases, consistent vocabulary and scope, composable reusable
  forms, and readable detailed control. Required semantics remain explicit.
- Representative real source examples demonstrate language quality. Repeated
  boilerplate and unnecessary verbosity need a design reason, not acceptance
  merely because the parser handles them. Concision cannot hide timing, width,
  clock/reset, ownership or configuration meaning.
- API/MCP operations cover the same design capabilities and can materialize
  readable source with semantic round-trip fidelity. A design feature exposed
  only through an API does not satisfy language completeness. Operational tool
  calls remain separate from design-language constructs.
- Design semantics, source expressiveness, compiler correctness, ergonomics,
  source-quality qualification and verification maturity have separate evidence.
- Representative complete designs, independent semantic oracles and invalid
  configuration controls qualify capability; parser acceptance alone cannot.
- Output is a self-consistent source tree with complete hierarchy, interfaces,
  types, configuration and design semantics consumable by external backend tools.
- Public source features have corpus/API/MCP applicability, runnable book examples
  and focused verification, with complete verification after feature completion.
- State-of-the-art claims require a named design class and independently checked
  criteria. Downstream backend success is not inferred from source generation.

## Task Tree

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON`
  Status: `proposed`
  Goal: `Deliver complete digital-chip source authoring through both IAL1 and IAL2, with initial VIAL verification.`
  Children: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.1, FULL-CHIP-SOURCE-AUTHORING-HORIZON.2, FULL-CHIP-SOURCE-AUTHORING-HORIZON.3, FULL-CHIP-SOURCE-AUTHORING-HORIZON.4, FULL-CHIP-SOURCE-AUTHORING-HORIZON.5, FULL-CHIP-SOURCE-AUTHORING-HORIZON.6, FULL-CHIP-SOURCE-AUTHORING-HORIZON.7, FULL-CHIP-SOURCE-AUTHORING-HORIZON.8, FULL-CHIP-SOURCE-AUTHORING-HORIZON.9, FULL-CHIP-SOURCE-AUTHORING-HORIZON.10, FULL-CHIP-SOURCE-AUTHORING-HORIZON.11`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.1`
  Status: `done`
  Goal: `Preserve the director's clarified DBIQNP objective and source/backend boundary without activating new implementation.`
  Acceptance: `Record all clarifications in the proposed task/index, roadmap, README and book, including full API/MCP coverage and ChatGPT/Claude plugin/UI clients. Keep the active implementation pointer unchanged. Verify authenticated decision/navigation, book and mandatory commit doctrines; make no present completeness, speed or backend-signoff claim.`
  Verification: `The director first asks about layer suitability, then explicitly requires complete chip authoring from both IAL1 and IAL2 and clarifies that the end product is source code with the backend excluded. The proposed task and canonical roadmap/book preserve that exact final scope, including complete actionable API/MCP and ChatGPT/Claude plugin/UI access. A separate unpublished ADR would push the rationale collection past rollover; the full draft, patch and first gate retain in full-chip-source-north-star-first-gate-20261025.json.gz. Route the product requirement to its canonical homes without deleting any prior decision, changing a ceiling or starting an unrelated rollover. README is compacted within its existing allowance. Earlier backend-orchestration advice is not adopted as a requirement. Required SPECFORGE delivery and domain-width .2.3.2.5 remain the active implementation frontier. Documentation and mandatory staged gates qualify this record; no feature implementation or full-chip capability audit occurs.`
  Commit: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.1: record full-chip source authoring north star`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.2`
  Status: `deferred`
  Goal: `Define the complete source-authoring contract and evidence-backed capability/gap matrix.`
  Acceptance: `Activate only after required SPECFORGE delivery/publication/feedback or a later explicit director selection. Define representative chip classes, source deliverables, semantic completeness, human/AI authoring needs and initial-verification requirements. Query canonical facts and public interfaces, distinguish implemented/focused/fully-qualified/proposed features, assign every gap a bounded task and dependency. Decide which source-level constraints/collateral are deliverables; backend algorithms remain excluded. No roadmap-sized unowned implementation leaf.`
  Verification: `Deferred; the accepted objective is not a current feature census.`
  Commit: `pending`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.3`
  Status: `deferred`
  Goal: `Develop complete IAL1 hardware authoring semantics from the selected gap matrix.`
  Acceptance: `After .2 selection, split required control, datapath/arithmetic, pipeline/hazard, memory/register-file, hierarchy, parameter/type, clock/reset and interface capabilities into independently executable feature trees. Each feature needs an elegant, concise and expressive Lispish authoring form, precise timing/resource/configuration semantics, diagnostics, backend-neutral contracts and API/MCP applicability. Qualify realistic readable source, independent behavior and semantic source/API round trips before closure; no automatic admission of an unspecified construct.`
  Verification: `Deferred; no IAL1 completeness or current absence claim.`
  Commit: `pending`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.4`
  Status: `deferred`
  Goal: `Develop complete IAL2 architectural/system authoring with explicit IAL1 refinement.`
  Acceptance: `After .2 and required lower-layer dependencies, select architectural, component, memory-map, interconnect, protocol and composition requirements with elegant, concise and expressive Lispish forms. Every detailed behavior remains reachable through explicit refinement/composition into IAL1; no bypass, silent loss or API-only design feature. Qualify realistic complete source from either layer, semantic API/MCP round trips and independent behavior. Distinct layer vocabulary remains valid when meaning is clear and composition is efficient.`
  Verification: `Deferred; existing bounded profiles remain the shipped contract.`
  Commit: `pending`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.5`
  Status: `deferred`
  Goal: `Provide the VIAL initial functional-verification capabilities required by the selected complete designs.`
  Acceptance: `After .2, coordinate existing HIAL/VIAL and simulator API owners. Select executable models, stimuli, assertions, scoreboards, coverage, temporal checks and actionable traces by actual design needs; preserve authored semantics separately from observed execution. Split gaps, qualify independent expected behavior and known-bad controls, and keep unsupported runtime/profile boundaries explicit.`
  Verification: `Deferred; this does not promote current generated verification artifacts to runtime proof.`
  Commit: `pending`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.6`
  Status: `deferred`
  Goal: `Qualify complete production-quality source delivery to external backend consumers.`
  Acceptance: `After the selected source features, verify complete emitted hierarchy, interfaces, parameter legality, memory/clock/reset contracts and all selected output profiles through published consumer APIs. Check reproducibility, elaboration, lint and independent functional semantics, retaining limitations. Define source acceptance separately from synthesis/physical/foundry results; implement no backend flow under this horizon.`
  Verification: `Deferred; implementation-ready is an earned source-delivery property.`
  Commit: `pending`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.7`
  Status: `deferred`
  Goal: `Qualify realistic complete CPU, DSP, MCU, ASIC and SoC source-authoring pilots.`
  Acceptance: `After selected prerequisites, choose explicit architecture, ISA/numeric semantics, scope, configurations and independent reference models before each pilot. Split pilots and reuse qualified IP through public contracts. Exercise both IAL authoring entry points, realistic composition and VIAL initial verification; account for every source file and unsupported behavior. A simple controller or toy core cannot establish advanced-design completeness.`
  Verification: `Deferred; no pilot design has been selected or executed.`
  Commit: `pending`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.8`
  Status: `deferred`
  Goal: `Establish authoring quality, efficiency, scale and design-class-specific maturity evidence.`
  Acceptance: `After selected pilots, define comparable workflows and ergonomic, compile-resource, correctness, maintainability and source-quality criteria. Apply CLAIM_VERIFICATION.md to measurements, with independent falsification and durable producers. Coordinate the existing end-to-end scalability tree instead of duplicating it. Full verification follows completed feature sets. Report precise limits; no universal state-of-the-art, speed or silicon-signoff guarantee.`
  Verification: `Deferred; no authoring-performance comparison or whole-chip maturity claim.`
  Commit: `pending`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.9`
  Status: `deferred`
  Goal: `Expose the entire FSMGen feature set as actionable API/MCP capabilities consumed by ChatGPT/Claude plugins and UI.`
  Acceptance: `After explicit activation and applicable capability contracts, coordinate FSMGEN-CONVERSATIONAL-INTERFACE and SEMANTIC-INTROSPECTION-MCP-WRITE-HORIZON instead of duplicating them. Every delivered feature needs authoritative API behavior, MCP access, complete input/result/error/effect contracts and consumer applicability evidence. ChatGPT/Claude plugins and UI invoke those same capabilities. Qualify each host's tool access and actual UI separately; preserve source identity, permissions, artifact/effect boundaries and reproducibility. Current read-only MCP coverage is not full actionable parity. Split implementation by feature and host; no connection or effectful tool is activated by this discussion.`
  Verification: `Deferred; the existing client owner and effectful MCP horizon retain implementation ownership. No host parity or complete current exposure is claimed.`
  Commit: `pending`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.10`
  Status: `done`
  Goal: `Record complete, elegant and expressive Lispish/S-expression authoring as a core requirement for every IAL1/IAL2 design feature.`
  Acceptance: `Preserve the director's latest DBIQNP requirement in the goal, feature acceptance/decomposition, roadmap and book. Require concise, composable and semantically precise source forms with no useless verbosity, plus semantic API/MCP source parity. Keep operational tools distinct from design-language constructs. Record the requirement without implementing new syntax or changing required delivery priority. Validate docs and mandatory staged doctrines, then commit cleanly.`
  Verification: `The director's requirement is preserved in the goal, acceptance criteria, IAL1/IAL2 decomposition, roadmap, book and discussion record. Both layers require complete Lispish design surfaces, concise/composable real examples and precise semantics, with equivalent API/MCP capabilities and semantic source round trips. Operational tools are not invented as HDL constructs. No syntax is admitted, host capability promoted or implementation lane activated. The implementation frontier remains ISF-REDUCTION-DELIVERY.2.3.3. Documentation and mandatory staged gates qualify this planning slice.`
  Commit: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.10: require expressive Lispish design surfaces`

- ID: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.11`
  Status: `done`
  Goal: `Reaffirm complete adjacent-layer lowering for every HIAL and VIAL construct through both HDL targets.`
  Acceptance: `Record the director's DBIQNP clarification in this proposed horizon, roadmap and book. Require explicit IAL2-to-IAL1-to-IAL0-to-SystemVerilog/VHDL paths, semantic preservation and source provenance for hardware and verification constructs. Distinguish synthesizable hardware from verification behavior, expansion from one-to-one syntax translation, and the goal from current backend/profile coverage. Keep active implementation ownership unchanged; validate docs and commit without starting a compiler redesign.`
  Verification: `The director explicitly requires every construct at each IAL to lower cleanly to the next, through HDL, for both HIAL and VIAL. Canonical scope now records that requirement and its semantic/evidence criteria. The same abstraction ladder applies to both domains, without requiring verification constructs to synthesize or claim identical native HDL syntax. Existing target gaps remain owned work; no unsupported profile is promoted and no feature is implemented. MEMORY.md remains at ISF-REDUCTION-DELIVERY.2.3.3.3.2. Book/task/mandatory doctrines qualify this discussion record.`
  Commit: `FULL-CHIP-SOURCE-AUTHORING-HORIZON.11: require complete HIAL and VIAL lowering paths`

## Acceptance Checklist (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S 'IAL2 never bypasses IAL1' -- README.md identifies 64b2924ba as the existing layered contract. The director's final DBIQNP clarification expands the intended authoring reach of both layers while explicitly ending the deliverable at source code. Current qualified subsets remain distinct from that objective.
- [x] **ADDRESSED (verified)** — The proposed task, roadmap, README and book preserve complete digital-chip source authoring and initial VIAL verification. The implementation Memory pointer is unchanged and the proposed tree is absent from active execution. Authenticated decision/navigation and task integrity checks pass.
- [x] **NO REGRESSION** — knowledge-map: OK remains mandatory through scripts/check_doctrines.sh and normal hooks; authenticated decisions, task integrity, current claim census and dispositions pass. The updated manual builds. No source grammar, lowering, capability/schema or runtime behavior changes.

## Director DBIQNP scope — 2026-10-25

### Discussion and final scope

The director's 2026-10-25 DBIQNP discussion establishes the ultimate objective:
FSMGen should elegantly, efficiently and convincingly author real complete
digital CPU, DSP, MCU, ASIC and SoC designs. The director explicitly requires
both IAL1 and IAL2 to have the necessary features, with VIAL handling initial
verification. The final clarification sets the end product to source code and
excludes the backend. This final boundary supersedes the discussion's earlier
suggestion that backend/signoff orchestration might belong to the objective.

### Accepted objective

Treat both IAL1 and IAL2 as intended entry points for complete digital-chip
source authoring. IAL1 must provide the required hardware semantics and detailed
implementation control. IAL2 must express complete architectural/system intent
with explicit composition/refinement into IAL1. Keep the established ordered,
reviewable IAL2 -> IAL1 -> IAL0 -> HDL contract. Distinct vocabulary is compatible
with complete capability at both entry points; no hidden bypass or semantic loss.

The deliverable is a complete, self-consistent implementation-ready source tree.
HDL generation remains part of FSMGen compilation; the excluded backend is
downstream chip implementation.
Control, datapaths, pipelines, memories, hierarchy, interfaces, configuration and
clock/reset behavior must be expressible as required by selected real designs.
Handwritten external RTL may remain a useful integration option, but permanent
IAL capability gaps cannot be treated as satisfying the full-chip authoring goal.

VIAL supplies initial functional verification alongside authoring. Its required
models, scenarios, checks, coverage and diagnostics must be selected and qualified
against real design needs. Generated verification text alone does not prove
execution or correctness. Synthesis, physical implementation, fabrication and
backend signoff engines remain downstream and outside this authoring objective.

### Delivery and ordering

This is an accepted direction, not a present completeness, performance or
production-qualification claim. Define source expressiveness, compiler correctness,
ergonomics, source-delivery quality and verification maturity separately. Qualify
representative designs and configurations with independent behavioral oracles.
Any state-of-the-art claim needs an explicit design class and earned criteria.
Backend qualification remains a separate responsibility of downstream tools.

This proposed horizon owns detailed decomposition and future gap assessment.
No full-chip audit or implementation is activated by this discussion. Decision0121
and the active required SPECFORGE frontier remain unchanged; activation follows
required delivery/publication/feedback or a later explicit director selection.


The director also reconfirms that the **entire FSMGen feature set must be
accessible and actionable via API through MCP**, with **ChatGPT/Claude plugins
and UI** as ways to access those capabilities. Feature completeness includes
API/MCP coverage and client operability. The compiler/API owns semantics;
conversational and graphical clients consume the same authoritative operations.
This reinforces the existing client and MCP horizon owners, without promoting
the currently bounded read-only adapter to full actionable coverage.

Methodology references distinguish source/design verification from physical flow:
[OpenTitan development stages](https://opentitan.org/book/doc/project_governance/development_stages.html)
and [OpenROAD flow](https://openroad-flow-scripts.readthedocs.io/en/latest/mainREADME.html).
These inform scope; no FSMGen integration or backend capability is claimed.

### Complete language surface and language quality

The director further requires **every feature of both IAL1 and IAL2** to be
expressed beautifully, elegantly, expressively and efficiently in the existing
Lispish/S-expression language, without useless verbosity. This is a core product
requirement. Language design must make common intent concise, composition natural
and detailed control readable. Each feature needs representative realistic source
examples and precise semantics; parser acceptance alone cannot establish quality.
API/MCP access must preserve that same language meaning and support materializing
readable source. This clarifies the proposed horizon without activating syntax
work or changing the required delivery frontier.

## Language requirement acceptance (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S 'complete digital-chip source-authoring' -- ROADMAP_V2.md identifies ee7cb1660, which records the full-chip goal but lacks the later universal Lispish-language quality criterion. The director explicitly adds that requirement during DBIQNP while required width implementation continues.
- [x] **ADDRESSED (verified)** — The proposed horizon, IAL1/IAL2 future decomposition, roadmap and book now require complete, concise and expressive Lispish surfaces, semantically precise composition and equivalent actionable API/MCP coverage. This records scope without implementing a language feature or changing the active implementation pointer.
- [x] **NO REGRESSION** — Source grammar, lowering and public capability behavior are unchanged. The book build, task integrity and scripts/check_doctrines.sh with knowledge-map: OK and normal hooks qualify the documentation slice; no full-chip implementation or runtime completeness is claimed.

### Complete lowering for hardware and verification

The director reaffirms that every IAL2 feature/construct lowers cleanly to IAL1,
every IAL1 feature/construct to IAL0, and every IAL0 feature/construct to HDL
(SystemVerilog and VHDL), for both HIAL and VIAL. This is the central completeness
contract, not just a route for selected convenient constructs. Source authors
may start at any layer; compilation from an upper layer retains every adjacent
lowering obligation.

Clean lowering means explicit semantics, legal lower-layer constructs, preserved
source provenance and independent preservation checks at each edge. Expansion
into several constructs is valid. Preserve the specified timing, sampling,
concurrency, widths/types, reset/clock and verification-observation relationships;
do not silently approximate unsupported semantics. HIAL hardware and VIAL checks,
monitors, stimulus and models share the abstraction ladder while keeping their
distinct meanings. Verification source need not be synthesizable. Target-native
syntax may differ when it implements the same defined contract.

Each future feature's acceptance must cover its full required lowering path,
diagnostics and inspectable source/API/MCP products. Missing target realizations
remain owned gaps and fail closed until implemented and qualified; emitting text
alone cannot establish preservation. No current target-parity, formal equivalence
proof or complete runtime coverage is inferred from this discussion. Existing
VIAL substrate decisions and required delivery priority remain unchanged.

## Layered lowering acceptance (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — git log -S 'faithful IAL2 -> IAL1 -> IAL0 lowering' -- docs/tasks/FULL-CHIP-SOURCE-AUTHORING-HORIZON.md identifies the earlier source-authoring objective. The director now explicitly extends the universal adjacent-layer obligation through SystemVerilog/VHDL to both HIAL and VIAL.
- [x] **ADDRESSED (verified)** — Proposed horizon, roadmap and book record the full ladder, semantic/source preservation, hardware/verification distinction and expansion semantics. The active implementation Memory pointer remains unchanged. No compiler redesign or source construct is activated by DBIQNP.
- [x] **NO REGRESSION** — Source grammar, compiler behavior and public capability contracts are unchanged. Book build, task integrity and scripts/check_doctrines.sh with knowledge-map: OK plus normal hooks gate this documentation-only clarification. Current backend/profile limits remain explicit.

## Blockers

This is proposed backlog. Decision0121 keeps required SPECFORGE delivery and
publication ahead of activation. The current implementation pointer remains in
`MEMORY.md`; this horizon owns future decomposition, not today's execution.
