# ISF-CONFLICTS: Rule And Transaction Output Conflict Semantics

## Metadata

- Tree ID: `ISF-CONFLICTS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Make ISF same-cycle conflict behavior precise, implementable, documented, and
regression-backed when multiple rules, transactions, drive calls, completion
pulses, or generated helper paths can target the same downstream signal or
transaction start input.

## Non-Goals

- Do not redesign the `.fsm` assignment model.
- Do not implement broad resource scheduling unless it is needed to close a
  concrete conflict semantic.
- Do not stabilize new public API surfaces beyond what the shipped conflict
  behavior requires.
- Do not hide incompatible same-cycle drives by choosing an arbitrary winner.

## Acceptance Criteria

- Conflict domains are explicitly defined for ISF-authored outputs, generated
  storage, transaction starts, delayed pulses, and named-drive expansions.
- Compatible fan-in cases are either merged deterministically or documented as
  intentionally rejected.
- Incompatible same-cycle drive cases fail with targeted diagnostics before
  misleading scheduled `.fsm` or HDL is treated as valid.
- Priority/resource metadata interaction is either implemented for the covered
  domains or explicitly deferred with the consequence documented.
- The scheduler/emitter behavior, ISF spec, public interface contract, mdBook,
  roadmap/live docs, and focused regressions agree.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-CONFLICTS`
  Status: `active`
  Goal: `Define and ship ISF same-cycle output conflict semantics.`
  Children: `ISF-CONFLICTS.1`, `ISF-CONFLICTS.2`, `ISF-CONFLICTS.3`,
  `ISF-CONFLICTS.4`, `ISF-CONFLICTS.5`, `ISF-CONFLICTS.6`,
  `ISF-CONFLICTS.7`

- ID: `ISF-CONFLICTS.1`
  Status: `done`
  Goal: `Inventory current conflict behavior and define conflict domains.`
  Acceptance: `Existing scheduler/emitter behavior is inspected, current
  accepted/rejected multi-drive shapes are listed, and conflict domains are
  named in this task file before implementation work starts.`
  Verification: `source/test inspection complete; git diff --check passed`
  Commit: `ISF-CONFLICTS.1: inventory current conflict domains`

- ID: `ISF-CONFLICTS.2`
  Status: `done`
  Goal: `Specify deterministic merge policy for compatible fan-in.`
  Acceptance: `The task file and live docs state which same-target cases merge
  by OR/fan-in, which share generated helper signals, and which preserve
  existing rule-trigger fan-in behavior.`
  Verification: `policy documented; git diff --check passed`
  Commit: `ISF-CONFLICTS.2: specify compatible fan-in policy`

- ID: `ISF-CONFLICTS.3`
  Status: `done`
  Goal: `Specify fail-closed and priority policy for incompatible drives.`
  Acceptance: `The task file records the policy for incompatible writes,
  missing priority, declared priority, and deferred resource arbitration.`
  Verification: `policy documented; git diff --check passed`
  Commit: `ISF-CONFLICTS.3: specify conflict priority policy`

- ID: `ISF-CONFLICTS.4`
  Status: `done`
  Goal: `Implement scheduler/emitter conflict tracking.`
  Children: `ISF-CONFLICTS.4.1`, `ISF-CONFLICTS.4.2`,
  `ISF-CONFLICTS.4.3`, `ISF-CONFLICTS.4.4`,
  `ISF-CONFLICTS.4.5`
  Acceptance: `The implementation can distinguish compatible fan-in from
  incompatible same-cycle drive conflicts without relying on text-order
  accidents in emitted `.fsm`.`
  Verification: `all executable leaves complete through runtime selector instrumentation`
  Commit: `completed by ISF-CONFLICTS.4.5`

- ID: `ISF-CONFLICTS.4.1`
  Status: `done`
  Goal: `Add scheduler-side assignment provenance inventory.`
  Acceptance: `ISF lowering has a bounded internal representation for emitted
  assignments that records source owner, source kind, target, operator, RHS,
  domain hint, and activation context before scheduled `.fsm` text is
  generated. Existing scheduled `.fsm` output remains behavior-compatible.`
  Verification: `prove -l t/1207-isf-assignment-provenance-inventory.t; bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-CONFLICTS.4.1: add ISF assignment provenance`

- ID: `ISF-CONFLICTS.4.2`
  Status: `done`
  Goal: `Classify compatible fan-in groups from assignment provenance.`
  Acceptance: `The scheduler can identify same target/operator/value groups,
  one-bit request/event fan-in, one-cycle pulse fan-in, and existing
  rule-trigger fan-in without treating unrelated data/helper assignments as
  compatible.`
  Verification: `prove -l t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t; bin/ci-regression isf --no-book; git diff --check`
  Commit: `ISF-CONFLICTS.4.2: classify ISF fan-in groups`

- ID: `ISF-CONFLICTS.4.3`
  Status: `done`
  Goal: `Add best-effort compile-time conflict detection and flags for cases where proof is not doable.`
  Acceptance: `The scheduler can reject statically provable overlapping
  same-target data conflicts, preserve ordinary mutually-exclusive state
  assignment behavior, and flag rule/drive cases where compile-time proof is
  not doable instead of silently claiming they are safe.`
  Verification: `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1209-isf-static-conflict-detection.t; prove -l t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t t/1209-isf-static-conflict-detection.t; bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-CONFLICTS.4.3: add ISF static conflict checks`

- ID: `ISF-CONFLICTS.4.4`
  Status: `done`
  Goal: `Apply target-local priority resolution for implemented conflict sets.`
  Acceptance: `Declared rule/actor priority can select one unique winner for a
  supported same-domain data conflict, while cycles, incomparable winners, and
  mixed timing operators fail closed.`
  Verification: `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1210-isf-priority-conflict-resolution.t; prove -l t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t; bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-CONFLICTS.4.4: apply ISF rule priority resolution`

