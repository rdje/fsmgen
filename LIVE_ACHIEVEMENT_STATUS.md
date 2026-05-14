# LIVE_ACHIEVEMENT_STATUS

This file tracks the latest completed roadmap-aligned slice for fast recovery.

## 2026-05-14: Architecture backlog — IR audit task tree
- Proposed [docs/tasks/FSMGEN-IR-AUDIT.md](docs/tasks/FSMGEN-IR-AUDIT.md) to
  track a future inventory and consolidation audit for FSMGen IR structures.
- The tree records the current architecture concern without making IR
  consolidation the active PNT lane ahead of `R14` ISF feature work.
- [docs/TASK_TREE.md](docs/TASK_TREE.md), [README.md](README.md),
  [ROADMAP_STATUS.md](ROADMAP_STATUS.md), [CHANGES.md](CHANGES.md),
  [DEVELOPMENT_NOTES.md](DEVELOPMENT_NOTES.md), and [MEMORY.md](MEMORY.md)
  point to the proposed tree.

## 2026-05-14: R14 — ISF spawn parameter binding
- Active R14 task-tree slice: `ISF-COMPOSITION.3` is complete.
- Spawn parameter declarations and per-instance overrides now validate before
  scheduled `.fsm` emission; spawned child `.fsm` files carry default
  `+params`, and parent lowerer metadata preserves override lists for the
  generated-top handoff.
- The next frontier is `ISF-COMPOSITION.4`.

## 2026-05-14: R14 — ISF composition public semantics
- Active R14 task-tree slice: `ISF-COMPOSITION.2` is complete.
- The accepted target contract now covers generated-top ownership, parent/child
  start-done wiring, spawned-child re-entry, spawn instance identity, and
  spawn-only `(params ...)` overrides.
- The next frontier is `ISF-COMPOSITION.3`.

## 2026-05-14: R14 — ISF composition handoff inventory
- Active R14 task-tree slice: `ISF-COMPOSITION.1` is complete.
- Current ISF spawn lowering emits parent/child scheduled `.fsm` files but no
  generated top; parent start signals are internal and schedule reports are
  parent-scoped.
- At the time of this inventory slice, the next frontier was
  `ISF-COMPOSITION.2`.

## 2026-05-14: R14 — ISF conflict tree closure
- Active R14 task-tree slice: `ISF-CONFLICTS.7` is complete.
- The `ISF-CONFLICTS` task tree is closed and now appears in the completed
  task-tree table.
- At the time of that closure, the next active R14 frontier was
  `ISF-COMPOSITION.1`.

## 2026-05-14: R14 — ISF conflict regression coverage
- Active R14 task-tree slice: `ISF-CONFLICTS.6` is complete.
- Existing focused tests now cover nonfatal compile issues, compatible fan-in
  groups, rejected diagnostics, and realistic APB done-pulse fan-in.
- The next frontier is `ISF-CONFLICTS.7`.

## 2026-05-14: R14 — ISF rejected conflict diagnostics
- Active R14 task-tree slice: `ISF-CONFLICTS.5.4` is complete.
- In-process scheduler calls and CLI schedule-report generation now have
  regression coverage for fail-closed rejected conflict diagnostics.
- The `ISF-CONFLICTS.5` diagnostics/report projection container is complete.
- The next frontier is `ISF-CONFLICTS.6`.

## 2026-05-14: R14 — ISF fan-in group projection
- Active R14 task-tree slice: `ISF-CONFLICTS.5.3` is complete.
- Schedule reports now include `compatible_fanin_groups` with bounded summaries
  for accepted compatible fan-in cases.
- The next frontier is `ISF-CONFLICTS.5.4`.

## 2026-05-14: R14 — ISF compile issues projection
- Active R14 task-tree slice: `ISF-CONFLICTS.5.2` is complete.
- Schedule-report `compile_issues` now carries warning-level conflict issues
  using bounded issue/source summaries.
- Fail-closed errors still stop lowering through targeted diagnostics; this
  slice only projects nonfatal issues in successful reports.
- The next frontier is `ISF-CONFLICTS.5.3`.

## 2026-05-14: R14 — ISF conflict report projection schema
- Active R14 task-tree slice: `ISF-CONFLICTS.5.1` is complete.
- The bounded schedule-report projection boundary is documented for later
  nonfatal `compile_issues` entries and compatible fan-in group summaries.
- The current implementation still emits successful reports with empty
  `compile_issues` and no `compatible_fanin_groups`; those emitter changes are
  the next leaves.
- The next frontier is `ISF-CONFLICTS.5.2`.

## 2026-05-14: R14 — ISF diagnostics projection split
- Active R14 task-tree slice: `ISF-CONFLICTS.5` is split into executable
  leaves.
- New leaves cover bounded schedule-report schema definition, nonfatal
  `compile_issues` projection, compatible fan-in projection, and
  rejected-conflict diagnostic closure.
- The next frontier is `ISF-CONFLICTS.5.1`.

## 2026-05-14: R14 — ISF runtime selector conflict instrumentation
- Active R14 task-tree slice: `ISF-CONFLICTS.4.5` is complete.
- Generated SystemVerilog now emits verification-only `$onehot0` selector
  assertions for same-value source selector conflicts and whole-mux value
  selector conflicts after ISF lowers through scheduled `.fsm`.
- Lowered RTL metadata now exposes `selector_conflict_targets` from backend
  assignment analysis; Verilog remains assertion-free and standalone DT roots
  keep the existing standalone-DT assertion path.
- The next frontier is `ISF-CONFLICTS.5`.

## 2026-05-14: R14 — ISF rule priority conflict resolution
- Active R14 task-tree slice: `ISF-CONFLICTS.4.4` is complete.
- Rule-local and actor-level rule priorities now resolve same-target rule/rule
  data conflicts by guarding the lower-priority assignment with the inverse
  higher-priority rule condition.
- Priority cycles fail closed; incomparable rule/rule conflicts remain
  rejected. Public schedule-report JSON is unchanged.
- The next frontier is `ISF-CONFLICTS.4.5`.

## 2026-05-14: R14 — ISF static conflict checks
- Active R14 task-tree slice: `ISF-CONFLICTS.4.3` is complete.
- `LoweringIR` now derives internal `conflict_issues` from assignment
  provenance.
- Provable rule/rule same-target data conflicts now fail closed, while
  rule/drive overlap is flagged as `not_doable` because this compile-time
  proof is not doable in the current analysis.
- Public schedule-report JSON is unchanged. The next frontier is
  `ISF-CONFLICTS.4.4`.

## 2026-05-14: R14 — ISF compatible fan-in classification
- Active R14 task-tree slice: `ISF-CONFLICTS.4.2` is complete.
- `LoweringIR` now derives internal `compatible_fanin_groups` from assignment
  provenance for same-value selector groups, request fan-in, pulse fan-in, and
  rule-trigger fan-in.
- Public schedule-report JSON is unchanged. The next frontier is
  `ISF-CONFLICTS.4.3`.

## 2026-05-14: R14 — ISF assignment provenance inventory
- Active R14 task-tree slice: `ISF-CONFLICTS.4.1` is complete.
- `LoweringIR` now carries internal assignment provenance records before
  scheduled `.fsm` emission, with source ownership, target/operator/RHS,
  domain hint, and activation context.
- Compile-time conflict detection is now explicitly best-effort: unprovable
  cases must be flagged, and runtime mux-selector conflict checks are tracked
  as a later verification-only leaf.
- The public schedule report is unchanged; projection remains deferred to the
  diagnostics/report leaf. This slice moved the tree to `ISF-CONFLICTS.4.2`;
  the current frontier is recorded in the latest R14 task-tree entry above.

## 2026-05-14: R14 — ISF conflict tracking implementation split
- Active R14 task-tree slice: `ISF-CONFLICTS.4` is now an active implementation
  container with executable subleaves.
- This slice moved the tree to `ISF-CONFLICTS.4.1`; the current frontier is
  recorded in the latest R14 task-tree entry above.
- Later subleaves cover compatible fan-in classification, unprioritized
  conflict detection, target-local priority resolution, and runtime selector
  conflict instrumentation for verification builds.

## 2026-05-14: R14 — ISF fail-closed conflict policy
- Active R14 task-tree slice: `ISF-CONFLICTS.3` is complete in
  [docs/tasks/ISF-CONFLICT-RESOLUTION.md](docs/tasks/ISF-CONFLICT-RESOLUTION.md).
- Incompatible same-target sources now have documented policy: prove mutual
  exclusion, use compatible fan-in, select one unique priority winner, or fail
  closed with targeted diagnostics.
- This slice moved the tree to `ISF-CONFLICTS.4`; the current frontier is
  recorded in the latest R14 task-tree entry above.

## 2026-05-14: R14 — ISF compatible fan-in policy
- Active R14 task-tree slice: `ISF-CONFLICTS.2` is complete in
  [docs/tasks/ISF-CONFLICT-RESOLUTION.md](docs/tasks/ISF-CONFLICT-RESOLUTION.md).
- Compatible fan-in is now specified for same target/value selector ORs,
  request/event ORs, pulse-class `<1 target 1` ORs, and the existing
  rule-trigger fan-in shape.
- This slice moved the tree to `ISF-CONFLICTS.3`; the current frontier is
  recorded in the latest R14 task-tree entry above.

## 2026-05-14: R14 — ISF conflict-domain inventory
- Active R14 task-tree slice: `ISF-CONFLICTS.1` is complete in
  [docs/tasks/ISF-CONFLICT-RESOLUTION.md](docs/tasks/ISF-CONFLICT-RESOLUTION.md).
- The current scheduler baseline now has a documented inventory: rule-trigger
  fan-in is the only deliberate compatible same-target merge path, and other
  same-target assignment families still need explicit policy/diagnostics.
- This slice moved the tree to `ISF-CONFLICTS.2`; the current frontier is
  recorded in the latest R14 task-tree entry above.

