# ISF-REDUCTION-DELIVERY: SPECFORGE scalar and grouped reductions

## Metadata

- Tree ID: `ISF-REDUCTION-DELIVERY`
- Status: `active`
- Roadmap lane: `R14 / ISF; R13 public semantic reports`
- Created: `2026-10-21`
- Last updated: `2026-10-21`
- Owner: repo-local workflow

## Goal

Implement and qualify the required R1–R3 of SPECFORGE FSMGEN-REQUESTS.12.
SEMANTIC-INTROSPECTION-MCP-FRONTIER `.92` retains request coordination and
publication ownership. Decision `0117` selects the contract. This bounded
implementation tree avoids growing the near-rollover coordination task file.

## Non-Goals

- This tree does not close durations, named timers or record-output delivery.
- Optional inversion has separate ownership and cannot delay required delivery.
- No sibling repository, submodule pin or caller integration is changed here.

## Acceptance Criteria

- Every required request clause has source, IAL0, HDL and public-report evidence.
- Preserve accepted binary expressions and existing logical negation.
- Keep authored dependencies distinct from resolved defaults; prove actual HDL
  width and group behavior under parameter overrides and short final groups.
- Each completed source slice has corpus and native/API/MCP coverage, focused
  checks, independent semantics, synchronized book and feedback, and its own commit.
- Full CI and exact-SHA hosted results qualify publication under SEM `.69`.
- Task integrity and all required doctrines pass without relaxed safety limits.

## Task Tree

- ID: `ISF-REDUCTION-DELIVERY`
  Status: `active`
  Goal: `Deliver required unary and parameter-correct grouped reductions.`
  Children: `ISF-REDUCTION-DELIVERY.1, ISF-REDUCTION-DELIVERY.2, ISF-REDUCTION-DELIVERY.3, ISF-REDUCTION-DELIVERY.4, ISF-REDUCTION-DELIVERY.5, ISF-REDUCTION-DELIVERY.6, ISF-REDUCTION-DELIVERY.7`

- ID: `ISF-REDUCTION-DELIVERY.1`
  Status: `active`
  Goal: `Implement and qualify unary XOR, AND and OR reductions end to end.`
  Acceptance: `Before source edits, inspect the shared recursive expression parser, declared signal/type resolution, AST and every relevant width consumer, ISF scalar validation, IAL0 replay, HDL emitter profiles and normalized reports. Add arity-dependent unary semantics without changing multi-operand behavior. Reject undeclared, aggregate, non-vector or malformed operands contextually. Prove result width in direct and nested expressions, scalar/slice/index truth tables, retained caller parity inputs and unchanged binary/unrolled controls. Qualify supported HDL profiles with actual compilation/runtime through published tools; retain first failures under the HIAL failure-only prerequisite. Add a runnable supported corpus case, named detached report inventory and complete native/API/real MCP/capability parity. Update ISF reference/book/feedback and focused checks; split any unsafe expansion before implementation. Commit before generic-width work.`
  Verification: `pending; historical unary refusal is retained by SEM .91`
  Commit: `children below`
  Children: `ISF-REDUCTION-DELIVERY.1.1, ISF-REDUCTION-DELIVERY.1.2, ISF-REDUCTION-DELIVERY.1.3, ISF-REDUCTION-DELIVERY.1.4`

