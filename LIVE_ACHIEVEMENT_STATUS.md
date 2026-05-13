# LIVE_ACHIEVEMENT_STATUS

This file tracks the latest completed roadmap-aligned slice for fast recovery.

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
- Active: `R14`. The current rule-trigger behavior and its limitation are now
  documented: multiple rules triggering the same transaction are
  OR-equivalent through direct `transaction_start` writes, but the scheduled
  `.fsm` does not preserve separate per-rule trigger provenance.
- The R14 backlog now explicitly carries the proposed general lowering:
  generate a distinct `rule_transaction` pulse source per rule/transaction
  pair, then drive `transaction_start` with generated combinational OR fan-in
  and no added cycle.

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