## 2026-05-14: R14 — ISF objective task-tree coverage
- Active R14 tracking slice: all currently documented ongoing/unresolved ISF
  objective families now have active task trees and current-frontier leaves
  under `docs/tasks/`.
- `ISF-CONFLICTS` was the first active tree because same-cycle conflict
  semantics informed the resource/priority and rule-action objectives.
- Additional trees now cover composition/spawn, resource/priority, rule
  actions, stages/contracts, data widths, schedule reports, fixtures,
  compatibility, and public contract synchronization.

## 2026-05-14: Workflow — task-tree adoption guide
- Active workflow docs slice: [docs/TASK_TREE_README.md](docs/TASK_TREE_README.md)
  now provides a direct setup guide for using the same task-tree tracking
  approach in another project.
- The guide covers the minimum required files, recommended full integration,
  roadmap/status relationship, commit and bootstrap hooks, first-tree creation,
  operating rules, completion evidence, and setup checklist.

## 2026-05-14: R14 — ISF task-tree requirement
- Active R14 workflow rule: every ISF task, slice, or PNT-selected activity
  must be sliced and logged in a task tree before implementation.
- Existing ISF trees should be reused when they own the topic; otherwise create
  a new `docs/tasks/*.md` tree from [docs/tasks/TEMPLATE.md](docs/tasks/TEMPLATE.md).
- This applies to implementation, diagnostics, fixtures, contracts, and
  documentation-only ISF changes.

## 2026-05-14: Workflow — repo-local task tree formalization
- Active workflow slice: broad tasks can now be tracked as repo-local task
  trees with stable node IDs, current-frontier leaf selection, blocker rules,
  validation evidence, and commit-subject traceability.
- [docs/TASK_TREE.md](docs/TASK_TREE.md) owns the workflow and active-tree
  index; [docs/tasks/TEMPLATE.md](docs/tasks/TEMPLATE.md) is the reusable
  top-level task template.
- [docs/tasks/ISF-CONFLICT-RESOLUTION.md](docs/tasks/ISF-CONFLICT-RESOLUTION.md)
  was created as the first active tree and originally set `ISF-CONFLICTS.1` as
  the first frontier leaf for ISF same-cycle conflict-semantics work.

## 2026-05-14: Book — feature backlog consolidation
- Active docs slice: not-fully-shipped, deferred, future-work, and not-yet
  frozen user-visible items now have one mdBook home:
  [docs/book/src/14-feature-backlog.md](docs/book/src/14-feature-backlog.md).
- [docs/FEATURE_BACKLOG.md](docs/FEATURE_BACKLOG.md) is the repo-level pointer
  to that canonical book chapter.
- Local caveat sections now point to the backlog, and future caveats of this
  kind should update the backlog at the same time.

## 2026-05-14: R14 — feature-first ISF focus
- Active roadmap direction changed: R14 should now prioritize public-facing
  ISF feature additions over standalone public-interface stabilization work.
- ISF public-interface docs and manifest metadata remain live, but they should
  be updated as part of feature slices rather than selected as standalone audit
  expansion work.
- Next PNT work should prefer documented ISF feature limitations and realistic
  fixture coverage.

## 2026-05-14: R8 — DTE guard factorization path
- Active language/HDL contract slice: lowered DTE header guards now flow
  through the same AST factorization, substitution, liveness, and rendering
  path as ordinary enable expressions.
- Generated `.sv` can share repeated header-guard predicates, for example one
  `mode_eq_const_3` helper reused by multiple state `*_en` assignments.
- Focused tests now lock both the shared generated HDL shape and the
  `top_state_enable:*` / `top_dt_enable:*` factorization contexts.

## 2026-05-14: R8 — State DT DTE header activation
- Active language-contract slice: regular state DTs now accept optional DTE
  header activation guards, using the same guard grammar as non-state DTs.
- Generated `.sv` lowers a guarded state DT enable as
  `(current_state == STATE) | lowered(header_guard)`, then applies that DTE at
  the DT-specific output-enable boundary.
- The book now documents that this is whole-DT activation: assignments, tests,
  and transitions inside the state DT participate when the header activation is
  true.
- Non-state DTs use the same header-activation surface everywhere they are
  accepted; DT activation is not an async reset-tree glue mechanism.

## 2026-05-14: R14/R8 — Guarded non-state DT DTE headers
- Active language/ISF contract slice: `.fsm` non-state DTs now accept optional
  DTE guards in the header, using the existing guard grammar.
- Generated `.sv` now emits guarded non-state DT top-level enables such as
  `route_en = req != 0` or `expr_guard_en = intermediate_and_req_ready_1`,
  then applies those DTEs at the DT-specific output-enable boundary.
- ISF rule guards now lower as rule DT DTE headers, for example
  `(-always_ready <ready ...)`, instead of nested guard blocks around rule
  actions.
- The mdBook, ISF spec, public-interface contract, manifest metadata, and
  focused tests are aligned to the new surface.

## 2026-05-14: R8 — State DTE boundary-gated output enables
- Active language/HDL contract slice: state-DT selector predicates remain
  factorizable without state decode, and the state DTE gates each emitted
  DT-specific output EN at the boundary.
- Generated `.sv` now keeps paths like `state_lhs_value_en = state_en &
  selector_predicate`, making the DTE-to-EN path the final gate.
- The book/live docs now state the full enable hierarchy: route OR inside each
  state DT, DTE gate at the state-DT boundary, FSM-level OR per `LHS`/`VAL`,
  then the target mux selector.

## 2026-05-14: R8 — Clock tick and cycle timing model
- Active language-contract docs slice: the mdBook now defines clock ticks,
  cycles, `N-`/`N+`, and the stable-`Q` interval between consecutive ticks.
- The new wording grounds `<-` and `<=` assignment timing in edge-triggered
  flop behavior before the book introduces detailed pair-form examples.

## 2026-05-14: R8 — Preferred `<=-` dual D-input operator
- Active language-contract slice: `<=-` is now the preferred D-input-named
  dual-output assignment operator, mirroring `<-=` and exposing `<LHS>_r`.
- Legacy `<=+` remains accepted as a compatibility alias and is still covered
  by regression tests.

## 2026-05-14: R14/R8 — DT selector model and await watchdog lowering
- Active: `R14`, with `.fsm` language-contract documentation touchpoints.
  The book now defines DTs as combinational selector logic with conceptual
  `DTE` gating and target mux semantics.
- ISF await watchdog lowering now emits `?wd (=0 timeout) (>0 (-- wd))`, so
  the scheduled `.fsm` review form does not suggest that decrement executes
  before the zero test.

## 2026-05-13: R14 — ISF when clause boundary
- Active: `R14`. `(when condition body...)` now requires a scalar or list-form
  condition and at least one list-form body clause before scheduled `.fsm`
  emission.
- `t/1206` covers scalar and expression conditions plus missing condition,
  missing body, scalar body, and nested scalar body malformed forms.

## 2026-05-13: R14 — ISF switch clause boundary
- Active: `R14`. `(switch signal (value body...)...)` now requires a scalar
  signal and one or more list-form branches before scheduled `.fsm` emission.
- `t/1205` covers valid explicit/default branch lowering plus malformed switch
  signal, branch, value, and body forms.

## 2026-05-13: R14 — ISF child composition clause boundary
- Active: `R14`. `(do transaction)` and `(spawn transaction as instance)` now
  require exact scalar child/instance operands before scheduled `.fsm`
  emission.
- `t/1204` covers valid child handshake lowering plus malformed `do` and
  `spawn` forms.

## 2026-05-13: R14 — ISF await sync clause boundary
- Active: `R14`. `(await_all done_port)` and `(await_any done_port)` now require
  exactly one scalar done-port operand before scheduled `.fsm` emission.
- `t/1203` covers valid sync-state lowering plus missing, nested, and
  extra-operand malformed forms.

## 2026-05-13: R14 — ISF repeat clause boundary
- Active: `R14`. `(repeat count body...)` now requires a scalar non-empty count
  and at least one body clause before scheduled `.fsm` emission.
- `t/1202` covers valid counter/body/check lowering plus missing count, missing
  body, nested count, and scalar body malformed forms.

## 2026-05-13: Workflow — quick smoke regression alias
- Active support workflow: `bin/ci-regression smoke` now aliases the curated
  `quick` tier for fast basic-functionality checks across direct `.fsm`,
  composition, and ISF basics.
- `t/1183` covers the alias dry run, shared quick test list, and `--no-book`
  behavior.

## 2026-05-13: R14 — ISF extract clause boundary
- Active: `R14`. `(extract word as field... [(widths N...)])` now requires a
  scalar source word and scalar destination fields before scheduled `.fsm`
  emission.
- `t/1201` covers valid explicit-width slice lowering plus nested word, nested
  field, unknown option, and field-after-widths malformed forms.

## 2026-05-13: R14 — ISF assemble clause boundary
- Active: `R14`. `(assemble part... as target)` now requires one or more
  scalar parts and one scalar target before scheduled `.fsm` emission.
- `t/1200` covers valid concat lowering plus missing-part, missing-`as`,
  nested-part, nested-target, and extra-operand malformed forms.

## 2026-05-13: Workflow — ISF regression tier 12xx readiness
- Active support workflow: `bin/ci-regression isf` now includes the future
  `t/12xx-isf*.t` numbered band while preserving the existing 109x/11xx bands.
- `t/1183` now checks both the latest visible ISF test and the 12xx/nullglob
  selector boundary.

## 2026-05-13: R14 — ISF shift clause boundary
- Active: `R14`. `shift_left` and `shift_right` now require scalar register and
  bit operands before scheduled `.fsm` emission.
- `t/1199` covers valid left/right shift lowering plus missing, nested, and
  extra malformed operand rejection.

## 2026-05-13: R14 — ISF update clause boundary
- Active: `R14`. `(update var expr)` now requires one scalar target and one
  scalar or list expression payload before scheduled `.fsm` emission.
- `t/1198` covers scalar and nested-expression update lowering plus missing
  RHS, nested target, extra operand, and nested-body malformed update
  rejection.