- ID: `ISF-REDUCTION-DELIVERY.1.1`
  Status: `done`
  Goal: `Prepare exact unary reduction widths and distinct intermediate identities without new source admission.`
  Acceptance: `Inspect shared expression width propagation, Core/runtime/substituted AST naming, direct intermediate widths and enable-graph width classification. Qualify unary ^/&/| as one-bit results independent of operand width, nested concatenation/comparison use and distinct readable intermediate identities; assignment-context width propagation must not resize a reduction operand. Preserve binary vector, logical negation, inversion and ordinary operand-propagation behavior. Add a meaningful RED-to-GREEN regression across the real independent consumers with adversarial vector-width and collision controls. Shared source parsing must still refuse unary reductions in this preparatory commit. Run focused expression/AST/backend-generation checks without external HDL execution, update decision/book/feedback and preserve actual test evidence. Runtime, source/corpus/public inventories remain explicitly pending under successors; commit before admission changes.`
  Verification: `Actual original RED and corrected native-predecessor RED fail four top-level subtests; the corrected current regression passes. The initial post-repair failure identifies an oracle error: runtime literals have their own stored definition, so the test now compares only all distinct reduction definitions and uses legal signal names. All current exact/Core/runtime/substituted/intermediate/enable widths and nested concatenations/comparisons are scalar where required; destination propagation cannot resize operands. Binary vectors, logical negation, inversion and ordinary propagation retain controls. Guarded focused All tests successful Files=7 Tests=21; fresh native --strict --check --json accepts the exact caller baseline and retains both unary arity refusals. Complete normalized logs, original test, corrected native capsule recipe/identities, current source hashes and typed outcomes are retained in docs/audits/unary-reduction-width-foundation-20261021.json. Re-derivation is current production-consumer regression and native supplied checks; falsification is the same corrected assertions against exact predecessor modules plus vector/identity/propagation controls; durability is tracked source/test/audit and this commit. No new source admission, public inventory, external HDL execution or R1/R2/R3 delivery claim. Book/task checks separately pass All tests successful Files=3 Tests=356, mdBook build and complete source/index contracts pass; native decision/Knowledge Map/task/claim checks pass. The final expanded comparison regression also fails against native predecessor modules and passes the complete current focused suite. Staged/normal gates precede commit.`
  Commit: `ISF-REDUCTION-DELIVERY.1.1: preserve scalar reduction widths and identities`

  Acceptance Checklist (enforced):
  - [x] **ROOT CAUSE (WHY + WHERE)** — Perl diagnostics from T2074 RED locate operand-width leakage in ExpressionBuilder/ExpressionNamer/direct intermediate inference, absent enable-graph reduction width, generated-name collisions and destination propagation. Fresh --strict --check --json still shows the independent arity refusal.
  - [x] **ADDRESSED (verified)** — Corrected assertions fail against exact native predecessor modules and pass against the repair; actual nested widths, complete distinct definition identities and operand-preservation controls qualify. Source grammar and public admission are unchanged. Complete logs and source identities remain in the dated width-foundation audit.
  - [x] **NO REGRESSION** — Guarded expression/naming/AST/intermediate/VHDL-text checks report All tests successful, Files=7, Tests=21; fresh supplied native baseline passes and unary forms retain their refusal. Book/task All tests successful Files=3 Tests=356, mdBook build, complete source/index, native decision/task and knowledge-map: OK pass. scripts/check_doctrines.sh plus normal hooks gate the commit. No external HDL runtime is inferred.

