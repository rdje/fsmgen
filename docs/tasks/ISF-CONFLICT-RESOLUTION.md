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
  Status: `pending`
  Goal: `Specify fail-closed and priority policy for incompatible drives.`
  Acceptance: `The task file records the policy for incompatible writes,
  missing priority, declared priority, and deferred resource arbitration.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONFLICTS.4`
  Status: `pending`
  Goal: `Implement scheduler/emitter conflict tracking.`
  Acceptance: `The implementation can distinguish compatible fan-in from
  incompatible same-cycle drive conflicts without relying on text-order
  accidents in emitted `.fsm`.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-CONFLICTS.5`
  Status: `pending`
  Goal: `Add diagnostics and schedule-report projection.`
  Acceptance: `Rejected conflict cases report targeted diagnostics, and
  accepted conflict/fan-in cases are visible in bounded schedule-report
  metadata where useful for downstream consumers.`
  Verification: `pending`
  Commit: `pending`

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
| 1 | `ISF-CONFLICTS.3` | `pending` | Compatible fan-in policy is specified; the next policy gap is incompatible same-cycle drives, priority, and deferred resource arbitration. |

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

## Open Questions

- Should priority metadata be enforced in this tree, or should this tree first
  fail closed for conflicts that require priority semantics?
- Which schedule-report fields are necessary for downstream consumers without
  prematurely freezing a broad conflict-report API?
- Which generated start/request sources besides rule triggers should be
  normalized into source carriers during the first implementation slice?

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

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-CONFLICTS` | `Docs: formalize repo-local task tree` | Initial tree creation is part of the repo-local task-tree workflow slice. |
| `ISF-CONFLICTS.1` | `ISF-CONFLICTS.1: inventory current conflict domains` | Records the inspected current behavior and names conflict domains before policy/implementation work. |
| `ISF-CONFLICTS.2` | `ISF-CONFLICTS.2: specify compatible fan-in policy` | Records the deterministic OR/fan-in policy for compatible request, pulse, and same-value selector domains. |

## Changelog

- `2026-05-14`: Created the active ISF conflict-resolution task tree.
- `2026-05-14`: Completed `ISF-CONFLICTS.1` inventory; current frontier moves
  to `ISF-CONFLICTS.2` for compatible fan-in merge policy.
- `2026-05-14`: Completed `ISF-CONFLICTS.2` compatible fan-in policy; current
  frontier moves to `ISF-CONFLICTS.3` for incompatible-drive, priority, and
  resource-arbitration policy.
