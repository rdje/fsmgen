# ISF-RULE-ACTIONS: Expression-Valued Rule Assignments

## Metadata

- Tree ID: `ISF-RULE-ACTIONS`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-14`
- Last updated: `2026-05-14`
- Owner: repo-local workflow

## Goal

Allow ISF rule actions to assign expression values where the expression can be
validated, lowered, scheduled, reported, and generated without weakening the
current rule guard, delayed trigger, and conflict semantics.

## Non-Goals

- Do not reintroduce the removed transaction `(assign ...)` keyword in this
  tree; compatibility decisions belong to `ISF-COMPATIBILITY`.
- Do not bypass `.fsm` expression validation by emitting raw scheduler text.
- Do not choose a conflict winner for expression-valued assignments without
  the policy from `ISF-CONFLICTS` and `ISF-RESOURCE-PRIORITY`.

## Acceptance Criteria

- Current rule action parsing and malformed-boundary behavior is inventoried.
- Expression-valued rule assignment syntax is documented precisely.
- Expressions lower through structured scheduler/`.fsm` expression paths,
  including width and symbol validation.
- Same-target expression assignments participate in the documented conflict
  policy.
- Schedule reports and public contract metadata describe the widened rule
  assignment family.
- Focused regressions cover valid expressions, malformed expressions,
  conflicts, CLI behavior, and docs.

## Task Tree

- ID: `ISF-RULE-ACTIONS`
  Status: `active`
  Goal: `Ship expression-valued rule assignments.`
  Children: `ISF-RULE-ACTIONS.1`, `ISF-RULE-ACTIONS.2`,
  `ISF-RULE-ACTIONS.3`, `ISF-RULE-ACTIONS.4`, `ISF-RULE-ACTIONS.5`

- ID: `ISF-RULE-ACTIONS.1`
  Status: `done`
  Goal: `Inventory current rule action parser/lowering/report behavior.`
  Acceptance: `The task file lists accepted rule actions, malformed rule
  action diagnostics, scalar-only limits, storage/report metadata, and conflict
  touchpoints.`
  Verification: `prove -l t/1168-isf-rule-guard-factoring.t t/1169-isf-rule-shorthand-guard.t t/1171-isf-rule-trigger-fanin.t t/1172-isf-rule-trigger-fanin-schedule-report.t t/1181-isf-rule-action-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RULE-ACTIONS.1: inventory rule action behavior`

- ID: `ISF-RULE-ACTIONS.2`
  Status: `done`
  Goal: `Specify expression-valued rule assignment syntax and semantics.`
  Acceptance: `The tree records accepted expression forms, symbol visibility,
  width rules, assignment family, guard interaction, and rejected cases.`
  Verification: `prove -l t/1168-isf-rule-guard-factoring.t t/1169-isf-rule-shorthand-guard.t t/1171-isf-rule-trigger-fanin.t t/1172-isf-rule-trigger-fanin-schedule-report.t t/1181-isf-rule-action-boundary.t t/1198-isf-update-clause-boundary.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RULE-ACTIONS.2: specify rule expression assignments`

- ID: `ISF-RULE-ACTIONS.3`
  Status: `done`
  Goal: `Implement expression lowering for rule assignments.`
  Acceptance: `Valid expressions preserve through scheduled FSM emission
  and HDL generation, while invalid expressions fail before emission.`
  Verification: `perl -I perl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1181-isf-rule-action-boundary.t t/1198-isf-update-clause-boundary.t t/1221-isf-rule-expression-assignment.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check`
  Commit: `ISF-RULE-ACTIONS.3: implement rule expression assignments`

- ID: `ISF-RULE-ACTIONS.4`
  Status: `pending`
  Goal: `Integrate rule expressions with conflict tracking and reports.`
  Acceptance: `Expression-valued rule assignments are counted, reported, and
  checked against same-target conflict policy.`
  Verification: `pending`
  Commit: `pending`

- ID: `ISF-RULE-ACTIONS.5`
  Status: `pending`
  Goal: `Add tests and synchronize docs/contracts.`
  Acceptance: `Focused tests and docs cover valid expression assignments,
  malformed cases, conflict cases, schedule report behavior, and public
  contract updates.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-RULE-ACTIONS.4` | `pending` | Expression RHS lowering is implemented; next integrate the widened assignment family with conflict/report tracking. |

## ISF-RULE-ACTIONS.1 Inventory

This inventory records the shipped rule-action surface before expression-valued
rule assignments are widened. It is a current-behavior record, not a frozen
API promise.

### Accepted Rule Guard Forms

- `(rule name action...)` is accepted. With no guard, the lowerer uses a
  constant `1` rule DTE.
- `(rule name condition action...)` is the preferred shorthand guard form.
  `condition` must be a scalar token. The parser normalizes it to the public
  `when => ['when', condition]` field.
- `(rule name (when condition) action...)` remains accepted and normalizes to
  the same public `when` field.
- A rule accepts at most one guard. Mixing shorthand and long-form guards, or
  repeating long-form guards, fails before actor-shell return.
- Rule-local `(when condition)` has no body. Body-bearing transaction
  `(when condition body...)` syntax is not accepted in a rule.

### Accepted Rule Action Forms

- `(port value)` is the current assignment action. `port` is any non-empty
  scalar action head other than reserved `trigger` and `priority`; `value`
  must be a scalar. The parser does not accept expression/list RHS values yet.
- `(trigger transaction)` requests a transaction. The target must be a
  non-empty scalar name resolving to a declared same-actor transaction.
  Forward references are accepted because validation runs after the full
  actor body is collected.
- `(priority over other_rule)` declares a rule-local priority edge. The target
  must be a non-empty scalar name resolving to a declared same-actor rule.
  Forward references are accepted.
- Unknown two-item list actions are treated as `(port value)` assignments
  unless their head is one of the reserved action heads above.

### Malformed Boundary Diagnostics

- A scalar action fails with
  `Error: rule '<name>' actions must be list forms`.
- A list action with a nested/non-scalar head fails with
  `Error: rule '<name>' action heads must be scalar`.
- Malformed triggers fail with
  `Error: rule '<name>' trigger requires '(trigger transaction)'`.
- Malformed rule-local priorities fail with
  `Error: rule '<name>' priority requires '(priority over other_rule)'`.
- Assignment actions with missing values, extra structure, or list RHS values
  fail with `Error: rule '<name>' assignment actions require '(port value)'`.
- Unknown trigger targets fail with
  `Error: rule '<name>' triggers unknown transaction '<target>' in actor '<actor>'`.
- Unknown priority targets fail with
  `Error: rule '<name>' priority targets unknown rule '<target>' in actor '<actor>'`.
- Duplicate guards fail with
  `Error: rule '<name>' accepts only one guard condition`.
- Malformed guards fail with
  `Error: rule '<name>' guard requires exactly one scalar condition`.

### Lowering Behavior

- Each rule lowers to one non-state DT with `kind => 'rule'`.
- The rule guard lowers to the DT header DTE. The lowerer emits the guard once
  as the DT enable instead of repeating it on every action.
- `(port value)` lowers to a flopped assignment with `op => '<-'` and
  `source_kind => 'rule_action'`.
- `(trigger transaction)` lowers to a one-cycle delayed pulse with
  `op => '<1'` on a generated per-rule source named
  `<rule>_<transaction>`, with `source_kind => 'rule_trigger_source'`.
- For each triggered transaction, the scheduler emits one generated
  `<transaction>_trigger_fanin` non-state DT. It drives
  `<transaction>_start` combinationally from the single source or the OR of
  all per-rule sources.
- `(priority over other_rule)` does not emit an assignment. The priority edge
  participates in the rule priority model used by covered conflict and
  resource-arbitration paths.

### Schedule Report And Storage Metadata

- Schedule reports expose rule DTs through `dt_blocks` entries with
  `kind => 'rule'` and an assignment count. They do not expose raw rule action
  payloads.
- Generated trigger fan-in DTs appear in `dt_blocks` with
  `kind => 'rule_trigger_fanin'`.
- Rule trigger source signals and generated transaction start signals are
  reported as one-bit scheduler-inferred storage in `inferred_storage`.
- Ordinary rule-action LHS storage is not itemized as a dedicated schedule
  report storage entry today; downstream users should rely on scheduled
  `.fsm`/HDL output, not the storage summary, for those rule-action registers.
- Successful priority/resource decisions project through
  `priority_resolutions` and `resource_arbitration`. Raw suppression
  bookkeeping remains internal.

### Conflict Touchpoints

- Rule assignment records use `source_kind => 'rule_action'` and participate
  in static data-conflict analysis.
- Same-target rule/rule assignments with the same operator and RHS are treated
  as compatible fan-in.
- Same-target rule/rule assignments with incompatible RHS values fail closed
  with `isf_conflicting_rule_writes` unless covered priority or resource
  arbitration resolves the overlap.
- Rule-local priority and actor-level rule priority can suppress the
  lower-priority assignment in the covered rule/rule data-conflict case.
- Actor-level rule-over-transaction priority can suppress the covered
  transaction assignment in the current lowerable direction.
- Priority-arbitrated `rule_slot` resources can suppress a whole lower-priority
  rule DT by gating its DTE.
- Rule/drive same-target overlap is reported as
  `isf_unproven_rule_drive_overlap` with `proof_status => not_doable` because
  the current analysis does not prove that overlap statically.
- Rule trigger pulses are request-domain sources. Multiple rules triggering
  the same transaction are resolved by generated OR fan-in, not by data
  conflict arbitration.

## ISF-RULE-ACTIONS.2 Specification

This specification defines the first expression-valued rule assignment slice.
It intentionally widens only the RHS of ordinary rule data assignments.

### Source Shape

Accepted forms:

```lisp
(rule drive_status ready
  (valid 1)
  (status (| req_valid error_seen))
  (next_count (+ count 1)))
