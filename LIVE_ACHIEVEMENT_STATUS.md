# LIVE_ACHIEVEMENT_STATUS

This file tracks the latest completed roadmap-aligned slice for fast recovery.

## 2026-05-26: R14 — Defensive missing-drain coverage shipped for same-domain second-awaitany
- Completed `ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`
  and closed the task tree.
- Added one `when`-body and one `switch`-branch `assert_lower_rejected`
  regression in `t/1215-isf-spawn-parameter-binding.t` for same-domain
  generated-do prior-`await_any` then spawn then second post-spawn
  `await_any` without final same-body `(await_all done)`. Both regressions
  match the existing validator confess at
  `perl/FSM/Scheduler/ISF/LoweringIR.pm:6551` for the
  `'generated do with static params and same-domain metadata'` kind.
- Test-only; no behavior, parser, scheduler, backend, generated `.fsm`,
  HDL, public API, or runtime change.
- Validation passed: `prove -Iperl t/1215-isf-spawn-parameter-binding.t`
  with `Files=1, Tests=100`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: Bootstrap architecture maintenance — R14 same-domain generated-do second-awaitany import-tree refreshed
- Completed `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-DOMAIN-SECOND-AWAITANY-REFRESH.1`
  and closed the task tree.
- Rebuilt the live `bin/fsmgen` import closure: `196` project-owned files,
  `195` `.pm` packages, and unchanged family counts.
- Refreshed `docs/BIN_FSMGEN_IMPORT_TREE.md` to keep the `2026-05-26`
  bootstrap baseline current and updated the recorded
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` line count to `11144` after the R14
  same-domain generated-do prior-`await_any` plus second post-spawn
  `await_any` repeat-body slice added one line.
- This was documentation-only architecture maintenance with no behavior,
  parser, scheduler, backend, generated `.fsm`, HDL, public API, or runtime
  change.
- Validation passed: import-closure recount with `total=196` and `pm=195`;
  largest-file recount showing `LoweringIR.pm` at `11144`; targeted
  stale-value grep; `prove -Iperl
  t/1305-isf-book-feature-matrix-audit.t
  t/1332-isf-atl-doc-status-audit.t` with `Files=2, Tests=411`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Same-domain generated do after prior awaitany then spawn plus second awaitany shipped
- Completed `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`
  and closed the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, same-domain generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))`, later generated
  spawn, second post-spawn multi-pending `(await_any done)`, and mandatory
  same-body `(await_all done)` before nested repeat re-entry for repeats
  directly inside top-level `when` bodies or top-level `switch` branches.
- Both `await_any` clauses observe generated children without clearing the
  outstanding generated-spawn done set; the deterministic generated do
  instance preserves static generated-top parameter overrides, optional
  generated-top input/output binding handoffs, and declared same-domain
  ownership metadata, then completes before the later generated spawn
  starts; the final `await_all` drains generated spawns from both sides of
  the generated `do`.
- Missing same-body `(await_all done)` drain, cross-domain activation,
  deeper branch/loop nesting, CDC behavior, and broader outstanding-child
  lifetime semantics remain fail-closed/deferred.
- Validation passed: syntax checks; focused behavior with
  `t/1215-isf-spawn-parameter-binding.t`; feature matrix audit with
  `t/1305-isf-book-feature-matrix-audit.t`; loop-body doc audit with
  `t/1307-isf-loop-body-doc-truth-audit.t`; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: Bootstrap architecture maintenance — R14 bound generated-do second-awaitany import-tree refreshed
- Completed `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-BOUND-SECOND-AWAITANY-REFRESH.1`
  and closed the task tree.
- Rebuilt the live `bin/fsmgen` import closure: `196` project-owned files,
  `195` `.pm` packages, and unchanged family counts.
- Refreshed `docs/BIN_FSMGEN_IMPORT_TREE.md` to keep the `2026-05-26`
  bootstrap baseline current and updated the recorded
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` line count to `11143` after the R14
  static-parameter and bound generated-do prior-`await_any` plus second
  post-spawn `await_any` repeat-body slices each added one line.
- This was documentation-only architecture maintenance with no behavior,
  parser, scheduler, backend, generated `.fsm`, HDL, public API, or runtime
  change.
- Validation passed: import-closure recount with `total=196` and `pm=195`;
  largest-file recount showing `LoweringIR.pm` at `11143`; targeted
  stale-value grep; `prove -Iperl
  t/1305-isf-book-feature-matrix-audit.t
  t/1332-isf-atl-doc-status-audit.t` with `Files=2, Tests=403`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Bound generated do after prior awaitany then spawn plus second awaitany shipped
- Completed `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`
  and closed the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, bound generated blocking
  `(do child (params ...) (bind ...))`, later generated spawn, second
  post-spawn multi-pending `(await_any done)`, and mandatory same-body
  `(await_all done)` before nested repeat re-entry for repeats directly
  inside top-level `when` bodies or top-level `switch` branches.
- Both `await_any` clauses observe generated children without clearing the
  outstanding generated-spawn done set; the deterministic generated do
  instance preserves static generated-top parameter overrides and generated
  top binding handoffs, then completes before the later generated spawn
  starts; the final `await_all` drains generated spawns from both sides of the
  generated `do`.
- Same-domain generated `do` variants of this second post-spawn `await_any`
  prior-observation shape, missing drains, cross-domain activation, deeper
  branch/loop nesting, CDC behavior, and broader outstanding-child lifetime
  semantics remain fail-closed/deferred.
- Validation passed: syntax checks; focused behavior `Files=1, Tests=98`;
  feature matrix audit `Files=1, Tests=403`; loop-body doc audit
  `Files=1, Tests=225`; public tested-by audit `Files=2, Tests=4`; live path
  audits `Files=4, Tests=657`; repeat/child regression `Files=4, Tests=112`;
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book` with
  `Files=275, Tests=1945`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Static-parameter generated do after prior awaitany then spawn plus second awaitany shipped
- Completed `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`
  and closed the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, static-parameter generated blocking
  `(do child (params ...))`, later generated spawn, second post-spawn
  multi-pending `(await_any done)`, and mandatory same-body
  `(await_all done)` before nested repeat re-entry for repeats directly
  inside top-level `when` bodies or top-level `switch` branches.
- Both `await_any` clauses observe generated children without clearing the
  outstanding generated-spawn done set; the deterministic generated do
  instance preserves static generated-top parameter overrides and completes
  before the later generated spawn starts; the final `await_all` drains
  generated spawns from both sides of the generated `do`.
- The bound analogue has since shipped in
  `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`.
  Same-domain generated `do` variants of this second post-spawn `await_any`
  prior-observation shape, missing drains, cross-domain activation, deeper
  branch/loop nesting, CDC behavior, and broader outstanding-child lifetime
  semantics remain fail-closed/deferred.
- Validation passed: syntax checks; focused scheduler/doc audits with
  `Files=3, Tests=713`; live path audits with `Files=2, Tests=29`;
  stale-doc grep; `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book` with `Files=275, Tests=1932`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: Bootstrap architecture maintenance — R14 generated-child second-awaitany import-tree refreshed
- Completed `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.1`
  and closed the task tree.
- Rebuilt the live `bin/fsmgen` import closure: `196` project-owned files,
  `195` `.pm` packages, and unchanged family counts.
- Refreshed `docs/BIN_FSMGEN_IMPORT_TREE.md` to keep the `2026-05-26`
  bootstrap baseline current and updated the recorded
  `perl/FSM/Scheduler/ISF/LoweringIR.pm` line count to `11141`; the later
  `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-BOUND-SECOND-AWAITANY-REFRESH.1` slice
  superseded that measurement with `11143`.
- This was documentation-only architecture maintenance with no behavior,
  parser, scheduler, backend, generated `.fsm`, HDL, public API, or runtime
  change.
- Validation passed: import-closure recount with `total=196` and `pm=195`;
  largest-file recount showing `LoweringIR.pm` at `11141`; targeted
  stale-value grep; `prove -Iperl
  t/1305-isf-book-feature-matrix-audit.t
  t/1332-isf-atl-doc-status-audit.t` with `Files=2, Tests=403`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Generated-child do after prior awaitany then spawn plus second awaitany shipped
- Completed `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`
  and closed the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, plain generated-child blocking
  `(do child)`, later generated spawn, second post-spawn multi-pending
  `(await_any done)`, and mandatory same-body `(await_all done)` before
  nested repeat re-entry for repeats directly inside top-level `when`
  bodies or top-level `switch` branches.
- Both `await_any` clauses observe generated children without clearing the
  outstanding generated-spawn done set; the deterministic generated do
  instance completes before the later generated spawn starts; the final
  `await_all` drains generated spawns from both sides of the generated-child
  `do`.
- At that checkpoint, static-parameter, bound, and same-domain generated
  `do` variants of this second post-spawn `await_any` prior-observation
  shape remained fail-closed/deferred. Later slices shipped the
  static-parameter and bound analogues; same-domain generated `do`, missing
  drains, cross-domain activation, deeper branch/loop nesting, CDC behavior,
  and broader outstanding-child lifetime semantics remain fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=94`;
  `prove -Iperl t/1305-isf-book-feature-matrix-audit.t` with `Files=1,
  Tests=397`; `prove -Iperl t/1307-isf-loop-body-doc-truth-audit.t` with
  `Files=1, Tests=207`; focused book/public audits with `Files=2, Tests=4`;
  live-doc audits with `Files=4, Tests=633`; broader repeat/child regression
  with `Files=4, Tests=108`; `./bin/ci-regression isf --no-book` with
  `Files=275, Tests=1917`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: Bootstrap architecture maintenance — R14 repeat import-tree refreshed
- Completed `BIN-FSMGEN-IMPORT-TREE-R14-REPEAT-REFRESH.1` and closed the
  task tree.
- Rebuilt the live `bin/fsmgen` import closure: `196` project-owned files,
  `195` `.pm` packages, and unchanged family counts.
- Refreshed `docs/BIN_FSMGEN_IMPORT_TREE.md` to the `2026-05-26` bootstrap
  baseline and updated the recorded `perl/FSM/Scheduler/ISF/LoweringIR.pm`
  line count to `11137`; the later
  `BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.1` slice
  superseded that measurement with `11141`.
- This was documentation-only architecture maintenance with no behavior,
  parser, scheduler, backend, generated `.fsm`, HDL, public API, or runtime
  change.
- Validation passed: import-closure recount with `total=196` and `pm=195`;
  largest-file recount showing `LoweringIR.pm` at `11137`; targeted
  stale-value greps; `prove -Iperl
  t/1305-isf-book-feature-matrix-audit.t
  t/1332-isf-atl-doc-status-audit.t` with `Files=2, Tests=399`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Local do after prior awaitany then spawn plus second awaitany shipped
- Completed `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1` and
  closed the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, local blocking `(do child)`, later
  generated spawn, second post-spawn multi-pending `(await_any done)`, and
  mandatory same-body `(await_all done)` before nested repeat re-entry for
  repeats directly inside top-level `when` bodies or top-level `switch`
  branches.
- Both `await_any` clauses observe generated children without clearing the
  outstanding generated-spawn done set; the local child completes before the
  later generated spawn starts; the final `await_all` drains generated spawns
  from both sides of the local `do`.
- The plain generated-child analogue has since shipped in
  `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.1`.
  At that checkpoint, static-parameter, bound, and same-domain generated `do`
  variants of this second post-spawn `await_any` prior-observation shape
  remained fail-closed/deferred. Later slices shipped the static-parameter and
  bound analogues; same-domain generated `do`, missing drains, cross-domain
  activation, deeper branch/loop nesting, CDC behavior, and broader
  outstanding-child lifetime semantics remain fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=92`; focused
  doc audits with `Files=2, Tests=591`; focused book/public audits with
  `Files=4, Tests=595`; live-doc audits with `Files=4, Tests=620`;
  broader repeat/child regression with `Files=4, Tests=106`;
  `./bin/ci-regression isf --no-book` with `Files=275, Tests=1902`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Same-domain generated do after prior awaitany then spawn before drain shipped
- Completed `ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` and
  closed the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, same-domain generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))`, later generated
  spawn, and mandatory same-body `(await_all done)` before nested repeat
  re-entry for repeats directly inside top-level `when` bodies or top-level
  `switch` branches.
- The prior `await_any` observes a generated child without clearing the
  outstanding generated-spawn done set; the generated do instance completes
  before the later generated spawn starts and preserves its static
  generated-top parameter override, optional generated-top input/output
  binding handoffs, and declared same-domain ownership metadata; the final
  `await_all` drains generated spawns from both sides of the generated `do`.
- A second post-spawn `await_any`, missing drains, cross-domain activation,
  deeper branch/loop nesting, CDC behavior, and broader outstanding-child
  lifetime semantics remain fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=90`; focused
  doc audits with `Files=2, Tests=579`; focused book/public audits with
  `Files=4, Tests=583`; live-doc audits with `Files=4, Tests=608`;
  broader repeat/child regression with `Files=4, Tests=104`;
  `./bin/ci-regression isf --no-book` with `Files=275, Tests=1888`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Bound generated do after prior awaitany then spawn before drain shipped
- Completed `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` and
  closed the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, bound generated blocking
  `(do child (params ...) (bind ...))`, later generated spawn, and mandatory
  same-body `(await_all done)` before nested repeat re-entry for repeats
  directly inside top-level `when` bodies or top-level `switch` branches.
- The prior `await_any` observes a generated child without clearing the
  outstanding generated-spawn done set; the generated do instance completes
  before the later generated spawn starts and preserves its static
  generated-top parameter override plus generated-top input/output binding
  handoffs; the final `await_all` drains generated spawns from both sides of
  the generated `do`.
- Same-domain generated-do prior-observation spawn-after-do, repeated
  post-spawn `await_any`, missing drains, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child lifetime semantics
  remain fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=88`; focused
  doc audits with `Files=2, Tests=569`; focused book/public audits with
  `Files=4, Tests=573`; live-doc audits with `Files=4, Tests=598`;
  broader repeat/child regression with `Files=4,
  Tests=102`; `./bin/ci-regression isf --no-book` with `Files=275,
  Tests=1876`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Static-parameter generated do after prior awaitany then spawn before drain shipped
- Completed `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` and
  closed the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, generated blocking
  `(do child (params ...))`, later generated spawn, and mandatory same-body
  `(await_all done)` before nested repeat re-entry for repeats directly
  inside top-level `when` bodies or top-level `switch` branches.
- The prior `await_any` observes a generated child without clearing the
  outstanding generated-spawn done set; the generated do instance completes
  before the later generated spawn starts and preserves its static
  generated-top parameter override; the final `await_all` drains generated
  spawns from both sides of the generated `do`.
- At that checkpoint, bound generated-do and same-domain generated-do
  prior-observation spawn-after-do variants, repeated post-spawn `await_any`,
  missing drains, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child lifetime semantics remained fail-closed/deferred;
  the later `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` slice
  shipped the bound generated-do analogue while same-domain generated-do
  remains deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=86`; focused
  book/public audits with `Files=4, Tests=563`; live-doc audits with
  `Files=4, Tests=588`; broader repeat/child regression with `Files=4,
  Tests=100`; `./bin/ci-regression isf --no-book` with `Files=275,
  Tests=1864`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Prior-awaitany spawn-after-do docs truth-synced
- Completed `ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.1` and
  closed the task tree.
- Removed stale current-doc wording that still re-deferred local-do and plain
  generated-child prior-observation spawn-after-do repeat paths after those
  paths shipped.
- ISF spec, downstream handoff, and public contract now consistently say the
  documented local/plain prior-observation do-then-spawn paths are shipped
  only when they go directly to mandatory same-body `(await_all done)`.
- At that checkpoint, static-parameter, bound, and same-domain generated-do
  prior-observation spawn-after-do variants, second post-spawn `await_any`,
  missing drains, cross-domain activation, deeper nesting, and broader
  outstanding-child lifetime behavior remained fail-closed/deferred; the
  later `ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` slice
  shipped the static-parameter analogue and the later
  `ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` slice shipped the
  bound analogue while same-domain remains deferred.
- Validation passed: `perl -Iperl -c
  t/1307-isf-loop-body-doc-truth-audit.t`; `prove -Iperl
  t/1307-isf-loop-body-doc-truth-audit.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1250-isf-spec-focused-test-index-audit.t
  t/1144-isf-public-tested-by-metadata-audit.t` with `Files=4, Tests=552`;
  stale wording grep; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Generated-child do after prior awaitany then spawn before drain shipped
- Completed `ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` and
  closed the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, plain generated-child blocking
  `(do child)`, later generated spawn, and mandatory same-body `(await_all
  done)` before nested repeat re-entry for repeats directly inside top-level
  `when` bodies or top-level `switch` branches.
- The prior `await_any` observes a generated child without clearing the
  outstanding generated-spawn done set; the generated do instance completes
  before the later generated spawn starts; the final `await_all` drains
  generated spawns from both sides of the generated-child `do`.
- Specialized generated-do prior-observation spawn-after-do variants,
  repeated post-spawn `await_any`, missing drains, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child lifetime
  semantics remain fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=84`; focused
  book/public audits with `Files=3, Tests=381`; broader repeat/child
  regression with `Files=4, Tests=98`; `prove -Iperl
  t/1307-isf-loop-body-doc-truth-audit.t` with `Files=1, Tests=156`;
  `./bin/ci-regression isf --no-book` with `Files=275, Tests=1836`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Local do after prior awaitany then spawn before drain shipped
- Completed `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` and closed
  the task tree.
- Branch-contained nested repeats now accept generated spawns, prior
  multi-pending `(await_any done)`, local blocking `(do child)`, later
  generated spawn, and mandatory same-body `(await_all done)` before nested
  repeat re-entry for repeats directly inside top-level `when` bodies or
  top-level `switch` branches.
- The prior `await_any` observes a generated child without clearing the
  outstanding generated-spawn done set; the local child completes before the
  later generated spawn starts; the final `await_all` drains generated spawns
  from both sides of the local `do`.
- Generated-do prior-observation spawn-after-do variants, repeated
  post-spawn `await_any`, missing drains, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child lifetime semantics remain
  fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=82`; focused
  book/public audits with `Files=3, Tests=377`; broader repeat/child
  regression with `Files=4, Tests=96`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1830`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Same-domain generated do then spawn post-awaitany shipped
- Completed `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` and
  closed the task tree.
- Branch-contained nested repeats now accept initial generated spawn,
  generated blocking `(do child (params ...) [(bind ...)] (domain NAME))`,
  later generated spawn, post-spawn multi-pending `(await_any done)`, and
  mandatory same-body `(await_all done)` before nested repeat re-entry for
  repeats directly inside top-level `when` bodies or top-level `switch`
  branches.
- The generated do instance completes before the later generated spawn starts
  and preserves static generated-top parameter binding, optional generated-top
  input/output binding handoffs, and declared same-domain ownership metadata;
  the post-spawn `await_any` observes either pre-do or post-do generated child
  without clearing the outstanding generated-spawn done set; the final
  `await_all` drains both pre-do and post-do generated children.
- At that checkpoint, prior active multi-pending `await_any`, missing drains,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child lifetime semantics remained fail-closed/deferred; the
  later `ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.1` slice shipped
  the local-do prior-observation spawn-after-do analogue.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=80`; focused
  book/public audits with `Files=3, Tests=373`; broader repeat/child
  regression with `Files=4, Tests=94`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1824`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Bound generated do then spawn post-awaitany shipped
- Completed `ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO-POST-AWAITANY.1` and
  closed the task tree.
- Branch-contained nested repeats now accept initial generated spawn, bound
  generated blocking `(do child (params ...) (bind ...))`, later generated
  spawn, post-spawn multi-pending `(await_any done)`, and mandatory same-body
  `(await_all done)` before nested repeat re-entry for repeats directly
  inside top-level `when` bodies or top-level `switch` branches.
- The generated do instance completes before the later generated spawn starts
  and preserves static generated-top parameter binding plus generated-top
  input/output binding handoffs; the post-spawn `await_any` observes either
  pre-do or post-do generated child without clearing the outstanding
  generated-spawn done set; the final `await_all` drains both pre-do and
  post-do generated children.
- At that checkpoint, same-domain generated-do post-spawn `await_any`, prior
  active multi-pending `await_any`, missing drains, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child lifetime
  semantics remained fail-closed/deferred; the later
  `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` slice shipped the
  same-domain generated-do analogue.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=78`; focused
  book/public audits with `Files=3, Tests=369`; broader repeat/child
  regression with `Files=4, Tests=92`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1818`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Static-parameter generated do then spawn post-awaitany shipped
- Completed `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-POST-AWAITANY.1` and
  closed the task tree.
- Branch-contained nested repeats now accept initial generated spawn,
  generated blocking `(do child (params ...))`, later generated spawn,
  post-spawn multi-pending `(await_any done)`, and mandatory same-body
  `(await_all done)` before nested repeat re-entry for repeats directly
  inside top-level `when` bodies or top-level `switch` branches.
- The generated do instance completes before the later generated spawn starts
  and preserves static generated-top parameter binding; the post-spawn
  `await_any` observes either pre-do or post-do generated child without
  clearing the outstanding generated-spawn done set; the final `await_all`
  drains both pre-do and post-do generated children.
- At that checkpoint, bound and same-domain generated-do post-spawn
  `await_any`, prior active multi-pending `await_any`, missing drains,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child lifetime semantics remained fail-closed/deferred; the
  later `ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO-POST-AWAITANY.1` slice shipped
  the bound generated-do analogue.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=76`; focused
  book/public audits with `Files=3, Tests=365`; broader repeat/child
  regression with `Files=4, Tests=90`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1812`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Local do then spawn post-awaitany shipped
- Completed `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO-POST-AWAITANY.1` and closed
  the task tree.
- Branch-contained nested repeats now accept initial generated spawn, local
  `(do child)`, later generated spawn, post-spawn multi-pending `(await_any
  done)`, and mandatory same-body `(await_all done)` before nested repeat
  re-entry for repeats directly inside top-level `when` bodies or top-level
  `switch` branches.
- The local child completes before the later generated spawn starts; the
  post-spawn `await_any` observes either pre-do or post-do generated child
  without clearing the outstanding generated-spawn done set; the final
  `await_all` drains both pre-do and post-do generated children.
- Specialized generated-do post-spawn `await_any`, prior active
  multi-pending `await_any`, missing drains, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child lifetime semantics remain
  fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=74`; focused
  book/public audits with `Files=3, Tests=361`; broader repeat/child
  regression with `Files=4, Tests=88`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1806`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Plain generated-child do then spawn post-awaitany shipped
- Completed `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.1` and
  closed the task tree.
- Branch-contained nested repeats now accept initial generated spawn, plain
  generated-child `(do child)`, later generated spawn, post-spawn
  multi-pending `(await_any done)`, and mandatory same-body `(await_all done)`
  before nested repeat re-entry for repeats directly inside top-level `when`
  bodies or top-level `switch` branches.
- The generated do instance completes before the later generated spawn starts;
  the post-spawn `await_any` observes either pre-do or post-do generated child
  without clearing the outstanding generated-spawn done set; the final
  `await_all` drains both pre-do and post-do generated children.
- Local-do and specialized generated-do post-spawn `await_any`, prior active
  multi-pending `await_any`, missing drains, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child lifetime semantics remain
  fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=72`; focused
  book/public audits with `Files=3, Tests=358`; broader repeat/child
  regression with `Files=4, Tests=86`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1801`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Same-domain generated do then spawn before drain shipped
- Completed `ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.1` and closed the task
  tree.
- Branch-contained nested repeats now accept initial generated spawn,
  generated blocking `(do child (params ...) [(bind ...)] (domain NAME))`,
  later generated spawn, and mandatory same-body `(await_all done)` before
  nested repeat re-entry for repeats directly inside top-level `when` bodies
  or top-level `switch` branches.
- The generated do instance completes before the later generated spawn starts;
  it preserves static generated-top parameter overrides, optional input/output
  binding handoffs, and declared same-domain ownership metadata; the later
  spawn joins the outstanding generated-spawn done set; the final `await_all`
  drains both pre-do and post-do generated children.
- Post/active multi-pending `await_any`, cross-domain activation, missing
  drains, deeper branch/loop nesting, and broader outstanding-child lifetime
  semantics remain fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=70`; focused
  book/public audits with `Files=3, Tests=354`; broader repeat/child
  regression with `Files=4, Tests=84`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1795`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Bound generated do then spawn before drain shipped
- Completed `ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO.1` and closed the task
  tree.
- Branch-contained nested repeats now accept initial generated spawn,
  generated blocking `(do child (params ...) (bind ...))`, later generated
  spawn, and mandatory same-body `(await_all done)` before nested repeat
  re-entry for repeats directly inside top-level `when` bodies or top-level
  `switch` branches.
- The generated do instance completes before the later generated spawn starts;
  it preserves its static generated-top parameter override and input/output
  binding handoffs; the later spawn joins the outstanding generated-spawn done
  set; the final `await_all` drains both pre-do and post-do generated
  children.
- At that checkpoint, same-domain generated-do spawn-after-do, generated or
  local spawn-after-do with post-do or active multi-pending `await_any`,
  missing drains, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child lifetime semantics remained fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=68`; focused
  book/public audits with `Files=3, Tests=351`; broader repeat/child
  regression with `Files=4, Tests=82`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1790`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Static-parameter generated do then spawn before drain shipped
- Completed `ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO.1` and closed the task
  tree.
- Branch-contained nested repeats now accept initial generated spawn,
  generated blocking `(do child (params ...))`, later generated spawn, and
  mandatory same-body `(await_all done)` before nested repeat re-entry for
  repeats directly inside top-level `when` bodies or top-level `switch`
  branches.
- The generated do instance completes before the later generated spawn starts;
  it preserves its static generated-top parameter override; the later spawn
  joins the outstanding generated-spawn done set; the final `await_all` drains
  both pre-do and post-do generated children.
- At that checkpoint, bound and same-domain generated-do spawn-after-do,
  generated or local spawn-after-do with post-do or active multi-pending
  `await_any`, missing drains, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child lifetime semantics remained
  fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=66`; focused
  book/public audits with `Files=3, Tests=347`; broader repeat/child
  regression with `Files=4, Tests=80`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1784`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Plain generated do then spawn before drain shipped
- Completed `ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO.1` and closed the task
  tree.
- Branch-contained nested repeats now accept initial generated spawn, plain
  generated-child blocking `(do child)`, later generated spawn, and mandatory
  same-body `(await_all done)` before nested repeat re-entry for repeats
  directly inside top-level `when` bodies or top-level `switch` branches.
- The generated do instance completes before the later generated spawn starts;
  the later spawn joins the outstanding generated-spawn done set; the final
  `await_all` drains both pre-do and post-do generated children.
- At that checkpoint, static-parameter, bound, and same-domain generated-do
  spawn-after-do, generated-child or local spawn-after-do with post-do or
  active multi-pending `await_any`, missing drains, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child lifetime
  semantics remained fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=64`; focused
  book/public audits with `Files=3, Tests=343`; broader repeat/child
  regression with `Files=4, Tests=78`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1778`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-26: R14 — Local do then spawn before drain shipped
- Completed `ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.1` and closed the task tree.
- Branch-contained nested repeats now accept initial generated spawn, local
  blocking `(do child)`, later generated spawn, and mandatory same-body
  `(await_all done)` before nested repeat re-entry for repeats directly inside
  top-level `when` bodies or top-level `switch` branches.
- The local child completes before the later generated spawn starts; the later
  spawn joins the outstanding generated-spawn done set; the final `await_all`
  drains both pre-do and post-do generated children.
- Generated-do spawn-after-do, local-do spawn-after-do with post-do or active
  multi-pending `await_any`, missing drains, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child lifetime semantics remain
  fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t` with `Files=1, Tests=62`; focused
  book/public audits with `Files=3, Tests=338`; broader repeat/child
  regression with `Files=4, Tests=76`; `./bin/ci-regression isf --no-book`
  with `Files=275, Tests=1771`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Same-domain generated-do post-do await_any shipped
- Completed `ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.1` and closed the task
  tree.
- Branch-contained nested repeats now accept same-domain generated blocking
  `do` before a post-do multi-pending `(await_any done)` observation: a repeat
  directly inside a top-level `when` body or top-level `switch` branch may run
  multiple generated spawns, then `(do child (params ...) [(bind ...)]
  (domain NAME))`, then post-do `(await_any done)`, and then mandatory
  same-body `(await_all done)` before nested repeat re-entry.
- The generated do instance must complete before the observation; pending
  generated-spawn done handoffs remain live until the later `await_all` drain.
- Generated-composition, domain partition, and schedule-report clock-domain
  summaries retain declared same-domain ownership metadata without implying
  CDC.
- New spawn after the do before the drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child lifetime semantics remain
  fail-closed/deferred.
- Validation passed: syntax checks; `prove -Iperl
  t/1215-isf-spawn-parameter-binding.t`; focused book/public audits with
  `Files=3, Tests=333`; broader repeat/child regression with `Files=4,
  Tests=74`; `./bin/ci-regression isf --no-book` with `Files=275,
  Tests=1764`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Static-zero repeat mdBook wording synchronized
- Completed `ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.1` and closed the task
  tree.
- Replaced stale ISF introduction wording that still said zero-count repeat
  bodies containing `do` or `spawn` fail closed until generated-child artifact
  pruning is specified.
- The mdBook now records the shipped behavior: plain and syntactically valid
  specialized static-zero child activations are pruned with no generated
  child/top, activation instance, local handoff, or loop-report artifact when
  their targets are not otherwise live; malformed activation subclause syntax
  still fails closed.
- Parser behavior, scheduler lowering, generated `.fsm`, HDL, public API,
  tests, and runtime behavior did not change.
- Validation passed: stale wording grep; `prove -Iperl
  t/1305-isf-book-feature-matrix-audit.t`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: Bootstrap — Static-zero repeat import-tree measurement refresh shipped
- Completed `BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.1` and closed
  the task tree.
- Rebuilt the live project-owned `FSM::...` import closure reachable from
  `bin/fsmgen`; topology remains unchanged at `196` reachable project files
  total and `195` reachable `.pm` packages with the same family counts.
- Refreshed the stale `perl/FSM/Scheduler/ISF/LoweringIR.pm` measured line
  count in `docs/BIN_FSMGEN_IMPORT_TREE.md` after the latest R14 static-zero
  repeat child-activation pruning work; the then-current count was `11048`.
- Parser behavior, scheduler lowering, generated `.fsm`, HDL, public API,
  tests, and runtime behavior did not change.
- Validation passed: import-closure recount; stale measured-value grep;
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Static zero repeat specialized child activation pruning shipped
- Completed `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.1` and closed
  the task tree.
- Syntactically valid parameterized, bound, or domain-annotated `do` and
  `spawn` child activations inside statically zero repeat bodies now lower as
  dead payloads after activation subclause shape validation.
- The pruned path emits no repeat counter, repeat init/check state,
  repeat-body state, generated child `.fsm`, generated top `.fsm`,
  activation instance, local child start/done handoff, or
  `transaction_loops[]` entry.
- Target transactions referenced by nonzero/live child activations, rule
  triggers, or explicit external entry guards are preserved.
- Malformed activation subclause syntax inside static-zero repeat bodies still
  fails closed through the existing activation clause shape diagnostics.
- Positive static repeat counts, known-width runtime repeat counts, and
  existing repeat-body child activation re-entry validation are unchanged.
- Validation passed: syntax checks; focused repeat/parameter/child-boundary
  tests with `Files=4, Tests=72`; focused public/book audits with `Files=5,
  Tests=334`; `./bin/ci-regression isf --no-book` with `Files=275,
  Tests=1759`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Static zero repeat child activation pruning shipped
- Completed `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.1` and closed the task tree.
- Plain `(spawn child as inst)` and plain `(do child)` clauses inside
  statically zero repeat bodies now lower as true zero-iteration no-ops when
  the target transaction is declared and reachable only through pruned
  zero-count activations.
- The pruned path emits no repeat counter, repeat init/check state,
  repeat-body state, generated child `.fsm`, generated top `.fsm`,
  activation instance, local child start/done handoff, or
  `transaction_loops[]` entry.
- Target transactions referenced by nonzero/live child activations, rule
  triggers, or explicit external entry guards are preserved.
- At shipment time, parameterized, bound, or domain-annotated child
  activation sites inside static-zero repeat bodies remained fail-closed; the
  later `ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.1` slice accepts
  those specialized forms as dead payloads after activation subclause shape
  validation.
- Positive static repeat counts, known-width runtime repeat counts, and
  existing repeat-body child activation re-entry validation are unchanged.
- Validation passed: syntax checks; focused repeat/parameter/child-boundary
  tests with `Files=4, Tests=71`; focused public/book audits with `Files=5,
  Tests=334`; `./bin/ci-regression isf --no-book` with `Files=275,
  Tests=1758`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: Bootstrap — Import-tree measurement refresh shipped
- Completed `BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.1` and closed the task
  tree.
- Rebuilt the live project-owned `FSM::...` import closure reachable from
  `bin/fsmgen`; topology remains unchanged at `196` reachable project files
  total and `195` reachable `.pm` packages.
- Refreshed stale measured line counts in `docs/BIN_FSMGEN_IMPORT_TREE.md`
  after recent R14 scheduler/parser work.
- Parser behavior, scheduler lowering, generated `.fsm`, HDL, public API,
  tests, and runtime behavior did not change.
- Validation passed: import-closure recount; stale measured-value grep;
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Repeat zero roadmap status synchronized
- Completed `ROADMAP-R14-REPEAT-ZERO-STATUS-TRUTH-SYNC.1` and closed the task
  tree.
- Current R14 transaction-parameter repeat-count roadmap entries no longer
  imply zero-valued same-transaction scalar repeat parameters fail closed after
  `ISF-STATIC-ZERO-REPEAT-NOOP.1`.
- The roadmap now records that the original positive-count transaction
  parameter slice was later superseded for zero-valued scalar parameters by
  static zero no-op lowering; aggregate/list and cross-transaction parameters
  remain fail-closed/unsupported.
- Parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report payloads, public contract code, tests, and runtime behavior
  did not change.
- Validation passed: stale roadmap wording grep; `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Static zero repeat no-op shipped
- Completed `ISF-STATIC-ZERO-REPEAT-NOOP.1` and closed the task tree.
- Static zero repeat counts now lower as transparent zero-iteration no-op
  regions for literal zero, zero-valued actor constants, actor scalar
  parameters, same-transaction scalar parameters, and qualified package scalar
  constants.
- Zero-count no-op repeats emit no repeat counter, repeat init/check state,
  repeat-body state, or `transaction_loops[]` entry.
- At shipment time, child activation inside statically zero repeat bodies
  remained fail-closed; the later
  `ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.1` slice accepts plain static-zero
  `do`/`spawn` child activations while keeping specialized activation forms
  fail-closed.
- Positive static repeat counts and known-width runtime scalar repeat counts
  keep their existing behavior.
- Validation passed: syntax checks; focused repeat/public-audit tests with
  `Files=7, Tests=344`; `./bin/ci-regression isf --no-book` with
  `Files=275, Tests=1757`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — No-reset scheduled FSM HDL shipped
- Completed `NO-RESET-SCHEDULED-FSM-HDL.1` and closed the task tree.
- Direct scheduled `.fsm` parsing now accepts explicit clock-only `+system`
  contracts as no-reset system contracts.
- Verilog-family HDL for no-reset scheduled modules exposes the clock but no
  reset port and emits clock-only sequential blocks with no reset branch.
- Reset-bearing `sreset`, `areset`, and legacy `asreset` behavior remains
  unchanged.
- The ISF no-reset acknowledged-event CDC fixture now reaches generated
  SystemVerilog through reset-free domain modules, a generated top, and a
  concrete CDC child that omits absent reset ports.
- Validation passed: syntax checks; focused direct-system/ISF CDC tests with
  `Files=4, Tests=24`; focused public-contract/book audits with `Files=6,
  Tests=359`; `./bin/ci-regression quick` with `Files=8, Tests=145`;
  `./bin/ci-regression isf --no-book` with `Files=275, Tests=1756`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — No-reset CDC fixture coverage shipped
- Completed `ISF-CDC-NO-RESET-FIXTURE.1` and closed the task tree.
- Added `isf/clock_domain_no_reset_event_crossing.isf` as a no-reset
  acknowledged-event CDC fixture.
- Focused coverage now proves bus/core domain lower-result artifacts,
  generated top CDC child wiring, absent-reset CDC metadata
  (`SOURCE_RESET_PRESENT 0d0` and `DEST_RESET_PRESENT 0d0`), in-process
  schedule report metadata, and CLI schedule JSON parity.
- The subsequent `NO-RESET-SCHEDULED-FSM-HDL.1` slice promotes the no-reset
  fixture to generated HDL coverage by adding reset-free scheduled `.fsm`
  backend support.
- Validation passed: syntax check; focused clock-domain/book audits with
  `Files=4, Tests=376`; `./bin/ci-regression isf --no-book` with
  `Files=275, Tests=1756`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Data-operation width backlog synchronized
- Completed `ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.1` and closed the task
  tree.
- The mdBook feature backlog no longer implies that every transaction
  parameter is fail-closed for explicit data-operation width evidence.
- The wording now preserves the shipped same-transaction scalar parameter
  support while still rejecting unrelated/cross-transaction parameters,
  zero-valued transaction parameters, aggregate/list transaction parameters,
  activation-site override-specialized data widths, runtime signals, and
  expressions.
- Parser behavior, scheduler lowering, generated `.fsm`, HDL,
  schedule-report payloads, public contract code, and runtime behavior did not
  change.
- Validation passed: focused backlog/book audits with `Files=2, Tests=341`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Schedule-report additive storage roles shipped
- Completed `ISF-SCHEDULE-REPORT-STORAGE-ROLES.1` and closed the task tree.
- Schedule JSON now reports `atl_trigger_start_handoff` for generated
  parent-to-child start pulses emitted by static actor-network triggers and
  trigger-batch lowering.
- Schedule JSON now reports `scheduler_error_status` for timeout terminal
  writes to the global `last_error` latch from await watchdogs and latency
  maximum checks.
- This is additive report metadata only: scheduled `.fsm`, HDL, state
  topology, timeout behavior, and private `LoweringIR` internals are
  unchanged.
- Validation passed: syntax checks; focused public-contract/report/docs tests
  with `Files=10, Tests=385`; focused schedule/ATL tests with `Files=4,
  Tests=11`; focused burst fixture with `Files=1, Tests=3`;
  `./bin/ci-regression isf --no-book` with `Files=275, Tests=1755`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Transaction-parameter zero divisors shipped
- Completed `ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.1` and closed the
  task tree.
- Runtime division and modulo expressions now fail closed when a divisor names
  a same-transaction scalar parameter default that resolves to zero.
- Transaction-local names shadow actor-level static names in the owning
  transaction expression context.
- Nonzero same-transaction parameter divisors, nonzero actor-parameter
  divisors, dynamic scalar divisors, nonzero actor constants, and nonzero
  literals keep their shipped behavior; arbitrary dynamic nonzero proof and
  use-site-specialized parameter divisor proof remain deferred.
- Validation passed: syntax checks; focused dynamic-divisor/public-doc tests
  with `Files=6, Tests=360`; `./bin/ci-regression isf --no-book` with
  `Files=275, Tests=1754`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Static timing override gates shipped
- Completed `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.1` and closed the
  task tree.
- Generated child activation overrides on `spawn`, generated blocking `do`,
  and rule `trigger` now fail closed when they would change a child
  transaction parameter consumed by repeat, wait, latency, or top-level
  await-local watchdog lowering.
- Same-value overrides remain accepted because the child scheduled `.fsm`
  stays default-resolved; full per-activation static timing specialization
  remains deferred.
- Validation passed: syntax checks; focused timing/activation/public-audit
  tests with `Files=15, Tests=450`; `./bin/ci-regression isf --no-book` with
  `Files=275, Tests=1751`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Static timing fail-closed checklist synchronized
- Completed `ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.1` and closed the
  task tree.
- Synchronized the downstream fail-closed checklist after the shipped
  transaction-parameter repeat, wait, latency, and top-level await-local
  watchdog slices.
- The checklist now distinguishes shipped same-transaction latency and
  top-level await-local watchdog parameter sources from still-invalid
  actor-level, nested control-flow, cross-transaction, zero, and non-scalar
  parameter sources.
- Parser behavior, scheduler lowering, generated `.fsm`, HDL, schedule-report
  payloads, public API, and runtime behavior did not change.
- Validation passed: focused spec/book/backlog audits with `Files=4,
  Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Watchdog transaction parameter limits shipped
- Completed `ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.1` and closed the task tree.
- Top-level await-local `(watchdog PARAM)` now accepts same-transaction scalar
  parameter defaults when they resolve to positive integer literals.
- Transaction watchdog params shadow actor-level static names in the
  top-level await-local watchdog slot and remain local lowering inputs; the
  resolved integer drives the existing watchdog counter width and init path.
- Zero-valued, aggregate/list, actor-level, and cross-transaction parameter
  watchdog limits fail closed before scheduled `.fsm` emission; dynamic
  watchdog limits and per-await counter specialization remain unsupported.
- Validation passed: syntax checks; focused watchdog/parameter/public-audit
  tests with `Files=16, Tests=459`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1748`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Latency transaction parameter bounds shipped
- Completed `ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.1` and closed the task tree.
- Transaction `(latency (min PARAM) (max PARAM))` now accepts same-transaction
  scalar parameter defaults when they resolve to positive integer literals.
- Transaction latency-bound params shadow actor-level static names and remain
  local lowering inputs; the resolved integer drives the existing latency
  counter guard, timeout check, and `min <= max` validation.
- Zero-valued, aggregate/list, and cross-transaction parameter latency bounds
  fail closed before scheduled `.fsm` emission; activation-site override
  specialization remains unsupported.
- Validation passed: syntax checks; focused latency/parameter/public-audit
  tests with `Files=16, Tests=455`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1747`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Wait transaction parameter counts shipped
- Completed `ISF-WAIT-TRANSACTION-PARAM-COUNTS.1` and closed the task tree.
- `(wait COUNT)` now accepts `COUNT` when it names a same-transaction scalar
  parameter default that resolves to a non-negative integer literal.
- Transaction wait-count params shadow actor-level static names and remain
  local lowering inputs; positive values emit fixed wait-state chains, and
  zero values keep the existing no-state/no-report zero-wait semantics.
- Aggregate/list transaction params fail closed before scheduled `.fsm`
  emission; cross-transaction params and activation-site override
  specialization remain unsupported.
- Validation passed: syntax checks; focused wait/parameter/public-audit tests
  with `Files=16, Tests=488`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1746`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Repeat transaction parameter counts shipped
- Completed `ISF-REPEAT-TRANSACTION-PARAM-COUNTS.1` and closed the task tree.
- `(repeat COUNT body...)` now accepts `COUNT` when it names a
  same-transaction scalar parameter default that resolves to a positive
  integer.
- Transaction repeat-count params shadow actor-level static names, provide
  counter-width evidence from the resolved positive integer, and load that
  resolved integer in scheduled `.fsm`.
- Zero-valued transaction params and aggregate/list transaction params fail
  closed before scheduled `.fsm` emission; cross-transaction params remain
  unsupported.
- Validation passed: syntax checks; focused repeat/parameter-surface tests
  with `Files=7, Tests=80`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1745`; focused public/spec/book audits with `Files=4,
  Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Active lane status synchronized
- Completed `ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.1` and closed the task tree.
- The detailed `Current active lane` recovery section in `ROADMAP_STATUS.md`
  no longer points at an older direct/local rule-trigger diagnostic as the
  latest active-lane completion.
- The head of the detailed R14 `Done` section now records the latest generated
  `do` timing coverage, binding timing history sync, rule-trigger output
  history sync, and direct entry-parameter diagnostic closures.
- This is documentation-only truth synchronization; parser behavior, scheduler
  lowering, generated `.fsm`, HDL, schedule-report payloads, public contract
  code, tests, and runtime behavior did not change.
- Validation passed: focused live-doc/book audits; `mdbook build docs/book`;
  and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Generated do binding timing coverage completed
- Completed `ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.1` and closed the task
  tree.
- Generated blocking `do` input bindings now have explicit regression coverage
  for accepted `(timing live)` assertions and report metadata:
  `binding_timing => generated_live_handoff` plus
  `authored_timing_mode => live`.
- Generated blocking `do` input bindings that request `(timing snapshot)` now
  have direct fail-closed mismatch coverage against the current generated-live
  transfer class.
- This is coverage-only behavior preservation; parser behavior, scheduler
  lowering, generated `.fsm`, HDL, schedule-report schema, public contract
  code, and runtime behavior did not change.
- Validation passed: syntax check; focused transaction-port binding test;
  focused port-binding/report/spec/book audits; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Binding timing history synchronized
- Completed `ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.1` and closed
  the task tree.
- Older recovery notes no longer imply all snapshot/live binding timing syntax
  is deferred.
- The docs now distinguish later shipped current-timing
  `(timing snapshot|live)` assertions and `authored_timing_mode` report
  metadata from deferred behavior-changing snapshot/live timing conversion.
- This is documentation-only truth synchronization; parser behavior, scheduler
  lowering, generated `.fsm`, HDL, schedule-report payloads, public contract
  code, and runtime behavior did not change.
- Validation passed: stale timing wording grep confirmed remaining matches are
  historical task non-goals or explicit behavior-conversion deferrals; focused
  live-doc/book audits with `Files=4, Tests=366`; `mdbook build docs/book`;
  and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Rule-trigger output history synchronized
- Completed `ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.1` and
  closed the task tree.
- Current mdBook activation-parameter wording and older recovery notes no
  longer imply all rule-trigger output bindings are unsupported.
- The docs now distinguish later shipped scalar generated-child rule-trigger
  output bindings from deferred direct/local rule-trigger output bindings.
- This is documentation-only truth synchronization; parser behavior, scheduler
  lowering, generated `.fsm`, HDL, schedule-report payloads, public contract
  code, and runtime behavior did not change.
- Validation passed: stale broad-output wording grep confirmed remaining
  matches are direct/local deferrals; focused live-doc/book audits with
  `Files=4, Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Direct entry parameter diagnostic hardened
- Completed `ISF-DIRECT-ON-PARAM-DIAGNOSTIC.1` and closed the task tree.
- Direct `(on start (params ...))` still fails before scheduled `.fsm`
  emission, but the diagnostic now says direct `(on ...)` activation is an
  entry guard, not a generated activation-site parameter override.
- Legal `(on start (sample ...))` behavior is unchanged.
- This is fail-closed diagnostic hardening; generated `.fsm`, HDL,
  schedule-report schema, public API, and runtime behavior for accepted
  sources did not change.
- Validation passed: syntax checks; focused sample/public-doc/book tests with
  `Files=7, Tests=375`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Port-binding historical recovery notes synchronized
- Completed `ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.1` and closed
  the task tree.
- Older `ISF-PORT-BINDING.5` recovery notes now point to later shipped slices
  for expression-valued input bindings, generated-child rule-trigger output
  bindings, explicit current-timing assertions, endpoint-kind metadata,
  binding-timing metadata, authored timing-mode metadata, and targeted
  duplicate output diagnostics.
- This is documentation-only truth synchronization; parser behavior,
  scheduler lowering, generated `.fsm`, HDL, schedule-report payloads, public
  contract code, and runtime behavior did not change.
- Validation passed: recovery-doc grep; public contract/spec/book audits with
  `Files=4, Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Rule-trigger duplicate output target diagnostic shipped
- Completed
  `ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1` and closed the task
  tree.
- Within one rule, multiple generated-child rule-trigger output bindings that
  target the same actor signal now fail closed before scheduled `.fsm`
  emission.
- Generated rule-trigger output bindings to distinct actor targets remain
  accepted, and direct/local rule-trigger output bindings still fail closed
  with the missing generated-child completion identity diagnostic.
- This is a fail-closed diagnostic hardening slice; generated `.fsm`, HDL,
  schedule-report schema, public API, and runtime behavior for accepted
  sources did not change.
- Validation passed: syntax checks; focused rule-trigger/port-binding/report
  and spec/book tests with `Files=8, Tests=386`; final live-doc/book audits
  with `Files=4, Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Binding report wording truth sync completed
- Completed
  `ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.1` and closed the
  task tree.
- Public contract and mdBook wording now distinguish deferred future
  binding-report expansions from the already-shipped bounded
  `transaction_port_bindings[]` summary fields, including `actor_signal`,
  `actor_expression`, endpoint kind, binding timing, and authored timing mode.
- This is documentation-only truth synchronization; parser behavior,
  scheduler lowering, generated `.fsm`, HDL, schedule-report payloads, public
  contract code, and runtime behavior did not change.
- Validation passed: public contract/spec/book audits with `Files=4,
  Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Duplicate output binding target diagnostic shipped
- Completed
  `ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.1` and
  closed the task tree.
- Multiple output bindings in one activation bind block that target the same
  actor signal now fail closed before scheduled `.fsm` emission.
- Input binding fan-out and accepted single-output binding behavior are
  unchanged.
- This is a fail-closed diagnostic hardening slice; generated `.fsm`, HDL,
  schedule-report schema, public API, and runtime behavior for accepted
  sources did not change.
- Validation passed: syntax checks; focused transaction-port/conflict/spec/book
  tests with `Files=7, Tests=381`; final live-doc/book audits with
  `Files=4, Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Local rule-trigger output diagnostic hardened
- Completed `ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.1` and closed
  the task tree.
- Direct/local rule-trigger output bindings still fail closed, but the
  diagnostic now says output bindings require a generated-child rule trigger
  completion identity and that direct/local targets do not provide one yet.
- Generated-child rule-trigger output-binding behavior is unchanged.
- This is diagnostic/docs only; scheduler lowering, generated `.fsm`, HDL,
  schedule-report schema, public API, and runtime behavior did not change.
- Validation passed: syntax checks; focused transaction-port/report/book
  tests with `Files=6, Tests=376`; conflict/golden checks with `Files=2,
  Tests=7`; final live-doc/book audits with `Files=4, Tests=366`; `mdbook
  build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 Documentation Truth Sync — Authored timing metadata wording completed
- Completed `ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.1` and closed the
  task tree.
- Updated stale ISF spec and mdBook feature-matrix non-claim wording so the
  shipped binding-report boundary names endpoint-kind, binding-timing, and
  authored timing-mode metadata.
- This was documentation-only truth synchronization; no parser behavior,
  scheduler lowering, generated `.fsm`, HDL, schedule-report payloads, public
  API, or runtime behavior changed.
- Validation passed: live spec/book audits with `Files=4, Tests=366`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Authored binding timing metadata shipped
- Completed `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.2` and
  closed the task tree.
- Every public `transaction_port_bindings[]` schedule-report entry now carries
  `authored_timing_mode`.
- Values are `snapshot` or `live` when the source binding explicitly spells
  `(timing snapshot)` or `(timing live)`, and JSON null when no explicit
  timing clause was authored, including output bindings.
- This is additive report/source-provenance metadata only; parser behavior,
  binding timing, scheduler lowering, generated `.fsm`, HDL, schema version,
  and runtime behavior did not change.
- Validation passed: syntax checks; focused report/public-contract/spec/book
  tests with `Files=12, Tests=392`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1743`; final live-doc/book audits with `Files=4,
  Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Authored binding timing metadata tree selected
- Created active task tree
  `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA`.
- Completed selection leaf
  `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.1`; the next
  implementation frontier is
  `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.2`.
- Selected public report key `authored_timing_mode` for
  `transaction_port_bindings[]` entries.
- The selected field will report `snapshot` or `live` when the source binding
  explicitly spells `(timing snapshot)` or `(timing live)`, and JSON `null`
  when no explicit timing clause was authored, including output bindings.
- This selection does not change parser behavior, scheduler lowering,
  generated `.fsm`, HDL, schedule-report payloads, schema version, public API,
  or runtime behavior yet.
- Validation passed: feature-backlog/live-book/book matrix audits; `mdbook
  build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA`.
- Current frontier: `ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.2`.

## 2026-05-25: R14 — Binding timing syntax shipped
- Completed `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.2` and closed the
  task tree.
- Input bindings on `do`, `spawn`, and rule `trigger` now accept explicit
  current-timing assertions: `(timing snapshot)` for activation-region or
  trigger-payload capture, and `(timing live)` for generated-top live handoff
  wiring.
- Mismatched timing mode/site combinations, malformed timing clauses, and
  timing clauses on output bindings fail closed.
- This changes syntax validation only; scheduler lowering, generated `.fsm`,
  HDL, schedule-report schema, `binding_timing` values, and runtime behavior
  did not change.
- Validation passed: syntax checks; focused transaction-port/spec/book tests
  with `Files=8, Tests=382`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1743`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Binding timing syntax tree selected
- Created active task tree `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX`.
- Completed selection leaf
  `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.1`; the next implementation
  frontier is `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.2`.
- Selected per-input-binding syntax:
  `(input PORT EXPR (timing snapshot))` and
  `(input PORT EXPR (timing live))`.
- The first implementation boundary is current-timing-only: accept explicit
  spelling only where it matches shipped binding timing, reject mismatches,
  and do not change scheduler lowering, generated `.fsm`, HDL, schedule-report
  schema, or runtime behavior.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX`.
- Current frontier: `ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.2`.

## 2026-05-25: R14 — Binding timing metadata shipped
- Completed `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.2` and closed the
  task tree.
- Every public `transaction_port_bindings[]` schedule-report entry now carries
  `binding_timing`.
- Values are `activation_region`, `generated_live_handoff`,
  `trigger_payload`, and `done_guarded`.
- This is additive report metadata only; ISF syntax, binding timing,
  scheduler lowering, generated `.fsm`, HDL, schema version, and runtime
  behavior did not change.
- Validation passed: syntax checks; focused report/public-contract/spec/book
  tests with `Files=11, Tests=386`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1742`; final live-doc/book audits with `Files=4,
  Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Binding timing metadata tree selected
- Created active task tree
  `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA`.
- Completed selection leaf
  `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.1`; the next implementation
  frontier is `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.2`.
- Selected public schedule-report key `binding_timing` for
  `transaction_port_bindings[]` entries.
- Selected bounded values: `activation_region`, `generated_live_handoff`,
  `trigger_payload`, and `done_guarded`.
- This selection does not change parser, scheduler, generated `.fsm`, HDL,
  schedule-report payloads, public API, or runtime behavior yet.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA`.
- Current frontier: `ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.2`.

## 2026-05-25: R14 Roadmap Maintenance — Latest slice truth sync completed
- Completed `ROADMAP-R14-LATEST-SLICE-TRUTH-SYNC.1` and closed the task tree.
- Synchronized the lower [ROADMAP_STATUS.md](ROADMAP_STATUS.md)
  current-active-lane summary with the latest completed R14 slice,
  `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2`.
- This is documentation-only roadmap maintenance; no parser, scheduler,
  generated `.fsm`, HDL, schedule-report, public API, or runtime behavior
  changed.
- Validation passed: `mdbook build docs/book`; current-active-lane roadmap
  audit; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Generated rule-trigger output bindings shipped
- Completed `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2` and closed the
  task tree.
- Generated-child rule triggers now accept scalar output bindings for declared
  output ports when the actor target is writable, same-domain, and
  width-compatible.
- The generated trigger handoff DT copies the child output handoff into the
  actor target under that trigger instance's `*_done_seen` observer, while the
  rule remains non-blocking.
- `transaction_port_bindings[]` entries for generated rule-trigger output
  bindings report the done observer in `done_signal`.
- Direct/local transaction rule-trigger output bindings remain fail-closed
  until a separate completion-identity contract is selected.
- Validation passed: syntax checks; focused public/report/spec/book tests with
  `Files=13, Tests=396`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1742`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Generated rule-trigger output-binding tree selected
- Created active task tree
  `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS`.
- Completed selection leaf
  `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.1`; the next implementation
  frontier is `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2`.
- The selected surface is generated-child rule-trigger output bindings only,
  using the unique generated instance and completion observation for the
  output-copy identity.
- Direct/local transaction rule-trigger output bindings remain fail-closed
  until a separate task selects a safe completion-identity contract.
- This selection slice does not change parser behavior, scheduler lowering,
  generated `.fsm`, HDL, public syntax, runtime behavior, or schedule-report
  payloads yet.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS`.
- Current frontier: `ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.2`.

## 2026-05-25: Bootstrap — import tree snapshot refreshed
- Completed the README/SESSION_BOOTSTRAP startup import-tree refresh.
- Rebuilt the source-derived [bin/fsmgen](bin/fsmgen) transitive
  project-owned `FSM::...` closure.
- Refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](docs/BIN_FSMGEN_IMPORT_TREE.md)
  to the current `196` reachable project files / `195` reachable `.pm`
  packages snapshot.
- Updated the measured direct import list and current largest-file hotspot
  read for the R14
  [perl/FSM/Scheduler/ISF/LoweringIR.pm](perl/FSM/Scheduler/ISF/LoweringIR.pm)
  and [perl/FSM/Adapter/ISF/Parser.pm](perl/FSM/Adapter/ISF/Parser.pm)
  owners.
- This was documentation-only bootstrap maintenance; no parser, scheduler,
  generated `.fsm`, HDL, CLI behavior, public API, schedule-report payload, or
  mdBook user-facing behavior changed.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Transaction-port binding endpoint-kind reports shipped
- Completed `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2` and closed the
  task tree.
- Public `transaction_port_bindings[]` schedule-report entries now include
  `actor_endpoint_kind`.
- Values are `signal` for scalar actor-side endpoints, `literal` for numeric
  or exact-width input operands, and `expression` for non-empty
  list-expression input operands.
- This is additive report metadata only; ISF syntax, binding timing, generated
  `.fsm`, HDL lowering, schema version, raw `LoweringIR` exposure, and
  rule-trigger output-binding behavior did not change.
- Validation passed: syntax checks; focused public/report/spec/book tests
  with `Files=8, Tests=344`; schedule-report freeze-boundary rerun with
  `Files=5, Tests=11`; `./bin/ci-regression isf --no-book` with `Files=274,
  Tests=1740`; final live-doc/book audits; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Transaction-port binding endpoint-kind report tree selected
- Created active task tree
  `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS`.
- Completed selection leaf
  `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.1`; the next implementation
  frontier is `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2`.
- The selected additive schedule-report field is
  `transaction_port_bindings[].actor_endpoint_kind`, with values `signal`,
  `literal`, and `expression`.
- This selection slice does not change parser behavior, scheduler lowering,
  generated `.fsm`, HDL, public syntax, runtime behavior, or schedule-report
  payloads yet.
- Active task tree: `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS`.
- Current frontier: `ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.2`.

## 2026-05-25: R14 — Direct transaction-parameter transaction-port widths shipped
- Completed `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.3` and closed the
  task tree.
- Direct/non-generated transactions now accept same-transaction scalar
  parameter defaults in transaction-local input/output port width options when
  the resolved default is a positive integer.
- Direct transaction parameter declarations are accepted only when at least
  one transaction-local port width references a declared same-transaction
  parameter; unrelated direct transaction parameters still fail closed.
- Transaction-local names resolve before actor constants and actor parameters,
  and a port-width transaction parameter may derive from an earlier scalar
  transaction parameter default.
- Cross-transaction parameters, zero or aggregate transaction parameters,
  forward/self/cyclic defaults, runtime signals, expressions,
  activation-site override specialization, generated-top respecialization,
  and schedule-report key-family changes remain deferred or fail-closed.
- Validation passed: syntax checks; focused transaction-port/public/spec/book
  tests with `Files=18, Tests=453`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1739`; live-doc/book audits with `Files=3, Tests=364`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Generated-child transaction-parameter transaction-port widths shipped
- Completed `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2`.
- Generated child transactions now accept same-transaction scalar parameter
  defaults in transaction-local input/output port width options when the
  resolved default is a positive integer.
- The resolved integer width flows through parser handoff, scheduled generated
  child `.fsm` `+size` declarations, generated parent handoff storage,
  `transaction_port_bindings[]` report widths, and HDL port/register ranges.
- Transaction-local names resolve before actor constants and actor parameters,
  and a port-width transaction parameter may derive from an earlier scalar
  transaction parameter default.
- Direct/non-generated transaction parameter port widths remain the active
  frontier; cross-transaction parameters, zero or aggregate transaction
  parameters, forward/self/cyclic defaults, runtime signals, expressions,
  activation-site override specialization, generated-top respecialization,
  and schedule-report key-family changes remain deferred or fail-closed.
- Validation passed: syntax checks; focused transaction-port/public/spec/book
  tests with `Files=13, Tests=382`; `./bin/ci-regression isf --no-book` with
  `Files=274, Tests=1738`; live-doc/book audits with `Files=3, Tests=364`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS`.
- Current frontier: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.3`.

## 2026-05-25: R14 — Transaction-parameter transaction-port width tree selected
- Created active task tree
  `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS`.
- Completed selection leaf
  `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.1`; the next implementation
  frontier is `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2`.
- The selected surface will allow same-transaction scalar parameter defaults
  to act as transaction-local input/output port width evidence when the
  resolved default is a positive integer.
- The implementation sequence is generated-child first, then direct/non-
  generated transaction validation. Activation-site override specialization,
  generated-top respecialization, aggregate/list parameters, runtime signals,
  arbitrary expressions, and schedule-report key-family changes remain
  deferred.
- No parser, scheduler, generated `.fsm`, HDL, schedule-report, public API, or
  runtime behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS`.
- Current frontier: `ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.2`.

## 2026-05-25: Roadmap Maintenance — This-commit task evidence truth sync completed
- Completed `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2` and closed the task
  tree.
- Completed, closed, and done task files no longer carry stale `this commit`
  commit evidence or stale `final gate pending` verification evidence in the
  audited fields.
- Evidence was resolved from git history by preferring commits whose subject
  starts with the task leaf ID.
- This was documentation-only maintenance; no parser, scheduler, generated
  `.fsm`, HDL, schedule-report, public API, or runtime behavior changed.
- Validation passed: this-commit/final-gate field audit;
  feature-backlog/live-book/book matrix audits with `Files=3, Tests=351`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: Roadmap Maintenance — This-commit task evidence truth sync selected
- Created active task tree `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC`.
- Completed selection leaf `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.1`; the
  next frontier is `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2`.
- The selected repair will audit completed task files and replace stale
  `this commit` placeholders and stale `final gate pending` verification
  wording with concrete completion evidence where recoverable.
- This is documentation-only maintenance; no parser, scheduler, generated
  `.fsm`, HDL, schedule-report, public API, or runtime behavior changed.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=351`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC`.
- Current frontier: `TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.2`.

## 2026-05-25: Roadmap Maintenance — Task-tree commit evidence truth sync completed
- Completed `TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.2` and closed the task tree.
- Completed task files no longer carry stale `pending commit`, `pending this
  commit`, `pending commit hash`, `pending commit workflow`, or exact
  `pending` commit-log rows in the audited evidence fields.
- Remaining pending wording is scoped to descriptive repair-scope prose,
  templates/workflow examples, or semantic feature wording such as
  pending-sample behavior.
- This was documentation-only maintenance; no parser, scheduler, generated
  `.fsm`, HDL, schedule-report, public API, or runtime behavior changed.
- Validation passed: stale-evidence field audit; malformed-row audit;
  feature-backlog/live-book/book matrix audits with `Files=3, Tests=351`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Direct transaction-parameter data-operation widths shipped
- Completed `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3` and closed the task
  tree.
- Direct/non-generated `shift_left`/`shift_right` `(width TX_PARAM)` and
  `extract`/`assemble` `(widths TX_PARAM...)` now accept same-transaction
  scalar parameter defaults when the resolved default is a positive integer.
- Direct transaction parameter declarations are accepted only when at least
  one data-operation width option references a declared same-transaction
  parameter; unrelated direct transaction parameters still fail closed.
- Transaction-local parameter names keep precedence before actor constants and
  actor parameters for this data-operation width value-domain slot.
- Aggregate/list defaults, zero-valued defaults, runtime signals, arbitrary
  expressions, activation-site override specialization, generated child
  variants, generated-top respecialization, and schedule-report key-family
  changes remain deferred.
- Validation passed: syntax checks; focused data-operation/public/spec/book
  tests with `Files=13, Tests=447`; `./bin/ci-regression isf --no-book` with
  `Files=273, Tests=1735`; final status/spec/book audits with `Files=4,
  Tests=366`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Generated-child transaction-parameter data-operation widths shipped
- Completed `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2`.
- Generated child `shift_left`/`shift_right` `(width TX_PARAM)` and
  `extract`/`assemble` `(widths TX_PARAM...)` now accept same-transaction
  scalar parameter defaults when the resolved default is a positive integer.
- Transaction-local parameter names resolve before actor constants and actor
  parameters for this data-operation width value-domain slot.
- Direct/non-generated transaction parameters remain fail-closed for
  data-operation width evidence, including direct transactions whose params
  are legal for temporal contract windows.
- Aggregate/list defaults, zero-valued defaults, runtime signals, arbitrary
  expressions, activation-site override specialization, generated child
  variants, generated-top respecialization, and schedule-report key-family
  changes remain deferred.
- Validation passed: syntax checks; focused data-operation/public/spec/book
  and boundary test runs totaling `Files=16, Tests=405`;
  `./bin/ci-regression isf --no-book` with `Files=273, Tests=1734`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS`.
- Current frontier: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.3`.

## 2026-05-25: R14 — Transaction-parameter data-operation width tree selected
- Created active task tree `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS`.
- Completed selection leaf `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.1`; the next
  implementation frontier is `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2`.
- The selected surface will allow same-transaction scalar parameter defaults
  to act as explicit data-operation width evidence for
  `shift_left`/`shift_right` `(width PARAM)` and
  `extract`/`assemble` `(widths PARAM...)` when the resolved default is a
  positive integer.
- The implementation sequence is generated-child first, then direct
  transaction validation. Activation-site override specialization,
  generated-top respecialization, aggregate/list parameters, runtime signals,
  arbitrary expressions, and schedule-report key-family changes remain
  deferred.
- No parser, scheduler, generated `.fsm`, HDL, schedule-report, public API, or
  runtime behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS`.
- Current frontier: `ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.2`.

## 2026-05-25: R14 — Same-value activation override contract-window support shipped
- Completed `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.2` and closed the
  task tree.
- Generated child activation-site overrides on `spawn`, generated blocking
  `do`, and rule `trigger` now accept a parameter override that targets a child
  temporal contract-window parameter when the override resolves to the same
  positive integer cycle count as the child transaction parameter default.
- Mismatched override values still fail closed with the targeted
  override-specialized contract-window diagnostic.
- Unknown override names and parameter-shape mismatches keep their existing
  diagnostic precedence.
- Generated child contract monitors and schedule reports remain
  default-resolved; no generated child variant module, report key, schema
  version, HDL projection, or public API shape changed.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused contract/public/spec/book tests
  with `Files=13, Tests=453`; `./bin/ci-regression isf --no-book` with
  `Files=272, Tests=1732`; final public/spec/book audits with `Files=5,
  Tests=368`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Same-value activation override contract-window slice selected
- Created active task tree `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE`.
- Completed `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.1`; the selected
  implementation frontier is
  `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.2`.
- The selected slice will accept activation-site overrides of generated child
  contract-window parameters only when the override resolves to the same
  positive integer cycle count as the child transaction parameter default.
- Mismatched override values remain fail-closed until full per-activation
  temporal monitor specialization is deliberately selected.
- The selection does not change parser, scheduler, generated `.fsm`, HDL,
  schedule-report, public API, or runtime behavior.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE`.
- Current frontier: `ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.2`.

## 2026-05-25: R14 — Activation override roadmap truth sync completed
- Completed `ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.1` and closed the
  one-leaf documentation truth-sync task tree.
- The lower R14 `Done` detail now includes the shipped
  `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2` diagnostic behavior.
- The R14 ISF objective coverage table now maps activation-site override
  diagnostics for generated child temporal contract-window parameters to
  `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS`.
- This was documentation-only roadmap maintenance; no parser, scheduler,
  generated `.fsm`, HDL, schedule-report, or public API behavior changed.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Activation override contract-window diagnostics shipped
- Completed `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2` and closed the task
  tree.
- Generated child activation-site parameter overrides now fail closed with a
  targeted diagnostic when `spawn`, generated blocking `do`, or rule
  `trigger` overrides a child transaction parameter used by that child
  transaction's bounded eventual temporal-contract window.
- The diagnostic runs after existing unknown-parameter and parameter-shape
  checks, so those earlier diagnostics remain stable.
- Overrides of generated child parameters that are not used by temporal
  contract windows remain accepted, and generated child contract windows with
  no activation override continue to lower from the transaction definition's
  resolved default.
- Full per-activation override-specialized temporal monitor lowering remains
  deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused contract/public/spec/book tests
  with `Files=13, Tests=452`; `./bin/ci-regression isf --no-book` with
  `Files=272, Tests=1731`; post-closure public/spec/book audits with
  `Files=5, Tests=368`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Activation override contract-window diagnostics selected
- Created active task tree `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS`.
- Completed `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.1`; the selected
  implementation frontier is
  `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2`.
- The selected slice will fail closed with targeted diagnostics when a
  `spawn`, generated child `do`, or rule `trigger` activation-site parameter
  override targets a generated child transaction parameter used by the target
  transaction's bounded eventual temporal-contract window.
- Use-site temporal monitor respecialization remains deferred. The selection
  deliberately does not respecialize generated child `.fsm` contract windows
  per activation site, generated top, instance, or trigger edge.
- Generated child transaction parameter contract windows with no activation
  override stay on the already shipped resolved-default path, and unrelated
  activation-site overrides should remain accepted.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS`.
- Current frontier: `ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.2`.

## 2026-05-25: R14 — Direct transaction contract parameter windows shipped
- Completed `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.2` and closed the
  task tree.
- Direct/non-generated bounded eventual temporal-contract windows now accept
  same-transaction scalar parameter defaults in both supported spellings:
  `(eventually SIGNAL within PARAM)` and
  `(eventually SIGNAL (within PARAM))`.
- Direct transaction `(params ...)` clauses are accepted only when at least
  one same-transaction temporal contract window references a declared
  parameter; unrelated direct transaction params still fail closed.
- Accepted direct transaction parameters reuse the existing temporal monitor
  lowering used by positive literals, actor constants, actor-local scalar
  parameter defaults, qualified package scalar constants, and generated child
  transaction scalar parameter defaults. Monitor timing, sticky-fail behavior,
  reset behavior, and SystemVerilog assertion projection are unchanged.
- Transaction-local parameter names resolve before actor constants and actor
  parameters in this value-domain slot, so direct transaction parameters
  shadow actor-level static names for contract windows.
- Schedule reports keep `temporal_contracts[].within_cycles` as the resolved
  positive integer and do not add a source-token field. Direct transaction
  parameters remain local lowering inputs and are not emitted as actor-level
  `.fsm` `+params`.
- Activation-site parameter override specialization, transaction parameters
  from other transactions, non-scalar aggregate/list transaction parameters,
  forward/self/cyclic transaction parameter defaults, runtime signals,
  arbitrary expressions, dynamic bounds, min/max windows, same-cycle checks,
  nested contracts, expression operands, global implication forms, multiple
  outstanding obligations, and transaction-parameter use in other value
  domains remain deferred or fail closed.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused contract/public/spec/book tests
  with `Files=11, Tests=447`; `./bin/ci-regression isf --no-book` with
  `Files=271, Tests=1729`; post-closure public/spec/book audits with
  `Files=5, Tests=368`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Direct transaction contract parameter windows selected
- Created active task tree `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS`.
- Completed `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.1`; the selected
  implementation frontier is
  `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.2`.
- The selected widening will allow direct/non-generated transaction bounded
  eventual temporal-contract `(eventually SIGNAL within PARAM)` windows, plus
  the nested `(within PARAM)` alias, to use same-transaction scalar parameter
  defaults when the resolved default is a positive integer literal.
- Accepted direct transaction-parameter windows should reuse the existing
  temporal monitor lowering used by positive literals, actor constants,
  actor-local scalar parameter defaults, qualified package scalar constants,
  and generated child transaction scalar parameter defaults.
- Schedule reports should keep `temporal_contracts[].within_cycles` as the
  resolved integer without adding a source-token field.
- Activation-site parameter override specialization, transaction parameters
  from other transactions, non-scalar aggregate/list transaction parameters,
  forward/self/cyclic transaction parameter defaults, runtime signals,
  arbitrary expressions, dynamic bounds, min/max windows, same-cycle checks,
  nested contracts, expression operands, global implication forms, multiple
  outstanding obligations, and transaction-parameter use in other value
  domains remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS`.
- Current frontier: `ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.2`.

## 2026-05-25: R14 — Temporal-contract transaction-parameter windows shipped
- Completed `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2` and closed the task
  tree.
- Generated child bounded eventual temporal-contract windows now accept
  same-transaction scalar parameter defaults in both supported spellings:
  `(eventually SIGNAL within PARAM)` and
  `(eventually SIGNAL (within PARAM))`.
- Accepted generated child transaction parameters require a parameter declared
  on the same generated child transaction and a resolved positive integer
  scalar literal default.
- Accepted transaction parameters reuse the existing temporal monitor lowering
  used by positive literals, actor constants, actor-local scalar parameter
  defaults, and qualified package scalar constants. Monitor timing,
  sticky-fail behavior, reset behavior, and SystemVerilog assertion projection
  are unchanged.
- Transaction-local parameter names resolve before actor constants and actor
  parameters in this value-domain slot, so generated child parameters shadow
  actor-level static names for contract windows.
- Schedule reports keep `temporal_contracts[].within_cycles` as the resolved
  positive integer and do not add a source-token field. Generated child `.fsm`
  artifacts remain the review path for authored child `+params`.
- Direct/non-generated transaction parameter declarations, activation-site
  parameter override specialization, transaction parameters from other
  transactions, non-scalar aggregate/list transaction parameters,
  forward/self/cyclic transaction parameter defaults, runtime signals,
  arbitrary expressions, dynamic bounds, min/max windows, same-cycle checks,
  nested contracts, expression operands, global implication forms, and
  multiple outstanding obligations remain deferred or fail closed.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused contract/public/spec/book tests
  with `Files=10, Tests=388`; `./bin/ci-regression isf --no-book` with
  `Files=270, Tests=1726`; post-closure public/spec/book audits with
  `Files=5, Tests=368`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Temporal-contract transaction-parameter windows selected
- Created active task tree `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS`.
- Completed `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.1`; the selected
  implementation frontier is `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2`.
- The selected widening will allow bounded eventual temporal-contract
  `(eventually SIGNAL within PARAM)` windows, plus the nested
  `(within PARAM)` alias, to use same-transaction scalar parameter defaults
  when the resolved default is a positive integer literal.
- Accepted transaction-parameter windows should reuse the existing temporal
  monitor lowering used by positive literals, actor constants, actor-local
  scalar parameter defaults, and qualified package scalar constants.
- Schedule reports should keep `temporal_contracts[].within_cycles` as the
  resolved integer without adding a source-token field.
- Activation-site parameter override specialization, transaction parameters
  from other transactions, non-scalar aggregate/list transaction parameters,
  forward/self/cyclic transaction parameter defaults, runtime signals,
  arbitrary expressions, dynamic bounds, min/max windows, same-cycle checks,
  nested contracts, expression operands, global implication forms, and
  multiple outstanding obligations remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS`.
- Current frontier: `ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.2`.

## 2026-05-25: R14 — Watchdog package-constant limits shipped
- Completed `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2` and closed the task tree.
- Actor-level `(watchdog PACKAGE.CONSTANT)` and await-local
  `(await ready (watchdog PACKAGE.CONSTANT))` limits now accept qualified
  imported package scalar constants when the owning actor imports `PACKAGE`,
  the package declares `CONSTANT`, and the constant resolves to a positive
  integer scalar literal.
- Accepted package constants reuse the existing watchdog counter lowering used
  by positive literals, actor constants, and actor-local scalar parameter
  defaults. Generated counter widths and init values match the equivalent
  literal limit.
- Schedule reports and public parser shells keep watchdog limits as resolved
  integers without adding a source-token field. Package/import metadata and
  embedded package `+constants` entries remain the review path for authored
  package constants.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package member/item paths, ambiguous local-enum/package-constant
  spellings, zero-valued constants, package constants inside watchdog-limit
  expressions, transaction parameters, runtime signals, arbitrary
  expressions, package constants in unrelated value domains, use-site
  specialization, generated-top respecialization, distinct per-await limits in
  one transaction, cross-domain watchdog policy, dynamic watchdog limits, and
  per-await counter reset semantics remain fail closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused watchdog/public/spec/book tests
  with `Files=12, Tests=393`; `./bin/ci-regression isf --no-book` with
  `Files=269, Tests=1723`; post-closure public/spec/book audits with
  `Files=8, Tests=377`; `mdbook build docs/book`; final live-doc/book audits
  with `Files=3, Tests=364`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Watchdog package-constant limits selected
- Created active task tree `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS`.
- Completed `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.1`; the selected
  implementation frontier is `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2`.
- The selected widening will allow actor-level
  `(watchdog PACKAGE.CONSTANT)` and await-local
  `(await ready (watchdog PACKAGE.CONSTANT))` limits to use qualified imported
  package scalar constants when the resolved value is a positive integer
  literal.
- Accepted package-constant watchdog limits should reuse the existing
  watchdog counter lowering used by positive literals, actor constants, and
  actor-local scalar parameter defaults.
- Schedule reports and public parser shells should keep watchdog limits as
  resolved integers without adding a source-token field.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package member/item paths, transaction parameters, runtime
  signals, arbitrary expressions, package constants in unrelated value
  domains, reusable-library use-site specialization, generated-top
  respecialization, distinct per-await limits in one transaction,
  cross-domain watchdog policy, dynamic watchdog limits, and per-await
  counter reset semantics remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS`.
- Current frontier: `ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.2`.

## 2026-05-25: R14 — Temporal-contract package-constant windows shipped
- Completed `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.2` and closed the task tree.
- Bounded eventual temporal-contract windows now accept qualified imported
  package scalar constants in both supported spellings:
  `(eventually SIGNAL within PACKAGE.CONSTANT)` and
  `(eventually SIGNAL (within PACKAGE.CONSTANT))`.
- Accepted package constants require an imported package, an existing package
  `+constants` entry, and a resolved positive integer scalar literal.
- Accepted package constants reuse the existing temporal monitor path used by
  positive literals, actor constants, and actor-local scalar parameter
  defaults; monitor timing, sticky-fail behavior, reset behavior, and
  SystemVerilog assertion projection are unchanged.
- Schedule reports keep `temporal_contracts[].within_cycles` as the resolved
  positive integer and do not add a source-token field. Package/import
  metadata and embedded package `+constants` entries remain the review path
  for the authored package constant.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package member/item paths, ambiguous local-enum/package-constant
  spellings, zero-valued constants, package constants inside contract-window
  expressions, transaction parameters, runtime signals, arbitrary
  expressions, package constants in unrelated value domains, use-site
  specialization, generated-top respecialization, dynamic bounds, min/max
  windows, same-cycle checks, nested contracts, expression operands, global
  implication forms, and multiple outstanding obligations remain fail closed
  or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused contract/public/spec/book tests
  with `Files=9, Tests=385`; `./bin/ci-regression isf --no-book` with
  `Files=268, Tests=1721`; post-closure public/spec/book audits with
  `Files=7, Tests=374`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Temporal-contract package-constant windows selected
- Created active task tree `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS`.
- Completed `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.1`; the selected
  implementation frontier is `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.2`.
- The next implementation leaf will allow bounded eventual temporal-contract
  `(eventually SIGNAL within PACKAGE.CONSTANT)` windows, plus the nested
  `(within PACKAGE.CONSTANT)` alias, to use qualified imported package scalar
  constants when the resolved value is a positive integer literal.
- Accepted package-constant windows should reuse the existing temporal
  monitor lowering used by positive literals, actor constants, and actor-local
  scalar parameter defaults.
- Schedule reports should keep `temporal_contracts[].within_cycles` as the
  resolved integer without adding a source-token field.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package member/item paths, transaction parameters, runtime
  signals, arbitrary expressions, package constants in unrelated value
  domains, reusable-library use-site specialization, generated-top
  respecialization, dynamic bounds, min/max windows, same-cycle checks, nested
  contracts, expression operands, global implication forms, and multiple
  outstanding obligations remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS`.
- Current frontier: `ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.2`.

## 2026-05-25: R14 — Latency package-constant bounds shipped
- Completed `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2` and closed the task tree.
- Transaction `(latency (min PACKAGE.CONSTANT) (max PACKAGE.CONSTANT))`
  bounds now accept qualified imported package scalar constants when the
  owning actor imports `PACKAGE`, the package declares `CONSTANT`, and the
  constant resolves to a positive integer scalar literal.
- Accepted package constants reuse the existing static latency path used by
  positive literals, actor constants, and actor-local scalar parameter
  defaults.
- Generated `.fsm` guards, timeout checks, inferred counter widths, and
  report-visible latency counter storage match the equivalent literal bounds.
- Package constants resolving to zero keep the existing positive-only
  latency-bound policy and fail closed before latency counter emission.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package member/item paths, ambiguous local-enum/package-constant
  spellings, package constants inside latency-bound expressions, transaction
  parameters, runtime signals, arbitrary expressions, package constants in
  unrelated value domains, reusable-library use-site specialization,
  generated-top respecialization, stage-local latency, and actor-level stage
  runtime semantics remain fail closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused latency/public/spec/book tests
  with `Files=9, Tests=380`; `./bin/ci-regression isf --no-book` with
  `Files=267, Tests=1719`; post-closure public/spec/book audits with
  `Files=7, Tests=374`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Latency package-constant bounds selected
- Created active task tree `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS`.
- Completed `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.1`; the selected
  implementation frontier is `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2`.
- The next implementation leaf will allow transaction
  `(latency (min PACKAGE.CONSTANT) (max PACKAGE.CONSTANT))` bounds to use
  qualified imported package scalar constants when the resolved value is a
  positive integer literal.
- Accepted package-constant latency bounds should reuse the existing static
  latency path used by positive literals, actor constants, and actor-local
  scalar parameter defaults.
- Package constants resolving to zero should keep the existing positive-only
  latency-bound policy and fail closed before latency counter emission.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package member/item paths, transaction parameters, runtime
  signals, arbitrary expressions, package constants in unrelated value
  domains, reusable-library use-site specialization, generated-top
  respecialization, stage-local latency, and actor-level stage runtime
  semantics remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS`.
- Current frontier: `ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.2`.

## 2026-05-25: R14 — Repeat package-constant counts shipped
- Completed `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2` and closed the task tree.
- Static transaction `(repeat PACKAGE.CONSTANT body...)` counts now accept
  qualified imported package scalar constants when the owning actor imports
  `PACKAGE`, the package declares `CONSTANT`, and the constant resolves to a
  positive integer scalar literal.
- Accepted package constants reuse the existing static repeat counter-width
  path used by positive literals, actor constants, and actor-local scalar
  parameter defaults.
- The scheduled `.fsm` repeat-counter load preserves the authored
  `PACKAGE.CONSTANT` token while the repeat counter width uses the resolved
  positive integer.
- Package constants resolving to zero keep the existing static zero-count
  repeat policy and fail closed before scheduled `.fsm` emission.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package member/item paths, ambiguous local-enum/package-constant
  spellings, package constants inside repeat-count expressions, transaction
  parameters, runtime expressions, arbitrary expressions, package constants in
  other value domains, repeat-body child activation widening, cross-domain
  repeat behavior, generated-top respecialization, and repeat-body clause
  widening remain fail closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused repeat/public/spec/book tests with
  `Files=10, Tests=386`; `./bin/ci-regression isf --no-book` with
  `Files=266, Tests=1717`; post-closure public/spec/book audits with
  `Files=7, Tests=374`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Repeat package-constant counts selected
- Created active task tree `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS`.
- Completed `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.1`; the selected
  implementation frontier is `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2`.
- The next implementation leaf will allow static transaction
  `(repeat PACKAGE.CONSTANT body...)` counts to use qualified imported package
  scalar constants when the resolved value is a positive integer literal.
- Accepted package-constant repeat counts should reuse the existing static
  repeat counter-width path used by positive literals, actor constants, and
  actor-local scalar parameter defaults, while preserving the authored
  `PACKAGE.CONSTANT` token in the scheduled `.fsm` repeat-counter load.
- Package constants resolving to zero should keep the existing static
  zero-count repeat policy and fail closed before scheduled `.fsm` emission.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package member/item paths, transaction parameters, runtime
  expressions, arbitrary expressions, package constants in other value
  domains, repeat-body child activation widening, cross-domain repeat
  behavior, generated-top respecialization, and repeat-body clause widening
  remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS`.
- Current frontier: `ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.2`.

## 2026-05-25: R14 — Wait package-constant counts shipped
- Completed `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.2` and closed the task tree.
- Static transaction `(wait PACKAGE.CONSTANT)` counts now accept qualified
  imported package scalar constants when the owning actor imports `PACKAGE`,
  the package declares `CONSTANT`, and the constant resolves to a
  non-negative integer scalar literal.
- Accepted package-constant waits reuse the existing static wait path: zero
  counts remain transparent no-ops with no wait state or
  `transaction_waits[]` report entry, while positive counts emit fixed
  wait-state chains.
- Positive package-constant waits report `count_kind: static`, integer
  `cycles`, and the authored `PACKAGE.CONSTANT` token in `count_source`.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package member/item paths, ambiguous local-enum/package-constant
  spellings, package constants inside wait expressions, transaction
  parameters, runtime signals, arbitrary expressions, package constants in
  other value domains, generated-top respecialization, and runtime
  wait/pending-sample routing changes remain fail closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused wait/public/spec/book tests with
  `Files=8, Tests=398`; `./bin/ci-regression isf --no-book` with
  `Files=265, Tests=1715`; post-closure public/spec/book audits with
  `Files=7, Tests=374`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Wait package-constant counts selected
- Created active task tree `ISF-WAIT-PACKAGE-CONSTANT-COUNTS`.
- Completed `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.1`; the selected
  implementation frontier is `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.2`.
- The next implementation leaf will allow static transaction
  `(wait PACKAGE.CONSTANT)` counts to use qualified imported package scalar
  constants when the resolved value is a non-negative integer literal.
- Accepted package-constant waits should reuse the existing static wait path:
  zero counts remain transparent no-ops, positive counts emit fixed
  wait-state chains, and `transaction_waits[]` reports keep `count_kind:
  static`, integer `cycles`, and the authored `PACKAGE.CONSTANT` token in
  `count_source`.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package member/item paths, transaction parameters, runtime
  signals, arbitrary expressions, package constants in other value domains,
  generated-top respecialization, and runtime wait/pending-sample routing
  changes remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-WAIT-PACKAGE-CONSTANT-COUNTS`.
- Current frontier: `ISF-WAIT-PACKAGE-CONSTANT-COUNTS.2`.

## 2026-05-25: R14 — Data-operation package-constant widths shipped
- Completed `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.2` and closed the task
  tree.
- `shift_left` and `shift_right` `(width PACKAGE.CONSTANT)` options, plus
  `assemble` and `extract` `(widths PACKAGE.CONSTANT ...)` entries, now accept
  qualified imported package scalar constants when the owning actor imports
  `PACKAGE`, the package declares `CONSTANT`, and the constant resolves to a
  positive integer scalar literal.
- Accepted package constants publish through the existing scheduler
  width-evidence path: scheduled `.fsm` shift positions, assemble/extract
  width facts and slices, and `inferred_storage[]` report widths. Backend HDL
  register-range projection for inferred data-op storage remains outside this
  slice.
- Unknown package constants, unqualified package constants, aggregate package
  constants, package member/item paths, ambiguous local-enum/package-constant
  spellings, zero-valued constants, transaction parameters, runtime signals,
  arbitrary expressions, package constants in other value domains, and
  generated-top respecialization remain deferred or fail closed.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused data-op/public/spec/book tests
  with `Files=16, Tests=392`; `./bin/ci-regression isf --no-book` with
  `Files=264, Tests=1713`; post-closure public/spec/book audits with
  `Files=7, Tests=374`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Data-operation package-constant widths selected
- Created active task tree `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS`.
- Completed `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.1`; the selected
  implementation frontier is `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.2`.
- The next implementation leaf will allow explicit data-operation width
  evidence to use qualified imported package scalar constants when the
  resolved value is a positive integer: `shift_left` and `shift_right`
  `(width PACKAGE.CONSTANT)`, plus `assemble` and `extract` `(widths
  PACKAGE.CONSTANT ...)`.
- Accepted package-constant width evidence should publish through the
  resolved integer width path already used by positive literals, actor
  constants, and actor-local scalar parameter defaults.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package aggregate scalar-leaf paths, enum values, transaction
  parameters, runtime signals, arbitrary expressions, package constants in
  other value domains, and generated-top respecialization remain deferred or
  fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS`.
- Current frontier: `ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.2`.

## 2026-05-25: R14 — Transaction port package width book truth sync
- Completed `ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.1` and
  closed the documentation truth-sync task tree.
- Removed stale mdBook feature-backlog prose that still said package
  constants fail closed in transaction-local port width contexts.
- The current book now states that transaction-local port widths accept
  qualified imported package scalar constants when they resolve to positive
  integers, publish resolved parser handoff, scheduled `.fsm`,
  `transaction_port_bindings[]`, and HDL widths, and keep unsupported package
  shapes, zero values, runtime signals, and expressions fail-closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this documentation
  truth-sync slice.
- Validation passed: `mdbook build docs/book`;
  feature-backlog/live-book/book-matrix audits with `Files=3, Tests=364`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Transaction port package-constant widths shipped
- Completed `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2` and closed the
  task tree.
- Transaction-local `(ports ...)` declarations now accept
  `(input NAME (width PACKAGE.CONSTANT))` and
  `(output NAME (width PACKAGE.CONSTANT))` when the owning actor imports
  `PACKAGE`, the package declares `CONSTANT`, and the constant resolves to a
  positive integer scalar literal.
- Parser transaction-port width validation now accepts package-constant-shaped
  qualified tokens, resolves imported package scalar constants before
  actor-local parameter/constant fallback, and keeps package-specific
  diagnostics for unknown, unqualified, aggregate, member/item path,
  ambiguous, zero-valued, runtime, and expression-valued sources.
- Accepted package-constant transaction port widths publish as resolved
  integer widths in public parser handoff, scheduled `.fsm` activation
  handoff storage, `transaction_port_bindings[]` reports, CLI outdir review
  artifacts, and generated HDL register ranges.
- Transaction-parameter-backed widths, package aggregate/path widths, runtime
  interface signals, arbitrary expressions, package constants outside this
  transaction-port-width surface, and generated-top respecialization remain
  fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused transaction/package/public tests
  with `Files=13, Tests=360`; `./bin/ci-regression isf --no-book` with
  `Files=263, Tests=1711`; post-closure public/spec/book audits with
  `Files=6, Tests=359`; feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-25: R14 — Transaction port package-constant widths selected
- Created active task tree
  `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS`.
- Completed `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.1`; the selected
  implementation frontier is
  `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2`.
- The next implementation leaf will allow transaction-local
  `(input NAME (width PACKAGE.CONSTANT))` and
  `(output NAME (width PACKAGE.CONSTANT))` declarations inside
  `(ports ...)` to use qualified imported package scalar constants when the
  resolved value is a positive integer literal.
- Accepted package-constant transaction port widths should publish as
  resolved integer widths in parser handoff, scheduled `.fsm`, activation
  handoff storage, schedule reports, and generated HDL, matching existing
  actor-constant and actor-parameter transaction port width behavior.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  package constants in other dimension/value domains, and generated-top
  respecialization remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS`.
- Current frontier: `ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.2`.

## 2026-05-24: R14 — Bank storage package-constant depths shipped
- Completed `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2` and closed the task
  tree.
- Actor-owned bank storage
  `(bank NAME (width N|PARAM|CONST|PACKAGE.CONSTANT)
  (depth PACKAGE.CONSTANT))` declarations may now use qualified imported
  package scalar constants for bank depths when the resolved value is a
  positive integer literal.
- Parser bank-depth validation now accepts package-constant-shaped qualified
  tokens for actor-owned bank depths, so package-specific diagnostics can
  distinguish unknown, unqualified, aggregate, aggregate/member path,
  ambiguous, zero-valued, runtime, and expression-valued sources.
- Accepted package-constant bank depths publish as resolved integer depths in
  parser handoff, scalarized scheduled `.fsm` `+size`, schedule-report
  evidence, `bank_accesses[]` depth/scalar-entry evidence, and generated HDL
  register declarations.
- Package constants in transaction-local port widths, waits, watchdogs,
  latency bounds, contract windows, repeat counts, generated-top
  respecialization, and other dimensions/value domains remain deferred or
  fail closed.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused public/storage/package tests with
  `Files=11, Tests=35`; `./bin/ci-regression isf --no-book` with
  `Files=262, Tests=1709`; post-closure public/spec/book/backlog audits with
  `Files=8, Tests=375`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Bank storage package-constant depths selected
- Created active task tree `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS`.
- Completed `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.1`; the selected
  implementation frontier is `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2`.
- The next implementation leaf will allow actor-owned bank storage
  `(bank NAME (width N|PARAM|CONST) (depth PACKAGE.CONSTANT))` declarations
  to use qualified imported package scalar constants for bank depths when the
  resolved value is a positive integer literal.
- Accepted package-constant bank depths will publish as resolved integer
  depths in parser handoff, scheduled `.fsm`, schedule-report evidence,
  scalarized storage families, bank access metadata, and generated HDL,
  matching existing actor-constant and actor-parameter bank storage depth
  behavior.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  package constants in other dimension/value domains, and generated-top
  respecialization remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS`.
- Current frontier: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.2`.

## 2026-05-24: R14 — Bank storage package-constant widths shipped
- Completed `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.2` and closed the task
  tree.
- Actor-owned bank storage `(bank NAME (width PACKAGE.CONSTANT) (depth
  N|PARAM|CONST))` declarations may now use qualified imported package scalar
  constants for bank element widths when the resolved value is a positive
  integer literal.
- Parser storage width validation now accepts package-constant-shaped
  qualified tokens for actor-owned scalar and bank storage widths, so
  package-specific diagnostics can distinguish unknown, unqualified,
  aggregate, aggregate/member path, ambiguous, zero-valued, runtime, and
  expression-valued sources.
- Accepted package-constant bank widths publish as resolved integer widths in
  parser handoff, scalarized scheduled `.fsm` `+size`, schedule-report
  evidence, `bank_accesses[]` width evidence, and generated HDL register
  ranges.
- Package constants in actor-owned bank depths, transaction-local port widths,
  waits, watchdogs, latency bounds, contract windows, repeat counts,
  generated-top respecialization, and other dimensions/value domains remain
  deferred or fail closed.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused public/storage/package tests with
  `Files=11, Tests=352`; `./bin/ci-regression isf --no-book` with
  `Files=261, Tests=1707`; post-closure public/spec/book/backlog audits with
  `Files=7, Tests=374`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Bank storage package-constant widths selected
- Created active task tree `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS`.
- Completed `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.1`; the selected
  implementation frontier is `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.2`.
- The next implementation leaf will allow actor-owned bank storage
  `(bank NAME (width PACKAGE.CONSTANT) (depth N|PARAM|CONST))` declarations
  to use qualified imported package scalar constants for bank element widths
  when the resolved value is a positive integer literal.
- Accepted package-constant bank widths will publish as resolved integer
  widths in parser handoff, scheduled `.fsm`, schedule-report evidence, width
  evidence, bank access metadata, and generated HDL, matching existing
  actor-constant and actor-parameter bank storage width behavior.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  package constants in bank depths or other dimension/value domains, and
  generated-top respecialization remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS`.
- Current frontier: `ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.2`.

## 2026-05-24: R14 — Scalar storage package-constant widths shipped
- Completed `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.2` and closed the
  task tree.
- Actor-owned scalar storage `(var NAME (width PACKAGE.CONSTANT))` and
  verbose `(variable NAME (width PACKAGE.CONSTANT))` declarations may now use
  qualified imported package scalar constants when the resolved value is a
  positive integer literal.
- Parser scalar storage width validation now accepts package-constant-shaped
  qualified tokens for actor-owned scalar storage only, so package-specific
  diagnostics can distinguish unknown, unqualified, aggregate,
  aggregate/member path, ambiguous, zero-valued, runtime, and
  expression-valued sources.
- Accepted package-constant scalar storage widths publish as resolved integer
  widths in parser handoff, scheduled `.fsm` `+size`, schedule-report
  evidence, width evidence, and generated HDL register ranges.
- Package constants in actor-owned bank depths, transaction-local port
  widths, waits, watchdogs, latency bounds, contract windows, repeat counts,
  generated-top respecialization, and other dimensions/value domains remain
  deferred or fail closed.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused public/scalar-storage/package
  tests with `Files=10, Tests=350`; `./bin/ci-regression isf --no-book` with
  `Files=260, Tests=1705`; post-closure public/spec/book/backlog audits with
  `Files=7, Tests=374`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Scalar storage package-constant widths selected
- Created active task tree `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS`.
- Completed `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.1`; the selected
  implementation frontier is `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.2`.
- The next implementation leaf will allow actor-owned scalar storage
  `(var NAME (width PACKAGE.CONSTANT))` and verbose
  `(variable NAME (width PACKAGE.CONSTANT))` declarations to use qualified
  imported package scalar constants when the resolved value is a positive
  integer literal.
- Accepted package-constant scalar storage widths will publish as resolved
  integer widths in parser handoff, scheduled `.fsm`, schedule-report
  evidence, width evidence, and generated HDL, matching existing
  actor-constant and actor-parameter scalar storage width behavior.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  package constants in other dimension/value domains, and generated-top
  respecialization remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS`.
- Current frontier: `ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.2`.

## 2026-05-24: R14 — Interface package-constant widths shipped
- Completed `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.2` and closed the task
  tree.
- Actor top-level interface `(input NAME (width PACKAGE.CONSTANT))` and
  `(output NAME (width PACKAGE.CONSTANT))` declarations may now use qualified
  imported package scalar constants when the resolved value is a positive
  integer literal.
- Parser interface width validation now accepts package-constant-shaped
  qualified tokens so package-specific diagnostics can distinguish unknown,
  unqualified, aggregate, aggregate/member path, ambiguous, zero-valued,
  runtime, and expression-valued sources.
- Accepted package-constant interface widths publish as resolved integer
  widths in parser handoff, scheduled `.fsm` `+size`, schedule-report
  evidence, and generated HDL port ranges.
- Package constants in actor-owned bank depths, transaction-local port
  widths, waits, watchdogs, latency bounds, contract windows, repeat counts,
  generated-top respecialization, and other dimensions/value domains remain
  deferred or fail closed.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused public/interface/package tests
  with `Files=10, Tests=350`; `./bin/ci-regression isf --no-book` with
  `Files=259, Tests=1703`; post-closure public/spec/book/backlog audits with
  `Files=7, Tests=374`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Interface package-constant widths selected
- Created active task tree `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS`.
- Completed `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.1`; the selected
  implementation frontier is `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.2`.
- The next implementation leaf will allow actor top-level interface
  `(input NAME (width PACKAGE.CONSTANT))` and
  `(output NAME (width PACKAGE.CONSTANT))` declarations to use qualified
  imported package scalar constants when the resolved value is a positive
  integer literal.
- Accepted package-constant interface widths will publish as resolved integer
  widths in parser handoff, scheduled `.fsm`, schedule reports, and generated
  HDL, matching existing actor-constant and actor-parameter interface width
  behavior.
- Unqualified package constants, unknown package constants, package aggregate
  constants, package aggregate scalar-leaf paths, ambiguous local-token
  spellings, zero-valued constants, runtime signals, arbitrary expressions,
  package constants in other dimension/value domains, and generated-top
  respecialization remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book/book-matrix audits with
  `Files=3, Tests=364`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS`.
- Current frontier: `ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.2`.

## 2026-05-24: R14 — Reusable-library use-site package constants shipped
- Completed `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.2` and closed the task tree.
- Reusable-library use-site parameter override scalar values and scalar
  leaves inside compatible aggregate/list override values may now reference
  qualified imported package scalar constants such as `shared.DEFAULT_WIDTH`.
- Parser reusable-library use-site parameter validation now accepts
  package-constant-shaped qualified tokens so the package-specific resolver
  can issue targeted unknown, aggregate, path, ambiguity, and value-domain
  diagnostics.
- Reusable-library use-site publication resolves package constants to literal
  generated-top/generated-composition bindings and `library_uses[]` report
  values, matching the existing importer-side specialization model.
- Unknown package constants, unqualified package constants, package aggregate
  constants, package member/item paths, ambiguous local-enum versus
  package-constant spellings, runtime signals, unsupported actor values,
  arbitrary expressions, and package constants outside this use-site override
  surface remain fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused reusable-library/package tests
  with `Files=8, Tests=21`; public/spec/book/backlog audits with `Files=7,
  Tests=352`; `./bin/ci-regression isf --no-book` with `Files=258,
  Tests=1701`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Reusable-library use-site package constants selected
- Created active task tree `ISF-LIBRARY-USE-PACKAGE-CONSTANTS`.
- Completed `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.1`; the selected
  implementation frontier is `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.2`.
- The next implementation leaf will allow reusable-library use-site parameter
  override scalar values and scalar leaves inside compatible aggregate/list
  override values to reference qualified imported package scalar constants
  such as `shared.DEFAULT_WIDTH`.
- Use-site override publication will resolve package constants to literal
  generated-top/generated-composition bindings and `library_uses[]` report
  values, matching the existing reusable-library specialization model rather
  than requiring generated-top package imports.
- Unqualified package constants, package aggregate constants and aggregate
  scalar-leaf paths, package constants in other value domains, arbitrary
  expressions, runtime signals, and package namespace pollution remain
  deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book audits with `Files=2,
  Tests=38`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-LIBRARY-USE-PACKAGE-CONSTANTS`.
- Current frontier: `ISF-LIBRARY-USE-PACKAGE-CONSTANTS.2`.

## 2026-05-24: R14 — Activation package-constant overrides shipped
- Completed `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.2` and closed the task
  tree.
- Generated activation parameter override scalar values and scalar leaves
  inside compatible aggregate/list override values now accept qualified
  imported package scalar constants such as `shared.DEFAULT_WIDTH`.
- Parser enum-member validation now defers imported package-constant-shaped
  activation override tokens to LoweringIR for activation parameter scalar
  values and aggregate/list leaves, while keeping unrelated enum validation
  surfaces unchanged.
- Lowering resolves activation override package constants to literal
  generated-top `?fsmc` parameter bindings and generated-composition report
  values, matching the existing activation specialization boundary.
- Unknown package constants, unqualified package constants, aggregate package
  constants, package member/item paths, ambiguous local-enum versus
  package-constant spellings, runtime signals, and arbitrary expressions
  remain fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused activation/package tests with
  `Files=6, Tests=18`; public/spec/book/backlog audits with `Files=7,
  Tests=352`; `./bin/ci-regression isf --no-book` with `Files=257,
  Tests=1699`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Activation package-constant overrides selected
- Created active task tree `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS`.
- Completed `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.1`; the selected
  implementation frontier is `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.2`.
- The next implementation leaf will allow generated activation parameter
  override scalar values and scalar leaves inside compatible aggregate/list
  override values to reference qualified imported package scalar constants
  such as `shared.DEFAULT_WIDTH`.
- Activation override publication will resolve package constants to literal
  generated-top bindings and generated-composition report values, matching the
  existing activation specialization model rather than preserving child-local
  default tokens.
- Unqualified package constants, package aggregate constants and aggregate
  scalar-leaf paths, package constants in other value domains, arbitrary
  expressions, runtime signals, and package namespace pollution remain
  deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book audits with `Files=2,
  Tests=38`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS`.
- Current frontier: `ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.2`.

## 2026-05-24: R14 — Transaction package-constant defaults shipped
- Completed `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.2` and closed the
  task tree.
- Generated-child transaction parameter scalar defaults and scalar leaves
  inside compatible aggregate/list defaults may now reference qualified
  imported package scalar constants such as `shared.DEFAULT_WIDTH`.
- Authored `PACKAGE.CONSTANT` tokens remain visible in generated child `.fsm`
  `+params`, generated-composition child summaries, and default instance
  bindings; resolved scalar numeric or exact-width literals are recorded
  internally for lowerer consumers and diagnostics.
- The parser now defers imported package-constant-shaped transaction parameter
  tokens to LoweringIR instead of rejecting them as enum members, while keeping
  other enum validation surfaces unchanged.
- Unknown package constants, unqualified package constants, aggregate package
  constants, package member/item paths, ambiguous local-enum versus
  package-constant spellings, runtime signals, non-scalar actor parameters,
  and arbitrary expressions remain fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused transaction/default tests with
  `Files=5, Tests=12`; public/spec/book/backlog audits with `Files=7,
  Tests=352`; `./bin/ci-regression isf --no-book` with `Files=256,
  Tests=1696`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Transaction package-constant defaults selected
- Created active task tree
  `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS`.
- Completed `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.1`; the selected
  implementation frontier is
  `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.2`.
- The next implementation leaf will allow generated-child transaction
  parameter scalar defaults and scalar leaves inside compatible aggregate/list
  defaults to reference qualified imported package scalar constants such as
  `shared.DEFAULT_WIDTH`.
- Authored package-constant tokens must remain visible in generated child
  `.fsm` `+params`, generated-composition child summaries, and default
  instance bindings because child artifacts already carry package imports and
  embedded package roots for package enum defaults.
- Unqualified package constants, package aggregate constants and aggregate
  scalar-leaf paths, package constants in other value domains, arbitrary
  expressions, runtime signals, and package namespace pollution remain
  deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog/live-book audits with `Files=2,
  Tests=38`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS`.
- Current frontier: `ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.2`.

## 2026-05-24: R14 — Package-constant actor parameter defaults shipped
- Completed `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2` and closed the task
  tree.
- Actor-level `(params ...)` scalar defaults and scalar leaves inside
  compatible aggregate/list defaults may now reference qualified imported
  package scalar constants such as `shared.DEFAULT_WIDTH`.
- Authored `PACKAGE.CONSTANT` tokens remain visible in scheduled `.fsm`
  `+params` and `actor_params[]`; resolved scalar numeric or exact-width
  literals are recorded internally for scalar actor-parameter consumers.
- The actor shell exposes bounded imported package constant symbol metadata so
  parser and LoweringIR resolution stay aligned.
- Unqualified package constants, unknown package constants, aggregate package
  constants, package constant member/item paths, ambiguous local-enum versus
  package-constant spellings, transaction parameters, runtime signals, and
  arbitrary expressions remain fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused actor-param/default tests with
  `Files=5, Tests=12`; public/spec/book/backlog audits with `Files=7,
  Tests=352`; `./bin/ci-regression isf --no-book` with `Files=255,
  Tests=1694`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Package-constant actor parameter defaults selected
- Created active task tree `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS`.
- Completed `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.1`; the selected
  implementation frontier is `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2`.
- The next implementation leaf will allow actor-level `(params ...)` scalar
  defaults and scalar leaves inside compatible aggregate/list defaults to
  reference qualified imported package scalar constants such as
  `shared.DEFAULT_WIDTH`.
- Authored package-constant tokens must remain visible in scheduled `.fsm`
  `+params` and `actor_params[]`, while resolved literals are recorded
  internally for scalar actor-parameter consumers.
- Unqualified package constants, package aggregate constants and aggregate
  scalar-leaf paths, package constants in other value domains, arbitrary
  expressions, transaction parameters, runtime signals, and package namespace
  pollution remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS`.
- Current frontier: `ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.2`.

## 2026-05-24: Roadmap — Current-active-lane truth sync
- Completed `ROADMAP-CURRENT-ACTIVE-LANE-TRUTH-SYNC.1` and closed the task
  tree.
- Updated the lower `ROADMAP_STATUS.md` current-active-lane summary so it
  matches the top live-status pointer after the transaction parameter
  dependency defaults tree closed.
- Both live-roadmap surfaces now report no active task tree/frontier and keep
  the task-tree gate explicit for the next behavior-bearing implementation
  slice.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed.
- Validation passed: focused book/spec/backlog audits with
  `Files=3, Tests=343`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Transaction parameter dependency defaults shipped
- Completed `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.2` and closed the task
  tree.
- Generated child transaction scalar defaults and scalar leaves inside
  compatible aggregate/list defaults may now reference earlier scalar
  transaction parameter defaults by name.
- Child-local dependency tokens remain authored in generated child `.fsm`
  `+params`, generated-composition child summaries, and default instance
  bindings, while resolved default literals are recorded internally.
- Forward references, self references, cycles, non-scalar transaction
  parameters, runtime interface signals, unknown symbols, arbitrary
  expressions, activation-site override dependencies, and package/imported
  constants beyond shipped enum members remain fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused transaction/default tests with
  `Files=6, Tests=71`; public/spec/book/backlog audits with `Files=6,
  Tests=351`; `./bin/ci-regression isf --no-book` with `Files=254,
  Tests=1692`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Transaction parameter dependency defaults selected
- Created active task tree `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS`.
- Completed `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.1`; the selected
  implementation frontier is `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.2`.
- The next implementation leaf will allow generated child transaction scalar
  parameter defaults and scalar leaves inside compatible aggregate/list
  defaults to reference earlier scalar transaction parameter defaults by name.
- Transaction-parameter dependency tokens must remain authored in generated
  child `.fsm` `+params`, generated-composition child summaries, and default
  instance bindings because those names are child-local and self-contained.
- Forward references, self references, cycles, non-scalar transaction
  parameters, runtime interface signals, unknown symbols, arbitrary
  expressions, activation-site override dependencies, and package/imported
  constants beyond shipped enum members remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS`.
- Current frontier: `ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.2`.

## 2026-05-24: R14 — Generated-child transaction static defaults shipped
- Completed `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.2` and closed the
  task tree.
- Generated child transaction scalar defaults and scalar leaves inside
  compatible aggregate/list defaults may now use declared actor constants and
  actor-local scalar parameter defaults by name.
- Actor-static transaction defaults are literalized before generated child
  `.fsm` `+params`, generated-composition child summaries, and default
  instance bindings are published; enum-backed defaults preserve authored enum
  tokens.
- Unsupported transaction-parameter dependencies, non-scalar actor parameters,
  runtime interface signals, unknown symbols, arbitrary expressions,
  package/imported constants beyond shipped enum members, and malformed shapes
  remain fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused transaction/default and
  static-value tests with `Files=7, Tests=73`; public/spec/book/backlog
  audits with `Files=6, Tests=351`; `./bin/ci-regression isf --no-book` with
  `Files=253, Tests=1690`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Generated-child transaction static defaults selected
- Created active task tree `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS`.
- Completed `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.1`; the selected
  implementation frontier is `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.2`.
- The next implementation leaf will allow generated child transaction scalar
  parameter defaults and scalar leaves inside compatible aggregate/list
  defaults to use declared actor constants and actor-local scalar parameter
  defaults by name.
- Actor-static names must resolve to literals before generated child `.fsm`
  `+params`, generated-composition summaries, and schedule-report publication.
- Transaction-parameter dependencies, non-scalar actor parameters, runtime
  interface signals, arbitrary expressions, package/imported constants beyond
  shipped enum members, and malformed shapes remain deferred or fail closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS`.
- Current frontier: `ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.2`.

## 2026-05-24: R14 — Ordered actor-parameter defaults shipped
- Completed `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2` and closed the task
  tree.
- Actor-level scalar parameter defaults and scalar leaves inside compatible
  aggregate/list defaults may now reference earlier actor-local scalar
  parameter defaults by name.
- Authored actor-parameter tokens remain visible in scheduled `.fsm` `+params`
  and `actor_params[]`; resolved literals are recorded internally for scalar
  parameter consumers.
- Forward references, self references, cycles, non-scalar actor parameters,
  transaction parameters, runtime interface signals, arbitrary expressions,
  package/imported constants beyond shipped enum members, and generated child
  transaction parameter defaults remain fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused actor-param/static-value tests
  with `Files=11, Tests=35`; public/spec/book/backlog audits with `Files=6,
  Tests=351`; `./bin/ci-regression isf --no-book` with `Files=252,
  Tests=1688`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Actor-parameter dependency defaults selected
- Created active task tree `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS`.
- Completed `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.1`; the selected
  implementation frontier is `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2`.
- The next implementation leaf will allow actor-level scalar parameter
  defaults and scalar leaves inside compatible aggregate/list defaults to
  reference earlier actor-local scalar parameter defaults by name.
- Source order is the only dependency model; forward/self/cyclic/non-scalar
  dependencies, transaction parameters, runtime signals, arbitrary
  expressions, package/imported constants beyond shipped enum members, and
  generated child transaction parameter defaults remain deferred or fail
  closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS`.
- Current frontier: `ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.2`.

## 2026-05-24: R14 — Actor-constant actor-parameter defaults shipped
- Completed `ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.2` and closed the task
  tree.
- Actor-level `(params ...)` scalar defaults may now use declared actor
  constants by name.
- Scalar leaves inside compatible aggregate/list actor parameter defaults may
  also use declared actor constants.
- Actor-constant-backed actor parameter defaults preserve authored constant
  tokens in scheduled `.fsm` `+params` and `actor_params[]` reports while
  recording resolved literals internally for scalar actor-parameter consumers.
- Unknown symbolic names, actor-parameter-to-actor-parameter defaults,
  transaction parameters, runtime interface signals, arbitrary expressions,
  generated child transaction parameter defaults, package/imported constants
  beyond enum members, dependency ordering, and expression solving remain
  fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused actor-param/static-value tests
  with `Files=9, Tests=29`; public/spec/book/backlog audits with `Files=6,
  Tests=351`; `./bin/ci-regression isf --no-book` with `Files=251,
  Tests=1686`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Reusable-library actor-static use-site overrides shipped
- Completed `ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.2` and closed the task tree.
- Reusable-library use-site `(params ...)` override values now accept
  importing-actor constants and actor-local scalar parameter defaults by name,
  including scalar leaves inside compatible aggregate/list override values.
- The parser resolves those static names to literals before generated-top
  `?fsmc` emission and `library_uses[]` schedule-report publication.
- Unknown symbolic names, runtime interface signals, non-scalar actor
  parameters as scalar values, transaction parameters, arbitrary expressions,
  and use-site parameter-driven interface/storage shape inference remain
  fail-closed or deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused library-use tests with `Files=4,
  Tests=11`; public/spec/book/backlog audits with `Files=6, Tests=351`;
  `./bin/ci-regression isf --no-book` with `Files=250, Tests=1684`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Activation parameter value-domain docs synchronized
- Completed `ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.1` and closed
  the task tree.
- Synchronized remaining mdBook feature-backlog, ISF spec, and public
  contract wording so activation override summaries include actor-local
  scalar parameter defaults.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed.
- Validation passed: focused spec/book/backlog audits with
  `Files=3, Tests=343`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Actor-parameter activation overrides shipped
- Completed `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2` and closed the task tree.
- Generated activation `(params ...)` override values now accept actor-local
  scalar parameter defaults by name for spawn, generated blocking `do`, and
  rule-trigger sites.
- Scalar leaves inside compatible aggregate/list activation override values
  may also use actor-local scalar parameter defaults.
- Actor-parameter override values resolve before lowerer IR publication,
  schedule reports, and generated-top `?fsmc` emission, preserving
  self-contained literal outputs.
- Transaction parameters, runtime signals, arbitrary expressions, non-scalar
  actor parameters, direct `(on ...)` activation params, and reusable-library
  use-site actor constants/parameters remain deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused activation parameter binding tests
  with `Files=3, Tests=65`; public/spec/book/backlog audits with `Files=6,
  Tests=351`; `./bin/ci-regression isf --no-book` with `Files=250,
  Tests=1683`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Actor-parameter activation override selected
- Created active task tree `ISF-ACTIVATION-PARAM-ACTOR-PARAMS`.
- Completed `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.1`.
- The current frontier is `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2`.
- The selected implementation will allow generated activation `(params ...)`
  override values to use actor-local scalar parameter defaults by name for
  spawn, generated blocking `do`, and rule-trigger sites.
- Actor parameters must resolve before lowerer IR publication, schedule
  reports, and generated-top `?fsmc` emission. Transaction parameters,
  runtime signals, arbitrary expressions, non-scalar actor parameters as
  scalar values, direct `(on ...)` activation params, and reusable-library
  use-site parameter semantics remain deferred.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior,
  public API, source, test, or generated behavior changed in this selection
  slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-ACTIVATION-PARAM-ACTOR-PARAMS`.
- Current frontier: `ISF-ACTIVATION-PARAM-ACTOR-PARAMS.2`.

## 2026-05-24: Roadmap — Active-lane latest-slice summary synchronized
- Completed `ROADMAP-ACTIVE-LANE-LATEST-SLICE-SYNC.1` and closed the task
  tree.
- Updated the lower `ROADMAP_STATUS.md` current-active-lane summary so it
  matches the top live-status board.
- The roadmap now consistently reports no active task tree/frontier and
  preserves the requirement that the next behavior-bearing implementation
  slice must create or select a task tree before code changes.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior,
  public API, source, test, or generated behavior changed.
- Validation passed: focused book/spec/backlog audits with
  `Files=3, Tests=343`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Transaction-over-rule book truth sync
- Completed `ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.1` and closed the task
  tree.
- Corrected stale mdBook intent-scheduling prose that still claimed
  transaction-over-rule priority was deferred.
- The book now states that covered same-target data transaction-over-rule
  priority is shipped through scheduled `.fsm` `(state_active STATE)` guard
  syntax.
- Broader transaction/transaction priority, unordered rule/transaction
  conflicts, and mixed timing conflicts remain fail-closed.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior,
  public API, source, test, or generated behavior changed.
- The task tree, README index, roadmap, mdBook, and live docs are
  synchronized.
- Validation passed: focused book/spec/backlog audits with
  `Files=3, Tests=343`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Storage-port round-robin resource shipped
- Completed `ISF-STORAGE-PORT-ROUND-ROBIN.2` and closed the task tree.
- FSMGen now supports bounded
  `(resource NAME (kind storage_port) (arbiter round_robin) (members STORAGE_SIGNAL...) (users RULE...))`
  declarations for declared rule users.
- Explicit storage-port members remain mandatory concrete actor-owned storage
  signals and continue to appear in `resource_arbitration[].members`.
- The scheduler emits `isf_rr_<resource>_turn`, gates the winning
  storage-port rule DT, reports `resource_arbitration[]` grants with
  `kind: storage_port`/`arbiter: round_robin`, and reports the pointer as
  `resource_round_robin_pointer`.
- Backlog resource kinds, generated-child resources, route mux/storage,
  ready/backpressure, payload protocols, storage locks, memory-port protocols,
  and lifetime ownership remain deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused resource arbitration with
  `Files=1, Tests=15`; public/report/book audits with `Files=9, Tests=370`;
  `./bin/ci-regression isf --no-book` with `Files=250, Tests=1682`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Storage-port round-robin resource selected
- Created active task tree `ISF-STORAGE-PORT-ROUND-ROBIN`.
- Completed `ISF-STORAGE-PORT-ROUND-ROBIN.1`.
- The current frontier is `ISF-STORAGE-PORT-ROUND-ROBIN.2`, the
  implementation leaf.
- The selected source shape is bounded to
  `(resource NAME (kind storage_port) (arbiter round_robin) (members STORAGE_SIGNAL...) (users RULE...))`
  for declared rule users.
- Explicit storage members remain mandatory, must name concrete actor-owned
  storage signals, and must keep current validation/reporting through
  `resource_arbitration[].members`.
- Backlog resource kinds, generated-child resources, route mux/storage,
  ready/backpressure, payload protocols, storage locks, and lifetime ownership
  remain deferred.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Output-bundle round-robin resource shipped
- Completed `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.2` and closed the task tree.
- FSMGen now supports bounded
  `(resource NAME (kind output_bundle) (arbiter round_robin) (users RULE...))`
  declarations for declared rule users.
- Explicit output-bundle members keep the shipped validation/reporting
  contract and continue to appear in `resource_arbitration[].members`.
- The scheduler emits `isf_rr_<resource>_turn`, gates the winning
  output-bundle rule DT, reports `resource_arbitration[]` grants with
  `kind: output_bundle`/`arbiter: round_robin`, and reports the pointer as
  `resource_round_robin_pointer`.
- Backlog resource kinds, generated-child resources, route mux/storage,
  ready/backpressure, payload protocols, and lifetime ownership remain
  deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused resource arbitration with
  `Files=1, Tests=14`; public/report/book audits with `Files=9, Tests=369`;
  `./bin/ci-regression isf --no-book` with `Files=250, Tests=1681`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Output-bundle round-robin resource selected
- Created active task tree `ISF-OUTPUT-BUNDLE-ROUND-ROBIN`.
- Completed `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.1`.
- The current frontier is `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.2`, the
  implementation leaf.
- The selected source shape is bounded to
  `(resource NAME (kind output_bundle) (arbiter round_robin) (users RULE...))`
  for declared rule users, preserving current explicit output-bundle member
  validation and `resource_arbitration[].members` reporting.
- Backlog resource kinds, generated-child resources, route mux/storage,
  ready/backpressure, payload protocols, and lifetime ownership remain
  deferred.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-OUTPUT-BUNDLE-ROUND-ROBIN`.
- Current frontier: `ISF-OUTPUT-BUNDLE-ROUND-ROBIN.2`.

## 2026-05-24: R14 — Transaction-start round-robin resource shipped
- Completed `ISF-TRANSACTION-START-ROUND-ROBIN.2` and closed the task tree.
- FSMGen now supports bounded
  `(resource TX (kind transaction_start) (arbiter round_robin) (users RULE...))`
  declarations for local non-generated transaction starts triggered by
  declared rule users.
- The scheduler emits `isf_rr_<resource>_turn`, gates the winning per-rule
  trigger-source DT before the existing generated transaction trigger fan-in,
  reports `resource_arbitration[]` grants with
  `kind: transaction_start`/`arbiter: round_robin`, and reports the pointer as
  `resource_round_robin_pointer`.
- Generated-child transaction starts, backlog resource kinds,
  route mux/storage, ready/backpressure, payload protocols, and lifetime
  ownership remain deferred.
- The ISF spec, downstream handoff, public contract, mdBook, task tree,
  README index, roadmap, and live docs are synchronized.
- Validation passed: syntax checks; focused resource arbitration with
  `Files=1, Tests=13`; public/report/book audits with `Files=8, Tests=355`;
  `./bin/ci-regression isf --no-book` with `Files=250, Tests=1680`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R14 — Transaction-start round-robin resource selected
- Created active task tree `ISF-TRANSACTION-START-ROUND-ROBIN`.
- Completed `ISF-TRANSACTION-START-ROUND-ROBIN.1`.
- The next frontier is `ISF-TRANSACTION-START-ROUND-ROBIN.2`, which must
  implement or explicitly close bounded `transaction_start` + `round_robin`
  arbitration for declared rule users that trigger one local non-generated
  transaction.
- No parser, scheduler, report, generated artifact, HDL, CLI behavior, public
  API, source, test, or generated behavior changed in this selection slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `ISF-TRANSACTION-START-ROUND-ROBIN`.
- Current frontier: `ISF-TRANSACTION-START-ROUND-ROBIN.2`.

## 2026-05-24: R11 — Top-boundary convention frontier audited
- Completed `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2` and closed the
  task tree.
- Decision: no new top-boundary convention implementation slice is selected
  now. Broader interface bundles, protocol groups, hidden child-to-child
  inference, automatic priority/merge/arbitration, wider public re-export
  policy, non-top-boundary convention semantics, and richer local override
  syntax remain deferred until one precise prerequisite contract exists.
- The mdBook composition basics chapter and feature backlog now document the
  shipped bounded top-boundary convention/connect-by-name contract and backlog
  boundary.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this audit slice.
- Validation passed: focused top-boundary convention evidence with `Files=19,
  Tests=65`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R11 — Top-boundary convention frontier audit selected
- Created active task tree `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`.
- Completed `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1`.
- The next frontier is `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2`, which
  will audit shipped declared top-port/connect-by-name convention behavior
  and choose one bounded next implementation slice or deferral.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`.
- Current frontier: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2`.

## 2026-05-24: R11 — Portable-type contract frontier audited
- Completed `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2` and closed the
  task tree.
- Decision: no new portable-type implementation slice is selected now.
  Broader enum-as-type unification, fixed-size arrays, arrays of records,
  broad inference-first scalar declarations, aggregate member/index
  autogrowth from partial use, arbitrary subaggregate runtime operators,
  portable VHDL record/array lowering, backend-neutral policy across every
  inferred site, and richer public type/export APIs remain deferred until one
  precise prerequisite contract exists.
- The mdBook symbols, type/aggregate, and feature-backlog chapters now
  document the shipped bounded portable-type contract and backlog boundary.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this audit slice.
- Validation passed: focused portable-type evidence with `Files=13,
  Tests=59`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R11 — Portable-type contract frontier audit selected
- Created active task tree `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`.
- Completed `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1`.
- The next frontier is `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2`, which
  will audit shipped portable synthesizable type behavior and choose one
  bounded next implementation slice or deferral.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`.
- Current frontier: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2`.

## 2026-05-24: R11 — Reusable-module contract frontier audited
- Completed `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2` and closed the
  task tree.
- Decision: no new reusable-module implementation slice is selected now.
  Broader unnamed roots, authored DT enable-control, declarative reusable
  packages, advanced reusable-module interface/export rules, broader lookup
  policy, external activation/deactivation, advanced same-target
  merge/priority, and debug-reporting semantics remain deferred until one
  precise prerequisite contract exists.
- The mdBook composition basics chapter and feature backlog now document the
  shipped bounded reusable standalone-DT/module-library contract and backlog
  boundary.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this audit slice.
- Validation passed: focused reusable-module evidence with `Files=16,
  Tests=42`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R11 — Reusable-module contract frontier audit selected
- Created active task tree `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT`.
- Completed `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.1`.
- The next frontier is `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2`, which
  will audit shipped reusable standalone-DT/module-library behavior and choose
  one bounded next implementation slice or deferral.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT`.
- Current frontier: `R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.2`.

## 2026-05-24: R11 — Shared-datapath contract frontier audited
- Completed `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2` and closed the
  task tree.
- Decision: no new shared-datapath implementation slice is selected now.
  Broader route mux/storage, arbitrary fan-in/fan-out protocols,
  ready/backpressure, payload protocols, dynamic scheduling, external-RTL or
  standalone-DT contributors, mixed storage-class lifting, and wider
  shared-data movement remain deferred until a precise prerequisite contract
  exists.
- The mdBook composition chapter and feature backlog now document the shipped
  bounded shared-datapath contract and backlog boundary.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this audit slice.
- Validation passed: focused shared-datapath evidence with `Files=18,
  Tests=36`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R11 — Shared-datapath contract frontier audit selected
- Created active task tree `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`.
- Completed `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1`.
- The next frontier is `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2`, which
  will audit shipped shared-datapath behavior and choose one bounded next
  implementation slice or deferral.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`.
- Current frontier: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2`.

## 2026-05-24: R11 — Parameter/generic frontier audited
- Completed `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2` and closed the task
  tree.
- Decision: no new parameter/generic implementation slice is selected now.
  VHDL generic-map lowering remains deferred behind active VHDL backend and
  composition-target support, and richer non-leafwise or mixed aggregate
  expression domains remain deferred until a precise portable type or
  aggregate-operator contract exists.
- The mdBook feature backlog now states those deferrals explicitly.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this audit slice.
- Validation passed: focused parameter/generic and VHDL-deferral evidence with
  `Files=10, Tests=203`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R11 — Parameter/generic frontier audit selected
- Created active task tree `R11-PARAMETER-GENERIC-FRONTIER-AUDIT`.
- Completed `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1`.
- The next frontier is `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2`, which will
  audit shipped semantic parameter/generic behavior and choose one bounded
  next implementation slice or deferral.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT`.
- Current frontier: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2`.

## 2026-05-24: R11 — `.rtlif` interface-source direction decided
- Completed `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2` and closed the task
  tree.
- Decision: `.rtlif` remains the canonical low-level external-RTL interface
  metadata contract for now. A separate stronger interface-source language is
  deferred until a concrete portable type, package/import, shared-datapath, or
  reusable-module requirement proves the current metadata layer is
  insufficient.
- The mdBook composition chapters now state that boundary explicitly.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this decision slice.
- Validation passed: focused `.rtlif` composition evidence with `Files=13,
  Tests=68`; parameter/package composition evidence with `Files=4,
  Tests=21`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R11 — `.rtlif` interface-source direction selected
- Created active task tree `R11-RTLIF-INTERFACE-SOURCE-DIRECTION`.
- Completed `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.1`.
- The next frontier is `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2`, which will
  audit shipped `.rtlif` behavior and decide whether a stronger
  interface-source contract is needed now before any `.rtlif` behavior change.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION`.
- Current frontier: `R11-RTLIF-INTERFACE-SOURCE-DIRECTION.2`.

## 2026-05-24: R11 — Composition-contract frontier audited
- Completed `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2` and closed the task
  tree.
- The focused R11 evidence sweep passed across composition parser,
  standalone-DT, reusable-source lookup, `.rtlif`, generated-child,
  explicit-wiring, connect-by-name, shared-datapath, assertion, runtime-HDL,
  and forward-IR coverage.
- The next bounded R11 frontier should be
  `R11-RTLIF-INTERFACE-SOURCE-DIRECTION`: decide whether `.rtlif` remains
  embedded-root plus sidecar metadata or whether FSMGen needs a stronger
  interface-source contract above it before any `.rtlif` behavior change.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this audit slice.
- Validation passed: focused R11 composition evidence sweep with `Files=27,
  Tests=175`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R11 — Composition-contract frontier audit selected
- Created active task tree `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT`.
- Completed `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.1`.
- The next frontier is `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2`, which
  will map shipped R11 coverage and select one bounded next composition slice
  or deferral from evidence.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT`.
- Current frontier: `R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.2`.

## 2026-05-24: R10 — Diagnostic/provenance exit frontier audited
- Completed `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2` and closed the task
  tree.
- Focused R10 diagnostic tests passed across the shipped source-context,
  cleaned CLI, entrypoint, extension, empty-source, quiet-mode,
  self-dependency, check-JSON, and semantic-JSON surfaces.
- A fresh expected-failure `.fsm` quiet CLI corpus probe checked 106 entries
  with `leaks=0`, and regression-corpus accounting still passes.
- No behavior-bearing change was made in this audit leaf. `R10` is now
  `mostly done`.
- Validation passed: focused R10 diagnostics with `Files=12, Tests=37`;
  expected-failure probe `checked=106, leaks=0`; regression-corpus accounting
  with `Files=1, Tests=3149`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R10 — Diagnostic/provenance exit audit selected
- Created active task tree `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT`.
- Completed `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.1`.
- A fresh expected-failure `.fsm` corpus probe checked 106 entries and found no
  remaining quiet CLI `Parser.pm`, `SourceFrontend.pm`, `Lispish::`,
  `called at`, or generic Perl script-line leakage.
- The next frontier is `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2`, which will
  decide whether another bounded `R10` implementation slice is justified now
  or whether `R10` should move to close/handoff status.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT`.
- Current frontier: `R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.2`.

## 2026-05-24: R10 — D-input self-dependency diagnostics cleaned
- Completed `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2` and closed the
  task tree.
- Illegal D-input self-dependency still rejects before HDL emission, but quiet
  CLI, check-JSON, and normalized semantic JSON diagnostics no longer expose
  parser filenames, parser routine names, or Perl stack frames.
- The diagnostic keeps source context, rejected operator, offending expression
  role, self-dependent signal, stable diagnostic code, and remediation hints.
- The mdBook troubleshooting chapter documents the user-facing behavior.
- Validation passed: focused diagnostics tests with `Files=7, Tests=32`;
  regression-corpus accounting with `Files=1, Tests=3149`; feature-backlog
  audit with `Files=1, Tests=15`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R10 — D-input self-dependency diagnostic cleanup selected
- Created active task tree
  `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP`.
- Completed `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1`.
- The next frontier is
  `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2`, which will preserve
  illegal D-input self-dependency rejection while removing parser
  implementation-name leakage from CLI and machine JSON diagnostics.
- No parser, scheduler, HDL, CLI behavior, public API, source, test,
  generated artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP`.
- Current frontier: `R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2`.

## 2026-05-24: R10 — Self-dependency diagnostics cleaned
- Completed `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2` and closed the task
  tree.
- Illegal combinational self-dependency still rejects before HDL emission, but
  quiet CLI, check-JSON, and normalized semantic JSON diagnostics no longer
  expose parser filenames, parser routine names, or Perl stack frames.
- The diagnostic keeps the source context, rejected assignment family,
  dependency path, stable diagnostic code, and remediation hint.
- The mdBook troubleshooting chapter documents the user-facing behavior.
- Validation passed: focused diagnostics tests with `Files=6, Tests=26`;
  regression-corpus accounting with `Files=1, Tests=3149`; feature-backlog
  audit with `Files=1, Tests=15`; `mdbook build docs/book`; and
  `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R10 — Self-dependency diagnostic cleanup selected
- Created active task tree `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP`.
- Completed `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.1`.
- The next frontier is `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2`, which will
  preserve illegal combinational self-dependency rejection while removing raw
  parser implementation-frame leakage from CLI and machine JSON diagnostics.
- No parser, scheduler, HDL, CLI behavior, public API, source, test, generated
  artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP`.
- Current frontier: `R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.2`.

## 2026-05-24: R10 — Quiet CLI banner suppressed
- Completed `R10-CLI-QUIET-BANNER-CLEANUP.2` and closed the task tree.
- `bin/fsmgen --quiet` now suppresses the interactive banner and processing
  line on success and failure.
- Non-quiet runs still print the banner, human diagnostics still print on
  failure, and machine JSON modes remain JSON-only.
- The mdBook CLI chapter documents the quiet-mode boundary.
- Validation passed: focused CLI quiet/banner tests with `Files=4, Tests=12`;
  feature-backlog audit with `Files=1, Tests=15`; `mdbook build docs/book`;
  and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R10 — Quiet-banner cleanup selected
- Created active task tree `R10-CLI-QUIET-BANNER-CLEANUP`.
- Completed `R10-CLI-QUIET-BANNER-CLEANUP.1`.
- The next frontier is `R10-CLI-QUIET-BANNER-CLEANUP.2`, which will suppress
  the interactive `=== FSM HDL Generator ===` banner when `--quiet` is active
  while preserving diagnostics, non-quiet output, and machine JSON behavior.
- No parser, scheduler, HDL, CLI behavior, public API, source, test, generated
  artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R10-CLI-QUIET-BANNER-CLEANUP`.
- Current frontier: `R10-CLI-QUIET-BANNER-CLEANUP.2`.

## 2026-05-24: R10 — Empty source-file diagnostics cleaned
- Completed `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3` and closed the task
  tree.
- Empty direct `.fsm` source files now fail with a targeted source-local
  diagnostic across pipeline, CLI, check-JSON, and normalized semantic JSON.
- The failure message reports the source path, says the file is empty, and
  tells the user to provide a non-empty FSMGen source file.
- The raw Lispish fallback text, the `does not exit` typo, and Perl stack
  frames no longer leak for this failure path.
- The mdBook troubleshooting chapter documents the behavior.
- Validation passed: focused empty-source/diagnostic JSON tests with
  `Files=8, Tests=19`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R10 — Diagnostic/provenance frontier audited
- Completed `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2`.
- The audit found that shipped `R10` coverage already handles top-level
  source-file context, generated-child context, RTL metadata context, missing
  child and missing `.rtlif` artifacts, lookup search roots, pre-pipeline CLI
  missing-input/output-open context, and typed-extension hook/loading context.
- The next frontier is `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3`: clean up
  empty direct `.fsm` source-file diagnostics across pipeline, CLI,
  check-JSON, and normalized semantic JSON so users see a targeted
  source-local message without raw Lispish fallback text, the legacy
  `does not exit` typo, or Perl stack frames.
- No parser, scheduler, HDL, CLI, public API, source, test, generated
  artifact, or generated behavior changed in this audit slice.
- Validation passed: focused diagnostic context tests with `Files=13,
  Tests=172`; feature-backlog audit with `Files=1, Tests=15`; `mdbook build
  docs/book`; and `git diff --check`.
- Active task tree: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT`.
- Current frontier: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.3`.

## 2026-05-24: R10 — Diagnostic/provenance frontier audit selected
- Created active task tree `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT`.
- Completed `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.1`.
- The next frontier is audit-only leaf
  `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2`, which will map current
  source-local and construct-local diagnostic coverage, tests, public
  metadata, mdBook coverage, and remaining gaps before selecting another
  diagnostic/provenance cut or close-out.
- No parser, scheduler, HDL, CLI, public API, source, test, generated
  artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT`.
- Current frontier: `R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.2`.

## 2026-05-24: R9 — Strict-mode frontier audited and closed
- Completed `R9-STRICT-MODE-FRONTIER-AUDIT.2` and closed the task tree.
- The audit found no currently named default-mode compatibility residue that
  requires another immediate strict-mode cut. Known residue is paired in the
  regression corpus, rejected by stable `FSMGEN_STRICT_*` diagnostics under
  strict mode, documented in the mdBook, and visible in language-surface
  manifest metadata.
- The maintained supported corpus currently has 40 `strict_supported` positive
  acceptance entries.
- `R9` is now `mostly done`; future strict-mode work is maintenance attached
  to future feature slices that add or preserve compatibility surfaces.
- No parser, scheduler, HDL, CLI, public API, source, test, generated
  artifact, or generated behavior changed in this audit slice.
- Validation passed: focused strict/corpus gates with `Files=13,
  Tests=3204`; feature-backlog audit with `Files=1, Tests=15`; `mdbook build
  docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R9 — Strict-mode frontier audit selected
- Created active task tree `R9-STRICT-MODE-FRONTIER-AUDIT`.
- Completed `R9-STRICT-MODE-FRONTIER-AUDIT.1`.
- The next frontier is audit-only leaf `R9-STRICT-MODE-FRONTIER-AUDIT.2`,
  which will map the current default/strict split, diagnostics, corpus
  accounting, mdBook coverage, and public metadata before selecting another
  strict cut or close-out.
- No parser, scheduler, HDL, CLI, public API, source, test, generated
  artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R9-STRICT-MODE-FRONTIER-AUDIT`.
- Current frontier: `R9-STRICT-MODE-FRONTIER-AUDIT.2`.

## 2026-05-24: R8 — Exit criteria audited and handed to R9
- Completed `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2` and closed the task tree.
- The audit found no concrete unclassified parser-visible legacy family for
  another immediate `R8` implementation leaf.
- `R8` is now marked `mostly done` in `ROADMAP_STATUS.md`: known compatibility
  residue is named in public metadata, paired in the regression corpus, and
  documented in the mdBook; ongoing support-claim maintenance remains required
  as future features land.
- No parser, scheduler, HDL, CLI, public API, source, test, generated
  artifact, or generated behavior changed.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R8 — Language-contract exit audit selected
- Created active task tree `R8-LANGUAGE-CONTRACT-EXIT-AUDIT`.
- Completed `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.1`.
- The next frontier is audit-only leaf `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2`,
  which will map the `R8` exit criteria to current docs, tests, corpus,
  strict-mode, manifest, and mdBook evidence before deciding close-out,
  handoff, or one bounded follow-up.
- No parser, scheduler, HDL, CLI, public API, source, test, generated
  artifact, or generated behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT`.
- Current frontier: `R8-LANGUAGE-CONTRACT-EXIT-AUDIT.2`.

## 2026-05-24: R8 — Language-surface legacy <=+ manifest metadata synced
- Completed `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.3` and closed the task tree.
- The capability manifest now records `legacy <=+ assignment operator alias
  for <=-` in both the broad default-mode compatibility inventory and the
  assignment-specific compatibility list.
- No parser, scheduler, strict-mode diagnostic, corpus classification, HDL,
  CLI, or generated behavior changed.
- The mdBook embedding/manifest chapter and live docs now describe the
  manifest discoverability contract.
- Validation passed: syntax check; language-surface/manifest tests with
  `Files=4, Tests=12`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R8 — Language-surface gray-zone residue audited
- Completed `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2`.
- Audited parser-accepted compatibility residue across behavior, regression
  ownership, strict-mode boundaries, manifest metadata, regression docs, and
  the mdBook.
- Selected `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.3` as the next bounded leaf:
  sync the legacy `<=+` assignment alias into the top-level language-surface
  default compatibility inventory.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API,
  source, test, or generated behavior changed.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT`.
- Current frontier: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.3`.

## 2026-05-24: R8 — Language-surface gray-zone audit selected
- Created active task tree `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT`.
- Completed `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.1`.
- The next frontier is audit-only leaf
  `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2`, which will select one bounded
  parser-accepted gray-zone construct family or record a close-out decision.
- No parser, scheduler, HDL, CLI, public API, source, test, or generated
  behavior changed in this activation slice.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT`.
- Current frontier: `R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.2`.

## 2026-05-24: R8 — Strict composition slash-link cut shipped
- Completed `R8-STRICT-SUPPORT-TIER-CUTS.3` and closed the task tree.
- Default mode still accepts well-formed composition `?wiring`
  `/source/target/` slash-link tokens as compatibility input.
- Strict mode now rejects those tokens before HDL emission with
  `FSMGEN_STRICT_COMPOSITION_WIRING_SLASH_LINK` and points users to
  `(source target)` or `(connect source target)`.
- Regression corpus accounting now has paired default-compatible and
  strict-rejected entries for this compatibility residue, and check-JSON plus
  normalized semantic JSON corpus gates classify the new strict bucket.
- The mdBook composition basics, composition advanced, and strict-mode
  chapters now document the exact default/strict split.
- Validation passed: focused strict/composition/corpus tests with `Files=6,
  Tests=3279`; manifest/diagnostic/JSON/support gates with `Files=8,
  Tests=1131`; feature-backlog audit with `Files=1, Tests=15`; `mdbook build
  docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: R8 — Strict support-tier frontier audited
- Completed `R8-STRICT-SUPPORT-TIER-CUTS.2`.
- The shipped strict-mode boundary rejects legacy direct roots, direct-root
  aliases, empty `+size`, misleading reset spellings, compact init/default
  directives, infix assignments, `<=+`, and legacy generated-child roots.
- Selected `R8-STRICT-SUPPORT-TIER-CUTS.3` as the next bounded implementation
  leaf: reject legacy composition `?wiring` `/source/target/` slash-link
  tokens in strict mode while preserving default-mode compatibility.
- Canonical replacements are `(source target)` and `(connect source target)`.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed in this audit slice.
- Validation passed: focused strict/composition/corpus tests with `Files=13,
  Tests=3281`; `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R8-STRICT-SUPPORT-TIER-CUTS`.
- Current frontier: `R8-STRICT-SUPPORT-TIER-CUTS.3`.

## 2026-05-24: R8 — Strict support-tier frontier selected
- Completed `R8-STRICT-SUPPORT-TIER-CUTS.1`.
- Activated the R8 task tree for the next strict-mode support-tier cuts.
- The current frontier is `R8-STRICT-SUPPORT-TIER-CUTS.2`, an audit of the
  current strict-mode enforcement boundary and next bounded compatibility cut.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `R8-STRICT-SUPPORT-TIER-CUTS`.
- Current frontier: `R8-STRICT-SUPPORT-TIER-CUTS.2`.

## 2026-05-24: Roadmap maintenance — Current active lane truth sync
- Corrected the secondary `ROADMAP_STATUS.md` current active lane block so it
  matches the top live snapshot after `RICHER-AGGREGATE-OPERATORS.3` closed.
- Active task tree: `none`.
- Current frontier: `none`.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: Aggregate types — Unary aggregate complement shipped
- Completed `RICHER-AGGREGATE-OPERATORS.3` and closed the task tree.
- Semantic parameter/generic aggregate values now support unary bitwise
  complement through `(~ VALUE)` and `(not VALUE)` in direct `+params`,
  `.rtlif` defaults, external RTL parameter overrides, and generated-child
  parameter overrides.
- The operand must be one list/record aggregate value. FSMGen flips each
  scalar leaf at its existing width, preserves the aggregate shape, and folds
  the result before HDL lowering.
- Scalar operands, missing operands, and unparenthesized multiple operands
  are rejected before HDL generation with targeted diagnostics.
- Runtime direct `.fsm` aggregate-to-aggregate operators, ISF runtime
  subaggregate operands, aggregate paths in expression-operator position, VHDL
  aggregate lowering, mixed scalar/aggregate operators, mismatched aggregate
  shapes, and backend-rendered aggregate operators remain deferred.
- Added direct/composition tests, strict supported corpus fixture
  `feature.params_aggregate_unary_complement`, corpus accounting, mdBook
  coverage, and live-doc synchronization.
- Validation passed: focused direct/composition/corpus tests with `Files=6,
  Tests=3287`; supported-corpus gates with `Files=6, Tests=27`;
  feature-backlog audit with `Files=1, Tests=15`; `mdbook build docs/book`;
  and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: Aggregate types — Richer aggregate operator frontier audited
- Completed `RICHER-AGGREGATE-OPERATORS.2`.
- The shipped aggregate operator surface is currently semantic
  parameter/generic value folding before HDL lowering: matching list/record
  aggregate operands support leafwise numeric and bitwise operators with
  fixed-width unsigned scalar leaves and fail-closed arithmetic diagnostics.
- Selected `RICHER-AGGREGATE-OPERATORS.3` as the next bounded implementation
  leaf: unary bitwise aggregate complement through `(~ VALUE)` and
  `(not VALUE)` in the same parameter/generic value path.
- Runtime direct `.fsm` aggregate-to-aggregate operators, ISF runtime
  subaggregate operands, aggregate paths in expression-operator position, VHDL
  aggregate lowering, mixed scalar/aggregate operators, and mismatched shapes
  remain deferred.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed.
- Validation passed: focused aggregate-operator and ISF-deferral tests with
  `Files=9, Tests=174`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `RICHER-AGGREGATE-OPERATORS`.
- Current frontier: `RICHER-AGGREGATE-OPERATORS.3`.

## 2026-05-24: Aggregate types — Richer aggregate operator frontier selected
- Completed `RICHER-AGGREGATE-OPERATORS.1`.
- Activated the task tree for the mdBook feature-backlog item
  "Richer Aggregate Operators".
- The current frontier is `RICHER-AGGREGATE-OPERATORS.2`, an audit of shipped
  aggregate operator handling and safe next surfaces.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `RICHER-AGGREGATE-OPERATORS`.
- Current frontier: `RICHER-AGGREGATE-OPERATORS.2`.

## 2026-05-24: Aggregate types — Backend-owned struct lowering audit closed
- Completed `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2` and closed the
  task tree.
- Exact-contract Verilog-family aggregate declarations already use the shared
  backend-owned packed typedef path for generated-module ports, direct
  internal/helper declarations, structural composition ports/nets, projected
  child aggregate carriers, and bounded inferred direct targets.
- Broader default lowering remains backlog; FSMGen must not infer
  hardware-visible structs from partial use, width-only evidence, anonymous
  guesses, or unsupported backend targets.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed.
- Validation passed: focused aggregate typedef and ISF-boundary tests with
  `Files=7, Tests=45`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: Aggregate types — Backend-owned struct lowering frontier selected
- Completed `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.1`.
- Activated the task tree for the mdBook feature-backlog item
  "Backend-Owned Struct/Record Default Lowering".
- The current frontier is
  `BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.2`, an audit of shipped
  structured typedef/declaration emission and safe next surfaces.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed.
- Validation passed: feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: Aggregate types — Member/index-root autogrowth audited and tree closed
- Completed `AGGREGATE-AUTOGROWTH-FROM-USAGE.6` and closed the task tree.
- Member/index-root aggregate autogrowth remains backlog for RTL safety:
  partial use does not prove complete root shape, record/list boundary, list
  length, member order, packed layout, anonymous type name, or conflict policy.
- Current diagnostics remain intentional: direct `.fsm` member access requires
  a declared aggregate root, and composition aggregate member/item top
  expressions require a declared aggregate root top port.
- The shipped autogrowth boundary is complete compile-time evidence only:
  whole aggregate constant roots and list-only direct RHS concat.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed in this audit slice.
- Validation passed: focused direct/composition aggregate tests with `Files=5,
  Tests=3124`; feature-backlog audit with `Files=1, Tests=15`;
  `mdbook build docs/book`; and `git diff --check`.
- Active task tree: `none`.
- Current frontier: `none`.

## 2026-05-24: Aggregate types — Direct RHS concat target list autogrowth shipped
- Completed `AGGREGATE-AUTOGROWTH-FROM-USAGE.5`.
- Direct `.fsm` whole-signal targets with no explicit declaration now infer a
  generated list aggregate contract from direct RHS concat expressions when
  every operand has exact scalar/list/record type evidence.
- Nested concat operands preserve nested list shape; SystemVerilog output uses
  generated packed typedef ports instead of flattening those targets to
  width-only metadata.
- Explicit target declarations remain authoritative, and anonymous record
  inference from concat remains out of scope.
- Added `t/1321-direct-aggregate-autogrowth.t` coverage and supported corpus
  entry `feature.direct_rhs_concat_target_autogrowth`.
- The current frontier is `AGGREGATE-AUTOGROWTH-FROM-USAGE.6`, an audit of
  member/index-root aggregate autogrowth.
- Validation passed: parser/corpus syntax checks; direct/corpus tests with
  `Files=3, Tests=3107`; supported-corpus behavior/json/manifest/accounting
  gates with `Files=6, Tests=27`; feature-backlog audit with `Files=1,
  Tests=15`; `mdbook build docs/book`; and
  `git diff --check`.

## 2026-05-24: Aggregate types — Direct RHS concat autogrowth audited
- Completed `AGGREGATE-AUTOGROWTH-FROM-USAGE.4`.
- Direct RHS concat already builds aggregate source contracts for declared
  aggregate targets: ordered list shape for list targets, nested list shape
  for nested concat operands, and target-aware record mapping when a declared
  record target supplies member names.
- The current frontier is `AGGREGATE-AUTOGROWTH-FROM-USAGE.5`, which will
  implement undeclared whole-signal list contract inference from direct RHS
  concat expressions with exact operand type specs.
- Anonymous record autogrowth from concat, no-width operands, partial paths,
  child endpoints, compound updates, VHDL aggregate lowering, and explicit
  target declaration overrides remain out of scope.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed in this audit slice.
- Validation passed: focused concat/corpus tests with `Files=3, Tests=3088`;
  feature-backlog audit with `Files=1, Tests=15`; `mdbook build docs/book`;
  and `git diff --check`.

## 2026-05-24: Aggregate types — Aggregate constant target autogrowth shipped
- Completed `AGGREGATE-AUTOGROWTH-FROM-USAGE.3`.
- Direct `.fsm` whole-signal targets with no explicit declaration now infer a
  generated aggregate type contract from whole aggregate RHS constant roots
  that already carry one canonical list or record payload shape.
- SystemVerilog output preserves the inferred target as a packed typedef port
  instead of flattening it to width-only metadata.
- Explicit target declarations remain authoritative; conflicting later
  aggregate constants fail closed; direct RHS concat autogrowth, arbitrary
  member/index root autogrowth, child endpoint inference, VHDL aggregate
  lowering, backend-owned struct lowering policy, and width-only aggregate
  compatibility remain out of scope.
- Added `t/1321-direct-aggregate-autogrowth.t` and supported corpus entry
  `feature.direct_aggregate_constant_target_autogrowth`.
- The current frontier is `AGGREGATE-AUTOGROWTH-FROM-USAGE.4`, an audit of
  direct RHS concat target autogrowth.
- Validation passed: parser/corpus syntax checks; direct/corpus tests with
  `Files=3, Tests=3085`; supported-corpus behavior/json/manifest/accounting
  gates with `Files=6, Tests=27`; feature-backlog audit with `Files=1,
  Tests=15`; `mdbook build docs/book`; and
  `git diff --check`.

## 2026-05-24: Aggregate types — Aggregate autogrowth frontier audited
- Completed `AGGREGATE-AUTOGROWTH-FROM-USAGE.2`.
- Audited shipped aggregate-growth behavior across direct `.fsm`,
  composition, ISF lowering, tests, corpus accounting, mdBook, and live docs.
- The current frontier is `AGGREGATE-AUTOGROWTH-FROM-USAGE.3`.
- The selected implementation surface is direct whole-signal LHS aggregate
  contract inference from a whole aggregate RHS constant root.
- Direct `.fsm` declared aggregate anchors, aggregate constants, typed
  member/item paths, partial aggregate LHS writes, whole aggregate RHS shape
  checks, concat/deconstruct aggregate source contracts, and bounded
  composition aggregate top-port inference are already shipped on their
  documented surfaces.
- Direct RHS concat autogrowth, arbitrary member/index root autogrowth, child
  endpoint inference, VHDL aggregate lowering, backend-owned struct lowering
  policy, and width-only aggregate compatibility remain out of scope.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed in the audit slice.
- Validation passed: focused aggregate/corpus tests with `Files=6,
  Tests=3085`; `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: Aggregate types — Aggregate autogrowth frontier selected
- Completed `AGGREGATE-AUTOGROWTH-FROM-USAGE.1`.
- Activated the active aggregate-types task tree for the mdBook
  feature-backlog item "Automatic Aggregate Growth From Usage".
- The current frontier is `AGGREGATE-AUTOGROWTH-FROM-USAGE.2`.
- The follow-up leaf must audit shipped aggregate inference across direct
  `.fsm`, composition, ISF lowering, tests, corpus accounting, mdBook, and
  live docs before selecting one bounded behavior-bearing source position.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed.
- Validation passed: live-book, spec-index, and feature-backlog audits with
  `Files=3, Tests=351`; `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: Language ergonomics — Direct runtime literal-zero divisor rejection shipped
- Completed `DYNAMIC-DIVISOR-SAFETY-FRONTIER.3` and closed the task tree.
- Direct `.fsm` runtime expression parsing now rejects numeric and exact-width
  literal-zero divisor operands for `/`, `%`, `div`, and `mod` before HDL
  emission.
- Nonzero literal divisors and dynamic signal divisors remain accepted and
  lower unchanged.
- Added focused parser tests in `t/1320-direct-runtime-divisor-safety.t`.
- Added expected-failure corpus fixtures
  `contract.direct_runtime_divide_literal_zero` and
  `contract.direct_runtime_modulo_exact_zero`.
- The mdBook, regression corpus docs, diagnostic-code metadata, corpus
  accounting, task tree, roadmap status, and live continuity docs were
  synchronized.
- Broader dynamic range/dataflow nonzero proofs remain future work.
- Validation passed: syntax checks; focused direct parser/corpus accounting
  with `Files=2, Tests=3064`; expected-failure corpus behavior with
  `Files=1, Tests=5`; check/semantic JSON and diagnostic registry gates with
  `Files=3, Tests=5`; capability/support-accounting gates with
  `Files=3, Tests=13`; supported-corpus gates with `Files=2, Tests=10`;
  language-surface gates with `Files=2, Tests=6`; ISF/direct arithmetic
  regression checks with `Files=2, Tests=24`; `mdbook build docs/book`; and
  `git diff --check`.

## 2026-05-24: Language ergonomics — Dynamic divisor safety frontier audited
- Completed `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2`.
- Audited shipped divide/modulo safety across direct `.fsm`, ISF lowering,
  tests, corpus accounting, mdBook, and live docs.
- Direct `.fsm` `+size` width expressions and aggregate `+params` expression
  folding already reject divide/modulo by zero before HDL emission.
- ISF runtime expressions already reject literal-zero, actor-constant-zero,
  and actor-parameter-zero divisors before scheduled `.fsm` emission.
- The current frontier is `DYNAMIC-DIVISOR-SAFETY-FRONTIER.3`.
- The selected implementation surface is direct `.fsm` runtime expression
  parsing: reject numeric/exact-width literal-zero divisors in `/`, `%`,
  `div`, and `mod` expressions before HDL emission.
- Broader dynamic dataflow/range nonzero proofs remain out of scope.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed in the audit slice.
- Validation passed: `perl -Iperl -c
  perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm`; focused ISF/direct/corpus
  tests with `Files=3, Tests=3057`; `mdbook build docs/book`; and
  `git diff --check`.

## 2026-05-24: Language ergonomics — Dynamic divisor safety frontier selected
- Completed `DYNAMIC-DIVISOR-SAFETY-FRONTIER.1`.
- Activated the active language-ergonomics task tree for the mdBook
  feature-backlog item "Dynamic Divisor Safety Proofs".
- The current frontier is `DYNAMIC-DIVISOR-SAFETY-FRONTIER.2`.
- The follow-up leaf must audit shipped divide/modulo safety across direct
  `.fsm`, composition, ISF lowering, tests, corpus accounting, mdBook, and
  live docs before selecting one bounded behavior-bearing proof surface.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed.
- Validation passed: live-book, spec-index, and feature-backlog audits with
  `Files=3, Tests=351`; `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: Language ergonomics — Symbolic scalar type widths shipped
- Completed `INFERENCE-FIRST-SCALAR-AUTHORING.3` and closed the task tree.
- Scalar `+types` now accept `(bits WIDTH_SYMBOL)` across direct-root,
  package, and composition-top paths when the width symbol resolves to a
  positive integer scalar constant or enum member in the available symbol
  scope.
- Signed, `two_state`, and `four_state` wrappers preserve the resolved width;
  composition local type specs can defer imported package width symbols until
  package-import finalization.
- Aggregate scalar leaves, parameters, runtime signals, and arbitrary
  expressions remain outside the declarative `(bits WIDTH_SYMBOL)` surface.
- The mdBook, regression corpus docs, capability/language-surface metadata,
  task tree, roadmap status, and live continuity docs were synchronized.
- Validation passed: syntax checks; focused scalar type tests with
  `Files=1, Tests=18`; corpus accounting with `Files=1, Tests=3033`;
  supported language-feature corpus with `Files=1, Tests=2`;
  language-surface/capability-manifest gates with `Files=3, Tests=10`;
  supported-corpus/semantic-JSON gates with `Files=2, Tests=10`;
  aggregate/structural type gates with `Files=2, Tests=10`;
  `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: Language ergonomics — Scalar inference frontier audited
- Completed `INFERENCE-FIRST-SCALAR-AUTHORING.2`.
- Audited the shipped scalar-inference boundary across direct `.fsm`,
  composition, ISF lowering, tests, corpus accounting, mdBook, and live docs.
- The current frontier is `INFERENCE-FIRST-SCALAR-AUTHORING.3`.
- The selected implementation surface is positive integer scalar width symbols
  inside declarative `(bits WIDTH_SYMBOL)` type specs.
- Arbitrary type-width expressions, aggregate leaf paths, runtime signals,
  parameter-specialization values, broad scalar autodeclaration, and aggregate
  autovivification remain out of scope.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed in the audit slice.
- Validation passed: `perl -Iperl -c t/279-declarative-scalar-types.t`;
  focused scalar/corpus tests with `Files=3, Tests=3036`;
  `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: Language ergonomics — Inference-first scalar authoring selected
- Completed `INFERENCE-FIRST-SCALAR-AUTHORING.1`.
- Activated the active language-ergonomics task tree for the mdBook
  feature-backlog item "Inference-First Scalar Authoring".
- The current frontier is `INFERENCE-FIRST-SCALAR-AUTHORING.2`.
- The follow-up leaf must audit the shipped scalar-inference boundary, current
  corpus, live docs, and deferred source positions before choosing one bounded
  behavior-bearing implementation surface.
- No parser, scheduler, report, generated artifact, HDL, CLI, public API, or
  public language behavior changed.
- Validation passed: `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`;
  live-book, spec-index, and feature-backlog audits with `Files=3, Tests=351`;
  `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: Roadmap maintenance — Feature-backlog owner coverage synchronized
- Completed `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.2` and closed the task tree.
- `docs/TASK_TREE.md` now lists every top-level mdBook feature-backlog category
  with its tracking stance.
- The mdBook feature backlog now points to that owner coverage policy and says
  categories marked `future task tree required` are not implementation
  permission slips.
- `t/1305-isf-book-feature-matrix-audit.t` verifies the category set, the
  owner coverage rows, and the future-task-tree wording.
- No parser, scheduler, report, generated artifact, HDL, CLI, or public API
  behavior changed.
- Validation passed: `perl -Iperl -c t/1305-isf-book-feature-matrix-audit.t`;
  `prove -Iperl t/1305-isf-book-feature-matrix-audit.t` with
  `Files=1, Tests=326`; live-book/spec index audits with `Files=2, Tests=25`;
  `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: Roadmap maintenance — Feature-backlog owner coverage selected
- Completed `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.1`.
- Activated the active roadmap-maintenance task tree for broad mdBook
  feature-backlog owner coverage synchronization.
- The current frontier is `FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.2`.
- The follow-up leaf must make the task-tree owner coverage table and mdBook
  backlog agree on broad backlog owner status and add focused audit coverage
  if needed.
- No parser, scheduler, report, generated artifact, HDL, CLI, or public API
  behavior changed.
- Validation passed: live-book/spec index audits with `Files=2, Tests=25`;
  `mdbook build docs/book`; and `git diff --check`.

## 2026-05-24: R14 — Round-robin resource arbitration shipped
- Completed `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2` and closed the task tree.
- FSMGen now supports bounded `(kind rule_slot)` resources with
  `(arbiter round_robin)` and declared rule users.
- Lowering emits a generated `isf_rr_<resource>_turn` pointer counter, grants
  the first requesting rule at or after that pointer in circular `(users ...)`
  order, gates the winning rule DT, and advances the pointer only from the
  winning rule DT.
- Schedule reports expose grants through `resource_arbitration[]` with
  `arbiter: round_robin`, and expose the generated pointer in
  `inferred_storage[]` with role `resource_round_robin_pointer`.
- Non-`rule_slot` round-robin resources, transaction users, generated-child
  resources, actor-network endpoint users, storage lifetime ownership,
  hold/release ownership, ready/backpressure, route mux/storage, invalid
  generated pointer names, pointer collisions, and multi-resource
  round-robin rule-user ownership remain fail-closed or deferred as
  documented.
- Validation passed: syntax checks; focused resource/report/public-contract
  and docs audits with `Files=11, Tests=378`; `mdbook build docs/book`; broad
  `./bin/ci-regression isf --no-book` with `Files=250, Tests=1667`; and
  `git diff --check`.

## 2026-05-24: R14 — Round-robin resource arbitration selected
- Completed `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.1`.
- Activated the active R14 task tree for bounded `(kind rule_slot)`
  `round_robin` arbitration over declared rule users.
- The active implementation frontier is
  `ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.2`.
- The selected implementation must generate an actor-local pointer, use
  circular `(users ...)` order, grant the first requesting user at or after
  that pointer, advance the pointer only when a grant executes, gate the whole
  winning rule DT, and expose grants through `resource_arbitration[]`.
- Other `round_robin` resource kinds, transaction users, generated-child
  resources, actor-network endpoint users, storage lifetime ownership,
  hold/release ownership, ready/backpressure, and route mux/storage remain
  deferred.
- No parser, scheduler, report, generated artifact, HDL, CLI, or public ISF
  behavior changed.

## 2026-05-24: R14 — Storage-port member documentation truth sync
- Completed `ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.1` and closed the task tree.
- Corrected stale spec wording so the public docs no longer imply
  `(members ...)` is accepted only for `(kind output_bundle)`.
- The shipped boundary is unchanged: `(members ...)` is accepted for
  `(kind output_bundle)` and `(kind storage_port)`, while `storage_port`
  members remain explicit concrete actor-owned storage signals for bound
  declared rule users.
- No parser, scheduler, report, generated artifact, HDL, CLI, public contract,
  or public runtime behavior changed.
- Validation passed: stale-wording audit over source docs; public live-book,
  spec-index, and feature-matrix audits with `Files=3, Tests=339`;
  `mdbook build docs/book`; and `git diff --check`.

## 2026-05-23: Project operations — Feature-backlog status audit CI repair
- Completed `CI-FEATURE-BACKLOG-STATUS-AUDIT.1` and closed the task tree.
- Reproduced the latest `Perl FSM Regression` failure locally:
  `t/1256-feature-backlog-status-audit.t` expected `Automatic Aggregate Growth
  From Usage` to be `Status: backlog.`, while the mdBook now correctly records
  `Status: partially shipped; broader inference surfaces remain backlog.`
- Updated the audit expectation to follow the mdBook truth.
- Triaged the earlier `Publish mdBook` failure as a Pages deploy
  `Bad credentials` run that was followed by a later successful `Publish
  mdBook` run with the same workflow file, so no Pages workflow change was
  required.
- Validation passed: focused failing audit with `Files=1, Tests=15`;
  live-doc audits with `Files=2, Tests=25`; `git diff --check`; full local
  `./bin/ci-regression` with `Files=1346, Tests=9515`, followed by a
  successful mdBook build.

## 2026-05-23: R14 — Storage-port resource priority shipped
- Completed `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2` and closed the task tree.
- `(kind storage_port)` resources now enforce static `priority` arbitration
  for declared rule users.
- Bound storage-port resources require explicit `(members ...)`, and each
  member must name a concrete actor-owned storage signal: scalar storage
  variables or scalarized bank element signals.
- Parser validation rejects output ports, actor input ports, transaction
  ports, bank roots, aggregate paths, inferred undeclared targets, and
  arbitrary expressions as storage-port members.
- Lowering gates losing rule DTs before their assignments can update the
  protected storage signals. The shipped subset is whole-rule one-cycle
  grant gating, not route mux/storage, storage locks, fairness state, or
  hold/release ownership.
- Schedule reports expose successful grants through
  `resource_arbitration[]` with `kind: storage_port` and the explicit
  `members` array.
- Validation passed: syntax checks; focused resource/report tests with
  `Files=3, Tests=20`; public/spec/book audits with `Files=8, Tests=344`;
  `mdbook build docs/book`; broad `./bin/ci-regression isf --no-book` with
  `Files=250, Tests=1665`; post-closure public/doc audits with
  `Files=6, Tests=347`; and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Storage-port resource priority selected
- Completed `ISF-STORAGE-PORT-RESOURCE-PRIORITY.1`.
- Activated the active R14 task tree for bounded `(kind storage_port)`
  priority arbitration over declared rule users with explicit actor-owned
  storage members.
- The active implementation frontier is
  `ISF-STORAGE-PORT-RESOURCE-PRIORITY.2`.
- The selected path requires an explicit `(members ...)` list and limits those
  members to concrete actor-owned storage signals: scalar storage variables
  and scalarized bank element signals.
- The implementation slice must reuse static priority grant gating on bound
  rule DTs and must not add route mux/storage, storage locks, fairness state,
  hold/release ownership, or broader member domains.
- No parser, scheduler, report, generated artifact, HDL, CLI, or public ISF
  behavior changed.
- Validation passed: live-doc/spec index audits with `Files=2, Tests=25`;
  `git diff --check`.

## 2026-05-23: R14 — Transaction-start resource priority shipped
- Completed `ISF-TRANSACTION-START-RESOURCE-PRIORITY.2` and closed the task
  tree.
- `(kind transaction_start)` resources now enforce static `priority`
  arbitration for declared rule users.
- The resource name must be a declared local transaction, and every bound rule
  user must trigger that transaction through the shipped non-generated
  rule-trigger surface.
- Lowering gates losing rule DTs before their trigger source pulses feed the
  generated `rule_trigger_fanin` DT, preserving the fan-in owner and one-cycle
  trigger timing.
- Schedule reports expose successful grants through
  `resource_arbitration[]` with `kind: transaction_start` and an empty
  `members` array.
- Unsupported arbiters and broader resource ownership remain deferred:
  `round_robin`, non-rule users, generated-child transaction starts,
  actor-network triggers, transaction lifetime ownership, ready/backpressure,
  route mux/storage, multi-capacity resources, and dynamic resource names.
- Validation passed: syntax checks; focused resource/report tests with
  `Files=3, Tests=17`; public/spec/book audits with `Files=8, Tests=341`;
  `mdbook build docs/book`; broad `./bin/ci-regression isf --no-book` with
  `Files=250, Tests=1662`; post-closure public/doc audits with
  `Files=6, Tests=347`; and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Transaction-start resource priority selected
- Completed `ISF-TRANSACTION-START-RESOURCE-PRIORITY.1`.
- Activated the active R14 task tree for bounded `(kind transaction_start)`
  priority arbitration over declared rule users.
- The active implementation frontier is
  `ISF-TRANSACTION-START-RESOURCE-PRIORITY.2`.
- No parser, scheduler, report, generated artifact, HDL, CLI, or public ISF
  behavior changed.
- Validation passed: live-doc/spec index audits with `Files=2, Tests=25`;
  `git diff --check`.

## 2026-05-23: R14 — Output-bundle roadmap wording cleanup
- Completed `ROADMAP-R14-OUTPUT-BUNDLE-WORDING-CLEANUP.1` and closed the
  one-leaf roadmap-maintenance task tree.
- Repaired duplicated `explicit` wording and a split `route mux/storage`
  phrase in `ROADMAP_STATUS.md` after the output-bundle member-domain truth
  sync.
- No parser, scheduler, report, HDL, CLI, public contract, spec, downstream
  handoff, mdBook, or public ISF behavior changed.
- Validation passed: focused text checks and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Output-bundle storage members shipped
- Completed `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` and closed the task tree.
- Explicit `(members name...)` lists for `output_bundle` resources may now
  name declared actor output ports or concrete actor-owned storage signals.
- Parser validation rejects explicit members that are not declared actor
  outputs or actor-owned storage signals.
- Lowering keeps the existing one-cycle static priority grant model and fails
  closed when explicit members do not match bound rule writes in those
  declared domains.
- Schedule reports keep the existing `resource_arbitration[].members` array;
  it now may contain declared output names or actor-owned storage signal names.
- Bank roots, aggregate paths, inferred undeclared LHS targets,
  actor-network endpoints, output-target users, transaction users,
  named-drive users, child-instance users, storage-port resources, route
  mux/storage, fairness, hold/release, multi-capacity resources, and broader
  `round_robin` beyond the later-shipped bounded `rule_slot` subset remain
  deferred.
- Validation passed: syntax checks; focused resource/public/spec/book tests
  with `Files=10, Tests=342`; `mdbook build docs/book`; broad
  `./bin/ci-regression isf --no-book` with `Files=250, Tests=1659`;
  post-closure public/doc audits with `Files=6, Tests=347`; and
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Output-bundle storage members selected
- Completed selection work for `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.1`.
- Activated the active R14 task tree for widening explicit `output_bundle`
  members to actor-owned storage signals.
- The selected implementation is intentionally bounded to concrete scalar
  storage signals: scalar vars and scalarized bank element signals. Bank
  roots, aggregate paths, inferred undeclared LHS targets, actor-network
  endpoints, output-target users, transaction users, named-drive users,
  child-instance users, storage-port resources, route mux/storage, fairness,
  hold/release, multi-capacity resources, and broader `round_robin` beyond the
  later-shipped bounded `rule_slot` subset remain deferred.
- No parser, scheduler, report, generated artifact, HDL, CLI, or public ISF
  behavior changed.
- Validation passed: live-doc/spec index audits with `Files=2, Tests=25`;
  `git diff --check`.

## 2026-05-23: R14 — Output-bundle wording truth sync
- Completed `ISF-OUTPUT-BUNDLE-MEANING-TRUTH-SYNC.1`.
- Public docs now distinguish unmembered `output_bundle` resources, which keep
  the historical implicit bound-rule output/LHS-target surface, from the
  explicit member-list surface shipped in the previous slice. That slice
  initially limited explicit members to declared actor outputs; the later
  `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` slice widened explicit members to
  concrete actor-owned storage signals.
- No parser, scheduler, emitter, HDL, CLI, report schema, or public resource
  catalog behavior changed.
- Validation passed: focused public-doc audits with `Files=6, Tests=347`;
  `mdbook build docs/book`; stale-wording search; and `git diff --check`.

## 2026-05-23: R14 — Output-bundle member list shipped
- Completed `ISF-OUTPUT-BUNDLE-MEMBER-LIST.2` and closed the task tree.
- `output_bundle` resources initially accepted explicit member-list
  subclauses naming declared actor output ports. The later
  `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` slice widened explicit members to
  concrete actor-owned storage signals as well.
- Unmembered output bundles still represent the historical implicit
  bound-rule driven output/LHS-target surface; explicit members are the
  narrower declared-output validation/reporting surface.
- Parser validation rejects malformed, duplicate, non-output, and
  wrong-kind member lists before actor-shell handoff.
- Lowering keeps the existing one-cycle static priority grant model and fails
  closed when an explicit member list does not match bound rule output writes.
- Schedule reports now include `members` on `resource_arbitration[]` entries;
  the array is empty unless an explicit output-bundle member list is present.
- Input ports, aggregate paths, actor-network endpoints, output-target users,
  transaction users, named-drive users, route mux/storage,
  fairness, hold/release, multi-capacity resources, and `round_robin` remain
  deferred as explicit member or routing surfaces.
- Validation passed: syntax checks; focused resource/public/spec/book tests
  with `Files=10, Tests=342`; `mdbook build docs/book`; fixture expectation
  sync checks with `Files=3, Tests=7`; broad
  `./bin/ci-regression isf --no-book` with `Files=250, Tests=1659`;
  post-closure public/doc audits with `Files=6, Tests=347`; and
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Output-bundle member list selected
- Completed selection work for `ISF-OUTPUT-BUNDLE-MEMBER-LIST.1`.
- Activated the active R14 task tree for explicit `output_bundle`
  member-list syntax.
- The selected path initially accepted explicit member lists only on
  `(kind output_bundle)` resources, validates members as declared actor output
  ports, preserves the existing static priority grant model for declared rule
  users, and adds bounded member evidence to the public report surface when
  implementation lands. The later storage-member slice widened the explicit
  member domain to concrete actor-owned storage signals.
- The active frontier is now `ISF-OUTPUT-BUNDLE-MEMBER-LIST.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Output-bundle resource priority shipped
- Completed `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.2` and closed the task tree.
- `output_bundle` resources now enforce static `priority` arbitration for
  declared rule users. Bound rules request when their guards are true, the
  priority graph chooses a unique winner, and losing rule DTs are guarded off
  without adding a cycle.
- The public resource catalog now lists `output_bundle` as enforced, and
  schedule reports keep the existing `resource_arbitration[]` entry shape with
  `kind: output_bundle`.
- Unsupported resource kinds, `round_robin`, non-rule users, target-member
  syntax, route mux/storage, fairness, and hold/release semantics remain
  deferred.
- Validation passed: syntax checks; focused resource/public/spec/book tests
  with `Files=8, Tests=336`; `mdbook build docs/book`; broad
  `./bin/ci-regression isf --no-book` with `Files=250, Tests=1657`;
  post-closure doc/public audits with `Files=6, Tests=347`;
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Output-bundle resource priority selected
- Completed selection work for `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.1`.
- Activated the active R14 task tree for bounded `output_bundle` resource
  enforcement.
- The selected path enforces `output_bundle` resources only for declared rule
  users under the existing static `priority` arbiter, reusing the shipped
  rule-DT grant-gating shape and preserving `resource_arbitration[]` report
  keys.
- The active frontier is now `ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Transaction-over-rule priority shipped
- Completed `ISF-TRANSACTION-OVER-RULE-PRIORITY.2` and closed the task tree.
- Scheduled `.fsm` now accepts bounded `(state_active STATE)` guard
  expressions that validate against declared regular FSM states and lower to
  internal `current_state == STATE` comparisons without creating fake authored
  input ports.
- ISF now lowers the covered same-target data case where a transaction wins
  over a rule. The winning transaction assignment remains unchanged in its
  transaction state DT, and the lower-priority non-state rule assignment is
  guarded off while that transaction state is active.
- The existing `priority_resolutions[]` report shape records the transaction
  winner and rule loser. Transaction/transaction priority, drive/rule
  arbitration, broader resource arbitration, and transaction lifetime
  ownership remain deferred.
- Validation passed: syntax checks; focused state-active/priority/public/
  spec/book tests with `Files=10, Tests=342`; `mdbook build docs/book`;
  broad `./bin/ci-regression isf --no-book` with `Files=250, Tests=1656`;
  post-closure doc/public audits with `Files=6, Tests=347`;
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Transaction-over-rule priority selected
- Completed selection work for `ISF-TRANSACTION-OVER-RULE-PRIORITY.1`.
- Activated the active R14 task tree for the covered same-target data case
  where a transaction is declared higher priority than a rule.
- The selected path first introduces a bounded scheduled `.fsm` state-active
  guard surface that does not create fake `current_state`, state-name, or
  generated `STATE_en` input ports, then uses it to suppress the lower-priority
  rule assignment while the winning transaction state is active.
- The active frontier is now `ISF-TRANSACTION-OVER-RULE-PRIORITY.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Assemble static part widths shipped
- Completed `ISF-ASSEMBLE-STATIC-PART-WIDTHS.2` and closed the task tree.
- `assemble` now accepts optional trailing
  `(widths N|PARAM|CONST...)` part-width evidence after the target.
- Accepted part widths lower like known part widths in width fact collection,
  assembled-target width derivation, later data-operation consumers,
  schedule-report storage width metadata, and generated HDL.
- Existing `assemble` concat emission, state timing, report key families,
  generated handoff naming, plain-form behavior, single-unknown-part
  inference, and multiple-unknown non-evidence concat lowering remain
  unchanged.
- Unsupported width sources fail closed: transaction parameters, runtime
  interface signals, arbitrary expressions, unknown names, zero values,
  aggregate values, activation override specialization, generated-top
  respecialization, and broader multiple-unknown inference.
- Validation passed: syntax checks; focused assemble/data-operation/public/
  spec/book tests with `Files=14, Tests=358`; `mdbook build docs/book`;
  broad `./bin/ci-regression isf --no-book` with `Files=250, Tests=1656`;
  post-closure doc/public audits with `Files=7, Tests=352`;
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Assemble static part widths selected
- Completed selection work for `ISF-ASSEMBLE-STATIC-PART-WIDTHS.1`.
- Activated the active R14 task tree for optional `assemble` part-width
  evidence using positive integer literals, actor-local scalar parameter
  defaults, and declared actor constants.
- The active frontier is now `ISF-ASSEMBLE-STATIC-PART-WIDTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Data operation static width sources shipped
- Completed `ISF-DATA-OP-STATIC-WIDTH-SOURCES.2` and closed the task tree.
- `shift_left`, `shift_right`, and `extract` explicit width evidence now
  accepts actor-local scalar parameter defaults and declared actor constants
  that resolve to positive integers.
- Accepted static values lower like literal widths in width fact collection,
  scheduled `.fsm` shift insert positions and extraction slices,
  schedule-report storage width metadata, and generated HDL.
- Unsupported sources fail closed: transaction parameters, runtime interface
  signals, arbitrary expressions, unknown names, zero values, aggregate values,
  use-site/generated-top respecialization, new `assemble` syntax, timing
  changes, generated handoff naming changes, activation binding semantics
  changes, and schedule-report key-family changes.
- Validation passed: syntax checks; focused data-operation/public/spec/book
  tests with `Files=11, Tests=342`; `mdbook build docs/book`; broad
  `./bin/ci-regression isf --no-book` with `Files=249, Tests=1652`;
  post-closure doc/public audits with `Files=7, Tests=352`;
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Data operation static width sources selected
- Completed selection work for `ISF-DATA-OP-STATIC-WIDTH-SOURCES.1`.
- Activated the active R14 task tree for actor-local scalar parameter defaults
  and declared actor constants as existing `shift_left`, `shift_right`, and
  `extract` width-evidence sources when those values resolve to positive
  integers.
- The active frontier is now `ISF-DATA-OP-STATIC-WIDTH-SOURCES.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Transaction port actor-constant widths shipped
- Completed `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2` and closed the
  task tree.
- Transaction-local `(ports ...)` `(width CONST)` declarations now accept
  declared actor constants resolving to positive integers.
- Accepted constant-backed widths lower like literal widths in public parser
  handoff, scheduled `.fsm` `+size`, activation handoff storage,
  `transaction_port_bindings[]` report widths, and generated HDL, while
  authored constants remain visible through `actor_constants[]` and scheduled
  `+constants`.
- Unsupported sources fail closed: transaction parameters, runtime interface
  signals, unknown symbolic names, zero-valued constants, non-scalar constant
  definitions, arbitrary expressions, use-site override specialization,
  generated-top respecialization, activation binding semantics changes,
  binding timing changes, output binding shape changes, and schedule-report
  key-family changes.
- Validation passed: syntax checks; focused transaction-port/public/spec/book
  tests with `Files=12, Tests=349`; `mdbook build docs/book`; broad
  `./bin/ci-regression isf --no-book` with `Files=248, Tests=1649`;
  post-closure doc/public audits with `Files=7, Tests=352`;
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Transaction port actor-constant widths selected
- Completed selection work for
  `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.1`.
- Activated the active R14 task tree for transaction-local `(ports ...)`
  `(width CONST)` declarations backed by actor-local constants resolving to
  positive integers.
- The active frontier is now
  `ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Bank storage actor-constant depths shipped
- Completed `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.2` and closed the task
  tree.
- Actor-owned bank storage `(depth CONST)` declarations now accept declared
  actor constants resolving to positive integers.
- Accepted constant-backed depths lower like literal depths in public parser
  handoff, deterministic scalarized storage family generation, scheduled
  `.fsm` `+size`, schedule-report `actor_storage` entries,
  `bank_accesses[]` depth/scalar-entry metadata, and generated HDL, while
  authored constants remain visible through `actor_constants[]` and scheduled
  `+constants`.
- Unsupported sources fail closed: unknown symbols, runtime interface signals,
  zero-valued constants, non-scalar values, arbitrary expressions,
  transaction-local port widths, use-site override specialization,
  generated-top respecialization, memory-array backend emission, dynamic
  storage depth, pointer-index semantic changes, and same-cycle bank policy
  changes.
- Validation passed: syntax checks; focused bank/public/spec/book tests with
  `Files=11, Tests=345`; `mdbook build docs/book`; broad
  `./bin/ci-regression isf --no-book` with `Files=247, Tests=1646`;
  post-closure doc/public audits with `Files=6, Tests=348`;
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Bank storage actor-constant depths selected
- Completed selection work for
  `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.1`.
- Activated the active R14 task tree for actor-owned bank storage
  `(depth CONST)` declarations backed by actor-local constants resolving to
  positive integers.
- The active frontier is now `ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Bank storage actor-constant widths shipped
- Completed `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2` and closed the task
  tree.
- Actor-owned bank storage `(width CONST)` declarations now accept declared
  actor constants resolving to positive integers.
- Accepted constant-backed widths lower like literal widths in public parser
  handoff, scalarized bank storage entries, scheduled `.fsm` `+size`,
  schedule-report `actor_storage` and `bank_accesses[]` widths, and generated
  HDL, while authored constants remain visible through `actor_constants[]` and
  scheduled `+constants`.
- Unsupported sources fail closed: unknown symbols, runtime interface signals,
  zero-valued constants, arbitrary expressions, bank depths,
  transaction-local port widths, use-site override specialization,
  generated-top respecialization, memory-array backend emission, dynamic
  storage depth, pointer-index semantic changes, and same-cycle bank policy
  changes.
- Validation passed: syntax checks; focused bank/public tests with
  `Files=11, Tests=343`; `mdbook build docs/book`; broad
  `./bin/ci-regression isf --no-book` with `Files=246, Tests=1641`;
  post-closure doc/public audits with `Files=6, Tests=348`;
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Bank storage actor-constant widths selected
- Completed selection work for
  `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.1`.
- Activated the active R14 task tree for actor-owned bank storage
  `(width CONST)` declarations backed by actor-local constants resolving to
  positive integers.
- The active frontier is now `ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Scalar storage actor-constant widths shipped
- Completed `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.2` and closed the task
  tree.
- Actor-owned scalar storage `(width CONST)` declarations now accept declared
  actor constants resolving to positive integers.
- Accepted constant-backed widths lower like literal widths in public parser
  handoff, scheduled `.fsm` `+size`, schedule-report `actor_storage` widths,
  and generated HDL, while authored constants remain visible through
  `actor_constants[]` and scheduled `+constants`.
- Unsupported sources fail closed: unknown symbols, runtime interface signals,
  zero-valued constants, arbitrary expressions, bank widths, bank depths,
  transaction-local port widths, use-site override specialization, and
  generated-top respecialization.
- Validation passed: syntax checks; focused storage/public tests with
  `Files=10, Tests=339`; `mdbook build docs/book`; broad
  `./bin/ci-regression isf --no-book` with `Files=245, Tests=1638`;
  post-closure doc/public audits with `Files=6, Tests=348`;
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Scalar storage actor-constant widths selected
- Completed selection work for
  `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.1`.
- Activated the active R14 task tree for actor-owned scalar storage
  `(width CONST)` declarations backed by actor-local constants resolving to
  positive integers.
- The active frontier is now `ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Interface actor-constant widths shipped
- Completed `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.2` and closed the task tree.
- Actor top-level interface `(width CONST)` declarations now accept declared
  actor constants resolving to positive integers.
- Accepted constant-backed widths lower like literal widths in public parser
  handoff, scheduled `.fsm` `+size`, schedule reports, and generated HDL,
  while authored constants remain visible through `actor_constants[]` and
  scheduled `+constants`.
- Unsupported sources fail closed: unknown symbols, runtime interface signals,
  zero-valued constants, arbitrary expressions, scalar storage widths, bank
  widths, bank depths, transaction-local port widths, use-site override
  specialization, and generated-top respecialization.
- Validation passed: syntax checks; focused public/interface tests with
  `Files=9, Tests=336`; `mdbook build docs/book`; broad
  `./bin/ci-regression isf --no-book` with `Files=244, Tests=1635`;
  post-closure doc/public audits with `Files=6, Tests=348`;
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Interface actor-constant widths selected
- Completed selection work for `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.1`.
- Activated the active R14 task tree for actor top-level interface
  `(width CONST)` declarations backed by actor-local constants resolving to
  positive integers.
- The active frontier is now `ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Bank storage actor-parameter depths shipped
- Completed `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.2` and closed the task tree.
- Actor-owned bank storage entries now accept `(depth PARAM)` when `PARAM`
  names an actor-local scalar parameter default resolving to a positive
  integer.
- Accepted parameter-backed depths lower like literal depths in public parser
  handoff, deterministic scalarized storage family generation, scheduled
  `.fsm` `+size`, schedule reports, `bank_accesses[]` metadata, and generated
  HDL.
- Unsupported depth sources fail closed: actor constants, runtime interface
  signals, unknown names, zero-valued or non-scalar actor parameters,
  arbitrary expressions, use-site override specialization, generated-top
  respecialization, memory-array backend emission, dynamic storage depth, and
  activation-specialized transaction-parameter-like dimensions.
- Validation passed: syntax checks; focused bank depth/width, scalar storage,
  bank-access, public, spec, and book tests with `Files=10, Tests=340`;
  `mdbook build docs/book`; broad `./bin/ci-regression isf --no-book` with
  `Files=243, Tests=1632`; post-closure doc audits with `Files=3,
  Tests=339`; `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Bank storage actor-parameter depths selected
- Completed selection work for
  `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.1`.
- Activated the active R14 task tree for actor-owned bank storage
  `(depth PARAM)` declarations backed by actor-local scalar parameter defaults
  resolving to positive integers.
- The active frontier is now `ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Transaction port actor-parameter widths shipped
- Completed `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2` and closed the task
  tree.
- Transaction-local `(ports ...)` entries now accept `(width PARAM)` when
  `PARAM` names an actor-local scalar parameter default resolving to a
  positive integer.
- Accepted parameter-backed widths lower like literal widths in public parser
  handoff, scheduled `.fsm` `+size`, activation handoff storage,
  `transaction_port_bindings[]` metadata, and generated HDL, while authored
  parameters remain visible through `+params` and `actor_params[]`.
- Unsupported width sources fail closed: transaction parameters, bank depths,
  actor constants, runtime interface signals, zero-valued or non-scalar actor
  parameters, arbitrary expressions, use-site override specialization, and
  generated-top respecialization.
- Validation passed: syntax checks; focused transaction-port, binding,
  public, spec, and book tests with `Files=9, Tests=339`; `mdbook build
  docs/book`; broad `./bin/ci-regression isf --no-book` with `Files=242,
  Tests=1627`; post-closure doc audits with `Files=3, Tests=339`; `git diff
  --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Transaction port actor-parameter widths selected
- Completed selection work for
  `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.1`.
- Activated the active R14 task tree for transaction-local `(ports ...)`
  `(width PARAM)` declarations backed by actor-local scalar parameter defaults
  resolving to positive integers.
- The active frontier is now
  `ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Bank storage actor-parameter widths shipped
- Completed `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.2` and closed the task tree.
- Actor-owned bank storage entries now accept `(width PARAM)` when `PARAM`
  names an actor-local scalar parameter default resolving to a positive
  integer.
- Accepted parameter-backed widths lower like literal widths in public parser
  handoff, scheduled `.fsm` `+size`, schedule reports, `bank_accesses[]`
  metadata, and generated HDL, while authored parameters remain visible
  through `+params` and `actor_params[]`.
- Unsupported width sources fail closed: actor-owned bank depths,
  transaction-local port widths, actor constants, runtime interface signals,
  zero-valued or non-scalar actor parameters, transaction parameters,
  arbitrary expressions, use-site override specialization, and generated-top
  respecialization.
- Validation passed: syntax checks; focused bank/scalar storage,
  bank-access, public, spec, and book tests with `Files=9, Tests=335`;
  `mdbook build docs/book`; broad `./bin/ci-regression isf --no-book` with
  `Files=241, Tests=1624`; post-closure doc audits with `Files=3,
  Tests=339`; `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Bank storage actor-parameter widths selected
- Completed selection work for `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.1`.
- Activated the active R14 task tree for actor-owned bank storage
  `(width PARAM)` declarations backed by actor-local scalar parameter defaults
  resolving to positive integers.
- The active frontier is now `ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Scalar storage actor-parameter widths shipped
- Completed `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.2` and closed the task
  tree.
- Actor-owned scalar storage entries now accept `(width PARAM)` when `PARAM`
  names an actor-local scalar parameter default resolving to a positive
  integer.
- Accepted parameter-backed widths lower like literal widths in public parser
  handoff, scheduled `.fsm` `+size`, schedule reports, and generated HDL,
  while authored parameters remain visible through `+params` and
  `actor_params[]`.
- Unsupported width sources fail closed: actor-owned bank depths,
  transaction-local port widths, actor constants, runtime interface signals,
  zero-valued or non-scalar actor parameters, transaction parameters,
  arbitrary expressions, use-site override specialization, and generated-top
  respecialization.
- Validation passed: syntax checks; focused scalar-storage, storage, bank,
  public, spec, and book tests with `Files=9, Tests=333`; `mdbook build
  docs/book`; broad `./bin/ci-regression isf --no-book` with `Files=240,
  Tests=1621`; post-closure doc audits with `Files=3, Tests=339`; `git diff
  --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Scalar storage actor-parameter widths selected
- Completed selection work for
  `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.1`.
- Activated the active R14 task tree for actor-owned scalar storage
  `(width PARAM)` declarations backed by actor-local scalar parameter defaults
  resolving to positive integers.
- The active frontier is now
  `ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Interface actor-parameter widths shipped
- Completed `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.2` and closed the task tree.
- Actor top-level interface ports now accept `(width PARAM)` when `PARAM`
  names an actor-local scalar parameter default resolving to a positive
  integer.
- Accepted parameter-backed widths lower like literal widths in public parser
  handoff, scheduled `.fsm` `+size`, schedule reports, and generated HDL,
  while authored parameters remain visible through `+params` and
  `actor_params[]`.
- Unsupported width sources fail closed: unknown symbolic names, actor
  constants, runtime interface signals, zero-valued or non-scalar actor
  parameters, transaction parameters, arbitrary expressions, storage
  dimensions, bank depths, transaction-local port widths, use-site override
  specialization, and generated-top respecialization.
- Validation passed: syntax checks, focused interface/public/spec/book tests
  with `Files=7, Tests=331`, broad `./bin/ci-regression isf --no-book` with
  `Files=239, Tests=1618`, post-closure doc audits with `Files=3,
  Tests=339`, `mdbook build docs/book`, and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Interface actor-parameter widths selected
- Completed selection work for `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.1`.
- Activated the active R14 task tree for actor top-level interface port
  `(width PARAM)` declarations backed by actor-local scalar parameter defaults
  resolving to positive integers.
- The active frontier is now `ISF-INTERFACE-ACTOR-PARAM-WIDTHS.2`.
- No compiler behavior changed.

## 2026-05-23: R14 — Dynamic-divisor actor-parameter-zero safety shipped
- Completed `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2` and closed the task
  tree.
- Runtime division and modulo expressions now fail closed when the divisor
  names an actor-local scalar parameter default that resolves to zero.
- Diagnostics identify the owning expression context, authored divisor token,
  and division/modulo operator family. Nonzero actor parameters, transaction
  parameters, dynamic scalar divisors, nonzero literals, and nonzero actor
  constants keep their shipped behavior.
- Validation passed: focused dynamic-divisor/public/doc tests, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1615`,
  `mdbook build docs/book`, and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-23: R14 — Dynamic-divisor actor-parameter-zero safety selected
- Completed selection work for
  `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.1`.
- Activated the active R14 task tree for rejecting runtime division/modulo
  divisors that name actor-local scalar parameter defaults resolving to zero.
- The active frontier is now `ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.2`.
- No compiler behavior changed.

## 2026-05-22: R14 — Repeat actor-parameter counts shipped
- Completed `ISF-REPEAT-ACTOR-PARAM-COUNTS.2` and closed the task tree.
- Transaction repeat counts now accept actor-local scalar parameter defaults
  that resolve to positive integers and lower to the same counter-width
  evidence model as equivalent positive actor-constant repeat counts, while
  preserving the authored count token in scheduled `.fsm` loads.
- Static zero actor-parameter repeat counts fail closed. Transaction
  parameters, expression-valued or non-scalar actor parameters, unknown names,
  arbitrary expressions, use-site specialization, generated-top repeat-count
  respecialization, repeat-body child activation widening, cross-domain repeat
  behavior, and repeat-body clause widening remain fail-closed or deferred.
- Validation passed: focused repeat/public/doc tests, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1612`,
  `mdbook build docs/book`, and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — Repeat actor-parameter counts selected
- Completed selection work for `ISF-REPEAT-ACTOR-PARAM-COUNTS.1`.
- Activated the active R14 task tree for static actor-parameter-backed
  transaction repeat counts.
- The active frontier is now `ISF-REPEAT-ACTOR-PARAM-COUNTS.2`.
- No compiler behavior changed.

## 2026-05-22: R14 — Watchdog actor-parameter limits shipped
- Completed `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.2` and closed the task tree.
- Actor-level and await-local watchdog limits now accept actor-local scalar
  parameter defaults that resolve to positive integers and lower to the same
  watchdog counter/report shape as equivalent positive literal or
  actor-constant watchdog limits.
- Transaction parameters, runtime signals, expressions, unknown names,
  zero-valued constants, zero-valued or non-scalar actor parameters, use-site
  specialization, distinct per-await limits, cross-domain watchdog policy,
  dynamic watchdog limits, and parameter-specialized generated-top watchdog
  counter sizing remain fail-closed or deferred.
- Validation passed: focused watchdog/public/doc tests, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1611`,
  `mdbook build docs/book`, and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — Watchdog actor-parameter limits selected
- Completed selection work for `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.1`.
- Activated the active R14 task tree for static actor-parameter-backed
  actor-level and await-local watchdog limits.
- The active frontier is now `ISF-WATCHDOG-ACTOR-PARAM-LIMITS.2`.
- No compiler behavior changed.

## 2026-05-22: R14 — Temporal contract actor-parameter windows shipped
- Completed `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.2` and closed the task tree.
- Bounded eventual temporal-contract windows now accept actor-local scalar
  parameter defaults that resolve to positive integers and lower to the same
  monitor shape as equivalent positive literal or actor-constant windows.
- Transaction parameters, runtime signals, expressions, unknown names,
  zero-valued constants, zero-valued or non-scalar actor parameters, use-site
  specialization, dynamic bounds, min/max windows, same-cycle checks, nested
  contracts, expression operands, and multiple outstanding obligations remain
  fail-closed or deferred.
- Validation passed: focused contract/public/doc tests, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1610`,
  `mdbook build docs/book`, and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — Temporal contract actor-parameter windows selected
- Completed selection work for `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.1`.
- Activated the active R14 task tree for static actor-parameter-backed
  bounded eventual temporal-contract windows.
- The active frontier is now `ISF-CONTRACT-ACTOR-PARAM-WINDOWS.2`.
- No compiler behavior changed.

## 2026-05-22: R14 — Latency actor-parameter bounds shipped
- Completed `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2` and closed the task tree.
- Transaction latency bounds now accept actor-local scalar parameter defaults
  that resolve to positive integers and lower to the same generated `.fsm`
  guard/timeout shape as equivalent literal bounds.
- Transaction parameters, runtime signals, expressions, unknown symbols,
  zero-valued constants, zero-valued or non-scalar actor parameters, use-site
  specialization, stage-local latency, and stage runtime semantics remain
  fail-closed or deferred.
- Validation passed: focused latency/public/doc tests, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1609`,
  `mdbook build docs/book`, and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — Latency actor-parameter bounds selected
- Completed `ISF-LATENCY-ACTOR-PARAM-BOUNDS.1`.
- Activated the active R14 task tree for static actor-parameter-backed
  transaction latency bounds.
- The active frontier is now `ISF-LATENCY-ACTOR-PARAM-BOUNDS.2`.
- No compiler behavior changed.

## 2026-05-22: R14 — Next-PNT roadmap wording synced
- Completed `ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.1` and closed the
  maintenance tree.
- The current R14 `Left` section now points to the live active-task pointer
  instead of naming an old closed tree.
- No compiler behavior changed.
- Validation passed: `mdbook build docs/book` and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — ATL frontier truth sync shipped
- Completed `ISF-ATL-FRONTIER-TRUTH-SYNC.2` and closed the maintenance tree.
- The exhausted ATL implementation tree now reports `none` / `closed` in its
  current-frontier table.
- No compiler behavior changed.
- Validation passed: `mdbook build docs/book` and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — ATL frontier truth sync selected
- Completed `ISF-ATL-FRONTIER-TRUTH-SYNC.1`.
- Activated the active R14 roadmap-maintenance task tree for stale
  closed-frontier wording in `ISF-ACTOR-NETWORK-ORCHESTRATION`.
- The active frontier is now `ISF-ATL-FRONTIER-TRUTH-SYNC.2`.
- No compiler behavior changed.

## 2026-05-22: R14 — Dynamic-divisor control/bank coverage shipped
- Completed `ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE.2` and closed the task
  tree.
- Focused dynamic-divisor tests now cover transaction conditions, rule guards,
  bank store index expressions, bank store value expressions, and bank load
  index expressions.
- No compiler behavior changed.
- Validation passed: focused dynamic-divisor test with `Files=1, Tests=16`,
  public/doc audits with `Files=3, Tests=320`, `mdbook build docs/book`, and
  `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — Dynamic-divisor control/bank coverage selected
- Completed `ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE.1`.
- Activated the active R14 task tree for dynamic-divisor control-flow and bank
  expression coverage hardening.
- The active frontier is now
  `ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE.2`.
- No compiler behavior changed.

## 2026-05-22: R14 — Dynamic-divisor drive coverage shipped
- Completed `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.2` and closed the task tree.
- Focused dynamic-divisor tests now cover named drive-call actual expressions
  and inline drive RHS expressions.
- No compiler behavior changed.
- Validation passed: focused dynamic-divisor test, public/doc audits,
  `mdbook build docs/book`, and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — Dynamic-divisor drive coverage selected
- Completed `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.1`.
- Activated the active R14 task tree for dynamic-divisor drive expression
  coverage hardening.
- The active frontier is now `ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.2`.
- No compiler behavior changed.

## 2026-05-22: R14 — Repeat transaction-parameter count diagnostic shipped
- Completed `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.2` and closed the
  task tree.
- Repeat counts that name generated child transaction parameters now fail
  closed with a targeted deferred-transaction-parameter diagnostic.
- Existing accepted repeat count behavior remains preserved.
- Validation passed: focused repeat/public/doc tests, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1601`,
  `mdbook build docs/book`, and `git diff --check`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — Repeat transaction-parameter count diagnostic selected
- Completed `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.1`.
- Activated the active R14 task tree for targeted transaction-parameter
  repeat count diagnostics.
- The active frontier is now
  `ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.2`.
- No compiler behavior changed.

## 2026-05-22: R14 — Backlog owner wording synced
- Completed `ISF-BACKLOG-OWNER-TRUTH-SYNC.2` and closed the task tree.
- The mdBook feature backlog and ATL design proposal now describe the closed
  repeat-body activation and ATL trees as historical records, while future
  behavior needs new task-tree leaves before code.
- Added focused audit coverage for that wording.
- No compiler behavior changed.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.

## 2026-05-22: R14 — Backlog owner truth-sync tree selected
- Completed `ISF-BACKLOG-OWNER-TRUTH-SYNC.1`.
- Activated the active R14 task tree for mdBook backlog owner truth
  synchronization.
- The active frontier is now `ISF-BACKLOG-OWNER-TRUTH-SYNC.2`.
- The selected implementation will clarify that closed repeat-body activation
  and ATL task trees are historical evidence, while future behavior changes
  need new task-tree leaves before code.
- No compiler behavior changed.

## 2026-05-22: R14 — Repeat count source boundary shipped
- Completed `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.2` and closed the task tree.
- At that point, repeat counts were accepted only as positive decimal
  literals, declared actor constants resolving to positive integers, or
  known-width runtime scalar names; current support later added actor-local
  scalar parameter defaults through `ISF-REPEAT-ACTOR-PARAM-COUNTS`.
- Unknown names, non-scalar actor parameters, malformed scalar tokens, and
  expression-valued counts fail closed before scheduled `.fsm` emission.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Validation passed: focused repeat tests, public/doc audits, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1593`,
  `mdbook build docs/book`, and `git diff --check`.

## 2026-05-22: R14 — Repeat count source boundary tree selected
- Completed `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.1`.
- Activated the active R14 task tree for the accepted repeat count source
  boundary.
- The active R14 frontier is now `ISF-REPEAT-COUNT-SOURCE-BOUNDARY.2`.
- The selected implementation will reject unsupported repeat count sources
  while preserving positive literal, positive actor-constant, and known-width
  runtime scalar repeat counts.
- No compiler behavior changed.

## 2026-05-22: R14 — Repeat runtime zero-count policy shipped
- Completed `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.2` and closed the task
  tree.
- Known-width runtime scalar repeat counts now bypass the repeat body and
  repeat check when the runtime value is zero. Nonzero values preserve the
  existing repeat body path.
- Positive literal repeat counts, positive actor constants, existing positive
  runtime repeat behavior, and static zero fail-closed diagnostics remain
  preserved.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Validation passed: focused repeat tests, public/doc audits, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1592`,
  `mdbook build docs/book`, and `git diff --check`.

## 2026-05-22: R14 — Repeat runtime zero-count policy tree selected
- Completed `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.1`.
- Activated the active R14 task tree for runtime scalar repeat zero-count
  skip semantics.
- The active R14 frontier is now
  `ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.2`.
- The selected implementation will bypass the repeat body when a runtime
  scalar repeat count is zero while preserving positive runtime repeat
  behavior and the already shipped static zero fail-closed policy.
- No compiler behavior changed.

## 2026-05-22: R14 — Repeat static zero-count policy shipped
- Completed `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2` and closed the task tree.
- FSMGen now fails closed for repeat counts that are statically known to be
  zero: literal zero counts and actor constants resolving to zero are rejected
  before scheduled `.fsm` emission.
- Positive literal repeat counts, positive actor constants, sampled/runtime
  dynamic repeat counts, repeat-body lowering, parameterized specialization,
  generated-top respecialization, and fully dynamic runtime zero-count skip
  semantics remain unchanged or deferred.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Validation passed: focused repeat tests, public/doc audits, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1591`,
  `mdbook build docs/book`, and `git diff --check`.

## 2026-05-22: R14 — Repeat static zero-count policy tree selected
- Completed selection work for `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.1`.
- Activated the active R14 task tree for a bounded static repeat zero-count
  policy.
- The active R14 frontier is now
  `ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.2`.
- The selected implementation will reject literal zero repeat counts and
  actor constants resolving to zero while preserving positive and dynamic
  repeat behavior.
- No compiler behavior changed.

## 2026-05-22: R14 — Repeat actor-constant widths shipped
- Completed `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2` and closed the task tree.
- FSMGen now accepts declared actor constants as repeat counter width evidence
  when the constant resolves to a non-negative integer.
- The generated repeat counter width uses the resolved constant value while
  the scheduled `.fsm` repeat-init assignment preserves the authored constant
  token.
- Literal repeat counts and sampled/runtime dynamic repeat counts keep their
  existing behavior. Actor/transaction parameter specialization,
  generated-top respecialization, dynamic repeat semantic changes, and
  zero-count policy changes remain deferred.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Validation passed: focused repeat tests, public/doc audits, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1590`,
  `mdbook build docs/book`, and `git diff --check`.

## 2026-05-22: R14 — Repeat actor-constant widths tree selected
- Completed `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.1`.
- Activated the active R14 task tree for actor constants as repeat counter
  width evidence.
- The active R14 frontier is now `ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.2`.
- The selected implementation will preserve repeat runtime behavior and the
  authored repeat load token while using the resolved actor constant for
  counter-width inference.
- No compiler behavior changed.

## 2026-05-22: R14 — Watchdog actor-constant limits shipped
- Completed `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2` and closed the task tree.
- FSMGen now accepts declared positive actor constants as actor-level and
  await-local watchdog limits.
- Actor-level constants resolve into the public numeric `watchdog` scalar and
  schedule reports while remaining visible through `actor_constants[]`;
  await-local constants resolve before watchdog counter injection.
- Distinct per-await watchdog limits in one transaction now fail closed because
  the current scheduled `.fsm` model owns one watchdog counter per transaction.
- Actor/transaction parameters, runtime signals, arbitrary expressions,
  cross-domain watchdog policy, and parameterized watchdog specialization
  remain fail-closed or deferred.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Validation passed: focused watchdog/timing/storage tests, public/doc audits,
  broad `./bin/ci-regression isf --no-book` with `Files=238, Tests=1589`,
  `mdbook build docs/book`, and `git diff --check`.

## 2026-05-22: R14 — Watchdog actor-constant limits tree selected
- Completed `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.1`.
- Activated the active R14 task tree for positive actor constants in
  actor-level and await-local watchdog limits.
- The active R14 frontier is now `ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.2`.
- The selected implementation will preserve omitted watchdog defaults,
  watchdog counter behavior, and public watchdog report shape while resolving
  declared positive actor constants to the same integer limits as literals.
- No compiler behavior changed.

## 2026-05-22: R14 — Latency actor-constant bounds shipped
- Completed `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2` and closed the task tree.
- FSMGen now accepts declared positive actor constants as transaction latency
  `(min ...)` and `(max ...)` bounds.
- Constants resolve before existing latency counter lowering, so generated
  guards, timeout checks, inferred counter widths, and report-visible storage
  roles match the equivalent literal bounds without adding a source-token
  report field.
- Actor/transaction parameters, runtime interface signals, unknown symbols,
  arbitrary expressions, zero-valued constants, stage-local latency, and
  parameterized latency counter specialization remain fail-closed or deferred.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Validation passed: focused latency/schedule/contract tests, public/doc
  audits, broad `./bin/ci-regression isf --no-book` with `Files=238,
  Tests=1585`, `mdbook build docs/book`, and `git diff --check`.

## 2026-05-22: R14 — Latency actor-constant bounds tree selected
- Completed `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.1`.
- Activated the active R14 task tree for positive actor constants in
  transaction latency `(min ...)` and `(max ...)` bounds.
- The active R14 frontier is now `ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.2`.
- The selected implementation will preserve literal latency lowering and
  public report/storage shapes while resolving declared positive actor
  constants to the same integer bounds as literals.
- No compiler behavior changed.

## 2026-05-22: R14 — Temporal contract actor-constant windows shipped
- Completed `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2` and closed the task tree.
- FSMGen now accepts declared positive actor constants as bounded eventual
  temporal-contract windows in both `(within CONST)` and flat `within CONST`
  spellings.
- Generated monitor timing is unchanged from literal windows after resolution;
  schedule reports keep `temporal_contracts[].within_cycles` as the resolved
  integer and do not add a source-token field.
- Actor/transaction parameters, runtime signals, arbitrary expressions,
  min/max windows, nested contracts, same-cycle checks, and multiple
  outstanding obligations remain fail-closed or deferred.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Validation passed: focused contract/boundary tests, public/doc audits, broad
  `./bin/ci-regression isf --no-book` with `Files=238, Tests=1584`,
  `mdbook build docs/book`, and `git diff --check`.

## 2026-05-22: R14 — Temporal contract actor-constant window tree selected
- Completed `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.1`.
- Activated the active R14 task tree for positive actor constants in bounded
  eventual temporal-contract `within` windows.
- The active R14 frontier is now `ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.2`.
- The selected implementation will preserve the current monitor timing and
  public `temporal_contracts[].within_cycles` shape while resolving a declared
  positive actor constant to the same integer bound as a literal.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL backlog truth-sync completed
- Completed `ISF-ATL-BACKLOG-TRUTH-SYNC.2` and closed the task tree.
- The mdBook feature backlog now describes bounded generated ATL tops as
  shipped for documented one-child/two-child resolved-child trigger/event and
  data-route subsets instead of globally excluded.
- Remaining ATL limits stay explicit: route mux/storage, handoff
  remapping/storage, payload protocols, ready/backpressure, CDC/reset
  remapping, fan-in/fan-out, compact movement aliases, group endpoints,
  runtime group scheduling, broader inferred child interface bindings, broader
  global scheduling ownership, and broader fail-closed boundaries.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL backlog truth-sync tree selected
- Completed `ISF-ATL-BACKLOG-TRUTH-SYNC.1`.
- Activated the active R14 documentation truth-sync tree for stale ATL backlog
  prose.
- The active R14 frontier is now `ISF-ATL-BACKLOG-TRUTH-SYNC.2`, which will
  correct the book-facing generated ATL top status while preserving explicit
  deferrals for route mux/storage, handoff storage, compact movement aliases,
  broader inferred child interface bindings, and broader fail-closed
  boundaries.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL compact instance alias shipped
- Completed `ISF-ATL-COMPACT-INSTANCE-ALIAS.2` and closed the task tree.
- FSMGen now accepts direct actor-body `(NAME : ACTOR_TYPE)` as a compact
  readability alias for the shipped verbose static instance form
  `(instance NAME of ACTOR_TYPE)`.
- Schedule JSON reports compact instances through `actor_network.instances[]`
  with `declaration: "instance_alias"`; verbose instances keep
  `declaration: "actor"`.
- Compact library-qualified forms use the same explicit import and actor-export
  resolution path as verbose `(instance NAME of ALIAS.EXPORT)` declarations.
- This is syntax ergonomics only. Instance scheduling behavior, actor type
  resolution policy, generated child emission policy, generated ATL top
  behavior, compact movement syntax, and route behavior are unchanged.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Validation passed: focused actor-network test, public/doc audit group, ATL
  fixture group, and broad `./bin/ci-regression isf --no-book` with
  `Files=238, Tests=1582`, plus `mdbook build docs/book` and
  `git diff --check`.

## 2026-05-22: R14 — ATL compact instance alias tree selected
- Completed `ISF-ATL-COMPACT-INSTANCE-ALIAS.1`.
- Activated the next R14 task tree for direct actor-body
  `(NAME : ACTOR_TYPE)` compact static instance declarations.
- The active R14 frontier is now `ISF-ATL-COMPACT-INSTANCE-ALIAS.2`.
- The selected implementation will keep instance behavior metadata-only where
  the verbose form is metadata-only and will not change actor type resolution,
  generated child emission, generated ATL tops, compact movement syntax, or
  route behavior.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL compact group alias shipped
- Completed `ISF-ATL-COMPACT-GROUP-ALIAS.2` and closed the task tree.
- FSMGen now accepts direct actor-body `(concurrent NAME ACTOR...)` as a
  compact readability alias for the shipped verbose static group metadata
  form `(group NAME (members ACTOR...) (mode concurrent))`.
- Schedule JSON reports the compact alias through `actor_network.groups[]`
  with `declaration: "concurrent_alias"`, `mode: "concurrent"`,
  `source: "actor_body"`, and `scheduling: "metadata_only"`; verbose groups
  keep `declaration: "group"`.
- This is syntax ergonomics only. Runtime group scheduling, group endpoints,
  group handoff routing, generated HDL group behavior, compact movement
  syntax, and permanent runtime group coupling remain deferred.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Validation passed: focused actor-network test, public/doc audit group, ATL
  fixture group, and broad `./bin/ci-regression isf --no-book` with
  `Files=238, Tests=1582`, plus `mdbook build docs/book` and
  `git diff --check`.

## 2026-05-22: R14 — ATL compact group alias tree selected
- Completed `ISF-ATL-COMPACT-GROUP-ALIAS.1`.
- Activated the next R14 task tree for the reserved compact
  `(concurrent NAME ACTOR...)` alias over the shipped verbose static group
  metadata surface.
- The selected next frontier was `ISF-ATL-COMPACT-GROUP-ALIAS.2`.
- The selected implementation was required to keep groups report-only and not
  add runtime group scheduling, group endpoints, compact movement syntax, or
  generated HDL behavior.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL multi-event wait sequencing shipped
- Completed `ISF-ATL-MULTI-EVENT-WAIT.2` and closed the task tree.
- FSMGen now lowers one temporary trigger batch followed by multiple
  contiguous top-level actor event waits into explicit sequential wait states.
  The shipped fixture waits on `reader_done`, `filter_done`, and
  `writer_done` after one reader/filter/writer trigger batch.
- Added `isf/atl_trigger_batch_multi_wait_pipeline.isf` and expanded
  `t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t` for scheduled `.fsm`
  structure, strict schedule JSON parity, and plain plus strict HDL
  generation.
- Schedule reports preserve every wait as a source-ordered
  `actor_network.event_waits[]` entry and keep the task-scoped
  `association_schedules[]`/compatibility `group_schedules[]` trigger-batch
  evidence.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, fixture matrix, roadmap, task-tree docs, and live
  docs.

## 2026-05-22: R14 — ATL multi-event wait tree selected
- Completed `ISF-ATL-MULTI-EVENT-WAIT.1`.
- Activated the next R14 task tree for bounded transaction-body ATL
  multi-event waits after one same-cycle temporary trigger batch.
- The active R14 frontier is now `ISF-ATL-MULTI-EVENT-WAIT.2`.
- The selected implementation will preserve explicit source-ordered wait
  states and report every wait through `actor_network.event_waits[]`.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL pin-egress mixed route set shipped
- Completed `ISF-ATL-PIN-MIXED-ROUTE-SETS.3` and closed the task tree.
- FSMGen now lowers same-child generated-child resolved-child output to
  top-level output route sets that combine exact-width vector routes and
  scalar one-bit routes in one contiguous post-event drive-call segment.
- Added `isf/atl_resolved_child_pin_egress_mixed_pipeline.isf` with focused
  `.fsm`, schedule JSON, strict outdir, HDL, and route-local vector
  width-mismatch coverage.
- Schedule reports preserve each route in `actor_network.data_movements[]`
  with route-local `kind`, `width`, and `width_source` values:
  `vector_actor_to_pin_handoff` for the 8-bit result route and
  `scalar_actor_to_pin_handoff` for the one-bit valid route.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, task-tree docs, and live docs.

## 2026-05-22: R14 — ATL pin-ingress mixed route set shipped
- Completed `ISF-ATL-PIN-MIXED-ROUTE-SETS.2`.
- FSMGen now lowers same-child generated-child top-level input-pin to
  resolved-child input route sets that combine exact-width vector routes and
  scalar one-bit routes in one contiguous pre-trigger drive-call segment.
- Added `isf/atl_resolved_child_pin_ingress_mixed_pipeline.isf` with focused
  `.fsm`, schedule JSON, strict outdir, HDL, and route-local vector
  width-mismatch coverage.
- Schedule reports preserve each route in `actor_network.data_movements[]`
  with route-local `kind`, `width`, and `width_source` values:
  `vector_pin_to_actor_handoff` for the 8-bit payload route and
  `scalar_pin_to_actor_handoff` for the one-bit valid route.
- The active R14 frontier is now `ISF-ATL-PIN-MIXED-ROUTE-SETS.3` for the
  inverse mixed scalar/vector pin-egress route set.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, task-tree docs, and live docs.

## 2026-05-22: R14 — ATL pin mixed route sets selected
- Completed `ISF-ATL-PIN-MIXED-ROUTE-SETS.1`.
- The active R14 frontier is now `ISF-ATL-PIN-MIXED-ROUTE-SETS.2`.
- The selected implementation will allow same-child generated-child
  top-level input-pin to resolved-child input route sets to combine scalar
  one-bit routes and exact-width vector routes while preserving route-local
  public metadata.
- The inverse same-child resolved-child output to top-level output mixed route
  set remains tracked as `ISF-ATL-PIN-MIXED-ROUTE-SETS.3`.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL pin-egress vector multi-route shipped
- Completed `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.3` and closed the task tree.
- FSMGen now lowers same-child exact-width vector resolved-child output routes
  into top-level output pins through the generated ATL top when every route
  has unique child outputs/top-level pins, adjacent post-event drive calls,
  and matching route-local widths.
- Added `isf/atl_resolved_child_pin_egress_vector_multi_pipeline.isf` with
  focused `.fsm`, schedule JSON, strict outdir, HDL, and width-mismatch
  coverage.
- Schedule reports identify each route as `vector_actor_to_pin_handoff` with
  `width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, and task-tree docs.

## 2026-05-22: R14 — ATL pin-ingress vector multi-route shipped
- Completed `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.2`.
- FSMGen now lowers same-child exact-width vector top-level input-pin routes
  into resolved child inputs through the generated ATL top when every route
  has unique pins/endpoints, adjacent pre-trigger drive calls, and matching
  route-local widths.
- Added `isf/atl_resolved_child_pin_ingress_vector_multi_pipeline.isf` with
  focused `.fsm`, schedule JSON, strict outdir, HDL, and width-mismatch
  coverage.
- Schedule reports identify each route as `vector_pin_to_actor_handoff` with
  `width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
- The active R14 frontier is now `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.3` for the
  inverse exact-width vector pin-egress multi-route set.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, and task-tree docs.

## 2026-05-22: R14 — ATL pin vector multi-route selected
- Completed `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.1`.
- The active R14 frontier is now `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.2`.
- The selected implementation will widen generated-child same-child
  top-level input-pin to resolved-child input route sets to exact-width vector
  routes only when each route's top-level pin and child endpoint have the same
  positive width.
- The inverse same-child resolved-child output to top-level output vector
  route set remains tracked as `ISF-ATL-PIN-VECTOR-MULTI-ROUTE.3`.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL pin-egress vector width shipped
- Completed `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3` and closed the task tree.
- FSMGen now lowers one exact-width vector resolved-child output route into
  one top-level output pin through the generated ATL top.
- Added `isf/atl_resolved_child_pin_egress_vector_pipeline.isf` with focused
  `.fsm`, schedule JSON, strict outdir, HDL, and width-mismatch coverage.
- Schedule reports now identify this route as `vector_actor_to_pin_handoff`
  with
  `width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`.
- `docs/TASK_TREE.md` and `ROADMAP_STATUS.md` now agree that no task tree is
  active before the next PNT selection.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, and task-tree docs.

## 2026-05-22: R14 — ATL pin-ingress vector width shipped
- Completed `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.2`.
- FSMGen now lowers one exact-width vector top-level input-pin route into one
  resolved child input through the generated ATL top.
- Added `isf/atl_resolved_child_pin_ingress_vector_pipeline.isf` with focused
  `.fsm`, schedule JSON, strict outdir, HDL, and width-mismatch coverage.
- Schedule reports now identify this route as `vector_pin_to_actor_handoff`
  with
  `width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`.
- The active R14 frontier is now `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3` for the
  inverse exact-width vector pin-egress route.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, and task-tree docs.

## 2026-05-22: R14 — ATL pin-route vector width selected
- Completed `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.1`.
- The active R14 frontier is now `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.2`.
- The selected implementation will widen generated-child top-level input-pin
  to resolved-child input routes only when both endpoint declarations have the
  same positive width.
- The inverse resolved-child output to top-level output vector route remains
  tracked as `ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.3`.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL actor-route vector width shipped
- Completed `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.2` and closed the task tree.
- FSMGen now lowers same-width generated-child actor-to-actor vector routes
  through parent handoff ports, generated top links, child `+interface` roles,
  HDL vector links, and schedule-report `vector_actor_handoff` metadata.
- Added `isf/atl_two_child_vector_data_pipeline.isf` with focused `.fsm`,
  schedule JSON, strict outdir, HDL, and width-mismatch coverage.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, and task-tree docs.

## 2026-05-22: R14 — ATL actor-route vector width selected
- Completed `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.1`.
- The active R14 frontier is now `ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.2`.
- The selected implementation will widen generated-child actor-to-actor ATL
  routes only when the resolved source child output and sink child input have
  the same explicit positive width.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL route drive argument boundary shipped
- Completed `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2` and closed the task tree.
- FSMGen now rejects parameterized selected ATL route drives through a
  route-kind-neutral `ATL scalar data movement` diagnostic.
- Added focused pin-ingress and pin-egress coverage for route drive formal
  parameters and route drive-call actual arguments.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, and task-tree docs.

## 2026-05-22: R14 — ATL route drive argument boundary selected
- Completed `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.1`.
- The active R14 frontier is now
  `ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.2`.
- The selected implementation will harden route drive formal/actual-argument
  rejection across shipped actor-to-actor, pin-ingress, and pin-egress ATL
  data-movement route kinds.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL pin-egress multi-route shipped
- Completed `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.2` and closed the task tree.
- FSMGen now accepts bounded multiple scalar resolved-child output routes into
  top-level output pins through adjacent post-event drive calls.
- Added `isf/atl_resolved_child_pin_egress_multi_pipeline.isf` with focused
  schedule report, generated-top, strict outdir, HDL, and fail-closed malformed
  route-set coverage.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, and task-tree docs.

## 2026-05-22: R14 — ATL pin-egress multi-route selected
- Completed `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.1`.
- The active R14 frontier is now `ISF-ATL-PIN-EGRESS-MULTI-ROUTE.2`.
- The selected implementation will widen generated-child resolved-child output
  to top-level output routing from one scalar route to several same-child,
  one-bit, contiguous post-event drive-call routes.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL pin-ingress multi-route shipped
- Completed `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.2` and closed the task tree.
- FSMGen now accepts bounded multiple scalar top-level input-pin routes into
  one resolved child through adjacent pre-trigger drive calls.
- Added `isf/atl_resolved_child_pin_ingress_multi_pipeline.isf` with focused
  schedule report, generated-top, strict outdir, HDL, and fail-closed malformed
  route-set coverage.
- Synchronized the ISF spec, downstream integration spec, public contract, ATL
  design proposal, mdBook, roadmap, and task-tree docs.

## 2026-05-22: R14 — ATL pin-ingress multi-route selected
- Completed `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.1`.
- The active R14 frontier is now `ISF-ATL-PIN-INGRESS-MULTI-ROUTE.2`.
- The selected implementation will widen generated-child top-level input-pin
  to resolved-child input routing from one scalar route to several
  same-child, one-bit, contiguous drive-call routes.
- No compiler behavior changed.

## 2026-05-22: Roadmap maintenance — R14 frontier truth synchronized
- Completed `ROADMAP-R14-FRONTIER-TRUTH-SYNC.1`.
- The maintenance tree is closed.
- `ROADMAP_STATUS.md` no longer names the completed
  `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2` leaf as the current R14 frontier.
- `ROADMAP_STATUS.md` and `docs/TASK_TREE.md` now agree that no task tree is
  active before the next PNT selection.
- No compiler behavior changed.

## 2026-05-22: R14 — ATL multi-route data movement shipped
- Completed `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2` and closed the task tree.
- FSMGen now accepts bounded multiple scalar generated-child actor-to-actor
  routes in one same-source/same-sink parent route segment.
- Added `isf/atl_two_child_multi_data_pipeline.isf` with focused schedule
  report, generated-top, strict outdir, and HDL coverage.
- Synchronized the ISF spec, downstream integration spec, public contract,
  mdBook, roadmap, and task-tree docs.

## 2026-05-22: R14 — ATL multi-route data movement selected
- Completed `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.1`.
- The active R14 frontier is now
  `ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.2`.
- The selected implementation will widen generated-child ATL actor-to-actor
  data movement from one scalar route to several same-source/same-sink scalar
  routes in one contiguous route segment, without claiming mux/storage,
  fan-in/fan-out, ready/backpressure, payload protocols, CDC, or repeated
  activation semantics.
- No compiler behavior changed.

## 2026-05-22: Roadmap maintenance — active-lane truth synchronized
- Completed `ROADMAP-ACTIVE-LANE-TRUTH-SYNC.2`.
- The maintenance tree is closed.
- `ROADMAP_STATUS.md` no longer claims the old R12 custom-clock task tree is
  active.
- `ROADMAP_STATUS.md` and `docs/TASK_TREE.md` now agree that no task tree is
  active before the next PNT selection.
- No compiler behavior changed.

## 2026-05-22: Roadmap maintenance — active-lane truth sync selected
- Completed `ROADMAP-ACTIVE-LANE-TRUTH-SYNC.1`.
- The active maintenance frontier is now `ROADMAP-ACTIVE-LANE-TRUTH-SYNC.2`.
- The selected implementation will remove stale active-lane/frontier claims
  from `ROADMAP_STATUS.md` before the next behavior-bearing PNT selection.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — parser-token coverage widened
- Completed `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts malformed verbose `?ports` declarations,
  invalid `?ports` tokens, non-positive `?ports` widths, malformed `?wiring`
  list-form endpoints, unsupported `?wiring` tokens, malformed
  composition-top `+constants` identifiers, and non-literal composition-top
  `+enums` values.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — parser-token widening selected
- Completed `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.2`.
- The selected implementation will promote composition parser token/top-symbol
  diagnostics into maintained expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — endpoint-shape coverage widened
- Completed `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts shared system-port declared same-name rejection
  and child aggregate-member endpoint rejection without declared aggregate
  types.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — endpoint-shape widening selected
- Completed `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.2`.
- The selected implementation will promote composition endpoint-shape
  diagnostics into maintained expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — C1 port-exposure coverage widened
- Completed `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts missing child exposure, unknown explicit top
  ports, width mismatch, and direction mismatch in the C1 passthrough lane.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — C1 port-exposure widening selected
- Completed `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.2`.
- The selected implementation will promote C1 passthrough exposure diagnostics
  into maintained expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — explicit-link topology coverage widened
- Completed `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts missing explicit `?wiring` in a multi-child
  explicit-link composition topology as a maintained expected-failure corpus
  entry.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — explicit-link topology widening selected
- Completed `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.2`.
- The selected implementation will promote missing explicit `?wiring`
  diagnostics into maintained expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — target-support coverage widened
- Completed `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts VHDL composition target rejection as a maintained
  expected-failure corpus entry.
- Stable diagnostic-code metadata, per-entry target-language corpus gates,
  check JSON, normalized semantic JSON, manifest, regression-corpus docs, and
  mdBook backend-boundary coverage are synchronized.
- No backend implementation behavior changed.

## 2026-05-22: R12 regression corpus — target-support widening selected
- Completed `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.2`.
- The selected implementation will promote unsupported VHDL composition target
  diagnostics into maintained expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — ports-shape coverage widened
- Completed `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts multiple `?ports` blocks, omitted `?ports`
  outside inferable lanes, and empty `?ports` outside inferable lanes.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — ports-shape widening selected
- Completed `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.2`.
- The selected implementation will promote multiple-`?ports`,
  omitted-`?ports`, and empty-`?ports` diagnostics into maintained
  expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — duplicate declaration coverage widened
- Completed `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts duplicate top-port declaration failures and
  duplicate child instance-name failures.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — duplicate declaration widening selected
- Completed `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.2`.
- The selected implementation will promote duplicate top-port and duplicate
  child-instance diagnostics into maintained expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — child-kind/ports-mapping coverage widened
- Completed
  `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts unsupported composition child-kind failures and
  legacy `?ports` mapping directive failures.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — child-kind/ports-mapping widening selected
- Completed
  `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.2`.
- The selected implementation will promote unsupported composition child-kind
  and legacy `?ports` mapping directive diagnostics into maintained
  expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — composition child-structure coverage widened
- Completed `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts malformed composition child-entry structure
  failures for empty child entries, non-string child headers, and dotted-pair
  payloads across `?fsmc`, `?wiring`, `?ports`, `?dtc`, and `?rtl`.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — composition child-structure widening selected
- Completed `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed composition child-entry
  structure diagnostics into maintained expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — RTL child source-shape coverage widened
- Completed `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts malformed external RTL child source count and
  nested payload shape failures for `?rtl`.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — RTL child source-shape widening selected
- Completed `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed external RTL child
  source-count and nested payload-shape diagnostics into maintained
  expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — generated-child source-shape coverage widened
- Completed
  `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts malformed generated-child source count and nested
  payload shape failures for both `?fsmc` and `?dtc`.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — generated-child source-shape widening selected
- Completed
  `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed generated-child
  source-count and nested payload-shape diagnostics into maintained
  expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-22: R12 regression corpus — wrong-kind child-source coverage widened
- Completed
  `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2`.
- The task tree is closed.
- FSMGen now support-accounts two wrong-kind external generated-child source
  failures:
  - `?fsmc` resolving to a standalone-DT `?dt` root.
  - `?dtc` resolving to an FSM `?fsm` root.
- Stable diagnostic-code metadata, check JSON, normalized semantic JSON,
  manifest, regression-corpus docs, and mdBook coverage are synchronized.
- No parser, source-resolution, or HDL-generation behavior changed.

## 2026-05-22: R12 regression corpus — wrong-kind child-source widening selected
- Completed
  `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.2`.
- The selected implementation will promote wrong-kind generated-child source
  realization diagnostics into maintained expected-failure corpus coverage.
- No compiler behavior changed.

## 2026-05-21: ISF spec focused-test index CI drift repaired
- Completed `ISF-SPEC-TEST-INDEX-SYNC.2`.
- The ISF spec focused-test index now includes
  `t/1332-isf-atl-doc-status-audit.t`, matching the current `t/*-isf-*.t`
  inventory.
- This fixes the GitHub `Perl FSM Regression` failure caused by
  `t/1250-isf-spec-focused-test-index-audit.t` without changing compiler
  behavior.

## 2026-05-21: R12 regression corpus — standalone DTC explicit-system autowire widening shipped
- Completed
  `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2` and closed
  the tree.
- The maintained corpus now has one additional supported-smoke entry for
  `?dtc` explicit-system auto-wiring.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-21: R12 regression corpus — standalone DTC explicit-system autowire widening selected
- Completed
  `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2`.
- The selected implementation will promote `?dtc` explicit-system auto-wiring
  into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-21: R12 regression corpus — standalone DT explicit-system widening shipped
- Completed `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.2` and closed
  the tree.
- The maintained corpus now has one additional supported-smoke entry for
  direct standalone `?dt` roots with canonical explicit `+system` metadata.
- Strict-supported metadata, direct `dt` source-kind assertion support,
  HDL-shape checks, supported corpus behavior, check JSON, normalized semantic
  JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-21: R12 regression corpus — standalone DT explicit-system widening selected
- Completed `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.2`.
- The selected implementation will promote direct standalone `?dt`
  explicit-system behavior into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-21: R12 regression corpus — implicit composition autowire widening shipped
- Completed
  `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2` and closed the
  tree.
- The maintained corpus now has one additional supported-smoke entry for
  composition auto-wiring of implicit child system ports.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-21: R12 regression corpus — implicit composition autowire widening selected
- Completed
  `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.2`.
- The selected implementation will promote composition auto-wiring of implicit
  child system ports into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-21: R12 regression corpus — implicit system defaults widening shipped
- Completed `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.2` and closed the
  tree.
- The maintained corpus now has one additional supported-smoke entry for
  direct `?fsm` sources that omit `+system`.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-21: R12 regression corpus — implicit system defaults widening selected
- Completed `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.2`.
- The selected implementation will promote direct omitted-`+system` defaults
  into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-21: R12 regression corpus — custom system clock widening shipped
- Completed `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has one additional supported-smoke entry for
  custom `+system` clock names using canonical reset spelling.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-21: R12 regression corpus — custom system clock widening selected
- Completed `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.2`.
- The selected implementation will promote supported custom `+system` clock
  names into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-21: R12 regression corpus — compound update variant widening shipped
- Completed `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2` and closed the
  tree.
- The maintained corpus now has one additional supported-smoke entry for
  compound update variants.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-21: R12 regression corpus — compound update variant widening selected
- Completed `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.2`.
- The selected implementation will promote supported compound update variants
  into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-21: R12 regression corpus — nested and compound guard widening shipped
- Completed `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2` and closed the
  tree.
- The maintained corpus now has one additional supported-smoke entry for
  nested guarded blocks and compound suffix guards.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-21: R12 regression corpus — nested and compound guard widening selected
- Completed `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.2`.
- The selected implementation will promote supported nested guarded blocks and
  compound suffix guards into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-21: R12 regression corpus — arithmetic and XOR operator widening shipped
- Completed `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.2` and closed the
  tree.
- The maintained corpus now has one additional supported-smoke entry for
  n-ary arithmetic and XOR operator variants.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-21: R12 regression corpus — arithmetic and XOR operator widening selected
- Completed `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.2`.
- The selected implementation will promote supported n-ary arithmetic and XOR
  operator variants into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-21: R12 regression corpus — reset-state alias widening shipped
- Completed `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has one additional supported-smoke entry for
  legacy reset-state aliases that normalize to DT-style
  `syncreset`/`asyncreset` enable regions.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-21: R12 regression corpus — reset-state alias widening selected
- Completed `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-RESET-STATE-ALIAS-CORPUS-WIDENING.2`.
- The selected implementation will promote supported legacy reset-state
  aliases into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — RHS expression supported variants widening shipped
- Completed `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.2` and
  closed the tree.
- The maintained corpus now has one additional supported-smoke entry for
  inline scalar comparisons and negated n-ary bitwise RHS operators.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — RHS expression supported variants widening selected
- Completed `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.2`.
- The selected implementation will promote inline scalar comparisons and
  negated n-ary bitwise RHS operators into maintained supported-smoke corpus
  coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — computed comparison selector widening shipped
- Completed `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.2` and closed
  the tree.
- The maintained corpus now has one additional supported-smoke entry for
  computed comparison selectors such as `?(== A B)`.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — computed comparison selector widening selected
- Completed `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.2`.
- The selected implementation will promote supported computed comparison
  selectors into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — symbolic/default selector widening shipped
- Completed `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.2` and closed
  the tree.
- The maintained corpus now has one additional supported-smoke entry for
  symbolic equality selectors and `default` / `_` fallback selector lowering.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — symbolic/default selector widening selected
- Completed `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.2`.
- The selected implementation will promote supported symbolic equality
  selectors and `default` / `_` fallback selectors into maintained
  supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — plain test-signal widening shipped
- Completed `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has one additional supported-smoke entry for plain
  `?SIG` equality selectors and branch-local assignment enables.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — plain test-signal widening selected
- Completed `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.2`.
- The selected implementation will promote supported plain `?SIG` equality
  selectors into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — standalone DT guard widening shipped
- Completed `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has one additional supported-smoke entry for
  standalone DT classification, always-on DT enables, guard-expression
  lowering, and guarded output-enable boundaries.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — standalone DT guard widening selected
- Completed `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.2`.
- The selected implementation will promote supported standalone DT
  classification and DTE guards into maintained supported-smoke corpus
  coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — test-branch selector widening shipped
- Completed `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has one additional supported-smoke entry for
  relational `?SIG` branch selectors covering nonzero reduction, greater-than,
  and less-or-equal lowering.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — test-branch selector widening selected
- Completed `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.2`.
- The selected implementation will promote supported relational test-branch
  selectors into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — computed test-selector widening shipped
- Completed `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.2` and closed the
  tree.
- The maintained corpus now has one additional supported-smoke entry for
  computed selector intermediate generation, explicit selector branches, and
  default branch reuse.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — computed test-selector widening selected
- Completed `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.2`.
- The selected implementation will promote supported computed test selectors
  into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — relational-operator widening shipped
- Completed `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has one additional supported-smoke entry for
  n-ary relational chains, word aliases, unary `not`, and guarded
  relational-chain lowering.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — relational-operator widening selected
- Completed `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.2`.
- The selected implementation will promote supported relational operator
  chains and word aliases into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — guard-shorthand widening shipped
- Completed `R12-GUARD-SHORTHAND-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has one additional supported-smoke entry for
  scalar truthiness, negated truthiness, inline comparison, and suffix-guard
  shorthand.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — guard-shorthand widening selected
- Completed `R12-GUARD-SHORTHAND-CORPUS-WIDENING.1`.
- The active R12 frontier is now `R12-GUARD-SHORTHAND-CORPUS-WIDENING.2`.
- The selected implementation will promote supported guard shorthand into
  maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — state-DTE guard widening shipped
- Completed `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has one additional supported-smoke entry for
  regular-state header DTE guards with scalar and expression activation
  conditions.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — state-DTE guard widening selected
- Completed `R12-STATE-DTE-GUARD-CORPUS-WIDENING.1`.
- The active R12 frontier is now `R12-STATE-DTE-GUARD-CORPUS-WIDENING.2`.
- The selected implementation will promote supported regular-state header DTE
  guards into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — update-shorthand variant widening shipped
- Completed `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.2` and closed the
  tree.
- The maintained corpus now has one additional supported-smoke entry for
  update-shorthand `+=` / `-=` variants with implicit and explicit deltas.
- Strict-supported metadata, HDL-shape checks, supported corpus behavior,
  check JSON, normalized semantic JSON, manifest coverage, regression-corpus
  docs, and the mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — update-shorthand variant widening selected
- Completed `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.2`.
- The selected implementation will promote supported `+=` / `-=`
  update-shorthand variants into maintained supported-smoke corpus coverage.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — duplicate default selector widening shipped
- Completed `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has one additional duplicate default
  test-selector expected-failure entry for selector nodes that contain both
  `default` and `_` branches.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — duplicate default selector widening selected
- Completed `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.2`.
- The selected implementation will promote duplicate `default` / `_`
  test-selector branch failures into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — top-level form widening shipped
- Completed `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has two additional unsupported top-level form
  expected-failure entries for future-looking infix init and malformed bare
  scalar body forms.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — top-level form widening selected
- Completed `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-TOP-LEVEL-FORM-CORPUS-WIDENING.2`.
- The selected implementation will promote unsupported top-level infix init
  forms and malformed bare scalar body forms into maintained expected-failure
  corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — delayed-pulse target widening shipped
- Completed `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has three additional delayed-pulse LHS target
  expected-failure entries for indexed, range-sliced, and pair-form indexed
  targets.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — delayed-pulse target widening selected
- Completed `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.2`.
- The selected implementation will promote indexed, range-sliced, and
  pair-form indexed delayed-pulse LHS target failures into maintained
  expected-failure corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — plus-FSM body widening shipped
- Completed `R12-PLUS-FSM-BODY-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has two additional plus-FSM body expected-failure
  entries for empty legacy `+fsm` root bodies and scalar nested `+fsm` body
  items.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — plus-FSM body widening selected
- Completed `R12-PLUS-FSM-BODY-CORPUS-WIDENING.1`.
- The active R12 frontier is now `R12-PLUS-FSM-BODY-CORPUS-WIDENING.2`.
- The selected implementation will promote empty legacy `+fsm` root bodies and
  scalar nested `+fsm` body items into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — symbol-token widening shipped
- Completed `R12-SYMBOL-TOKEN-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has four additional symbol-token expected-failure
  entries for malformed `+constants`, `+define`, and `+params` identifiers
  plus non-scalar `+enums` member values.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — symbol-token widening selected
- Completed `R12-SYMBOL-TOKEN-CORPUS-WIDENING.1`.
- The active R12 frontier is now `R12-SYMBOL-TOKEN-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed `+constants`, `+define`,
  and `+params` identifiers plus non-scalar `+enums` member values into
  maintained expected-failure corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — aggregate parameter-expression widening shipped
- Completed `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2` and closed the
  tree.
- The maintained corpus now has six additional aggregate parameter-expression
  expected-failure entries for mixed operands, shape mismatches, arithmetic
  overflow, underflow, and divide-by-zero.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — aggregate parameter-expression widening selected
- Completed `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.2`.
- The selected implementation will promote aggregate `+params` expression
  mixed operands, shape mismatches, arithmetic overflow, underflow, and
  divide-by-zero into maintained expected-failure corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — parameter dependency widening shipped
- Completed `R12-PARAM-DEPENDENCY-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has two additional parameter dependency
  expected-failure entries for cyclic `+params` dependency graphs and duplicate
  `+params` declarations.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — parameter dependency widening selected
- Completed `R12-PARAM-DEPENDENCY-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-PARAM-DEPENDENCY-CORPUS-WIDENING.2`.
- The selected implementation will promote cyclic `+params` dependency graphs
  and duplicate `+params` declarations into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — symbol-value widening shipped
- Completed `R12-SYMBOL-VALUE-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has three additional symbol-value
  expected-failure entries for unresolved `+params` value names and ambiguous
  bare bitstring-like `+constants` / `+params` values.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — symbol-value widening selected
- Completed `R12-SYMBOL-VALUE-CORPUS-WIDENING.1`.
- The active R12 frontier is now `R12-SYMBOL-VALUE-CORPUS-WIDENING.2`.
- The selected implementation will promote unresolved `+params` value names
  and ambiguous bare bitstring-like `+constants` / `+params` values into
  maintained expected-failure corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — malformed symbol-entry widening shipped
- Completed `R12-SYMBOL-ENTRY-MALFORMED-CORPUS-WIDENING.2` and closed the
  tree.
- The maintained corpus now has four additional malformed symbol-entry
  expected-failure entries for `+constants`, `+define`, `+params`, and
  `+enums` member entries.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — malformed symbol-entry widening selected
- Completed `R12-SYMBOL-ENTRY-MALFORMED-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-SYMBOL-ENTRY-MALFORMED-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed `+constants`, `+define`,
  `+params`, and `+enums` member entries into maintained expected-failure
  corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — empty symbol-section widening shipped
- Completed `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has four additional empty symbol-section
  expected-failure entries for `+constants`, `+define`, `+params`, and
  `+enums`.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — empty symbol-section widening selected
- Completed `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.2`.
- The selected implementation will promote empty `+constants`, `+define`,
  `+params`, and `+enums` sections into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — init-directive shape widening shipped
- Completed `R12-INIT-DIRECTIVE-SHAPE-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has three additional init-directive shape
  expected-failure entries for malformed `:=` payloads and malformed compact
  `:=` directives.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — init-directive shape widening selected
- Completed `R12-INIT-DIRECTIVE-SHAPE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-INIT-DIRECTIVE-SHAPE-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed `:=` payload shapes and
  malformed compact `:=` directives into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — condition-expression widening shipped
- Completed `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has four additional condition-expression
  expected-failure entries for malformed guard shorthand payloads and malformed
  inline comparison tokens.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — condition-expression widening selected
- Completed `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-CONDITION-EXPRESSION-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed guard shorthand payloads
  and malformed inline comparison tokens into maintained expected-failure
  corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — RHS expression widening shipped
- Completed `R12-RHS-EXPRESSION-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has three additional RHS expression
  expected-failure entries for unsupported operators, malformed operator arity,
  and guard-only tokens in ordinary value position.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — RHS expression widening selected
- Completed `R12-RHS-EXPRESSION-CORPUS-WIDENING.1`.
- The active R12 frontier is now `R12-RHS-EXPRESSION-CORPUS-WIDENING.2`.
- The selected implementation will promote unsupported RHS expression
  operators, malformed RHS operator arity, and guard-only RHS tokens into
  maintained expected-failure corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — FSM-root body widening shipped
- Completed `R12-FSM-ROOT-BODY-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has two additional structured `?fsm` root-body
  expected-failure entries for empty roots and scalar top-level body items.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — FSM-root body widening selected
- Completed `R12-FSM-ROOT-BODY-CORPUS-WIDENING.1`.
- The active R12 frontier is now `R12-FSM-ROOT-BODY-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed empty structured `?fsm`
  roots and scalar top-level body items into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — state-body widening shipped
- Completed `R12-STATE-BODY-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has two additional state-body expected-failure
  entries for malformed empty regular state bodies and malformed empty
  standalone-DT bodies.
- Stable diagnostic code metadata, corpus behavior checks, check JSON,
  normalized semantic JSON, manifest coverage, regression-corpus docs, and the
  mdBook are synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — state-body widening selected
- Completed `R12-STATE-BODY-CORPUS-WIDENING.1`.
- The active R12 frontier is now `R12-STATE-BODY-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed empty regular state
  bodies and empty standalone-DT bodies into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — update-shorthand widening shipped
- Completed `R12-UPDATE-SHORTHAND-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has four additional update-shorthand
  expected-failure entries for malformed nested targets and malformed
  positional tails.
- Stable diagnostic codes, corpus behavior checks, check JSON, normalized
  semantic JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — update-shorthand widening selected
- Completed `R12-UPDATE-SHORTHAND-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-UPDATE-SHORTHAND-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed update-shorthand targets
  and malformed update-shorthand tails into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — inline-modifier widening shipped
- Completed `R12-INLINE-MODIFIER-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has two additional inline-modifier
  expected-failure entries for malformed inline modifier payloads and duplicate
  inline modifier clauses.
- Stable diagnostic codes, corpus behavior checks, check JSON, normalized
  semantic JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — inline-modifier widening selected
- Completed `R12-INLINE-MODIFIER-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-INLINE-MODIFIER-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed and duplicate inline
  compound modifiers into maintained expected-failure corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — test-selector widening shipped
- Completed `R12-TEST-SELECTOR-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has three additional test-selector
  expected-failure entries for malformed `?bad-name` and `?0` plain
  test-signal names plus the unambiguous malformed computed selector that
  omits its selector expression.
- Stable diagnostic codes, corpus behavior checks, check JSON, normalized
  semantic JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — test-selector widening selected
- Completed `R12-TEST-SELECTOR-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-TEST-SELECTOR-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed plain test-signal names
  and malformed computed test selectors into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — operator/directive widening shipped
- Completed `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has four additional operator/directive
  expected-failure entries for unsupported `?=` and `=>` assignment operators
  plus unsupported compact `:=` reset values `[DATAIN]` and `<start`.
- Stable diagnostic codes, corpus behavior checks, check JSON, normalized
  semantic JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — operator/directive widening selected
- Completed `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.2`.
- The selected implementation will promote unsupported assignment operators
  and unsupported `:=` reset values into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — assignment-boundary widening shipped
- Completed `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has six additional assignment-boundary
  expected-failure entries for invalid delayed-pulse RHS values, mixed
  assignment-family conflicts, incompatible pulse-delay mixes, combinational
  self-dependency, and D-input self-dependency.
- Stable diagnostic codes, corpus behavior checks, check JSON, normalized
  semantic JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — assignment-boundary widening selected
- Completed `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.2`.
- The selected implementation will promote invalid delayed-pulse RHS values,
  mixed assignment-family conflicts, incompatible pulse-delay mixes, and
  illegal self-dependency families into maintained expected-failure corpus
  entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — name/reference widening shipped
- Completed `R12-NAME-REFERENCE-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has six additional name/reference expected-failure
  entries for malformed direct FSM source names, malformed composition top
  names, malformed state and standalone-DT names, malformed transition
  targets, and unknown transition targets.
- Stable diagnostic codes, corpus behavior checks, check JSON, normalized
  semantic JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — name/reference widening selected
- Completed `R12-NAME-REFERENCE-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-NAME-REFERENCE-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed source names, malformed
  state/DT names, malformed transition targets, and unknown transition targets
  into maintained expected-failure corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — system-section widening shipped
- Completed `R12-SYSTEM-SECTION-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has six additional malformed `+system`
  expected-failure entries for incomplete sections, duplicate clock/reset
  entries, malformed entry structures, and invalid clock/reset identifiers.
- Stable diagnostic codes, corpus behavior checks, check JSON, normalized
  semantic JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — system-section widening selected
- Completed `R12-SYSTEM-SECTION-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-SYSTEM-SECTION-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed `+system` failures into
  maintained expected-failure corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — malformed-form widening shipped
- Completed `R12-MALFORMED-FORM-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has six additional malformed-form expected-failure
  entries for malformed top-level source roots, unsupported single-token
  actions, empty guarded blocks, malformed test branches, and malformed bare
  test selectors.
- Stable diagnostic codes, corpus behavior checks, check JSON, normalized
  semantic JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — malformed-form widening selected
- Completed `R12-MALFORMED-FORM-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-MALFORMED-FORM-CORPUS-WIDENING.2`.
- The selected implementation will promote malformed source/body/test-form
  failures into maintained expected-failure corpus entries.
- No compiler behavior changed.

## 2026-05-20: R12 regression corpus — language-contract widening shipped
- Completed `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.2` and closed the tree.
- The maintained corpus now has seven additional language-contract
  expected-failure entries for unsupported top-level source/directive forms,
  generic/template placeholder forms, and bare condition suffix forms.
- Stable diagnostic codes, corpus behavior checks, check JSON, normalized
  semantic JSON, manifest coverage, regression-corpus docs, and the mdBook are
  synchronized.
- No parser acceptance or generation behavior changed.

## 2026-05-20: R12 regression corpus — language-contract widening selected
- Completed `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.1`.
- The active R12 frontier is now
  `R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.2`.
- The selected implementation will promote bounded, already-focused
  language-contract rejections into maintained expected-failure corpus entries
  with stable diagnostics and support-accounting checks.
- No compiler behavior changed.

## 2026-05-20: R9 strict mode — legacy <=+ boundary shipped
- Completed `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.2` and closed the tree.
- Strict mode now rejects legacy `<=+` pair and infix assignments with a
  preferred `<=-` migration hint, including generated-child sources.
- Default mode keeps `<=+` compatibility; a paired corpus asset now proves
  default acceptance and strict rejection.
- The mdBook and regression corpus docs now state that strict-supported
  partial-LHS fixtures use preferred `<=-`.

## 2026-05-20: R9 strict mode — legacy <=+ boundary selected
- Completed `R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.1`.
- The active R9 frontier is now strict-mode rejection of the legacy `<=+`
  assignment alias while preserving default-mode compatibility.
- The next implementation leaf must keep preferred `<=-` strict-supported,
  move `<=+` into explicit compatibility evidence, and sync the book plus
  corpus docs.

## 2026-05-20: R8 language-contract hardening — delayed-pulse partial-LHS boundary shipped
- Completed `R8-PARTIAL-LHS-PULSE-BOUNDARY.1`.
- Delayed-pulse `<N` targets are now scalar-only at the language boundary:
  indexed, sliced, aggregate, and deconstruct targets reject before HDL
  generation with a targeted diagnostic.
- Parser, pipeline, and CLI entry points are covered, and the mdBook now
  documents the scalar-target-only rule.

## 2026-05-20: R8 language-contract hardening — delayed-pulse partial-LHS boundary split
- Completed `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.3`.
- Closed the preferred partial-LHS tree after splitting indexed/sliced
  delayed-pulse `<N` targets into the active
  `R8-PARTIAL-LHS-PULSE-BOUNDARY.1` implementation leaf.
- Decision: reject unsupported partial delayed pulses deliberately; do not
  widen pulse semantics now.
- No compiler behavior changed.

## 2026-05-20: R8 language-contract hardening — preferred partial-LHS coverage shipped
- Completed `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.2`.
- Focused tests and maintained corpus fixtures now prove preferred `<=-`
  partial indexed/sliced writes, full-width `*_r` outputs, and inferred-width
  behavior alongside existing legacy `<=+` alias compatibility.
- The mdBook language-basics chapter now describes that supported
  partial-LHS surface explicitly.
- No production code changed.

## 2026-05-20: R8 language-contract hardening — preferred partial-LHS coverage selected
- Completed `R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.1`.
- Activated the R8 task tree and selected direct preferred `<=-` partial-LHS
  dual-output coverage as the next leaf.
- Existing legacy `<=+` coverage stays in scope, and broader delayed-pulse or
  vector widening is reserved for a separate decision after the preferred
  spelling is guarded.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — module_info guard selection closed
- Completed `MODULE-INFO-PROJECTION-GUARD.2`.
- Selected no missing implementation guard or wording fix. The existing
  docs/book/support-contract wording already keeps `module_info` bounded,
  compatibility-oriented, and non-canonical as a whole hash.
- Deferred `.3`, closed the tree, and changed no compiler behavior.

## 2026-05-20: Architecture backlog — module_info mirrors audited
- Completed `MODULE-INFO-PROJECTION-GUARD.1`.
- The audit maps direct, composition, generated-child, public-contract, and
  normalized semantic report `module_info` mirrors to existing owners and
  tests.
- The later `.2` decision selected no missing guard or wording fix and closed
  the tree.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — ISF LoweringIR extraction deferred
- Completed `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.2`.
- Current IR phase boundaries remain unchanged. No private `LoweringIR`
  extraction candidate is selected now, `.3` is deferred, and no
  behavior-bearing implementation leaf is PNT-eligible from this tree.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — ISF LoweringIR subfamilies inventoried
- Completed `ISF-LOWERINGIR-BOUNDARY-EXTRACTION.1`.
- Stable private `LoweringIR` subfamilies and public projection points are now
  mapped in the task tree.
- The later `.2` decision selected no extraction candidate now and closed the
  tree.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — GlobalASTManager boundary corrected
- Completed `GLOBAL-AST-MANAGER-BOUNDARY.2` and closed the tree.
- [perl/FSM/GlobalASTManager.pm](perl/FSM/GlobalASTManager.pm) now documents
  compatibility-only status instead of production-wide factorization
  ownership.
- The live direct SystemVerilog first-pass factorization owner remains
  [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm).
- No production behavior changed.

## 2026-05-20: Architecture backlog — GlobalASTManager boundary classified
- Completed `GLOBAL-AST-MANAGER-BOUNDARY.1`.
- `FSM::GlobalASTManager` is compatibility-only; the live direct
  SystemVerilog first-pass factorization owner is
  [perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm](perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/GlobalFactorizationSupport.pm).
- `GLOBAL-AST-MANAGER-BOUNDARY.2` then corrected stale ownership wording and
  closed the tree.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — ExpressionNamer legacy parse boundary guarded
- Completed `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2` and closed the tree.
- Added [t/521-expression-namer-legacy-parse-boundary-audit.t](t/521-expression-namer-legacy-parse-boundary-audit.t).
- The guard locks the current private hash parser shape, hash-aware caller
  behavior, and blessed-only no-op hooks.
- No production behavior changed.

## 2026-05-20: Architecture backlog — ExpressionNamer legacy parse boundary audited
- Completed `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.1`.
- `FSM::ExpressionNamer->parse_expression` is documented as a private
  string-to-legacy-hash parser, not a `CoreAST` or `FSM::AST::*` producer.
- `EXPR-NAMER-LEGACY-PARSE-BOUNDARY.2` then added focused guard coverage and
  closed the tree.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — Duplicate AST utils file removed
- Completed `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2` and closed the tree.
- Removed the standalone `perl/FSM/AST/Utils.pm` duplicate.
- The sole live backend AST constructor owner is now the in-file
  `FSM::AST::Utils` package in [perl/FSM/AST/Node.pm](perl/FSM/AST/Node.pm).
- No generated behavior changed.

## 2026-05-20: Architecture backlog — AST utils owner selected
- Completed `EXPR-AST-UTILS-OWNER-CONSOLIDATION.1`.
- Selected the in-file `FSM::AST::Utils` package in
  [perl/FSM/AST/Node.pm](perl/FSM/AST/Node.pm) as the sole live backend AST
  constructor owner.
- `EXPR-AST-UTILS-OWNER-CONSOLIDATION.2` then removed the unimported
  standalone duplicate and closed the tree.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — ExpressionNamer tracked duplicate removed
- Completed `EXPR-NAMER-TRACKED-COPY-CLEANUP.1` and closed the tree.
- Removed the formerly tracked `perl/FSM/ExpressionNamer.pm.new` duplicate
  after static search found no runtime or test load path.
- The live owner remains [perl/FSM/ExpressionNamer.pm](perl/FSM/ExpressionNamer.pm).
- No expression naming behavior changed.

## 2026-05-20: Architecture backlog — Expression AST ownership follow-up trees created
- Completed `IR-EXPRESSION-AST-OWNERSHIP.3` and closed the tree.
- Proposed follow-up trees now own each cleanup candidate:
  `EXPR-NAMER-TRACKED-COPY-CLEANUP`,
  `EXPR-AST-UTILS-OWNER-CONSOLIDATION`,
  `EXPR-NAMER-LEGACY-PARSE-BOUNDARY`, and
  `GLOBAL-AST-MANAGER-BOUNDARY`.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — Expression AST ownership classification completed
- Completed `IR-EXPRESSION-AST-OWNERSHIP.2`.
- Deliberate phase boundaries remain separate: direct `CoreAST`, backend
  `FSM::AST::*`, structural `ConnectionExpr`, composition specs, actual
  literal lowering, aggregate type support, and private ISF expression
  payloads.
- `.3` is now selected to create concrete follow-up leaves for the real
  ownership risks: legacy `ExpressionNamer` parsing, `GlobalASTManager`,
  duplicate `FSM::AST::Utils`, and `ExpressionNamer.pm.new`.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — Expression AST ownership inventory completed
- Completed `IR-EXPRESSION-AST-OWNERSHIP.1`.
- The task tree now lists direct `CoreAST`, backend `FSM::AST::*`,
  `ExpressionNamer`, `GlobalASTManager`, enable-graph expression handoffs,
  structural `ConnectionExpr`, composition source-expression specs, actual
  literal lowering, and private ISF expression payloads.
- The active frontier is `IR-EXPRESSION-AST-OWNERSHIP.2` for deliberate versus
  accidental duplication classification.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — Direct structural projection guard completed
- Completed `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3` and closed the tree.
- Added [t/1333-direct-structural-rtl-ir-projection.t](t/1333-direct-structural-rtl-ir-projection.t).
- The guard proves direct `structural_rtl_ir` currently exposes identity and
  port/system-port projection only, and direct body structures remain empty.
- No production code changed.

## 2026-05-20: Architecture backlog — Direct structural guard selected
- Completed `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2`.
- The active implementation frontier is
  `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.3`.
- `.3` must add a no-op regression guard for direct-root `structural_rtl_ir`
  projection parity and must not reroute direct HDL emission.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — Direct structural backend residue map completed
- Completed `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.1`.
- Direct-root HDL still emits through `GeneratedModuleEmitter -> FlattenedDT`
  before direct `StructuralRTLIR` exists; composition already emits the top
  from `StructuralRTLIR`.
- Direct `StructuralRTLIR` is currently port/system-port projection only, so
  the next slice must select a no-op guard/convergence step rather than
  rerouting HDL emission.
- The active frontier is `IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.2`.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — IR follow-up selection completed
- Completed `FSMGEN-IR-AUDIT.4` and closed the audit tree.
- Proposed follow-up task trees now cover direct-root structural backend
  convergence, expression-AST ownership, private ISF `LoweringIR` boundary
  extraction, and `module_info` projection guarding.
- Deliberate non-actions are recorded: raw parser/lowerer/planner objects stay
  private, public JSON/report surfaces stay projections, and no generic all-IR
  refactor is selected.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — IR policy completed
- Completed `FSMGEN-IR-AUDIT.3`.
- Added [docs/IR_POLICY.md](docs/IR_POLICY.md) as the repo-local policy for
  adding, extending, exposing, or retiring IR and IR-like compiler surfaces.
- Future IR changes must document owner, producer/consumer set, invariants,
  public/private boundary, serialization/report contract, defensive-copy
  policy, validation, docs impact, and migration/retirement plan when needed.
- The active frontier is `FSMGEN-IR-AUDIT.4` for concrete follow-up selection.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — IR boundary classification completed
- Completed `FSMGEN-IR-AUDIT.2`.
- Every inventoried IR or IR-like surface now has a phase classification,
  source-of-truth status, public/private status, and disposition.
- The book-facing IR/metadata section now documents the same public/private
  boundary for forward IR projections, `module_info`, composition provenance,
  and private ISF lowerer/parser internals.
- The active frontier is `FSMGEN-IR-AUDIT.3` for repo-local IR policy.
- No compiler behavior changed.

## 2026-05-20: Architecture backlog — IR inventory completed
- Completed `FSMGEN-IR-AUDIT.1`.
- The task tree now inventories parser, ISF scheduler, composition, forward
  IR, report, snapshot, and backend-local IR-like surfaces with owners,
  producers, consumers, and public/private surface notes.
- The active frontier is `FSMGEN-IR-AUDIT.2` for canonical/private boundary
  classification.
- No compiler behavior changed.

## 2026-05-20: R14 — ATL documentation status truth sync completed
- Completed `ISF-ATL-DOC-STATUS-TRUTH-SYNC.1`.
- Removed stale active-tree wording from the ATL book/proposal/status surfaces
  after `ISF-ACTOR-NETWORK-ORCHESTRATION` closed.
- No compiler behavior changed.

## 2026-05-20: R14 — ATL source-expression source-order hardening completed
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.99`.
- Drive-before-instance generated-child actor-to-actor route source
  expressions such as `(writer.payload (+ reader.payload 1))` now have
  explicit coverage for the same targeted ATL source-expression diagnostic
  after actor instances are known.
- The accepted scalar route, sink-expression source-order diagnostic,
  generated artifacts, and schedule-report shape are unchanged.
- The `ISF-ACTOR-NETWORK-ORCHESTRATION` task tree is closed; no active R14
  task-tree frontier remains in `docs/TASK_TREE.md`.

## 2026-05-20: R14 — Repeat-body switch-bound post-do await_any completed
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.112`.
- Top-level `switch` branch nested repeats now support generated blocking
  `(do child (params ...) (bind ...))` before post-do multi-pending
  `(await_any done)`, with a mandatory same-body `(await_all done)` drain
  before nested repeat re-entry.
- The generated do wires input/output binding handoffs, waits for its fresh
  done handoff before the observation, and preserves generated-spawn done
  handoffs until the later drain.
- The repeat-body child activation tree is closed; the ATL frontier completed
  next in `.9.99`.

## 2026-05-20: R14 — ATL source-expression source-order hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.98`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.99`.
- `.9.99` is selected to harden generated-child route source-expression
  diagnostics for drive-before-instance source order.
- No compiler behavior changed in the selection leaf.

## 2026-05-20: R14 — Repeat-body switch-bound post-do await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.111`.
- The active repeat-body frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.112`.
- `.112` is selected to implement the direct top-level `switch` branch
  analogue of the shipped when-contained bound generated-do post-do
  `await_any` subset.
- No compiler behavior changed in the selection leaf.

## 2026-05-20: R14 — ISF timing conventions completed
- Completed `ISF-TIMING-CONVENTIONS.1`.
- Omitted legacy single-clock actor timing now defaults to `clk`, async
  active-low `rst_n`, and watchdog `65535`.
- Explicit timing remains source-owned, and named clock-domain actors keep
  domain-owned clock/reset semantics.
- The book, ISF spec, downstream handoff, public contract, live docs, and
  focused coverage now document the same convention.
- The `ISF-TIMING-CONVENTIONS` tree is closed. After that slice, the active
  R14 frontiers were `ISF-REPEAT-BODY-CHILD-ACTIVATION.112` and
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.99`.

## 2026-05-19: R14 — ATL accepted-route source-order coverage completed
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.97`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.98`.
- The accepted generated-child actor-to-actor route now has positive coverage
  for drive-before-instance source order.
- The book, downstream handoff, spec, design proposal, backlog, and audit now
  document that accepted-route source-order guarantee.

## 2026-05-19: R14 — ATL accepted-route source-order coverage selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.96`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.97`.
- `.9.97` is selected to prove the accepted generated-child actor-to-actor
  route remains accepted when the named route drive appears before the direct
  static actor instances.
- No compiler behavior changed in the selection leaf.

## 2026-05-19: R14 — ATL route sink-expression source-order boundary hardened
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.95`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.96`.
- Drive-before-instance generated-child route sink expressions now fail with
  the same targeted ATL sink-expression diagnostic.
- Ordinary malformed local drive targets such as `((out) 1)` keep the
  generic drive-body scalar-head diagnostic.
- The book, downstream handoff, spec, design proposal, backlog, and audit now
  document that source-order diagnostic guarantee.

## 2026-05-19: R14 — ATL route sink-expression source-order hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.94`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.95`.
- `.9.95` is selected to keep the targeted ATL sink-expression diagnostic
  when a route drive body is authored before the static actor instances.
- No compiler behavior changed in the selection leaf.

## 2026-05-19: R14 — ATL route sink-expression boundary hardened
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.93`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.94`.
- Generated-child actor-to-actor route sink expressions such as
  `((+ writer.payload 1) reader.payload)` now fail with a targeted ATL
  sink-expression diagnostic.
- The book, downstream handoff, spec, design proposal, backlog, and audit now
  document route endpoint expressions as the symmetric source/sink deferred
  boundary.

## 2026-05-19: R14 — ATL route sink-expression hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.92`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.93`.
- `.9.93` is selected to add a targeted generated-child actor-to-actor route
  diagnostic for sink-side expressions.
- No compiler behavior changed in the selection leaf.

## 2026-05-19: R14 — ATL route source-expression boundary hardened
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.91`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.92`.
- Focused coverage now rejects generated-child actor-to-actor route
  source-side expressions such as `(+ reader.payload 1)`.
- The book, downstream handoff, spec, design proposal, backlog, and audit now
  document that boundary directly.
- No production compiler behavior changed.

## 2026-05-19: R14 — ATL route expression hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.90`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.91`.
- `.9.91` is selected to prove generated-child actor-to-actor route
  source expressions remain fail-closed while the shipped scalar endpoint
  route remains unchanged.
- The dedicated mdBook ATL concept and route-term sections remain the
  user-facing truth anchors for this boundary.
- No compiler behavior changed.

## 2026-05-19: R14 — ATL downstream handoff concept coverage synced
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.89`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.90`.
- The downstream ISF handoff now mirrors the dedicated mdBook ATL concept
  sections and has audit coverage.
- No compiler behavior changed.

## 2026-05-19: R14 — ATL downstream handoff concept sync selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.88`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.89`.
- `.9.89` is selected to keep the downstream ISF handoff self-contained and
  synchronized with the new mdBook ATL concept sections.
- This is documentation and audit only; no compiler behavior is selected.

## 2026-05-19: R14 — ATL mdBook concept sections synced
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.87`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.88`.
- The composition chapter now has dedicated ATL concept subsections and audit
  markers for the user-facing actor-network model.
- No compiler behavior changed.

## 2026-05-19: R14 — ATL design proposal route status synced
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.86`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.87`.
- The ATL design proposal now distinguishes one-child pin-route scope from
  the shipped two-child scalar actor-to-actor route.
- The mdBook audit now covers the proposal route-boundary wording. No
  compiler behavior changed.

## 2026-05-19: R14 — ATL design proposal route sync selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.85`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.86`.
- `.9.86` is selected to synchronize the ATL design proposal with the shipped
  generated-child actor-to-actor route boundary and to audit that wording.
- This is documentation and audit only; no compiler behavior is selected.

## 2026-05-19: R14 — ATL reserved-route docs synced
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.84`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.85`.
- The composition chapter, downstream handoff, and backlog now state the
  selected two-child scalar actor-to-actor route is shipped while malformed or
  wider route shapes remain fail-closed.
- The mdBook audit now rejects the stale reserved-route wording. No compiler
  behavior changed.

## 2026-05-19: R14 — ATL reserved-route docs sync selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.83`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.84`.
- `.9.84` is selected to replace remaining stale reserved-route wording in
  the composition chapter, downstream handoff, and backlog with the current
  shipped/tight-fail-closed boundary.
- This is documentation and audit only; no compiler behavior is selected.

## 2026-05-19: R14 — ATL book matrix route status synced
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.82`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.83`.
- The mdBook feature-support matrix now states the exact shipped
  generated-child data-route exceptions and no longer treats every
  actor-to-actor generated-child route as backlog.
- The mdBook audit now covers the corrected matrix markers and rejects the old
  backlog-only wording. No compiler behavior changed.

## 2026-05-19: R14 — ATL book matrix truth sync selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.81`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.82`.
- `.9.82` is selected to synchronize the mdBook feature-support matrix with
  the shipped generated-child actor-to-actor route status.
- The slice must be documentation and audit only. No source syntax,
  parser/lowerer behavior, report shape, generated artifact shape, runtime
  behavior, or route capability is selected.

## 2026-05-19: R14 — ATL route drive argument hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.80`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.81`.
- Focused coverage now rejects generated-child route drive definitions with
  formal parameters and route drive calls with actual arguments.
- Existing parser diagnostics already enforced both cases, so no production
  code changed.
- The book, spec, downstream handoff, design proposal, and backlog now state
  that those forms remain outside the shipped route subset.

## 2026-05-19: R14 — ATL route drive argument hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.79`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.80`.
- `.9.80` is selected to add focused coverage for generated-child route drive
  definitions with formal parameters and route drive calls with actual
  arguments.
- No source syntax, report shape, generated artifact shape, runtime behavior,
  drive actual binding, expression movement, payload protocol,
  mux/storage, fan-in/fan-out, ready/backpressure, recursive actor network, or
  permanent actor grouping behavior is selected.

## 2026-05-19: R14 — ATL design proposal sync shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.78`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.79`.
- The ATL design proposal now records the generated-child route parent
  interface-role boundary, generated-handoff collision hardening, lowerer
  defensive collision backstop, and audit-backed mdBook route-term support
  boundary.
- No source syntax, parser/lowerer behavior, report shape, generated artifact
  shape, runtime behavior, remapping, mux/storage, fan-in/fan-out,
  ready/backpressure, payload protocol, recursive actor network, or permanent
  actor grouping behavior changed.

## 2026-05-19: R14 — ATL design proposal sync selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.77`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.78`.
- `.9.78` is selected to synchronize the ATL design proposal with the latest
  generated-child route parent-boundary, generated-handoff collision,
  lowerer-backstop, and mdBook route-term support-boundary facts.
- This is documentation-only. No source syntax, parser/lowerer behavior,
  report shape, generated artifact shape, runtime behavior, remapping,
  mux/storage, fan-in/fan-out, ready/backpressure, payload protocol,
  recursive actor network, or permanent actor grouping behavior is selected.

## 2026-05-19: R14 — ATL route-term precision docs shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.76`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.77`.
- The mdBook `Generated-Child Route Terms` section now has separate
  subsections for route lifetime/value boundary, generated handoffs, handoff
  remapping, diagnostic ownership, route muxing/storage, fan-in/fan-out,
  ready/backpressure, and payload protocols.
- The mdBook audit now requires those subsection headings and preserves the
  existing generated-child route support/non-support markers.
- No source syntax, parser/lowerer behavior, report shape, generated artifact
  shape, runtime behavior, remapping, mux/storage, fan-in/fan-out, CDC/reset
  remapping, ready/backpressure, payload protocol, recursive actor network,
  or permanent actor grouping behavior changed.

## 2026-05-19: R14 — ATL route-term precision docs selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.75`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.76`.
- `.9.76` is selected to make the mdBook's dedicated
  `Generated-Child Route Terms` section a precise term-by-term support
  boundary covering generated handoffs, remapping, mux/storage,
  fan-in/fan-out, ready/backpressure, payload protocols, parser/lowerer
  collision ownership, route lifetime, and the one-bit drive-call-cycle
  boundary.
- This is a documentation-only selection. No source syntax, parser/lowerer
  behavior, report shape, generated artifact shape, runtime behavior,
  remapping, mux/storage, fan-in/fan-out, CDC/reset remapping,
  ready/backpressure, payload protocol, recursive actor network, or permanent
  actor grouping behavior is selected.

## 2026-05-19: R14 — ATL route-term book audit shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.74`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.75`.
- The mdBook feature-matrix audit now extracts the dedicated
  `Generated-Child Route Terms` section and checks coverage markers for
  generated handoffs, handoff remapping, route muxing/storage,
  fan-in/fan-out, ready/backpressure, payload protocols, parser/lowerer
  collision ownership, and the one-bit drive-call-cycle route boundary.
- No source syntax, runtime behavior, report shape, generated artifact shape,
  remapping, route mux/storage, fan-in/fan-out, CDC/reset remapping,
  ready/backpressure, payload protocol, recursive actor network, or permanent
  actor grouping behavior changed.

## 2026-05-19: R14 — ATL route-term book audit selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.73`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.74`.
- `.9.74` is selected to add an mdBook audit for the dedicated
  `Generated-Child Route Terms` section.
- The audit must keep handoff remapping, route muxing/storage,
  fan-in/fan-out, ready/backpressure, payload protocols, parser/lowerer
  collision ownership, generated handoffs, and the current one-bit
  drive-call-cycle boundary visible in the book.
- No source syntax, runtime behavior, report shape, generated artifact shape,
  remapping, route mux/storage, fan-in/fan-out, CDC/reset remapping,
  ready/backpressure, payload protocol, recursive actor network, or permanent
  actor grouping behavior is selected.

## 2026-05-19: R14 — ATL lowerer collision backstop shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.72`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.73`.
- The lowerer now revalidates selected generated-child actor-to-actor route
  trigger, event, data, and named-drive request handoff names before
  generated-top wiring.
- Mutated scheduler-facing metadata that collides with parent interface,
  actor-owned storage, or another generated handoff fails closed with a
  targeted lowerer diagnostic.
- Normal source diagnostics remain parser-owned, and no source syntax,
  report shape, generated artifact shape, remapping, route mux/storage,
  fan-in/fan-out, CDC/reset remapping, ready/backpressure, payload protocol,
  recursive actor network, or permanent actor grouping behavior changed.

## 2026-05-19: R14 — ATL lowerer collision backstop selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.71`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.72`.
- `.9.72` is selected as a defensive lowerer backstop for malformed or
  mutated scheduler-facing actor metadata that would collide with selected
  generated-child actor-to-actor trigger, event, data, or named-drive request
  handoff names.
- Normal `.isf` source diagnostics remain parser-owned from `.9.70`; no
  source syntax, report shape, generated artifact shape, remapping, mux,
  storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure, payload
  protocol, recursive actor network, or permanent grouping behavior is
  selected.

## 2026-05-19: R14 — ATL generated-handoff collision hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.70`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.71`.
- Parent interface or actor-owned storage names that collide with the
  generated-child actor-to-actor route's trigger, event, data, or named-drive
  request handoffs now fail closed in focused coverage.
- The parser now rejects the route drive-request collision before the
  scheduler can materialize `forward_payload_start`.
- Generated-handoff remapping, route mux/storage, fan-in/fan-out, interface
  remapping, CDC/reset remapping, ready/backpressure, payload protocols,
  recursive actor networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-handoff collision hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.69`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.70`.
- `.9.70` is selected to prove parent-declared interface or storage names
  cannot collide with the generated-child actor-to-actor route's trigger,
  event, data, or named-drive request handoffs.
- Route mux/storage, fan-in/fan-out, generated-handoff remapping, interface
  remapping, CDC/reset remapping, ready/backpressure, payload protocols,
  recursive actor networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child boundary-role hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.68`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.69`.
- Focused coverage now rejects generated-child actor-to-actor route
  transactions with output-as-start, input-as-completion, undeclared boundary
  pins, or wider boundary pins.
- The parser emits the targeted boundary-role diagnostic; the lowerer keeps a
  defensive parent-interface-role backstop.
- Interface remapping, activation fan-in, completion fan-out, boundary
  expressions, route continuation, pending handoff storage, route
  mux/storage, ready/backpressure, payload protocols, recursive actor
  networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child boundary-role hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.67`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.68`.
- `.9.68` is selected to keep the generated-child actor-to-actor route
  boundary pins directionally tied to the parent interface: start from a
  scalar top-level input and complete to a scalar top-level output.
- The mdBook feature matrix also now keeps the latest repeat-body audit
  marker phrases in a visible collapsible block so the documented gate can
  verify the shipped nested repeat activation subsets.
- Output-as-start, input-as-completion, undeclared, and wider boundary pins
  remain deferred fail-closed cases before interface remapping, activation
  fan-in, completion fan-out, route storage, muxing, ready/backpressure,
  payload protocols, recursive actor networks, or permanent actor grouping
  are claimed.

## 2026-05-19: Project documentation — mdBook rendered prose-blob cleanup shipped
- Completed `MDBOOK-PARAGRAPH-SPACING.4`.
- Closed the `MDBOOK-PARAGRAPH-SPACING` task tree.
- Split long rendered prose blocks across the mdBook sources and included
  downstream ISF integration handoff so generated HTML no longer contains
  long `<p>` blobs or long prose `<li>` blobs under the rendered-output audit.
- The slice is formatting-only; whitespace-normalized source comparison
  against `HEAD` is clean for the touched Markdown sources.
- Validation passed with `mdbook build docs/book`, rendered HTML long-prose
  audit, whitespace-normalized source comparison, and `git diff --check`.

## 2026-05-19: Project documentation — mdBook rendered-HTML blob cleanup reopened
- Completed `MDBOOK-PARAGRAPH-SPACING.3`.
- Reopened the task tree because generated HTML still contains long
  list-item prose blobs.
- The active project-documentation frontier is now
  `MDBOOK-PARAGRAPH-SPACING.4`.
- The next slice must split those list items into rendered list-contained
  paragraphs and validate against generated HTML.

## 2026-05-19: Project documentation — mdBook paragraph-spacing cleanup shipped
- Completed `MDBOOK-PARAGRAPH-SPACING.2`.
- Closed the `MDBOOK-PARAGRAPH-SPACING` task tree.
- Reformatted the mdBook source so the user-reported Extensions and
  Embedding and Intent Scheduling chapters, plus other obvious prose blobs
  found during audit, have blank-line paragraph separation.
- The slice is formatting-only: no behavior, syntax, diagnostic, example,
  feature-claim, table, list, or fenced-code content change is intended.
- Validation passed with `mdbook build docs/book`, `git diff --check`, and a
  whitespace-normalized mdBook source comparison against `HEAD`.

## 2026-05-19: Project documentation — mdBook paragraph-spacing cleanup ownership created
- Completed `MDBOOK-PARAGRAPH-SPACING.1`.
- Created task-tree ownership for the requested formatting-only mdBook
  readability cleanup.
- The active project-documentation frontier is now
  `MDBOOK-PARAGRAPH-SPACING.2`.
- Chapter content is intentionally unchanged in this ownership slice; the
  next slice performs the paragraph-spacing cleanup and mdBook gate.

## 2026-05-19: R14 — ATL generated-child boundary-simplicity hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.66`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.67`.
- Focused coverage now rejects generated-child actor-to-actor route
  transactions whose start boundary carries an activation-body sample or
  whose completion boundary carries an extra payload operand.
- The parser emits a targeted boundary-simplicity diagnostic; the lowerer
  keeps a defensive boundary-shape backstop.
- Activation-body sampling, completion payload/fan-out, local setup/cleanup,
  route continuation, pending handoff storage, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child boundary-simplicity hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.65`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.66`.
- `.9.66` is selected to keep route-adjacent start/completion boundaries
  body-free: `(on PORT)` and `(complete PORT)` only.
- Activation-body samples, completion payload/fan-out, local setup/cleanup,
  route continuation, pending handoff storage, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route-boundary cardinality hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.64`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.65`.
- Focused coverage now rejects generated-child actor-to-actor route
  transactions with an extra simple start boundary before the route segment
  or an extra simple completion boundary after it.
- The parser emits a targeted route-boundary cardinality diagnostic; the
  lowerer keeps a defensive boundary-count backstop.
- Activation fan-in, completion fan-out, start-condition arbitration, local
  setup/cleanup, route continuation, pending handoff storage,
  route mux/storage, ready/backpressure, payload protocols, recursive actor
  networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route-boundary cardinality selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.63`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.64`.
- `.9.64` is selected to keep the isolated generated-child actor-to-actor
  route bounded by exactly one simple `(on ...)` before the route segment and
  exactly one simple `(complete ...)` after it.
- Activation fan-in, completion fan-out, start-condition arbitration, local
  setup/cleanup, route continuation, pending handoff storage, route
  mux/storage, ready/backpressure, payload protocols, recursive actor
  networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route-isolation hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.62`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.63`.
- Focused coverage now rejects generated-child actor-to-actor route
  transactions with parent-local work before the source trigger or after the
  sink event wait.
- The parser emits a targeted route-isolation diagnostic; the lowerer keeps
  a defensive clause-index and parent-transaction-clause backstop.
- Pre-route setup, post-route sampling, local side effects, cleanup work,
  route continuation, pending handoff storage, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route-isolation hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.61`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.62`.
- `.9.62` is selected to keep the generated-child actor-to-actor route as
  the only executable parent transaction-body work between the transaction
  start condition and completion.
- Pre-route setup, post-route sampling, local side effects, cleanup work,
  route continuation, pending handoff storage, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route-contiguity hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.60`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.61`.
- Focused coverage now rejects generated-child actor-to-actor route
  sequences whose route clauses are ordered but interrupted by parent-local
  work before the data drive call.
- The parser emits a targeted route-contiguity diagnostic; the lowerer keeps
  a defensive clause-index backstop for generated-top construction.
- Interleaved parent work, local side effects, pre/post route sampling,
  route continuation, pending handoff storage, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route-contiguity hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.59`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.60`.
- `.9.60` is selected to keep the generated-child actor-to-actor route as
  one contiguous transaction-body segment: source trigger, source event
  wait, data drive call, sink trigger, and sink event wait.
- Interleaved parent work, local side effects, pre/post route sampling,
  route continuation, pending handoff storage, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child source-wait order hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.58`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.59`.
- Focused coverage now rejects generated-child actor-to-actor route
  sequences that wait on the source child event before triggering the source
  child.
- No production code change was required; the existing parser order
  diagnostic already enforced this boundary.
- Pre-trigger acknowledgement, sticky event sampling, event replay, route
  continuation, pending handoff storage, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child source-wait order hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.57`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.58`.
- `.9.58` is selected to keep the generated-child actor-to-actor route
  ordered so the source child event wait occurs after the source child
  trigger.
- Source-wait-before-trigger route shapes remain fail-closed before
  pre-trigger acknowledgement, sticky event sampling, event replay, route
  continuation, pending handoff storage, route mux/storage,
  ready/backpressure, or payload protocol behavior is claimed.

## 2026-05-19: R14 — ATL generated-child sink-wait order hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.56`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.57`.
- Focused coverage now rejects generated-child actor-to-actor route
  sequences that wait on the sink child event before triggering the sink
  child.
- No production code change was required; the existing parser order
  diagnostic already enforced this boundary.
- Pre-trigger acknowledgement, sticky event sampling, event replay, route
  continuation, pending handoff storage, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child sink-wait order hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.55`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.56`.
- `.9.56` is selected to keep the generated-child actor-to-actor route
  ordered so the sink child event wait occurs after the sink child trigger.
- Sink-wait-before-trigger route shapes remain fail-closed before
  pre-trigger acknowledgement, sticky event sampling, event replay, route
  continuation, pending handoff storage, route mux/storage,
  ready/backpressure, or payload protocol behavior is claimed.

## 2026-05-19: R14 — ATL generated-child sink-trigger order hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.54`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.55`.
- Focused coverage now rejects generated-child actor-to-actor route
  sequences that trigger the sink child before the data drive call.
- No production code change was required; the existing parser order
  diagnostic already enforced this boundary.
- Speculative sink activation, delayed payload delivery, route continuation,
  pending handoff storage, route mux/storage, ready/backpressure, payload
  protocols, recursive actor networks, and permanent actor grouping remain
  deferred.

## 2026-05-19: R14 — ATL generated-child sink-trigger order hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.53`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.54`.
- `.9.54` is selected to keep the generated-child actor-to-actor route
  ordered so the data drive call occurs before the sink child trigger.
- Sink-before-drive route shapes remain fail-closed before speculative sink
  activation, delayed payload delivery, route continuation, pending handoff
  storage, route mux/storage, ready/backpressure, or payload protocol
  behavior is claimed.

## 2026-05-19: R14 — ATL generated-child route transaction-owner hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.52`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.53`.
- Focused coverage now rejects generated-child actor-to-actor route clauses
  split across multiple parent transactions: source trigger, source event
  wait, data drive call, sink trigger, and sink event wait must share one
  parent transaction.
- The parser now emits a targeted route-owner diagnostic, and the lowerer
  keeps the same check as a defensive backstop.
- Route continuation, pending handoff storage, transaction rendezvous,
  cross-transaction route scheduling, route mux/storage, ready/backpressure,
  payload protocols, recursive actor networks, and permanent actor grouping
  remain deferred.

## 2026-05-19: R14 — ATL generated-child route transaction-owner hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.51`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.52`.
- `.9.52` is selected to keep the generated-child actor-to-actor route inside
  one parent transaction, with focused fail-closed coverage for split route
  clauses across multiple parent transactions.
- Route continuation, pending handoff storage, transaction rendezvous,
  cross-transaction route scheduling, route mux/storage, ready/backpressure,
  payload protocols, recursive actor networks, and permanent actor grouping
  remain deferred.

## 2026-05-19: R14 — ATL generated-child repeated-wait hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.50`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.51`.
- Focused coverage now rejects extra source-child and sink-child event waits
  in the same generated-child actor-to-actor route sequence.
- The parser now reports this as a generated-child actor-to-actor route
  repeated-wait boundary before the broader trigger-batch/data-movement
  fallback; the lowerer keeps a defensive backstop.
- Event fan-in/fan-out, repeated wait sequencing, route mux/storage,
  CDC/reset remapping, ready/backpressure, payload protocols, recursive actor
  networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child repeated-wait hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.49`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.50`.
- `.9.50` is selected to keep the generated-child actor-to-actor route to
  one source-child event wait and one sink-child event wait in the selected
  route sequence, with focused fail-closed coverage for extra waits.
- Event fan-in/fan-out, repeated wait sequencing, route mux/storage,
  CDC/reset remapping, ready/backpressure, payload protocols, recursive actor
  networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child repeated-trigger hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.48`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.49`.
- Focused coverage now rejects extra source-child and sink-child triggers in
  the same generated-child actor-to-actor route sequence.
- The parser now reports this as a generated-child actor-to-actor route
  repeated-trigger boundary before the broader trigger-batch/data-movement
  fallback; the lowerer keeps a defensive backstop.
- Repeated activation, restart, pending-request merging, trigger
  fan-in/fan-out, multi-activation scheduling, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child repeated-trigger hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.47`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.48`.
- `.9.48` is selected to keep the generated-child actor-to-actor route to
  one source-child trigger and one sink-child trigger in the selected route
  sequence, with focused fail-closed coverage for extra triggers.
- Repeated activation, restart, pending-request merging, trigger
  fan-in/fan-out, multi-activation scheduling, route mux/storage,
  ready/backpressure, payload protocols, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route self-route hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.46`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.47`.
- Focused coverage now rejects same-child source/sink route pairs in the
  generated-child actor-to-actor route.
- No production code change was required; the parser already enforced
  distinct source and sink actor instances for ATL scalar actor-to-actor
  movement.
- Self-route, loopback, child-internal bypass, route mux/storage,
  fan-in/fan-out, ready/backpressure, payload protocols, recursive actor
  networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route self-route hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.45`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.46`.
- `.9.46` is selected to keep the generated-child actor-to-actor route
  between two distinct resolved children and add focused fail-closed coverage
  for same-child source/sink route pairs.
- Self-route, loopback, child-internal bypass, route mux/storage,
  fan-in/fan-out, ready/backpressure, payload protocols, recursive actor
  networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route clock/reset hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.44`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.45`.
- Focused coverage now rejects generated-child actor-to-actor route source
  and sink children whose clock or reset signature differs from the parent.
- No production code change was required; the generated-top lowerer already
  enforced same-clock/reset-policy child wiring.
- CDC bridge insertion, reset remapping, generated-top system-port remapping,
  route mux/storage, fan-in/fan-out, ready/backpressure, payload protocols,
  recursive actor networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route clock/reset hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.43`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.44`.
- `.9.44` is selected to keep the generated-child actor-to-actor route in
  one parent clock/reset policy and add focused fail-closed coverage for
  source or sink child clock/reset mismatches.
- CDC bridge insertion, reset remapping, generated-top system-port remapping,
  route mux/storage, fan-in/fan-out, ready/backpressure, payload protocols,
  recursive actor networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route width hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.42`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.43`.
- Focused coverage now rejects generated-child actor-to-actor route endpoints
  wider than one bit on both the source child output side and sink child
  input side.
- No production code change was required; the lowerer already enforced the
  scalar endpoint-width boundary.
- Payload packing, truncation, extension, route mux/storage, fan-in/fan-out,
  CDC/reset remapping, ready/backpressure, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child route width hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.41`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.42`.
- `.9.42` is selected to keep the generated-child actor-to-actor route
  scalar one-bit and add focused fail-closed coverage for wider source child
  output and sink child input endpoints.
- Payload packing, truncation, extension, route mux/storage, fan-in/fan-out,
  CDC/reset remapping, ready/backpressure, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child data-route hardening shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.40`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.41`.
- Focused coverage now rejects generated-child actor-to-actor routes with a
  missing source child output, multiple endpoint pairs in one route drive,
  multiple selected route drives, or repeated route drive calls.
- The missing source-output diagnostic now names the `source instance` role.
- No ATL source syntax, public report key, generated artifact shape,
  mux/storage, fan-in/fan-out, CDC/reset remapping, ready/backpressure,
  payload protocol, recursive actor network, or permanent actor grouping
  behavior changed.

## 2026-05-19: R14 — ATL generated-child data-route hardening selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.39`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.40`.
- `.9.40` is selected as a hardening slice for the just-shipped
  `isf/atl_two_child_data_pipeline.isf` generated-child actor-to-actor route.
- The selected next work locks the source child output requirement, sink
  child input requirement, one drive body, one endpoint pair, and one
  top-level drive call.
- Broader route mux/storage, multi-route wiring, fan-in/fan-out,
  CDC/reset remapping, ready/backpressure, payload protocols, repeated
  triggers, trigger batches, groups, recursive actor networks, and permanent
  actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child actor-to-actor route shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.38`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.39`.
- `isf/atl_two_child_data_pipeline.isf` now proves one scalar
  generated-child actor-to-actor data route through the two-child generated
  ATL top.
- The parent owns timing: it triggers `reader.capture`, awaits `reader.done`,
  drives `(writer.payload reader.payload)`, triggers `writer.emit`, awaits
  `writer.done`, and completes.
- The generated top wires `reader.payload` to parent `reader_payload` and
  parent `writer_payload` to `writer.payload`; reports reuse
  `actor_network.data_movements[]` and `actor_network.generated_tops[]`.
- Broader multi-route data wiring, fan-in/fan-out, route mux/storage,
  CDC/reset remapping, ready/backpressure, payload protocols, repeated
  triggers, trigger batches, groups, recursive actor networks, and permanent
  actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated-child actor-to-actor route selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.37`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.38`.
- `.9.38` is selected to lower one scalar generated-child actor-to-actor
  route through the existing two-child generated ATL top.
- Selected source shape: resolved `reader` and `writer` children, one drive
  body `(writer.payload reader.payload)`, and a transaction ordered as
  `trigger reader.capture`, `await reader.done`, `drive forward_payload`,
  `trigger writer.emit`, `await writer.done`, then `complete`.
- The selected implementation will reuse `actor_network.data_movements[]` and
  `actor_network.generated_tops[]`; broader multi-route data wiring,
  route mux/storage, CDC/reset remapping, ready/backpressure, payload
  protocols, recursive actor networks, and permanent actor grouping remain
  deferred.

## 2026-05-19: Project operations — hosted ISF parser warning cascade repaired
- Completed `CI-HOSTED-ISF-REGRESSION-CASCADE.1`.
- The GitHub `Perl FSM Regression` run `26091311743` for `de04debd` failed
  in the later ISF regression band because hosted Perl emitted deprecated
  `given` / `when` warnings from `FSM::Adapter::ISF::Parser`.
- The parser actor-body dispatch now uses explicit keyword equality checks,
  and the smartmatch warning suppression was removed because that feature is
  no longer used.
- No ISF syntax, lowering, schedule JSON, or HDL semantics changed in this
  slice; the fix preserves clean-stderr behavior across hosted/system Perl
  versions.
- Local validation passed: parser syntax check, static no-`given`/`when`
  grep, focused hosted-failure ISF cluster, `./bin/ci-regression quick
  --no-book`, `./bin/ci-regression isf --no-book`, and
  `./bin/ci-regression full --no-book`.

## 2026-05-19: Project operations — hosted full regression gate repaired
- Completed `CI-FULL-REGRESSION-GREEN.1`.
- The stale five-test full-regression failures exposed after the Perl 5.32
  compatibility fix are now aligned with shipped behavior.
- Factorization fixpoint coverage now reaches second-pass signature behavior
  through compound post-substitution expressions while keeping the
  bare-intermediate skip policy intact.
- Composition-scope coverage now rejects a malformed nested wiring structure
  instead of rejecting the valid canonical `(source target)` form.
- SystemVerilog assertion checks now allow harmless compare-operand
  parentheses while preserving the semantic checks for width, truthiness, and
  relational lowering.
- The focused five-file cluster and `./bin/ci-regression full --no-book`
  pass locally.

## 2026-05-19: R14 — ATL two-child generated top shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.36`.
- `ISF-ACTOR-NETWORK-ORCHESTRATION.9.37` is the active ATL frontier and must
  select the next bounded widening before code.
- Added `isf/atl_two_child_pipeline.isf` for two resolved children with
  sequential `reader.capture`/`reader.done` then
  `writer.emit`/`writer.done` handoffs and no ATL data movement.
- Lowering emits parent, both children, and one generated top. The top wires
  each parent trigger handoff to the matching child start input and each
  child event output back to the parent event handoff.
- Report evidence stays in existing actor-network families, with
  `actor_network.generated_tops[].children[]` carrying per-child generated
  top wiring metadata for the multi-child shape.

## 2026-05-19: R14 — ATL multi-child route diagnostic shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.34`.
- FSMGen now fails closed the reserved generated-child actor-to-actor
  data-route shape when a drive-body actor-to-actor movement is coupled to
  qualified actor trigger/event handoffs.
- The diagnostic states that generated-child actor-to-actor data movement
  cannot be combined with actor trigger/event handoffs while multi-child ATL
  top scheduling remains deferred.
- Focused coverage preserves the shipped parent-handoff actor-to-actor route
  and the one-child generated-top trigger/event, pin-ingress, and pin-egress
  fixtures.
- This slice advanced the ATL frontier to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.35`, the selection leaf that has since
  completed.

## 2026-05-19: R14 — ATL multi-child route boundary selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.33`.
- Selected `ISF-ACTOR-NETWORK-ORCHESTRATION.9.34` as the then-active ATL
  frontier.
- `.9.34` will fail closed the reserved generated-child actor-to-actor
  data-route shape before multi-child ATL top scheduling is widened.
- Selected reserved shape: two resolved child instances, one existing
  `(sink source)` drive pair such as `(writer.payload reader.payload)`,
  producer trigger/event sequencing, the drive call, then attempted sink
  trigger/event sequencing.
- Shipped parent-handoff actor-to-actor routes and one-child generated-top
  trigger/event, pin-ingress, and pin-egress fixtures must remain accepted.

## 2026-05-19: R14 — ATL resolved-child pin egress top wiring shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.32`.
- Added `isf/atl_resolved_child_pin_egress_pipeline.isf`.
- FSMGen now wires one scalar resolved-child output route to one top-level
  output pin through the generated ATL top for the selected shape
  `(pins.result worker.payload)` after `worker.done`.
- The generated top wires child `payload` to parent `worker_payload`, parent
  `result` to top `result`, parent trigger to child `process_start`, and
  child `done` to the parent event handoff.
- Public report surfaces remain `actor_network.data_movements[]` and
  `actor_network.generated_tops[]`; private top data-link plumbing is not a
  new public report family.
- This slice advanced the ATL frontier to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.33`, the selection leaf that has since
  completed.

## 2026-05-19: R14 — ATL resolved-child pin egress top wiring selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.31`.
- The next active ATL implementation leaf is
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.32`.
- `.9.32` is selected to wire one scalar resolved-child output route to one
  top-level output pin through the generated ATL top, using the source shape
  `(pins.result worker.payload)` after the parent has triggered
  `worker.process` and awaited `worker.done`.
- No compiler behavior changed in the selection slice.
- Actor-to-actor generated-child routes, multi-child data wiring, route mux/storage,
  CDC/reset remapping, ready/backpressure, payload protocols, recursive actor
  networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL resolved-child pin ingress top wiring shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.30`.
- Added `isf/atl_resolved_child_pin_ingress_pipeline.isf` for one scalar
  top-level input-pin route into one resolved child through the generated ATL
  top.
- The generated top now wires top `payload` to the parent, parent
  `worker_payload` to child input `payload`, parent `worker_process_start` to
  child `process_start`, and child `done` to parent `worker_done`.
- Schedule JSON continues to expose the route through
  `actor_network.data_movements[]` and generated-top discovery through
  `actor_network.generated_tops[]`; no new public report family was added.
- Generated child `.fsm` output can carry generated `+interface` role
  metadata for selected ATL child input ports so HDL generation preserves
  those ports.
- Broader generated-child actor-to-actor routes, actor-to-pin routes,
  multi-child data wiring, route mux/storage, CDC/reset remapping, ready/backpressure,
  payload protocols, recursive actor networks, and permanent actor grouping
  remain deferred or fail-closed.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.31`.

## 2026-05-19: R14 — ATL resolved-child pin ingress selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.29`.
- The next active ATL implementation leaf is
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.30`.
- `.9.30` is selected to wire one scalar top-level input pin into one resolved
  child through the generated ATL top, using the source shape
  `(worker.payload pins.payload)` plus the existing `worker.process` trigger
  and `worker.done` event wait.
- No compiler behavior changed in the selection slice.
- Actor-to-actor generated-child routes, actor-to-pin generated-child routes,
  multi-child ATL data wiring, route mux/storage, CDC, ready/backpressure, payload
  protocol, recursive actor networks, and permanent actor grouping remain
  deferred.

## 2026-05-19: R14 — ATL generated-top HDL promotion shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.28`.
- The resolved-child generated-top fixture now has plain and strict CLI HDL
  coverage in `t/1330-isf-atl-resolved-child-fixture-coverage.t`.
- The emitted SystemVerilog is asserted to contain the generated top,
  scheduled parent, resolved child, parent-to-child trigger link, and
  child-to-parent event link.
- No production code change was required.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.29`.

## 2026-05-19: R14 — ATL generated-top HDL promotion selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.27`.
- The next active ATL implementation leaf is
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.28`.
- `.9.28` is selected to prove plain and strict CLI SystemVerilog generation
  for `isf/atl_resolved_child_pipeline.isf`, including the generated top,
  scheduled parent, resolved child, and selected internal trigger/event
  handoff links.
- No compiler behavior changed in the selection slice. No new report schema
  is selected; `actor_network.generated_tops[]` remains the discovery surface.
- Multi-child ATL tops, generated-child data routes, payloads,
  ready/backpressure, CDC, route mux/storage, recursive actor networks, and
  permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL generated top shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.26`.
- The resolved-child fixture now emits the parent
  `atl_resolved_child_pipeline.fsm`, resolved child
  `atl_resolved_child_pipeline__worker.fsm`, and generated top
  `atl_resolved_child_pipeline_top.fsm`.
- The generated top wires the parent public pins to the top boundary, connects
  parent `worker_process_start` to child `process_start`, and connects child
  `done` to parent `worker_done`.
- Schedule JSON reports this through `actor_network.generated_tops[]`; the
  public ISF contract advertises the key family.
- Broader multi-child ATL data wiring, generated-child data routes, trigger batches,
  CDC, ready/backpressure, payload binding, route mux/storage, recursive actor
  networks, and permanent actor grouping remain deferred or fail-closed.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.27`.

## 2026-05-19: R14 — ATL generated top subset selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.25`.
- The next active ATL implementation leaf is
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.26`.
- `.9.26` is selected to emit the first generated ATL top for exactly one
  resolved child, one parent trigger handoff, and one parent event wait with
  matching parent/child clock and reset names/policies.
- The selected top will instantiate the parent and resolved child, wire
  public top-level pins to the parent, wire the parent trigger handoff to the
  child transaction start input discovered from the child transaction's
  authored `(on START_SIGNAL)`, and wire the child event output to the parent
  event handoff input.
- Broader generated-top inference, multiple children, data movement, trigger
  batches, groups, CDC, ready/backpressure, payloads, route mux/storage,
  recursive actor networks, and generated-top conflicts remain fail-closed or
  deferred.

## 2026-05-19: R14 — ATL resolved-child fixture shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.24`.
- Added `isf/atl_resolved_child_pipeline.isf` as the reviewable fixture for
  resolved ATL child artifact emission.
- The fixture lowers to exactly `atl_resolved_child_pipeline.fsm` and
  `atl_resolved_child_pipeline__worker.fsm`, emits no
  `atl_resolved_child_pipeline_top.fsm`, and proves strict schedule JSON
  parity through `t/1330-isf-atl-resolved-child-fixture-coverage.t`.
- Schedule JSON reports the resolved `worker` instance plus one
  `transaction_triggers[]` entry and one `event_waits[]` entry; data
  movement, association schedule, and group schedule arrays remain empty.
- Generated ATL tops, HDL child wiring, inferred interface binding,
  actor-event fan-in, route mux/storage, CDC, ready/backpressure, recursive
  actor networks, and permanent actor grouping remain deferred.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.25`.

## 2026-05-19: R14 — ATL resolved-child fixture selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.23`.
- The next active ATL slice is
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.24`, selected to add
  `isf/atl_resolved_child_pipeline.isf`.
- The fixture will prove resolved child `.fsm` artifact emission together
  with parent trigger/event handoffs, while keeping generated ATL tops and
  child wiring deferred.
- No compiler behavior changed.

## 2026-05-19: R14 — ATL child artifacts shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.22`.
- Resolved `(instance NAME of ALIAS.EXPORT)` ATL static actor instances now
  emit child scheduled `.fsm` artifacts named
  `<parent_actor>__<instance>.fsm` in addition to the parent scheduled `.fsm`.
- Schedule JSON continues to advertise those child names through the resolved
  `actor_network.instances[]` `module` and `scheduled_fsm` fields; no new
  report family was added.
- No generated ATL top is emitted, no HDL child wiring is inferred, and
  trigger/event/data handoffs remain external parent ports.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.23`.

## 2026-05-19: R14 — ATL child-artifact boundary selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.21`.
- The next active ATL implementation leaf is
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.22`, selected to emit resolved ATL child
  scheduled `.fsm` artifacts for `(instance NAME of ALIAS.EXPORT)` entries
  using the already reported `<parent_actor>__<instance>.fsm` names.
- The selected next slice keeps the parent scheduled `.fsm` unchanged, emits
  no generated ATL top, and does not infer or wire child interfaces.
- Existing trigger/event/data handoffs remain external parent ports, and
  existing `(use alias.actor as instance ...)` generated-top behavior remains
  separate.
- Generated ATL tops, HDL child wiring, interface binding inference,
  actor-event fan-in, route mux/storage, ready/backpressure, CDC, recursive
  actor networks, and permanent actor grouping remain deferred.

## 2026-05-19: R14 — ATL type-resolution metadata shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.20`.
- Valid `(instance NAME of ALIAS.EXPORT)` forms now resolve to
  metadata-only library/export provenance for explicit imported library
  aliases and existing actor exports.
- Schedule JSON carries resolved instance keys under
  `actor_network.instances[]`: `type_resolution`, `library`, `alias`,
  `export`, `module`, and `scheduled_fsm`.
- The lowerer still emits only the parent scheduled `.fsm`; generated ATL
  child `.fsm` artifacts, generated ATL tops, HDL child wiring, inferred
  handoff binding, actor-event fan-in, route mux/storage, CDC, and
  ready/backpressure remain deferred.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.21`.

## 2026-05-19: R14 — ATL type-resolution metadata subset selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.19`.
- The next active ATL slice is
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.20`, selected to resolve
  `(instance NAME of ALIAS.EXPORT)` to report-visible library/export
  provenance only when `ALIAS` is an explicit import alias and `EXPORT` names
  an actor export.
- The selected report keys for resolved `actor_network.instances[]` entries
  are `type_resolution`, `library`, `alias`, `export`, `module`, and
  `scheduled_fsm`, with reserved future child names
  `<parent_actor>__<instance>` and `<parent_actor>__<instance>.fsm`.
- No compiler behavior changed. Generated ATL child `.fsm` artifacts,
  generated ATL tops, HDL child wiring, inferred handoff bindings,
  route mux/storage, actor-event fan-in, CDC, and ready/backpressure remain
  deferred.

## 2026-05-19: R14 — ATL library-qualified type syntax fails closed
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.18`.
- `(instance NAME of ALIAS.EXPORT)` now fails closed with targeted ATL
  diagnostics for the selected future actor type-resolution source shape.
- The focused regression covers missing imports, non-explicit import aliases,
  unknown aliases, unknown exports, and known exports that remain reserved
  before generated child emission.
- No actor type resolution, generated child `.fsm`, generated ATL top, HDL
  child wiring, or report schema change is claimed. The active ATL frontier
  advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.9.19`.
- Broad ISF gate passed with `Files=235, Tests=1374`.

## 2026-05-19: R14 — ATL actor type-resolution source contract selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.17`.
- Future ATL actor type resolution is selected as explicit
  `(instance NAME of ALIAS.EXPORT)` syntax backed by the enclosing actor's
  library imports and actor exports.
- Unqualified static actor types remain metadata-only, and sibling actor roots
  remain fail-closed instead of acting as child definitions.
- No compiler behavior changed. The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.18`.

## 2026-05-19: R14 — ATL actor-root boundary shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.16`.
- Multiple top-level `(actor ...)` roots now fail closed with a targeted
  diagnostic before ATL actor type resolution or generated child artifacts are
  claimed.
- The focused regression also proves one actor root plus a same-source
  `(library ...)` root remains accepted.
- Broad ISF gate passed with `Files=235, Tests=1373`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.17`.

## 2026-05-19: R14 — ATL actor-root boundary selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.15`.
- Selected `ISF-ACTOR-NETWORK-ORCHESTRATION.9.16` to make multiple top-level
  `(actor ...)` roots fail closed before generated ATL child type resolution
  is claimed.
- No compiler behavior changed. The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.16`.

## 2026-05-19: R14 — ATL multi-event fan-in boundary proof
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.14`.
- Added focused negative coverage in
  `t/1322-isf-actor-network-static.t` for one temporary trigger batch followed
  by two actor event waits.
- The parser fails before scheduled `.fsm` emission with the current
  one-event-wait diagnostic, preserving the single-event parent-handoff
  boundary.
- Broad ISF gate passed with `Files=235, Tests=1372`.
- No production behavior changed. The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.15`.

## 2026-05-19: R14 — ATL multi-event fan-in boundary selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.13`.
- Selected `ISF-ACTOR-NETWORK-ORCHESTRATION.9.14` for negative coverage of
  the deferred multi-event actor fan-in boundary after a temporary trigger
  batch.
- The selected rejected source attempts one trigger batch followed by
  `(await reader.done)` and `(await writer.done)` in the same transaction.
- No compiler behavior changed. The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.14`.

## 2026-05-19: R14 — ATL trigger-batch wait fixture shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.12`.
- Added the file-backed `isf/atl_trigger_batch_wait_pipeline.isf` fixture and
  `t/1329-isf-atl-trigger-batch-wait-fixture-coverage.t`.
- The fixture proves temporary trigger-batch plus single event-wait parent
  orchestration through scheduled `.fsm` structure, strict schedule JSON
  parity, generated trigger/event handoff ports, association schedule
  metadata, compatibility group schedule metadata, empty data movement, and
  plain/strict HDL generation.
- Broad ISF gate passed with `Files=235, Tests=1372`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.13`.

## 2026-05-19: R14 — ATL trigger-batch wait fixture selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.11`.
- Selected `isf/atl_trigger_batch_wait_pipeline.isf` for the next fixture
  slice, using one same-cycle trigger batch to three static actors followed by
  one `writer.done` event wait before completion.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.12`.

## 2026-05-19: R14 — ATL trigger-wait fixture shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.10`.
- Added the file-backed `isf/atl_trigger_wait_pipeline.isf` fixture and
  `t/1328-isf-atl-trigger-wait-fixture-coverage.t`.
- The fixture proves single-actor parent trigger/event orchestration through
  scheduled `.fsm` structure, strict schedule JSON parity, generated
  trigger/event handoff ports, `actor_network.transaction_triggers[]` and
  `actor_network.event_waits[]` metadata, empty association/group/data
  movement arrays, and plain/strict HDL generation.
- Broad ISF gate passed with `Files=234, Tests=1369`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.11`.

## 2026-05-19: R14 — ATL trigger-wait fixture selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.9`.
- Selected `isf/atl_trigger_wait_pipeline.isf` for the next fixture slice,
  using one static actor, one generated trigger handoff output, one generated
  event handoff input, and one top-level transaction that triggers, waits,
  and completes.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.10`.

## 2026-05-19: R14 — ATL pin egress fixture shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.8`.
- Added the file-backed `isf/atl_pin_egress_pipeline.isf` fixture and
  `t/1327-isf-atl-pin-egress-fixture-coverage.t`.
- The fixture proves the bounded scalar actor-to-top-level output pin route
  through scheduled `.fsm` structure, strict schedule JSON parity, generated
  actor source handoff input, `actor_network.data_movements[]` metadata, empty
  association/group schedules, and plain/strict HDL generation.
- Broad ISF gate passed with `Files=233, Tests=1366`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.9`.

## 2026-05-19: R14 — ATL pin egress fixture selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.7`.
- Selected `isf/atl_pin_egress_pipeline.isf` for the next fixture slice,
  using one static actor, one generated actor source handoff, one top-level
  output pin sink, one scalar actor-to-pin drive-body route, and one
  transaction drive call.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.8`.

## 2026-05-19: R14 — ATL pin ingress fixture shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.6`.
- Added the file-backed `isf/atl_pin_ingress_pipeline.isf` fixture and
  `t/1326-isf-atl-pin-ingress-fixture-coverage.t`.
- The fixture proves the bounded scalar top-level input-pin to actor route
  through scheduled `.fsm` structure, strict schedule JSON parity, generated
  actor handoff output, `actor_network.data_movements[]` metadata, empty
  association/group schedules, and plain/strict HDL generation.
- Broad ISF gate passed with `Files=232, Tests=1363`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.7`.

## 2026-05-19: R14 — ATL pin ingress fixture selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.5`.
- Selected `isf/atl_pin_ingress_pipeline.isf` for the next fixture slice,
  using one static actor, one top-level input pin source, one scalar
  pin-to-actor drive-body route, and one transaction drive call.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.6`.

## 2026-05-19: R14 — ATL data-route fixture shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4`.
- Added the file-backed `isf/atl_data_route_pipeline.isf` fixture and
  `t/1325-isf-atl-data-route-fixture-coverage.t`.
- The fixture proves the bounded scalar actor-to-actor data route through
  scheduled `.fsm` structure, strict schedule JSON parity, generated parent
  handoff ports, `actor_network.data_movements[]` metadata, empty
  association/group schedules, and plain/strict HDL generation.
- Broad ISF gate passed with `Files=231, Tests=1360`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.5`.

## 2026-05-19: R14 — ATL data-route fixture selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.3`.
- Selected `isf/atl_data_route_pipeline.isf` for the next fixture slice,
  using two static actors, one scalar actor-to-actor drive-body route, and one
  transaction drive call.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.4`.

## 2026-05-19: R14 — ATL association schedule reports shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2`.
- Schedule JSON now has canonical `actor_network.association_schedules[]`
  entries for task-scoped temporary trigger batches. The shipped kind is
  `temporary_trigger_batch`; lifetime is `task_scoped`.
- Existing `actor_network.group_schedules[]` output remains available as a
  schema-version-1 compatibility view.
- No source syntax or generated HDL behavior changed.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.3`.

## 2026-05-19: R14 — ATL association schedule reports selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.9.1` before implementation.
- Selected `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2` as the next bounded ATL
  slice: add canonical `actor_network.association_schedules[]` report
  metadata for task-scoped temporary associations.
- The selected implementation will preserve existing
  `actor_network.group_schedules[]` output as a schema-version-1
  compatibility view and will not change source syntax or generated HDL
  behavior.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.2`.
- Validation passed: `mdbook build docs/book`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`.

## 2026-05-19: R14 — ATL temporary trigger-batch fixture shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.8.2` with the clarified ATL
  model: actor associations are task-scoped and should not be represented as
  permanent groups by default.
- The fixture is now `isf/atl_trigger_batch_pipeline.isf`, with three static
  actors and one contiguous trigger batch. It has no `(group ...)`
  declaration.
- The new regression proves scheduled `.fsm`, strict schedule JSON, and
  plain/strict HDL reachability for the temporary trigger-batch fixture. Broad
  ISF gate passed with `Files=230, Tests=1357`.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.9.1` for selecting the next
  temporary-association slice before code.

## 2026-05-18: R14 — ATL first realistic fixture selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.8.1` before fixture
  implementation.
- Selected `isf/atl_group_trigger_pipeline.isf` as the first realistic ATL
  fixture: three direct static actor instances, one verbose static group, and
  one exact same-cycle external group-trigger batch.
- The next leaf, `ISF-ACTOR-NETWORK-ORCHESTRATION.8.2`, must add that
  fixture with scheduled `.fsm`, strict schedule JSON, and plain/strict HDL
  coverage while preserving the current fail-closed boundaries.
- The selected fixture does not claim peer event synchronization, endpoint
  data movement, generated ATL child `.fsm` artifacts, generated ATL tops,
  group endpoints, compact group aliases for that leaf, CDC,
  route mux/storage, payloads, or ready/backpressure.
- Validation passed: `mdbook build docs/book`; `git diff --check`.

## 2026-05-18: R14 — ATL realistic fixture frontier decomposed
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.8` decomposition before code.
- The next realistic multi-actor ATL fixture work is split into
  `ISF-ACTOR-NETWORK-ORCHESTRATION.8.1` for fixture selection and
  `ISF-ACTOR-NETWORK-ORCHESTRATION.8.2` for fixture promotion.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.8.1`.
- Validation passed: `mdbook build docs/book`; `git diff --check`.

## 2026-05-18: R14 — ATL group trigger batch lowering shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.7.5` and closed the first
  concurrent group scheduling sequence.
- The selected same-cycle group trigger batch now lowers from existing
  top-level transaction-body `(trigger actor.transaction)` clauses when the
  contiguous batch targets every member of one declared static group exactly
  once.
- The scheduled parent emits one grouped trigger state that pulses all
  generated external actor-transaction trigger outputs in the same cycle.
  Schedule JSON preserves per-target `actor_network.transaction_triggers[]`
  and adds batch-level `actor_network.group_schedules[]` evidence.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.8`
  for realistic multi-actor orchestration fixtures.
- Generated children, group endpoints, event/data-movement coupling,
  route mux/storage, CDC, compact group aliases for that leaf,
  partial/mixed/noncontiguous batches, repeated members, and fan-in/fan-out
  remain deferred or fail-closed.
- Validation passed: syntax checks, focused actor-network, schedule-report
  matrix, and public-contract audits, `mdbook build docs/book`, broad
  `./bin/ci-regression isf --no-book` with `Files=229, Tests=1353`, and
  `git diff --check`.

## 2026-05-18: R14 — ATL group trigger batch selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.7.4`.
- Selected the first concurrent-group scheduling behavior before code:
  contiguous top-level transaction-body `(trigger actor.transaction)` clauses
  may form a same-cycle external trigger batch only when every actor is a
  distinct member of one declared static group.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.7.5`
  for lowering only that selected subset and reporting
  `actor_network.group_schedules[]` evidence.
- No behavior is implemented by this selection leaf; generated children,
  group endpoints, storage/mux insertion, event/data-movement coupling, CDC,
  compact group aliases for that leaf, and broader fan-in/fan-out remain
  deferred or fail-closed.
- Validation passed: `mdbook build docs/book`; `prove -Iperl
  t/1250-isf-spec-focused-test-index-audit.t
  t/1305-isf-book-feature-matrix-audit.t`; `git diff --check`.

## 2026-05-18: R14 — ATL static group metadata shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.7.3`.
- Direct actor-body `(group NAME (members ACTOR...) (mode concurrent))`
  declarations now report static `actor_network.groups[]` metadata for at
  least two already declared direct static actor instances.
- The group metadata is report-only. It does not schedule concurrent
  execution, infer dependencies, insert route mux/storage, emit generated
  child artifacts, create group endpoints, cross clock domains, or accept
  compact `(concurrent ...)` aliases.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.7.4`.
- Validation passed: parser/lowerer/JSON-emitter/public-contract syntax
  checks, focused actor-network, schedule-report matrix, and public-contract
  audits, `mdbook build docs/book`, broad `./bin/ci-regression isf --no-book`
  with `Files=229, Tests=1352`, and `git diff --check`.

## 2026-05-18: R14 — ATL group declarations fail closed
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.7.2`.
- Direct actor-body `(group ...)` declarations and compact
  `(concurrent ...)` aliases now fail closed with targeted ATL group
  diagnostics.
- This is diagnostics only: no group metadata, group endpoints, scheduling
  overlap, generated child artifacts, route mux/storage, CDC, or concurrent
  actor execution is implemented yet.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.7.3`.
- Validation passed: parser syntax check, focused actor-network regression,
  `mdbook build docs/book`, broad `./bin/ci-regression isf --no-book` with
  `Files=229, Tests=1351`, and `git diff --check`.

## 2026-05-18: R14 — ATL concurrent group boundary selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.7.1`.
- Decomposed concurrent actor-group scheduling before code into targeted
  fail-closed group diagnostics, static group metadata, first scheduling
  selection, and first scheduling lowering leaves.
- The next code leaf, `.7.2`, must reject reserved direct actor-body
  `(group NAME (members ACTOR...) (mode concurrent))` declarations and compact
  `(concurrent NAME ACTOR...)` aliases with ATL-specific diagnostics.
- No group metadata, group endpoints, scheduling overlap, generated child
  artifacts, route mux/storage, CDC, or concurrent actor execution is claimed
  yet.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.7.2`.
- Validation passed: `mdbook build docs/book`, spec/book audits, and
  `git diff --check`.

## 2026-05-18: R14 — ATL actor-to-pin handoff lowering shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.6.4` and closed the `.6`
  top-level pin movement group.
- The selected scalar actor endpoint to top-level output pin handoff subset
  now lowers from one named drive body with one
  `(pins.output_pin actor.endpoint)` pair and one top-level transaction drive
  call.
- The parent scheduled `.fsm` reads a generated one-bit actor handoff input,
  drives the existing one-bit top-level output pin during the drive-call
  cycle, and schedule JSON reports kind `scalar_actor_to_pin_handoff` under
  `actor_network.data_movements[]`.
- Wider pins, storage/muxing, generated child `.fsm` artifacts, generated ATL
  tops, HDL child wiring, inline/expression movement, fan-in/fan-out, groups,
  CDC, mixed pin/actor movement in one drive, and trigger/await coupling
  remain deferred or fail-closed.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.7`.
- Validation passed: parser syntax check, focused actor-network regression,
  schedule/drive boundary regressions, public-contract/report audits,
  `mdbook build docs/book`, broad `./bin/ci-regression isf --no-book` with
  `Files=229, Tests=1351`, and `git diff --check`.

## 2026-05-18: R14 — ATL actor-to-pin handoff subset selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.6.3`.
- Selected the first actor endpoint to top-level output pin subset before
  behavior-bearing code: one scalar `(pins.output_pin actor.endpoint)` pair
  in one named drive body, exactly one direct static actor instance, and one
  top-level transaction drive call.
- The selected source is a generated scalar external actor handoff input named
  `actor_endpoint`; the sink is the existing one-bit top-level output pin.
- The selected report kind is `scalar_actor_to_pin_handoff` under
  `actor_network.data_movements[]`, with `source => external_handoff` and
  `sink => top_level_pin`.
- Wider pins, storage/muxing, generated child `.fsm` artifacts, generated ATL
  tops, HDL child wiring, inline/expression movement, fan-in/fan-out, groups,
  CDC, mixed pin/actor movement in one drive, and trigger/await coupling
  remain deferred or fail-closed.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.6.4`.
- Validation passed: `mdbook build docs/book`, spec/book audits, and
  `git diff --check`.

## 2026-05-18: R14 — ATL pin-to-actor handoff lowering shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.6.2`.
- The selected scalar top-level input pin to actor handoff subset now lowers
  from one named drive body with one `(actor.endpoint pins.input_pin)` pair
  and one top-level transaction drive call.
- The parent scheduled `.fsm` reads the existing one-bit top-level input pin,
  drives a generated one-bit actor handoff output during the drive-call cycle,
  and schedule JSON reports kind `scalar_pin_to_actor_handoff` under
  `actor_network.data_movements[]`.
- Actor-to-pin movement, wider pins, storage/muxing, generated child `.fsm`
  artifacts, generated ATL tops, HDL child wiring, inline/expression movement,
  fan-in/fan-out, groups, CDC, and trigger/await coupling remain deferred or
  fail-closed.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.6.3`.
- Validation passed: parser syntax check, focused actor-network regression,
  schedule/drive boundary regressions, `mdbook build docs/book`,
  book/spec audits, broad `./bin/ci-regression isf --no-book` with
  `Files=229, Tests=1350`, and `git diff --check`.

## 2026-05-18: R14 — ATL pin-to-actor handoff subset selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.6.1`.
- Selected the first top-level pin movement subset before behavior-bearing
  code: one scalar `(actor.endpoint pins.input_pin)` pair in one named drive
  body, exactly one direct static actor instance, and one top-level
  transaction drive call.
- The selected source is the existing one-bit top-level input pin; the sink is
  a generated scalar external actor handoff output named `actor_endpoint`.
- Actor-to-pin movement, wider pins, storage/muxing, generated child `.fsm`
  artifacts, generated ATL tops, HDL child wiring, inline/expression movement,
  fan-in/fan-out, groups, CDC, and trigger/await coupling remain deferred or
  fail-closed.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.6.2`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ATL scalar handoff lowering shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.5.4` and closed the `.5`
  actor-to-actor data-movement group.
- The selected scalar actor-to-actor handoff subset now lowers from one named
  drive body with one `(sink_actor.endpoint source_actor.endpoint)` pair and
  one top-level transaction drive call.
- The parent scheduled `.fsm` exposes the generated source handoff as a
  one-bit external input and the generated sink handoff as a one-bit external
  output, with route lifetime limited to the drive-call cycle.
- Schedule JSON now reports the movement through
  `actor_network.data_movements[]`.
- Actor type resolution, generated child `.fsm` artifacts, generated ATL
  tops, HDL child wiring, pin movement, inline/expression movement,
  fan-in/fan-out, groups, CDC, and trigger/await coupling remain deferred or
  fail-closed.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.6`.
- Validation passed: parser/lowerer/JSON-emitter/public-contract syntax
  checks, focused actor-network and schedule-report matrix tests,
  public-contract/manifest/book audit tests, adjacent drive-boundary tests,
  `mdbook build docs/book`, broad `./bin/ci-regression isf --no-book` with
  `Files=229, Tests=1349`, and `git diff --check`.

## 2026-05-18: R14 — ATL scalar handoff subset selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.5.3`.
- Selected the first generated scalar actor-to-actor handoff subset before
  behavior-bearing code: exactly two direct static actor instances, one named
  drive body with one scalar endpoint pair, and one top-level transaction
  drive call.
- Generated parent handoff ports are selected as a scalar external source
  input named `source_actor_source_endpoint` and a scalar external sink output
  named `sink_actor_sink_endpoint`.
- The route lifetime is one drive-call cycle, width evidence is one bit, and
  `actor_network.data_movements[]` report keys are selected.
- Child actor type resolution, generated child `.fsm` artifacts, generated ATL
  tops, HDL child wiring, pin movement, inline/expression movement,
  fan-in/fan-out, groups, CDC, and trigger/await coupling remain deferred or
  fail-closed.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.5.4`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ATL data movement endpoint forms fail closed
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.5.2`.
- Named drive bodies and inline transaction drive-body pairs now reject
  qualified actor endpoint sinks or sources when the qualifier names the
  current static actor instance.
- The diagnostic names ATL actor data movement and whether the reserved
  endpoint appeared as a sink or source.
- Generated actor-to-actor movement, two-instance lowering, route muxes,
  handoff storage, width inference across actor types, generated ATL children,
  generated ATL tops, and HDL routing remain deferred.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.5.3`.
- Validation passed: parser and public-contract syntax checks, focused
  actor-network/public-contract/book audit tests, `mdbook build docs/book`,
  the broad `./bin/ci-regression isf --no-book` gate with `Files=229,
  Tests=1348`, and `git diff --check`.

## 2026-05-18: R14 — ATL data movement boundary selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.5.1`.
- The first actor data movement code leaf is fail-closed reservation for
  qualified actor endpoint drive-body pairs, not generated routing.
- Qualified actor endpoints in drive-body sink/source positions will reject
  with ATL data-movement diagnostics when the qualifier names a declared
  static actor instance.
- Generated actor-to-actor movement, two-instance lowering, route muxes,
  handoff storage, width inference across actor types, generated ATL children,
  generated ATL tops, and HDL routing remain deferred.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.5.2`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ATL actor triggers lower to parent handoff output
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2`.
- Exactly one top-level transaction-body `(trigger actor.transaction)` may
  now target the current single static actor instance.
- FSMGen lowers the trigger to a generated one-cycle parent output named
  `actor_transaction_start`; for example, `reader.capture` becomes
  `reader_capture_start`.
- The scheduled parent `.fsm` exposes and pulses that output. Schedule JSON
  reports the trigger in `actor_network.transaction_triggers[]`.
- The trigger sink is `external_handoff`. Actor type resolution, generated ATL
  child `.fsm` files, generated ATL tops, child trigger wiring, payloads or
  bindings, ready/backpressure, multiple/nested triggers, fan-in/fan-out,
  cross-clock actor triggers, concurrent groups, data movement, and HDL
  behavior remain deferred or fail-closed.
- The active ATL frontier advances to `ISF-ACTOR-NETWORK-ORCHESTRATION.5`;
  that activity must be decomposed/selected before behavior-bearing code.
- Validation passed: focused syntax and actor-network/report/public-contract
  tests, `mdbook build docs/book`, `./bin/ci-regression isf --no-book`
  (Files=229, Tests=1347), and `git diff --check`.

## 2026-05-18: R14 — ATL actor trigger handoff selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.1`.
- The next qualified actor-transaction trigger behavior is scoped to one
  top-level transaction-body `(trigger actor.transaction)` for the current
  single static actor instance.
- The selected lowering maps the trigger to a deterministic one-cycle parent
  output handoff named `actor_transaction_start`; for example,
  `reader.capture` becomes `reader_capture_start`.
- The trigger sink remains external. Actor type resolution, generated ATL
  child `.fsm` files, generated ATL tops, rule-level qualified triggers,
  nested triggers, multiple triggers, fan-in/fan-out, trigger payloads or
  bindings, ready/backpressure, cross-clock actor triggers, concurrent groups,
  and HDL wiring remain deferred or fail-closed.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.2`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ATL actor-event waits lower to parent handoff input
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.2`.
- Exactly one top-level transaction-body `(await actor.event)` may now target
  the current single static actor instance.
- FSMGen lowers the wait to a generated one-bit parent event input named
  `actor_event`; for example, `reader.done` becomes `reader_done`.
- The scheduled parent `.fsm` exposes and waits on that input. Schedule JSON
  reports the wait in `actor_network.event_waits[]`.
- The event source is `external_handoff`. Actor type resolution, generated
  ATL child `.fsm` files, generated ATL tops, qualified actor transaction
  triggers, multiple/nested waits, fan-in/fan-out, event payloads,
  cross-clock actor events, concurrent groups, data movement, and HDL behavior
  remain deferred or fail-closed.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.4.4.1`.
- Validation passed: focused syntax and actor-network/report/public-contract
  tests, `mdbook build docs/book`, `./bin/ci-regression isf --no-book`
  (Files=229, Tests=1346), and `git diff --check`.

## 2026-05-18: R14 — ATL actor-event wait handoff selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.1`.
- The next generated actor-event wait behavior is scoped to one top-level
  transaction-body `(await actor.event)` for the current single static actor
  instance.
- The selected lowering maps the wait to a deterministic one-bit parent event
  handoff input named `actor_event`; for example, `reader.done` becomes
  `reader_done`.
- The event producer remains external. Actor type resolution, generated ATL
  child `.fsm` files, generated ATL tops, qualified actor transaction
  triggers, multiple or nested event waits, fan-in/fan-out, event payloads,
  cross-clock actor events, concurrent groups, data movement, and HDL behavior
  remain deferred or fail-closed.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3.2`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ATL reserved event/trigger forms fail closed
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.4.2`.
- Reserved qualified `(await actor.event)`, transaction-body
  `(trigger actor.transaction)`, and rule-level
  `(trigger actor.transaction)` now fail closed with ATL-specific diagnostics
  before scheduled `.fsm` emission when the qualifier names a declared static
  actor instance.
- The guard is instance-aware. Dotted enum-looking names that do not name a
  static actor instance keep their prior diagnostics.
- Existing unqualified local behavior remains unchanged: `(await signal)`
  still waits on a local signal, and rule-level `(trigger transaction)` still
  triggers a local transaction.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.4.3`, which must select real generated
  actor-event behavior before code.
- Validation passed: parser and public-contract syntax checks, focused tests,
  public contract/manifest audits, schedule-report/spec/book audits,
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book`
  (Files=229, Tests=1345), and `git diff --check`.

## 2026-05-18: R14 — ATL event/trigger boundary selected
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.4.1`.
- The actor-event frontier is now split into recoverable leaves. The next code
  leaf, `ISF-ACTOR-NETWORK-ORCHESTRATION.4.2`, must reject reserved
  qualified `(await actor.event)`, transaction-body
  `(trigger actor.transaction)`, and rule-level
  `(trigger actor.transaction)` with ATL-specific diagnostics before
  scheduled `.fsm` emission.
- Existing unqualified local forms remain unchanged: `(await signal)` still
  waits on a local signal, and rule-level `(trigger transaction)` still
  triggers a local transaction.
- Generated actor-event behavior remains deferred. No generated ATL child
  `.fsm`, generated ATL top, route mux, handoff storage, event fan-in/fan-out
  contract, schedule-report event keys, or HDL behavior is promised by this
  selection slice.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ATL v0 public contract settled
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.2`.
- The ATL v0 public direction is now synchronized across the design proposal,
  ISF spec, downstream integration handoff, public contract, mdBook, roadmap,
  and task tree.
- The accepted shipped surface is still only one direct actor-body static
  instance recorded as `actor_network` metadata. Future ATL syntax is reserved
  but not implemented: endpoint-aware drive-body `(sink source)` movement,
  `(do actor.transaction)`, `(spawn actor.transaction as NAME)`,
  `(trigger actor.transaction)`, `(await actor.event)`, and direct actor-body
  groups.
- `connect`, `transfer`, and `move` are not ATL v0 movement syntax.
- The current generated-artifact contract is explicit: no generated ATL child
  `.fsm`, generated ATL top, route mux, handoff storage, event payload, group
  schedule, or HDL behavior is promised until a later implementation leaf
  ships it.
- The active ATL frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.4` for the first bounded actor-event
  trigger/sync subset selection.
- Validation passed: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`,
  focused actor-network/report/public metadata/book tests (Files=7,
  Tests=186), `mdbook build docs/book`, `./bin/ci-regression isf --no-book`
  (Files=229, Tests=1344), and `git diff --check`.

## 2026-05-18: R14 — SPECFORGE strict-check JSON failure surface fixed
- Completed `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3` and closed the
  downstream SPECFORGE stage/contract bug tree.
- `.isf` parser, lowering, schedule-report, and downstream semantic check
  failures now emit structured `success: false` JSON under `--check --json`
  and `--check-json`, exit nonzero, and keep stderr clean.
- The exact `sf-isf-stage-ready-valid` artifact now reports its residual
  `isf_priority_mixed_timing_conflict` in JSON instead of returning empty
  stdout with stderr-only diagnostics.
- Added focused regression coverage for an ISF lowering failure and an ISF
  semantic conflict in check JSON mode.
- Docs are synchronized across README, the ISF spec, mdBook, downstream
  integration spec, public contract, task tree, roadmap board, and live docs.
  The active R14 frontiers are now
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.111` and
  `ISF-ACTOR-NETWORK-ORCHESTRATION.2`; no active downstream bug frontier
  remains.
- Validation passed after the focused-test index was updated:
  `perl -c bin/fsmgen`, focused check/stage/contract tests, exact SPECFORGE
  source and baseline checks, `mdbook build docs/book`, focused book/doc
  audits, `t/1250-isf-spec-focused-test-index-audit.t`,
  `./bin/ci-regression isf --no-book` (Files=229, Tests=1344), and
  `git diff --check`.

## 2026-05-18: R14 — SPECFORGE ready/valid stage form fixed
- Completed `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2`.
- FSMGen now accepts the downstream-documented transaction-stage spelling
  `(stage name (ready ready_signal) (valid valid_signal))`.
- The older `(stage name (input ready_signal) (output valid_signal))`
  spelling remains accepted as a compatibility alias. Alias mixtures for the
  same endpoint fail closed as duplicate ready or valid endpoints.
- The exact `sf-isf-stage-ready-valid` artifact was reproduced before
  implementation with the unsupported `ready` diagnostic. After the fix it no
  longer fails on the source spelling; it reaches the existing
  `isf_priority_mixed_timing_conflict` diagnostic because `rule_7` and the
  stage valid endpoint both write `ADDRESS`.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  downstream bug frontier advances to
  `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.3`.
- Validation passed: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`,
  `prove -Iperl t/1179-isf-phase-stage-boundary.t
  t/1180-isf-unsupported-transaction-clause-boundary.t
  t/1223-isf-stage-lowering.t
  t/1225-isf-stage-contract-schedule-report.t`, the exact
  `sf-isf-stage-ready-valid` source and baseline strict checks,
  `mdbook build docs/book`, focused book/doc audits, and
  `./bin/ci-regression isf --no-book` (Files=228, Tests=1342), and
  `git diff --check`.

## 2026-05-18: R14 — SPECFORGE flat eventual contract form fixed
- Completed `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1`.
- FSMGen now accepts the downstream-documented flat bounded-eventually
  contract spelling `(contract name (eventually signal within cycles))`.
- The older nested spelling
  `(contract name (eventually signal (within cycles)))` remains accepted as a
  compatibility alias, and both forms lower to the same arm state plus
  pending/age/sticky-fail monitor.
- The minimized `sf-isf-contract-eventually-flat` issue bundle was reproduced
  before implementation and now passes
  `./bin/fsmgen --strict --check --json` with `success: true`.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  downstream bug frontier advances to
  `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.2`.
- Validation passed: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm`,
  `prove -Iperl t/1175-isf-contract-fail-closed.t
  t/1180-isf-unsupported-transaction-clause-boundary.t
  t/1224-isf-contract-lowering.t`, the real
  `sf-isf-contract-eventually-flat` source plus baseline strict JSON checks,
  `mdbook build docs/book`, focused book/doc audits, and
  `./bin/ci-regression isf --no-book` (Files=228, Tests=1341), and
  `git diff --check`.

## 2026-05-18: R14 — SPECFORGE stage/contract reports reproduced
- Created active task tree
  [docs/tasks/ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.md](docs/tasks/ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.md)
  before implementation.
- Reproduced `sf-isf-contract-eventually-flat`: the minimized flat
  bounded-eventually source exits `255`, emits zero JSON stdout bytes despite
  `--json`, and writes the reported contract diagnostic to stderr.
- Reproduced `sf-isf-stage-ready-valid`: the minimized ready/valid stage
  source exits `255`, emits zero JSON stdout bytes despite `--json`, and
  writes the reported unsupported `ready` diagnostic to stderr.
- Both issue-bundle `expected/baseline-good.isf` files pass strict JSON check
  with `success: true`.
- No implementation fix is included in this slice. The active fix frontier is
  `ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.1`.

## 2026-05-18: R14 — ISF ATL static instance syntax narrowed
- Advanced `ISF-ACTOR-NETWORK-ORCHESTRATION.2` with the source-shape
  correction requested during review.
- A top-level actor now declares the shipped static ATL child actor instance
  only through direct actor-body `(instance NAME of ACTOR_TYPE)` syntax.
  `(network ...)` is not an accepted wrapper and now fails closed.
- The parser shell still preserves `actor_network.kind` plus instance `name`,
  `actor_type`, and `declaration`, and schedule JSON exposes the same
  metadata through top-level `actor_network`; the only shipped declaration
  value is now `actor`.
- This remains metadata-only ATL: no actor type resolution, child
  instantiation, generated child `.fsm` artifacts, generated ATL top,
  actor-to-actor movement, qualified actor transaction triggers, actor events,
  groups, or multi-instance scheduling.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  handoff, public contract, ATL design proposal, task tree, roadmap board, and
  live docs.
- Validation passed: `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`,
  `t/1322-isf-actor-network-static.t`,
  `t/1255-isf-schedule-report-golden-matrix.t`, public schedule-report
  metadata audits, spec/book audits, `mdbook build docs/book`,
  `git diff --check`, and `./bin/ci-regression isf --no-book`
  (Files=228, Tests=1340).

## 2026-05-18: R14 — ISF static actor-network metadata shipped
- Completed `ISF-ACTOR-NETWORK-ORCHESTRATION.3`.
- A top-level actor can now declare exactly one static actor instance through
  the direct actor-level `(instance NAME of ACTOR_TYPE)` clause.
- The parser shell preserves `actor_network.kind` plus instance `name`,
  `actor_type`, and declaration spelling, and schedule JSON exposes the same
  metadata through top-level `actor_network`.
- This slice is metadata-only: it does not resolve actor types, instantiate
  child actors, emit generated child `.fsm` artifacts, generate an ATL top,
  move data between actors, trigger qualified actor transactions, or wait on
  actor events.
- Multiple static instances, groups, dynamic/non-scalar instance names,
  direct recursive instances, endpoint-aware drive movement, actor events, and
  qualified actor transaction triggers remain deferred to later ATL leaves.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  handoff, public contract, ATL design proposal, task tree, roadmap board, and
  live docs. The actor-network frontier advances to
  `ISF-ACTOR-NETWORK-ORCHESTRATION.2`, the broader ATL syntax/public-contract
  leaf needed before event, trigger, group, and movement implementation
  leaves.
- Validation passed: parser/lowerer/report/contract syntax checks,
  `t/1322-isf-actor-network-static.t`,
  `t/1255-isf-schedule-report-golden-matrix.t`,
  public schedule-report metadata audits, spec/book audits,
  `mdbook build docs/book`, `git diff --check`, and
  `./bin/ci-regression isf --no-book` (Files=228, Tests=1341).

## 2026-05-18: R14 — ISF Actor Transfer Level model captured
- Added [docs/ISF_ATL_DESIGN_PROPOSAL.md](docs/ISF_ATL_DESIGN_PROPOSAL.md)
  as the concrete ATL v0 proposal. It keeps `(actor ...)` as the root and now
  selects direct top-level actor-body ATL clauses instead of a `(network ...)`
  wrapper.
- The proposal defines qualified endpoints, verbose and compact syntax
  candidates, endpoint-aware drive-body pairs in existing `(sink source)`
  order, one-cycle events, top-level orchestration, concurrent groups,
  first-slice scope, and fail-closed boundaries.
- Top-level `connect` is no longer the preferred ATL v0 movement syntax; the
  scheduler should derive mux/enable/handoff storage and connectivity from
  drive body pairs plus drive-call timing points.
- This choice keeps ISF uniform and low friction: the scheduler discriminates
  endpoint roles instead of requiring a new movement keyword.
- The scheduler also owns dynamic runtime routing between actors. FSMGen
  derives route selects, mux/enables, handoffs, and generated connectivity
  from movement intent.
- The RTL mux analogy is now explicit: ATL movement clauses are not permanent
  wires. Multiple source actors may feed one sink actor at different scheduled
  moments only when FSMGen can prove disjoint timing or emit a reviewable
  mux/enable/handoff plan.
- `(network ...)` is not treated as required syntax; it is only one candidate
  scoping form pending review.
- Activated `ISF-ACTOR-NETWORK-ORCHESTRATION.1` as the current
  actor-network clarification/design leaf.
- Recorded Actor Transfer Level (`ATL`) as the working mental model: RTL moves
  values between flops/registers; ATL moves data, information, and activation
  between actors.
- Captured the intended source shape: the whole network is a top-level actor,
  that actor's transactions/rules can trigger actors or transactions inside
  the network, and data movement must cover actor-to-actor links, concurrent
  actor groups, and top-level pin boundaries.
- FSMGen is expected to infer the needed schedule and lower to explicit
  `.fsm`, so this remains IAL1 while the source is explicit `.isf`
  actor/network syntax.
- No implementation was started. Exact syntax, compact/verbose spelling,
  event/data primitive names, first subset, and fail-closed boundaries remain
  to clarify before code.

## 2026-05-18: R14 — ISF actor-network orchestration proposed
- Added proposed task tree
  [docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md](docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md).
- The proposed axis covers explicit `.isf` actor networks: orchestrator
  actors can eventually trigger peer/sub-actors, synchronize on named
  one-cycle event pulses, and move data through scheduler-visible bindings
  while FSMGen owns scheduling/lowering to explicit `.fsm`.
- This is currently classified as likely IAL1 because the source remains
  explicit ISF actor/network syntax. It becomes IAL2 only if the source moves
  above explicit actor/network constructs into protocol/platform intent
  inference.
- The tree is proposed, not active implementation. The first leaf requires
  user clarification before code.

## 2026-05-18: R14 — ISF when-contained bound generated do before post-do await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.110`.
- Top-level `when` bodies may now contain nested repeats with multiple
  generated spawns, static-parameter generated blocking
  `(do child (params ...) (bind ...))` while those generated spawns remain
  pending, `(await_any done)` as an observation point after that generated
  do, and a later same-body `(await_all done)` drain before the nested repeat
  check can loop.
- Lowering waits for the generated do instance's fresh done handoff before
  evaluating the post-do `await_any`, wires generated-top input/output
  binding handoffs for that lexical generated do site, keeps generated-spawn
  done handoffs live through the observation, and drains every pending
  generated child before nested repeat re-entry.
- At that time, the domain-metadata post-do generated-do analogue and the
  switch-contained bound analogue remained fail-closed, along with
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.111`, which must
  select the next bounded subset before implementation.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=57), focused repeat/spawn/doc checks (Files=3, Tests=385), `mdbook build docs/book`,
  `./bin/ci-regression isf --no-book` (Files=227, Tests=1338), and
  `git diff --check`.

## 2026-05-18: R14 — ISF when-contained bound generated do before post-do await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.109`.
- Selected top-level `when` body nested repeats with multiple generated
  spawns, static-parameter generated blocking
  `(do child (params ...) (bind ...))` while those generated spawns remain
  pending, `(await_any done)` as an observation point after that generated
  do, and a later same-body `(await_all done)` drain before the nested repeat
  check can loop.
- The selected implementation contract preserves static parameter overrides,
  wires generated-top input/output binding handoffs for the generated do
  instance, waits for that instance's fresh done handoff before the post-do
  `await_any`, keeps generated-spawn done handoffs live through that
  observation, and drains every pending generated child before nested repeat
  re-entry.
- Domain metadata, the switch-contained bound analogue, spawn-after-do before
  the drain, cross-domain activation, deeper nesting, and broader
  outstanding-child semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not
  yet shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.110`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`,
  (Files=2, Tests=320), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained static-parameter generated do before post-do await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.108`.
- Top-level `switch` branches may now contain nested repeats with multiple
  generated spawns, static-parameter generated blocking
  `(do child (params ...))` while those generated spawns remain pending,
  `(await_any done)` as an observation point after that generated do, and a
  later same-body `(await_all done)` drain before the nested repeat check can
  loop.
- Lowering waits for the generated do instance's fresh done handoff before
  evaluating the post-do `await_any`, preserves static generated-top
  parameter binding, keeps generated-spawn done handoffs live through the
  observation, and drains every pending generated child before nested repeat
  re-entry.
- Bind handoffs, domain metadata, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.109`, which must
  select the next bounded subset before implementation.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=56), focused repeat/spawn/doc checks (Files=3, Tests=376), `mdbook build docs/book`,
  `./bin/ci-regression isf --no-book` (Files=227, Tests=1329), and
  `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained static-parameter generated do before post-do await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.107`.
- Selected top-level `switch` branch nested repeats with multiple generated
  spawns, static-parameter generated blocking `(do child (params ...))`
  while those generated spawns remain pending, `(await_any done)` as an
  observation point after that generated do, and a later same-body
  `(await_all done)` drain before the nested repeat check can loop.
- The selected implementation contract preserves the authored static
  parameter overrides, waits for the generated do instance's fresh done
  handoff before the post-do `await_any`, keeps generated-spawn done handoffs
  live through that observation, and drains every pending generated child
  before nested repeat re-entry.
- Bind handoffs, domain metadata, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not
  yet shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.108`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=315), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained static-parameter generated do before post-do await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.106`.
- Top-level `when` bodies may now contain nested repeats with multiple
  generated spawns, static-parameter generated blocking
  `(do child (params ...))` while those generated spawns remain pending,
  `(await_any done)` as an observation point after that generated do, and a
  later same-body `(await_all done)` drain before the nested repeat check can
  loop.
- Lowering waits for the generated do instance's fresh done handoff before
  evaluating the post-do `await_any`, preserves static generated-top
  parameter binding, keeps generated-spawn done handoffs live through the
  observation, and drains every pending generated child before nested repeat
  re-entry.
- Bind handoffs, domain metadata, the switch-contained static-parameter
  analogue, spawn-after-do before the drain, cross-domain activation, deeper
  nesting, and broader outstanding-child semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.107`, which must
  select the next bounded subset before implementation.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=55), focused repeat/spawn/doc checks (Files=3, Tests=370), `mdbook build docs/book`,
  `./bin/ci-regression isf --no-book` (Files=227, Tests=1323), and
  `git diff --check`.

## 2026-05-18: R14 — ISF when-contained static-parameter generated do before post-do await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.105`.
- Selected top-level `when` body nested repeats with multiple generated
  spawns, static-parameter generated blocking `(do child (params ...))`
  while those generated spawns remain pending, `(await_any done)` as an
  observation point after that generated do, and a later same-body
  `(await_all done)` drain before the nested repeat check can loop.
- The selected implementation contract preserves the authored static
  parameter overrides, waits for the generated do instance's fresh done
  handoff before the post-do `await_any`, keeps generated-spawn done handoffs
  live through that observation, and drains every pending generated child
  before nested repeat re-entry.
- Bind handoffs, domain metadata, the switch-contained analogue,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not
  yet shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.106`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=310), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained generated-child do before post-do await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.104`.
- Top-level `switch` branches may now contain nested repeats with multiple
  generated spawns, plain generated-child blocking `(do child)` while those
  generated spawns remain pending, `(await_any done)` as an observation point
  after that generated-child do, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- Lowering waits for the generated do instance's fresh done handoff before
  evaluating the post-do `await_any`, keeps generated-spawn done handoffs
  live through that observation, preserves source-order samples around
  spawn/do/await_any/await_all, and drains every pending generated child
  before nested repeat re-entry.
- Static-parameter generated do, bind handoffs, domain metadata,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.105`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=54), focused repeat/spawn/doc checks (Files=3, Tests=364),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book`
  (Files=227, Tests=1317), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained generated-child do before post-do await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.103`.
- Selected top-level `switch` branch nested repeats with multiple generated
  spawns, plain generated-child blocking `(do child)` while those generated
  spawns remain pending, `(await_any done)` as an observation point after
  that generated-child do, and a later same-body `(await_all done)` drain
  before the nested repeat check can loop.
- The selected implementation contract mirrors the shipped when-contained
  generated-child-do-before-post-do-`await_any` proof: the generated do
  instance must produce a fresh done handoff before the observation, the
  post-do `await_any` keeps generated-spawn done handoffs live, and every
  pending generated child drains before nested repeat re-entry.
- Static-parameter generated do, bind handoffs, domain metadata,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not
  yet shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.104`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=305), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained generated-child do before post-do await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.102`.
- Top-level `when` bodies may now contain nested repeats with multiple
  generated spawns, plain generated-child blocking `(do child)` while those
  generated spawns remain pending, `(await_any done)` as an observation point
  after that generated-child do, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- Lowering waits for the generated do instance's fresh done handoff before
  evaluating the post-do `await_any`, keeps generated-spawn done handoffs
  live through that observation, preserves source-order samples around
  spawn/do/await_any/await_all, and drains every pending generated child
  before nested repeat re-entry.
- Static-parameter generated do, bind handoffs, domain metadata, the
  switch-contained generated-child analogue, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.103`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=53), focused repeat/spawn/doc checks (Files=3, Tests=358),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book`
  (Files=227, Tests=1311), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained generated-child do before post-do await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.101`.
- Selected top-level `when` body nested repeats with multiple generated
  spawns, plain generated-child blocking `(do child)` while those generated
  spawns remain pending, `(await_any done)` as an observation point after
  that generated-child do, and a later same-body `(await_all done)` drain
  before the nested repeat check can loop.
- The selected implementation contract waits for the generated do instance's
  fresh done handoff before the post-do `await_any`, keeps generated-spawn
  done handoffs live through that observation, and drains every pending
  generated child before nested repeat re-entry.
- Static-parameter generated do, bind handoffs, domain metadata, the
  switch-contained generated-child analogue, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not
  yet shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.102`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=300), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained local do before post-do await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.100`.
- Top-level `switch` branches may now contain nested repeats with multiple
  generated spawns, local blocking `(do child)` while those generated spawns
  remain pending, `(await_any done)` as an observation point after the local
  do, and a later same-body `(await_all done)` drain before the nested repeat
  check can loop.
- Lowering waits for the local child's fresh done pulse before evaluating the
  post-do `await_any`, keeps generated-spawn done handoffs live through that
  observation, preserves source-order samples around spawn/do/await_any/
  await_all, and drains every pending generated child before nested repeat
  re-entry.
- Generated-do post-do `await_any`, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.101`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, focused repeat/spawn/doc checks (Files=3,
  Tests=352), `mdbook build docs/book`,
  `./bin/ci-regression isf --no-book` (Files=227, Tests=1305), and
  `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained local do before post-do await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.99`.
- Selected top-level `switch` branch nested repeats with multiple generated
  spawns, local blocking `(do child)` while those generated spawns remain
  pending, `(await_any done)` as an observation point after the local do, and
  a later same-body `(await_all done)` drain before the nested repeat check
  can loop.
- The selected implementation contract mirrors the shipped when-contained
  local-do-before-post-do-`await_any` proof: the local child remains in the
  parent scheduled module, the post-do `await_any` observes only generated
  spawns without clearing them, and every pending generated child drains
  before nested repeat re-entry.
- Generated-do post-do `await_any`, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not
  yet shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.100`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=295), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained local do before post-do await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.98`.
- Top-level `when` bodies may now contain nested repeats with multiple
  generated spawns, local blocking `(do child)` while those generated spawns
  remain pending, `(await_any done)` as an observation point after the local
  do, and a later same-body `(await_all done)` drain before the nested repeat
  check can loop.
- Lowering waits for the local child's fresh done pulse before evaluating the
  post-do `await_any`, keeps generated-spawn done handoffs live through that
  observation, preserves source-order samples around spawn/do/await_any/
  await_all, and drains every pending generated child before nested repeat
  re-entry.
- Switch-contained post-do `await_any`, generated-do post-do `await_any`,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.99`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=51), doc audits (Files=2, Tests=295), focused activation/domain/doc
  suite (Files=13, Tests=528), `mdbook build docs/book`,
  `./bin/ci-regression isf --no-book` (Files=227, Tests=1299), and
  `git diff --check`.

## 2026-05-18: R14 — ISF when-contained local do before post-do await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.97`.
- Selected top-level `when` body nested repeats with multiple generated
  spawns, local blocking `(do child)` while those generated spawns remain
  pending, `(await_any done)` as an observation point after the local do, and
  a later same-body `(await_all done)` drain before the nested repeat check
  can loop.
- The selected implementation contract keeps the local child in the parent
  scheduled module, waits for the local child's fresh done pulse before the
  post-do `await_any`, keeps generated-spawn done handoffs live through that
  observation, and drains every pending generated child before nested repeat
  re-entry.
- Switch-contained post-do `await_any`, generated-do post-do `await_any`,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not
  yet shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.98`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=290), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat domain do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.96`.
- Top-level `switch` branches may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation,
  same-domain static-parameter generated
  `(do child (params ...) [(bind ...)] (domain NAME))` with optional
  generated-top input/output binding handoffs while those generated spawns
  remain pending, and a later same-body `(await_all done)` drain before the
  nested repeat check can loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the same-domain generated do instance, records declared ownership
  metadata in generated-composition/domain partition and schedule-report
  clock-domain summaries, waits for the generated do instance's fresh done
  handoff, and then drains every pending generated child before nested repeat
  re-entry.
- `await_any` after the do, spawn-after-do before the drain, cross-domain
  activation, deeper nesting, and broader outstanding-child semantics remain
  fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.97`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=50), touched repeat/spawn/doc checks (Files=4, Tests=480), focused
  activation/domain/doc suite (Files=13, Tests=522),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1293), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat domain do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.95`.
- Selected top-level `switch` branch nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, same-domain
  static-parameter generated `(do child (params ...) [(bind ...)] (domain NAME))`
  with optional generated-top input/output binding handoffs while those
  generated spawns remain pending, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- The selected implementation contract mirrors the shipped when-contained
  domain proof: generated-spawn done handoffs stay live after `await_any` and
  through the same-domain generated do instance, declared ownership metadata
  remains report-visible, and every pending generated child drains before
  nested repeat re-entry.
- `await_any` after the do, spawn-after-do before the drain, cross-domain
  activation, deeper nesting, and broader outstanding-child semantics remain
  deferred.
- The mdBook feature backlog now documents this subset as selected but not yet
  shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.96`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=286), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat domain do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.94`.
- Top-level `when` bodies may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation,
  same-domain static-parameter generated
  `(do child (params ...) [(bind ...)] (domain NAME))` with optional
  generated-top input/output binding handoffs while those generated spawns
  remain pending, and a later same-body `(await_all done)` drain before the
  nested repeat check can loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the same-domain generated do instance, records declared ownership
  metadata in generated-composition/domain partition and schedule-report
  clock-domain summaries, waits for the generated do instance's fresh done
  handoff, and then drains every pending generated child before nested repeat
  re-entry.
- The switch-contained domain analogue, `await_any` after the do,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.95`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=49), touched repeat/spawn/doc checks (Files=4, Tests=475), focused
  activation/domain/doc suite (Files=13, Tests=517),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1288), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat domain do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.93`.
- Selected top-level `when` body nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, same-domain
  static-parameter generated `(do child (params ...) [(bind ...)] (domain NAME))`
  with optional generated-top input/output binding handoffs while those
  generated spawns remain pending, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- The selected implementation contract keeps generated-spawn done handoffs
  live after `await_any` and through the same-domain generated do instance,
  records declared ownership metadata in generated-composition and
  schedule-report clock-domain summaries, and then drains every pending
  generated child before nested repeat re-entry.
- The switch-contained domain analogue, `await_any` after the do,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not yet
  shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.94`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=282), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat bound do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.92`.
- Top-level `switch` branches may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation,
  static-parameter generated `(do child (params ...) (bind ...))` with
  generated-top input/output binding handoffs while those generated spawns
  remain pending, and a later same-body `(await_all done)` drain before the
  nested repeat check can loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the bound generated do instance, applies that instance's static
  parameter overrides and binding handoffs once in the generated top, waits
  for its own fresh done handoff, and then drains every pending generated
  child before nested repeat re-entry.
- Domain metadata after prior `await_any`, `await_any` after the do,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.93`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=48), touched repeat/spawn/doc checks (Files=4, Tests=470), focused
  activation/domain/doc suite (Files=13, Tests=512),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1283), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat bound do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.91`.
- Selected top-level `switch` branch nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, static-parameter
  generated `(do child (params ...) (bind ...))` with generated-top
  input/output binding handoffs while those generated spawns remain pending,
  and a later same-body `(await_all done)` drain before the nested repeat
  check can loop.
- The selected implementation contract keeps generated-spawn done handoffs
  live after `await_any` and through the bound generated do instance, applies
  the generated do instance's static parameter overrides and binding handoffs
  once in the generated top, and then drains every pending generated child
  before nested repeat re-entry.
- Domain metadata after prior `await_any`, `await_any` after the do,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not yet
  shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.92`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=277), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat bound do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.90`.
- Top-level `when` bodies may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation,
  static-parameter generated `(do child (params ...) (bind ...))` with
  generated-top input/output binding handoffs while those generated spawns
  remain pending, and a later same-body `(await_all done)` drain before the
  nested repeat check can loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the bound generated do instance, applies that instance's static
  parameter overrides and binding handoffs once in the generated top, waits
  for its own fresh done handoff, and then drains every pending generated
  child before nested repeat re-entry.
- Domain metadata after prior `await_any`, the switch-contained bound
  analogue after prior `await_any`, `await_any` after the do, spawn-after-do
  before the drain, cross-domain activation, deeper nesting, and broader
  outstanding-child semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.91`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=47), touched repeat/spawn/doc checks (Files=4, Tests=464), focused
  activation/domain/doc suite (Files=13, Tests=506),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1277), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat bound do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.89`.
- Selected top-level `when` body nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, static-parameter
  generated `(do child (params ...) (bind ...))` with generated-top
  input/output binding handoffs while those generated spawns remain pending,
  and a later same-body `(await_all done)` drain before the nested repeat
  check can loop.
- The selected implementation contract keeps generated-spawn done handoffs
  live after `await_any` and through the generated do instance, applies the
  generated do instance's static parameter overrides and binding handoffs once
  in the generated top, and then drains every pending generated child before
  nested repeat re-entry.
- Domain metadata, the switch-contained bound analogue, `await_any` after the
  do, spawn-after-do before the drain, cross-domain activation, deeper
  nesting, and broader outstanding-child semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not yet
  shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.90`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=272), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat parameterized do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.88`.
- Top-level `switch` branches may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation,
  static-parameter generated `(do child (params ...))` while those generated
  spawns remain pending, and a later same-body `(await_all done)` drain before
  the nested repeat check can loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the generated do instance, applies the generated do instance's
  static parameter overrides once in the generated top, waits for that
  instance's own fresh done handoff, and then drains every pending generated
  child before nested repeat re-entry.
- Bind handoffs, domain metadata, `await_any` after the do, spawn-after-do
  before the drain, cross-domain activation, deeper nesting, and broader
  outstanding-child semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.89`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=46), touched repeat/spawn/doc checks (Files=4, Tests=458), focused
  activation/domain/doc suite (Files=13, Tests=500),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1271), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat parameterized do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.87`.
- Selected top-level `switch` branch nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, static-parameter
  generated `(do child (params ...))` while those generated spawns remain
  pending, and a later same-body `(await_all done)` drain before the nested
  repeat check can loop.
- The selected implementation contract keeps generated-spawn done handoffs
  live after `await_any` and through the generated do instance, applies the
  generated do instance's static parameter overrides once in the generated
  top, and then drains every pending generated child before nested repeat
  re-entry.
- Bind handoffs, domain metadata, `await_any` after the do, spawn-after-do
  before the drain, cross-domain activation, deeper nesting, and broader
  outstanding-child semantics remain deferred.
- The mdBook feature backlog now documents this subset as selected but not yet
  shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.88`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=267), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat parameterized do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.86`.
- Top-level `when` bodies may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation,
  static-parameter generated `(do child (params ...))` while those generated
  spawns remain pending, and a later same-body `(await_all done)` drain before
  the nested repeat check can loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the generated do instance, applies the generated do instance's
  static parameter overrides once in the generated top, waits for that
  instance's own fresh done handoff, and then drains every pending generated
  child before nested repeat re-entry.
- Bind handoffs, domain metadata, the switch-contained static-parameter
  analogue, `await_any` after the do, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.87`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=45), touched repeat/spawn/doc checks (Files=4, Tests=452), focused
  activation/domain/doc suite (Files=13, Tests=494),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1265), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat parameterized do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.85`.
- Selected top-level `when` body nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, static-parameter
  generated `(do child (params ...))` while those generated spawns remain
  pending, and a later same-body `(await_all done)` drain before the nested
  repeat check can loop.
- The selected implementation contract keeps generated-spawn done handoffs
  live after `await_any` and through the generated do instance, applies the
  generated do instance's static parameter overrides once in the generated
  top, and then drains every pending generated child before nested repeat
  re-entry.
- Bind handoffs, domain metadata, the switch-contained analogue,
  `await_any` after the do, spawn-after-do before the drain, cross-domain
  activation, deeper nesting, and broader outstanding-child semantics remain
  deferred.
- The mdBook feature backlog now documents this subset as selected but not yet
  shipped. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.86`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=262), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat generated-child do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.84`.
- Top-level `switch` branches may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation, plain
  generated-child `(do child)` while those generated spawns remain pending,
  and a later same-body `(await_all done)` drain before the nested repeat
  check can loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the generated do instance, waits for the generated do instance's
  own fresh done handoff, and then drains every pending generated child before
  nested repeat re-entry.
- Parameterized, bound, or domain-qualified generated `do` after prior
  `await_any`, `await_any` after the do, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain fail-closed.
- Docs are synchronized across the mdBook, ISF spec, downstream integration
  spec, public contract, task tree, roadmap board, and live docs. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.85`, which must
  select the next bounded repeat-body child activation subset.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=44), touched repeat/spawn/doc checks (Files=4, Tests=446), focused
  activation/domain/doc suite (Files=13, Tests=488),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1259), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat generated-child do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.83`.
- Selected top-level `switch` branch nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, plain generated-
  child `(do child)` while those generated spawns remain pending, and a later
  same-body `(await_all done)` drain before the nested repeat check can loop.
- The selected implementation contract keeps generated-spawn done handoffs
  live after `await_any` and through the generated do instance. The generated
  do target must already be emitted as a generated child by another activation
  site and must wait for its own fresh done handoff.
- Static params, bind handoffs, domain metadata, `await_any` after the do,
  spawn-after-do before the drain, cross-domain activation, deeper nesting,
  and broader outstanding-child semantics remain deferred. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.84`, which implements this
  selected subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=257), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat generated-child do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.82`.
- Top-level `when` bodies may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation, plain
  generated-child blocking `(do child)` while those generated spawns remain
  pending, and a later same-body `(await_all done)` drain before the nested
  repeat check can loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the generated do instance, waits for that instance's fresh done
  handoff, and then drains every pending generated child before nested repeat
  re-entry.
- Parameterized, bound, or domain-qualified generated `do` after prior
  `await_any`, the switch-contained generated-child analogue, `await_any`
  after the do, spawn-after-do before the drain, cross-domain activation,
  deeper nesting, and broader outstanding-child semantics remain fail-closed.
  The active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.83`,
  which must select the next bounded repeat-body child activation subset
  before code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=43), touched repeat/spawn/doc checks (Files=4, Tests=440), focused
  activation/domain/doc suite (Files=13, Tests=482),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1253), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat generated-child do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.81`.
- Selected top-level `when` body nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, plain generated-
  child `(do child)` while those generated spawns remain pending, and a later
  same-body `(await_all done)` drain before the nested repeat check can loop.
- The selected implementation contract keeps generated-spawn done handoffs
  live after `await_any` and through the generated do instance. The generated
  do target must already be emitted as a generated child by another activation
  site and must wait for its own fresh done handoff.
- Static params, bind handoffs, domain metadata, the switch-contained
  analogue, `await_any` after the do, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.82`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=252), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat local do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.80`.
- Top-level `switch` branches may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation, local
  blocking `(do child)` while those generated spawns remain pending, and a
  later same-body `(await_all done)` drain before the nested repeat check can
  loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the local do, waits for the local child's fresh done pulse, and then
  drains every pending generated child before nested repeat re-entry.
- Generated do after prior multi-pending `await_any`, `await_any` after the
  do, spawn-after-do before the drain, cross-domain activation, deeper
  nesting, and broader outstanding-child semantics remain fail-closed. The
  active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.81`, which
  must select the next bounded repeat-body child activation subset before
  code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=42), touched repeat/spawn/doc checks (Files=4, Tests=434), focused
  activation/domain/doc suite (Files=13, Tests=476),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1247), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat local do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.79`.
- Selected top-level `switch` branch nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, local blocking
  `(do child)` while those generated spawns remain pending, and a later
  same-body `(await_all done)` drain before the nested repeat check can loop.
- The selected implementation contract mirrors the shipped when-contained
  proof: generated-spawn done handoffs stay live after `await_any` and
  through the local do. The local do target remains in the parent scheduled
  module and must wait for its own fresh done pulse.
- Generated do after prior multi-pending `await_any`, `await_any` after the
  do, spawn-after-do before the drain, cross-domain activation, deeper
  nesting, and broader outstanding-child semantics remain deferred. The
  active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.80`, which
  implements this selected subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=247), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat local do after await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.78`.
- Top-level `when` bodies may now contain nested repeats with multiple
  generated spawns, a multi-pending `(await_any done)` observation, local
  blocking `(do child)` while those generated spawns remain pending, and a
  later same-body `(await_all done)` drain before the nested repeat check can
  loop.
- Lowering keeps generated-spawn done handoffs live after `await_any` and
  through the local do, waits for the local child's fresh done pulse, and then
  drains every pending generated child before nested repeat re-entry.
- Generated `do` after prior multi-pending `await_any`, the switch-contained
  local-do analogue after prior multi-pending `await_any`, `await_any` after
  the do, spawn-after-do before the drain, cross-domain activation, deeper
  nesting, and broader outstanding-child semantics remain fail-closed. The
  active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.79`, which
  must select the next bounded repeat-body child activation subset before
  code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=41), touched repeat/spawn/doc checks (Files=4, Tests=428), focused
  activation/domain/doc suite (Files=13, Tests=470),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1241), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat local do after await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.77`.
- Selected top-level `when` body nested repeats with multiple generated
  spawns, a multi-pending `(await_any done)` observation, local blocking
  `(do child)` while those generated spawns remain pending, and a later
  same-body `(await_all done)` drain before the nested repeat check can loop.
- The selected implementation contract keeps generated-spawn done handoffs
  live after `await_any` and through the local do. The local do target remains
  in the parent scheduled module and must wait for its own fresh done pulse.
- Generated do after prior multi-pending `await_any`, the switch-contained
  analogue, `await_any` after the do, spawn-after-do before the drain,
  cross-domain activation, deeper nesting, and broader outstanding-child
  semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.78`, which implements this selected
  subset.
- Validation passed: `mdbook build docs/book`,
  `prove -l t/1305-isf-book-feature-matrix-audit.t t/1307-isf-loop-body-doc-truth-audit.t`
  (Files=2, Tests=242), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat domain do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.76`.
- Top-level `switch` branches may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, followed by generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))` with static parameter
  overrides, optional input/output port bindings, and declared same-domain
  metadata while those generated spawns remain pending, and a later same-body
  `(await_all done)` drain before the nested repeat check can loop.
- The generated do site owns one deterministic generated instance, preserves
  static generated-top parameter binding, optional generated-top binding
  handoffs, generated-composition domain metadata, and schedule-report
  clock-domain child-instance metadata, waits for its own fresh done handoff,
  and leaves generated-spawn done handoffs live for the later drain.
- The domain annotation remains ownership metadata only. `await_any` around
  the do, new nested spawn after the do before the drain, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics remain fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.77`, which must select the next bounded
  repeat-body child activation subset before code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=40), touched repeat/spawn/doc checks (Files=4, Tests=422), focused
  activation/domain/doc suite (Files=13, Tests=464),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1235), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat domain do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.75`.
- Selected top-level `switch` branches containing nested repeats with one or
  more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites,
  followed by generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))` with static parameter
  overrides, optional input/output port bindings, and declared same-domain
  ownership metadata while those generated spawns remain pending, and a later
  same-body `(await_all done)` drain before the nested repeat check can loop.
- The selected contract mirrors the shipped when-contained same-domain
  pending-spawn generated do proof: the generated do instance preserves
  static generated-top parameter binding, optional generated-top binding
  handoffs, generated-composition and clock-domain report ownership metadata,
  and the pending generated-spawn done set until the later drain.
- The domain annotation remains metadata only. `await_any` around the do, new
  spawn after the do before drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.76`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat domain do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.74`.
- Top-level `when` bodies may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, followed by generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))` with static parameter
  overrides, optional input/output port bindings, and declared same-domain
  metadata while those generated spawns remain pending, and a later same-body
  `(await_all done)` drain before the nested repeat check can loop.
- The generated do site owns one deterministic generated instance, preserves
  static generated-top parameter binding, optional generated-top binding
  handoffs, generated-composition domain metadata, and schedule-report
  clock-domain child-instance metadata, waits for its own fresh done handoff,
  and leaves generated-spawn done handoffs live for the later drain.
- The domain annotation remains ownership metadata only. The switch-contained
  domain analogue, `await_any` around the do, new nested spawn after the do
  before the drain, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics remain fail-closed. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.75`, which must select the
  next bounded repeat-body child activation subset before code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=39), touched repeat/spawn/doc checks (Files=4, Tests=416), focused
  activation/domain/doc suite (Files=13, Tests=458),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1229), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat domain do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.73`.
- Selected top-level `when` bodies containing nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, followed by generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))` with static parameter
  overrides, optional input/output port bindings, and declared same-domain
  ownership metadata while those generated spawns remain pending, and a later
  same-body `(await_all done)` drain before the nested repeat check can loop.
- The selected contract preserves static generated-top parameter binding,
  optional generated-top binding handoffs, generated-composition and
  clock-domain report ownership metadata on the deterministic generated do
  instance, and the pending generated-spawn done set until the later drain.
- The switch-contained domain analogue, `await_any` around the do, new spawn
  after the do before drain, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain deferred. The
  active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.74`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat bound do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.72`.
- Top-level `switch` branches may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, followed by generated blocking `(do child (params ...) (bind ...))`
  with static parameter overrides and input/output port bindings while those
  generated spawns remain pending, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- The generated do site owns one deterministic generated instance, preserves
  static generated-top parameter binding, wires generated-top input/output
  binding handoffs once for that lexical do site, waits for that instance's
  fresh done handoff, leaves generated-spawn done handoffs live for the later
  drain, and preserves source-order samples around spawn/do/sync.
- Domain metadata on that do, `await_any` around the do, new nested spawn
  after the do before the drain, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain fail-closed. The
  active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.73`, which
  must select the next bounded repeat-body child activation subset before
  code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=38), touched repeat/spawn/doc checks (Files=4, Tests=410), focused
  activation/domain/doc suite (Files=13, Tests=452),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1223), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat bound do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.71`.
- Selected top-level `switch` branches containing nested repeats with one or
  more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites,
  followed by generated blocking `(do child (params ...) (bind ...))` with
  static parameter overrides and input/output port bindings while those
  generated spawns remain pending, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- The selected contract mirrors the shipped when-contained bound generated do
  while spawn pending proof: the generated do instance preserves static
  generated-top parameter binding, wires generated-top input/output binding
  handoffs, waits for its own fresh done handoff, and the later drain still
  gates nested repeat re-entry.
- Domain metadata on that do, `await_any` around the do, new spawn after the
  do before drain, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics remain deferred. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.72`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat bound do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.70`.
- Top-level `when` bodies may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, followed by generated blocking `(do child (params ...) (bind ...))`
  with static parameter overrides and input/output port bindings while those
  generated spawns remain pending, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- The generated do site owns one deterministic generated instance, preserves
  static generated-top parameter binding, wires generated-top input/output
  binding handoffs once for that lexical do site, waits for that instance's
  fresh done handoff, leaves generated-spawn done handoffs live for the later
  drain, and preserves source-order samples around spawn/do/sync.
- Domain metadata on that do, the switch-contained bound analogue,
  `await_any` around the do, new nested spawn after the do before the drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.71`, which must select the
  next bounded repeat-body child activation subset before code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=37), touched repeat/spawn/doc checks (Files=4, Tests=404), focused
  activation/domain/doc suite (Files=13, Tests=446),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1217), and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat bound do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.69`.
- Selected top-level `when` bodies containing nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, followed by generated blocking `(do child (params ...) (bind ...))`
  with static parameter overrides and input/output port bindings while those
  generated spawns remain pending, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- The selected contract must preserve static generated-top parameter binding
  and generated-top binding handoffs on the generated do instance while the
  later drain still gates nested repeat re-entry on every outstanding
  generated child.
- Domain metadata on that do, the switch-contained bound analogue,
  `await_any` around the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.70`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat parameterized do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.68`.
- Top-level `switch` branches may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, static-parameter generated `(do child (params ...))` while those
  generated spawns remain pending, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- The generated do site owns one deterministic generated instance, preserves
  static generated-top parameter binding, waits for that instance's fresh done
  handoff, leaves generated-spawn done handoffs live for the later drain, and
  preserves source-order samples around spawn/do/sync.
- Bind/domain subclauses on that do, `await_any` around the do, new nested
  spawn after the do before the drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.69`, which must select the next bounded
  repeat-body child activation subset before code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=36), touched repeat/spawn/doc checks (Files=4, Tests=398), focused
  activation/domain/doc suite (Files=13, Tests=440),
  `mdbook build docs/book`, `./bin/ci-regression isf --no-book` (Files=227,
  Tests=1211), and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat parameterized do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.67`.
- Selected top-level `switch` branches containing nested repeats with one or
  more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites,
  followed by generated blocking `(do child (params ...))` with static
  parameter overrides while those generated spawns remain pending, and a later
  same-body `(await_all done)` drain before the nested repeat check can loop.
- The selected contract mirrors the shipped when-contained static-parameter
  generated do while spawn pending proof: the generated do instance preserves
  static generated-top parameter binding, waits for its own fresh done
  handoff, and the later drain still gates nested repeat re-entry.
- Bind/domain subclauses on that do, `await_any` around the do, new spawn
  after the do before drain, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain deferred. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.68`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat parameterized do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.66`.
- Top-level `when` bodies may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, static-parameter generated `(do child (params ...))` while those
  generated spawns remain pending, and a later same-body `(await_all done)`
  drain before the nested repeat check can loop.
- The generated do site owns one deterministic generated instance, preserves
  static generated-top parameter binding, waits for that instance's fresh done
  handoff, leaves generated-spawn done handoffs live for the later drain, and
  preserves source-order samples around spawn/do/sync.
- Bind/domain subclauses on that do, the switch-contained analogue,
  `await_any` around the do, new nested spawn after the do before the drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed. The active frontier advances
  to `ISF-REPEAT-BODY-CHILD-ACTIVATION.67`, which must select the next
  bounded repeat-body child activation subset before code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=35), touched repeat/spawn/doc checks (Files=4, Tests=392), focused
  activation/domain/doc suite (Files=13, Tests=434), `mdbook build docs/book`,
  `./bin/ci-regression isf --no-book` (Files=227, Tests=1205), and
  `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat parameterized do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.65`.
- Selected top-level `when` bodies containing nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, followed by generated blocking `(do child (params ...))` with static
  parameter overrides while those generated spawns remain pending, and a later
  same-body `(await_all done)` drain before the nested repeat check can loop.
- The selected contract extends the shipped generated-child do while spawn
  pending proof with static generated-top parameter binding on the
  deterministic generated do instance, while generated-spawn done handoffs
  remain live until the later drain.
- Bind/domain subclauses on that do, the switch-contained analogue,
  `await_any` around the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.66`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat generated do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.64`.
- Top-level `switch` branches may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, generated-child plain `(do child)` while those generated spawns
  remain pending, and a later same-body `(await_all done)` drain before the
  nested repeat check can loop.
- The generated do site owns one deterministic generated instance, waits for
  that instance's fresh done handoff, leaves generated-spawn done handoffs
  live for the later drain, and preserves source-order samples around
  spawn/do/sync.
- Parameterized, bound, or domain-qualified generated do while pending,
  `await_any` around the do, new nested spawn after the do before the drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed. The active frontier advances
  to `ISF-REPEAT-BODY-CHILD-ACTIVATION.65`, which must select the next
  bounded repeat-body child activation subset before code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=34), touched repeat/spawn/doc checks (Files=4, Tests=386), focused
  activation/domain/doc suite (Files=13, Tests=428), `mdbook build docs/book`,
  `./bin/ci-regression isf --no-book` (Files=227, Tests=1199), and
  `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat generated do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.63`.
- Selected top-level `switch` branches containing nested repeats with one or
  more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites,
  followed by generated-child plain `(do child)` while those generated spawns
  remain pending, and a later same-body `(await_all done)` drain before the
  nested repeat check can loop.
- The selected contract mirrors the shipped when-contained generated-child do
  while spawn pending proof: the generated do target is already emitted
  elsewhere, the generated do instance waits for its own fresh done handoff,
  and the later drain still gates nested repeat re-entry.
- Static params, bind/domain subclauses on that do, `await_any` around the do,
  new spawn after the do before drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.64`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat generated do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.62`.
- Top-level `when` bodies may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, generated-child plain `(do child)` while those generated spawns
  remain pending, and a later same-body `(await_all done)` drain before the
  nested repeat check can loop.
- The generated do site owns one deterministic generated instance, waits for
  that instance's fresh done handoff, leaves generated-spawn done handoffs
  live for the later drain, and preserves source-order samples around
  spawn/do/sync.
- Parameterized, bound, or domain-qualified generated do while pending, the
  switch-contained generated-child analogue, `await_any` around the do, new
  nested spawn after the do before the drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.63`, which must select the next bounded
  repeat-body child activation subset before code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=33), touched repeat/spawn/doc checks (Files=4, Tests=380), focused
  activation/domain/doc suite (Files=13, Tests=422), `mdbook build docs/book`,
  `./bin/ci-regression isf --no-book` (Files=227, Tests=1193), and
  `git diff --check`.

## 2026-05-18: R14 — ISF when-contained repeat generated do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.61`.
- Selected top-level `when` body nested repeats with one or more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites,
  generated-child plain `(do child)` while those generated spawns remain
  pending, and a later same-body `(await_all done)` drain before the nested
  repeat check can loop.
- The selected do target must already be emitted as a generated child by
  another activation site. The generated do instance should wait for its own
  fresh done handoff without clearing generated-spawn done handoffs, and the
  later drain must still gate nested repeat re-entry.
- Static params, bind/domain subclauses on that do, switch-contained analogue,
  `await_any` around the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.62`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.60`.
- Top-level `switch` branches may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, local plain `(do child)` while those generated spawns remain pending,
  and a later same-body `(await_all done)` drain before the switch-branch
  nested repeat check can loop.
- The local do stays in the parent scheduled module, waits for the local
  child's fresh done pulse, and leaves generated-spawn done handoffs live for
  the later drain. Source-order samples around spawn/do/sync remain explicit.
- Generated `do` while spawn pending, `await_any` before or after the local
  do, new nested spawn after the local do before drain, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics remain fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.61`, which must select the next bounded
  repeat-body child activation subset before code.
- Validation passed: syntax checks, touched repeat/spawn test (Files=1,
  Tests=32), touched repeat/spawn/doc checks (Files=4, Tests=374), focused
  activation/domain/doc suite (Files=13, Tests=416), `mdbook build docs/book`,
  `./bin/ci-regression isf --no-book` (Files=227, Tests=1187), and
  `git diff --check`.

## 2026-05-18: R14 — ISF switch-contained repeat do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.59`.
- Selected top-level `switch` branches containing nested repeats with one or
  more generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` sites,
  followed by local `(do child)` while those generated spawns remain pending,
  and a later same-body `(await_all done)` drain before the nested repeat
  check can loop.
- The selected contract keeps the local do in the parent scheduled module,
  preserves every pending generated-spawn done handoff across that local do,
  and requires the later drain to gate nested repeat re-entry.
- Generated `do` while spawn pending, `await_any` before or after the local
  do, new spawn after the local do before drain, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.60`.
- Validation passed: `mdbook build docs/book` and `git diff --check`.

## 2026-05-18: Project operations — GitHub CI and Pages re-enabled
- Completed `GITHUB-PUBLIC-AUTOMATION-REENABLE.1`.
- The hosted regression workflow is active again at
  [.github/workflows/regression.yml](.github/workflows/regression.yml) and
  uses the shared `./bin/ci-regression` gate for `main` pushes, pull requests
  targeting `main`, and manual runs.
- GitHub Pages publishing is now repo-owned at
  [.github/workflows/pages.yml](.github/workflows/pages.yml): it builds
  [docs/book](docs/book) and publishes `docs/book/book` when repository Pages
  settings use GitHub Actions.
- README, mdBook regression guidance, live docs, and the task tree are
  synchronized with the active hosted automation state.
- Validation passed: `bash -n bin/ci-regression`, workflow YAML load through
  Ruby, `mdbook build docs/book`, `./bin/ci-regression quick --no-book`
  (Files=8, Tests=145), and `git diff --check`.
- Active R14 compiler frontier remains
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.59`.

## 2026-05-17: R14 — ISF when-contained repeat do while spawn pending shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.58`.
- Top-level `when` bodies may now contain nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, local plain `(do child)` while those generated spawns remain pending,
  and a later same-body `(await_all done)` drain before the nested repeat
  check can loop.
- The local do stays in the parent scheduled module, waits for the local
  child's fresh done pulse, and leaves generated-spawn done handoffs live for
  the later drain. Source-order samples around spawn/do/sync remain explicit.
- Generated `do` while spawn pending, the switch-contained analogue,
  `await_any` before or after the local do, new spawn after the local do before
  drain, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed. The active frontier advances
  to `ISF-REPEAT-BODY-CHILD-ACTIVATION.59`, which must select the next
  bounded repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF when-contained repeat do while spawn pending selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.57`.
- Selected top-level `when` bodies containing nested repeats with one or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, followed by local `(do child)` while those generated spawns remain
  pending, and a later same-body `(await_all done)` drain before the nested
  repeat check can loop.
- The selected surface keeps the do target local to the parent scheduled
  module and keeps the generated spawn done set live until the later drain.
- Generated `do` while spawn pending, the switch-contained analogue,
  `await_any` observation before the do, new spawn after the do before drain,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances
  to `ISF-REPEAT-BODY-CHILD-ACTIVATION.58`.

## 2026-05-17: R14 — ISF switch-contained repeat await_any drain shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.56`.
- Top-level `switch` branches may now contain nested repeats with two or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, a multi-pending `(await_any done)` observation point, and a mandatory
  later same-body `(await_all done)` drain before the nested repeat check can
  loop.
- Lowering keeps the outstanding generated child done set live after the
  `await_any` observation point, preserves source-order samples before the
  drain, and rejects new nested `spawn` or `do` clauses before the drain.
- The mdBook, ISF spec, downstream integration spec, public contract, and doc
  audits now state the same branch-contained rule for top-level `when` bodies
  and top-level `switch` branches.
- `do` while a nested spawn is pending, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.57`, which must select the next bounded
  repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF switch-contained repeat await_any drain selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.55`.
- Selected top-level `switch` branches containing nested repeats with two or
  more generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, a multi-pending `(await_any done)` observation point, and a mandatory
  later same-body `(await_all done)` drain before the nested repeat check can
  loop.
- The selected surface mirrors the shipped when-contained multi-pending
  `await_any` drain proof and keeps source-order samples before sync points
  explicit.
- New nested `spawn` or `do` clauses before the mandatory drain, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.56`.

## 2026-05-17: R14 — ISF when-contained repeat await_any drain shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.54`.
- Top-level `when` bodies may now contain nested repeats with two or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, a multi-pending `(await_any done)` observation point, and a mandatory
  later same-body `(await_all done)` drain before the nested repeat check can
  loop.
- Lowering keeps the outstanding generated child done set live after the
  `await_any` observation point, preserves source-order samples before the
  drain, and rejects new nested `spawn` or `do` clauses before the drain.
- Switch-contained multi-pending `await_any`, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.55`, which must select the next bounded
  repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF when-contained repeat await_any drain selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.53`.
- Selected top-level `when` bodies containing nested repeats with two or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites, a multi-pending `(await_any done)` observation point, and a mandatory
  later same-body `(await_all done)` drain before the nested repeat check can
  loop.
- The selected surface mirrors the shipped top-level repeat-body
  multi-pending `await_any` drain proof and keeps source-order samples before
  sync points explicit.
- Switch-contained multi-pending `await_any`, new nested `spawn` or `do`
  clauses before the mandatory drain, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.54`.

## 2026-05-17: R14 — ISF switch-contained repeat multiple spawns shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.52`.
- Top-level `switch` branches may now contain nested repeats with two or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites when the same nested repeat body reaches `(await_all done)` before the
  nested repeat check can loop.
- Lowering preserves generated-top parameter overrides, input/output binding
  handoffs, same-domain metadata, source-order samples before nested spawn or
  sync states, schedule-report binding provenance, and clock-domain
  child-instance metadata for each lexical nested spawn.
- Nested `await_any` for multiple pending children, `do` while a nested spawn
  is pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed. The active frontier advances
  to `ISF-REPEAT-BODY-CHILD-ACTIVATION.53`, which must select the next bounded
  repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF switch-contained repeat multiple spawns selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.51`.
- Selected top-level `switch` branches containing nested repeats with two or
  more generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites that must drain through same-body `(await_all done)` before the nested
  repeat check can loop.
- The selected surface mirrors the shipped when-contained multiple-spawn leaf,
  reuses the static generated-child handoff model, and preserves source-order
  samples before nested spawn or sync states.
- Nested `await_any` for multiple pending children, `do` while a nested spawn
  is pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.52`.

## 2026-05-17: R14 — ISF when-contained repeat multiple spawns shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.50`.
- Top-level `when` bodies may now contain nested repeats with two or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites when the same nested repeat body reaches `(await_all done)` before the
  nested repeat check can loop.
- Lowering preserves generated-top parameter overrides, input/output binding
  handoffs, same-domain metadata, source-order samples before nested spawn or
  sync states, schedule-report binding provenance, and clock-domain
  child-instance metadata for each lexical nested spawn.
- Nested `await_any` for multiple pending children, switch-contained multiple
  nested spawns, `do` while a nested spawn is pending, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics remain fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.51`, which must select the next bounded
  repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF when-contained repeat multiple spawns selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.49`.
- Selected top-level `when` bodies containing nested repeats with two or more
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  sites that must drain through same-body `(await_all done)` before the nested
  repeat check can loop.
- The selected surface reuses the static generated-child handoff model and
  source-order samples before nested spawn or sync states.
- Nested `await_any` for multiple pending children, switch-contained multiple
  nested spawns, `do` while a nested spawn is pending, cross-domain
  activation, deeper branch/loop nesting, and broader outstanding-child
  semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.50`.

## 2026-05-17: R14 — ISF switch-contained repeat spawn await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.48`.
- Top-level `switch` branches may now contain nested repeats with exactly one
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  when the same nested repeat body reaches single-pending `(await_any done)`.
- Lowering preserves the static generated-child handoff model, generated-top
  parameter overrides, input/output binding handoffs, same-domain metadata,
  source-order samples before nested spawn or sync states, and schedule-report
  binding/domain metadata.
- Multiple pending nested spawns, `do` while a nested spawn is pending,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain fail-closed. The active frontier advances
  to `ISF-REPEAT-BODY-CHILD-ACTIVATION.49`, which must select the next bounded
  repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF switch-contained repeat spawn await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.47`.
- Selected top-level `switch` branches containing nested repeats with exactly
  one generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  that may drain through same-body single-pending `(await_any done)`.
- The selected proof mirrors the shipped when-contained single-pending
  `await_any` leaf: one pending nested static child means `await_any` gates the
  nested repeat check on the same done handoff as `await_all`.
- Multiple pending nested spawns, `do` while a nested spawn is pending,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.48`.

## 2026-05-17: R14 — ISF when-contained repeat spawn await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.46`.
- Top-level `when` bodies may now contain nested repeats with exactly one
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  when the same nested repeat body reaches single-pending `(await_any done)`.
- Lowering preserves the static generated-child handoff model, generated-top
  parameter overrides, input/output binding handoffs, same-domain metadata,
  source-order samples before nested spawn or sync states, and schedule-report
  binding/domain metadata.
- Multiple pending nested spawns, switch-contained `await_any`, `do` while a
  nested spawn is pending, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain deferred. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.47`, which must
  select the next bounded repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF when-contained repeat spawn await_any selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.45`.
- Selected top-level `when` bodies containing nested repeats with exactly one
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  that may drain through same-body single-pending `(await_any done)`.
- The selected proof mirrors the shipped top-level repeat-body
  single-pending `await_any` subset: one pending nested static child means
  `await_any` gates the nested repeat check on the same done handoff as
  `await_all`.
- Multiple pending nested spawns, switch-contained `await_any`, `do` while a
  nested spawn is pending, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain deferred. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.46`.

## 2026-05-17: R14 — ISF switch-contained repeat spawn await_all shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.44`.
- Top-level `switch` branches may now contain nested repeats with exactly one
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  when the same nested repeat body reaches same-body `(await_all done)` before
  the nested repeat check can loop.
- Lowering emits one static generated child instance for the lexical nested
  spawn, preserves generated-top parameter overrides, input/output binding
  handoffs, and same-domain metadata, and keeps source-order samples before
  nested spawn or sync states explicit.
- `await_any`, multiple pending nested spawns, `do` while a nested spawn is
  pending, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances
  to `ISF-REPEAT-BODY-CHILD-ACTIVATION.45`, which must select the next
  bounded repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF switch-contained repeat spawn await_all selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.43`.
- Selected top-level `switch` branches containing nested repeats with exactly
  one generated
  `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])` that
  reaches same-body `(await_all done)` before the nested repeat check can
  loop.
- The selected contract mirrors the shipped when-contained single-spawn leaf,
  reuses the static generated-child handoff model, preserves source-order
  samples before nested spawn or sync states, and keeps `await_any`, multiple
  pending nested spawns, `do` while a nested spawn is pending,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics deferred.
- The active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.44`.

## 2026-05-17: R14 — ISF when-contained repeat spawn await_all shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.42`.
- Top-level `when` bodies may now contain nested repeats with exactly one
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  when the same nested repeat body reaches same-body `(await_all done)` before
  the nested repeat check can loop.
- Lowering emits one static generated child instance for the lexical nested
  spawn, preserves generated-top parameter overrides, input/output binding
  handoffs, and same-domain metadata, and keeps source-order samples before
  nested spawn or sync states explicit.
- `await_any`, multiple pending nested spawns, switch-contained spawn nesting,
  `do` while a nested spawn is pending, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.43`, which must select the next bounded
  repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF when-contained repeat spawn await_all selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.41`.
- Selected top-level `when` bodies containing nested repeats with exactly one
  generated `(spawn child as inst [(params ...)] [(bind ...)] [(domain NAME)])`
  that reaches same-body `(await_all done)` before the nested repeat check can
  loop.
- The selected contract reuses the static generated-child handoff model,
  preserves source-order samples before nested spawn or sync states, and keeps
  `await_any`, multiple pending nested spawns, switch-contained spawn nesting,
  `do` while a nested spawn is pending, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics deferred.
- The active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.42`.

## 2026-05-17: R14 — ISF switch-contained repeat generated do domains shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.40`.
- Top-level `switch` branches may now contain nested repeats with generated
  blocking `(do child (params ...) [(bind ...)] (domain NAME))` for declared
  same-domain ownership metadata.
- Lowering emits one deterministic generated do instance for the lexical
  nested do site, preserves generated-composition and schedule-report
  clock-domain metadata for that instance, and gates the switch-branch repeat
  check on that generated instance's fresh done handoff.
- Spawn nesting, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics remain deferred. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.41`, which must select the
  next bounded repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF switch-contained repeat generated do domains selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.39`.
- Selected top-level `switch` branches containing nested repeats with
  generated blocking `(do child (params ...) [(bind ...)] (domain NAME))` as
  the next bounded nested generated-do same-domain metadata subset.
- The selected contract mirrors the shipped when-contained domain subset:
  record declared same-domain ownership for the deterministic generated do
  instance at the lexical nested site and preserve generated-composition and
  schedule-report clock-domain metadata without implying CDC or cross-domain
  activation.
- Spawn nesting, cross-domain activation, deeper branch/loop nesting, and
  broader outstanding-child semantics remain deferred. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.40`.

## 2026-05-17: R14 — ISF when-contained repeat generated do domains shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.38`.
- Top-level `when` bodies may now contain nested repeats with generated
  blocking `(do child (params ...) [(bind ...)] (domain NAME))` for declared
  same-domain ownership metadata.
- Lowering emits one deterministic generated do instance for the lexical
  nested do site, preserves generated-composition and schedule-report
  clock-domain metadata for that instance, and gates the when-body repeat
  check on that generated instance's fresh done handoff.
- Switch-contained domain metadata, spawn nesting, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.39`, which must select the next bounded
  repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF when-contained repeat generated do domains selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.37`.
- Selected top-level `when` bodies containing nested repeats with generated
  blocking `(do child (params ...) [(bind ...)] (domain NAME))` as the next
  bounded nested generated-do same-domain metadata subset.
- The selected contract records declared same-domain ownership for the
  deterministic generated do instance at the lexical nested site, preserving
  generated-composition and schedule-report clock-domain metadata without
  implying CDC or cross-domain activation.
- Switch-contained domain metadata, spawn nesting, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.38`.

## 2026-05-17: R14 — ISF switch-contained repeat generated do bindings shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.36`.
- Top-level `switch` branches may now contain nested repeats with generated
  blocking `(do child (params ...) (bind ...))`, static parameter overrides,
  and input/output port bindings.
- Lowering emits one deterministic generated do instance for the lexical
  nested do site, applies parameter overrides once in the generated top, wires
  binding handoffs once for that instance, preserves source-order samples
  around the do, and gates the switch-branch repeat check on that generated
  instance's fresh done handoff.
- Domain metadata, spawn nesting, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain deferred. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.37`, which must
  select the next bounded repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF switch-contained repeat generated do bindings selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.35`.
- Selected top-level `switch` branches containing nested repeats with
  generated blocking `(do child (params ...) (bind ...))` as the next bounded
  nested generated-do binding subset.
- The selected contract mirrors the shipped when-contained binding subset:
  reuse the deterministic generated do instance from the switch-contained
  static-parameter subset, wire generated-top input/output binding handoffs
  once for the lexical nested do site, and gate the switch-branch repeat check
  on that instance's fresh done handoff.
- Domain metadata, spawn nesting, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain deferred. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.36`.

## 2026-05-17: R14 — ISF when-contained repeat generated do bindings shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.34`.
- Top-level `when` bodies may now contain nested repeats with generated
  blocking `(do child (params ...) (bind ...))`, static parameter overrides,
  and input/output port bindings.
- Lowering emits one deterministic generated do instance for the lexical
  nested do site, applies parameter overrides once in the generated top, wires
  binding handoffs once for that instance, preserves source-order samples
  around the do, and gates the when-body repeat check on that generated
  instance's fresh done handoff.
- Domain metadata, switch-contained bound nested `do`, spawn nesting,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.35`, which must select the next bounded
  repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF when-contained repeat generated do bindings selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.33`.
- Selected top-level `when` bodies containing nested repeats with generated
  blocking `(do child (params ...) (bind ...))` as the next bounded nested
  generated-do binding subset.
- The selected contract reuses the deterministic generated do instance from
  the when-contained static-parameter subset, wires generated-top input/output
  binding handoffs once for that lexical nested do site, and gates the
  when-body repeat check on that instance's fresh done handoff.
- Domain metadata, switch-contained bound nested `do`, spawn nesting,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.34`.

## 2026-05-17: R14 — ISF switch-contained repeat generated do params shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.32`.
- Top-level `switch` branches may now contain nested repeats with generated
  blocking `(do child (params ...))` and static parameter overrides.
- Lowering emits one deterministic generated do instance for the lexical
  nested do site, applies parameter overrides once in the generated top,
  preserves source-order samples around the do, and gates the switch-branch
  repeat check on that generated instance's fresh done handoff.
- Bind metadata, domain metadata, spawn nesting, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.33`, which must select the next bounded
  repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF switch-contained repeat generated do params selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.31`.
- Selected top-level `switch` branches containing nested repeats with
  generated blocking `(do child (params ...))` and static parameter overrides
  as the next bounded nested generated-do subset.
- The selected contract owns one deterministic generated do instance for the
  lexical nested repeat-body do site, applies static parameter overrides once
  in the generated top, and gates the switch-branch repeat check on that
  instance's fresh done handoff.
- Bind metadata, domain metadata, spawn nesting, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.32`.

## 2026-05-17: R14 — ISF when-contained repeat generated do params shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.30`.
- Top-level `when` bodies may now contain nested repeats with generated
  blocking `(do child (params ...))` and static parameter overrides.
- Lowering emits one deterministic generated do instance for the lexical
  nested do site, applies parameter overrides once in the generated top,
  preserves source-order samples around the do, and gates the when-body repeat
  check on that generated instance's fresh done handoff.
- Bind metadata, domain metadata, spawn nesting, switch-contained
  parameterized nested do, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain deferred. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.31`, which must
  select the next bounded repeat-body child activation subset before code.

## 2026-05-17: R14 — ISF when-contained repeat generated do params selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.29`.
- Selected top-level `when` bodies containing nested repeats with generated
  blocking `(do child (params ...))` and static parameter overrides as the
  next bounded nested generated-do subset.
- The selected contract owns one deterministic generated do instance for the
  lexical nested repeat-body do site, applies static parameter overrides once
  in the generated top, and gates the when-body repeat check on that
  instance's fresh done handoff.
- Bind metadata, domain metadata, spawn nesting, switch-contained
  parameterized nested do, cross-domain activation, deeper branch/loop
  nesting, and broader outstanding-child semantics remain deferred. The active
  frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.30`.

## 2026-05-17: R14 — ISF switch-contained repeat generated-child do shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.28`.
- Top-level `switch` branches may now contain nested repeats with plain
  `(do child)` targeting a child already emitted as a generated child by
  another activation site.
- Lowering emits one deterministic generated do instance for the lexical
  nested do site, preserves source-order samples around that do, and gates the
  switch-branch repeat check on the generated instance's fresh done handoff.
- Activation subclauses, spawn nesting, cross-domain activation, deeper
  branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.29`.

## 2026-05-17: R14 — ISF switch-contained repeat generated-child do selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.27`.
- Selected top-level `switch` branches containing nested repeats with plain
  `(do child)` targeting an already generated child as the next bounded
  nested generated-child subset.
- The selected contract owns one deterministic generated do instance for the
  lexical nested repeat-body do site and gates the switch-branch repeat check
  on that instance's fresh done handoff.
- Activation subclauses, parameterized nested do, bind/domain metadata, spawn
  nesting, cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.28`.

## 2026-05-17: R14 — ISF when-contained repeat generated-child do shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.26`.
- Top-level `when` bodies may now contain nested repeats with plain
  `(do child)` targeting a child already emitted as a generated child by
  another activation site.
- Lowering emits one deterministic generated do instance for the lexical
  nested do site, preserves source-order samples around that do, and gates the
  nested repeat check on the generated instance's fresh done handoff.
- Activation subclauses, spawn nesting, switch-contained generated-child `do`,
  cross-domain activation, deeper branch/loop nesting, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.27`.

## 2026-05-17: R14 — ISF when-contained repeat generated-child do selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.25`.
- Selected top-level `when` bodies containing nested repeats with plain
  `(do child)` targeting an already generated child as the next bounded
  nested generated-child subset.
- The selected contract owns one deterministic generated do instance for the
  lexical nested repeat-body do site and gates the nested repeat check on that
  instance's fresh done handoff.
- Activation subclauses, parameterized nested do, bind/domain metadata, spawn
  nesting, switch-contained generated-child `do`, cross-domain activation,
  deeper branch/loop nesting, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.26`.

## 2026-05-17: R14 — ISF switch-contained repeat local do shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.24`.
- Top-level `switch` branches may now contain nested repeats with local
  repeat-body `(do child)` when the child remains in the parent scheduled
  module.
- The lowerer wires local child start/done handoffs, keeps samples around the
  nested do in source order, and gates the switch-branch repeat check on the
  child's fresh done pulse.
- Generated targets, `(params ...)`, `(bind ...)`, `(domain NAME)`,
  repeat-body spawn, generated/spawn nested activation, deeper branch/loop
  nesting, cross-domain activation, and broader outstanding-child semantics
  remain fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.25`.

## 2026-05-17: R14 — ISF switch-contained repeat local do selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.23`.
- Selected top-level `switch` branches containing nested repeats with local
  repeat-body `(do child)` as the next bounded nested-placement subset.
- The selected contract keeps the child local to the parent scheduled module,
  preserves samples around the nested do in source order, and keeps the
  switch-branch repeat check gated by the child's fresh done pulse.
- Generated targets, `(params ...)`, `(bind ...)`, `(domain NAME)`,
  repeat-body spawn, deeper branch/loop nesting, cross-domain activation, and
  broader outstanding-child semantics remain deferred. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.24`.

## 2026-05-17: R14 — ISF when-contained repeat local do shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.22`.
- Repeats directly inside top-level `when` bodies may now use local
  `(do child)` when the child remains in the parent scheduled module.
- The lowerer wires local child start/done handoffs, keeps samples around the
  nested do in source order, and gates the branch-owned repeat check on the
  child's fresh done pulse.
- Generated targets, `(params ...)`, `(bind ...)`, `(domain NAME)`,
  generated/spawn nested activation, deeper branch/loop repeats, cross-domain
  activation, and broader outstanding-child semantics remain fail-closed. The
  active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.23`.

## 2026-05-17: R14 — ISF when-contained repeat local do selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.21`.
- Selected top-level `when` bodies containing nested repeats with local
  repeat-body `(do child)` as the next bounded nested-placement subset.
- The selected contract keeps the child local to the parent scheduled module
  and keeps the nested repeat check gated by the child's fresh done pulse.
- Repeat-body spawn, generated repeat-body `do`, bind/domain metadata,
  switch/loop nesting, cross-domain activation, and broader outstanding-child
  semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.22`.

## 2026-05-17: R14 — ISF repeat-body multi-pending await_any drain shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.20`.
- Top-level repeat bodies may now use multi-pending `(await_any done)` after
  multiple repeat-body spawns only when a later same-body `(await_all done)`
  drains the same outstanding children before the repeat check can loop.
- Lowering keeps the outstanding spawned done-port set live after
  multi-pending `await_any`, then clears it at the mandatory `await_all`
  drain.
- New repeat-body `spawn` or `do` clauses before that drain remain
  fail-closed. Nested placement, cross-domain activation, and broader
  outstanding-child semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.21`.

## 2026-05-17: R14 — ISF repeat-body multi-pending await_any drain selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.19`.
- Selected multi-pending repeat-body `(await_any done)` as the next bounded
  subset only when a later same-body `(await_all done)` drains the same
  outstanding repeat-body spawns before the repeat check.
- The selected contract treats `await_any` as an observation point and keeps
  new repeat-body `spawn` or `do` clauses before the mandatory drain out of
  scope.
- Nested placement, cross-domain activation, and broader outstanding-child
  semantics remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.20`.

## 2026-05-17: R14 — ISF repeat-body do sample timing shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.18`.
- Top-level repeat bodies may now sample immediately before or after shipped
  repeat-body local or generated `do` states.
- Samples before repeat-body `do` lower into an explicit sample state before
  the do state; samples after repeat-body `do` lower after the do state's
  fresh done guard and before the repeat check.
- Nested placement, cross-domain activation, multi-pending `await_any`, and
  broader outstanding-child semantics remain deferred. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.19`.

## 2026-05-17: R14 — ISF repeat-body do sample timing selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.17`.
- Selected top-level repeat-body sample-before/after-do timing as the next
  bounded implementation subset.
- The selected timing contract materializes samples before the do state for
  sample-before-do, or after the do state's fresh done guard and before the
  repeat check for sample-after-do.
- Nested placement, cross-domain activation, multi-pending `await_any`, and
  broader outstanding-child semantics remain deferred. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.18`.

## 2026-05-17: R14 — ISF repeat-body generated-child do shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.16`.
- Top-level repeat bodies may now use plain `(do child)` when `child` is
  already emitted as a generated child by another activation site.
- The repeat-body do site emits one deterministic generated child activation
  instance and waits for that instance's fresh done handoff before the repeat
  check can loop.
- Sample-before/after-do timing, nested placement, cross-domain activation,
  multi-pending `await_any`, and broader outstanding-child semantics remain
  fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.17`.

## 2026-05-17: R14 — ISF repeat-body generated-child do selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.15`.
- Selected top-level repeat-body plain `(do child)` targeting an already
  generated child as the next bounded implementation subset.
- The selected surface owns one deterministic generated activation instance
  for the lexical repeat-body do site and keeps repeat re-entry gated by that
  instance's fresh done handoff.
- Sample-before/after-do timing, nested placement, cross-domain activation,
  multi-pending `await_any`, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.16`.

## 2026-05-17: R14 — ISF repeat-body spawn-after-sample ordering shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.14`.
- Top-level repeat bodies may now sample before a later repeat-body spawn
  when the same body reaches `await_all` or single-pending `await_any` before
  the repeat check can loop.
- Pending samples lower into an explicit sample state before the spawn state,
  then the generated child sync gates repeat re-entry.
- Sample-before/after-do timing, nested placement, cross-domain activation,
  multi-pending `await_any`, and broader outstanding-child semantics remain
  fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.15`.

## 2026-05-17: R14 — ISF repeat-body spawn-after-sample ordering selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.13`.
- Selected top-level repeat-body spawn-after-sample ordering as the next
  bounded implementation subset.
- The selected timing contract emits pending samples before the later spawn
  state, then requires same-body `await_all` or single-pending `await_any`
  before the repeat check can loop.
- Sample-before/after-do timing, nested placement, cross-domain activation,
  multi-pending `await_any`, and broader outstanding-child semantics remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.14`.

## 2026-05-17: R14 — ISF repeat-body generated do domain metadata shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.12`.
- Top-level repeat bodies may now use generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))` for declared
  same-domain ownership metadata on the static generated do instance.
- Generated-composition metadata and schedule-report
  `clock_domains[].child_instances` preserve the lexical repeat-do instance
  ownership while runtime repeat re-entry remains done-gated.
- Undeclared domains, cross-domain activation, plain generated-child local do
  targets, nested placement, multi-pending `await_any`, and
  sample-before/after-do timing remain fail-closed. The active frontier
  advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.13`.

## 2026-05-17: R14 — ISF repeat-body generated do domain metadata selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.11`.
- Selected top-level repeat-body generated blocking
  `(do child (params ...) [(bind ...)] (domain NAME))` as the next bounded
  implementation subset.
- The selected surface is same-domain ownership metadata only for the static
  generated do instance, preserving generated-composition and schedule-report
  clock-domain metadata without implying CDC behavior.
- Cross-domain activation, nested placement, plain generated-child local do
  targets, multi-pending `await_any`, and sample-before/after-do timing remain
  deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.12`.

## 2026-05-17: R14 — ISF repeat-body generated do bindings shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.10`.
- Top-level repeat bodies may now use generated blocking
  `(do child (params ...) (bind ...))` with static parameter overrides and
  input/output port bindings.
- The generated do state starts one deterministic generated instance for the
  lexical do site, generated-top wiring applies the parameter and binding
  handoffs once, and repeat re-entry waits for that instance's fresh done
  handoff.
- Schedule JSON reports the binding provenance for the repeat-body generated
  do site. Repeat-body do domain metadata, plain local do targeting an
  already generated child, nested placement, cross-domain activation,
  multi-pending `await_any`, and sample-before/after-do timing remain
  fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.11`.

## 2026-05-17: R14 — ISF repeat-body generated do bindings selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.9`.
- Selected top-level repeat-body generated blocking
  `(do child (params ...) (bind ...))` as the next bounded implementation
  subset.
- The selected contract reuses the static generated do instance from `.8` and
  adds one generated-top binding handoff set for the lexical repeat-body do
  site.
- Repeat-body do domain metadata, nested placement, cross-domain activation,
  multi-pending `await_any`, plain generated-child local do targets, and
  sample-before/after-do timing remain deferred. The active frontier advances
  to `ISF-REPEAT-BODY-CHILD-ACTIVATION.10`.

## 2026-05-17: R14 — ISF repeat-body generated do static params shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.8`.
- Top-level repeat bodies may now use generated blocking
  `(do child (params ...))` with static parameter overrides.
- The generated do state starts one generated instance for the lexical do site
  and waits for that instance's fresh done handoff before the repeat check can
  loop.
- Generated-do binding handoffs, domain metadata, plain local do targeting an
  already generated child, sample-before/after-do timing, nested placement,
  cross-domain activation, and multi-pending `await_any` were still
  fail-closed at that leaf. The active frontier advanced to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.9`.

## 2026-05-17: R14 — ISF repeat-body generated do parameter subset selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.7`.
- Selected top-level repeat-body generated blocking `(do child (params ...))`
  as the next bounded implementation subset.
- The selected contract is one static generated child instance for the lexical
  do site, static parameter overrides in the generated top, and repeat
  re-entry only after the generated instance's fresh done pulse.
- Generated-do binding handoffs, domain metadata, nested placement,
  cross-domain activation, multi-pending `await_any`, and
  sample-before/after-do timing remained deferred at that selection leaf. The
  active frontier advanced to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.8`.

## 2026-05-17: R14 — ISF repeat-body sample-after-spawn timing shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.6`.
- Top-level repeat bodies may now sample after repeat-body spawn when the same
  body reaches `await_all` or single-pending `await_any` before the repeat
  check can loop.
- The pending samples lower into an explicit sample state before the sync
  state, so the generated timing is visible and reviewable.
- Spawn-after-sample ordering, sample-before/after-do timing, multi-pending
  `await_any`, nested branch/loop child activation, and cross-domain
  activation remain fail-closed. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.7`.

## 2026-05-17: R14 — ISF repeat-body local blocking do shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.5`.
- Top-level repeat bodies may now use local `(do child)` when the child remains
  in the parent scheduled module.
- The repeat-body `do` state starts the local child and waits for the child's
  fresh done pulse before the repeat check can loop.
- Generated, parameterized, bound, domain-qualified, generated-child-target,
  nested, and sample-before/after-do repeat-body `do` forms remain fail-closed.
  The active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.6`.

## 2026-05-17: R14 — ISF repeat-body single-pending await_any shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.4`.
- Top-level repeat bodies may now use `(await_any done)` after a repeat-body
  spawn only when exactly one child instance is pending.
- The subset preserves the static-child re-entry proof: the repeat check is
  reached only after the one child has produced fresh `done`.
- Zero-pending and multi-pending repeat-body `await_any` remain fail-closed.
  The active frontier advances to `ISF-REPEAT-BODY-CHILD-ACTIVATION.5`.

## 2026-05-17: R14 — ISF repeat-body spawn same-domain metadata shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.3`.
- Top-level repeat bodies may now use
  `(spawn child as inst [(params ...)] [(bind ...)] (domain NAME))` when
  `NAME` is the declared same-domain owner and the same repeat body reaches
  `(await_all done)` before the repeat check can loop.
- The domain annotation is metadata only: it groups the static generated child
  instance in clock-domain reports and does not imply CDC or cross-domain
  activation support.
- Repeat-body `await_any`, `do`, nested activation, cross-domain activation,
  and sample-after-spawn timing remain deferred. The active frontier advances
  to `ISF-REPEAT-BODY-CHILD-ACTIVATION.4`.

## 2026-05-17: R14 — ISF repeat-body spawn bindings shipped
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.2`.
- Top-level repeat bodies may now use
  `(spawn child as inst [(params ...)] (bind ...))` when the same repeat body
  reaches `(await_all done)` before the repeat check can loop.
- Input/output bindings reuse the static generated-child handoff model and are
  visible in generated-top wiring plus schedule-report
  `transaction_port_bindings[]` provenance.
- Repeat-body `(domain ...)`, `await_any`, `do`, nested activation, and
  sample-after-spawn timing remain deferred. The active frontier advances to
  `ISF-REPEAT-BODY-CHILD-ACTIVATION.3`.

## 2026-05-17: R14 — ISF repeat-body spawn bindings selected
- Completed `ISF-REPEAT-BODY-CHILD-ACTIVATION.1`.
- Activated the repeat-body child-activation task tree.
- Selected repeat-body `(spawn child as inst [(params ...)] (bind ...))` as
  the next implementation subset, limited to the existing top-level repeat
  plus same-body `(await_all done)` path.
- Deferred repeat-body `(domain ...)`, `await_any`, `do`, nested activation,
  and sample-after-spawn timing remain tracked in later leaves.

## 2026-05-17: R14 — ISF repeat-body activation remainders now tracked
- Created proposed R14 task tree:
  [docs/tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md](docs/tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md).
- The proposed tree owns repeat-body spawn `(bind ...)`, spawn `(domain ...)`,
  `await_any`, repeat-body `do`, nested branch/loop activation, and
  sample-after-spawn timing before future implementation.
- Updated the task-tree index, README task index, roadmap board, live docs,
  and mdBook feature backlog.
- Strengthened the workflow so code, test, source, generated-artifact, and
  config changes must have task-tree ownership before edits begin.
- No active ISF task tree is open; the next R14 PNT slice must select or
  activate a task tree first.

## 2026-05-16: R14 — ISF repeat-body spawn params shipped
- Completed R14 task-tree slice:
  `ISF-REPEAT-SPAWN-PARAMS.2` in
  [docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md](docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md).
- The `ISF-REPEAT-SPAWN-PARAMS` tree is now closed. No active ISF task tree
  remains open; the next R14 PNT slice must select or create a new task tree
  first.
- Top-level repeat bodies may now contain
  `(spawn child as inst (params ...))` when the same repeat body reaches
  `(await_all done)` before the repeat check can loop.
- Parameter overrides specialize the single lexical generated child instance
  once in the generated top; they are not per-iteration runtime values.
- Repeat-body `(bind ...)`, `(domain ...)`, `await_any`, `do`, samples after
  repeat-body spawn, and nested branch/loop activation remain fail-closed.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl modules/tests passed; focused
  repeat/spawn/doc tests passed with `Files=5, Tests=236`;
  `mdbook build docs/book` passed; `./bin/ci-regression isf --no-book`
  passed with `Files=227, Tests=1044`; `git diff --check` passed.

## 2026-05-16: R14 — ISF repeat-body spawn params contract selected
- Completed R14 task-tree slice:
  `ISF-REPEAT-SPAWN-PARAMS.1` in
  [docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md](docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md).
- The `ISF-REPEAT-SPAWN-PARAMS` tree is active. Current frontier:
  `ISF-REPEAT-SPAWN-PARAMS.2`, implementing the selected parameterized
  repeat-spawn subset.
- The selected subset allows top-level repeat-body
  `(spawn child as inst (params ...))` only when the same repeat body reaches
  `(await_all done)` before the repeat check can loop.
- Parameter overrides specialize the single lexical generated child instance
  in the generated top. They are not per-iteration runtime values.
- Repeat-body `(bind ...)`, `(domain ...)`, `await_any`, `do`, samples after
  repeat-body spawn, and nested branch/loop activation remain deferred.
- Updated the mdBook feature backlog, roadmap board, README task index, and
  task tree.
- Validation: `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF repeat-body spawn plus await_all subset shipped
- Completed R14 task-tree slice:
  `ISF-SPAWN-IN-REPEAT.2` in
  [docs/tasks/ISF-SPAWN-IN-REPEAT.md](docs/tasks/ISF-SPAWN-IN-REPEAT.md).
- The `ISF-SPAWN-IN-REPEAT` tree is now closed. No active ISF task tree
  remains open; the next R14 PNT slice must select or create a new task tree
  first.
- Top-level repeat bodies may now contain plain `(spawn child as inst)` when
  the same repeat body reaches `(await_all done)` before the repeat check can
  loop.
- The lexical spawn name denotes one static generated child instance reused
  across repeat iterations, and the same-body `await_all` observes all pending
  child done ports before re-entry.
- `await_any`, repeat-body `do`, spawn params/bind/domain forms, samples after
  repeat-body spawn, and nested branch/loop repeat-body spawn forms remain
  fail-closed.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl modules/tests passed; focused
  repeat/spawn/doc tests passed with `Files=5, Tests=228`;
  `mdbook build docs/book` passed; `./bin/ci-regression isf --no-book`
  passed with `Files=227, Tests=1036`; `git diff --check` passed.

## 2026-05-16: R14 — ISF spawn-in-repeat first contract selected
- Completed R14 task-tree slice:
  `ISF-SPAWN-IN-REPEAT.1` in
  [docs/tasks/ISF-SPAWN-IN-REPEAT.md](docs/tasks/ISF-SPAWN-IN-REPEAT.md).
- The `ISF-SPAWN-IN-REPEAT` tree is active. Current frontier:
  `ISF-SPAWN-IN-REPEAT.2`, implementing the documented first subset.
- The first implementation subset is top-level repeat bodies containing plain
  `(spawn child as inst)` clauses whose pending done ports are consumed by a
  same-body `(await_all done)` before the repeat check can loop.
- The lexical spawn name denotes one static generated child instance reused
  across repeat iterations. `await_any`, repeat-body `do`, activation params,
  activation bindings, activation domain overrides, and nested branch/loop
  repeat-body spawn forms remain deferred.
- Updated the mdBook feature backlog, roadmap board, README task index, and
  task tree.
- Validation: `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF phase successor zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-PHASE-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-PHASE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-PHASE-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-PHASE-SAMPLE` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create a
  new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into
  transaction `(phase ...)` pass-through states. The zero path materializes
  pending samples and preserves the original pass-through transition.
- Positive-count paths still sample in the first active wait state and then
  enter the original phase state without double-sampling.
- Actor-level phase metadata remains report-only. The accepted runtime
  scheduling shape is limited to transaction phase marker states with no
  assignments or guards.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=144`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1031`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF spawn successor zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-SPAWN-SAMPLE` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create a
  new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into
  top-level `spawn` states when the generated child start handoff is
  independent of pending sample aliases. The zero path materializes pending
  samples, asserts the original `inst_start` handoff, and advances like the
  original spawn state.
- Positive-count paths still sample in the first active wait state and then
  enter the original spawn state without double-sampling.
- Spawn states whose generated start handoff touches pending sample aliases
  remain fail-closed. Blocking `do` successors remain separate because they
  also own input/output bindings and a completion guard.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=142`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1029`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF sync successor zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-SYNC-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-SYNC-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-SYNC-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-SYNC-SAMPLE` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create a
  new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into
  top-level `await_all` and `await_any` sync states when the collected done
  ports are independent of pending sample aliases. The zero path materializes
  pending samples and preserves the original all-done or any-done transition.
- Positive-count paths still sample in the first active wait state and then
  enter the original sync state without double-sampling.
- Sync states whose collected done ports read pending sample aliases remain
  fail-closed. Inline-body `await_all`/`await_any` clauses remain outside the
  shipped branch/loop body surface.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=140`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1027`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF bank-access predecessor runtime dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.md](docs/tasks/ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.md).
- The `ISF-DYNAMIC-WAIT-BANK-PREDECESSOR` tree is now closed. No active ISF
  task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- Runtime dynamic waits can now follow transaction bank `load` and `store`
  states. The bank predecessor keeps its guarded scalarized assignments while
  the following wait edge splits into positive-count counter snapshot and
  zero-count bypass paths.
- `(load BANK IDX as TARGET) (wait cycles)` and `(store BANK IDX VALUE) (wait
  cycles)` now use the shipped sampled-counter runtime wait contract and reach
  HDL generation.
- Bank syntax, scalarized bank storage, load/store assignment semantics, and
  pending-sample bank successor compatibility are unchanged.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=138`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1025`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF loop decision zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE` tree is now closed. No active ISF
  task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into repeat
  check states and while/until loop decision states when their counter
  assignment and loop condition are independent of pending sample aliases. The
  zero path materializes pending samples and preserves the original repeat
  counter decrement or while/until branch behavior.
- Positive-count paths still sample in the first active wait state and then
  enter the original loop decision/check state without double-sampling.
- Loop decisions whose counter assignment or loop condition touches a pending
  sample alias remain fail-closed, as do unrelated remaining dynamic-wait
  predecessor/successor shapes.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=137`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1024`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF contract arm zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE` tree is now closed. No active ISF
  task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into top-level
  bounded-eventual contract arm states when the arm state is independent of
  pending sample aliases. The zero path materializes pending samples, emits
  the same one-cycle arm request, and advances like the original contract arm
  state.
- Positive-count paths still sample in the first active wait state and then
  enter the original contract arm state without double-sampling.
- The contract monitor DT remains the sole owner of pending/age/fail storage
  and observes the same arm request. Contract arm states that read or
  overwrite pending sample aliases and nested/unsupported contract shapes
  remain fail-closed. A later slice enabled independent loop decision/check
  successors.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  contract/wait/book audit tests passed with `Files=3, Tests=140`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1022`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF stage zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-STAGE-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-STAGE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-STAGE-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-STAGE-SAMPLE` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create a
  new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into top-level
  ready/valid stage successors when the stage ready input and valid output are
  independent of pending sample aliases. The zero path materializes pending
  samples, drives the original `valid` assignment, and preserves the original
  ready-gated transition.
- Positive-count paths still sample in the first active wait state and then
  enter the original stage state without double-sampling.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  stage/wait/book audit tests passed with `Files=3, Tests=136`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1020`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF consecutive runtime waits carry pending samples across zero links
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE` tree is now closed. No active ISF
  task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- Pending samples before consecutive top-level runtime waits now survive
  zero-count links. A zero first wait plus positive second wait enters a
  generated sample-preserving second-wait entry clone; an all-zero path enters
  a generated clone of the final sample-compatible target.
- Positive first-count paths still sample in the original first wait, and the
  original downstream wait state remains unsampled for paths that already
  materialized the sample.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait tests passed with `Files=1, Tests=31`; focused wait/book audit tests
  passed with `Files=2, Tests=131`; `./bin/ci-regression isf --no-book`
  passed with `Files=227, Tests=1018`; `mdbook build docs/book` passed;
  `git diff --check` passed.

## 2026-05-16: R14 — ISF independent bank-store zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE` tree is now closed. No
  active ISF task tree remains open; the next R14 implementation slice must
  select or create a new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into an
  independent bank-store successor. The zero path materializes pending
  samples, performs the original guarded scalarized store assignments, and
  advances to the original bank-store successor without adding a hidden
  sample-only cycle.
- Bank stores that read a pending sample alias as the index or stored value,
  or overwrite one as a scalarized destination entry, remain fail-closed.
  A later slice enabled consecutive top-level runtime waits to carry pending
  samples across zero-count wait links. Later slices enabled top-level
  ready/valid stage successors, top-level bounded-eventual contract arm
  successors, and independent loop decision/check successors when they do not
  touch pending sample aliases.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait tests passed with `Files=1, Tests=30`; focused wait/book audit tests
  passed with `Files=2, Tests=129`; `./bin/ci-regression isf --no-book`
  passed with `Files=227, Tests=1016`; `mdbook build docs/book` passed;
  `git diff --check` passed.

## 2026-05-16: R14 — ISF independent bank-load zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE` tree is now closed.
- Runtime dynamic waits with pending samples can now zero-bypass into an
  independent bank-load successor. The zero path materializes pending samples,
  performs the original guarded scalarized load assignments, and advances to
  the original bank-load successor without adding a hidden sample-only cycle.
- The transaction-state linker now advances bank `load` and bank `store`
  states to their following transaction state, fixing ordinary transaction
  bank access sequencing. A later slice enables independent store
  zero-bypass.
- Bank loads that read a pending sample alias as the index or overwrite one as
  the target remain fail-closed. A later slice independently enabled
  bank-store successors when they do not touch pending sample aliases.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=127`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1014`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF independent extract zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE` tree is now closed. No
  active ISF task tree remains open; the next R14 implementation slice must
  select or create a new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into an
  independent extract successor. The zero path materializes pending samples in
  an extract clone, performs the original slice assignments, and advances to
  the original extract successor without adding a hidden sample-only cycle.
- Extract states that read a pending sample alias as the source word or
  overwrite one as a destination field remain fail-closed. Later slices
  independently enabled bank-load, bank-store, top-level ready/valid stage
  successors, top-level bounded-eventual contract arm successors, and
  independent loop decision/check successors when they do not touch pending
  sample aliases.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=125`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1012`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF independent assemble zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE` tree is now closed. No
  active ISF task tree remains open; the next R14 implementation slice must
  select or create a new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into an
  independent assemble successor. The zero path materializes pending samples
  in an assemble clone, performs the original concat assignment, and advances
  to the original assemble successor without adding a hidden sample-only cycle.
- Assemble states that read a pending sample alias as a part or overwrite one
  as the target remain fail-closed. Later slices independently enabled
  extract, bank-load, bank-store, top-level ready/valid stage successors,
  top-level bounded-eventual contract arm successors, and independent loop
  decision/check successors when they do not touch pending sample aliases.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=123`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1010`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF independent shift zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE` tree is now closed. No
  active ISF task tree remains open; the next R14 implementation slice must
  select or create a new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into an
  independent shift successor. The zero path materializes pending samples in a
  shift clone, performs the original shift assignment, and advances to the
  original shift successor without adding a hidden sample-only cycle.
- Shifts that read or overwrite a pending sample alias remain fail-closed.
  Later slices independently enabled assemble, extract, bank-load, bank-store,
  top-level ready/valid stage successors, top-level bounded-eventual contract
  arm successors, and independent loop decision/check successors when they do
  not touch pending sample aliases.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=121`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1008`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF independent update zero-bypass coverage added
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.md).
- The `ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE` tree is now
  closed. No active ISF task tree remains open; the next R14 implementation
  slice must select or create a new task tree first.
- Added explicit wait-lowering regression coverage for independent
  `(update out 1)` zero-bypass after a pending sample, matching the canonical
  independent `set` behavior shipped in the previous slice.
- No source-language behavior, public contract shape, generated artifact
  contract, schedule-report schema, or mdBook behavior text changed.
- Validation: `perl -Iperl -c t/1244-isf-wait-clause-lowering.t` passed;
  `prove -l t/1244-isf-wait-clause-lowering.t` passed with `Files=1,
  Tests=25`; `git diff --check` passed.

## 2026-05-16: R14 — ISF independent setter zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE` tree is now closed. No active
  ISF task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into an
  independent scalar `set`/`update` successor. The zero path materializes the
  pending samples in a setter clone, performs the original setter assignment,
  and advances to the original setter successor without adding a hidden
  sample-only cycle.
- Setters that read or overwrite a pending sample alias remain fail-closed.
  Later slices independently enabled shift, assemble, extract, bank-load,
  bank-store, top-level ready/valid stage successors, top-level
  bounded-eventual contract arm successors, and independent loop
  decision/check successors when they do not touch pending sample aliases.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=118`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1005`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF completion zero-bypass pending-sample dynamic waits shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.1` in
  [docs/tasks/ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.md](docs/tasks/ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.md).
- The `ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE` tree is now closed. No active ISF
  task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- Runtime dynamic waits with pending samples can now zero-bypass into a
  compatible completion successor. The zero path materializes the pending
  sample assignments in a completion clone, emits the delayed completion pulse,
  and returns to idle without adding a hidden sample-only cycle.
- Positive-count paths still sample in the first wait state and exit through
  the original completion state. Unsafe data-operation successors, consecutive
  pending-sample runtime waits, and unsupported loop/check-state successors
  remain fail-closed.
- Updated the ISF spec, downstream handoff, public contract, mdBook, roadmap
  board, README task index, and task tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/book audit tests passed with `Files=2, Tests=114`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=1001`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF parameter-backed static wait counts shipped
- Completed R14 task-tree slice:
  `ISF-PARAM-WAIT-COUNTS.1` in
  [docs/tasks/ISF-PARAM-WAIT-COUNTS.md](docs/tasks/ISF-PARAM-WAIT-COUNTS.md).
- The `ISF-PARAM-WAIT-COUNTS` tree is now closed. No active ISF task tree
  remains open; the next R14 implementation slice must select or create a new
  task tree first.
- `(wait NAME)` now accepts actor-local scalar parameter defaults when the
  default resolves to a non-negative integer literal. Zero defaults are
  transparent, positive defaults emit fixed wait-state chains, and
  `transaction_waits[]` records static wait metadata with the authored
  parameter name in `count_source`.
- Transaction parameters, non-scalar actor parameter defaults, non-integer
  defaults, unknown symbolic names, and use-site override specialization remain
  fail-closed for wait counts.
- Updated the ISF spec, downstream handoff, public contract, mdBook,
  schedule-report golden matrix, roadmap board, README task index, and task
  tree.
- Validation: syntax checks for changed Perl tests/modules passed; focused
  wait/report/book/spec audit tests passed with `Files=4, Tests=115`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=998`;
  `mdbook build docs/book` passed.

## 2026-05-16: R14 — ISF FIFO library fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md](docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md).
- The `ISF-FIFO-LIBRARY-FIXTURE-PROMOTION` tree is now closed. No active ISF
  task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- Added
  [t/1321-isf-fifo-library-fixture-coverage.t](t/1321-isf-fifo-library-fixture-coverage.t)
  for file-backed strict schedule JSON parity, generated importer/child/top
  scheduled `.fsm` artifacts, strict `--outdir` file emission, fixed FIFO
  parameter overrides, use-site bindings, scalarized FIFO data entries,
  generated top wiring, and plain plus strict generated-top HDL generation for
  [isf/fifo_library_use.isf](isf/fifo_library_use.isf).
- The fixture remains fixed to `DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and
  `OCC_WIDTH=3`; broader reusable-library generalization remains deferred.
- Updated public `tested_by` metadata, CI tier checks, the ISF spec,
  downstream handoff, public contract, reusable-library catalog, mdBook,
  fixture matrix, roadmap board, README task index, and task tree.
- Validation: syntax checks for changed Perl files passed; focused
  library/public/book/catalog/spec audit tests passed with
  `Files=9, Tests=112`;
  `./bin/ci-regression isf --no-book` passed with `Files=227, Tests=996`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF FIFO controller fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md](docs/tasks/ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md).
- The `ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION` tree is now closed. No active
  ISF task tree remains open; the next R14 implementation slice must select
  or create a new task tree first.
- Added
  [t/1320-isf-fifo-controller-fixture-coverage.t](t/1320-isf-fifo-controller-fixture-coverage.t)
  for file-backed strict schedule JSON parity, scheduled `.fsm` structure,
  compatible same-value fan-in metadata, plain and strict HDL generation,
  idle cycles, push-only, pop-only, simultaneous push+pop occupancy updates,
  actor-maintained full/empty flags, and 2-bit pointer wrap for
  [isf/fifo_controller.isf](isf/fifo_controller.isf).
- The fixture is explicitly controller-only and does not claim data-bank
  storage or `data_out` datapath transfer behavior.
- Updated public `tested_by` metadata, CI tier checks, the ISF spec,
  downstream handoff, public contract, mdBook, fixture matrix, roadmap board,
  README task index, and task tree.
- Validation: syntax checks for changed Perl files passed; focused
  controller/public/book/spec audit tests passed with `Files=7, Tests=105`;
  `./bin/ci-regression isf --no-book` passed with `Files=226, Tests=992`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF FIFO datapath fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md](docs/tasks/ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md).
- The `ISF-FIFO-DATAPATH-FIXTURE-PROMOTION` tree is now closed. No active ISF
  task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- Added
  [t/1319-isf-fifo-datapath-fixture-coverage.t](t/1319-isf-fifo-datapath-fixture-coverage.t)
  for file-backed strict schedule JSON parity, scheduled `.fsm` structure,
  bounded `bank_accesses[]` metadata, plain and strict HDL generation,
  scalarized depth-4 bank storage, pointer-guarded accepted pushes, and
  pointer-guarded accepted pops for [isf/fifo_data_path.isf](isf/fifo_data_path.isf).
- Updated public `tested_by` metadata, CI tier checks, the ISF spec,
  downstream handoff, public contract, mdBook, fixture matrix, roadmap board,
  README task index, and task tree.
- Validation: syntax checks for changed Perl files passed; focused
  bank-access/public/book/spec audit tests passed with `Files=7, Tests=105`;
  `./bin/ci-regression isf --no-book` passed with `Files=225, Tests=988`;
  `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF shift-left explicit-width evidence shipped
- Completed R14 task-tree slice:
  `ISF-SHIFT-LEFT-EXPLICIT-WIDTH.1` in
  [docs/tasks/ISF-SHIFT-LEFT-EXPLICIT-WIDTH.md](docs/tasks/ISF-SHIFT-LEFT-EXPLICIT-WIDTH.md).
- The `ISF-SHIFT-LEFT-EXPLICIT-WIDTH` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create
  a new task tree first.
- `shift_left` now accepts optional `(width N)` as static register-width
  evidence, rejects malformed or contradictory width assertions, and can feed
  that evidence to later `shift_right` lowering plus schedule-report storage
  width metadata.
- Widthless `shift_left` remains accepted, and the emitted left-shift
  scheduled `.fsm` expression remains unchanged.
- Added
  [t/1318-isf-shift-left-explicit-width.t](t/1318-isf-shift-left-explicit-width.t)
  and updated boundary/public/CI/book/spec audit coverage.
- Updated the ISF spec, downstream handoff, public contract, mdBook, closed
  data-width notes, roadmap board, README task index, and task tree.
- Validation: `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm` passed;
  focused shift/data/public/book/spec audit tests passed with `Files=8,
  Tests=110`; `./bin/ci-regression isf --no-book` passed with `Files=224,
  Tests=984`; `mdbook build docs/book` passed; `git diff --check` passed.

## 2026-05-16: R14 — ISF stage/contract fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md](docs/tasks/ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md).
- The `ISF-STAGE-CONTRACT-FIXTURE-PROMOTION` tree is now closed. No active
  ISF task tree remains open; the next R14 implementation slice must select
  or create a new task tree first.
- Added [isf/stream_stage_contract.isf](isf/stream_stage_contract.isf) as a
  bounded ready/valid stage plus bounded eventual contract fixture.
- Added
  [t/1317-isf-stage-contract-fixture-coverage.t](t/1317-isf-stage-contract-fixture-coverage.t)
  for file-backed scheduled `.fsm` structure, strict schedule JSON parity,
  plain and strict HDL generation, sampled payload forwarding, ready/valid
  barrier metadata, bounded eventual contract metadata, temporal monitor
  storage roles, SystemVerilog sticky-fail assertion projection, and delayed
  completion pulse behavior.
- Updated public `tested_by` metadata and synchronized the spec, downstream
  handoff, public contract, mdBook, fixture matrix, and live docs.
- Validation: focused stage/contract/public/book/spec audit tests passed with
  `Files=9, Tests=112`; `./bin/ci-regression isf --no-book` passed with
  `Files=223, Tests=979`; `mdbook build docs/book` passed; `git diff
  --check` passed.

## 2026-05-16: R14 — ISF rule/resource fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-RULE-RESOURCE-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md](docs/tasks/ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md).
- The `ISF-RULE-RESOURCE-FIXTURE-PROMOTION` tree is now closed. No active ISF
  task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- Added [isf/rule_resource_arbiter.isf](isf/rule_resource_arbiter.isf) as a
  bounded `rule_slot`/`priority` resource arbitration fixture.
- Added
  [t/1316-isf-rule-resource-fixture-coverage.t](t/1316-isf-rule-resource-fixture-coverage.t)
  for file-backed scheduled `.fsm` structure, strict schedule JSON parity,
  plain and strict HDL generation, rule-over-transaction priority
  suppression, resource arbitration report metadata, lower-priority rule
  gating, and delayed completion pulse behavior.
- Updated public `tested_by` metadata and synchronized the spec, downstream
  handoff, public contract, mdBook, fixture matrix, and live docs.
- Validation: focused rule/resource/public/book/spec audit tests passed with
  `Files=7, Tests=106`; `./bin/ci-regression isf --no-book` passed with
  `Files=222, Tests=975`; `mdbook build docs/book` passed; `git diff --check`
  passed.

## 2026-05-16: R14 — ISF generated-composition fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md](docs/tasks/ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md).
- The `ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION` tree is now closed. No
  active ISF task tree remains open; the next R14 implementation slice must
  select or create a new task tree first.
- Added
  [t/1315-isf-generated-composition-fixture-coverage.t](t/1315-isf-generated-composition-fixture-coverage.t)
  for file-backed generated top, parent, and child scheduled `.fsm`
  structure, strict schedule JSON parity, strict `--outdir` file emission,
  generated top HDL wiring, parent start/await/data handoff behavior, and
  child drive request/payload handoff behavior.
- Updated public `tested_by` metadata and synchronized the spec, downstream
  handoff, public contract, mdBook, fixture matrix, and live docs.
- Validation: focused generated-composition/public/book/spec audit tests
  passed with `Files=9, Tests=105`; `./bin/ci-regression isf --no-book`
  passed with `Files=221, Tests=971`; `mdbook build docs/book` passed;
  `git diff --check` passed.

## 2026-05-16: R14 — ISF when fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-WHEN-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-WHEN-FIXTURE-PROMOTION.md](docs/tasks/ISF-WHEN-FIXTURE-PROMOTION.md).
- The `ISF-WHEN-FIXTURE-PROMOTION` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create
  a new task tree first.
- Added
  [t/1314-isf-when-fixture-coverage.t](t/1314-isf-when-fixture-coverage.t)
  for file-backed scheduled `.fsm` structure, strict schedule JSON parity,
  plain and strict HDL generation, entry drive setup, two conditional decision
  states, multi-step true-body drives, false-path fallthrough, compatible
  named-drive start fan-in, and delayed completion pulse behavior.
- Updated public `tested_by` metadata and synchronized the spec, downstream
  handoff, public contract, mdBook, fixture matrix, and live docs.
- Validation: focused when/public/book/spec audit tests passed with
  `Files=8, Tests=102`; `git diff --check` passed; `mdbook build docs/book`
  passed; broad `./bin/ci-regression isf --no-book` passed with `Files=220,
  Tests=967`.

## 2026-05-16: R14 — ISF switch fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-SWITCH-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-SWITCH-FIXTURE-PROMOTION.md](docs/tasks/ISF-SWITCH-FIXTURE-PROMOTION.md).
- The `ISF-SWITCH-FIXTURE-PROMOTION` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create
  a new task tree first.
- Added
  [t/1313-isf-switch-fixture-coverage.t](t/1313-isf-switch-fixture-coverage.t)
  for file-backed scheduled `.fsm` structure, strict schedule JSON parity,
  plain and strict HDL generation, sampled selector capture, explicit branch
  dispatch, default fallthrough to completion, named-drive branch starts, and
  delayed completion pulse behavior.
- Updated public `tested_by` metadata and synchronized the spec, downstream
  handoff, public contract, mdBook, fixture matrix, and live docs.
- Validation: focused switch/public/book/spec audit tests passed with
  `Files=7, Tests=103`; `git diff --check` passed; `mdbook build docs/book`
  passed; broad `./bin/ci-regression isf --no-book` passed with `Files=219,
  Tests=963`.

## 2026-05-16: R14 — ISF phase fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-PHASE-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-PHASE-FIXTURE-PROMOTION.md](docs/tasks/ISF-PHASE-FIXTURE-PROMOTION.md).
- The `ISF-PHASE-FIXTURE-PROMOTION` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create
  a new task tree first.
- [isf/phase_test.isf](isf/phase_test.isf) now leaves `done` exclusively owned
  by `complete done`, avoiding mixed reusable-drive and delayed-pulse
  assignment families during HDL generation.
- Added
  [t/1312-isf-phase-fixture-coverage.t](t/1312-isf-phase-fixture-coverage.t)
  for file-backed scheduled `.fsm` structure, strict schedule JSON parity,
  plain and strict HDL generation, transaction phase pass-through states, no
  reusable `done` drive storage, and delayed completion pulse behavior.
- Updated public `tested_by` metadata and synchronized the spec, downstream
  handoff, public contract, mdBook, fixture matrix, and live docs.
- Validation: focused phase/public/book/spec audit tests passed with
  `Files=6, Tests=99`; `git diff --check` passed; `mdbook build docs/book`
  passed; broad `./bin/ci-regression isf --no-book` passed with `Files=218,
  Tests=959`.

## 2026-05-16: R14 — ISF UART-like fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-UART-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-UART-FIXTURE-PROMOTION.md](docs/tasks/ISF-UART-FIXTURE-PROMOTION.md).
- The `ISF-UART-FIXTURE-PROMOTION` tree is now closed. No active ISF task tree
  remains open; the next R14 implementation slice must select or create a new
  task tree first.
- [isf/uart_tx.isf](isf/uart_tx.isf) now drives serial `tx` from sampled
  `byte_data[0]` before shifting the sampled byte right, so strict HDL
  generation no longer relies on full-byte truncation into a one-bit output.
- Added
  [t/1311-isf-uart-fixture-coverage.t](t/1311-isf-uart-fixture-coverage.t)
  for file-backed scheduled `.fsm` structure, strict schedule JSON parity,
  plain and strict HDL generation, known-width `shift_right`, repeat counter
  storage, busy drive sequencing, and completion pulse behavior.
- Updated public `tested_by` metadata and synchronized the spec, downstream
  handoff, public contract, mdBook, fixture matrix, and live docs.
- Validation: focused UART/public/book/spec audit tests passed with
  `Files=6, Tests=96`; `git diff --check` passed; `mdbook build docs/book`
  passed; broad `./bin/ci-regression isf --no-book` passed with `Files=217,
  Tests=955`.

## 2026-05-16: R14 — ISF burst-reader fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-BURST-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-BURST-FIXTURE-PROMOTION.md](docs/tasks/ISF-BURST-FIXTURE-PROMOTION.md).
- The `ISF-BURST-FIXTURE-PROMOTION` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create a
  new task tree first.
- Added
  [t/1310-isf-burst-fixture-coverage.t](t/1310-isf-burst-fixture-coverage.t)
  for file-backed scheduled `.fsm` structure, strict schedule JSON parity,
  plain and strict HDL generation, dynamic repeat counter storage, watchdog
  and latency counter roles, sampled aliases, and completion/timeout pulse
  fan-in.
- Updated public `tested_by` metadata and synchronized the spec, downstream
  handoff, public contract, mdBook, fixture matrix, and live docs.
- Validation: focused burst/public/book/spec audit tests passed with
  `Files=5, Tests=93`; `git diff --check` passed; broad
  `./bin/ci-regression isf --no-book` passed with `Files=216, Tests=951`.

## 2026-05-16: R14 — ISF I2C-like fixture promotion shipped
- Completed R14 task-tree slice:
  `ISF-I2C-FIXTURE-PROMOTION.1` in
  [docs/tasks/ISF-I2C-FIXTURE-PROMOTION.md](docs/tasks/ISF-I2C-FIXTURE-PROMOTION.md).
- The `ISF-I2C-FIXTURE-PROMOTION` tree is now closed. No active ISF task tree
  remains open; the next R14 implementation slice must select or create a new
  task tree first.
- [isf/i2c_master.isf](isf/i2c_master.isf) now drives write-data SDA from
  sampled `data[7]` and shifts the sampled byte after each driven bit, avoiding
  an implicit `data_bit` input in generated HDL.
- Added
  [t/1309-isf-i2c-fixture-coverage.t](t/1309-isf-i2c-fixture-coverage.t)
  for file-backed scheduled `.fsm` structure, strict schedule JSON parity,
  plain and strict HDL generation, switch-branch repeats, read-data shifting,
  sampled write-data bit selection, and absence of an implicit `data_bit`
  input.
- Updated public `tested_by` metadata and synchronized the spec, downstream
  handoff, public contract, mdBook, fixture matrix, and live docs.
- Validation: focused I2C/public/book/spec audit tests passed with
  `Files=5, Tests=92`; `git diff --check` passed; broad
  `./bin/ci-regression isf --no-book` passed with `Files=215, Tests=947`.

## 2026-05-16: R14 — ISF assemble single-part width inference shipped
- Completed R14 task-tree slice:
  `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.1` in
  [docs/tasks/ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.md](docs/tasks/ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.md).
- The `ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE` tree is now closed. No active
  ISF task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- ISF `assemble` now infers exactly one missing source part width from a known
  destination width plus known sibling part widths.
- The inferred part width remains transaction-local width evidence for later
  data operations in the same transaction. Two or more unknown source parts
  remain accepted as concat operands, but do not provide width evidence.
- A single unknown part whose inferred remainder is not positive now fails
  closed with a targeted diagnostic.
- Widened
  [t/1200-isf-assemble-clause-boundary.t](t/1200-isf-assemble-clause-boundary.t)
  and
  [t/1305-isf-book-feature-matrix-audit.t](t/1305-isf-book-feature-matrix-audit.t),
  and synchronized the spec, downstream handoff, public contract, mdBook, and
  live docs.
- Validation: focused assemble/matrix tests passed with `Files=2, Tests=85`;
  `git diff --check` passed; broad `./bin/ci-regression isf --no-book` passed
  with `Files=214, Tests=943`.

## 2026-05-16: R14 — ISF actor-constant zero divisor safety shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-DIVISOR-CONSTANTS.1` in
  [docs/tasks/ISF-DYNAMIC-DIVISOR-CONSTANTS.md](docs/tasks/ISF-DYNAMIC-DIVISOR-CONSTANTS.md).
- The `ISF-DYNAMIC-DIVISOR-CONSTANTS` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create
  a new task tree first.
- ISF runtime division/modulo safety now rejects actor-level constants that
  resolve to zero, including enum-backed zero constants, before scheduled
  `.fsm` emission.
- Nonzero actor constants, nonzero literal divisors, and dynamic scalar
  divisors remain accepted and lower unchanged. Actor/transaction parameters
  remain outside this proof because they are overrideable specialization
  values.
- Widened
  [t/1308-isf-dynamic-divisor-safety.t](t/1308-isf-dynamic-divisor-safety.t)
  and
  [t/1305-isf-book-feature-matrix-audit.t](t/1305-isf-book-feature-matrix-audit.t),
  and synchronized the spec, downstream handoff, public contract, mdBook, and
  live docs.
- Validation: focused divisor/matrix tests passed with `Files=2, Tests=87`;
  `git diff --check` passed; broad `./bin/ci-regression isf --no-book` passed
  with `Files=214, Tests=939`.

## 2026-05-16: R14 — ISF extract single-field width inference shipped
- Completed R14 task-tree slice:
  `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.1` in
  [docs/tasks/ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.md](docs/tasks/ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.md).
- The `ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE` tree is now closed. No active
  ISF task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- ISF `extract` now infers exactly one missing destination field width from a
  known source word width plus known sibling field widths, including
  assemble-derived source widths.
- The inferred field width remains transaction-local width evidence for later
  data operations in the same transaction. Multiple unknown fields,
  non-positive remainders, explicit-width conflicts, and source/field total
  mismatches still fail closed.
- Widened
  [t/1101-isf-extract-slices.t](t/1101-isf-extract-slices.t)
  and
  [t/1305-isf-book-feature-matrix-audit.t](t/1305-isf-book-feature-matrix-audit.t),
  and synchronized the spec, downstream handoff, public contract, mdBook, and
  live docs.
- Validation: focused extract/matrix tests passed with `Files=2, Tests=85`;
  `git diff --check` passed; broad `./bin/ci-regression isf --no-book` passed
  with `Files=214, Tests=935`.

## 2026-05-16: R14 — ISF dynamic divisor literal-zero safety shipped
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-DIVISOR-SAFETY.1` in
  [docs/tasks/ISF-DYNAMIC-DIVISOR-SAFETY.md](docs/tasks/ISF-DYNAMIC-DIVISOR-SAFETY.md).
- The `ISF-DYNAMIC-DIVISOR-SAFETY` tree is now closed. No active ISF task tree
  remains open; the next R14 implementation slice must select or create a new
  task tree first.
- ISF parser semantic validation now rejects division/modulo expressions with
  literal-zero divisor operands across shipped runtime expression surfaces
  before scheduled `.fsm` emission.
- Nonzero literal divisors and dynamic scalar divisors remain accepted and
  lower unchanged; broader dynamic nonzero proof remains documented backlog.
- Added
  [t/1308-isf-dynamic-divisor-safety.t](t/1308-isf-dynamic-divisor-safety.t)
  and synchronized the spec index, public contract metadata, downstream
  handoff, and mdBook feature matrix.
- Validation: focused audit set passed with `Files=4, Tests=86`; broad
  `./bin/ci-regression isf --no-book` passed with `Files=214, Tests=930`.

## 2026-05-16: R14 — ISF feature matrix CLI examples synchronized
- Completed R14 task-tree slice:
  `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.1` in
  [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.md).
- The `ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC` tree is now closed. No
  active ISF task tree remains open; the next R14 implementation slice must
  select or create a new task tree first.
- The ISF shipped feature matrix now includes copyable CLI examples for
  strict mode, schedule JSON, multi-file `--outdir`, and SystemVerilog HDL
  handoff.
- Widened
  [t/1305-isf-book-feature-matrix-audit.t](t/1305-isf-book-feature-matrix-audit.t)
  to keep the CLI markers present.
- No parser, scheduler, CLI behavior, schedule-report payload, generated
  `.fsm`, or HDL behavior changed.

## 2026-05-16: R14 — ISF feature matrix issue-bundle coverage synchronized
- Completed R14 task-tree slice:
  `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.1` in
  [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.md).
- The `ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC` tree is now closed. No
  active ISF task tree remains open; the next R14 implementation slice must
  select or create a new task tree first.
- The ISF shipped feature matrix now includes a runnable
  `bin/fsmgen-issue-bundle` example and states that downstream tools do not
  need to classify `.fsm`, `.isf`, parser, lowering, HDL, or API root cause
  before reporting.
- Widened
  [t/1305-isf-book-feature-matrix-audit.t](t/1305-isf-book-feature-matrix-audit.t)
  to keep the helper invocation markers present.
- No parser, scheduler, issue-bundle helper behavior, schedule-report payload,
  generated `.fsm`, or HDL behavior changed.

## 2026-05-16: R14 — ISF feature matrix report metadata coverage synchronized
- Completed R14 task-tree slice:
  `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.1` in
  [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.md).
- The `ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC` tree is now closed. No
  active ISF task tree remains open; the next R14 implementation slice must
  select or create a new task tree first.
- The ISF shipped feature matrix now explicitly lists actor report metadata,
  actor params, schedule JSON schema-version stability, storage role metadata,
  and the report-internal non-claims.
- Widened
  [t/1305-isf-book-feature-matrix-audit.t](t/1305-isf-book-feature-matrix-audit.t)
  to keep those shipped feature-family and non-claim markers present.
- No parser, scheduler, report payload, generated `.fsm`, or HDL behavior
  changed.

## 2026-05-16: R14 — ISF feature matrix port/binding coverage synchronized
- Completed R14 task-tree slice:
  `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.1` in
  [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.md).
- The `ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC` tree is now closed. No
  active ISF task tree remains open; the next R14 implementation slice must
  select or create a new task tree first.
- The ISF shipped feature matrix now explicitly lists transaction ports,
  activation-site bindings, and `transaction_port_bindings[]` report
  provenance. At that historical slice the rule-trigger output-binding and
  snapshot-vs-live timing non-claims were still present; later R14 slices
  shipped generated-child rule-trigger output bindings and current-timing
  `(timing snapshot|live)` assertions while keeping direct/local rule-trigger
  output bindings and behavior-changing timing conversion deferred.
- Widened
  [t/1305-isf-book-feature-matrix-audit.t](t/1305-isf-book-feature-matrix-audit.t)
  to keep those shipped feature-family and non-claim markers present.
- No parser, scheduler, report payload, generated `.fsm`, or HDL behavior
  changed.

## 2026-05-16: R14 — ISF feature matrix stage/contract coverage synchronized
- Completed R14 task-tree slice:
  `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.1` in
  [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.md).
- The `ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC` tree is now closed. No active
  ISF task tree remains open; the next R14 implementation slice must select or
  create a new task tree first.
- The ISF shipped feature matrix now explicitly lists transaction stage
  lowering and temporal contract SystemVerilog assertion projection, with
  example syntax and broader non-claims.
- Widened
  [t/1305-isf-book-feature-matrix-audit.t](t/1305-isf-book-feature-matrix-audit.t)
  to keep those shipped feature-family markers present.
- No parser, scheduler, report payload, generated `.fsm`, or HDL behavior
  changed.

## 2026-05-16: R14 — ISF loop-body documentation truth synchronized
- Completed R14 task-tree slice:
  `ISF-LOOP-BODY-DOC-TRUTH-SYNC.1` in
  [docs/tasks/ISF-LOOP-BODY-DOC-TRUTH-SYNC.md](docs/tasks/ISF-LOOP-BODY-DOC-TRUTH-SYNC.md).
- The `ISF-LOOP-BODY-DOC-TRUTH-SYNC` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create a
  new task tree first.
- The ISF spec and mdBook feature backlog now include transaction `set` in
  the shipped loop-body inline subset, matching the transaction chapter.
- Added
  [t/1307-isf-loop-body-doc-truth-audit.t](t/1307-isf-loop-body-doc-truth-audit.t)
  to prevent loop-body shipped-clause drift.
- No parser, scheduler, report payload, generated `.fsm`, or HDL behavior
  changed.

## 2026-05-16: R14 — ISF rule-guard backlog truth synchronized
- Completed R14 task-tree slice:
  `ISF-RULE-GUARD-DOC-TRUTH-SYNC.1` in
  [docs/tasks/ISF-RULE-GUARD-DOC-TRUTH-SYNC.md](docs/tasks/ISF-RULE-GUARD-DOC-TRUTH-SYNC.md).
- The `ISF-RULE-GUARD-DOC-TRUTH-SYNC` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create a
  new task tree first.
- The ISF spec and mdBook feature backlog now state that standalone enum
  member and scalar aggregate rule guards are shipped in shorthand and
  long-form rule syntax.
- The remaining enum target, enum operator-position, aggregate
  operator-position, and subaggregate rule-target deferrals remain explicit.
- Added
  [t/1306-isf-rule-guard-doc-truth-audit.t](t/1306-isf-rule-guard-doc-truth-audit.t)
  to prevent the stale backlog wording from returning.
- No parser, scheduler, report payload, generated `.fsm`, or HDL behavior
  changed.

## 2026-05-16: R14 — ISF book shipped feature matrix added
- Completed R14 task-tree slice:
  `ISF-MDBOOK-FEATURE-MATRIX.1` in
  [docs/tasks/ISF-MDBOOK-FEATURE-MATRIX.md](docs/tasks/ISF-MDBOOK-FEATURE-MATRIX.md).
- The `ISF-MDBOOK-FEATURE-MATRIX` tree is now closed. No active ISF task tree
  remains open; the next R14 implementation slice must select or create a new
  task tree first.
- Added
  [docs/book/src/13k-isf-feature-support-matrix.md](docs/book/src/13k-isf-feature-support-matrix.md)
  as the book-facing support matrix for shipped ISF feature families,
  examples, generated/reported behavior, and explicit non-claims.
- The matrix is reachable from [docs/book/src/SUMMARY.md](docs/book/src/SUMMARY.md)
  and advertised through the public ISF `live_document_paths` manifest surface.
- Added
  [t/1305-isf-book-feature-matrix-audit.t](t/1305-isf-book-feature-matrix-audit.t)
  to prevent support-matrix drift.
- No parser, scheduler, report payload, generated `.fsm`, or HDL behavior
  changed.

## 2026-05-16: R14 — ISF repeat-body documentation truth synchronized
- Completed R14 task-tree slice:
  `ISF-REPEAT-BODY-DOC-TRUTH-SYNC.1` in
  [docs/tasks/ISF-REPEAT-BODY-DOC-TRUTH-SYNC.md](docs/tasks/ISF-REPEAT-BODY-DOC-TRUTH-SYNC.md).
- The `ISF-REPEAT-BODY-DOC-TRUTH-SYNC` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create a
  new task tree first.
- The book/spec/handoff/public-contract docs now list the shipped repeat-body
  subset, including `set`, actor-owned bank `store`/`load`, and shipped `wait`
  clauses, while keeping child activation, await-sync, stage, contract, and
  nested loop forms deferred.
- Added
  [t/1304-isf-repeat-body-doc-truth-audit.t](t/1304-isf-repeat-body-doc-truth-audit.t)
  to prevent repeat-body doc drift.
- No parser, scheduler, report, generated `.fsm`, or HDL behavior changed.

## 2026-05-16: R14 — ISF public live book paths advertised
- Completed R14 task-tree slice:
  `ISF-LIVE-BOOK-DOCUMENT-PATHS.1` in
  [docs/tasks/ISF-LIVE-BOOK-DOCUMENT-PATHS.md](docs/tasks/ISF-LIVE-BOOK-DOCUMENT-PATHS.md).
- The `ISF-LIVE-BOOK-DOCUMENT-PATHS` tree is now closed. No active ISF task
  tree remains open; the next R14 implementation slice must select or create a
  new task tree first.
- The public ISF contract and manifest now advertise every Intent Scheduling
  mdBook chapter from [docs/book/src/SUMMARY.md](docs/book/src/SUMMARY.md),
  plus the canonical feature backlog and reference map, through
  `live_document_paths`.
- Added
  [t/1303-isf-public-live-book-paths-audit.t](t/1303-isf-public-live-book-paths-audit.t)
  to prevent summary/manifest drift.
- No syntax, lowering, scheduled `.fsm`, schedule JSON payload, or HDL output
  changed.

## 2026-05-16: R14 — ISF type/enum/aggregate parity tree closed
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.49` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The `ISF-TYPE-AGGREGATE-PARITY` tree is now closed. No active ISF task tree
  remains open; the next R14 implementation slice must select or create a new
  task tree first.
- Added
  [docs/book/src/13j-type-enum-aggregate.md](docs/book/src/13j-type-enum-aggregate.md)
  as the self-contained mdBook page for shipped ISF type aliases, enum member
  contexts, aggregate storage carriers, scalar aggregate leaf contexts, review
  artifacts, diagnostics, and explicit deferrals.
- Remaining enum target/operator-position and aggregate carrier/subaggregate
  work is future task-tree-owned backlog.

## 2026-05-16: R14 — ISF aggregate standalone rule guards shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.48` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.49`, selecting the
  next enum or aggregate value/update context after aggregate standalone rule
  guards.
- Rule guard scalar values now accept scalar aggregate storage leaves in
  shorthand and long-form `when` rule syntax.
- Scheduled `.fsm` rule review artifacts preserve those guards as guarded
  non-state DT header suffixes such as `<frame.flag`.
- Unknown aggregate paths, out-of-range indexes, and subaggregate guards fail
  closed; aggregate paths in expression operator position remain deferred.

## 2026-05-16: R14 — ISF enum standalone rule guards shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.47` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.48`, selecting the
  next enum or aggregate value/update context after enum standalone rule
  guards.
- Rule guard scalar values now accept local and package enum members in
  shorthand and long-form `when` rule syntax.
- Scheduled `.fsm` rule review artifacts preserve those guards as guarded
  non-state DT header suffixes such as `<mode.BUSY`.
- Unknown enum members fail closed; expression operator-position enum members
  and enum targets remain deferred.

## 2026-05-16: R14 — ISF enum standalone conditions shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.46` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.47`, selecting the
  next enum or aggregate value/update context after enum standalone
  transaction conditions.
- Transaction `when`/`while`/`until` scalar conditions now accept local and
  package enum members and emit computed `.fsm` selector review artifacts.
- Unknown enum members fail closed; expression operator-position enum members
  and enum targets remain deferred.
- The ISF regression tier now covers the 13xx test band.

## 2026-05-16: R14 — ISF aggregate standalone conditions shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.45` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.46`, selecting the
  next enum or aggregate value/update context after aggregate standalone
  transaction conditions.
- Transaction `when`/`while`/`until` scalar conditions now accept scalar
  aggregate storage leaves and emit computed `.fsm` selector review artifacts.
- Subaggregate standalone conditions fail closed.

## 2026-05-16: R14 — ISF aggregate inline drive targets shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.44` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.45`, selecting the
  next enum or aggregate value/update context after aggregate inline drive
  targets.
- Inline drive targets now accept scalar aggregate storage leaves and preserve
  them in scheduled `.fsm` state-assignment review artifacts.
- Subaggregate inline drive targets fail closed.

## 2026-05-16: R14 — ISF aggregate named drive targets shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.43` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.44`, selecting the
  next enum or aggregate value/update context after aggregate named drive
  targets.
- Named drive body targets now accept scalar aggregate storage leaves and
  preserve them in scheduled `.fsm` drive DT review artifacts.
- Subaggregate drive targets and inline drive targets fail closed.

## 2026-05-16: R14 — ISF aggregate rule targets shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.42` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.43`, selecting the
  next enum or aggregate value/update context after aggregate rule targets.
- Rule assignment targets now accept scalar aggregate storage leaves in both
  explicit `set` and shorthand rule assignment forms.
- Subaggregate rule targets, enum rule targets, and aggregate drive/inline
  drive targets fail closed.

## 2026-05-16: R14 — ISF enum switch selectors shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.41` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.42`, selecting the
  next enum or aggregate value/update context after enum switch selectors.
- Transaction `switch` selectors now accept local and package enum members and
  emit computed `.fsm` selector review artifacts such as `?(mode.BUSY)`.
- Standalone enum conditions, enum targets, and expression operator-position
  enum members fail closed.

## 2026-05-16: R14 — ISF aggregate switch selectors shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.40` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.41`, selecting the
  next enum or aggregate value/update context after aggregate switch selectors.
- Transaction `switch` selectors now accept scalar aggregate storage leaves and
  emit computed `.fsm` selector review artifacts such as `?(frame.mode)`.
- Enum switch selectors and subaggregate selectors or branch values fail closed.

## 2026-05-16: R14 — ISF aggregate switch branch values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.39` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.40`, selecting the
  next enum or aggregate value/update context after aggregate switch branch
  values.
- Transaction `switch` branch scalar values now accept scalar aggregate storage
  leaves and preserve authored branch-value tokens in scheduled `.fsm` switch
  review artifacts.
- Switch selectors and subaggregate branch values fail closed.

## 2026-05-16: R14 — ISF aggregate inline drive RHS expression operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.38` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.39`, selecting the
  next enum or aggregate value/update context after inline drive aggregate RHS
  expression operands.
- Inline drive assignment RHS expressions now accept scalar aggregate storage
  leaves as operands and preserve authored expression payloads in scheduled
  `.fsm` state assignments.
- Inline drive targets, operator-position aggregate paths, and subaggregate
  operands fail closed.

## 2026-05-16: R14 — ISF aggregate inline drive RHS values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.37` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.38`, selecting the
  next enum or aggregate value/update context after inline drive aggregate RHS
  values.
- Inline drive assignment scalar RHS values now accept scalar aggregate storage
  leaves and preserve authored RHS tokens in scheduled `.fsm` state
  assignments.
- This direct-value slice left inline drive RHS expression operands and
  subaggregate RHS values to follow-on work; `.38` now ships the bounded
  expression-operand context.

## 2026-05-16: R14 — ISF aggregate named drive-call actual expression operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.36` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.37`, selecting the
  next enum or aggregate value/update context after named drive-call aggregate
  actual expression operands.
- Named drive-call actual expressions now accept scalar aggregate storage
  leaves as operands and preserve authored expression payloads in scheduled
  `.fsm` drive-parameter assignments.
- Operator-position aggregate paths, subaggregate operands, and inline drive
  assignment aggregates fail closed.

## 2026-05-16: R14 — ISF aggregate named drive-call actual values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.35` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.36`, selecting the
  next enum or aggregate value/update context after named drive-call aggregate
  actual values.
- Named drive-call scalar actual values now accept scalar aggregate storage
  leaves and preserve authored actual tokens in scheduled `.fsm`
  drive-parameter assignments.
- This direct-value slice left drive-call actual expressions, inline drive
  assignment aggregate contexts, and subaggregate actual values to follow-on
  leaves; newer entries above record the bounded contexts that now ship.

## 2026-05-16: R14 — ISF aggregate named drive RHS expression operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.34` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.35`, selecting the
  next enum or aggregate value/update context after named drive body aggregate
  RHS expression operands.
- Named drive body RHS expressions now accept scalar aggregate storage leaves
  as operands and preserve authored expression payloads in scheduled `.fsm`
  drive DTs.
- Operator-position aggregate paths, subaggregate operands, and aggregate drive
  targets fail closed.

## 2026-05-16: R14 — ISF aggregate named drive RHS values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.33` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.34`, selecting the
  next enum or aggregate value/update context after named drive body aggregate
  RHS values.
- Named drive body scalar RHS values now accept scalar aggregate storage leaves
  and preserve authored RHS tokens in scheduled `.fsm` drive DTs.
- Drive targets, drive RHS expression aggregate operands, and subaggregate RHS
  values fail closed.

## 2026-05-16: R14 — ISF aggregate transaction condition operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.32` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.33`, selecting the
  next enum or aggregate value/update context after transaction condition
  aggregate expression operands.
- Transaction `when`/`while`/`until` condition expressions now accept scalar
  aggregate storage leaves as operands and preserve authored condition payloads
  in scheduled `.fsm` computed-test selectors.
- Standalone aggregate conditions, operator-position aggregate paths, and
  subaggregate operands fail closed.

## 2026-05-16: R14 — ISF aggregate rule guard expression operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.31` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.32`, selecting the
  next enum or aggregate value/update context after rule guard aggregate
  expression operands.
- Rule guard expressions now accept scalar aggregate storage leaves as operands
  and preserve authored guard payloads in scheduled `.fsm` rule DT headers plus
  public `when` normalization.
- Standalone aggregate guards, operator-position aggregate paths, and
  subaggregate operands fail closed.

## 2026-05-16: R14 — ISF aggregate rule RHS expression operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.30` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.31`, selecting the
  next enum or aggregate value/update context after rule assignment RHS
  aggregate expression operands.
- Rule assignment RHS expressions now accept scalar aggregate storage leaves as
  operands and preserve authored expression payloads in guarded rule DTs and
  assignment provenance.
- Operator-position aggregate paths, subaggregate operands, and aggregate rule
  assignment targets fail closed.

## 2026-05-16: R14 — ISF aggregate rule RHS values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.29` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.30`, selecting the
  next enum or aggregate value/update context after rule assignment RHS
  aggregate leaf values.
- Rule assignment scalar RHS values now accept scalar aggregate storage leaves
  from declared actor-owned aggregate storage variables.
- Scheduled `.fsm` rule DTs and assignment provenance preserve authored
  aggregate leaf paths; rule assignment aggregate targets and RHS expression
  operands fail closed.

## 2026-05-16: R14 — ISF enum named drive RHS expression operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.28` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.29`, selecting the
  next enum or aggregate value/update context after named drive body RHS
  expression operands.
- Named drive body RHS expressions now accept local and package-qualified enum
  members as scalar operands and preserve authored expression payloads in
  generated drive DTs.
- Drive body expressions recursively substitute drive formals with generated
  payload signals; drive body RHS expression operator-position enum members and
  drive targets fail closed.

## 2026-05-16: R14 — ISF enum reusable-library use-site overrides shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.27` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.28`, selecting the
  next enum or aggregate value/update context after reusable-library use-site
  enum overrides.
- Reusable-library use-site parameter overrides now accept local and
  package-qualified enum members as scalar values and aggregate/list leaves.
- Those use-site enum members resolve to literal generated-top `?fsmc`
  parameter bindings and `library_uses[]` schedule-report values; unknown enum
  members and plain symbolic use-site values fail closed.

## 2026-05-16: R14 — ISF enum inline drive RHS expression operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.26` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.27`, selecting the
  next enum or aggregate value/update context after inline drive RHS expression
  enum operands.
- Inline transaction drive assignment RHS expressions now accept local and
  package-qualified enum members as scalar operands and preserve authored
  expression payloads in scheduled `.fsm` state assignments.
- Inline drive RHS expression operator-position enum members, inline drive
  targets, reusable-library use-site enum overrides, and broader non-shipped
  contexts remain deferred.

## 2026-05-16: R14 — ISF enum inline drive RHS values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.25` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.26`, selecting the
  next enum or aggregate value/update context after inline drive assignment RHS
  enum values.
- Inline transaction drive assignment RHS scalar values now accept local and
  package-qualified enum members and preserve authored RHS tokens in scheduled
  `.fsm` state assignments.
- Inline drive targets, inline drive RHS expressions, reusable-library
  use-site enum overrides, and broader non-shipped contexts remain deferred.

## 2026-05-16: R14 — ISF enum transaction aggregate parameter defaults shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.24` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.25`, selecting the
  next enum or aggregate value/update context after generated child transaction
  aggregate/list enum parameter defaults.
- Generated child transaction aggregate/list `(params ...)` defaults now accept
  local and package-qualified enum members as scalar leaves, preserve authored
  tokens in child `.fsm` `+params`, generated-composition child parameter
  summaries, and default instance bindings, and record resolved literal leaves
  internally for validation.
- Reusable-library use-site enum overrides, runtime signals, arbitrary
  expressions, and broader non-parameter value contexts remain deferred.

## 2026-05-16: R14 — ISF enum actor aggregate parameter defaults shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.23` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.24`, selecting the
  next enum or aggregate value/update context after actor aggregate/list enum
  parameter defaults.
- Actor-level aggregate/list `(params ...)` defaults now accept local and
  package-qualified enum members as scalar leaves, preserve authored tokens in
  scheduled `.fsm` `+params` and `actor_params[]`, and record resolved literal
  leaves internally for validation.
- Generated child transaction aggregate/list parameter enum leaves,
  reusable-library use-site enum overrides, transaction parameters, runtime
  signals, and arbitrary expressions remain deferred.

## 2026-05-16: R14 — ISF enum activation aggregate leaves shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.22` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.23`, selecting the
  next enum or aggregate value/update context after activation aggregate/list
  enum leaves.
- Aggregate/list activation parameter overrides on `spawn`, generated blocking
  `do`, and rule `trigger` now accept local and package-qualified enum members
  as scalar leaves, resolving them to literal generated-top and
  generated-composition report bindings.
- Reusable-library use-site enum overrides, aggregate/list parameter-default
  enum leaves, direct `(on ...)` activation overrides, and broader non-shipped
  value contexts remain deferred.

## 2026-05-16: R14 — ISF enum transaction condition operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.21` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.22`, selecting the
  next enum or aggregate value/update context after transaction condition enum
  expression operands.
- Transaction `when`/`while`/`until` condition expressions now accept local and
  package-qualified enum members as scalar operands, preserve authored
  computed-test condition expressions in scheduled `.fsm`, and pass strict CLI
  HDL generation.
- Standalone enum transaction conditions, expression operator-position enum
  members, switch selectors, set targets, and other non-shipped condition/value
  contexts remain deferred.

## 2026-05-16: R14 — ISF enum rule guard expression operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.20` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.21`, selecting the
  next enum or aggregate value/update context after rule guard enum expression
  operands.
- Shorthand and long-form rule guard expressions now accept local and
  package-qualified enum members as scalar operands, preserve authored guard
  expressions in scheduled `.fsm` rule DT headers, and pass strict CLI HDL
  generation.
- Standalone enum guards, expression operator-position enum members, rule
  targets, and other non-shipped rule enum contexts remain deferred.

## 2026-05-16: R14 — ISF enum rule assignment expression values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.19` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.20`, selecting the
  next enum or aggregate value/update context after rule assignment RHS enum
  expression operands.
- Explicit `(set port expr)` and shorthand `(port expr)` rule assignments now
  accept local and package-qualified enum members as scalar operands inside RHS
  expressions, preserve authored expression payloads in guarded scheduled
  `.fsm` rule DTs, and pass strict CLI HDL generation.
- Expression operator-position enum members, rule guards, rule targets, and
  other non-shipped rule enum contexts remain deferred.

## 2026-05-16: R14 — ISF enum rule assignment RHS values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.18` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.19`, selecting the
  next enum or aggregate value/update context after scalar rule assignment RHS
  enum values.
- Explicit `(set port value)` and shorthand `(port value)` rule assignments now
  accept local and package-qualified enum members as direct scalar RHS values,
  preserve authored tokens in guarded scheduled `.fsm` rule DTs, and pass strict
  CLI HDL generation.
- Rule guards, rule targets, enum members inside rule assignment RHS
  expressions, and other non-shipped rule enum contexts remain deferred.

## 2026-05-16: R14 — ISF enum activation parameter overrides shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.17` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.18`, selecting the
  next enum or aggregate value/update context after scalar activation override
  enum values.
- Scalar activation parameter overrides on `spawn`, generated blocking `do`, and
  rule `trigger` now accept local and package-qualified enum members while
  resolving them to literal generated-top `?fsmc` parameter bindings.
- Enum leaves inside aggregate/list activation overrides, reusable-library
  use-site overrides, direct `(on ...)` activation overrides, rules, conditions,
  selectors, and other non-shipped contexts remain deferred.

## 2026-05-16: R14 — ISF enum transaction parameter defaults shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.16` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.17`, selecting the
  next enum or aggregate value/update context after transaction parameter enum
  defaults.
- Generated child transaction scalar `(params ...)` defaults now accept local
  and package-qualified enum members while preserving authored tokens in child
  scheduled `.fsm` `+params` and generated-composition schedule-report
  parameter summaries/default bindings.
- Enum leaves inside aggregate/list transaction params, activation parameter
  overrides, reusable-library use-site overrides, rules, conditions,
  selectors, and other non-shipped contexts remain deferred.

## 2026-05-16: R14 — ISF enum actor parameter defaults shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.15` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.16`, selecting the
  next enum or aggregate value/update context after actor parameter enum
  defaults.
- Actor-level scalar `(params ...)` defaults now accept local and
  package-qualified enum members while preserving authored tokens in scheduled
  `.fsm` `+params` and `actor_params[]` schedule reports.
- Enum leaves inside aggregate/list actor params, transaction params,
  activation parameter overrides, reusable-library use-site overrides, rules,
  conditions, selectors, and other non-shipped contexts remain deferred.

## 2026-05-16: R14 — ISF enum drive-call expression values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.14` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.15`, selecting the
  next enum or aggregate value/update context after drive-call actual
  expression enum operands.
- Named drive-call actual expressions now accept local and package-qualified
  enum members as scalar operands while preserving authored expression
  payloads in generated drive-parameter assignments.
- Enum members in expression operator position, inline drive assignments,
  rules, conditions, switch selectors, set targets, parameters, and other
  non-shipped contexts remain deferred.

## 2026-05-16: R14 — ISF enum drive-call values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.13` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.14`, selecting the
  next enum or aggregate value/update context after drive-call scalar enum
  actual values.
- Named drive-call scalar actuals now accept local and package-qualified enum
  members while preserving authored values in generated drive-parameter
  assignments.
- Enum members in drive-call expression actuals, inline drive assignments,
  rules, conditions, switch selectors, set targets, parameters, and other
  non-shipped contexts remain deferred.

## 2026-05-16: R14 — ISF enum drive values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.12` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.13`, selecting the
  next enum or aggregate value/update context after drive body RHS enum
  values.
- Scalar drive body RHS values now accept local and package-qualified enum
  members while preserving authored values in generated drive DTs.
- Enum members in drive targets, drive-call actuals, rules, conditions,
  switch selectors, set targets, parameters, and other non-shipped contexts
  remain deferred.

## 2026-05-16: R14 — ISF enum switch branch values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.11` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.12`, selecting the
  next enum or aggregate value/update context after enum switch branch values.
- Transaction `switch` branch values now accept local and package-qualified
  enum members while preserving authored branch values in scheduled `.fsm`.
- Enum members in switch selectors, conditions, set targets, rules, drives,
  parameters, and other non-shipped contexts remain deferred.

## 2026-05-16: R14 — ISF enum set expression operands shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.10` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.11`, selecting the
  next enum or aggregate value/update context after enum set expression
  operands.
- Transaction `set` RHS expressions now accept local and package-qualified
  enum members as scalar operands while preserving authored expressions in
  scheduled `.fsm`.
- Enum members in expression operator position, conditions, set targets,
  rules, drives, parameters, and other non-transaction-set RHS contexts remain
  deferred.

## 2026-05-16: R14 — ISF direct enum set values shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.9` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.10`, selecting the
  next enum or aggregate value/update context after direct enum set values.
- Direct transaction `set` RHS scalar values now accept local and
  package-qualified enum member tokens while preserving the authored token in
  scheduled `.fsm`.
- Enum members inside expressions, conditions, set targets, rules, drives,
  parameters, and other non-direct-set RHS scalar contexts remain deferred.

## 2026-05-16: R14 — ISF aggregate storage leaf expression reads shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.8` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.9`, selecting the
  next enum or aggregate value/update context after aggregate expression
  operands.
- Transaction `set` RHS expressions now accept scalar record member and list
  item operands from declared actor-owned aggregate storage carriers.
- Operator-position aggregate paths, subaggregate operands, non-`set`
  aggregate expression contexts, and enum member references outside actor
  constants remain deferred.

## 2026-05-16: R14 — ISF aggregate storage leaf writes shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.7` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.8`, selecting the
  next enum or aggregate value/update context after scalar leaf writes.
- Direct transaction `set` targets now accept scalar record member and list
  item writes to declared actor-owned aggregate storage carriers.
- Subaggregate writes, aggregate paths inside broader expressions, aggregate
  interface/transaction/bank carriers, and enum member references outside
  actor constants remain deferred.

## 2026-05-16: R14 — ISF aggregate storage leaf reads shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.6` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.7`, selecting one
  aggregate update or value context after read-only leaf access.
- Transaction `set` RHS values now accept scalar record member and list item
  reads from declared actor-owned aggregate storage carriers.
- Partial aggregate writes, aggregate paths inside broader expressions, and
  aggregate leaf reads outside transaction `set` RHS remain deferred.

## 2026-05-16: R14 — ISF aggregate storage carriers shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.5` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.6`, implementing
  one declared aggregate leaf access context after storage carriers.
- Actor-owned storage variables now accept local and package aggregate
  `list`/`record` aliases, preserve the authored alias in scheduled `.fsm`
  `+size`, and expose bounded `inferred_storage[].type` / `type_kind`
  schedule-report metadata.
- Aggregate aliases on interface ports, transaction ports, storage banks,
  member/item paths, and partial aggregate updates remain deferred.

## 2026-05-16: R14 — ISF actor-constant enum members shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.4` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.5`, implementing
  one declared aggregate carrier after scalar alias and enum constant
  resolution.
- Actor constants now accept local enum members and package-qualified enum
  members. Authored tokens are preserved in scheduled `.fsm` `+constants` and
  schedule reports, while resolved non-negative integer values feed static
  waits and existing static activation-parameter overrides.
- Enum member references outside actor constants and typed aggregate carriers
  remain deferred.

## 2026-05-16: R14 — ISF scalar type aliases shipped
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.3` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.4`, implementing
  enum member references in one static scalar ISF value context.
- ISF now accepts actor-local `(types ...)`, package imports as `(imports
  (package NAME) ...)`, and explicit `(type NAME)` scalar aliases on
  width-bearing actor interface ports, transaction-local ports, and
  actor-owned storage entries.
- Lowered scheduled `.fsm` preserves `+types`, declaration-only `+enums`,
  `+import`, typed `+size`, and embedded imported package roots. Enum member
  value references and typed aggregate carriers remain backlog leaves.

## 2026-05-16: R14 — ISF enum/type source contract selected
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.2` in
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.3`, implementing
  the first scalar type-alias reference path for ISF width-bearing
  declarations.
- Selected future source forms: actor-local `(types ...)` / `(enums ...)`,
  `(imports (package NAME) ...)` for existing `.fsm` packages, and `(type
  NAME)` as the named-type option that is mutually exclusive with `(width N)`.
- Current compiler behavior is unchanged. The downstream handoff remains clear
  that those forms are not supported syntax until implementation and focused
  tests land.

## 2026-05-16: R14 — ISF enum/type/aggregate parity tree opened
- Completed R14 task-tree slice:
  `ISF-TYPE-AGGREGATE-PARITY.1`, opening
  [docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md](docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md).
- The active PNT frontier is now `ISF-TYPE-AGGREGATE-PARITY.2`, which must
  specify the ISF symbol-source contract before parser widening.
- Documented the current truth boundary: `.fsm` has package-backed
  constants/enums/type aliases and bounded aggregate typing; ISF does not yet
  accept enum declarations, type declarations, named type tokens in width
  slots, or typed aggregate carrier/update semantics.
- Synchronized the task-tree index, ISF spec, downstream handoff, public
  contract notes, mdBook backlog, roadmap, and live docs. No compiler behavior
  changed in this slice.

## 2026-05-16: R14 — ISF CDC fixture matrix hardened
- Completed R14 task-tree slice:
  `ISF-CDC-FIXTURE-MATRIX.1`, closing
  [docs/tasks/ISF-CDC-FIXTURE-MATRIX.md](docs/tasks/ISF-CDC-FIXTURE-MATRIX.md).
- Added [isf/clock_domain_dual_event_crossing.isf](isf/clock_domain_dual_event_crossing.isf),
  covering two opposite-direction acknowledged event crossings in one
  generated top.
- Extended [t/1247-isf-clock-domain-partition.t](t/1247-isf-clock-domain-partition.t)
  to prove both CDC children, bounded report metadata, CLI schedule JSON
  parity, and generated HDL.
- Synchronized the ISF spec, downstream handoff, public contract doc, mdBook,
  feature backlog, roadmap, and task-tree index. The slice adds fixture
  coverage only; no payload CDC, ordering semantics, or new crossing primitive
  shipped.

## 2026-05-16: R14 — ISF temporal contract assertions projected
- Completed R14 task-tree slice:
  `ISF-TEMPORAL-CONTRACT-ASSERTIONS.1`, closing
  [docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md](docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md).
- SystemVerilog generation for bounded eventual contracts now emits a
  verification-only assertion from the generated sticky fail bit under
  `` `ifndef SYNTHESIS``.
- Schedule JSON reports
  `temporal_contracts[].assertion_projection = systemverilog_sticky_fail`,
  and the public contract value family advertises that status.
- Verilog output remains assertion-free, and schedule reports continue to omit
  raw monitor equations and backend assertion text.

## 2026-05-16: R14 — ISF feature-backlog status labels synchronized
- Completed R14 task-tree slice:
  `ISF-FEATURE-BACKLOG-STATUS-SYNC.1`, closing
  [docs/tasks/ISF-FEATURE-BACKLOG-STATUS-SYNC.md](docs/tasks/ISF-FEATURE-BACKLOG-STATUS-SYNC.md).
- Corrected mdBook feature-backlog status labels for aggregate backlog items,
  temporal contracts, schedule JSON schema freeze, reusable libraries, and
  multi-clock/CDC semantics.
- Added [t/1256-feature-backlog-status-audit.t](t/1256-feature-backlog-status-audit.t)
  to lock the corrected labels and reject stale active-tree status wording.
- Parser, scheduler, schedule JSON, generated `.fsm`, public contract, and HDL
  behavior are unchanged.

## 2026-05-16: R14 — ISF schedule-report full schema frozen
- Completed R14 task-tree slice:
  `ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.1`, closing
  [docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md](docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md).
- The public ISF contract now advertises
  `schedule_report_full_schema_stable = true` for schedule JSON
  `schema_version: 1`.
- Direct contract, manifest, CLI manifest, and CLI manifest alias views all
  assert the stable schedule-report schema flag.
- Raw parser actor hashes and `LoweringIR` remain non-public full APIs, and
  future report changes still follow the documented evolution policy.

## 2026-05-16: R14 — ISF schedule-report golden matrix shipped
- Completed R14 task-tree slice:
  `ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.1`, closing
  [docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md](docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md).
- Added [t/1255-isf-schedule-report-golden-matrix.t](t/1255-isf-schedule-report-golden-matrix.t)
  as the executable matrix for advertised schedule-report branches.
- Each matrix case runs through both in-process and CLI schedule-report paths
  and must emit equal payloads.
- Every advertised `schedule_report_*` contract branch except
  `schedule_report_full_schema_stable` now has a matrix owner.
- That slice deliberately left `schedule_report_full_schema_stable` unchanged;
  the later full-schema-freeze slice flips it for schedule JSON
  `schema_version: 1`.

## 2026-05-16: R14 — ISF schedule-report summary boundary documented
- Completed R14 task-tree slice:
  `ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.1`, closing
  [docs/tasks/ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.md](docs/tasks/ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.md).
- ISF spec, downstream handoff, public contract doc, and mdBook now state that
  raw assignment provenance, private assignment indexes, activation proof
  internals, and recursive child report dumps remain private.
- Public consumers should use bounded summary arrays and counts, the
  lower-result `files` map, named generated artifacts, `generated_composition`,
  `library_uses[]`, and `clock_domains[]` / `crossings[]`.
- The assignment-provenance/multi-file child summary decision is no longer an
  open whole-schema freeze blocker; the golden fixture matrix remains.
- Schedule JSON payloads, parser, scheduler, generated `.fsm`, and HDL output
  are unchanged.

## 2026-05-16: R14 — ISF schedule-report evolution policy documented
- Completed R14 task-tree slice:
  `ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.1`, closing
  [docs/tasks/ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.md](docs/tasks/ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.md).
- ISF spec, downstream handoff, public contract doc, and mdBook now define
  additive and breaking schedule-report change rules.
- Additive changes require same-slice public contract metadata, focused tests,
  and docs; breaking changes require a `schema_version` bump plus migration or
  deprecation documentation.
- Additive/deprecation policy is no longer an open whole-schema freeze blocker.
- Schedule JSON payloads, parser, scheduler, generated `.fsm`, and HDL output
  are unchanged.

## 2026-05-16: R14 — ISF schedule-report schema version shipped
- Completed R14 task-tree slice:
  `ISF-SCHEDULE-REPORT-SCHEMA-VERSION.1`, closing
  [docs/tasks/ISF-SCHEDULE-REPORT-SCHEMA-VERSION.md](docs/tasks/ISF-SCHEDULE-REPORT-SCHEMA-VERSION.md).
- In-process and CLI schedule JSON reports now include top-level
  `schema_version: 1`.
- The ISF public contract advertises `schema_version` in
  `schedule_report_top_level_keys`; this report payload version is separate
  from `embedding.isf_public_interface.schema_version`.
- Updated focused report tests plus the ISF spec, downstream handoff, public
  contract doc, mdBook, roadmap, and live docs.
- Lowering semantics, generated `.fsm`, and HDL output are unchanged.

## 2026-05-16: R14 — ISF generated-name stability policy documented
- Completed R14 task-tree slice:
  `ISF-GENERATED-NAME-POLICY.1`, closing
  [docs/tasks/ISF-GENERATED-NAME-POLICY.md](docs/tasks/ISF-GENERATED-NAME-POLICY.md).
- ISF spec, downstream handoff, public contract doc, and mdBook now state that
  generated names are deterministic for the same source and FSMGen version and
  may be used as report-local/artifact-local identifiers when public fields
  explicitly reference them.
- The docs also state generated names are not a semantic string grammar;
  downstream consumers should use bounded metadata fields instead of parsing
  generated spelling.
- Generated-name stability is no longer an open whole-schema freeze blocker.
- Parser, scheduler, report payload, public manifest, generated `.fsm`, and
  HDL behavior are unchanged.

## 2026-05-16: R14 — ISF resource backlog truth synchronized
- Completed R14 task-tree slice:
  `ISF-RESOURCE-BACKLOG-TRUTH-SYNC.1`, closing
  [docs/tasks/ISF-RESOURCE-BACKLOG-TRUTH-SYNC.md](docs/tasks/ISF-RESOURCE-BACKLOG-TRUTH-SYNC.md).
- Corrected the canonical mdBook feature backlog so scalar authoring no longer
  carries resource-arbitration status text.
- Corrected the enforced-resource-arbitration item to say the
  `rule_slot`/`priority` subset is partially shipped while broader resource
  kinds and arbiters remain backlog.
- Clarified that resource-grant/debug storage is still deferred because
  shipped arbitration reports static `resource_arbitration[]` summaries and
  guard lowering rather than materialized grant storage.
- Parser, scheduler, report payload, public manifest, generated `.fsm`, and
  HDL behavior are unchanged.

## 2026-05-16: R14 — ISF activation handshake storage roles shipped
- Completed R14 task-tree slice:
  `ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.1`, closing
  [docs/tasks/ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.md](docs/tasks/ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.md).
- Public schedule JSON now tags generated activation start handoff storage
  with `inferred_storage[].role = activation_start_handoff` when that one-bit
  handoff appears in `inferred_storage[]`.
- Public schedule JSON now tags generated activation done handoff storage with
  `inferred_storage[].role = activation_done_handoff`.
- The ISF public contract and capability manifest advertise both roles through
  `schedule_report_storage_role_values`.
- Extended [t/1148-isf-public-storage-metadata-audit.t](t/1148-isf-public-storage-metadata-audit.t)
  with generated spawn and generated rule-trigger handoff probes.
- Activation syntax, generated child instantiation, start/done timing,
  generated `.fsm`, and HDL output are unchanged.

## 2026-05-16: R14 — ISF rule-trigger storage roles shipped
- Completed R14 task-tree slice:
  `ISF-RULE-TRIGGER-STORAGE-REPORTS.1`, closing
  [docs/tasks/ISF-RULE-TRIGGER-STORAGE-REPORTS.md](docs/tasks/ISF-RULE-TRIGGER-STORAGE-REPORTS.md).
- Public schedule JSON now tags rule-trigger source pulse storage with
  `inferred_storage[].role = rule_trigger_source`.
- Public schedule JSON now tags per-input rule-trigger payload-source storage
  with `inferred_storage[].role = rule_trigger_payload_source`.
- The ISF public contract and capability manifest advertise both roles through
  `schedule_report_storage_role_values`.
- Extended [t/1148-isf-public-storage-metadata-audit.t](t/1148-isf-public-storage-metadata-audit.t)
  with direct and generated rule-trigger report probes.
- Rule-trigger syntax, guard semantics, activation timing, generated `.fsm`,
  and HDL output are unchanged.

## 2026-05-16: R14 — ISF transaction-port storage role synchronized
- Completed R14 task-tree slice:
  `ISF-TRANSACTION-PORT-STORAGE-REPORTS.1`, closing
  [docs/tasks/ISF-TRANSACTION-PORT-STORAGE-REPORTS.md](docs/tasks/ISF-TRANSACTION-PORT-STORAGE-REPORTS.md).
- Public contract metadata now advertises `transaction_port` through
  `schedule_report_storage_role_values`, matching already-emitted
  transaction-local port storage roles.
- Extended [t/1148-isf-public-storage-metadata-audit.t](t/1148-isf-public-storage-metadata-audit.t)
  with a direct transaction-port report probe.
- Transaction port syntax, binding syntax, timing, generated `.fsm`, and HDL
  output are unchanged.

## 2026-05-16: R14 — ISF activation handoff storage roles synchronized
- Completed R14 task-tree slice:
  `ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.1`, closing
  [docs/tasks/ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.md](docs/tasks/ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.md).
- Public contract metadata now advertises `transaction_port_binding` and
  `trigger_done_observe` through `schedule_report_storage_role_values`,
  matching already-emitted generated activation handoff storage roles.
- Extended [t/1148-isf-public-storage-metadata-audit.t](t/1148-isf-public-storage-metadata-audit.t)
  with spawn and generated rule-trigger report probes.
- Generated activation lowering, generated-top wiring, rule-trigger timing,
  generated `.fsm`, and HDL output are unchanged.

## 2026-05-16: R14 — ISF dynamic-wait storage role contract synchronized
- Completed R14 task-tree slice:
  `ISF-DYNAMIC-WAIT-STORAGE-REPORTS.1`, closing
  [docs/tasks/ISF-DYNAMIC-WAIT-STORAGE-REPORTS.md](docs/tasks/ISF-DYNAMIC-WAIT-STORAGE-REPORTS.md).
- Public contract metadata now advertises `dynamic_wait_counter` through
  `schedule_report_storage_role_values`, matching the already-emitted runtime
  dynamic wait counter role in schedule JSON.
- Extended [t/1148-isf-public-storage-metadata-audit.t](t/1148-isf-public-storage-metadata-audit.t)
  with a runtime dynamic wait report fixture.
- Dynamic wait lowering, zero-bypass behavior, pending-sample behavior,
  generated `.fsm`, and HDL output are unchanged.

## 2026-05-16: R14 — ISF temporal-contract storage roles shipped
- Completed R14 task-tree slice:
  `ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.1`, closing
  [docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md](docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md).
- Public schedule JSON now tags temporal-contract monitor pending/fail
  registers and the age counter with `inferred_storage[].role =
  temporal_contract_monitor`.
- The ISF public contract and capability manifest advertise the role through
  `schedule_report_storage_role_values`.
- Added [t/1254-isf-temporal-contract-storage-report.t](t/1254-isf-temporal-contract-storage-report.t)
  for in-process and CLI report projection.
- Temporal-contract runtime behavior, monitor DT equations, reset behavior,
  generated `.fsm`, HDL output, and assertion projection are unchanged.

## 2026-05-16: R14 — ISF actor parameter reports shipped
- Completed R14 task-tree slice: `ISF-ACTOR-PARAM-REPORTS.1`, closing
  [docs/tasks/ISF-ACTOR-PARAM-REPORTS.md](docs/tasks/ISF-ACTOR-PARAM-REPORTS.md).
- Public schedule JSON now exposes actor-level `(params ...)` defaults through
  `actor_params[]`.
- Each entry exposes the parameter `name` and JSON-safe default `value`, with
  `schedule_report_actor_param_keys` advertised through the ISF public
  contract and capability manifest.
- Added [t/1253-isf-actor-param-report.t](t/1253-isf-actor-param-report.t)
  for in-process and CLI report projection.
- Actor parameters remain static specialization defaults, not runtime payloads;
  generated `.fsm` `+params` emission and override behavior are unchanged.

## 2026-05-16: R14 — ISF actor phase/stage metadata reports shipped
- Completed R14 task-tree slice:
  `ISF-ACTOR-PHASE-STAGE-REPORTS.1`, closing
  [docs/tasks/ISF-ACTOR-PHASE-STAGE-REPORTS.md](docs/tasks/ISF-ACTOR-PHASE-STAGE-REPORTS.md).
- Public schedule JSON now exposes parser-validated actor-level `(phase ...)`
  and `(stage ...)` metadata through `actor_phases[]` and `actor_stages[]`.
- Each entry exposes the authored `name` and JSON-safe list-form `body`, with
  key families advertised through the ISF public contract and capability
  manifest.
- Added [t/1252-isf-actor-phase-stage-report.t](t/1252-isf-actor-phase-stage-report.t)
  for in-process and CLI report projection.
- Actor-level phase/stage runtime semantics remain deferred; generated `.fsm`,
  generated composition tops, and HDL output are unchanged.

## 2026-05-16: R14 — downstream issue-bundle reporting flow published
- Completed R14 task-tree slice: `DOWNSTREAM-ISSUE-REPRO-FLOW.1`, closing
  [docs/tasks/DOWNSTREAM-ISSUE-REPRO-FLOW.md](docs/tasks/DOWNSTREAM-ISSUE-REPRO-FLOW.md).
- Added [docs/DOWNSTREAM_ISSUE_REPORTING.md](docs/DOWNSTREAM_ISSUE_REPORTING.md)
  as the strict, format-agnostic protocol for downstream FSMGen bug reports.
- Added [bin/fsmgen-issue-bundle](bin/fsmgen-issue-bundle), which creates a
  runnable local reproduction bundle and a rerunnable `commands.sh`.
- Added [t/1251-fsmgen-issue-bundle-helper.t](t/1251-fsmgen-issue-bundle-helper.t)
  to prove the helper and generated script work.
- Parser, scheduler, report payload, generated `.fsm`, and HDL behavior are
  unchanged.

## 2026-05-16: R14 — ISF spec focused-test index audited
- Completed R14 task-tree slice: `ISF-SPEC-TEST-INDEX-SYNC.1`, closing
  [docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md](docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md).
- Updated [docs/ISF_SPEC.md](docs/ISF_SPEC.md) so its focused-test list covers
  the current ISF regression files through `t/1250`.
- Added [t/1250-isf-spec-focused-test-index-audit.t](t/1250-isf-spec-focused-test-index-audit.t)
  to keep that list synchronized with `t/*-isf-*.t`.
- Parser, scheduler, report payload, generated `.fsm`, and HDL behavior are
  unchanged.

## 2026-05-16: R14 — ISF removed assign diagnostic truth synchronized
- Completed R14 task-tree slice:
  `ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.1`, closing
  [docs/tasks/ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.md](docs/tasks/ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.md).
- Corrected the canonical mdBook feature backlog so the removed transaction
  `(assign ...)` entry reflects the shipped targeted migration diagnostic.
- `(assign ...)` remains fail-closed and is not auto-mapped to accepted timing
  constructs; the diagnostic points authors to `(set ...)`, `(update ...)`,
  `(drive ...)`, rule assignments, or `(complete ...)`.
- Parser, scheduler, schedule-report, manifest, generated `.fsm`, and HDL
  behavior are unchanged.

## 2026-05-16: R14 — ISF actor-constant parameter overrides shipped
- Completed R14 task-tree slice: `ISF-PARAM-OVERRIDE-CONSTANTS.2`, closing
  [docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md](docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md).
- Spawn, generated blocking `do`, and rule-trigger activation `(params ...)`
  sites now accept actor-local constants as static override values.
- Constants resolve to literal values before generated-top emission, so
  generated tops and schedule reports continue to expose self-contained
  literal parameter override values through existing fields.
- Runtime signals, actor/transaction parameters, unknown names, and arbitrary
  expressions remain fail-closed.

## 2026-05-16: R14 — ISF actor-constant parameter override contract selected
- Completed R14 task-tree slice: `ISF-PARAM-OVERRIDE-CONSTANTS.1`.
- Opened [docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md](docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md)
  as the active owner for actor-local constants in activation parameter
  overrides.
- Selected the future source contract: actor constants may be used as scalar
  values, or scalar leaves in aggregate/list values, on generated activation
  `(params ...)` sites. They must resolve to literals before generated-top
  emission.
- Actor/transaction parameters, runtime signals, and arbitrary expressions
  remain out of scope for this tree.
- This slice is specification-only; compiler behavior is unchanged.
- The active frontier advances to `ISF-PARAM-OVERRIDE-CONSTANTS.2`.

## 2026-05-16: R14 — ISF feature backlog truth synchronized
- Completed R14 task-tree slice: `ISF-BACKLOG-TRUTH-SYNC.1`.
- Updated the canonical mdBook feature backlog so activation-parameter
  override status matches the closed `ISF-ACTIVATION-PARAM-OVERRIDES` tree.
- The backlog now states that spawn, blocking `do`, and rule-trigger parameter
  overrides are the shipped bounded activation-parameter surface, and direct
  `(on ...)` activation parameter syntax is unsupported and regression-covered
  as fail-closed.
- Parser, scheduler, schedule-report, manifest, and HDL behavior are
  unchanged by this documentation-truth slice.

## 2026-05-16: R14 — ISF downstream integration handoff published
- Completed R14 task-tree slice: `ISF-DOWNSTREAM-INTEGRATION-SPEC.1`.
- Added [docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md)
  as the single self-contained human integration contract for downstream
  `.isf` producers and consumers.
- The mdBook includes the same canonical handoff content through
  [docs/book/src/13i-downstream-integration.md](docs/book/src/13i-downstream-integration.md),
  so the book and handoff document cannot drift through duplicated prose.
- The handoff is now part of the ISF public synchronization invariant and the
  machine-readable public contract `live_document_paths`; future
  downstream-visible ISF changes must keep it synchronized with code, tests,
  live spec, book, public contract, manifest metadata, and deferrals.
- Parser, scheduler, schedule-report payload shape, and HDL behavior are
  unchanged by this slice.

## 2026-05-16: R14 — ISF activation parameter override tree closed
- Completed R14 task-tree slice: `ISF-ACTIVATION-PARAM-OVERRIDES.5`.
- Added focused regression coverage proving direct
  `(on start (params ...))` fails closed as an unsupported `(on ...)` body
  form before scheduled artifacts are emitted.
- The existing scheduler boundary remains unchanged: direct `(on ...)`
  activation accepts only `(sample port as name)` nested body clauses; static
  per-activation specialization belongs on generated activation forms.
- The `ISF-ACTIVATION-PARAM-OVERRIDES` tree is now closed. The next requested
  R14 work is a single self-contained downstream integration specification for
  `.isf`, which needs a fresh task-tree owner before implementation.

## 2026-05-16: R14 — ISF direct activation parameter boundary specified
- Completed R14 task-tree slice: `ISF-ACTIVATION-PARAM-OVERRIDES.4`.
- Direct `(on ...)` activation is specified as fail-closed for activation-site
  `(params ...)`. `(on start (params ...))` is not public syntax and must not
  specialize hardware or create runtime parameter assignment semantics.
- The boundary is intentional: `(on ...)` is the transaction's own entry guard,
  not a caller-owned generated activation instance. Transaction-local `params`
  remain definition defaults.
- Runtime-varying entry values should use transaction ports, `(sample ...)`,
  or supported activation-site `(bind ...)` payloads. Static per-activation
  specialization belongs on generated activation forms such as `spawn`,
  parameterized blocking `do`, and parameterized rule `trigger`.
- This slice is specification-only. Compiler behavior, accepted syntax,
  report shape, and HDL output are unchanged.
- The active frontier advances to `ISF-ACTIVATION-PARAM-OVERRIDES.5`,
  implementing or test-closing the direct activation parameter boundary.

## 2026-05-16: R14 — ISF rule-trigger parameter overrides shipped
- Completed R14 task-tree slice: `ISF-ACTIVATION-PARAM-OVERRIDES.3`.
- Rule actions now accept
  `(trigger transaction (params (NAME value) ...) (bind ...))` for static
  transaction parameter specialization.
- Parameterized rule triggers lower through generated child activation
  instances named `{rule}_{transaction}_trigger_{ordinal}`. The generated top
  applies overrides through `?fsmc` params and wires explicit start/input/done
  handoffs.
- Existing rule-trigger pulse and input payload timing are preserved. The
  generated child `done` handoff is wired for composition consistency but does
  not make the rule wait for completion.
- Schedule JSON reports trigger activations with
  `activation_kind => trigger` and parameter binding provenance. At this
  historical slice output bindings remained unsupported; later R14 slices
  shipped the generated-child subset while keeping direct/local targets
  deferred.
- The active frontier advances to `ISF-ACTIVATION-PARAM-OVERRIDES.4`,
  specifying the direct transaction activation parameter boundary.

## 2026-05-16: R14 — ISF rule-trigger parameter override contract selected
- Completed R14 task-tree slice: `ISF-ACTIVATION-PARAM-OVERRIDES.2`.
- The selected future source shape is
  `(trigger transaction (params (NAME value) ...) (bind ...))`; `(params ...)`
  remains static specialization, and `(bind ...)` remains runtime payload.
- The selected lowering strategy is one generated child activation instance
  per lexical parameterized trigger site, named
  `{rule}_{transaction}_trigger_{ordinal}` and specialized through generated
  top `?fsmc` params.
- The implementation must preserve current rule-trigger pulse and input
  payload timing through generated handoff DTs. At this selection point
  rule-trigger output bindings remained unsupported; later R14 slices shipped
  generated-child rule-trigger output bindings while keeping direct/local
  targets deferred.
- This slice is specification-only. Compiler behavior, accepted public syntax,
  report shape, and HDL output are unchanged.
- The active frontier advances to `ISF-ACTIVATION-PARAM-OVERRIDES.3`,
  implementing rule-trigger parameter overrides.

## 2026-05-16: R14 — ISF activation parameter override tree opened
- Completed R14 task-tree slice: `ISF-ACTIVATION-PARAM-OVERRIDES.1`.
- [docs/tasks/ISF-ACTIVATION-PARAM-OVERRIDES.md](docs/tasks/ISF-ACTIVATION-PARAM-OVERRIDES.md)
  is now the active owner for rule-trigger parameter overrides and the direct
  transaction activation parameter boundary.
- This slice changes workflow state only. Compiler behavior, public syntax,
  report shape, and HDL output are unchanged.
- The active frontier advances to `ISF-ACTIVATION-PARAM-OVERRIDES.2`,
  specifying the rule-trigger parameter override lowering contract before
  scheduler edits.

## 2026-05-15: R14 — ISF multi-domain event CDC HDL shipped
- Completed R14 task-tree slice: `ISF-CLOCK-DOMAINS.7`.
- Plain multi-domain `.isf` HDL generation now emits the generated
  multi-domain top and a concrete acknowledged-event CDC child for accepted
  event-crossing actors on SystemVerilog/Verilog-family targets when each
  emitted domain artifact satisfies the current scheduled `.fsm` clock/reset
  HDL contract.
- The generated CDC child is selected by explicit ISF-generated `.rtlif`
  metadata; ordinary external `?rtl` modules remain externally supplied.
- The generated top now relies on composition system-port auto-wiring for
  same-name domain clock/reset connections and keeps explicit links for the
  differently named CDC child clock/reset ports.
- `ISF-CLOCK-DOMAINS` is now closed; the next PNT selection should choose the
  next roadmap-aligned R14 task outside this tree.

## 2026-05-15: R14 — ISF multi-domain reports and fixtures shipped
- Completed R14 task-tree slice: `ISF-CLOCK-DOMAINS.6`.
- Public multi-domain schedule JSON now projects the generated top scope,
  domain-local artifact summaries through `clock_domains[]`, and accepted
  event crossing metadata through `crossings[]`.
- Added a realistic event-crossing fixture and regression coverage proving CLI
  `--emit-schedule-json` parity plus supported HDL generation for emitted
  single-domain artifacts.
- At that point, plain multi-domain generated HDL remained blocked for
  `ISF-CLOCK-DOMAINS.7`; it is now shipped by the newer entry above.
- At that point, the active frontier advanced to `ISF-CLOCK-DOMAINS.7`; that
  path is now shipped by the newer entry above.

## 2026-05-15: R14 — ISF multi-domain top artifacts emitted
- Completed R14 task-tree slice: `ISF-CLOCK-DOMAINS.5.4`.
- Public multi-domain `lower(...)` now emits `<actor>_top.fsm`, instantiating
  each domain module and explicit CDC child interfaces for accepted event
  crossings.
- Parser support now includes actor-scoped `(crossings ...)` event
  declarations for the acknowledged single-bit event primitive.
- Public `report(...)` and generated HDL for the multi-domain top/CDC path
  remain blocked for `ISF-CLOCK-DOMAINS.6`.
- The active frontier advances to `ISF-CLOCK-DOMAINS.6`, diagnostics,
  reports, and fixtures for multi-clock behavior.

## 2026-05-15: R14 — ISF domain scheduled artifacts emitted
- Completed R14 task-tree slice: `ISF-CLOCK-DOMAINS.5.3`.
- Public multi-domain `lower(...)` now emits one domain-local scheduled `.fsm`
  artifact per declared domain, named `<actor>__domain_<domain>.fsm`.
- Domain artifacts use the domain clock/reset and contain only domain-local
  ports, storage, transactions, rules, and generated helper signals.
- Public `report(...)`, generated multi-domain top wiring, and CDC artifacts
  remain blocked for later leaves.
- The active frontier advances to `ISF-CLOCK-DOMAINS.5.4`, generated
  multi-domain top and event-crossing artifact emission.

## 2026-05-15: R14 — ISF clock-domain partitioning handoff shipped
- Completed R14 task-tree slice: `ISF-CLOCK-DOMAINS.5.2`.
- Parser accepts selected `(clock-domains ...)` metadata and `(domain NAME)`
  ownership annotations for ports, storage, transactions, rules, reusable
  `use` instances, and generated child activations.
- `LoweringIR` groups accepted sources by declared domain and rejects direct
  unowned cross-domain references before emission.
- Single-domain `(clock-domains ...)` sources still lower through the existing
  single-clock path. Multi-domain `lower(...)` and `report(...)` validate the
  partition, then reject until domain artifacts and report projection ship.
- The active frontier advances to `ISF-CLOCK-DOMAINS.5.3`,
  domain-specific scheduled `.fsm` emission.

## 2026-05-15: R14 — ISF clock-domain lowering artifacts selected
- Completed R14 task-tree slice: `ISF-CLOCK-DOMAINS.5.1`.
- Future multi-domain lowering emits one normal single-clock scheduled `.fsm`
  artifact per domain, named `<actor>__domain_<domain>.fsm`.
- Generated top wiring and acknowledged event CDC logic are explicit generated
  artifacts, not hidden multi-clock behavior inside ordinary scheduled `.fsm`
  modules.
- This was specification-only; parser/lowering behavior is unchanged.
- The active frontier advances to `ISF-CLOCK-DOMAINS.5.2`,
  domain-partitioning IR handoff.

## 2026-05-15: R14 — ISF event crossing primitive selected
- Completed R14 task-tree slice: `ISF-CLOCK-DOMAINS.4`.
- The first future legal CDC primitive is an acknowledged single-bit event
  channel in actor-scoped `(crossings ...)` source.
- It has source-domain event request, generated source-domain `ready`,
  generated destination-domain one-cycle pulse, one outstanding event, and no
  payload.
- Direct cross-domain reads, writes, triggers, activations, child bindings, and
  reset assertion/deassertion events remain fail-closed unless a shipped
  primitive owns that path.
- This was specification-only; parser/lowering behavior is unchanged.
- The active frontier advances to `ISF-CLOCK-DOMAINS.5`, lowering artifacts.

## 2026-05-15: R14 — ISF clock-domain reset ownership selected
- Completed R14 task-tree slice: `ISF-CLOCK-DOMAINS.3`.
- Future multi-domain reset ownership lives inside `(clock-domains ...)`
  domain entries. Existing actor-level `(reset ...)` remains the shipped
  single-domain shorthand.
- Each future domain owns zero or one reset. Synchronous resets are sampled on
  the owning domain clock; asynchronous resets are direct external reset pins,
  not DT-generated reset trees.
- This was specification-only; parser/lowering behavior is unchanged.
- The active frontier advances to `ISF-CLOCK-DOMAINS.4`, cross-domain
  interaction primitives.

## 2026-05-15: R14 — ISF clock-domain source model selected
- Completed R14 task-tree slice: `ISF-CLOCK-DOMAINS.2`.
- [docs/tasks/ISF-CLOCK-DOMAINS.md](docs/tasks/ISF-CLOCK-DOMAINS.md) is now
  active with current frontier `ISF-CLOCK-DOMAINS.3`.
- The future source model is actor-scoped named domains through an
  unimplemented `(clock-domains ...)` block. Existing `(clock name)` remains
  the only accepted clock syntax.
- Ports, storage, transactions, rules, and child instances may reference only
  actor-declared domains or inherit the default; drives inherit their
  activation-site domain.
- Direct unowned cross-domain reads, writes, triggers, activations, and
  bindings remain fail-closed until a legal CDC primitive ships.

## 2026-05-15: R14 — ISF public contract synchronization tree closed
- Completed R14 task-tree slice: `ISF-PUBLIC-CONTRACT.4`.
- `embedding.isf_public_interface.guidance` now says feature-driven public ISF
  changes must move matching public contract and manifest audit tests in the
  same implementation slice.
- [t/1142-isf-public-guidance-metadata-audit.t](t/1142-isf-public-guidance-metadata-audit.t),
  [docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](docs/ISF_PUBLIC_INTERFACE_CONTRACT.md),
  and [docs/book/src/13-intent-scheduling.md](docs/book/src/13-intent-scheduling.md)
  were updated with the same rule.
- [docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md](docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md)
  is now closed and moved to the completed task-tree table.
- No active PNT-eligible R14 task tree remains until a proposed tree is
  activated or a fresh task tree is selected.

## 2026-05-15: R14 — ISF synchronization checklist applied to active workflow
- Completed R14 task-tree slice: `ISF-PUBLIC-CONTRACT.3`.
- [docs/TASK_TREE.md](docs/TASK_TREE.md) now requires every ISF feature leaf to
  inspect the reusable synchronization checklist and record its selected public
  sync scope.
- [docs/book/src/90-reference-map.md](docs/book/src/90-reference-map.md) now
  points to the task-tree workflow and checklist as focused workflow
  references.
- This was documentation-only; compiler behavior is unchanged.
- The active R14 frontier advances to `ISF-PUBLIC-CONTRACT.4`.

## 2026-05-15: R14 — ISF public contract synchronization checklist
- Completed R14 task-tree slice: `ISF-PUBLIC-CONTRACT.2`.
- [docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md](docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md)
  now defines the reusable feature-slice checklist for public ISF surface
  classification, spec/book sync, contract/manifest alignment, test gate
  selection, live-doc updates, and commit recovery hygiene.
- This was documentation-only; compiler behavior is unchanged.
- The active R14 frontier advances to `ISF-PUBLIC-CONTRACT.3`, applying the
  checklist to active ISF task trees.

## 2026-05-15: R14 — ISF public contract owner inventory
- Completed R14 task-tree slice: `ISF-PUBLIC-CONTRACT.1`.
- [docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md](docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md)
  now lists the written docs, mdBook chapters, parser/scheduler/emitter
  owners, contract/manifest owners, public test families, and live-doc
  touchpoints that must stay synchronized for ISF feature work.
- This was documentation-only; compiler behavior is unchanged.
- The active R14 frontier advances to `ISF-PUBLIC-CONTRACT.2`, the reusable
  feature-slice synchronization checklist.

## 2026-05-15: R14 — ISF runtime expression wait counts
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.6`.
- Runtime wait counts can now be known-width non-empty list expressions, not
  only scalar count signals.
- Positive paths snapshot the normalized expression into the generated wait
  counter on the predecessor edge; zero paths compare the same expression
  against zero and bypass the wait state.
- `transaction_waits[]` reports expression counts as `runtime_expression` with
  null `cycles`, normalized `count_source`, and generated counter metadata.
- Unknown-width/malformed expressions remained fail-closed at that slice.
  Actor-parameter-backed static counts later shipped under
  `ISF-PARAM-WAIT-COUNTS.1`. `ISF-DYNAMIC-WAIT` is closed.

## 2026-05-15: Bootstrap — import tree snapshot refreshed
- Re-ran the README/session-bootstrap import-tree sanity pass.
- Refreshed [docs/BIN_FSMGEN_IMPORT_TREE.md](docs/BIN_FSMGEN_IMPORT_TREE.md)
  to the current source-derived snapshot: `195` reachable project files and
  `194` reachable `.pm` packages from [bin/fsmgen](bin/fsmgen).
- The refreshed note records the serializable plan/report support family, the
  ISF generated composition-top emitter, and the R14 `LoweringIR` growth as
  the largest active feature-owner hotspot.
- This changes no compiler behavior and leaves the active R14 frontier at
  `ISF-DYNAMIC-WAIT.3.3.6`, expression-valued runtime wait counts.

## 2026-05-15: R14 — ISF repeat and loop runtime wait pending samples
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.5.4`.
- `repeat`, `while`, and `until` bodies can now preserve pending samples
  across runtime wait positive and zero paths for sample-compatible body
  successors.
- Positive paths sample once in the first active wait state and continue counts
  greater than one through a no-resample wait loop.
- Zero paths use sample-preserving clones while repeat check loop-back/exit,
  `while` false exits, and `until` true exits remain unchanged.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.6`, expression-valued
  runtime wait counts.

## 2026-05-15: R14 — ISF branch runtime wait pending samples
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.5.3`.
- `when` bodies and `switch` branches can now preserve pending samples across
  runtime wait positive and zero paths for sample-compatible selected
  successors.
- Positive paths sample once in the first active wait state and continue counts
  greater than one through a no-resample wait loop.
- Zero paths use sample-preserving clones, while `when` false exits, other
  switch cases, and implicit switch fallthrough remain unchanged.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.5.4`, repeat/loop
  runtime wait pending-sample preservation.

## 2026-05-15: R14 — ISF top-level runtime wait pending samples
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.5.2`.
- Top-level runtime waits can now follow pending samples.
- Positive counts materialize samples once in the first active wait state, then
  counts greater than one continue through a generated no-resample wait-loop
  state.
- Runtime zero counts bypass to a sample-preserving clone of the following
  state-producing clause when that state can carry samples without changing
  timing, preserving `wait 0` timing for the shipped subset.
- Other top-level successors remain fail-closed until their materialization
  rule is explicit.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.5.3`, branch runtime
  wait pending-sample preservation.

## 2026-05-15: R14 — ISF pending-sample dynamic wait split
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.5.1`.
- Split active task-tree node `ISF-DYNAMIC-WAIT.3.3.5` into executable
  pending-sample preservation leaves.
- Runtime `count == 0` must not introduce a hidden sample-only cycle.
- Positive-count paths should materialize pending samples in the first active
  wait state; zero-count paths should materialize them in the next
  state-producing clause.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.5.2`, top-level
  runtime wait pending-sample preservation.

## 2026-05-15: R14 — ISF loop-body dynamic waits
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.4.5`.
- Runtime scalar waits in `while` and `until` bodies now lower for the
  no-pending-sample subset.
- `while` entry/back-edge true paths load/enter or bypass the body wait, while
  false paths still exit.
- `until` true paths still exit, while false back-edges reload/enter or bypass
  the body wait for the next iteration.
- Loop decision exits can now split a following runtime wait while preserving
  the opposite loop branch.
- Pending samples before loop-body dynamic waits remain fail-closed.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.5`, pending-sample
  preservation across runtime dynamic wait paths.

## 2026-05-15: R14 — ISF switch-branch dynamic waits
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.4.4`.
- Runtime scalar waits in `switch` branches now lower for the
  no-pending-sample subset.
- The selected case carries the positive-count counter load/entry path and
  zero-count bypass path; other explicit cases remain selectable.
- Implicit switch fallthrough is guarded by the complement of the explicit
  case predicates.
- Pending samples before a `switch`-branch dynamic wait remain fail-closed.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.4.5`, dynamic waits in
  `while`/`until` bodies.

## 2026-05-15: R14 — ISF repeat-body dynamic waits
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.4.3`.
- Runtime scalar waits in `repeat` bodies now lower for the no-pending-sample
  subset.
- Repeat-body generated dynamic wait counters are registered alongside the
  repeat counter, and repeat-check loop-back/exit behavior remains intact.
- Pending samples before a `repeat`-body dynamic wait remain fail-closed.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.4.4`, dynamic waits in
  `switch` branches.

## 2026-05-15: R14 — ISF when-body dynamic waits
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.4.2`.
- Runtime scalar waits in `when` bodies now lower for the no-pending-sample
  subset.
- The branch true edge loads/enters on positive counts and bypasses on zero
  counts; the branch false edge still skips the entire body.
- Pending samples before a `when`-body dynamic wait remain fail-closed.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.4.3`, dynamic waits in
  `repeat` bodies.

## 2026-05-15: R14 — ISF inline dynamic wait split
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.4.1`.
- Inline runtime scalar waits in `when`, `switch`, `repeat`, `while`, and
  `until` bodies remain fail-closed, now with focused regression coverage and
  mdBook/spec text for each context.
- Loop-body wait diagnostics now distinguish `while body` from `until body`.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.4.2`, dynamic waits in
  `when` bodies.

## 2026-05-15: R14 — ISF dynamic waits after additional predecessors
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.3`.
- Top-level runtime scalar waits now lower after `await`, `stage`,
  `repeat_check`, `sync_all`, and `sync_any` predecessor states.
- The lowerer combines each predecessor's advance condition with the dynamic
  count split while preserving unrelated alternatives such as await timeouts
  and repeat loop-back edges.
- The `.fsm` emitter now preserves expression-guarded split transitions inside
  await, repeat-check, await-all, and await-any special rendering paths.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.4`, inline dynamic
  waits in branch and loop bodies.

## 2026-05-15: R14 — ISF consecutive runtime scalar waits
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.2`.
- Consecutive top-level runtime scalar waits now lower through recursive
  zero-bypass handling and active-wait final-edge splitting.
- If the first runtime count is zero, the activation edge evaluates the next
  wait's zero/positive paths instead of entering it with an uninitialized
  counter.
- If the first wait is active, its final sampled-counter edge loads or bypasses
  the following wait without rereading the first count source.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3.3`, additional
  top-level predecessor kinds.

## 2026-05-15: R14 — ISF dynamic wait expansion split
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.3.1`.
- `ISF-DYNAMIC-WAIT.3.3` is now an active container for the remaining runtime
  dynamic wait expansion work.
- The next frontier is `ISF-DYNAMIC-WAIT.3.3.2`, consecutive top-level runtime
  scalar waits.
- Later leaves track additional top-level predecessor kinds, inline
  branch/loop bodies, pending-sample preservation, and expression-valued count
  evaluation.

## 2026-05-15: R14 — ISF bounded runtime scalar waits
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.2`.
- Top-level `(wait count_signal)` now accepts known-width runtime scalar count
  names in bypass-capable transaction-body contexts.
- Runtime zero counts bypass the generated wait state on the predecessor edge;
  positive counts load a generated `*_wait_*_cnt` counter on that same edge.
- The wait state consumes exactly the sampled count by decrementing the counter
  and looping until the sampled value reaches `1`.
- Schedule reports distinguish static and runtime waits with `count_kind`,
  `count_source`, `counter_signal`, and `counter_width`; runtime waits keep
  `cycles` null.
- The active frontier advances to `ISF-DYNAMIC-WAIT.3.3`, expanding dynamic
  wait contexts after this first lowering.

## 2026-05-15: R14 — ISF actor constants and symbolic waits
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.2`.
- Actors now accept `(constants (NAME value) ...)` for actor-scoped
  non-negative integer compile-time constants.
- Scheduled `.fsm` emits the constants as `+constants`, and schedule reports
  expose bounded `actor_constants[]` entries.
- `(wait NAME)` resolves actor constants and then follows the existing static
  wait lowering: positive counts emit fixed wait-state chains, and zero counts
  are transparent no-ops.
- The active frontier moved into `ISF-DYNAMIC-WAIT.3` runtime scalar dynamic
  waits.

## 2026-05-15: R14 — ISF runtime dynamic wait split
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.3.1`.
- Runtime dynamic waits now have an executable implementation boundary:
  `count == 0` must bypass on the predecessor edge, not through a generated
  decision state.
- The next frontier is `ISF-DYNAMIC-WAIT.3.2`, first bounded runtime scalar
  wait lowering for scalar count names with known unsigned width.
- Pending samples, inline branch/switch/repeat/loop dynamic waits, and count
  expressions remained fail-closed at that slice until their exact
  bypass/snapshot behavior was implemented. Actor-parameter-backed static
  counts later shipped under `ISF-PARAM-WAIT-COUNTS.1`.

## 2026-05-15: R14 — ISF non-literal wait-count contract
- Completed R14 task-tree slice: `ISF-DYNAMIC-WAIT.1`.
- Added
  [docs/tasks/ISF-DYNAMIC-WAIT.md](docs/tasks/ISF-DYNAMIC-WAIT.md)
  as the active feature tree for symbolic and runtime dynamic transaction
  wait counts.
- Static symbolic counts are specified as compile-time counts that must
  resolve before lowering and then behave exactly like literal waits.
- Runtime scalar dynamic counts remain implementation backlog until the lowerer
  can preserve zero-count fallthrough, snapshot positive counts, use known
  counter widths/reset behavior, and expose dynamic report metadata.
- This specification frontier later shipped under `ISF-DYNAMIC-WAIT.2`.

## 2026-05-15: R14 — ISF activation input binding expressions
- Completed R14 task-tree slice: `ISF-ACTIVATION-BIND-EXPRESSIONS.1`.
- Activation input bindings now accept scalar signals, numeric/exact-width
  literals, and non-empty list expressions at shipped `do`, generated
  `do`/`spawn`, and rule-trigger activation sites.
- Output bindings remain scalar-only writable endpoints.
- Generated spawn tops no longer same-name wire actor input signals that are
  already consumed by explicit input-binding expressions.
- `transaction_port_bindings[]` now includes bounded `actor_expression`
  provenance, with `actor_signal` set to JSON null for expression-valued input
  bindings.

## 2026-05-15: R14 — ISF zero-count wait semantics
- Completed R14 task-tree slice: `ISF-WAIT-ZERO.1` defines and implements
  `(wait 0)`.
- `(wait 0)` is accepted in top-level and inline transaction wait contexts as
  a transparent no-op.
- It emits no generated wait state, consumes no active transaction cycle, and
  creates no `transaction_waits[]` report entry.
- Pending samples before `(wait 0)` are preserved for the next
  state-producing clause.
- Dynamic and symbolic wait counts remain backlog.

## 2026-05-15: R11 — Lisp-ish ?wiring forms
- Active task-tree slice: `COMPOSITION-WIRING-LISPISH.1` ships canonical
  explicit composition link forms.
- `?wiring` accepts compact `(source target)` and verbose
  `(connect source target)` links; `/source/target/` remains compatibility
  input.
- Source-side `(cat ...)` and `(repeat COUNT operand)` forms are accepted in
  those links and normalize to the existing typed composition source-expression
  path.
- ISF-generated composition tops now emit the canonical list-link spelling.
- `?wiring` is now the canonical shipped block name in parser diagnostics,
  generated composition tops, examples, tests, and user-facing docs.

## 2026-05-15: R14 — ISF storage var-only source surface
- Active R14 task-tree slice: `ISF-STORAGE-VAR-SURFACE.1` narrows
  actor-owned scalar storage source vocabulary.
- `(var name (width N))` is canonical; `(variable name (width N))` is the
  verbose alias.
- `(state ...)` and `(register ...)` storage entries now fail closed.
- Schedule-report `kind: register` remains generated backend storage-class
  metadata, not source vocabulary.

## 2026-05-15: R14 — ISF clock-domain backlog
- Captured the current single-clock-domain ISF boundary in the spec, mdBook,
  roadmap, task-tree index, README, and live docs.
- Added
  [docs/tasks/ISF-CLOCK-DOMAINS.md](docs/tasks/ISF-CLOCK-DOMAINS.md)
  as a proposed task tree for future multi-clock, asynchronous, and
  interacting clock-domain semantics.
- Different clock names and reusable-library generated-top links remain
  signal-name bindings only; they do not imply CDC behavior.

## 2026-05-15: R14 — ISF storage variable aliases
- Active R14 task-tree slice: `ISF-STORAGE-VAR-ALIASES.1` adds scalar storage
  aliases for actor-owned storage declarations.
- `(var name (width N))` and `(variable name (width N))` were introduced as
  scalar storage forms; the later `ISF-STORAGE-VAR-SURFACE` slice made those
  the only accepted scalar source forms.
- `(var ...)` is the canonical source spelling for new scalar actor-owned
  storage; `(variable ...)` is the verbose alias.
- The aliases reuse the existing scheduled `.fsm`, schedule-report
  `actor_storage`, and HDL generation paths.
- Focused validation passed for parser syntax, storage lowering/reporting/HDL,
  and singleton actor-clause preservation.

## 2026-05-15: R14 — ISF library system-port remapping
- Active R14 task-tree slice:
  `ISF-LIBRARY-SYSTEM-BINDINGS.1` supports reusable-library clock/reset
  parent/child name remapping.
- Generated ISF composition tops now emit explicit links for remapped library
  system signals, while same-name bindings continue through system-port
  auto-wiring.
- Direct `.fsm +system` accepts HDL-compatible authored clock identifiers, and
  malformed clock identifiers still fail closed.
- The shipped behavior is single-clock-domain ISF name binding only; multi-clock
  and CDC semantics remain unshipped.
- Focused validation passed for direct system contracts, generated library top
  HDL, public catalog metadata, and language-surface metadata.

## 2026-05-15: R6 — verbose .rtlif metadata ports
- `.rtlif` now accepts verbose `(input ...)` and `(output ...)` declarations as
  aliases for compact external-RTL metadata tokens.
- Shipped role attributes are `:clock`, `:reset`, and `:data`, with
  parenthesized `(clock)`, `(reset)`, and `(data)` aliases.
- `clock` and `reset` remain system-input roles; verbose output declarations
  with those roles are rejected.
- The mdBook now states that `.rtlif` roles are composition metadata roles, not
  HDL data types, and shows compact/verbose equivalences.
- Focused validation passed in [t/88-rtlif-typed-port-contract.t](t/88-rtlif-typed-port-contract.t).

## 2026-05-15: R6 — verbose composition port declarations
- `?ports` now accepts verbose `(input ...)` and `(output ...)` declarations
  as aliases for compact top-port tokens.
- `(width TOKEN)` uses the same width resolver as compact suffixes.
- Nullary verbose attributes can be written as `(attribute)` or `:attribute`;
  the shipped declared same-name flag is canonical `:same-name`, with
  `(same-name)`, `:connect-by-name`, and `(connect-by-name)` accepted aliases.
- Malformed verbose declarations now produce declaration-shaped diagnostics and
  failed-run summaries.
- Focused validation passed for parser, HDL, C4 by-name, parser diagnostics,
  and failure-summary tests.

## 2026-05-15: R14 — ISF transaction activation tree closure
- Active R14 task-tree slice: `ISF-TRANSACTION-ACTIVATION.4` is complete, and
  [docs/tasks/ISF-TRANSACTION-ACTIVATION.md](docs/tasks/ISF-TRANSACTION-ACTIVATION.md)
  is closed.
- The shipped activation-parameter surface is now explicitly bounded to
  spawned child instances and blocking `do` generated child activations.
- Rule `trigger` parameter overrides, direct activation parameters, symbolic
  parameter values, and expression-valued parameter overrides remain backlog
  and require a fresh explicit task-tree leaf before implementation.
- Validation for this closure slice: `mdbook build docs/book` and
  `git diff --check`.

## 2026-05-15: R14 — ISF blocking do parameter overrides
- Active R14 task-tree slice: `ISF-TRANSACTION-ACTIVATION.3` is complete in
  [docs/tasks/ISF-TRANSACTION-ACTIVATION.md](docs/tasks/ISF-TRANSACTION-ACTIVATION.md).
- Blocking `(do child (params ...))` now lowers through a generated child
  activation instance, applies static parameter overrides in the generated top,
  and waits for that instance's `done` handoff.
- Generated blocking `do` port bindings are reviewable in scheduled `.fsm` as
  parent-owned `do_port_binding` DTs with done-gated output copies.
- Schedule reports now expose `activation_generated_top` when generated child
  activation is not spawn-only, and generated-composition instances include
  `activation_kind`.
- The mdBook, ISF spec, public contract docs, roadmap status, task tree, and
  live docs are synchronized for the shipped behavior. The next frontier is
  `ISF-TRANSACTION-ACTIVATION.4`.
- Validation passed: changed-module Perl syntax checks, focused
  composition/report tests, `./bin/ci-regression isf --no-book`,
  `mdbook build docs/book`, and `git diff --check`.

## 2026-05-15: R14 — ISF task-like transaction activation boundary
- Active R14 task-tree slice: `ISF-TRANSACTION-ACTIVATION.1` is complete in
  [docs/tasks/ISF-TRANSACTION-ACTIVATION.md](docs/tasks/ISF-TRANSACTION-ACTIVATION.md).
- The mdBook/spec wording now states the current transaction-as-task boundary:
  ports are formal data/control ports, `(bind ...)` entries pass scalar actual
  signals at shipped activation sites, and generated hardware remains static.
- At that slice, general activation-site parameter overrides were not shipped
  except for existing spawned-child specialization. Blocking `do` parameter
  overrides have since shipped in `ISF-TRANSACTION-ACTIVATION.3`; rule
  `trigger` and other forms remain backlog.
- `ISF-TRANSACTION-ACTIVATION.2` is also complete: future general
  activation-site parameter overrides use `(params (NAME value) ...)` as static
  specialization syntax, distinct from runtime port actuals in `(bind ...)`.
- The active frontier advances to `ISF-TRANSACTION-ACTIVATION.3`, implementing
  the next selected activation-site parameter override.

## 2026-05-15: R14 — ISF scalar setter syntax
- Active R14 task-tree slice: `ISF-SETTER-SYNTAX.1` is complete, closing
  [docs/tasks/ISF-SETTER-SYNTAX.md](docs/tasks/ISF-SETTER-SYNTAX.md).
- `(set lhs expr)` is now the canonical explicit scalar setter in rule and
  transaction contexts.
- Rule `set` lowers as a flopped rule assignment under the guarded rule
  non-state DT DTE; transaction `set` lowers as one ordered flopped transaction
  state.
- Existing transaction `(update lhs expr)` and rule `(lhs expr)` shorthand remain
  supported while the ISF API continues to evolve.
- [t/1246-isf-setter-syntax.t](t/1246-isf-setter-syntax.t) proves parser,
  scheduler, scheduled `.fsm`, malformed diagnostics, and HDL reachability.
- Validation passed: focused affected tests, `./bin/ci-regression isf --no-book`,
  and `mdbook build docs/book`.

## 2026-05-15: R14 — ISF transaction loop lowering
- Active R14 task-tree slice: `ISF-CONTROL-FLOW.3` is complete, closing
  [docs/tasks/ISF-CONTROL-FLOW.md](docs/tasks/ISF-CONTROL-FLOW.md).
- Top-level transaction `(while cond body...)` now lowers as a pre-test
  zero-or-more loop with explicit entry and back-edge decision states.
- Top-level transaction `(until cond body...)` now lowers as a body-first
  one-or-more loop with a generated post-body decision state.
- Loop conditions are sampled only in generated decision states, supported
  bodies use the shipped inline transaction subset, and malformed or
  unsupported loop-body combinations fail closed.
- Successful schedule reports expose bounded `transaction_loops[]` entries,
  and [t/1245-isf-transaction-loop-lowering.t](t/1245-isf-transaction-loop-lowering.t)
  proves scheduled `.fsm`, report, diagnostics, and SystemVerilog reachability.
- The next R14 action is to select or activate the next user-visible feature
  tree. Public-contract stabilization remains feature-driven rather than the
  main lane.

## 2026-05-15: R14 — ISF positive-literal wait lowering
- Active R14 task-tree slice: `ISF-CONTROL-FLOW.2` is complete.
- `(wait N)` now accepts positive integer literal counts in transaction body
  contexts and lowers to fixed generated `*_wait_*` state chains with exactly
  one active transaction cycle per generated wait state.
- Successful schedule reports expose bounded `transaction_waits[]` entries;
  malformed, zero, list, and dynamic wait counts fail closed.
- The mdBook, ISF spec, public contract, task tree, roadmap status, and live
  docs are synchronized for the shipped wait behavior.
- The next active R14 frontier is `ISF-CONTROL-FLOW.3`, dynamic transaction
  loops.

## 2026-05-15: R14 — ISF control-flow contract specification
- Active R14 task-tree slice: `ISF-CONTROL-FLOW.1` is complete, and
  `ISF-CONTROL-FLOW` is now active.
- `(wait N)` is specified as an unconditional exact-cycle transaction delay
  for positive integer literal `N >= 1`; dynamic counts and zero-count
  behavior remain deferred.
- `(while cond body...)` is specified as pre-test zero-or-more, and
  `(until cond body...)` as body-first one-or-more, with conditions sampled
  only in generated decision states.
- The next active R14 frontier is `ISF-CONTROL-FLOW.2`, positive-literal
  `(wait N)` implementation.

## 2026-05-15: R14 — ISF port binding authoring boundary
- Active R14 task-tree slice: `ISF-PUBLIC-CONTRACT.7` is complete as a
  documentation-only clarification.
- The mdBook now states that transaction-port connectivity is authored with
  ISF `(ports ...)` and `(bind ...)` forms, while generated `.fsm` handoff
  signals, mux selectors, and generated-top bridge nets remain compiler-owned
  lowering artifacts.
- The ISF spec and public contract wording are aligned with the closed
  `ISF-PORT-BINDING` tree and the shipped bounded
  `transaction_port_bindings[]` report surface.
- The next R14 feature candidate remains `ISF-CONTROL-FLOW`, currently
  proposed, for `(wait N)`, `(while ...)`, and `(until ...)`.

## 2026-05-15: R14 — ISF port binding schedule-report projection
- Active R14 task-tree slice: `ISF-PORT-BINDING.5` is complete, closing
  `ISF-PORT-BINDING`.
- Successful schedule reports now expose bounded `transaction_port_bindings`
  entries for scalar `do`, `spawn`, and rule-trigger input bindings.
- The public contract, ISF spec, mdBook, task tree, and live docs are updated
  to describe the shipped binding provenance surface.
- The next R14 feature candidate is `ISF-CONTROL-FLOW`, currently proposed,
  for `(wait N)`, `(while ...)`, and `(until ...)`.

## 2026-05-15: R14 — ISF port binding conflict semantics
- Active R14 task-tree slice: `ISF-PORT-BINDING.4` is complete.
- Spawn output bindings now carry parent-transaction provenance and participate
  in the existing rule/transaction conflict path.
- Accepted spawn-output fan-in and rule-trigger input payload fan-in lower as
  ordinary guarded `.fsm` assignments and reach SystemVerilog selector
  assertions for runtime verification.
- The next active R14 frontier is `ISF-PORT-BINDING.5`, bounded report/docs
  coverage for the shipped binding surface.

## 2026-05-15: R14 — ISF transaction port activation bindings
- Active R14 task-tree slice: `ISF-PORT-BINDING.3` is complete.
- Scalar `(bind ...)` blocks now lower for `do`, `spawn`, and rule-trigger
  input payloads, with direction/width checks and actor input/output policy
  enforcement.
- Spawned bindings use hidden generated-top handoffs; rule-trigger input
  bindings use per-rule payload sources before trigger fan-in.
- The next active R14 frontier is `ISF-PORT-BINDING.4`, actor pin/conflict
  edge-case integration.

## 2026-05-15: R14 — ISF transaction port declarations
- Active R14 task-tree slice: `ISF-PORT-BINDING.2` is complete.
- Transactions now parse a single `(ports ...)` declaration into public
  actor-shell metadata: `ports.inputs[]` and `ports.outputs[]` entries with
  scalar `name` and positive integer `width`.
- Declared-but-unbound ports remain parser metadata only; they are not lowered
  into scheduled `.fsm` or HDL behavior until activation bindings ship.
- The next active R14 frontier is `ISF-PORT-BINDING.3`, explicit transaction
  port bindings at activation sites.

## 2026-05-15: R14 — ISF port binding contract specification
- Active R14 task-tree slice: `ISF-PORT-BINDING.1` is complete.
- [docs/ISF_SPEC.md](docs/ISF_SPEC.md) now records the proposed
  transaction-port declaration and activation-binding surface, plus actor pin
  read/write policy and same-cycle visibility requirements.
- The mdBook backlog has a matching "Transaction Ports And Actor Pin Access"
  section, and the ISF public contract marks the feature as non-public until
  implementation and regressions ship.
- The next active R14 frontier is `ISF-PORT-BINDING.2`, parser support for
  transaction port declarations and diagnostics.

## 2026-05-15: R14 — ISF transaction-port binding task tree
- Active R14 task-tree setup: `ISF-PORT-BINDING` is now active.
- [docs/tasks/ISF-PORT-BINDING.md](docs/tasks/ISF-PORT-BINDING.md) tracks
  transaction ports, activation-time bindings, and actor top-level pin access.
- The feature direction is ISF-level syntax lowering to explicit `.fsm`, with
  direction/width checks, same-cycle visibility, conflict behavior,
  diagnostics, and schedule-report provenance to be specified before
  implementation.
- The next active R14 frontier is `ISF-PORT-BINDING.1`.

## 2026-05-15: R14 — ISF library catalog contract synchronization
- Active R14 task-tree slice: `ISF-LIBRARIES.5` is complete, and the
  `ISF-LIBRARIES` task tree is closed.
- [docs/ISF_LIBRARY_CATALOG.md](docs/ISF_LIBRARY_CATALOG.md) now records the
  shipped reusable ISF library definitions. The first entry is
  `common.fifo.fifo`, with fixed parameters, interface, storage, semantics,
  tests, and limitations.
- The ISF public contract now advertises `library_catalog_paths`,
  `library_catalog_entry_keys`, and `shipped_library_definitions`, and the
  focused catalog-contract test keeps the human catalog and contract metadata
  aligned.
- The next R14 action is to select or activate the next user-visible feature
  tree. Public contract work remains feature-driven rather than the primary
  lane.

## 2026-05-15: R14 — ISF FIFO library HDL proof
- Active R14 task-tree slice: `ISF-LIBRARIES.4.6` is complete.
- [isf/fifo_library_use.isf](isf/fifo_library_use.isf) now reaches CLI
  SystemVerilog generation through the generated top path.
- The HDL proof checks the generated top module, specialized FIFO child,
  fixed parameter bindings, scalarized data entries, and pointer-gated
  accepted push/pop selectors.
- The slice fixed AST factorization structural identity so `CoreAST`
  signal references keep their concrete signal names and same-shape helpers
  do not collapse unrelated signals.
- The next active R14 frontier is `ISF-LIBRARIES.5`, public library
  catalog/contract synchronization for the shipped FIFO fixture.

## 2026-05-15: R14 — ISF reusable FIFO library fixture
- Active R14 task-tree slice: `ISF-LIBRARIES.4.5` is complete.
- [isf/common/fifo.isf](isf/common/fifo.isf) now exports the first reusable
  FIFO actor library fixture, `common.fifo.fifo`.
- [isf/fifo_library_use.isf](isf/fifo_library_use.isf) imports that library,
  binds the public FIFO interface, and instantiates `u_fifo` through the
  shipped library-use surface.
- The FIFO actor combines same-cycle push/pop controller rules with
  actor-owned bank `store`/`load` data movement for the fixed
  `DATA_WIDTH=8`, `DEPTH=4` target.
- The next active R14 frontier is `ISF-LIBRARIES.4.6`, proving the reusable
  FIFO fixture through generated top HDL and focused generated-artifact
  checks.

## 2026-05-15: R14 — ISF FIFO data-buffer access implementation
- Active R14 task-tree slice: `ISF-LIBRARIES.4.4.5` is complete.
- `(store <bank-name> <index> <value>)` and
  `(load <bank-name> <index> as <target>)` now parse and lower for declared
  actor-owned fixed-depth banks in rules and supported transaction contexts.
- Depth-4 bank access lowers to guarded scalarized assignments over entries
  such as `data_0` through `data_3`, preserving read-before-write same-cycle
  semantics.
- Schedule reports now expose bounded `bank_accesses` metadata, and malformed
  access shapes, unknown banks, non-bank storage names, out-of-range literal
  indexes, and known width mismatches fail closed.
- The next active R14 frontier is `ISF-LIBRARIES.4.5`, the first reusable
  FIFO actor library fixture.

## 2026-05-15: R14 — ISF FIFO data-buffer access contract
- Active R14 task-tree slice: `ISF-LIBRARIES.4.4.4` is complete.
- The FIFO datapath access syntax is specified as
  `(store <bank-name> <index> <value>)` and
  `(load <bank-name> <index> as <target>)`.
- The planned lowering uses the existing scalarized bank entries, so a
  depth-4 bank remains reviewable through guarded access to `data_0` through
  `data_3`.
- Same-cycle store/load on the same bank is read-before-write in the first
  contract.
- The next active R14 frontier is `ISF-LIBRARIES.4.4.5`, implementing that
  bank access surface.

## 2026-05-15: R14 — ISF FIFO controller same-cycle matrix
- Active R14 task-tree slice: `ISF-LIBRARIES.4.4.3` is complete.
- A depth-4 FIFO controller fixture now lowers through scheduled `.fsm`,
  schedule JSON, and SystemVerilog generation.
- The public boundary is controller-shaped: inputs `write_req`, `data_in`,
  and `read_req`; outputs `full`, `empty`, and `data_out`.
- `full` and `empty` are maintained by the actor from occupancy. The fixture
  updates `wr_ptr`, `rd_ptr`, `occupancy`, `full`, and `empty` for idle,
  push-only, pop-only, and push+pop cases.
- That slice authored scalar storage with `(state ...)`. The later
  `ISF-STORAGE-VAR-ALIASES` slice made `(var ...)` the preferred scalar
  source spelling, while keeping `(state ...)` accepted and `(register ...)`
  rejected. The report's `kind: register` remains generated storage-class
  metadata.
- The next active R14 frontier is `ISF-LIBRARIES.4.4.4`, the FIFO data-buffer
  access contract needed before a real reusable FIFO library fixture.

## 2026-05-14: R14 — ISF disjoint rule writes
- Active R14 task-tree slice: `ISF-LIBRARIES.4.4.2` is complete.
- Same-target rule writes are accepted when rule guards contain direct
  contradictory facts proving the guarded assignments cannot fire in the
  same cycle.
- The regression fixture is depth 4 and includes actor-owned storage,
  write/read pointer state, occupancy, and the four FIFO request cases.
- Unproved overlaps remain conservative: compatible fan-in, priority
  resolution, or fail-closed conflict diagnostics still handle them.
- The next active R14 frontier is `ISF-LIBRARIES.4.4.3`, the complete
  same-cycle FIFO controller update matrix on actor-owned storage.

## 2026-05-14: R14 — ISF expression-valued rule guards
- Active R14 task-tree slice: `ISF-LIBRARIES.4.4.1` is complete.
- Rule guards now accept scalar or list-expression conditions in shorthand and
  long-form `(when ...)` spellings.
- Expression guards lower once as the rule non-state DT DTE and reach
  scheduled `.fsm` parsing plus SystemVerilog generation.
- This unblocks direct FIFO fire predicates such as
  `(& push (! pop) (! full))`.
- The next active R14 frontier is `ISF-LIBRARIES.4.4.2`, disjoint-rule write
  proof for the FIFO same-cycle update matrix.

## 2026-05-14: R14 — ISF actor-owned storage declarations
- Active R14 task-tree slice: `ISF-LIBRARIES.4.3` is complete.
- Actors can now declare fixed-width internal state values and fixed-depth
  storage banks through a singleton `(storage ...)` clause.
- Storage banks lower to deterministic scalar element names such as
  `data_0` through `data_3`, giving the first `DEPTH=4` FIFO fixture concrete
  reviewable storage before memory-array syntax is generalized.
- Declared storage is emitted in scheduled `.fsm` `+size`, reported with the
  `actor_storage` role, and proven through SystemVerilog generation when used.
- The next active R14 frontier is `ISF-LIBRARIES.4.4`, same-cycle FIFO
  read/write update semantics.

## 2026-05-14: R14 — ISF real FIFO requirements
- Active R14 task-tree slice: `ISF-LIBRARIES.4.2` is complete.
- A depth-1 placeholder has been rejected as the reusable FIFO fixture.
- The first real FIFO fixture target is `DEPTH=4`, with four storage entries,
  pointer wrap, occupancy values 0 through 4, and full/empty derivation.
- FIFO modeling must cover idle, push-only, pop-only, and simultaneous
  push+pop cycles, with fire predicates derived from the same pre-cycle state.
- Transaction `(when ...)` is ordered control flow and is not sufficient to
  model same-cycle FIFO write/read port concurrency.
- The next active R14 frontier is `ISF-LIBRARIES.4.3`, adding the storage
  primitives needed before a real FIFO library can be authored.

## 2026-05-14: R14 — ISF library generated top wiring
- Active R14 task-tree slice: `ISF-LIBRARIES.4.1` is complete.
- Resolved library actor uses now emit generated composition tops and reach
  SystemVerilog generation through the normal composition path.
- Bound library inputs/outputs are linked directly between top ports and the
  library child instance, with library-owned outputs suppressing duplicate
  parent output links.
- Same-name clock/reset bindings use existing system-port auto-wiring;
  system-name remapping remains fail-closed.
- The next active R14 frontier is `ISF-LIBRARIES.4.2`.

## 2026-05-14: R14 — ISF library import resolution
- Active R14 task-tree slice: `ISF-LIBRARIES.3` is complete.
- Actor-scoped `(imports ...)` and `(use ...)` now resolve exported actors
  from `(library name ...)` roots on the file-backed source-dir/`FSMLIB`/cwd
  search path.
- The parser validates use-site parameters and clock/reset/interface bindings
  before scheduler handoff.
- Lowering emits specialized child scheduled `.fsm` artifacts and schedule
  reports expose bounded `library_uses` provenance.
- Generated top wiring/HDL integration remains for `ISF-LIBRARIES.4`, now the
  next active R14 frontier.

## 2026-05-14: R14 — ISF library binding model
- Active R14 task-tree slice: `ISF-LIBRARIES.2` is complete.
- The first reusable-library specialization target is exported actors with
  instance-local parameter overrides and explicit clock/reset/interface
  binding.
- Generated child artifact names are planned as
  `<importing_actor>__<instance>` and
  `<importing_actor>__<instance>.fsm`.
- Successful reports should expose bounded `library_uses` provenance once the
  feature ships.
- The next active R14 frontier is `ISF-LIBRARIES.3`.

## 2026-05-14: R14 — ISF library import model
- Active R14 task-tree slice: `ISF-LIBRARIES.1` is complete.
- The `ISF-LIBRARIES` tree is active with frontier `ISF-LIBRARIES.2`.
- The planned public surface now has a documented shape: `(library name ...)`
  roots, actor-scoped imports, namespaced imported actor use, exported actors
  first, and fail-closed diagnostics for unresolved or ambiguous library use.
- FIFO remains a reusable actor, not a transaction-only abstraction, because
  it owns persistent storage and interface timing.

## 2026-05-14: R14 — ISF compatibility tree closure
- Active R14 task-tree slice: `ISF-COMPATIBILITY.5` is complete, and the
  `ISF-COMPATIBILITY` tree is closed.
- Added CLI schedule-report/strict-HDL parity for accepted ignored handshake
  compatibility input and CLI failure parity for removed transaction `assign`.
- Public `tested_by` metadata and tier selection now include
  [t/1229-isf-compatibility-cli-parity.t](t/1229-isf-compatibility-cli-parity.t).
- The remaining public-contract tree is cross-cutting and should not displace
  feature delivery unless a selected feature changes a public surface.

## 2026-05-14: R14 — ISF compatibility diagnostics
- Active R14 task-tree slice: `ISF-COMPATIBILITY.4` is complete.
- Legacy handshake validation now requires exactly one scalar `valid` and one
  scalar `ready`, rejects duplicate handshake names, and remains ignored for
  lowering.
- Removed transaction `(assign ...)` now has a targeted migration diagnostic.
- The next active R14 frontier is `ISF-COMPATIBILITY.5`.

## 2026-05-14: R14 — ISF removed assign policy
- Active R14 task-tree slice: `ISF-COMPATIBILITY.3` is complete.
- Removed transaction `(assign ...)` stays rejected and will not be auto-mapped
  because its timing intent is ambiguous.
- The implementation leaf should add a targeted migration diagnostic.
- The next active R14 frontier is `ISF-COMPATIBILITY.4`.

## 2026-05-14: R14 — ISF handshake compatibility policy
- Active R14 task-tree slice: `ISF-COMPATIBILITY.2` is complete.
- Legacy `(handshake ...)` stays accepted but ignored; it will not gain
  scheduled `.fsm`, schedule JSON, HDL, or public actor-shell metadata
  semantics.
- Validation tightening and migration diagnostics are left for the
  implementation leaf.
- The next active R14 frontier is `ISF-COMPATIBILITY.3`.

## 2026-05-14: R14 — ISF compatibility inventory
- Active R14 task-tree slice: `ISF-COMPATIBILITY.1` is complete.
- Deprecated `(handshake ...)` is parser-validated then ignored; it does not
  affect scheduled `.fsm`, schedule JSON, HDL, or strict-mode semantics.
- Removed transaction `(assign ...)` is parsed as private clause input and
  fails closed during scheduler validation.
- The next active R14 frontier is `ISF-COMPATIBILITY.2`.

## 2026-05-14: R14 — proposed ISF libraries/imports
- Proposed R14 task tree: `ISF-LIBRARIES` now tracks reusable ISF library and
  import support.
- The book backlog records the FIFO modeling rule: FIFO is actor-first because
  it owns persistent storage and interface state; transactions model
  operations against that actor.
- The tree is proposed, not active. The next active R14 frontier remains
  `ISF-COMPATIBILITY.1`.

## 2026-05-14: R14 — ISF fixture tree closure
- Active R14 task-tree slice: `ISF-FIXTURES.5` is complete, and the
  `ISF-FIXTURES` tree is closed.
- APB remains the quick/smoke fixture baseline; the SPI-like serial-transfer
  fixture is covered in the broader `isf` tier through schedule JSON,
  scheduled `.fsm`, plain HDL, and strict HDL.
- The docs now list the remaining unclaimed realistic fixture targets and
  record the ISF arity policy for future variadic constructs.
- The next active R14 frontier is `ISF-COMPATIBILITY.1`.

## 2026-05-14: R14 — ISF fixture tier placement
- Active R14 task-tree slice: `ISF-FIXTURES.4` is complete.
- The SPI-like fixture test is explicitly kept in the `isf` tier and out of
  quick/smoke.
- The fixture tree records the expressiveness policy: realistic fixtures
  should use documented ISF constructs, and awkward workarounds should become
  tracked missing-language items.
- Named drive call actuals now keep composed expression forms, so Lisp-like
  argument-level composition works for drive parameters.
- The next active R14 frontier is `ISF-FIXTURES.5`.

## 2026-05-14: R14 — ISF SPI-like fixture coverage
- Active R14 task-tree slice: `ISF-FIXTURES.3` is complete.
- `isf/spi_master.isf` is now covered through schedule JSON, scheduled `.fsm`,
  plain HDL generation, and strict HDL generation as a bounded SPI-like
  mode-0 serial-transfer fixture.
- The downstream `.fsm` expression path now accepts shift operators through
  SystemVerilog generation, and the fixture uses explicit `tx_byte[7]` MOSI
  bit selection.
- The next active R14 frontier is `ISF-FIXTURES.4`.

## 2026-05-14: R14 — ISF fixture coverage matrix
- Active R14 task-tree slice: `ISF-FIXTURES.2` is complete.
- The matrix selects `isf/spi_master.isf` as the next compact SPI-like
  mode-0 serial-transfer schedule/HDL/strict fixture target.
- The next active R14 frontier is `ISF-FIXTURES.3`.

## 2026-05-14: R14 — ISF resource catalog metadata
- Active R14 task-tree slice: `ISF-RESOURCE-CATALOG.3` is complete.
- The shareable resource registry now has a code owner shared by the parser and
  `embedding.isf_public_interface`.
- The next active R14 frontier remains `ISF-FIXTURES.2`.

## 2026-05-14: R14 — ISF fixture coverage inventory
- Active R14 task-tree slice: `ISF-FIXTURES.1` is complete.
- The fixture tree now inventories current `.isf` fixtures, ISF regression
  tiers, strict-mode coverage, and gaps before adding new realistic cases.
- The next active R14 frontier is `ISF-FIXTURES.2`.

## 2026-05-14: R14 — ISF schedule-report tree closure
- Active R14 task-tree slice: `ISF-SCHEDULE-REPORTS.5` is complete.
- The schedule-report tree is closed with an explicit freeze-boundary
  regression and synchronized public-contract provenance.
- The next active R14 frontier is `ISF-FIXTURES.1`.

## 2026-05-14: R14 — ISF schedule-report schema-freeze plan
- Active R14 task-tree slice: `ISF-SCHEDULE-REPORTS.4` is complete.
- The schedule-report freeze plan now records contractual, bounded-evolving,
  and private surfaces plus the blockers to a full schema freeze.
- The next active R14 frontier is `ISF-SCHEDULE-REPORTS.5`.

## 2026-05-14: R14 — ISF schedule-report storage roles
- Active R14 task-tree slice: `ISF-SCHEDULE-REPORTS.3` is complete.
- Successful schedule reports now include optional `inferred_storage[].role`
  metadata for the first evidence-backed storage families, and the public
  contract advertises the bounded role value family.
- The next active R14 frontier is `ISF-SCHEDULE-REPORTS.4`.

## 2026-05-14: R14 — ISF schedule-report storage role taxonomy
- Active R14 task-tree slice: `ISF-SCHEDULE-REPORTS.2` is complete.
- Richer storage classification is specified as optional
  `inferred_storage[].role`, while `kind` remains the coarse
  `counter`/`register` category.
- The next active R14 frontier is `ISF-SCHEDULE-REPORTS.3`.

## 2026-05-14: R14 — ISF schedule-report contract inventory
- Active R14 task-tree slice: `ISF-SCHEDULE-REPORTS.1` is complete.
- The schedule-report task tree now records the current bounded public report
  shape, feature-owned branches, storage metadata, multi-file scope, and
  non-frozen schema boundaries.
- The next active R14 frontier is `ISF-SCHEDULE-REPORTS.2`.

## 2026-05-14: R14 — ISF data-width schedule-report closure
- Active R14 task-tree slice: `ISF-DATA-WIDTHS.5` is complete, and the
  `ISF-DATA-WIDTHS` tree is closed.
- Schedule JSON `inferred_storage` now reports positive integer `width`
  metadata for inferred scheduler counters and register storage with known ISF
  width evidence.
- The new storage-width regression covers sampled aliases, extracted fields,
  assembled targets, explicit-width shift registers, and completion pulses.
- The next active R14 frontier is `ISF-SCHEDULE-REPORTS.1`.

## 2026-05-14: R14 — ISF shift and assemble width alignment
- Active R14 task-tree slice: `ISF-DATA-WIDTHS.4` is complete.
- `shift_right` now uses known or explicit width evidence and fails closed for
  missing or contradictory width facts instead of emitting placeholder
  `WIDTH` expressions.
- `assemble` now rejects known target-width mismatches while allowing unknown
  part widths only as non-evidence concat operands.
- The next active R14 frontier is `ISF-DATA-WIDTHS.5`.

## 2026-05-14: R14 — ISF shareable resource registry clarification
- Active R14 task-tree slice: `ISF-RESOURCE-CATALOG.2` is complete.
- The ISF resource catalog is now described as the public growable registry of
  shareable resource kinds, with resource names as author-defined instance
  handles and resource kinds as the stable class of shareable thing.
- Runtime behavior is unchanged: `rule_slot` with `priority` arbitration is
  the only shipped enforced kind today. The next active R14 frontier remains
  `ISF-DATA-WIDTHS.4`.

## 2026-05-14: R14 — ISF extract width enforcement
- Active R14 task-tree slice: `ISF-DATA-WIDTHS.3` is complete.
- `extract` now follows the no-placeholder width policy: accepted source emits
  exact slices, while unknown field widths and source/field width mismatches
  fail closed before scheduled `.fsm` emission.
- The next active R14 frontier is `ISF-DATA-WIDTHS.4`.

## 2026-05-14: R14 — ISF data-width policy
- Active R14 task-tree slice: `ISF-DATA-WIDTHS.2` is complete.
- Width evidence precedence and failure policy are now specified. Explicit
  width options are assertions, and migrated operation families should fail
  closed instead of emitting placeholders for accepted source.
- The first implementation target is `extract`; the next active R14 frontier
  is `ISF-DATA-WIDTHS.3`.

## 2026-05-14: R14 — ISF data-width inventory
- Active R14 task-tree slice: `ISF-DATA-WIDTHS.1` is complete.
- The task tree now records current width sources, explicit options,
  placeholder fallbacks, generated `.fsm` shapes, underconstrained cases, and
  schedule-report storage effects for ISF data operations.
- The next active R14 frontier is `ISF-DATA-WIDTHS.2`.

## 2026-05-14: R14 — ISF stage/contract schedule-report closure
- Active R14 task-tree slice: `ISF-STAGES-CONTRACTS.6` is complete, and the
  `ISF-STAGES-CONTRACTS` tree is closed.
- Successful schedule reports now expose `transaction_stages` for shipped
  ready/valid barriers and `temporal_contracts` for shipped bounded eventual
  monitors.
- The public contract advertises the new report key/value families, and the
  new regression covers both in-process and CLI JSON report paths.
- The next active R14 frontier is `ISF-DATA-WIDTHS.1`.

## 2026-05-14: R14 — ISF bounded contract lowering
- Active R14 task-tree slice: `ISF-STAGES-CONTRACTS.5` is complete.
- Top-level `(contract name (eventually signal (within cycles)))` now lowers
  to one transaction arm state plus an always-on monitor DT.
- The monitor owns pending, age, and sticky-fail storage: success clears the
  pending obligation, timeout or overlap sets fail, and reset clears the
  generated storage.
- The new regression covers scheduled `.fsm` emission, targeted rejections,
  `.fsm` frontend parsing, and SystemVerilog handoff.
- The next active R14 frontier is `ISF-STAGES-CONTRACTS.6`.

## 2026-05-14: R14 — ISF bounded stage lowering
- Active R14 task-tree slice: `ISF-STAGES-CONTRACTS.4` is complete.
- Top-level `(stage name (input ready_signal) (output valid_signal))` now
  lowers to one ready-gated transaction state that drives `valid_signal = 1`
  while active.
- The new regression covers scheduled `.fsm` emission, pending-sample
  materialization, targeted rejections, `.fsm` frontend parsing, and
  SystemVerilog handoff.
- The next active R14 frontier is `ISF-STAGES-CONTRACTS.5`.

## 2026-05-14: R14 — ISF bounded contract semantics
- Active R14 task-tree slice: `ISF-STAGES-CONTRACTS.3` is complete.
- The first planned temporal-contract model is a top-level transaction-local
  bounded eventual monitor with source shape
  `(contract name (eventually signal (within cycles)))`.
- The planned lowering uses a scheduled `.fsm` arm state plus monitor DT with
  pending, age, and sticky-fail storage. Actor reset clears it; success clears
  the pending obligation; timeout or overlap sets fail.
- The next active R14 frontier is `ISF-STAGES-CONTRACTS.4`.

## 2026-05-14: R14 — ISF bounded stage semantics
- Active R14 task-tree slice: `ISF-STAGES-CONTRACTS.2` is complete.
- The first planned transaction-stage model is a top-level ready/valid
  handshake barrier with the source shape
  `(stage name (input ready_signal) (output valid_signal))`.
- The planned lowering is one state that drives `valid_signal = 1` while
  active and advances only when `ready_signal` is true. Nested stages,
  stage-local latency/compute/action bodies, multiple endpoints,
  registered-valid variants, and skid-buffer behavior remain deferred.
- The next active R14 frontier is `ISF-STAGES-CONTRACTS.3`.

## 2026-05-14: R14 — ISF stage/contract inventory
- Active R14 task-tree slice: `ISF-STAGES-CONTRACTS.1` is complete.
- The task tree now inventories current parsed forms, preservation points,
  diagnostics, and missing lowering hooks for transaction stages and temporal
  contracts.
- The ISF spec, public contract, and mdBook now clarify that actor-level
  phase/stage metadata is parser-carried only, transaction phases lower as
  pass-through states, transaction stages fail closed before IR lowering, and
  contracts have no payload/check IR yet.
- The next active R14 frontier is `ISF-STAGES-CONTRACTS.2`.

## 2026-05-14: R14 — ISF rule-action tree closure
- Active R14 task-tree slice: `ISF-RULE-ACTIONS.5` is complete.
- The `ISF-RULE-ACTIONS` task tree is closed and moved to the completed
  task-tree table.
- Covered behavior now includes expression-valued rule assignment parsing,
  lowering, malformed diagnostics, scheduled `.fsm`/HDL handoff, compatible
  fan-in reports, conflict diagnostics, and priority-resolution reports.
- The next active R14 frontier is `ISF-STAGES-CONTRACTS.1`.

## 2026-05-14: R14 — ISF rule-expression conflict/report integration
- Active R14 task-tree slice: `ISF-RULE-ACTIONS.4` is complete.
- Expression-valued rule assignments now have explicit compatible fan-in,
  conflict diagnostic, and priority-resolution report coverage.
- The new `t/1222` regression is advertised in ISF public contract
  provenance.
- The next active R14 frontier is `ISF-RULE-ACTIONS.5`.

## 2026-05-14: R14 — ISF rule-expression assignment implementation
- Active R14 task-tree slice: `ISF-RULE-ACTIONS.3` is complete.
- Rule assignment actions now accept scalar-or-list RHS expressions and lower
  them as existing flopped `<-` rule assignments.
- New coverage proves scheduled `.fsm` emission, assignment provenance, normal
  `.fsm` frontend parsing, and HDL generation.
- The full ISF regression tier passed after the parser/lowerer change.
- The next active R14 frontier is `ISF-RULE-ACTIONS.4`.

## 2026-05-14: R14 — ISF rule-expression assignment specification
- Active R14 task-tree slice: `ISF-RULE-ACTIONS.2` is complete.
- Expression-valued rule assignments are specified as `(port expr)` with
  scalar `port`, scalar-or-list `.fsm` RHS expressions, and existing flopped
  `<-` rule assignment semantics.
- Rule guards remain scalar in this slice; alternate rule assignment operators
  and broad new width inference remain deferred.
- The next active R14 frontier is `ISF-RULE-ACTIONS.3`.

## 2026-05-14: R14 — ISF rule-action behavior inventory
- Active R14 task-tree slice: `ISF-RULE-ACTIONS.1` is complete.
- The task tree now inventories current rule guard/action parsing,
  malformed-boundary diagnostics, scalar-only limits, lowering behavior,
  schedule-report/storage metadata, and conflict touchpoints.
- The mdBook rule/backlog text now reflects that rule-local priority feeds the
  covered priority/resource paths.
- The next active R14 frontier is `ISF-RULE-ACTIONS.2`.

## 2026-05-14: R14 — ISF shareable resource kind catalog
- Active R14 task-tree slice: `ISF-RESOURCE-CATALOG.1` is complete.
- Public ISF documentation now lists the growable shareable resource kind
  catalog across the spec, mdBook, public contract, and feature backlog.
- `rule_slot` is the only shipped enforced kind today; `output_bundle`,
  `interface_bundle`, `named_drive`, `transaction_start`, `child_instance`,
  and `storage_port` remain backlog catalog names.
- Focused resource parser/lowering regressions and the mdBook build pass.
- The next active R14 frontier remains `ISF-RULE-ACTIONS.1`.

## 2026-05-14: R14 — ISF resource/priority tree closure
- Active R14 task-tree slice: `ISF-RESOURCE-PRIORITY.6` is complete.
- The `ISF-RESOURCE-PRIORITY` task tree is closed and moved to the completed
  task-tree table.
- Covered behavior now includes parser/resource boundaries, priority-arbitrated
  `rule_slot`, target-local priority, fail-closed diagnostics, and bounded
  arbitration schedule-report metadata.
- The next active R14 frontier is `ISF-RULE-ACTIONS.1`.

## 2026-05-14: R14 — ISF arbitration schedule-report projection
- Active R14 task-tree slice: `ISF-RESOURCE-PRIORITY.5` is complete.
- Successful schedule reports now expose `priority_resolutions` and
  `resource_arbitration` arrays for bounded static arbitration decisions.
- The in-process scheduler and CLI JSON path are covered by
  `t/1220-isf-arbitration-schedule-report.t`.
- The next active R14 frontier is `ISF-RESOURCE-PRIORITY.6`.

## 2026-05-14: R14 — ISF rule/transaction priority resolution
- Active R14 task-tree slice: `ISF-RESOURCE-PRIORITY.4` is complete.
- Actor-level rule-over-transaction priority now resolves the covered
  same-target data conflict by guarding the transaction-state assignment with
  the inverse active rule condition.
- Unordered rule/transaction conflicts, priority cycles, mixed timing
  conflicts, and transaction-over-rule priority fail closed.
- The next active R14 frontier is `ISF-RESOURCE-PRIORITY.5`.

## 2026-05-14: R14 — ISF rule-slot resource enforcement
- Active R14 task-tree slice: `ISF-RESOURCE-PRIORITY.3` is complete.
- ISF now enforces priority-arbitrated `rule_slot` resources by gating bound
  rule DT enables with resource grants.
- New parser support accepts `(kind ...)` and `(users ...)` resource
  subclauses, while unsupported bound resource kinds and `round_robin` bound
  resources fail closed.
- The next active R14 frontier is `ISF-RESOURCE-PRIORITY.4`.

## 2026-05-14: R14 — ISF resource/priority arbitration semantics
- Active R14 task-tree slice: `ISF-RESOURCE-PRIORITY.2` is complete.
- ISF resource semantics now have a growable shareable-resource catalog. The
  first implementation target is `rule_slot`, a one-cycle mutual-exclusion
  resource for rule users.
- Planned but unshipped kinds include `output_bundle`, `interface_bundle`,
  `named_drive`, `transaction_start`, `child_instance`, and `storage_port`;
  unsupported kinds must fail closed until their lowering contracts ship.
- The next active R14 frontier is `ISF-RESOURCE-PRIORITY.3`.

## 2026-05-14: R14 — ISF resource/priority metadata inventory
- Active R14 task-tree slice: `ISF-RESOURCE-PRIORITY.1` is complete.
- The task tree now records accepted resource and priority forms, parser
  validations, current same-target rule/rule priority enforcement,
  schedule-report exposure gaps, and resource arbitration gaps.
- Resources remain validated metadata only; priority currently resolves only
  the covered rule/rule data-conflict case.
- The next active R14 frontier is `ISF-RESOURCE-PRIORITY.2`, which must define
  supported arbitration and priority semantics before implementation.

## 2026-05-14: R14 — ISF composition tree closure
- Active R14 task-tree slice: `ISF-COMPOSITION.6` is complete.
- The `ISF-COMPOSITION` tree is now closed and moved to the completed
  task-tree table.
- The realistic `isf/spawn_parent.isf` fixture now covers generated-composition
  metadata through both in-process and CLI schedule-report paths.
- The next active R14 frontier is `ISF-RESOURCE-PRIORITY.1`.

## 2026-05-14: R14 — ISF composition report/diagnostic closure
- Active R14 task-tree slice: `ISF-COMPOSITION.5.4` is complete.
- The generated-composition report/diagnostic sub-tree is closed with schema,
  projection, contextual handoff diagnostics, tests, contract docs, mdBook,
  roadmap, and live docs aligned.
- At completion time, the next frontier moved to `ISF-COMPOSITION.6`.

## 2026-05-14: R14 — ISF generated handoff diagnostics
- Active R14 task-tree slice: `ISF-COMPOSITION.5.3` is complete.
- Generated-composition handoff port-name conflicts now fail before
  generated-top emission with diagnostics naming the transaction, spawn
  instance, handoff role, and named drive/parameter when applicable.
- At completion time, the next frontier moved to `ISF-COMPOSITION.5.4` for
  final report/diagnostic closure.

## 2026-05-14: R14 — ISF composition report projection
- Active R14 task-tree slice: `ISF-COMPOSITION.5.2` is complete.
- Schedule JSON now emits the live `generated_composition` discovery field for
  spawned-child generated tops while using JSON null for non-composed actors.
- The ISF public-interface contract and capability manifest advertise the
  generated-composition key families and keep the API explicitly live rather
  than frozen.
- At completion time, the next frontier moved to `ISF-COMPOSITION.5.3` for
  targeted generated-composition diagnostics.

## 2026-05-14: R14 — ISF composition report schema
- Active R14 task-tree slice: `ISF-COMPOSITION.5.1` is complete.
- The bounded `generated_composition` schedule-report field is defined for
  generated top, parent, child, instance, handoff, and parameter-binding
  summaries.
- At completion time, the next frontier moved to `ISF-COMPOSITION.5.2` for
  emitter and contract implementation.

## 2026-05-14: R14 — ISF composition report/diagnostic split
- Active R14 task-tree slice: `ISF-COMPOSITION.5` is now split into executable
  leaves.
- The next report/diagnostic work is schema-first, followed by successful
  generated-composition report projection, targeted diagnostics, and closure.
- The active `ISF-COMPOSITION` frontier is now `ISF-COMPOSITION.5.1`.

## 2026-05-14: R14 — ISF intent abstraction layers
- Active R14 task-tree slice: documentation-only `ISF-PUBLIC-CONTRACT.6` is
  complete.
- The ISF book, spec, and public contract now name `.fsm` as IAL0 and current
  `.isf` as IAL1.
- Possible IAL2 work is only backlog exploration for real protocol/platform
  semantics above transactions; aliases/macros/sugar without distinct runtime
  meaning are not enough reason to create another layer.
- The active R14 composition frontier remains `ISF-COMPOSITION.5`.

## 2026-05-14: R14 — ISF construct semantics invariant
- Active R14 task-tree slice: documentation-only `ISF-PUBLIC-CONTRACT.5` is
  complete.
- The ISF book, spec, and public contract now state that every shipped
  construct needs explicit source shape, lowering path, runtime semantics,
  diagnostics boundary, downstream visibility, and regression evidence.
- Parser acceptance alone is not a support claim; incomplete constructs remain
  deferred, backlog, or validated compatibility input.
- The active R14 composition frontier remains `ISF-COMPOSITION.5`.

## 2026-05-14: R14 — ISF spawn/repeat lifetime clarification
- Active R14 task-tree slice: documentation-only `ISF-COMPOSITION.7` is
  complete.
- The book and live ISF docs now define `spawn` as static HDL composition plus
  runtime activation. Future `spawn` inside `repeat` must reuse the same
  lexical instance and must not imply dynamic hardware creation.
- Dynamic repeat counts are documented as runtime counter loads, with
  data-dependent latency plus zero-count and busy/re-entry policy remaining as
  explicit backlog boundaries.
- The next frontier remains `ISF-COMPOSITION.5`.

## 2026-05-14: R14 — ISF generated composition top handoff
- Active R14 task-tree slice: `ISF-COMPOSITION.4` is complete.
- Spawned-child ISF lowering now emits a generated `<actor>_top.fsm`
  composition source, and the CLI uses it as the HDL entrypoint when present.
- The generated top wires parent start outputs, child done outputs, child
  named-drive handoff outputs, and per-instance spawn parameter overrides
  through the existing composition pipeline.
- The next frontier is `ISF-COMPOSITION.5`.

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
  for configured and defaulted legacy single-clock reset hashes, with null
  reserved for domain-owned omitted resets.

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
  aligned with APB plus no-watchdog reports that now use the default scalar
  watchdog limit.

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

## 2026-05-26: Prior-observation second post-spawn await_any book truth sync
- Roadmap lane: `R14 documentation truth sync`.
- Completed slice:
  [`ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.1`](docs/tasks/ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.md)
  closes the picky-audit-identified gap between the already-shipped validator
  contract at `perl/FSM/Scheduler/ISF/LoweringIR.pm:6470` and the mdBook
  chapters `13h-lowering-reference.md`, `13b-transactions.md`, and
  `13k-isf-feature-support-matrix.md`, plus the
  `documents_stale_domain_prior_await_any_second_post_spawn_deferral` helper
  and the `@prior_observation_second_await_any_truth_docs` audit list in
  `t/1307-isf-loop-body-doc-truth-audit.t`.
- Public behavior changed: no; doc/test sync only.
- Focused validation passed:
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t
  t/1305-isf-book-feature-matrix-audit.t
  t/1307-isf-loop-body-doc-truth-audit.t` (Files=3, Tests=803);
  `mdbook build docs/book`; `git diff --check`.
- Next bounded slice: hand off to whichever R14 ISF feature lane the roadmap
  selects next.

## 2026-05-26: Plain generated-child switch-branch second-awaitany missing-drain coverage shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md)
  added the switch-branch `assert_lower_rejected` regression for the plain
  generated-child `(do worker)` prior-`await_any` then spawn then second
  post-spawn `await_any` without final same-body `(await_all done)` shape,
  matching the existing validator confess at `LoweringIR.pm:6551` for the
  `'generated-child do'` kind. The when-body counterpart already lived in
  `t/1215`.
- Public behavior changed: no; test-only.
- Focused validation passed:
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: param missing-drain SECOND-AWAITANY coverage.

## 2026-05-26: Static-parameter generated-do second-awaitany missing-drain coverage shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-GENDO-PARAM-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-GENDO-PARAM-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md)
  added when-body and switch-branch `assert_lower_rejected` regressions for
  the static-parameter generated `(do child (params ...))` prior-`await_any`
  then spawn then second post-spawn `await_any` without final same-body
  `(await_all done)` shape, matching the existing validator confess at
  `LoweringIR.pm:6551` for the `'generated do with static params'` kind.
- Public behavior changed: no; test-only.
- Focused validation passed:
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: bound missing-drain SECOND-AWAITANY coverage.

## 2026-05-26: Bound generated-do second-awaitany missing-drain coverage shipped — matrix complete
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md)
  added when-body and switch-branch `assert_lower_rejected` regressions for
  the bound generated `(do child (params ...) (bind ...))` prior-`await_any`
  then spawn then second post-spawn `await_any` without final same-body
  `(await_all done)` shape, matching the existing validator confess at
  `LoweringIR.pm:6551` for the `'generated do with static params and
  bindings'` kind. The SECOND-AWAITANY missing-drain regression matrix is
  now complete across the five generated-do families.
- Public behavior changed: no; test-only.
- Focused validation passed:
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: pick the next R14 ISF feature lane.

## 2026-05-26: Plain generated-child switch-branch spawn-after-do missing-drain coverage shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md)
  added the switch-branch `assert_lower_rejected` regression for the plain
  generated-child `(do worker)` prior-`await_any` then later generated
  spawn without final same-body `(await_all done)` drain shape, matching
  the existing validator confess at `LoweringIR.pm:6551` for the
  `'generated-child do'` kind. The when-body counterpart already lived in
  `t/1215`.
- Public behavior changed: no; test-only.
- Focused validation passed:
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: static-parameter switch-branch SPAWN-AFTER-DO
  missing-drain coverage.

## 2026-05-26: Static-parameter switch-branch spawn-after-do missing-drain coverage shipped — matrix complete
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md)
  added the switch-branch `assert_lower_rejected` regression for the
  static-parameter generated `(do worker (params ...))` prior-`await_any`
  then later generated spawn without final same-body `(await_all done)`
  drain shape, matching the existing validator confess at
  `LoweringIR.pm:6551` for the `'generated do with static params'` kind.
  With this slice the SPAWN-AFTER-DO without-drain matrix is complete
  across the five generated-do families on both branch-contained subsets.
- Public behavior changed: no; test-only.
- Focused validation passed:
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: pick the next R14 ISF feature lane or audit a
  different coverage matrix.

## 2026-05-27: Local-do before-post-do await_any missing-drain coverage shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-LOCALDO-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-LOCALDO-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md)
  added when-body and switch-branch `assert_lower_rejected` regressions for
  the local `(do local_worker)` then post-do multi-pending `(await_any done)`
  without final `(await_all done)` shape, matching the existing validator
  confess at `LoweringIR.pm:6551` for the local-do label.
- Public behavior changed: no; test-only.
- Focused validation passed:
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: plain generated-child BEFORE-POST-DO-AWAITANY
  missing-drain coverage.

## 2026-05-27: Plain generated-child before-post-do await_any missing-drain coverage shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md)
  added when-body and switch-branch `assert_lower_rejected` regressions
  for the plain generated-child `(do worker)` before post-do multi-pending
  `(await_any done)` without final `(await_all done)` shape.
- Public behavior changed: no; test-only.
- Focused validation passed:
  `prove -Iperl t/1215-isf-spawn-parameter-binding.t` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: static-parameter BEFORE-POST-DO-AWAITANY missing-drain
  coverage.

## 2026-05-27: Static-parameter before-post-do await_any missing-drain coverage shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md)
  added when-body and switch-branch `assert_lower_rejected` regressions for
  the static-parameter `(do worker (params ...))` before post-do
  multi-pending `(await_any done)` without final `(await_all done)` shape.
- Public behavior changed: no; test-only.
- Focused validation passed: `prove -Iperl t/1215` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: bound BEFORE-POST-DO-AWAITANY missing-drain coverage
  (when-body only; switch-branch already exists).

## 2026-05-27: Bound when-body before-post-do await_any missing-drain coverage shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md)
  added the when-body `assert_lower_rejected` regression for the bound
  generated `(do worker (params ...) (bind ...))` before post-do
  multi-pending `(await_any done)` without final `(await_all done)` shape.
- Public behavior changed: no; test-only.
- Focused validation passed: `prove -Iperl t/1215` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: domain BEFORE-POST-DO-AWAITANY missing-drain coverage.

## 2026-05-27: Same-domain before-post-do await_any missing-drain coverage shipped — matrix complete
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-REPEAT-GENDO-DOMAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.1`](docs/tasks/ISF-REPEAT-GENDO-DOMAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md)
  added when-body and switch-branch `assert_lower_rejected` regressions
  for the same-domain `(do worker (params ...) (bind ...) (domain core))`
  before post-do multi-pending `(await_any done)` without final
  `(await_all done)` shape. With this slice the BEFORE-POST-DO-AWAITANY
  missing-drain matrix is complete across the five generated-do families
  on both branch-contained subsets.
- Public behavior changed: no; test-only.
- Focused validation passed: `prove -Iperl t/1215` (Files=1, Tests=100);
  `mdbook build docs/book`; `./bin/ci-regression isf --no-book`;
  `git diff --check`.
- Next bounded slice: hand off to whichever R14 ISF feature lane the roadmap
  selects next.

## 2026-05-27: Selected R14 data-op activation-override width gate
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE`](docs/tasks/ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.md).
- Goal: widen the activation-site parameter override-specialized
  default-preserving gate from timing-parameter contexts to data-operation
  width contexts (`shift_left`, `shift_right`, `assemble`, `extract`).
- Public behavior changed: no; this `.1: select` commit only registers the
  task tree.
- Focused validation passed: `mdbook build docs/book`; `git diff --check`.
- Next bounded slice:
  `ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.2` (validator gate +
  `t/1370` regression + doc-surface updates).

## 2026-05-27: Data-op activation-override width gate shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.2`](docs/tasks/ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.md)
  widened the validator activation-site default-preserving gate from
  timing-parameter contexts to data-operation width contexts
  (`shift_left`, `shift_right`, `assemble`, `extract`). Mismatched
  activation overrides on a generated child's transaction parameter
  consumed by a data-op width now fail closed with a targeted
  `static-width parameter` diagnostic.
- Public behavior changed: yes — previously-silently-accepted
  mismatched overrides for data-op width parameters now fail closed.
  Same-value overrides keep working; unrelated overrides keep working;
  static-timing/contract precedence preserved.
- Focused validation passed: `prove -Iperl t/1370 t/1369 t/1367 t/1366
  t/1305 t/1307` (Files=6, Tests=715); `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`; `git diff --check`.
- Next bounded slice: hand off to whichever R14 ISF feature lane the
  roadmap selects next.

## 2026-05-27: Selected R14 transaction port activation-override width gate
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE`](docs/tasks/ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.md).
- Goal: widen the activation-site parameter override-specialized
  default-preserving gate to transaction port width contexts.
- Public behavior changed: no; this `.1: select` commit only registers
  the task tree.
- Focused validation passed: `mdbook build docs/book`; `git diff --check`.
- Next bounded slice:
  `ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.2` (validator
  gate + `t/1371` regression + doc-surface updates).

## 2026-05-27: Transaction port activation-override width gate shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.2`](docs/tasks/ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.md)
  widened the validator activation-site default-preserving gate to
  transaction port width contexts. Mismatched activation overrides on a
  generated child's transaction parameter consumed by a port width now
  fail closed with a targeted `static port-width parameter` diagnostic.
- Public behavior changed: yes — previously-silently-accepted
  mismatched overrides for transaction port width parameters now fail
  closed. Same-value overrides keep working; unrelated overrides keep
  working; data-op-width and static-timing precedence preserved.
- Focused validation passed: `prove -Iperl t/1371 t/1370 t/1369 t/1368
  t/1250 t/1305 t/1307` (Files=7, Tests=718); `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`; `git diff --check`.
- Next bounded slice: hand off to whichever R14 ISF feature lane the
  roadmap selects next.

## 2026-05-27: Selected R14 cross-domain repeat-body do diagnostic precision
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION`](docs/tasks/ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.md).
- Goal: emit a targeted "cross-domain repeat-body do remains deferred"
  diagnostic when a `(do TARGET (domain X))` annotation names a domain
  different from the calling transaction's domain. Broader cross-domain
  `do` implementation remains a future leaf.
- Public behavior changed: no; `.1: select` commit only registers the
  task tree.
- Focused validation passed: `mdbook build docs/book`; `git diff --check`.
- Next bounded slice:
  `ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.2` (validator
  change + `t/1372` regression + doc-surface updates).

## 2026-05-27: Cross-domain repeat-body do diagnostic precision shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.2`](docs/tasks/ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.md)
  shipped the targeted cross-domain repeat-body do diagnostic at all
  three nested-repeat sites, refreshed `t/1247` expectations, and
  synchronized `ISF_SPEC.md`/`ISF_DOWNSTREAM_INTEGRATION_SPEC.md`/
  `14-feature-backlog.md`.
- Public behavior changed: yes — the diagnostic for cross-domain
  repeat-body do with `(domain ...)` annotation is now precise instead
  of misleadingly suggesting `(params)`. Same-domain rejections and
  no-annotation rejections unchanged.
- Focused validation passed: `prove -Iperl t/1247 t/1372 t/1250`
  (Files=3, Tests=17); `mdbook build docs/book`;
  `./bin/ci-regression isf --no-book`; `git diff --check`.
- Next bounded slice: another item from the backlog (broader
  cross-domain do lowering remains a future leaf of this same tree).

## 2026-05-27: Selected R14 static-timing override sub-axis diagnostic precision
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION`](docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.md).
- Goal: split the aggregated static-timing override gate into four
  sub-axis-specific gates (repeat-count, wait-count, latency-bound,
  watchdog-limit) at the spawn/do and rule-trigger activation sites.
  Each sub-axis emits its own targeted diagnostic and its own
  deferral phrase. Same-value paths unchanged.
- Public behavior changed: no; `.1: select` commit only registers
  the task tree.
- Focused validation passed: `mdbook build docs/book`; `git diff --check`.
- Next bounded slice:
  `ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.2`
  (validator split + `t/1373` regression + `t/1369`/`t/1370`
  refresh + doc-surface updates).

## 2026-05-27: Static-timing override sub-axis diagnostic precision shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.2`](docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.md)
  shipped the four sub-axis-specific diagnostics at both
  activation-override sites (spawn/do and rule trigger), added
  regression `t/1373`, refreshed `t/1369` and `t/1370` expectations,
  and synchronized `ISF_SPEC.md`/`ISF_DOWNSTREAM_INTEGRATION_SPEC.md`/
  `14-feature-backlog.md`.
- Public behavior changed: yes — mismatched overrides on repeat-count,
  wait-count, latency-bound, and watchdog-limit parameters now each
  emit their own targeted diagnostic instead of one aggregated
  `static-timing parameter` message. Same-value paths and
  unknown/shape precedence unchanged.
- Focused validation passed: `prove -Iperl t/1369 t/1370 t/1373`
  (Files=3, Tests=12); `./bin/ci-regression isf --no-book`
  (Files=279, Tests=2037); `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: another item from the backlog (broader
  implementation of each sub-axis remains separately deferred per
  their own future lanes).

## 2026-05-27: Selected R14 loop-contained repeat-body activation diagnostic precision
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION`](docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md).
- Goal: emit a targeted `loop-contained repeat-body <do|spawn>
  remains deferred` diagnostic when a `(repeat ...)` with `do` or
  `spawn` body clauses is nested inside `(while ...)` or `(until
  ...)`. Other unsupported nested-repeat cases keep their existing
  generic message. Broader loop-contained implementation remains a
  future leaf.
- Public behavior changed: no; `.1: select` commit only registers
  the task tree.
- Focused validation passed: `mdbook build docs/book`; `git diff --check`.
- Next bounded slice:
  `ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`
  (validator change + `t/1374` regression + doc-surface updates).

## 2026-05-27: Loop-contained repeat-body activation diagnostic precision shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`](docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md)
  shipped the targeted loop-contained repeat-body do/spawn diagnostic
  at the two unsupported-repeat-body subset entry points, added
  regression `t/1374`, and synchronized `ISF_SPEC.md`/
  `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`/`14-feature-backlog.md`.
- Public behavior changed: yes — loop-contained
  `(repeat ... (do|spawn ...))` now fails closed with a targeted
  diagnostic instead of the generic "supported only for top-level..."
  message. Other unsupported nested-repeat cases unchanged.
- Focused validation passed: `prove -Iperl t/1374 t/1215`
  (Files=2, Tests=103); `./bin/ci-regression isf --no-book`
  (Files=280, Tests=2040); `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: another item from the backlog (broader
  loop-contained repeat activation implementation remains a future
  leaf of this same tree).

## 2026-05-27: Selected R14 deeper-nested repeat-body activation diagnostic precision
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION`](docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md).
- Goal: emit a targeted `deeper-nested repeat-body <do|spawn>
  remains deferred` diagnostic for deeper-when and when-inside-switch
  cases at the two repeat-body subset entry points. Loop-contained
  unchanged; generic message kept as safety-net fallback. Broader
  deeper-nested implementation remains a future leaf.
- Public behavior changed: no; `.1: select` commit only registers
  the task tree.
- Focused validation passed: `mdbook build docs/book`; `git diff --check`.
- Next bounded slice:
  `ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`
  (validator change + `t/1375` regression + `t/1215` refresh + doc
  updates).

## 2026-05-27: Deeper-nested repeat-body activation diagnostic precision shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.2`](docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md)
  shipped the targeted deeper-nested repeat-body do/spawn diagnostic
  at the two unsupported-repeat-body subset entry points, added
  regression `t/1375`, refreshed `t/1215` and `t/1374` expectations,
  and synchronized `ISF_SPEC.md`/
  `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`/`14-feature-backlog.md`.
- Public behavior changed: yes — deeper-when nesting and
  when-inside-switch nesting now fail closed with a targeted
  diagnostic instead of the generic "supported only for top-level..."
  message. Loop-contained continues to fire its targeted diagnostic
  first; generic message retained as safety-net fallback.
- Focused validation passed: `prove -Iperl t/1215 t/1374 t/1375`
  (Files=3, Tests=108); `./bin/ci-regression isf --no-book`
  (Files=281, Tests=2045); `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: another item from the backlog (broader
  deeper-nested repeat activation implementation remains a future
  leaf of this same tree).

## 2026-05-27: Bootstrap import-tree count refreshed after diagnostic-precision slices
- Roadmap lane: `R14`.
- Completed slice:
  [`BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.1`](docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.md)
  refreshed the recorded `perl/FSM/Scheduler/ISF/LoweringIR.pm`
  line count from `11144` to `11309` (+165) after the four R14
  diagnostic-precision slices added cumulative validator code.
  Topology unchanged at `total=196`, `pm=195`, `bin/fsmgen=1175`.
- Public behavior changed: no — doc-only architecture maintenance.
- Focused validation passed:
  `wc -l perl/FSM/Scheduler/ISF/LoweringIR.pm` confirms `11309`;
  `wc -l bin/fsmgen` confirms `1175`; stale `11144` grep clean
  against the live import-tree note; `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: another item from the backlog.

## 2026-05-27: Selected R14 loop-contained and deeper-nested diagnostic doc-truth sync
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC`](docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.md).
- Goal: extend the targeted-diagnostic synchronization for the
  loop-contained and deeper-nested slices to book chapters
  `13b-transactions.md`, `13d-control-flow.md`,
  `13h-lowering-reference.md`, and `13k-isf-feature-support-matrix.md`.
- Public behavior changed: no; `.1: select` commit only registers
  the task tree.
- Focused validation passed: `mdbook build docs/book`; `git diff --check`.
- Next bounded slice:
  `ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.2`
  (book prose updates + audit reverification).

## 2026-05-27: Loop-contained and deeper-nested diagnostic doc-truth sync shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.2`](docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.md)
  updated the four book chapters that mention deeper-branch and
  loop-contained repeat deferrals to also describe the new targeted
  diagnostics. Doc-truth coverage for the targeted-diagnostic
  shipped surface is now complete.
- Public behavior changed: no — pure doc-truth sync.
- Focused validation passed: `prove -Iperl t/1305 t/1307 t/1332`
  (Files=3, Tests=709); `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: another item from the backlog.

## 2026-05-27: Selected R14 book examples for new targeted diagnostics
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE`](docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.md).
- Goal: add user-facing `.fsm` source examples to book chapters
  showing the rejected shape for each of the seven targeted
  diagnostics shipped this session. Activation-override examples in
  13b; loop-contained and deeper-nested examples in 13d.
- Public behavior changed: no; `.1: select` commit only registers
  the task tree.
- Focused validation passed: `mdbook build docs/book`; `git diff --check`.
- Next bounded slice:
  `ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.2` (book example
  fragments + audit reverification).

## 2026-05-27: Book examples for new targeted diagnostics shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.2`](docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.md)
  added seven user-facing `.fsm` source examples to the book
  (five in 13b for cross-domain repeat-body do plus the four
  activation-override sub-axis gates; two in 13d for loop-contained
  and deeper-nested). Each example shows the rejected shape,
  verbatim diagnostic, and deferred-lane note.
- Public behavior changed: no — pure book-content slice.
- Focused validation passed: `prove -Iperl t/1305 t/1307 t/1332`
  (Files=3, Tests=709); `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: another item from the backlog (a broader
  audit of feature-example coverage across the book is a future
  task tree).

## 2026-05-27: mdBook coverage audit published
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-MDBOOK-COVERAGE-AUDIT.1`](docs/tasks/ISF-MDBOOK-COVERAGE-AUDIT.md)
  produced
  [`docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md`](docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md)
  — a comprehensive one-shot audit of the FSMGen mdBook against
  the shipped codebase surface.
- Eight gap categories (G1-G8) and a prioritized slice queue.
  Highest-impact finding: cookbook chapter has zero ISF recipes
  despite ISF being the primary authoring layer.
- Public behavior changed: no — pure doc audit.
- Focused validation passed: `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: the user selects the next coverage slice
  from the audit queue.

## 2026-05-27: Selected R14 G1 cookbook ISF recipes
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-COOKBOOK-RECIPES-G1`](docs/tasks/ISF-COOKBOOK-RECIPES-G1.md).
- Goal: add five ISF recipes to cookbook chapter 12 spanning the
  core authoring surface (basic actor, spawn, parameterized
  blocking do, rule trigger, repeat-body generated do).
- Public behavior changed: no; `.1: select` commit only registers
  the task tree.
- Focused validation passed: `mdbook build docs/book`; `git diff --check`.
- Next bounded slice: `ISF-COOKBOOK-RECIPES-G1.2` (recipes +
  parse/lower validation + audit reverification).

## 2026-05-27: G1 cookbook ISF recipes shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-COOKBOOK-RECIPES-G1.2`](docs/tasks/ISF-COOKBOOK-RECIPES-G1.md)
  added five ISF recipes (9-13) to cookbook chapter 12. Each
  recipe was verified to parse and lower cleanly through the
  full ISF stack before commit.
- Public behavior changed: no — pure book content.
- Focused validation passed: `prove -Iperl t/1305 t/1307 t/1332`
  (Files=3, Tests=709); each recipe parses+lowers; `mdbook build
  docs/book`; `git diff --check`.
- Next bounded slice: audit gap G3 (remaining `remains deferred`
  diagnostics without book example) or G7 (13d accept-path
  examples) per the audit queue.

## 2026-05-29: Example-correctness audit addendum published
- Roadmap lane: `R14`.
- Triggered by the user's new requirement that every `.isf`
  example in the book must lower cleanly to FSM.
- Scanned 275 `lisp` blocks across `12-cookbook.md`, `13*.md`,
  and `14-feature-backlog.md`. Found 15 failing complete-looking
  blocks (8 ellipsis shorthand, 4 multi-file references, 1
  multi-actor block, 1 intentional fail-closed illustration to
  keep, 1 real broken example).
- Audit findings appended to the existing
  [`docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md`](docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md)
  as the example-correctness addendum.
- Public behavior changed: no — doc-only.
- Next bounded slice: `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX` (resolve
  each issue per the disposition listed in the addendum), then
  continue with the G2-G8 queue with the stricter
  "lowers-cleanly-and-fully-explained" standard for all new
  examples.

## 2026-05-29: Selected R14 example-correctness fix
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-BOOK-EXAMPLE-CORRECTNESS-FIX`](docs/tasks/ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.md).
- Goal: resolve the 14 parse-fail and 1 lower-fail issues
  identified in the audit addendum. Plan per category: convert
  ellipsis fragments to text blocks, embed library/package
  fixtures inline, supply the missing drive, annotate the
  intentional fail-closed illustration.
- Public behavior changed: no; `.1: select` commit only registers
  the task tree.
- Focused validation passed: `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: `ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.2`.

## 2026-05-29: Example-correctness fix shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.2`](docs/tasks/ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.md)
  resolved all 15 failing blocks across 7 book chapters. Real bug
  fix in `13-intent-scheduling.md`; two complete-example expansions
  in `13a` and `13c`; 11 ellipsis/library/multi-file blocks
  converted to `text` with lead-ins.
- Public behavior changed: no — book content only.
- Focused validation passed: re-run of the audit script reports
  20 complete fixtures lower cleanly + 0 failures (was 17 OK + 15
  failing); `prove -Iperl t/1305 t/1307 t/1332` (Files=3,
  Tests=709); `mdbook build docs/book`; `git diff --check`.
- Next bounded slice: enhance cookbook recipes 9-13 with
  walkthrough explanations (task #34), then proceed with audit
  gaps G2-G8 under the stricter "every example lowers cleanly and
  is thoroughly explained" standard.

## 2026-05-29: Selected R14 cookbook walkthroughs
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-COOKBOOK-WALKTHROUGHS`](docs/tasks/ISF-COOKBOOK-WALKTHROUGHS.md).
- Goal: add clause-by-clause walkthroughs to cookbook recipes
  9-13 so each recipe teaches the syntax in addition to
  illustrating a use case.
- Public behavior changed: no; `.1: select` commit only registers
  the task tree.
- Focused validation passed: `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: `ISF-COOKBOOK-WALKTHROUGHS.2`.

## 2026-05-29: Cookbook walkthroughs shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-COOKBOOK-WALKTHROUGHS.2`](docs/tasks/ISF-COOKBOOK-WALKTHROUGHS.md)
  added clause-by-clause walkthrough paragraphs to cookbook
  recipes 9-13. Each walkthrough names every top-level clause and
  explains its contribution to the schedule.
- Public behavior changed: no — book content only.
- Focused validation passed: `prove -Iperl t/1305 t/1307 t/1332`
  (Files=3, Tests=709); `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: continue the G2-G8 queue under the stricter
  "every example lowers cleanly and is thoroughly explained"
  standard. Next is gap G3 (remaining `remains deferred`
  diagnostics without book example) or G7 (13d accept-path
  examples).

## 2026-05-29: Selected R14 G3 remaining-deferred examples
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-DIAGNOSTIC-EXAMPLES-G3`](docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-G3.md).
- Goal: add 4 representative examples (package-constant
  aggregate, two-child data route × 2, await_any-after-do/spawn)
  per audit gap G3.
- Public behavior changed: no; `.1: select` only.
- Validation: `mdbook build docs/book`; `git diff --check`.
- Next: `ISF-DIAGNOSTIC-EXAMPLES-G3.2`.

## 2026-05-29: G3 remaining-deferred examples shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-DIAGNOSTIC-EXAMPLES-G3.2`](docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-G3.md)
  added 4 rejection-shape illustrations + converted 11 prior
  rejection-fragment blocks from `lisp` to `text` after the user
  reiterated that `lisp`-tagged examples must lower cleanly.
- Public behavior changed: no — book content + block-tag
  convention only.
- Focused validation passed: re-audit script (20 OK, 0 failures);
  `prove -Iperl t/1305 t/1307 t/1332` (Files=3, Tests=709);
  `mdbook build docs/book`; `git diff --check`.
- Next bounded slice: the user requested a build-gate test that
  extracts every `lisp` block and verifies it lowers; that lands
  as `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE`. After that, continue
  the G2-G8 queue (G7 13d accept-path or G2 low-density clause
  keywords).

## 2026-05-29: Selected R14 book-example lowering build gate
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE`](docs/tasks/ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.md).
- Goal: add `t/1376-isf-book-example-lowering-audit.t` to enforce
  that every `lisp`-tagged book example parses and lowers
  cleanly. Build fails on any lowering error.
- Public behavior changed: no (test-only).
- Focused validation: `mdbook build docs/book`;
  `git diff --check`.
- Next: `ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.2`.

## 2026-05-29: Book-example lowering build gate shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.2`](docs/tasks/ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.md)
  added `t/1376` and registered it in the ISF_SPEC focused-tests
  list. The test enforces that every `lisp`-tagged book example
  lowers cleanly. Build fails on any lowering error.
- Public behavior changed: no — test addition only.
- Focused validation: `prove -Iperl t/1376 t/1305 t/1307 t/1332
  t/1250` (Files=5, Tests=713); `mdbook build docs/book`;
  `git diff --check`.
- Next bounded slice: continue the G2-G8 queue.

## 2026-05-29: Selected R14 downstream/contract handoff sync
- Roadmap lane: `R14`.
- Active task tree:
  [`ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC`](docs/tasks/ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.md).
- Goal: propagate the recent diagnostic surface (sub-axis,
  loop-contained, deeper-nested, t/1372-1376) to
  `ISF_PUBLIC_INTERFACE_CONTRACT.md` and add a current-status
  addendum to `SPECFORGE_FEEDBACK_RESPONSE.md`.
- Public behavior changed: no (.1 select).
- Next: `ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.2`.

## 2026-05-29: Downstream/contract handoff sync shipped
- Roadmap lane: `R14`.
- Completed slice:
  [`ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.2`](docs/tasks/ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.md)
  brought both stale downstream/contract docs up to date.
- `ISF_PUBLIC_INTERFACE_CONTRACT.md` activation-override section
  now references `t/1372-1376` and carries sub-axis,
  loop-contained, deeper-nested, and book-lowering-gate wording.
- `SPECFORGE_FEEDBACK_RESPONSE.md` got a dated addendum
  summarising the targeted diagnostic surface, the lisp/text
  block convention, the build gate, the cookbook recipes, and
  the current audit set.
- Public behavior changed: no — doc surfaces only.
- Focused validation passed: `prove -Iperl t/1305 t/1307 t/1332
  t/1376` (Files=4, Tests=711); `mdbook build docs/book`;
  `git diff --check`.
- Next: continue the G2-G8 queue.

## 2026-05-29: Selected R14 G7 13d accept-path examples
- Active tree: `ISF-G7-13D-ACCEPT-PATH-EXAMPLES`. Adds 4 complete
  accept-path actor fixtures + walkthroughs to 13d.
- `.1` is this selection commit.

## 2026-05-29: G7 13d accept-path examples shipped
- 4 fixtures added; t/1376 now reports 24 complete fixtures lower
  cleanly (was 20). Audits clean.

## 2026-05-29: Selected R14 G6 13j examples
- `ISF-G6-13J-EXAMPLES`. Three fixtures for 13j.

## 2026-05-29: G6 13j examples shipped
- 3 fixtures added; t/1376 24 → 27. Audits clean.