- ID: `ISF-CONFLICTS.4.5`
  Status: `done`
  Goal: `Add verification-only runtime selector conflict instrumentation.`
  Acceptance: `The implementation can emit verification-only logic that checks
  mux selector conflicts at runtime: multi-hit source selectors for the same
  LHS/VAL selector when requested, and two or more different VAL selectors
  active for the same LHS mux in the same cycle.`
  Verification: `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t t/1211-isf-runtime-selector-conflict-instrumentation.t t/154-standalone-dt-assertion-runtime-hdl.t t/156-forward-lowered-rtl-ir-surface.t t/170-forward-lowered-rtl-ir-output-drive-helpers.t t/190-pipeline-direct-generation-orchestrator.t t/194-generated-module-emitter.t t/305-hdl-generator-result-contract.t t/340-normalized-semantic-lowered-rtl-ir-contract.t t/343-hdl-generator-module-info-contract.t t/497-lowered-rtl-ir-accessor-defensive-copy-boundary-audit.t t/590-direct-generation-module-info-lowered-ir-alias-boundary-audit.t; bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-CONFLICTS.4.5: add runtime selector assertions`

- ID: `ISF-CONFLICTS.5`
  Status: `done`
  Goal: `Add diagnostics and schedule-report projection.`
  Children: `ISF-CONFLICTS.5.1`, `ISF-CONFLICTS.5.2`,
  `ISF-CONFLICTS.5.3`, `ISF-CONFLICTS.5.4`
  Acceptance: `Rejected conflict cases report targeted diagnostics, and
  accepted conflict/fan-in cases are visible in bounded schedule-report
  metadata where useful for downstream consumers.`
  Verification: `all executable leaves complete through rejected-conflict diagnostic coverage`
  Commit: `completed by ISF-CONFLICTS.5.4`

- ID: `ISF-CONFLICTS.5.1`
  Status: `done`
  Goal: `Define the bounded conflict/fan-in schedule-report projection schema.`
  Acceptance: `The planned nonfatal compile-issue entries and compatible
  fan-in metadata entries are named, scoped, and documented before emitter
  changes widen the public schedule-report shape.`
  Verification: `git diff --check; mdbook build docs/book`
  Commit: `ISF-CONFLICTS.5.1: define report projection schema`

- ID: `ISF-CONFLICTS.5.2`
  Status: `done`
  Goal: `Project nonfatal conflict issues into schedule-report compile_issues.`
  Acceptance: `Warning-level conflict issues such as rule/drive overlap are
  emitted in schedule JSON with bounded code, severity, proof status, target,
  and source-owner summaries without changing fail-closed diagnostics.`
  Verification: `prove -l t/1212-isf-schedule-report-compile-issues-projection.t; prove -l t/1130-isf-public-compile-issues-success-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t; prove -l t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1172-isf-rule-trigger-fanin-schedule-report.t t/1209-isf-static-conflict-detection.t; bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-CONFLICTS.5.2: project compile issues`

- ID: `ISF-CONFLICTS.5.3`
  Status: `done`
  Goal: `Project accepted compatible fan-in groups into schedule-report metadata.`
  Acceptance: `Accepted same-value, request, pulse, and rule-trigger fan-in
  groups have bounded schedule-report summaries that preserve target, domain,
  operator/value, and source-owner context useful to downstream consumers.`
  Verification: `prove -l t/1213-isf-schedule-report-compatible-fanin-projection.t; prove -l t/1096-isf-schedule-json-report.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1131-isf-public-top-level-discovery-audit.t; bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-CONFLICTS.5.3: project fan-in groups`

- ID: `ISF-CONFLICTS.5.4`
  Status: `done`
  Goal: `Add rejected-conflict diagnostic coverage and close projection docs.`
  Acceptance: `CLI/in-process rejected conflict diagnostics name the stable
  code, target, and conflicting owners, and the ISF spec, public contract, and
  mdBook agree with the shipped projection behavior.`
  Verification: `prove -l t/1214-isf-rejected-conflict-diagnostics.t; prove -l t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t t/1144-isf-public-tested-by-metadata-audit.t; bin/ci-regression isf --no-book; mdbook build docs/book; git diff --check`
  Commit: `ISF-CONFLICTS.5.4: cover rejected diagnostics`

- ID: `ISF-CONFLICTS.6`
  Status: `pending`
  Goal: `Add focused regressions and at least one realistic fixture.`
  Acceptance: `Tests cover accepted fan-in, rejected incompatible drives, and
  a realistic ISF fixture that would have been ambiguous without the new
  conflict model.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONFLICTS.7`
  Status: `pending`
  Goal: `Synchronize user-facing documentation and close the tree.`
  Acceptance: `The ISF spec, public interface contract, mdBook, roadmap,
  MEMORY, CHANGES, DEVELOPMENT_NOTES, and LIVE_ACHIEVEMENT_STATUS describe the
  shipped conflict behavior and remaining limitations.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-CONFLICTS.6` | `pending` | Diagnostics/report projection is complete; the next leaf adds broader focused regressions and a realistic fixture. |

## Current Behavior Inventory

`ISF-CONFLICTS.1` inspected the current scheduler, `.fsm` emitter, schedule
JSON emitter, parser boundaries, and focused rule/drive/complete tests before
any new conflict implementation. The implementation baseline is:

- `perl/FSM/Scheduler/ISF/LoweringIR.pm` builds state assignment arrays and
  non-state DT blocks. It records assignment `lhs`, `rhs`, `op`, and optional
  guard metadata, but it does not maintain a central same-target conflict
  registry.
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm` renders those assignment arrays in
  scheduled `.fsm` form. Rule DT assignments can be grouped by assignment-local
  guard, but the emitter does not diagnose multiple assignments to the same
  `lhs`.
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm` reports DT names, kinds, and
  assignment counts. It does not expose per-assignment ownership, target
  domains, fan-in provenance beyond DT names, or conflict metadata.
- `perl/FSM/Adapter/ISF/Parser.pm` rejects malformed public syntax and several
  namespace collisions, but it does not reject same-cycle semantic conflicts
  between otherwise valid actions.

Current accepted or intentionally generated shapes:

- Multiple rules may trigger the same transaction. Each `(trigger Tk)` inside
  rule `Rj` lowers to a distinct one-cycle delayed-pulse source named
  `Rj_Tk`; a generated combinational `Tk_trigger_fanin` DT ORs all such
  sources into `Tk_start`. This is the one explicit compatible fan-in
  precedent in the current implementation.
- A rule's non-trigger `(port value)` action lowers to a guarded rule DT action
  that flops `port` with `<-`. The parser accepts only scalar values today.
  There is no current ISF-level check that two simultaneously enabled rules
  drive the same `port`.