```

- The assignment action keeps the existing two-item shape: `(target expr)`.
- `target` must be a non-empty scalar action head and must not be the reserved
  rule action heads `trigger` or `priority`.
- `expr` may be one scalar token or one non-empty list expression.
- A list expression is one `.fsm` RHS expression tree. Its head must be a
  scalar expression operator or callable token, and its operands may be scalar
  leaves or nested expression lists.
- Expression-valued rule assignments do not add new rule action keywords.

### Expression Domain

The initial implementation should share the same RHS expression domain as
transaction `(update var expr)` and the `.fsm` value expression slot:

- scalar literals and signal references
- named constants, enum values, and parameter/generic values visible to the
  scheduled `.fsm`
- indexed and sliced references accepted by `.fsm`
- unary `!`
- n-ary arithmetic/bitwise/logical forms such as `+`, `-`, `*`, `/`, `%`,
  `&`, `|`, `^`, `!&`, `!|`, and `!^`
- word aliases such as `not`, `eq`, `ne`, `lt`, `le`, `gt`, `ge`, `add`,
  `sub`, `mul`, `div`, `mod`, `and`, `nand`, `or`, `nor`, `xor`, and `xnor`
- RHS pack expressions such as `(concat ...)` and `(cat ...)`

The rule lowerer should preserve the RHS as structured expression data until
the scheduled `.fsm` emitter formats it. The generated `.fsm` must still pass
through the normal `.fsm` parser and HDL generation path; expression support
must not be a raw-text bypass around existing expression validation.

### Symbol Visibility

Expression names are interpreted in the generated scheduled `.fsm` module
scope. The visible set is the same practical set available to transaction
`update` RHS expressions:

- actor interface inputs and outputs
- generated start/done, trigger-source, counter, and helper storage declared
  in the scheduled `.fsm`
- values captured by `sample`, `extract`, `assemble`, and other data-operation
  paths when those names are present in the scheduled module
- imported constants, enum values, parameters, and generic values that the
  scheduled `.fsm` frontend already accepts

The rule parser should validate expression shape. Unknown or unresolvable
symbols should fail through the normal scheduled `.fsm`/HDL validation path
unless a narrower symbol table is added in the implementation slice.

### Assignment Family And Guard Interaction

- Expression-valued rule assignments remain ordinary rule data assignments.
- They lower with `op => '<-'` and `source_kind => 'rule_action'`, the same as
  scalar `(port value)` actions today.
- The LHS keeps the existing output handling: if `target` names an actor
  output, scheduled `.fsm` emission uses the existing output LHS token form.
- The rule guard remains the non-state DT DTE. The expression is selected when
  that rule DTE is active.
- Priority/resource suppression composes as assignment or DTE guards exactly
  as it does for scalar rule assignments. Suppression never rewrites the RHS
  expression itself.
- This slice does not introduce combinational `=` rule actions, D-input-named
  `<=` rule actions, or delayed-pulse `<1` rule data assignments.

### Width Rules

- No broad new ISF width-inference engine is part of this tree.
- Width behavior follows the existing `.fsm` expression and assignment rules.
  Authors should declare widths with the existing interface/`+size` surfaces
  or use exact-width literals when the expression would otherwise be
  ambiguous.
- Exact-width and based literals remain the preferred way to disambiguate RHS
  expression width.
- A width problem discovered by scheduled `.fsm` parsing, AST normalization,
  or HDL generation is a valid fail-closed outcome for this first slice.
- Aggregate/record growth and backend-owned struct emission remain outside
  this task tree.

### Rejected Cases

- `(target)` with no RHS remains rejected.
- `(target expr extra)` remains rejected.
- `((target) expr)` remains rejected because the LHS must be scalar.
- `(target ())` is rejected because the RHS expression list is empty.
- `(target ((op) a b))` is rejected because expression heads must be scalar.
- `(trigger expr)` remains the trigger action and must keep the exact
  `(trigger transaction)` shape.
- `(priority expr)` remains the priority action and must keep the exact
  `(priority over other_rule)` shape.
- Expression-valued rule guards are not part of this slice; rule guards stay
  scalar until a separate guard-expression contract is accepted.
- Control-flow forms such as `when`, `switch`, `repeat`, `do`, `spawn`, and
  `complete` are not RHS expressions.

## ISF-RULE-ACTIONS.3 Implementation

This slice ships expression-valued RHS support for ordinary rule assignments.

### Parser And Lowering

- Rule assignment actions now accept `(port expr)` where `expr` is either a
  scalar token or a non-empty list expression.
- The parser validates expression-list shape recursively: expression heads
  must be scalar, and ISF control-flow heads such as `when`, `switch`,
  `repeat`, `do`, `spawn`, and `complete` are rejected as RHS expressions.
- Missing RHS values and extra assignment operands continue to fail closed
  with the targeted rule-action diagnostic.
- The scheduler formats rule assignment RHS values through the same ISF
  expression formatter used by transaction `(update var expr)`.
- Rule expression assignments keep `op => '<-'` and
  `source_kind => 'rule_action'`; they remain ordinary data-domain rule
  assignments.

### Regression Evidence

- [t/1181-isf-rule-action-boundary.t](../../t/1181-isf-rule-action-boundary.t)
  now covers accepted expression-valued rule actions plus malformed expression
  boundaries.
- [t/1221-isf-rule-expression-assignment.t](../../t/1221-isf-rule-expression-assignment.t)
  covers scheduled `.fsm` expression emission, separate rule-trigger fan-in,
  assignment provenance, normal `.fsm` frontend parsing, and HDL generation.
- [t/1144-isf-public-tested-by-metadata-audit.t](../../t/1144-isf-public-tested-by-metadata-audit.t)
  includes the new regression in ISF public contract provenance.

## Decisions

- `2026-05-14`: Rule action widening is tracked independently from legacy
  transaction `assign` compatibility so the supported rule surface can move
  without reviving removed syntax accidentally.
- `2026-05-14`: The inventory confirms that the current widening point is the
  scalar RHS of `(port value)`. Rule guards, trigger targets, and priority
  targets are also scalar-only today, but this tree focuses first on
  expression-valued assignment RHS lowering.
- `2026-05-14`: Expression-valued rule assignments will share the transaction
  `update`/`.fsm` RHS expression domain and keep the existing flopped `<-`
  rule assignment family. Guard expressions, alternate rule assignment
  operators, and broad new width inference are deferred.
- `2026-05-14`: The implementation uses the existing transaction-update
  expression formatter for rule RHS values, so this slice changes the rule
  action parser/lowerer boundary without adding a second expression language.

## Open Questions

- Whether rule guards should later accept full expression syntax remains a
  separate future feature question.
- Whether rule actions should later expose explicit assignment operators such
  as combinational `=` or D-input-named `<=` remains a separate future feature
  question.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-14` | `ISF-RULE-ACTIONS` | `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RULE-ACTIONS.1` | `prove -l t/1168-isf-rule-guard-factoring.t t/1169-isf-rule-shorthand-guard.t t/1171-isf-rule-trigger-fanin.t t/1172-isf-rule-trigger-fanin-schedule-report.t t/1181-isf-rule-action-boundary.t t/1190-isf-rule-priority-target-boundary.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RULE-ACTIONS.2` | `prove -l t/1168-isf-rule-guard-factoring.t t/1169-isf-rule-shorthand-guard.t t/1171-isf-rule-trigger-fanin.t t/1172-isf-rule-trigger-fanin-schedule-report.t t/1181-isf-rule-action-boundary.t t/1198-isf-update-clause-boundary.t t/1209-isf-static-conflict-detection.t t/1210-isf-priority-conflict-resolution.t`; `mdbook build docs/book`; `git diff --check` | `passed` |