## 2026-05-13: R14 — ISF latency clause boundary
- Active: `R14`. Transaction `(latency ...)` clauses now validate `(min N)`
  and `(max N)` as unique positive-integer options before latency counter
  emission, and valid `max` bounds now drive the latency counter width/max
  check.
- `t/1197` covers valid counter support plus empty clauses, unknown options,
  non-integer values, duplicate options, and `min > max`.

## 2026-05-13: R14 — ISF complete clause boundary
- Active: `R14`. `(complete port)` now requires exactly one scalar completion
  target before scheduled `.fsm` emission.
- `t/1196` covers valid delayed-pulse terminal lowering plus missing, nested,
  extra-operand, and nested-body malformed complete clauses.

## 2026-05-13: R14 — ISF sample clause boundary
- Active: `R14`. Standalone samples and `(on ...)` inline samples now require
  exact `(sample port as name)` shape with scalar source and target names
  before scheduled `.fsm` emission.
- `t/1195` covers guarded entry samples, piggybacked standalone samples,
  malformed sample shapes, nested `(on ...)` guards, and unsupported `(on ...)`
  body forms.

## 2026-05-13: R14 — ISF drive body parser boundary
- Active: `R14`. Drive definition body entries now fail malformed shapes before
  parser actor-shell return; accepted entries are scalar `(port value)` pairs.
- `t/1194` covers valid shell/lowering behavior plus scalar body entries,
  nested ports, missing values, extra operands, and expression-valued drive
  body assignments.

## 2026-05-13: R14 — ISF drive call arity boundary
- Active: `R14`. Known ISF drive calls now require exact positional arity
  during lowering: declared parameter count and actual count must match.
- `t/1193` covers valid parameter binding plus missing actuals, extra actuals,
  extra actuals on simple drives, and nested extra actual rejection through the
  shared named-drive-call lowerer.

## 2026-05-13: R14 — ISF singleton actor clause boundary
- Active: `R14`. Repeated actor-shell singleton clauses now fail before parser
  actor-shell return. The singleton set is `(clock ...)`, `(reset ...)`,
  `(watchdog ...)`, `(interface ...)`, and `(resources ...)`.
- `t/1192` covers valid singleton field preservation plus duplicate rejection
  for each singleton clause, preventing silent overwrite of public timing,
  interface, and resource metadata.

## 2026-05-13: R14 — ISF actor priority target boundary
- Active: `R14`. Actor-level `(priority lhs over rhs)` metadata now requires
  both sides to resolve to declared same-actor transactions or rules before
  parser actor-shell return.
- `t/1191` covers valid forward references plus unknown lhs/rhs target
  rejection. Arbitration enforcement still remains deferred.

## 2026-05-13: R14 — ISF rule priority target boundary
- Active: `R14`. Rule-local `(priority over other_rule)` metadata now requires
  `other_rule` to resolve to a declared rule in the same actor before parser
  actor-shell return.
- `t/1190` covers valid forward references plus unknown priority-target
  rejection. Priority enforcement still remains deferred.

## 2026-05-13: R14 — ISF drive parameter boundary
- Active: `R14`. Parameterized drive declarations now require unique scalar
  parameter names before parser actor-shell return.
- `t/1189` covers valid parameter preservation plus duplicate and nested
  parameter rejection. This prevents one positional drive-call argument slot
  from ambiguously sharing a local parameter name with another slot.

## 2026-05-13: R14 — ISF interface port boundary
- Active: `R14`. Interface port names are now parser-validated as unique
  non-empty scalars across both input and output directions.
- `t/1188` covers distinct input/output shells plus duplicate same-direction
  and cross-direction port rejection before actor-shell return.

## 2026-05-13: R14 — ISF drive name boundary
- Active: `R14`. Duplicate `(drive name ...)` definitions are now rejected
  before actor-shell return instead of overwriting an earlier drive body in
  the drive-name-keyed hash.
- `t/1187` covers distinct drive-map entries and duplicate-drive rejection.
  The public drive shell remains hash-backed, but each drive key is now an
  explicit unique non-empty name.

## 2026-05-13: R14 — ISF rule name boundary
- Active: `R14`. Rule names are now parser-validated as non-empty scalars that
  are unique within the actor.
- `t/1186` covers valid distinct rule names and duplicate-name rejection before
  actor-shell return. This keeps generated rule DTs and trigger-source prefixes
  unambiguous.

## 2026-05-13: R14 — ISF transaction name boundary
- Active: `R14`. Transaction names are now parser-validated as non-empty
  scalars that are unique within the actor.
- `t/1185` covers valid distinct transaction names and duplicate-name
  rejection before actor-shell return. This keeps rule/child target
  resolution and generated state/DT names unambiguous.

## 2026-05-13: R14 — ISF child transaction target boundary
- Active: `R14`. `(do child)` and `(spawn child as instance)` lowering now
  requires `child` to be a declared transaction in the same actor before
  scheduled `.fsm` emission.
- `t/1184` covers valid forward references plus unknown `do` and `spawn`
  targets. Missing child references now fail closed instead of producing dead
  start/done handshake signals.

## 2026-05-13: Workflow — tiered local regression gate
- Active support workflow: `bin/ci-regression` now has explicit `quick`, `isf`,
  and `full` modes, with no argument still running the historical full gate.
- `t/1183` covers `--list`, dry-run command selection, `--no-book`, and
  unknown-mode diagnostics. The quick tier is a smoke set for fast feedback,
  not a replacement for focused tests or the full pre-push gate.

## 2026-05-13: R14 — ISF rule trigger target boundary
- Active: `R14`. Rule `(trigger transaction)` actions now require the target
  transaction to be declared in the same actor before parser handoff returns.
- `t/1182` covers valid forward references plus unknown-target rejection with
  a diagnostic naming the rule, target, and actor. This prevents misspelled
  triggers from synthesizing unowned `transaction_start` fan-in paths.

## 2026-05-13: R14 — ISF rule action parser boundary
- Active: `R14`. Rule actions now fail malformed shapes at parse time before
  actor-shell return. Accepted actions are `(port value)`,
  `(trigger transaction)`, and `(priority over other_rule)`.
- `t/1181` covers the accepted rule action shell and malformed scalar,
  nested-head, trigger-arity, missing-value, and expression-valued assignment
  cases. Expression-valued rule assignment remains deferred.

## 2026-05-13: R14 — ISF unsupported transaction clauses fail closed
- Active: `R14`. Unsupported ISF transaction clause heads now fail closed
  before lowering instead of being silently ignored, including the removed
  `(assign ...)` keyword and unsupported nested body forms.
- `t/1180` covers top-level and nested unsupported clauses across
  transaction, `when`, `switch`, and `repeat` contexts, while keeping the
  specific deferred `contract` and `stage` diagnostics intact.

## 2026-05-13: R14 — ISF phase/stage boundary
- Active: `R14`. Actor-level phase/stage metadata and transaction
  phase/stage clauses now share a parser-enforced scalar-name plus list-body
  structural boundary.
- `t/1179` covers carried actor-level metadata, pass-through transaction
  phase lowering, transaction stage fail-closed lowering, and malformed
  phase/stage shape rejection. Full transaction stage pipeline lowering
  remains deferred.

## 2026-05-13: R14 — ISF handshake compatibility boundary
- Active: `R14`. Deprecated `(handshake name (valid signal) (ready signal))`
  metadata is now parser-validated before being ignored.
- `t/1178` covers the accepted compatibility shape plus malformed names,
  missing properties, unsupported keys, duplicate properties, and nested signal
  values. Old handshake semantics remain deferred.

## 2026-05-13: R14 — ISF do-child done pulse
- Active: `R14`. Blocking `(do child)` now pulses the generated internal
  `child_done` handoff with `<1` instead of assigning it with sticky `<-`.
- `t/1177` proves the scheduled `.fsm` shape through normal `.fsm` parsing and
  HDL generation; the ISF spec, public-interface contract, and mdBook now
  explain why repeated child calls need a fresh completion pulse.
- Full-gate follow-up: `ExpressionNamer` wire declaration formatting now
  computes the MSB before interpolation, keeping `t/520` stable when query-map
  defensive-copy checks run inside the full suite.

## 2026-05-13: R14 — ISF resource/priority parser boundaries
- Active: `R14`. Resource and priority metadata now has parser-side structural
  validation before an actor shell is returned: supported resource arbiters,
  duplicate resource rejection, actor-level `(priority lhs over rhs)`, and
  rule-local `(priority over other_rule)`.
- `t/1176` covers the accepted full-featured fixture plus malformed resources
  and priorities. Arbitration enforcement remains deferred.

## 2026-05-13: R14 — ISF contract clauses fail closed
- Active: `R14`. Transaction `(contract ...)` temporal assertions still remain
  deferred, but authored contract clauses now fail closed during lowering
  instead of being silently dropped from scheduled `.fsm` output.
- `t/1175` covers top-level and nested contract clauses in `when`, `switch`,
  and `repeat` bodies; the ISF spec, public-interface contract, mdBook, and
  roadmap notes now document the boundary.

## 2026-05-13: R14 — ISF extract explicit field widths
- Active: `R14`. `extract` now accepts `(widths N...)` so authors can provide
  ordered field widths when they are not declared elsewhere, producing exact
  descending slices instead of placeholder `field HIGH/LOW` bounds.
- `t/1174` covers valid explicit-width extraction plus malformed count and
  declared-width conflict rejection; the ISF spec, public-interface contract,
  mdBook, and roadmap notes now describe the bounded option.

## 2026-05-13: R14 — ISF shift_right explicit width option
- Active: `R14`. `shift_right` now accepts `(width N)` so authors can provide
  the shifted register width when it is not declared elsewhere, producing a
  concrete inserted-MSB position instead of the placeholder `WIDTH` fallback.
- `t/1173` covers valid explicit-width lowering and malformed width rejection;
  the ISF spec, public-interface contract, mdBook, and roadmap notes now
  describe the bounded option.