- Named drive definitions lower to non-state DTs. Each drive body assignment is
  emitted as `<- (lhs rhs)` guarded by the drive's `name_start` signal, with
  parameter actuals routed through generated `name_param` carriers. The parser
  checks drive names, parameter names, and body entry shape, but not duplicate
  body targets or same-target overlap between different drive DTs.
- Transaction-local `(sample port as name)` captures and extract field
  captures lower with `<=`, so the sample alias names the D input and can be
  observed in the same cycle by following state-DT logic. No global same-alias
  ownership policy exists today.
- `(complete port)` and timeout terminal paths lower completion outputs with
  `<1`, creating a one-cycle delayed pulse. Child completion handshakes also
  use `<1` for generated `child_done` signals. There is no general check that
  user-authored drive/rule paths do not also target the same completion port.
- `(do child)` and `(spawn child as instance)` emit ordinary combinational
  start assignments to `child_start` or `instance_start`; these direct
  transaction-control assignments are not currently merged through the
  rule-trigger fan-in mechanism.
- Watchdog, latency, repeat, child-handshake, drive-parameter, and rule-trigger
  helper signals are generated as ordinary scheduler-owned targets. Their
  storage widths and report summaries are inferred, but ownership is not yet
  represented as a conflict domain in schedule JSON.

Current rejected shapes and boundaries:

- Duplicate actor-local transaction names, rule names, drive names, actor
  phase names, actor stage names, and interface port names are rejected.
- Singleton actor clauses `(clock ...)`, `(reset ...)`, `(watchdog ...)`,
  `(interface ...)`, and `(resources ...)` fail closed when repeated.
- Rule action shapes are limited to scalar `(port value)`,
  `(trigger transaction)`, and `(priority over other_rule)`. Unknown trigger
  targets and unknown rule-priority targets are rejected.
- Actor-level `(priority lhs over rhs)` targets must resolve to declared rules
  or transactions. Resource entries must use
  `(resource name (arbiter priority|round_robin))` and duplicate resources are
  rejected.
- Drive body entries are limited to scalar `(port value)` pairs, drive
  parameter names must be scalar and unique per drive, duplicate drive
  definitions are rejected, and known drive calls must match declared arity.
- `(complete port)`, `(sample port as name)`, `(do transaction)`,
  `(spawn transaction as instance)`, sync, repeat, switch, when, data-operation,
  and child-target forms have focused shape validation, but those checks are
  syntax/target checks, not same-target conflict checks.

Conflict domains named for the next policy slices:

- Transaction start domain: `Tk_start` requests, per-rule `Rj_Tk` trigger
  sources, generated `Tk_trigger_fanin` DTs, and direct `do`/`spawn` start
  assignments.
- Public output/data-drive domain: interface outputs and user-visible storage
  driven by rule actions, named drive bodies, inline transaction drives,
  updates, shifts, assembles, and extracts.
- Completion/done domain: `(complete port)` pulses, timeout completion pulses,
  generated child-done pulses, and any author path that targets the same done
  signal.
- Sample/alias capture domain: `(sample port as name)` and extract-field
  captures that use `<=` D-input naming and may be consumed by following state
  logic.
- Generated helper/storage domain: watchdog counters, latency counters and
  error flags, repeat counters, drive parameter carriers, child start/done
  signals, and rule-trigger source pulses.
- Resource/priority domain: parser-carried `(resources ...)`,
  actor-level `(priority lhs over rhs)`, and rule-local
  `(priority over other_rule)` metadata that is validated today but not yet
  enforced as arbitration.

The key gap is therefore explicit: ISF lowering currently accumulates
assignments and relies on downstream `.fsm` semantics for most same-target
cases. The conflict work must introduce scheduler-level ownership/conflict
tracking so compatible fan-in is deliberate and incompatible same-cycle drives
fail closed with targeted diagnostics.

## Deterministic Compatible Fan-In Policy

`ISF-CONFLICTS.2` defines the compatible fan-in cases that future
implementation slices may merge deliberately. The policy is intentionally
narrow: it allows merges only when every active source requests the same
observable effect. Anything else belongs to `ISF-CONFLICTS.3` fail-closed and
priority policy.

Compatible same-target cases:

- Same target, same assignment operator, same canonical value: multiple sources
  that select the same `LHS`/`VAL` pair are compatible. Their enable/write
  predicates merge by OR into one selector for that `LHS`/`VAL` pair. This is
  the ordinary DT mux-selector model made explicit at the ISF scheduler level.
- One-bit event/request fan-in: multiple sources that assert the same one-bit
  request signal with value `1` are compatible when the signal is classified as
  an event/request target. The generated implementation must OR source
  predicates or source pulse signals into one canonical target request.
- One-cycle pulse fan-in: multiple `<1 (target 1)` sources for the same
  pulse-class target are compatible when the target is intended as a pulse
  such as a completion/done event. The WEN predicates merge by OR; no source
  may request `0`, use another operator, or carry payload data in this domain.
- Rule-trigger fan-in remains the shipped precedent: every rule trigger source
  keeps its distinct `Rj_Tk` delayed-pulse carrier, and a generated
  `Tk_trigger_fanin` DT ORs those carriers into `Tk_start`.

Cases that must not be silently merged as compatible fan-in:

- Same `lhs` with different values, different RHS expressions, or different
  assignment operators. A value conflict is not solved by ORing enables unless
  a later policy proves mutual exclusion or applies explicit priority.
- Data/payload carriers for drive parameters, samples, extracts, updates,
  shifts, assembles, counters, and status fields when the candidate sources can
  carry different values. These are data mux domains, not event fan-in domains.
- A start/request signal whose associated payload or parameter carriers would
  conflict in the same cycle. ORing the start signal alone is insufficient if
  the receiver also consumes shared generated payload carriers.
- Any generated helper signal that is not explicitly marked as shareable by its
  domain owner. Helper names should not become accidental fan-in points merely
  because two generated paths chose the same string.

Generated helper sharing policy:

- Transaction start helpers are shareable request targets. Rule triggers keep
  the existing per-rule `Rj_Tk` source names and `Tk_trigger_fanin` DT. Future
  non-rule start request sources, such as direct child `do` callers, may join
  the same start-request domain only through named source ownership and a
  generated OR fan-in point.