- ID: `ISF-REDUCTION-DELIVERY.1.2`
  Status: `pending`
  Goal: `Admit unary reductions through declared scalar validation, IAL0 and detached public reports.`
  Acceptance: `After .1, qualify source/arity/type/path/scope validation, direct/nested reduction assignment widths, source/carrier parity and default retained caller parity. Add the detached reductions inventory through native check/semantic/schedule, API and actual newline MCP, with capability and source/version/query applicability, supported corpus admission and independent report/semantic controls. Preserve binary and logical behavior. Generate HDL for supported profiles without borrowing runtime proof. Commit any growing preparatory slice with its exact missing qualification boundary; do not close the required unary feature before .4.`
  Verification: `pending width foundation`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.1.3`
  Status: `pending`
  Goal: `Commit the exact unary HDL witness and qualify its failure-only observer admission.`
  Acceptance: `Coordinate the existing HIAL .19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.10.11.7 for this director-prioritized genuinely needed witness. Before supervised HDL execution, commit exact tests/source/bench, fixed targets/profile/count and complete independent truth-table oracle. Separately qualify any changed observer identity/coverage using immutable native/failure-only helpers, original arguments/limits/results/errno and independent cleanup. No spent original/reused admission or recurrence campaign, host-policy change or authentication request.`
  Verification: `pending authored source and fixed witness`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.1.4`
  Status: `pending`
  Goal: `Qualify actual unary HDL behavior, profile boundaries and complete required R1 delivery.`
  Acceptance: `After .2/.3, consume one fresh admitted observation for the genuine unary witness. Independently prove XOR/AND/OR, scalar/bit/slice/odd parity and nested widths against public HDL pins, plus an actually wrong reduction control and unchanged binary/unrolled controls. Qualify each supported profile or precise refusal with native/API/MCP/carrier/corpus/book parity. Preserve complete first failures and settle all owned jobs; captured native rejection stops further runtime until diagnosed. Commit exact scope evidence and close SEM .92.2 only on complete R1 delivery; required R2/R3 and publication remain open.`
  Verification: `pending exact witness and observer admission`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.2`
  Status: `pending`
  Goal: `Preserve authored scalar width dependencies and resolved defaults.`
  Acceptance: `Coordinate SEM .33.3.1 and .32.3; audit public IAL0 parameterized sizing and reuse its evaluator. Retain dependency metadata from actor/transaction/library declarations through parser, LoweringIR, IAL0 and sanitized reports. Never infer a dependency from matching numbers. Cover constants versus parameters, aliases, reset/default sizing and unrelated equal-width controls. Keep incomplete HDL override support explicitly bounded in book/capabilities; qualify detached report and carrier parity, then commit this foundation.`
  Verification: `pending after unary delivery`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.3`
  Status: `pending`
  Goal: `Emit consistent parameter-dependent widths through supported HDL profiles.`
  Acceptance: `After .2, coordinate SEM .33.3.2. Carry dependencies through canonical IAL0 to ports, storage, intermediate expressions, constants and resets; no HDL post-processing. Independently compile a real parameter override and compare its declarations and runtime against separately generated matching defaults. Unrelated equal-width declarations remain independent. Refuse profiles that cannot preserve these relationships. Synchronize corpus/public native/API/MCP/book/feedback contracts and commit.`
  Verification: `pending width carrier foundation`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.4`
  Status: `pending`
  Goal: `Qualify specialization, parameter legality and external relationship guards.`
  Acceptance: `After .2/.3, coordinate SEM .33.3.3/.33.3.4 and existing derived-width legality. Recompute independent library/activation/generated-top environments before bindings, refuse stale/default-width mismatches and invalid widths, and preserve instance identity. Qualify positive integer legality plus compiled external HDL checks for dependent group/output-width relationships. Reports describe the chosen environment and retain authored dependencies without suggesting a default is generic proof. Keep all generic-width obligations tracked through closure and commit the bounded implementation.`
  Verification: `pending generic emission`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.5`
  Status: `pending`
  Goal: `Implement reduce-groups with parameter-correct group order and short tails.`
  Acceptance: `After .2-.4, implement decision 0117 through shared expression/type/width, ISF validation, IAL0 AST, HDL and detached reports. Literal operators ^/&/| and positive decimal N only; use elaborated operand width, least-significant group first, exact result width and an unpadded short final group. Strict target mismatch names target width and group count. Independently qualify defaults, overrides, N greater than W, single-bit and short-tail vectors, slices, nested expressions and invalid group/operator/operand controls. Add supported corpus plus real native/API/MCP reports, actual HDL behavior and synchronized references/book/feedback; no default-width unroll or source-only delivery claim. Split a growing slice before implementation.`
  Verification: `pending generic prerequisites`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.6`
  Status: `pending`
  Goal: `Qualify and publish complete required SPECFORGE reduction delivery.`
  Acceptance: `Coordinate SEM .92.4 and .69 after required source slices. Compare exact retained unrolled baseline and accepted scalar parity, then grouped parity at widths 16/32 and a short-tail setting under real parameter overrides, with independent expected bits and width/legality negatives. Verify source/carrier/report/public discovery and supported profiles, required full CI and exact-SHA hosted workflows. Update canonical feedback with revision, selected syntax, limits and caller-owned pin/bundle/integration steps. No foreign write or historical-gate waiver; required R1-R3 close only on complete evidence.`
  Verification: `pending implementation and publication qualification`
  Commit: `pending`

- ID: `ISF-REDUCTION-DELIVERY.7`
  Status: `pending`
  Goal: `Implement or explicitly defer optional width-preserving vector inversion.`
  Acceptance: `Coordinate SEM .92.5 after unary semantics. Selected (~ X) preserves operand width and complements each bit, including grouped results; logical ! remains single-bit. Implement only with independent truth tables, nested widths, native/API/MCP/carrier/profile/corpus/book qualification, or document a bounded deferral. Optional R4 must not block required R1-R3 publication.`
  Verification: `optional; required grouped XOR remains useful without inversion`
  Commit: `pending`

## Blockers

Publication retains the HIAL/startup, full-CI and query-incident obligations
under SEM `.69` and `.93`. No external access or product decision is pending.