## 2026-05-13: R14 — ISF rule trigger fan-in schedule report audit
- Active: `R14`. The schedule JSON report now has focused coverage for the
  shipped rule-trigger fan-in shape: rule DT order, `rule_trigger_fanin` kind,
  assignment counts, and one-bit inferred storage for generated trigger
  sources and `transaction_start`.
- The ISF public-interface contract tested_by metadata, ISF spec, and mdBook
  now advertise that downstream-facing report projection as regression-backed.

## 2026-05-13: R14 — ISF rule trigger fan-in implementation
- Active: `R14`. ISF rule `(trigger transaction)` lowering now preserves
  per-rule/per-transaction provenance by pulsing generated `rule_transaction`
  sources and driving `transaction_start` through a generated combinational
  fan-in DT.
- This closes the documented rule-trigger fan-in backlog item. `t/1171` covers
  multi-rule fan-in through scheduled `.fsm` parsing and HDL generation, while
  `t/1168` and `t/1169` now cover the single-source fan-in shape.

## 2026-05-13: R14 — close major guide migration status
- Active: `R14`. The USER_GUIDE-to-mdBook major-section migration is complete
  at the guide level: `docs/USER_GUIDE.md` is now a compact compatibility
  waypoint pointing at owning book chapters.
- Next PNT work should return to ISF implementation/API stabilization unless a
  concrete documentation drift issue is found.

## 2026-05-13: R14 — retire migrated user-guide front matter
- Active: `R14`. `docs/USER_GUIDE.md` sections 1-2.1 now point to owning
  mdBook chapters instead of carrying duplicated migrated core/direct/
  composition contract prose.
- The guide is now explicitly a compatibility waypoint and migration
  reference; the book is the normative user-facing surface.

## 2026-05-13: R14 — retire migrated user-guide tail
- Active: `R14`. `docs/USER_GUIDE.md` sections 3-10 now point to owning
  mdBook chapters instead of carrying duplicated migrated prose.
- The old guide remains a compatibility waypoint, while the book owns CLI,
  composition examples, typed extensions, troubleshooting, and practical
  authoring guidance.

## 2026-05-13: R14 — guide migration coverage map
- Active: `R14`. The mdBook reference map now records book homes for all major
  `docs/USER_GUIDE.md` section families and states that remaining work is
  duplication reduction and drift prevention.
- New normative user-facing wording should land in the owning book chapter
  first, with the old guide kept as a migration/compatibility reference.

## 2026-05-13: R14 — typed-extension guide-to-book migration
- Active: `R14`. Chapter 11 now explicitly states the typed-extension
  definition, non-goals, blessed-object/hook validation boundary, and
  CLI/config loading prerequisites from the old guide.
- No runtime behavior changed; this is a bounded USER_GUIDE-to-mdBook
  migration slice.

## 2026-05-13: R14 — authoring guidelines guide-to-book migration
- Active: `R14`. Chapter 02 now owns the practical authoring guidance for
  assignment-operator timing intent, delayed pulses, guard readability, and
  strict/check/trace bring-up.
- No runtime behavior changed; this is another bounded USER_GUIDE-to-mdBook
  migration slice.

## 2026-05-13: R14 — CLI/debug guide-to-book migration
- Active: `R14`. Chapter 09 now owns the guide's operational CLI contract:
  common commands, option semantics, report-only JSON modes, source
  resolution, and trace/debug behavior.
- No runtime behavior changed; this slice narrows the remaining user-guide
  migration work to deeper embedding/API and ISF material.

## 2026-05-13: R14 — book-owned diagnostic documentation hints
- Active: `R14`. Runtime parser/source diagnostics now use centralized
  book-owned documentation hints for supported-boundary, strict-mode, and
  package-boundary failures instead of pointing at `docs/USER_GUIDE.md`.
- The mdBook troubleshooting chapter and reference map now record that
  diagnostic hints should route users to the book while the old guide remains
  a migration reference.

## 2026-05-13: R14 — composition guide-to-book migration
- Active: `R14`. The mdBook composition chapters now carry the broad `?top`
  contract previously centralized in `docs/USER_GUIDE.md`, including root/body
  shape, port tokens, child source resolution, `.rtlif`, C1-C6 lane summary,
  structural actuals, concat operands, inferred internal carriers, and failure
  context.
- `docs/COMPOSITION_SCOPE.md` remains a focused maintainer-side scope map while
  user-facing composition rules continue moving into the book.

## 2026-05-13: R14 — direct .fsm guide-to-book migration
- Active: `R14`. The mdBook now carries the core direct `.fsm` contract that
  had still been centralized in `docs/USER_GUIDE.md`, including guard/suffix,
  selector/default, update-shorthand, root-kind, DT-kind, declaration-shape,
  CLI-report, and unsupported-syntax boundaries.
- The old guide now explicitly points back to the book migration rule: if the
  guide and book differ on contractual user-facing material, that is a
  documentation bug to reconcile, not a reason to leave the contract only in
  the guide.

## 2026-05-13: R14 — compact ISF await_all transition guard
- Active: `R14`. ISF `await_all` scheduled `.fsm` emission now uses one
  transition suffix guarded by the AND of all collected done ports, e.g.
  `(-> parent_done <(& w0_done w1_done w2_done))`, instead of nested guard
  blocks.
- The `.fsm` transition suffix parser now accepts explicit condition
  expression payloads such as `<(& a_done b_done c_done)`, and focused tests
  cover parser, scheduled `.fsm`, and HDL behavior.

## 2026-05-13: R14 — ISF when-form scope clarification
- Active: `R14`. The mdBook Control Flow chapter now makes clear that
  `(when condition body...)` is transaction-local control flow, not the
  rule-local guard form.
- The Rules chapter, ISF spec, and public-interface contract now state that
  rule `(when condition)` is guard-only and that `(rule name condition
  actions...)` remains the preferred shorthand.

## 2026-05-13: R14 — ISF rule trigger fan-in backlog
- Active: `R14`. This entry originally documented the direct-start limitation
  and the proposed fan-in design. The later `ISF rule trigger fan-in
  implementation` slice shipped that design.
- The retained contract is that each rule/transaction pair generates a
  distinct `rule_transaction` pulse source, then generated combinational fan-in
  drives `transaction_start` with no added cycle.

## 2026-05-13: R14 — ISF rule shorthand guard syntax
- Active: `R14`. ISF rules now accept `(rule name condition actions...)` as a
  shorthand for `(rule name (when condition) actions...)`, with both spellings
  normalized to the public actor-shell `when` field.
- `t/1169` covers parser normalization, duplicate guard diagnostics, scheduled
  `.fsm` emission, and HDL generation. The mdBook, ISF spec, public-interface
  contract, and `full_featured.isf` fixture now show the shorthand.

## 2026-05-13: R14 — ISF rule trigger pulse lowering
- Active: `R14`. ISF rule `(trigger transaction)` now lowers the generated
  `transaction_start` assignment with `<1`, making rule-driven transaction
  starts one-cycle delayed pulses instead of sticky flopped request bits.
- `t/1168` now locks the pulsed trigger shape inside the factored rule guard
  and still proves the scheduled `.fsm` parses through the ordinary frontend
  and reaches HDL generation.

## 2026-05-13: R14 — ISF rule guard factoring
- Active: `R14`. ISF rule DT emission now renders `(when ...)` once as a
  factored `.fsm` guard block around lowered actions, improving scheduled
  `.fsm` readability while preserving ordinary rule port-assignment
  behavior.
- `t/1168` covers the generated text shape and proves the factored block parses
  through the ordinary `.fsm` frontend and reaches HDL generation.

## 2026-05-13: R14 — .fsm default selector and ISF switch fallback
- Active: `R14`. `.fsm` test nodes now support `default` and `_` selectors
  that lower as `!(OR of explicit sibling predicates)`, and ISF switch
  fallthrough now emits that real `.fsm` default selector instead of a
  duplicated `=0` branch.
- Authored ISF `(default ...)`/`(_ ...)` switch branches own the fallback path,
  suppress implicit fallthrough, and are duplicate-checked together. Focused
  `.fsm`, ISF, capture-support, mdBook, and language-surface manifest checks
  cover the new contract.

## 2026-05-13: R14 — ISF complete pulse lowering and traced gate fixes
- Active: `R14`. `(complete port)` and timeout completion now lower to `<1`
  one-cycle delayed pulses; the ISF public contract, spec, mdBook, and
  schedule-report tests now advertise that pulse semantics and classify
  completion `done` as register-backed storage.
- Validation also fixed two full-gate blockers found during this slice:
  traced `next_state` transition captures now stay combinational instead of
  producing a 1-bit `next_state_next` flop helper, and explicit `.fsm`/`.isf`
  lookup names no longer get doubled during `--path`/`FSMLIB` resolution.

## 2026-05-13: R14 — APB done ownership cleanup
- Active: `R14`. `isf/apb_requester.isf` no longer drives transaction `done`
  from `done_phase`; `t/1100` now locks that APB protocol cleanup and
  transaction completion are owned separately.

## 2026-05-13: R14 — ISF sample D-input lowering clarification
- Active: `R14`. The mdBook lowering reference now explains why
  `(sample port as name)` lowers with `<=`: the sampled alias denotes the
  D-input/next-value side for same-state consumers, while `<-` would expose the
  previous Q/output value and can force an extra state.

## 2026-05-13: R14 — ISF actor-shell drive metadata audit
- Active: `R14`. `t/1167` proves public actor-shell drive metadata is exact and
  aligned with APB drive definitions, while non-scalar drive names and params
  are rejected before returning an actor shell.

## 2026-05-13: R14 — ISF actor-shell rule metadata audit
- Active: `R14`. `t/1166` proves public actor-shell rule-entry metadata is
  exact and aligned with rule-bearing plus rule-free parser actors, while
  non-scalar rule names are rejected before returning an actor shell.

## 2026-05-13: R14 — ISF actor-shell timing metadata audit
- Active: `R14`. `t/1165` proves public actor timing metadata is exact and
  aligned with APB plus omitted reset/watchdog actors, while malformed timing
  declarations are rejected before returning an actor shell.