- Named drive starts are shareable request targets only together with their
  parameter-carrier policy. The drive's `drive_start` request can be ORed, but
  `drive_param` carriers are not request fan-in; they need one active writer,
  identical values, or later priority/resource handling.
- Completion/done helpers are pulse targets when generated by `(complete ...)`,
  timeout completion, or child completion. They may merge only as `<1 value 1`
  pulse fan-in.
- Rule-trigger source helpers are not shared. They are unique per
  `(rule, transaction)` pair so diagnostics and schedule reports can preserve
  trigger provenance before the target fan-in.
- Watchdog counters, latency counters/error flags, repeat counters, sample
  aliases, extract fields, and drive parameter carriers default to single-owner
  data/helper domains. Sharing them requires a later explicit same-value,
  mutual-exclusion, priority, or resource policy.

Implementation consequence for later leaves:

- The scheduler should classify assignments by domain before emission:
  `request`, `pulse`, `data`, `helper`, or `resource_arbitrated`.
- Compatible merges should be recorded in IR with source provenance so schedule
  reports can expose fan-in without freezing a broad public conflict API too
  early.
- The emitted scheduled `.fsm` should be a consequence of the policy, not the
  place where ISF discovers whether a same-target merge was safe.

## Fail-Closed And Priority Policy

`ISF-CONFLICTS.3` defines what happens when same-target sources are not
compatible fan-in. The rule is fail closed unless the scheduler can prove that
the sources cannot be active in the same cycle or can select a unique winner
through explicit priority.

Conflict detection is activation-aware:

- Different values for the same target are not a conflict when their source
  activation predicates are mutually exclusive. Ordinary distinct FSM state
  decode predicates are the baseline structural mutual-exclusion proof.
- If overlap is possible, or the scheduler cannot prove non-overlap, the
  sources must either match a compatible fan-in rule or be resolved by explicit
  priority.
- Compile-time proof is best-effort. When the scheduler cannot prove a case
  safe or conflicting, it must flag that proof is not doable for that case
  instead of silently treating the design as conflict-free.
- Text order is never an arbitration rule. Author order may preserve reporting
  determinism, but it must not choose hardware behavior for an incompatible
  same-cycle drive.

Incompatible writes without priority:

- Same target with different values or different RHS expressions in overlapping
  activation regions fails before scheduled `.fsm`/HDL is accepted.
- Same target with different assignment operators, such as `=`, `<-`, `<=`, or
  `<1`, fails even if priority metadata exists. Mixed timing operators describe
  different hardware contracts, not just different data values.
- Same source owner assigning different values to the same target in one active
  region fails. Priority cannot order an owner against itself.
- Same drive body, same rule body, or same generated helper family emitting
  conflicting payload/data assignments fails unless the assignments collapse to
  the same target/operator/value selector.
- Diagnostics should name the target, domain, assignment operators, source
  owners, representative values/RHS expressions, and the missing policy
  needed to proceed.

Declared priority policy:

- Actor-level `(priority lhs over rhs)` and rule-local
  `(priority over other_rule)` form one priority graph over source owners.
  Parser validation already ensures that declared targets exist; the conflict
  implementation must additionally detect cycles and ambiguous incomparable
  winners for a given conflict set.
- Priority is target-local for this conflict model. A priority edge selects the
  winning assignment for the conflicting target/domain; it must not silently
  disable unrelated non-conflicting actions unless a later resource-arbitration
  policy introduces explicit owner-wide grants.
- Priority can resolve data/value conflicts only within one timing/domain
  class. It does not legalize mixed `=`, `<-`, `<=`, and `<1` drives to the
  same target.
- If one unique maximal source remains after applying the priority graph, that
  source wins for the conflicting target. If two or more incomparable maximal
  sources remain and they drive different values, the scheduler fails closed.
- Rule-local priority is equivalent to an edge from the containing rule to the
  referenced rule. Actor-level priority can order rules or transactions. A
  transaction priority edge applies to assignments owned by that transaction's
  active states, not to generated helper signals owned by another domain.
- A lower-priority source still participates when no higher-priority conflicting
  source is active. Priority selects among overlapping contenders; it does not
  erase the lower-priority behavior.

Deferred resource-arbitration policy:

- `(resources ...)` metadata is validated and preserved today, but no current
  syntax binds a rule, transaction, drive, or output to a named resource. A
  declared resource therefore cannot by itself resolve a same-target conflict.
- A `priority` resource arbiter is a future owner-wide grant mechanism, not a
  substitute for the target-local priority policy above until resource usage
  binding exists.
- A `round_robin` resource arbiter requires stateful grant generation and
  fairness semantics. It is deferred to the resource/priority task tree and
  must not be approximated by author order or by combinational ORs.
- Until resource arbitration is implemented, any conflict whose only plausible
  resolution is a named resource must fail with a diagnostic that says resource
  arbitration is declared but not enforced for that conflict.

## Runtime Selector Conflict Verification

Compile-time conflict detection is useful but inherently incomplete. The tree
therefore keeps a separate runtime-verification path for selector conflicts.
That path is verification-only for now.

Runtime conflict checks follow the mux-selector model:

- For each `LHS` mux, every selectable `VAL` has a one-bit selector. That
  selector is the logical OR of all FSM/ISF-origin source selectors for the
  corresponding `LHS`/`VAL` pair.
- A verification check can flag multiple active source selectors contributing
  to the same `LHS`/`VAL` selector in the same cycle when the policy wants
  one-hot source ownership for that selector.
- A verification check must flag two or more different `VAL` selectors active
  for the same `LHS` mux in the same cycle, because that means the design is
  trying to mux out different values to one target.
- The same reasoning applies inside an ISF transaction or FSM-local lowering
  region when the needed selector signals are still visible.

This runtime path complements, rather than replaces, compile-time analysis:
compile-time checks should catch and reject what they can prove; unprovable
cases should be flagged; verification-only selector checks can then catch the
remaining runtime-active conflicts.

## Assignment Provenance Inventory

`ISF-CONFLICTS.4.1` adds the first internal implementation layer for conflict
tracking. `FSM::Scheduler::ISF::LoweringIR` now finalizes each lowered module
with an `assignment_provenance` array before any scheduled `.fsm` text is
emitted.