| `2026-05-14` | `ISF-RULE-ACTIONS.3` | `perl -I perl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -I perl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`; `prove -l t/1144-isf-public-tested-by-metadata-audit.t t/1181-isf-rule-action-boundary.t t/1198-isf-update-clause-boundary.t t/1221-isf-rule-expression-assignment.t`; `./bin/ci-regression isf --no-book`; `mdbook build docs/book`; `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-RULE-ACTIONS` | `R14: map ISF objectives to task trees` | Initial tree creation belongs to the ISF objective task-tree coverage slice. |
| `ISF-RULE-ACTIONS.1` | `ISF-RULE-ACTIONS.1: inventory rule action behavior` | Current scalar-only boundary and report/conflict touchpoints inventoried. |
| `ISF-RULE-ACTIONS.2` | `ISF-RULE-ACTIONS.2: specify rule expression assignments` | Expression RHS semantics specified before implementation. |
| `ISF-RULE-ACTIONS.3` | `ISF-RULE-ACTIONS.3: implement rule expression assignments` | Parser/lowerer support and focused regression landed. |

## Changelog

- `2026-05-14`: Completed `ISF-RULE-ACTIONS.1` by inventorying current rule
  action parser, lowering, schedule-report, storage, and conflict behavior.
- `2026-05-14`: Completed `ISF-RULE-ACTIONS.2` by specifying expression-valued
  rule assignment syntax, expression domain, symbol visibility, width policy,
  guard interaction, assignment family, and rejected cases.
- `2026-05-14`: Completed `ISF-RULE-ACTIONS.3` by implementing
  expression-valued rule assignment parsing/lowering and adding focused
  parser/lowering/HDL coverage.
- `2026-05-14`: Created the active ISF rule-action task tree.