## 2026-05-13: R14 — ISF actor-shell actor-name metadata audit
- Active: `R14`. `t/1164` proves public actor-shell `actor_name` identity
  metadata is exact and aligned with parser facade APB actors, while non-scalar
  actor root names are rejected before returning an actor shell.

## 2026-05-13: R14 — ISF actor-shell transaction-shape metadata audit
- Active: `R14`. `t/1163` proves public actor-shell transaction-entry metadata
  is exact and aligned with parser facade APB actors, while non-scalar
  transaction names are rejected before returning an actor shell.

## 2026-05-13: R14 — ISF actor-shell interface-shape metadata audit
- Active: `R14`. `t/1162` proves public actor-shell `interface` subshape
  metadata is exact and aligned with parser facade APB actors, while malformed
  interface entries are rejected before returning an actor shell.

## 2026-05-12: R14 — ISF facade failure diagnostic metadata audit
- Active: `R14`. `t/1161` proves public ISF facade failure diagnostic metadata
  is exact and aligned with constructor, parser, and scheduler boundary checks.

## 2026-05-12: R14 — ISF actor-shell value-shape metadata audit
- Active: `R14`. `t/1160` proves public actor-shell value-shape metadata is
  exact and aligned with parser facade APB actors.

## 2026-05-12: R14 — ISF report reset-shape metadata audit
- Active: `R14`. `t/1159` proves schedule-report reset-shape metadata is exact
  for configured reset hashes and omitted reset JSON null.

## 2026-05-12: R14 — ISF report DT kind metadata audit
- Active: `R14`. `t/1158` proves schedule-report DT kind metadata is exact and
  aligned with APB plus full-featured reports.

## 2026-05-12: R14 — ISF report transaction-ordering metadata audit
- Active: `R14`. `t/1157` proves schedule-report transaction-ordering metadata
  is exact and aligned with the full-featured multi-transaction report.

## 2026-05-12: R14 — ISF lower-result file-shape metadata audit
- Active: `R14`. `t/1156` proves lower-result `files` map basename and
  scheduled-text-root metadata is exact and aligned with real lowerings.

## 2026-05-12: R14 — ISF strict CLI success metadata audit
- Active: `R14`. `t/1155` proves accepted `--strict file.isf`
  HDL-generation success metadata is exact and aligned with the APB CLI path.

## 2026-05-12: R14 — ISF facade return metadata audit
- Active: `R14`. `t/1154` proves public in-process ISF facade return-shape
  metadata is exact and aligned with APB parser/scheduler facade results.

## 2026-05-12: R14 — ISF CLI success metadata audit
- Active: `R14`. `t/1153` proves public ISF CLI success metadata is exact and
  aligned with schedule JSON, `--outdir`, and HDL-generation paths.

## 2026-05-12: R14 — ISF report scalar metadata audit
- Active: `R14`. `t/1152` proves schedule-report scalar metadata is exact and
  aligned with APB plus no-watchdog reports.

## 2026-05-12: R14 — ISF report count metadata audit
- Active: `R14`. `t/1151` proves schedule-report interface and state-count
  metadata is exact and aligned with APB lowering.

## 2026-05-12: R14 — ISF reset metadata audit
- Active: `R14`. `t/1150` proves schedule-report reset metadata is exact and
  aligned with reset reports.

## 2026-05-12: R14 — ISF transaction metadata audit
- Active: `R14`. `t/1149` proves schedule-report transaction metadata is exact
  and aligned with the APB report.

## 2026-05-12: R14 — ISF storage metadata audit
- Active: `R14`. `t/1148` proves schedule-report inferred-storage metadata is
  exact and aligned with the APB report.

## 2026-05-12: R14 — ISF report DT assignment-count audit
- Active: `R14`. `t/1147` proves schedule-report DT assignment counts match
  generated scheduled `.fsm` DT blocks.

## 2026-05-12: R14 — ISF DT assignment metadata audit
- Active: `R14`. `t/1146` proves public DT assignment operator metadata is
  exact and aligned with generated scheduled `.fsm` assignment operators.

## 2026-05-12: R14 — ISF scheduled `.fsm` metadata audit
- Active: `R14`. `t/1145` proves scheduled `.fsm` artifact metadata is exact
  across direct and manifest views.

## 2026-05-12: R14 — ISF tested_by metadata audit
- Active: `R14`. `t/1144` proves ISF `tested_by` provenance metadata is exact
  across direct and manifest views.

## 2026-05-12: R14 — ISF facade-shape metadata audit
- Active: `R14`. `t/1143` proves public ISF facade-shape metadata is exact
  across direct and manifest views.

## 2026-05-12: R14 — ISF guidance metadata audit
- Active: `R14`. `t/1142` proves ISF contract guidance metadata is exact and
  duplicate-free across direct and manifest views.

## 2026-05-12: R14 — ISF identity/stability metadata audit
- Active: `R14`. `t/1141` proves ISF contract identity and stability flags are
  exact across direct and manifest views.

## 2026-05-12: R14 — ISF schedule-report metadata audit
- Active: `R14`. `t/1140` proves schedule-report metadata fields are exact
  across direct and manifest views.

## 2026-05-12: R14 — ISF lower-result metadata audit
- Active: `R14`. `t/1139` proves lower-result discovery metadata is exact
  across direct and manifest views.

## 2026-05-12: R14 — ISF constructor-option metadata audit
- Active: `R14`. `t/1138` proves public constructor option metadata is exact
  and duplicate-free across direct and manifest views.

## 2026-05-12: R14 — ISF method-name metadata audit
- Active: `R14`. `t/1137` proves public parser/scheduler method-name metadata
  is exact and duplicate-free across direct and manifest views.

## 2026-05-12: R14 — ISF CLI option metadata audit
- Active: `R14`. `t/1136` proves the ISF public CLI option list is exact and
  duplicate-free across direct and manifest views.

## 2026-05-12: R14 — ISF entrypoint metadata audit
- Active: `R14`. `t/1135` proves the ISF public contract entrypoint metadata
  is exact and duplicate-free across direct and manifest views.

## 2026-05-12: R14 — ISF parse_file path boundary audit
- Active: `R14`. `t/1134` proves `parse_file(...)` accepts readable `.isf`
  files and rejects missing, directory, and wrong-extension paths.

## 2026-05-12: R14 — ISF constructor receiver boundary audit
- Active: `R14`. `t/1133` proves ISF adapter/scheduler constructors reject
  malformed invocants with bounded diagnostics.

## 2026-05-12: R14 — ISF method receiver boundary audit
- Active: `R14`. `t/1132` proves public parser/scheduler facade methods
  reject malformed receivers with bounded diagnostics.

## 2026-05-12: R14 — ISF top-level discovery audit
- Active: `R14`. `t/1131` proves the ISF public contract top-level discovery
  list is unique and exact across direct, manifest, and CLI manifest views.

## 2026-05-12: R14 — ISF compile_issues success-shape audit
- Active: `R14`. `t/1130` proves successful in-process and CLI schedule
  reports keep `compile_issues` present as an empty array.

## 2026-05-12: R14 — ISF actor shell contract audit
- Active: `R14`. `t/1129` proves both public parser facades return actors with
  the manifest-advertised scheduler-consumable shell keys.

## 2026-05-12: R14 — ISF multi-file schedule report audit
- Active: `R14`. `t/1128` proves multi-file schedule reports are currently
  parent-scoped and that the manifest advertises this scope.

## 2026-05-12: R14 — ISF scheduler method boundary audit
- Active: `R14`. `t/1127` proves `lower(...)` and `report(...)` enforce the
  public scheduler actor-shell argument boundary.

## 2026-05-12: R14 — ISF parser method boundary audit
- Active: `R14`. `t/1126` proves `parse_file(...)` and `parse_source(...)`
  enforce the public defined-scalar argument shapes.

## 2026-05-12: R14 — ISF constructor boundary audit
- Active: `R14`. `t/1125` proves ISF adapter/scheduler constructors accept only
  the public `debug` option and reject malformed option lists.

## 2026-05-12: R14 — ISF CLI strict mode audit
- Active: `R14`. `t/1124` proves `--strict` remains accepted for public
  `file.isf` HDL generation with clean stderr.

## 2026-05-12: R14 — ISF CLI HDL generation audit
- Active: `R14`. `t/1123` proves the plain `file.isf` CLI path reaches
  generated HDL for APB with clean stderr.

## 2026-05-12: R14 — ISF CLI outdir lowering audit
- Active: `R14`. `t/1122` proves `--outdir` writes multi-file scheduled `.fsm`
  artifacts matching the in-process lower-result files map.

## 2026-05-12: R14 — ISF CLI schedule report audit
- Active: `R14`. `t/1121` proves `--emit-schedule-json` emits clean public APB
  schedule JSON matching the in-process scheduler report.

## 2026-05-12: R14 — ISF live document path audit
- Active: `R14`. `t/1120` proves
  `embedding.isf_public_interface.live_document_paths` is manifest-aligned and
  points at unique repo-local Markdown files.

## 2026-05-12: R14 — deterministic ISF DT block order
- Active: `R14`. `t/1119` proves APB generated `.fsm` DT block order and
  schedule-report `dt_blocks` order are deterministic through `parse_file(...)`
  and `parse_source(...)`; `embedding.isf_public_interface` advertises the
  matching ordering policy.

## 2026-05-12: R14 — ISF parse_source facade audit
- Active: `R14`. `t/1118` proves `parse_source(...)` is scheduler-consumable
  and matches `parse_file(...)` through public lower/report identities.

## 2026-05-12: R14 — ISF lower result files audit
- Active: `R14`. `t/1117` proves the public ISF lower-result `files` map for
  both single-file and multi-file lowering.

## 2026-05-12: R14 — ISF schedule report key-family audit
- Active: `R14`. `t/1116` proves the APB schedule report conforms to the
  key families advertised by `embedding.isf_public_interface`.