Each provenance record carries:

- `owner` and `owner_kind`, naming the transaction, rule, drive, or generated
  owner associated with the assignment.
- `source_kind`, such as `drive_call_start`, `drive_call_param`,
  `complete_pulse`, `rule_action`, `rule_trigger_source`,
  `rule_trigger_fanin`, or `drive_body`.
- `target`, `operator`, and `rhs`, copied from the assignment that will be
  emitted.
- `domain`, a bounded hint such as `request`, `pulse`, `capture`, `helper`, or
  `data`.
- `assignment_index`, preserving the assignment's stable order within its
  source container.
- `activation`, naming the state or DT container plus the state guard, DT DTE
  guard, and assignment-local guard when present.

This slice does not change emitted scheduled `.fsm`, generated HDL, or the
public schedule-report schema. Schedule-report projection belongs to
`ISF-CONFLICTS.5`; compatible fan-in classification belongs to
`ISF-CONFLICTS.4.2`.

## Compatible Fan-In Classification

`ISF-CONFLICTS.4.2` adds a second internal implementation layer:
`LoweringIR` now derives `compatible_fanin_groups` from
`assignment_provenance`.

The classifier records compatible groups for:

- `same_target_value`: same `target`, `operator`, `rhs`, and non-helper
  `domain`. This represents ordinary selector ORing for one `LHS`/`VAL` pair.
- `request`: multiple request-domain sources for the same request target.
  This includes combinations such as a direct `do` start request and a
  generated rule-trigger fan-in request for the same transaction start.
- `pulse`: multiple one-cycle pulse-domain sources for the same target and
  pulse value, such as several `(complete done)` paths.
- `rule_trigger_fanin`: per-rule trigger-source pulses grouped by target
  transaction before the generated `transaction_trigger_fanin` request.

The classifier intentionally skips helper-domain same-value groups such as
`can_accept`, watchdog, latency, or repeat helpers. Those generated helpers
remain single-owner or future diagnostics territory unless a later policy marks
them shareable.

This slice is still internal: it does not alter scheduled `.fsm` emission,
public schedule-report JSON, or HDL generation. It gives the next leaves a
bounded candidate set for compile-time conflict detection and diagnostics.

## Best-Effort Static Conflict Detection

`ISF-CONFLICTS.4.3` adds internal `conflict_issues` derivation to
`LoweringIR`. The analysis is intentionally best-effort:

- Compatible pairs are skipped using the same same-value, request, and pulse
  rules as `compatible_fanin_groups`.
- Statically provable conflicting rule/rule data writes to the same target now
  fail closed during lowering with a targeted `isf_conflicting_rule_writes`
  diagnostic.
- Rule/drive data conflicts are flagged internally as
  `isf_unproven_rule_drive_overlap` with `proof_status => not_doable`.
  They are not rejected yet because this slice cannot prove the rule guard and
  generated drive-start guard overlap in all cases.
- Ordinary transaction state assignments remain accepted. The analysis does
  not treat different transaction states as same-cycle conflicts merely because
  they assign different values to the same target.

At the time of `ISF-CONFLICTS.4.3`, the public schedule report still exposed
successful `compile_issues` as an empty array. `ISF-CONFLICTS.5.2` now projects
nonfatal conflict diagnostics into that array.

## Target-Local Priority Resolution

`ISF-CONFLICTS.4.4` ships the first enforced priority behavior for ISF
conflicts:

- Supported scope is same-target rule/rule data conflicts. Rule/drive,
  transaction/transaction, resource, and mixed-domain arbitration remain
  outside this leaf.
- Rule-local `(priority over other_rule)` and actor-level
  `(priority high over low)` both contribute rule-priority edges when both
  endpoints are rules.
- A higher-priority rule suppresses the lower-priority rule's conflicting
  assignment by adding an assignment guard that negates the higher-priority
  rule condition. The priority is target-local: unrelated assignments in the
  lower-priority rule are not disabled.
- Priority cycles fail closed with `isf_priority_cycle_conflict`.
  Incomparable rule/rule conflicts still fail closed through the ordinary
  `isf_conflicting_rule_writes` diagnostic.
- Successful priority resolution changes the scheduled `.fsm` review artifact.
  It does not itself add compile issues; reports with no nonfatal issues still
  keep `compile_issues` empty.

## Runtime Selector Instrumentation

`ISF-CONFLICTS.4.5` ships verification-only runtime checks from the
post-lowering `.fsm` HDL backend:

- `LoweredRTLIR` now records generated mux-selector conflict targets from
  backend assignment analysis, not just public output-drive families.
- Same-value source selectors are checked with `$onehot0` over the per-DT or
  per-rule source enables that feed one `LHS`/`VAL` selector.
- Whole-mux value selectors are checked with `$onehot0` over the LHS-level
  value selector signals for one target mux.