## 2026-05-12: R14 — ISF public contract CLI manifest audit
- Active: `R14`. `t/1115` proves both capability-manifest CLI spellings
  advertise the same `embedding.isf_public_interface` contract payload.

## 2026-05-12: R14 — ISF public contract defensive copy
- Active: `R14`. `t/1114` proves fresh `embedding.isf_public_interface`
  contract builds stay clean after caller mutation.

## 2026-05-12: R14 — ISF public contract JSON roundtrip
- Active: `R14`. `t/1113` proves `embedding.isf_public_interface` contract
  metadata survives JSON encode/decode unchanged.

## 2026-05-12: R14 — ISF public interface contract
- Active: `R14`. `embedding.isf_public_interface` now advertises the bounded
  live downstream-consumer contract for ISF parser/scheduler facades and
  schedule-report key families.

## 2026-05-12: R14 — samples before data ops
- Active: `R14`. `t/1111` proves samples are materialized before data
  operations at top level and inside `when`, `switch`, and `repeat` bodies.

## 2026-05-12: R14 — `do` child entry rewire
- Active: `R14`. `t/1110` proves blocking `do` children enter the first
  non-entry child state, including data-op-first children.

## 2026-05-12: R14 — readable `await_all` guard emission
- Active: `R14`. `t/1109` now also proves nested `await_all` guard closings
  are emitted one per generated `.fsm` line.

## 2026-05-12: R14 — `await_all` nested guard coverage
- Active: `R14`. `t/1109` proves `await_all` waits on every collected spawned
  done signal through one nested all-guards transition.

## 2026-05-12: R14 — schedule JSON transaction states
- Active: `R14`. `t/1108` proves schedule JSON transaction summaries include
  generated control-flow and data-operation states.

## 2026-05-12: R14 — `when` body data/repeat lowering
- Active: `R14`. `t/1107` proves `when` bodies now lower data operations and
  nested repeats with inferred counter widths while preserving false exits.

## 2026-05-12: R14 — schedule JSON counter storage
- Active: `R14`. `t/1106` proves schedule JSON reports assigned scheduler
  counters as counters with inferred widths while preserving the current
  storage-name surface.

## 2026-05-12: R14 — size deduplication
- Active: `R14`. `t/1105` proves inferred scheduler storage no longer
  duplicates declared interface ports in `.fsm` `+size` entries.

## 2026-05-12: R14 — when false exits
- Active: `R14`. `t/1104` proves top-level and switch-nested `when` blocks
  emit false skip paths to the correct post-body/post-switch state.

## 2026-05-12: R14 — switch branch exits
- Active: `R14`. `t/1103` proves multi-state switch branches and
  switch-nested repeat checks exit after the whole switch instead of falling
  into later branch bodies.

## 2026-05-12: R14 — repeat counter widths
- Active: `R14`. `t/1102` proves repeat counters infer widths from decimal
  literals and sampled named counts, and switch-nested repeats declare the
  shared transaction counter width.

## 2026-05-12: R14 — exact extract slices
- Active: `R14`. `t/1101` proves `assemble ... as target` handling and
  known-width `extract` lowering to exact descending slices, including
  assemble-inferred word widths.

## 2026-05-12: R14 — DT terminology corrected
- Active: `R14`. The spec, user guide, and mdBook now distinguish state DTs
  from non-state DTs and state that assignment operators, not DT spelling,
  decide combinational vs sequential behavior.

## 2026-05-12: R14 — sample piggyback lowering
- Active: `R14`. `t/1100` proves entry samples and pending samples before
  named drive/await states now materialize in the scheduled state; APB is now a
  corrected 7-state schedule with no trailing sample state.

## 2026-05-12: R14 — repeat drive/data ops
- Active: `R14`. `t/1099` proves repeat bodies lower named drive calls and data
  ops; known-width `shift_right` now uses concrete width. Later slices added
  known-width extract slices. Remaining: resources, priority, composition-top.

## 2026-05-12: R14 — `await_any` all guards
- Active: `R14`. `t/1098` proves `await_any` watches every collected spawned
  done signal, not only the first. Remaining: priority/resource, data-op,
  composition-top limits.

## 2026-05-12: R14 — named start binding
- Active: `R14`. `t/1097` locks concrete start assertions for `do`, `spawn`,
  and control-flow drive calls. `_start` placeholder removed from those paths.

## 2026-05-12: R14 — schedule JSON report test
- Active: `R14`. `t/1096` locks current APB schedule JSON shape from
  `Emitter::JSON`: identity, counts, transaction states, DTs, storage, no
  compile issues. Next: implementation slice for a documented scheduler gap.

## 2026-05-12: R14 — ISF spec synced to implementation
- Active: `R14`. `docs/ISF_SPEC.md` + mdBook now record shipped behavior and
  limitations: unenforced priorities/resources, unknown-width data-op
  fallbacks, deferred composition-top instantiation. Later slices narrowed
  several limits.

## 2026-05-12: Bootstrap — R14 docs/import tree
- Active: `R14`. Import tree refreshed for `.isf` pre-lowering path: 191 project
  files, 190 `.pm` packages. README and roadmap status point to current ISF
  CLI/options. The following slice synced ISF_SPEC.

## 2026-05-12: R14 — mdBook ISF + data manip
- Active: `R14`. 8 ISF sub-chapters + shift/assemble/extract. 36 states, 7 tests.

## 2026-05-12: R14 — no merge, mdBook
- Active: `R14`. One drive = one cycle. mdBook ISF chapter 13 added. 7 tests.

## 2026-05-12: R14 — parameterized drives
- Active: `R14`. `(drive (name p) body...)` + `(drive name arg)`. 7 tests pass.

## 2026-05-12: R14 — drive architecture
- Active: `R14`. Drive calls -> start assertions + non-state DTs. I2C @ 19 states. 7 tests.

## 2026-05-11: R14 — handshake removed
- Active: `R14`. `(on port)` + implicit `can_accept`. 7 tests pass.

## 2026-05-11: R14 — multi-file
- Active: `R14`. Multi-file spawn + `--outdir`. 7 tests pass.

## 2026-05-11: R14 — spawn
- Active: `R14`. Spawn instance signals. 7 tests pass.

## 2026-05-11: R14 — `(do ...)`
- Active: `R14`. `(do ...)` shipped. 7 tests pass.

## 2026-05-11: R14 — JSON
- Active: `R14`. `Emitter::JSON` shipped. 7 tests pass.

## 2026-05-11: R14 — IR refactor
- Active: `R14`. `LoweringIR` + `Emitter::FSM` shipped. 7 tests pass.

## 2026-05-11: R14 `.isf` — trigger/pulse
- Active: `R14`. Trigger/pulse shipped. 7 tests pass.

## 2026-05-11: R14 `.isf` — latency
- Active: `R14`. Latency lowering shipped. All 3 fixtures pass, 7 tests pass.

## 2026-05-11: R14 `.isf` — rule lowering
- Active: `R14`. Rules → DT blocks shipped. 7 tests pass.

## 2026-05-11: R14 `.isf` — watchdog
- Active: `R14`. Watchdog shipped. 7 tests pass.

## 2026-05-11: R14 `.isf` — CLI wired
- `bin/fsmgen` now accepts `.isf` files. Full CLI pipeline works. 7 ISF tests.

## 2026-05-11: R14 `.isf` scheduler — repeat
- Active lane: `R14`. Repeat lowering, counter inference, 7 ISF tests, both fixtures compile.

## 2026-05-11: R14 `.isf` scheduler — transaction lowering
- Active lane: `R14`. Transaction lowering converts ISF clauses → `.fsm` states. Full pipeline works end-to-end.
  `isf/apb_requester.isf` → `.fsm` → SystemVerilog. 6 ISF tests pass.

## 2026-05-11: R14 `.isf` scheduler — module header
- Active lane: `R14`. `FSM::Scheduler::ISF` with `ModuleEmitter`, 4 ISF tests pass. Next: transaction lowering.

## 2026-05-11: R14 `.isf` parser — full construct coverage
- Active lane: `R14`. All constructs validated, tracing added, 3 passing tests. Next: scheduler.

## 2026-05-11: R14 `.isf` parser — first slice
- Active lane: `R14`. `FSM::Adapter::ISF` with LispishAdapter, parser, fixture, 2 passing tests.

## 2026-05-11: `.isf` specification v0.5 — watchdog, named spawn
- Active lane: `R14`. ISF_SPEC.md v0.5: `(watchdog ...)`, `(spawn tx as name ...)`, deadlock policy. 1 open question.

## 2026-05-11: `.isf` specification v0.4 — sample everywhere, watchdog
- Active lane: `R14`. ISF_SPEC.md v0.4: universal `(sample ...)`, implicit `(await ...)` watchdog, spawn params + recursive spawn. 4 open questions.

## 2026-05-11: `.isf` specification v0.3 — transaction composition
- Active lane: `R14`. [docs/ISF_SPEC.md](docs/ISF_SPEC.md) v0.3: `(actor ...)`, `(do ...)`/`(spawn ...)` composition, dynamic `(repeat ...)`, dual-form `(priority ...)`, 5 open questions.

## 2026-05-11: `.isf` specification v0.2 — pure Lisp, no register leakage
- Active lane: `R14`. [docs/ISF_SPEC.md](docs/ISF_SPEC.md) v0.2: pure Lisp, handshake-first,
  scheduler-owns-storage. Next: first `.isf` parser or worked lowering example.

## 2026-05-11: R14 `.isf` format specification v0.1
- Active lane: `R14` — Intent Scheduling. First slice complete: [docs/ISF_SPEC.md](docs/ISF_SPEC.md).
- Defines `.isf` syntax, lowering contract, and schedule report model.
- Next slice: worked lowering example (AHB requester read burst → .fsm states).

## 2026-05-11: R14 reprioritized — Intent Scheduling `.isf` now active
- Active lane: `R14` — Intent Scheduling (`.isf` format and lowering compiler).
- TRM capture canceled (handled externally by SPECFORGE).
- R8–R13 lanes closed. R13: 96 full-surface audits complete.
- First slice: formalize `.isf` format specification from INTENT_SCHEDULING_BRAINSTORM.md.

## 2026-05-11: R14 reprioritized — TRM intent capture now active
- Active lane: `R14` — TRM / protocol-spec intent capture (promoted from H4).
- R8–R13 lanes closed. R13: 96 full-surface audits complete.
- Former R14 (VHDL) demoted to horizon H5. VHDL_SCOPE.md preserved for future reference.
- Next bounded slice: internalize the AXI case-study method, produce first APB requester capture worksheet.

## 2026-05-11: HDLGenerator facade contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1090. Public behavior changed: no.
- Next bounded slice: continue remaining contract full-surface audits.

## 2026-05-11: HDLGenerator facade contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1089. Public behavior changed: no.
- Next bounded slice: continue facade full-surface stability audits.

## 2026-05-11: HDLGenerator resolved package imports contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1088. Public behavior changed: no.
- HDLGenerator nested contract family (8 contracts) now fully audited.
- Next bounded slice: continue remaining contract full-surface audits.

## 2026-05-11: HDLGenerator resolved package imports contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1087. Public behavior changed: no.
- Next bounded slice: continue resolved package imports full-surface stability audits.

## 2026-05-11: HDLGenerator raw AST contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1086. Public behavior changed: no.
- Next bounded slice: resolved package imports contract.

## 2026-05-11: HDLGenerator raw AST contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1085. Public behavior changed: no.
- Next bounded slice: continue raw AST full-surface stability audits.

## 2026-05-11: HDLGenerator FSM module contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1084. Public behavior changed: no.
- Next bounded slice: raw AST contract.

## 2026-05-11: HDLGenerator FSM module contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1083. Public behavior changed: no.
- Next bounded slice: continue FSM module full-surface stability audits.

## 2026-05-11: HDLGenerator composition spec contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1082. Public behavior changed: no.
- Next bounded slice: FSM module contract.

## 2026-05-11: HDLGenerator composition spec contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1081. Public behavior changed: no.
- Next bounded slice: continue composition spec full-surface stability audits.

## 2026-05-11: HDLGenerator composition plan contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1080. Public behavior changed: no.
- Next bounded slice: composition spec contract.

## 2026-05-11: HDLGenerator composition plan contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1079. Public behavior changed: no.
- Next bounded slice: continue composition plan full-surface stability audits.

## 2026-05-11: HDLGenerator statistics contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1078. Public behavior changed: no.
- Next bounded slice: composition plan contract.

## 2026-05-11: HDLGenerator statistics contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1077. Public behavior changed: no.
- Next bounded slice: continue statistics full-surface stability audits.

## 2026-05-11: HDLGenerator module info contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1076. Public behavior changed: no.
- Next bounded slice: statistics contract.

## 2026-05-11: HDLGenerator module info contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1075. Public behavior changed: no.
- Next bounded slice: continue module info full-surface stability audits.

## 2026-05-11: HDLGenerator source info contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1074. Public behavior changed: no.
- Next bounded slice: module info contract.

## 2026-05-11: HDLGenerator source info contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1073. Public behavior changed: no.
- Next bounded slice: continue source info full-surface stability audits.

## 2026-05-11: Semantic exports contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1072. Public behavior changed: no.
- Manifest section-level contract family now fully audited.
- Next bounded slice: HDLGenerator nested contracts.

## 2026-05-11: Semantic exports contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1071. Public behavior changed: no.
- Next bounded slice: continue semantic exports full-surface stability audits.

## 2026-05-11: Backend validation contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1070. Public behavior changed: no.
- Next bounded slice: semantic exports contract.

## 2026-05-11: Backend validation contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1069. Public behavior changed: no.
- Next bounded slice: continue backend validation full-surface stability audits.

## 2026-05-11: Documentation contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1068. Public behavior changed: no.
- Next bounded slice: backend validation contract.

## 2026-05-11: Documentation contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1067. Public behavior changed: no.
- Next bounded slice: continue documentation full-surface stability audits.

## 2026-05-11: Language surface contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1066. Public behavior changed: no.
- Next bounded slice: documentation contract.

## 2026-05-11: Language surface contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1065. Public behavior changed: no.
- Next bounded slice: continue language surface full-surface stability audits.

## 2026-05-11: Producer section contract full surface rebuilds cleanly
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1064-producer-contract-full-surface-defensive-copy-audit.t](t/1064-producer-contract-full-surface-defensive-copy-audit.t)
  now proves a fresh producer section contract build stays clean after caller
  mutation, completing the producer section contract full-surface audit pair.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1064-producer-contract-full-surface-defensive-copy-audit.t t/1063-producer-contract-full-surface-json-roundtrip-audit.t t/319-producer-contract.t t/449-producer-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue remaining section-level contract full-surface audits.

## 2026-05-11: Producer section contract full surface survives JSON
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1063-producer-contract-full-surface-json-roundtrip-audit.t](t/1063-producer-contract-full-surface-json-roundtrip-audit.t)
  now proves the full producer section contract owner survives JSON encode/decode
  unchanged.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1063-producer-contract-full-surface-json-roundtrip-audit.t t/319-producer-contract.t t/449-producer-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue producer section full-surface stability audits.

## 2026-05-11: Embedding contract full surface rebuilds cleanly
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1062-embedding-contract-full-surface-defensive-copy-audit.t](t/1062-embedding-contract-full-surface-defensive-copy-audit.t)
  now proves a fresh embedding contract build stays clean after caller mutation.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1062-embedding-contract-full-surface-defensive-copy-audit.t t/1061-embedding-contract-full-surface-json-roundtrip-audit.t t/321-embedding-contract.t t/480-embedding-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue remaining contract full-surface audits.

## 2026-05-11: Embedding contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1061. Public behavior changed: no.
- Batch complete: 25 new full-surface audit pairs across 14 contract families.
- Next bounded slice: continue remaining contract full-surface audits.

## 2026-05-11: Debug runtime contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1060. Public behavior changed: no.
- Next bounded slice: embedding contract.

## 2026-05-11: Debug runtime contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1059. Public behavior changed: no.
- Next bounded slice: continue debug runtime full-surface stability audits.

## 2026-05-11: HDL external validation contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1058. Public behavior changed: no.
- Next bounded slice: debug runtime contract.

## 2026-05-11: HDL external validation contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1057. Public behavior changed: no.
- Next bounded slice: continue HDL external validation full-surface stability audits.

## 2026-05-11: Extension contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1056. Public behavior changed: no.
- Next bounded slice: HDL external validation contract.

## 2026-05-11: Extension contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1055. Public behavior changed: no.
- Next bounded slice: continue extension full-surface stability audits.

## 2026-05-11: Composition report contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1054. Public behavior changed: no.
- Next bounded slice: extension contract.

## 2026-05-11: Composition report contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1053. Public behavior changed: no.
- Next bounded slice: continue composition report full-surface stability audits.

## 2026-05-11: Report generated output contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1052. Public behavior changed: no.
- Shared public report contract family now fully audited.
- Next bounded slice: composition report contract.

## 2026-05-11: Report generated output contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1051. Public behavior changed: no.
- Next bounded slice: continue generated output full-surface stability audits.

## 2026-05-11: Report command contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1050. Public behavior changed: no.
- Next bounded slice: continue remaining shared report contracts.

## 2026-05-11: Report command contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1049. Public behavior changed: no.
- Next bounded slice: continue report command full-surface stability audits.

## 2026-05-11: Report source contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1048. Public behavior changed: no.
- Next bounded slice: continue remaining shared report contracts.

## 2026-05-11: Report source contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1047. Public behavior changed: no.
- Next bounded slice: continue report source full-surface stability audits.

## 2026-05-11: Report producer contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1046. Public behavior changed: no.
- Next bounded slice: continue remaining shared report contracts.

## 2026-05-11: Report producer contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1045. Public behavior changed: no.
- Next bounded slice: continue report producer full-surface stability audits.

## 2026-05-11: Diagnostics section contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1044. Public behavior changed: no.
- Next bounded slice: continue remaining contract families.

## 2026-05-11: Diagnostics section contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1043. Public behavior changed: no.
- Next bounded slice: continue diagnostics section full-surface stability audits.

## 2026-05-11: Diagnostic code registry contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1042. Public behavior changed: no.
- Next bounded slice: continue remaining contract families.

## 2026-05-11: Diagnostic code registry contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1041. Public behavior changed: no.
- Next bounded slice: continue diagnostic code registry full-surface stability audits.

## 2026-05-11: Support accounting match contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1040. Public behavior changed: no.
- Next bounded slice: continue remaining contract families.

## 2026-05-11: Support accounting match contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1039. Public behavior changed: no.
- Next bounded slice: continue match contract full-surface stability audits.

## 2026-05-11: Support accounting contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1038. Public behavior changed: no.
- Next bounded slice: continue remaining contract families.

## 2026-05-11: Support accounting contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1037. Public behavior changed: no.
- Next bounded slice: continue support accounting full-surface stability audits.

## 2026-05-11: Normalized semantic structural RTL IR contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1036. Public behavior changed: no.
- The normalized semantic nested-contract family (11 contracts) is now fully audited.
- Next bounded slice: continue with remaining public contract families.

## 2026-05-11: Normalized semantic structural RTL IR contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1035. Public behavior changed: no.
- Next bounded slice: continue structural RTL IR full-surface stability audits.

## 2026-05-11: Normalized semantic lowered RTL IR contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1034. Public behavior changed: no.
- Next bounded slice: continue normalized semantic nested-contract audits.

## 2026-05-11: Normalized semantic lowered RTL IR contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1033. Public behavior changed: no.
- Next bounded slice: continue lowered RTL IR full-surface stability audits.

## 2026-05-11: Normalized semantic intent HIR contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1032. Public behavior changed: no.
- Next bounded slice: continue normalized semantic nested-contract audits.