- The emitted checks are SystemVerilog-only and wrapped in
  `` `ifndef SYNTHESIS``. Verilog output remains assertion-free.
- Standalone DT roots keep the earlier standalone-DT multi-drive assertion
  path rather than receiving a duplicate generic selector block.
- The metadata is generated from backend assignment analysis, so internal muxes
  such as `next_state` are covered along with ISF-authored data targets.

This leaf does not widen the successful public ISF schedule-report schema.
Report projection of conflict/fan-in metadata remains assigned to
`ISF-CONFLICTS.5`.

## Schedule Report Projection Boundary

`ISF-CONFLICTS.5.1` defines the public projection boundary for the later
diagnostics/report leaves. It does not change emitted JSON yet.
At that point, `compile_issues` still remained empty in successful schedule
reports and `compatible_fanin_groups` remained absent.

`ISF-CONFLICTS.5.2` now ships the `compile_issues` part of that boundary.
Nonfatal issues can appear in a successful schedule report. Fail-closed
conflicts still surface as targeted diagnostics instead of producing a
successful report, unless a future explicit error-report mode is designed.
Each projected conflict issue uses this bounded object shape:

- `code`: stable scalar diagnostic code, such as
  `isf_unproven_rule_drive_overlap`.
- `severity`: bounded scalar severity. The first projected conflict cases use
  `warning`; rejected conflicts stay outside successful schedule reports.
- `target`: scalar target signal or request name.
- `domain`: bounded domain name such as `data`, `request`, `pulse`,
  `capture`, or `helper`.
- `proof_status`: bounded proof result. The important current value is
  `not_doable`, meaning the scheduler is explicitly flagging that the
  compile-time proof is NOT doable for that case.
- `reason`: human-readable diagnostic text. Consumers should use `code` and
  `proof_status` for machine policy, not parse this text.
- `sources`: bounded source summaries.

Each public source summary is capped to scheduler ownership and target facts:
`owner`, `owner_kind`, `source_kind`, `target`, `operator`, `rhs`, and
`domain`. Raw activation context, assignment indexes, priority-suppression
bookkeeping, and the complete `assignment_provenance` records remain private
`LoweringIR` internals unless a later slice deliberately exposes a narrower
field.

`ISF-CONFLICTS.5.3` now ships the `compatible_fanin_groups` projection as
successful-report metadata for accepted fan-in groups. The field is a top-level
array that is present even when empty. Each group uses:

- `kind`: one of the shipped classifier families:
  `same_target_value`, `request`, `pulse`, or `rule_trigger_fanin`.
- `domain`: the fan-in domain used by the classifier.
- `sources`: the same bounded source-summary shape used by `compile_issues`.
- `target`: present for same-target, request, and pulse groups.
- `operator` and `rhs`: present when the fan-in depends on one
  target/operator/value selector.
- `target_transaction` and `fanin_target`: present for
  `rule_trigger_fanin`, naming the transaction and generated start target.

This projection is deliberately narrower than the internal classification
objects. It gives downstream consumers enough information to explain why a
multi-source case was accepted without freezing raw lowerer hashes, activation
proof internals, or future arbitration machinery as public API.

The public projection also avoids duplicating domain-specific fan-in groups as
generic same-value groups. For example, a `<1 done 1` pulse fan-in is reported
as `kind => pulse`, not as both `same_target_value` and `pulse`. That keeps the
public report focused while leaving the internal classifier free to keep
overlapping analysis views.

## Nonfatal Compile Issues Projection

`ISF-CONFLICTS.5.2` projects warning-level `conflict_issues` into schedule JSON
without changing fail-closed behavior. The current shipped case is
`isf_unproven_rule_drive_overlap`: a rule action and a generated drive body can
target the same data output, and the scheduler records that proving overlap or
mutual exclusion is `not_doable` in the current compile-time analysis.

The JSON emitter filters out `severity => error` issues. Those errors still
belong to the lowering diagnostic path, where they stop generation. Warnings
are emitted as bounded `compile_issues` entries, preserving only the fields
documented above plus bounded source summaries. Source activation trees,
assignment indexes, and priority-suppression metadata remain private even
though they exist internally.

The public contract metadata now advertises:

- `schedule_report_compile_issue_keys`
- `schedule_report_compile_issue_source_keys`
- `schedule_report_compile_issue_severity_values`
- `schedule_report_compile_issue_proof_status_values`

Successful reports with no nonfatal issues continue to expose
`compile_issues: []`, preserving the existing no-issue success shape for APB
and other ordinary fixtures.

## Compatible Fan-In Group Projection

`ISF-CONFLICTS.5.3` projects accepted compatible fan-in groups into schedule
JSON. The current report exposes a top-level `compatible_fanin_groups` array.
The array is empty when no accepted fan-in groups exist.

Projected group kinds are:

- `same_target_value` for same target/operator/value selector fan-in in
  ordinary data-like domains.
- `request` for accepted request/start fan-in.
- `pulse` for accepted one-cycle pulse fan-in.
- `rule_trigger_fanin` for the existing per-rule trigger-source OR into a
  transaction start.

Group entries expose required `kind`, `domain`, and `sources` keys, plus the
bounded optional target/value keys that apply to that group. Source summaries
reuse the same bounded ownership/target shape used by `compile_issues`.
Activation context and assignment indexes remain private.

## Rejected Conflict Diagnostic Coverage

`ISF-CONFLICTS.5.4` closes the diagnostics/report projection container. The
new coverage proves that provable rule/rule conflicts fail closed through both
the in-process scheduler (`lower(...)` and `report(...)`) and the CLI
`--emit-schedule-json` path.

Rejected conflict diagnostics must name:

- the stable code, currently `isf_conflicting_rule_writes`;
- the target, such as `valid`;
- the reason, such as overlapping rule data writes selecting different values;
- the conflicting owners, source kinds, operators, and values.

The CLI path must not emit successful schedule JSON on these rejected cases.
This keeps the contract clear: `compile_issues` is for nonfatal issues in
successful reports, while proved incompatible conflicts remain fail-closed
diagnostics.

## Decisions

- `2026-05-14`: The conflict-resolution work will be tracked as a task tree
  because it is expected to branch into policy, implementation, diagnostics,
  tests, and documentation subtasks.
- `2026-05-14`: The existing rule-trigger fan-in implementation remains a
  compatible fan-in precedent, not a license to silently merge every same-target
  drive.
- `2026-05-14`: `ISF-CONFLICTS.1` established that rule-trigger fan-in is the
  only explicit compatible same-target merge path in the current ISF lowerer.
  Other same-target cases are accepted or rejected by narrower syntax/namespace
  boundaries, not by a general ISF conflict model.
- `2026-05-14`: `ISF-CONFLICTS.2` narrows compatible fan-in to same
  `LHS`/operator/value selectors, one-bit request/event ORs, one-cycle
  pulse-class `<1 target 1` ORs, and the existing per-rule transaction-trigger
  fan-in shape. Payload/data conflicts and mixed timing operators must not be
  silently merged.
- `2026-05-14`: `ISF-CONFLICTS.3` makes incompatible overlap fail closed
  unless activation predicates are provably mutually exclusive or explicit
  priority selects one unique winner within the same timing/domain class.
  Resource declarations remain metadata until usage binding and arbiter
  lowering are implemented.
- `2026-05-14`: `ISF-CONFLICTS.4` was split into executable implementation
  leaves before code changes: provenance inventory, compatible fan-in
  classification, unprioritized conflict detection, and target-local priority.
- `2026-05-14`: `ISF-CONFLICTS.4.1` keeps assignment provenance internal to
  `LoweringIR` for now. Public schedule-report projection is deferred to
  `ISF-CONFLICTS.5` so the report schema does not widen before diagnostics are
  designed.
- `2026-05-14`: Compile-time conflict detection is best-effort. Cases where
  static proof is not doable must be flagged explicitly, and verification-only
  runtime selector conflict instrumentation is tracked as `ISF-CONFLICTS.4.5`.
- `2026-05-14`: `ISF-CONFLICTS.4.2` keeps compatible fan-in classification
  internal to `LoweringIR` through `compatible_fanin_groups`; public projection
  remains deferred until diagnostics/report policy is implemented.
- `2026-05-14`: `ISF-CONFLICTS.4.3` adds internal best-effort
  `conflict_issues`: provable rule/rule data conflicts fail closed, while
  rule/drive overlap is flagged as `not_doable` until a later slice can prove
  or instrument it.
- `2026-05-14`: `ISF-CONFLICTS.4.4` applies target-local priority resolution
  to same-target rule/rule data conflicts by guarding lower-priority
  assignments with the inverse higher-priority rule condition. Priority cycles
  fail closed.
- `2026-05-14`: `ISF-CONFLICTS.4.5` implements verification-only selector
  checks in the generated-module HDL path rather than the ISF scheduler. That
  keeps checks tied to the actual mux selector signals after all backend
  factoring and LHS-level selector generation are complete.
- `2026-05-14`: `ISF-CONFLICTS.5` is split before implementation because
  report projection needs a schema boundary before public schedule-report
  emission changes, then separate nonfatal issue projection, fan-in projection,
  and rejected-diagnostic closure leaves.
- `2026-05-14`: `ISF-CONFLICTS.5.1` defines a bounded schedule-report
  projection boundary before emitter changes. Nonfatal `compile_issues`
  entries will expose stable issue code, severity, target/domain,
  `proof_status`, reason text, and capped source summaries; compatible fan-in
  groups will expose only group kind/domain, target/value facts, and the same
  capped source summaries. Raw provenance and activation proof internals remain
  private.
- `2026-05-14`: `ISF-CONFLICTS.5.2` ships the nonfatal `compile_issues`
  projection for successful schedule reports. Warning issues are projected with
  bounded issue/source keys; error issues remain fail-closed diagnostics.
- `2026-05-14`: `ISF-CONFLICTS.5.3` ships accepted compatible fan-in group
  projection through a top-level `compatible_fanin_groups` array. The public
  projection is intentionally narrower than internal classification and avoids
  duplicate generic same-value entries for request/pulse fan-in.
- `2026-05-14`: `ISF-CONFLICTS.5.4` closes diagnostics/report projection by
  regression-covering rejected conflict diagnostics in the in-process scheduler
  and CLI schedule-report path. `compile_issues` remains nonfatal-only.

## Open Questions

- Which generated start/request sources besides rule triggers should be
  normalized into source carriers during the first implementation slice?
- Should the first implementation slice include only diagnostics, or also
  accepted priority lowering for data conflicts with one unique winner?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-CONFLICTS` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.1` | Source/test inspection of `LoweringIR`, scheduled `.fsm` emitter, schedule JSON emitter, parser boundaries, and focused ISF rule/drive/complete tests | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.1` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.2` | Compatible fan-in policy documented in the task tree and live docs | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.2` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.3` | Fail-closed, priority, and deferred resource-arbitration policy documented in the task tree and live docs | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.3` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4` | Split into executable implementation leaves | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.1` | `prove -l t/1207-isf-assignment-provenance-inventory.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.1` | `bin/ci-regression isf --no-book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.1` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.2` | `prove -l t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.2` | `bin/ci-regression isf --no-book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.2` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.3` | `prove -l t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t t/1209-isf-static-conflict-detection.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.3` | `bin/ci-regression isf --no-book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.3` | `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1209-isf-static-conflict-detection.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.3` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.3` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.4` | `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1207-isf-assignment-provenance-inventory.t t/1208-isf-compatible-fanin-classification.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.4` | `prove -l t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.4` | `bin/ci-regression isf --no-book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.4` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.4` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.5` | `prove -l t/1211-isf-runtime-selector-conflict-instrumentation.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.5` | `prove -l t/154-standalone-dt-assertion-runtime-hdl.t t/156-forward-lowered-rtl-ir-surface.t t/170-forward-lowered-rtl-ir-output-drive-helpers.t t/194-generated-module-emitter.t t/497-lowered-rtl-ir-accessor-defensive-copy-boundary-audit.t t/590-direct-generation-module-info-lowered-ir-alias-boundary-audit.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.5` | `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t t/1211-isf-runtime-selector-conflict-instrumentation.t t/154-standalone-dt-assertion-runtime-hdl.t t/156-forward-lowered-rtl-ir-surface.t t/170-forward-lowered-rtl-ir-output-drive-helpers.t t/194-generated-module-emitter.t t/497-lowered-rtl-ir-accessor-defensive-copy-boundary-audit.t t/590-direct-generation-module-info-lowered-ir-alias-boundary-audit.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.5` | `prove -l t/305-hdl-generator-result-contract.t t/340-normalized-semantic-lowered-rtl-ir-contract.t t/343-hdl-generator-module-info-contract.t t/190-pipeline-direct-generation-orchestrator.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.5` | `bin/ci-regression isf --no-book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.5` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.4.5` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5` | Split into executable diagnostics/report projection leaves | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.1` | Bounded schedule-report projection schema documented in the task tree, ISF spec, public contract, and mdBook | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.1` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.1` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.2` | `prove -l t/1212-isf-schedule-report-compile-issues-projection.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.2` | `prove -l t/1130-isf-public-compile-issues-success-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.2` | `prove -l t/1116-isf-public-schedule-report-key-family-audit.t t/1121-isf-public-cli-schedule-report-audit.t t/1172-isf-rule-trigger-fanin-schedule-report.t t/1209-isf-static-conflict-detection.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.2` | `bin/ci-regression isf --no-book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.2` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.2` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.3` | `prove -l t/1213-isf-schedule-report-compatible-fanin-projection.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.3` | `prove -l t/1096-isf-schedule-json-report.t t/1116-isf-public-schedule-report-key-family-audit.t t/1140-isf-public-schedule-report-metadata-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1131-isf-public-top-level-discovery-audit.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.3` | `bin/ci-regression isf --no-book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.3` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.3` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.4` | `prove -l t/1214-isf-rejected-conflict-diagnostics.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.4` | `prove -l t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t t/1144-isf-public-tested-by-metadata-audit.t` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.4` | `bin/ci-regression isf --no-book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.4` | `mdbook build docs/book` | `passed` |
| `2026-05-14` | `ISF-CONFLICTS.5.4` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONFLICTS` | `Docs: formalize repo-local task tree` | Initial tree creation is part of the repo-local task-tree workflow slice. |
| `ISF-CONFLICTS.1` | `ISF-CONFLICTS.1: inventory current conflict domains` | Records the inspected current behavior and names conflict domains before policy/implementation work. |
| `ISF-CONFLICTS.2` | `ISF-CONFLICTS.2: specify compatible fan-in policy` | Records the deterministic OR/fan-in policy for compatible request, pulse, and same-value selector domains. |
| `ISF-CONFLICTS.3` | `ISF-CONFLICTS.3: specify conflict priority policy` | Records fail-closed behavior for incompatible overlap and target-local priority/resource boundaries. |
| `ISF-CONFLICTS.4` | `ISF-CONFLICTS.4: split conflict tracking implementation` | Splits the broad implementation container into executable provenance, classification, detection, and priority leaves. |
| `ISF-CONFLICTS.4.1` | `ISF-CONFLICTS.4.1: add ISF assignment provenance` | Adds internal `LoweringIR` assignment provenance records and focused regression coverage. |
| `ISF-CONFLICTS.4.2` | `ISF-CONFLICTS.4.2: classify ISF fan-in groups` | Adds internal compatible fan-in group classification from assignment provenance. |
| `ISF-CONFLICTS.4.3` | `ISF-CONFLICTS.4.3: add ISF static conflict checks` | Adds internal best-effort conflict issues, rule/rule rejection, and rule/drive `not_doable` flags. |
| `ISF-CONFLICTS.4.4` | `ISF-CONFLICTS.4.4: apply ISF rule priority resolution` | Adds target-local rule-priority suppression for same-target rule/rule data conflicts. |
| `ISF-CONFLICTS.4.5` | `ISF-CONFLICTS.4.5: add runtime selector assertions` | Adds verification-only SystemVerilog selector assertions from backend assignment analysis. |
| `ISF-CONFLICTS.5` | `ISF-CONFLICTS.5: split diagnostics projection` | Splits diagnostics/report projection into schema, compile-issues, fan-in, and rejected-diagnostic leaves. |
| `ISF-CONFLICTS.5.1` | `ISF-CONFLICTS.5.1: define report projection schema` | Defines the bounded public shape for planned nonfatal `compile_issues` entries and compatible fan-in group summaries. |
| `ISF-CONFLICTS.5.2` | `ISF-CONFLICTS.5.2: project compile issues` | Emits warning-level conflict issues in schedule-report `compile_issues` using bounded issue/source summaries. |
| `ISF-CONFLICTS.5.3` | `ISF-CONFLICTS.5.3: project fan-in groups` | Emits accepted compatible fan-in groups in schedule-report `compatible_fanin_groups`. |
| `ISF-CONFLICTS.5.4` | `ISF-CONFLICTS.5.4: cover rejected diagnostics` | Adds in-process and CLI fail-closed diagnostic coverage and closes the projection container. |