## 2026-05-11: Normalized semantic intent HIR contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1031. Public behavior changed: no.
- Next bounded slice: continue intent HIR full-surface stability audits.

## 2026-05-11: Normalized semantic signal analysis contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1030. Public behavior changed: no.
- Next bounded slice: continue normalized semantic nested-contract audits.

## 2026-05-11: Normalized semantic signal analysis contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1029. Public behavior changed: no.
- Next bounded slice: continue signal analysis full-surface stability audits.

## 2026-05-11: Normalized semantic explicit system contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1028. Public behavior changed: no.
- Next bounded slice: continue normalized semantic nested-contract audits.

## 2026-05-11: Normalized semantic explicit system contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1027. Public behavior changed: no.
- Next bounded slice: continue explicit system full-surface stability audits.

## 2026-05-11: Normalized semantic system contract full surface rebuilds cleanly
- Roadmap lane: R13. Completed slice: t/1026. Public behavior changed: no. Focused validation passed.
- Next bounded slice: continue normalized semantic nested-contract audits.

## 2026-05-11: Normalized semantic system contract full surface survives JSON
- Roadmap lane: R13. Completed slice: t/1025 now proves the full system contract survives JSON encode/decode unchanged.
- Public behavior changed: no. Focused validation passed.
- Next bounded slice: continue system full-surface stability audits.

## 2026-05-11: Normalized semantic symbol contract full surface rebuilds cleanly
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice: t/1024 now proves a fresh symbol contract build stays clean after caller mutation.
- Public behavior changed: no.
- Focused validation passed.
- Next bounded slice: continue normalized semantic nested-contract full-surface stability audits.

## 2026-05-11: Normalized semantic symbol contract full surface survives JSON
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1023-normalized-semantic-symbol-contract-full-surface-json-roundtrip-audit.t](t/1023-normalized-semantic-symbol-contract-full-surface-json-roundtrip-audit.t)
  now proves the full normalized semantic symbol contract owner survives
  JSON encode/decode unchanged.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1023-normalized-semantic-symbol-contract-full-surface-json-roundtrip-audit.t t/335-normalized-semantic-symbol-contract.t t/472-normalized-semantic-symbol-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue normalized semantic symbol full-surface stability audits.

## 2026-05-11: Normalized semantic forward IR contract full surface rebuilds cleanly
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1022-normalized-semantic-forward-ir-contract-full-surface-defensive-copy-audit.t](t/1022-normalized-semantic-forward-ir-contract-full-surface-defensive-copy-audit.t)
  now proves a fresh normalized semantic forward IR contract build stays clean
  after caller mutation.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1022-normalized-semantic-forward-ir-contract-full-surface-defensive-copy-audit.t t/1021-normalized-semantic-forward-ir-contract-full-surface-json-roundtrip-audit.t t/334-normalized-semantic-forward-ir-contract.t t/471-normalized-semantic-forward-ir-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue normalized semantic nested-contract full-surface stability audits.

## 2026-05-11: Normalized semantic forward IR contract full surface survives JSON
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1021-normalized-semantic-forward-ir-contract-full-surface-json-roundtrip-audit.t](t/1021-normalized-semantic-forward-ir-contract-full-surface-json-roundtrip-audit.t)
  now proves the full normalized semantic forward IR contract owner survives
  JSON encode/decode unchanged.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1021-normalized-semantic-forward-ir-contract-full-surface-json-roundtrip-audit.t t/334-normalized-semantic-forward-ir-contract.t t/471-normalized-semantic-forward-ir-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue normalized semantic forward IR full-surface stability audits.

## 2026-05-11: Normalized semantic composition contract full surface rebuilds cleanly
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1020-normalized-semantic-composition-contract-full-surface-defensive-copy-audit.t](t/1020-normalized-semantic-composition-contract-full-surface-defensive-copy-audit.t)
  now proves a fresh normalized semantic composition contract build stays clean
  after caller mutation.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1020-normalized-semantic-composition-contract-full-surface-defensive-copy-audit.t t/1019-normalized-semantic-composition-contract-full-surface-json-roundtrip-audit.t t/333-normalized-semantic-composition-contract.t t/470-normalized-semantic-composition-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue normalized semantic nested-contract full-surface stability audits.

## 2026-05-11: Normalized semantic composition contract full surface survives JSON
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1019-normalized-semantic-composition-contract-full-surface-json-roundtrip-audit.t](t/1019-normalized-semantic-composition-contract-full-surface-json-roundtrip-audit.t)
  now proves the full normalized semantic composition contract owner survives
  JSON encode/decode unchanged.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1019-normalized-semantic-composition-contract-full-surface-json-roundtrip-audit.t t/333-normalized-semantic-composition-contract.t t/470-normalized-semantic-composition-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue normalized semantic composition full-surface stability audits.

## 2026-05-11: Normalized semantic module contract full surface rebuilds cleanly
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1018-normalized-semantic-module-contract-full-surface-defensive-copy-audit.t](t/1018-normalized-semantic-module-contract-full-surface-defensive-copy-audit.t)
  now proves a fresh normalized semantic module contract build stays clean
  after caller mutation.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1018-normalized-semantic-module-contract-full-surface-defensive-copy-audit.t t/1017-normalized-semantic-module-contract-full-surface-json-roundtrip-audit.t t/332-normalized-semantic-module-contract.t t/469-normalized-semantic-module-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue normalized semantic nested-contract full-surface stability audits.

## 2026-05-11: Normalized semantic module contract full surface survives JSON
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1017-normalized-semantic-module-contract-full-surface-json-roundtrip-audit.t](t/1017-normalized-semantic-module-contract-full-surface-json-roundtrip-audit.t)
  now proves the full normalized semantic module contract owner survives
  JSON encode/decode unchanged.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1017-normalized-semantic-module-contract-full-surface-json-roundtrip-audit.t t/332-normalized-semantic-module-contract.t t/469-normalized-semantic-module-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue normalized semantic module full-surface stability audits.

## 2026-05-11: Normalized semantic payload contract full surface rebuilds cleanly
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1016-normalized-semantic-payload-contract-full-surface-defensive-copy-audit.t](t/1016-normalized-semantic-payload-contract-full-surface-defensive-copy-audit.t)
  now proves a fresh normalized semantic payload contract build stays clean
  after caller mutation.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1016-normalized-semantic-payload-contract-full-surface-defensive-copy-audit.t t/1015-normalized-semantic-payload-contract-full-surface-json-roundtrip-audit.t t/330-normalized-semantic-payload-contract.t`.
- Next bounded slice: continue normalized semantic nested-contract full-surface stability audits.

## 2026-05-11: Normalized semantic payload contract full surface survives JSON
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1015-normalized-semantic-payload-contract-full-surface-json-roundtrip-audit.t](t/1015-normalized-semantic-payload-contract-full-surface-json-roundtrip-audit.t)
  now proves the full normalized semantic payload contract owner survives
  JSON encode/decode unchanged.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1015-normalized-semantic-payload-contract-full-surface-json-roundtrip-audit.t t/330-normalized-semantic-payload-contract.t`.
- Next bounded slice: continue normalized semantic payload full-surface stability audits.

## 2026-05-11: Check result contract full surface rebuilds cleanly
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1014-check-result-contract-full-surface-defensive-copy-audit.t](t/1014-check-result-contract-full-surface-defensive-copy-audit.t)
  now proves a fresh check result contract build stays clean after caller
  mutation of a previous full contract result.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1014-check-result-contract-full-surface-defensive-copy-audit.t t/1013-check-result-contract-full-surface-json-roundtrip-audit.t t/329-check-result-contract.t t/456-check-result-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue public report full-surface stability audits.

## 2026-05-11: Check result contract full surface survives JSON
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1013-check-result-contract-full-surface-json-roundtrip-audit.t](t/1013-check-result-contract-full-surface-json-roundtrip-audit.t)
  now proves the full check result contract owner survives JSON encode/decode
  unchanged.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/1013-check-result-contract-full-surface-json-roundtrip-audit.t t/329-check-result-contract.t t/456-check-result-contract-defensive-copy-boundary-audit.t`.
- Next bounded slice: continue check result full-surface stability audits.

## 2026-05-11: Check failure diagnostic contract full surface rebuilds cleanly
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1012-check-failure-diagnostic-contract-full-surface-defensive-copy-audit.t](t/1012-check-failure-diagnostic-contract-full-surface-defensive-copy-audit.t)
  now proves a fresh check failure diagnostic contract build stays clean after
  caller mutation of a previous full contract result.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/331-check-failure-diagnostic-contract.t t/457-check-failure-diagnostic-contract-defensive-copy-boundary-audit.t t/1011-check-failure-diagnostic-contract-full-surface-json-roundtrip-audit.t t/1012-check-failure-diagnostic-contract-full-surface-defensive-copy-audit.t t/1010-check-diagnostics-contract-full-surface-defensive-copy-audit.t`.
- Next bounded slice: continue public report full-surface stability audits.

## 2026-05-10: Check failure diagnostic contract full surface survives JSON
- Roadmap lane: `R13` public embedding/API stabilization.
- Completed slice:
  [t/1011-check-failure-diagnostic-contract-full-surface-json-roundtrip-audit.t](t/1011-check-failure-diagnostic-contract-full-surface-json-roundtrip-audit.t)
  now proves the shared failure `diagnostic` contract owner survives JSON
  encode/decode unchanged.
- Public behavior changed: no; this is a full-surface stability audit only.
- Focused validation passed:
  `prove -I perl t/331-check-failure-diagnostic-contract.t t/457-check-failure-diagnostic-contract-defensive-copy-boundary-audit.t t/1007-normalized-semantic-report-contract-full-surface-json-roundtrip-audit.t t/1009-check-diagnostics-contract-full-surface-json-roundtrip-audit.t t/1011-check-failure-diagnostic-contract-full-surface-json-roundtrip-audit.t`.
- Next bounded slice: continue public report full-surface stability audits.