## Changelog

- `2026-05-14`: Created the active ISF conflict-resolution task tree.
- `2026-05-14`: Completed `ISF-CONFLICTS.1` inventory; current frontier moves
  to `ISF-CONFLICTS.2` for compatible fan-in merge policy.
- `2026-05-14`: Completed `ISF-CONFLICTS.2` compatible fan-in policy; current
  frontier moves to `ISF-CONFLICTS.3` for incompatible-drive, priority, and
  resource-arbitration policy.
- `2026-05-14`: Completed `ISF-CONFLICTS.3` fail-closed and priority policy;
  current frontier moves to `ISF-CONFLICTS.4` for scheduler/emitter conflict
  tracking.
- `2026-05-14`: Split `ISF-CONFLICTS.4`; current frontier moves to
  `ISF-CONFLICTS.4.1` for scheduler-side assignment provenance inventory.
- `2026-05-14`: Completed `ISF-CONFLICTS.4.1`; current frontier moves to
  `ISF-CONFLICTS.4.2` for compatible fan-in classification from provenance.
- `2026-05-14`: Completed `ISF-CONFLICTS.4.2`; current frontier moves to
  `ISF-CONFLICTS.4.3` for best-effort compile-time conflict detection and
  flags for cases where proof is not doable.
- `2026-05-14`: Completed `ISF-CONFLICTS.4.3`; current frontier moves to
  `ISF-CONFLICTS.4.4` for target-local priority resolution.
- `2026-05-14`: Completed `ISF-CONFLICTS.4.4`; current frontier moves to
  `ISF-CONFLICTS.4.5` for verification-only runtime selector conflict
  instrumentation.
- `2026-05-14`: Completed `ISF-CONFLICTS.4.5`; current frontier moves to
  `ISF-CONFLICTS.5` for diagnostics and schedule-report projection.
- `2026-05-14`: Split `ISF-CONFLICTS.5`; current frontier moves to
  `ISF-CONFLICTS.5.1` for bounded conflict/fan-in schedule-report projection
  schema definition.
- `2026-05-14`: Completed `ISF-CONFLICTS.5.1`; current frontier moves to
  `ISF-CONFLICTS.5.2` for nonfatal conflict issue projection into
  `compile_issues`.
- `2026-05-14`: Completed `ISF-CONFLICTS.5.2`; current frontier moves to
  `ISF-CONFLICTS.5.3` for compatible fan-in group projection.
- `2026-05-14`: Completed `ISF-CONFLICTS.5.3`; current frontier moves to
  `ISF-CONFLICTS.5.4` for rejected-conflict diagnostic coverage and projection
  docs closure.
- `2026-05-14`: Completed `ISF-CONFLICTS.5.4` and the `ISF-CONFLICTS.5`
  container; current frontier moves to `ISF-CONFLICTS.6`.
