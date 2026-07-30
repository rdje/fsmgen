# PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT: Audit Generated Instance Names

## Metadata

- Tree ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT`
- Status: `done`
- Roadmap lane: `HDL quality / protocol composition identifiers`
- Created: `2026-07-23`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Audit generated composition instance names against target-HDL reserved words
and select one shared fail-closed or deterministic-renaming policy.

## Origin And Evidence

`IAL2-FEATURE-COMPLETENESS-FRONTIER.794` found that the AHB aggregate emitted
instance name `interconnect`, a SystemVerilog keyword, so otherwise valid
generated `ahb_tb` failed Verilator parsing. The AHB path now uses `fabric`.
`ApbComposition.pm` still selects `interconnect` for generated multi-peripheral
tops, showing that the issue may be cross-protocol rather than AHB-only.

## Non-Goals

- Do not change APB, AXI, VHDL, or shared identifier policy inside the active
  AHB paired-composition slice.
- Do not rename public module/object names unless an audit proves that is
  required; the observed defect concerns child instance identifiers.
- Do not activate while the current task-tree is dirty.

## Acceptance Criteria (when activated)

- Inventory generated child instance names across AHB, APB, AXI, reusable
  library, and actor-network composition paths.
- Check each target language's reserved-word handling and current identifier
  sanitizer/collision policy with deterministic focused probes.
- Select a shared diagnostic or rename rule that preserves stable report/top
  wiring names where legal and records any public report delta.
- Prove affected public compositions through target-language parsing/lint and
  synchronize docs, Knowledge Map, tasks/Memory, and gates.

## Task Tree

- ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT`
  Status: `done`
  Goal: `Audit generated child instance names against target-language reserved words before selecting a shared policy.`
  Children: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1`, `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.2`

- ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1`
  Status: `done`
  Goal: `Inventory and probe reserved generated instance identifiers without changing behavior.`
  Acceptance: `Enumerate composition instance-name producers, run focused target-language parser/lint probes for every risky identifier, and select a bounded shared remediation contract or close the concern with evidence. Make no behavior change in this audit.`
  Verification: `Activated only after clean selector commit b0bcb12b5 through clean continuity commit dc8df309c. Inventory covers direct C4, APB one-to-one/multi-peripheral, AHB, five AXI compositions, reusable-library use, spawn/generated do/rule-trigger, ATL static network, parent/domain/CDC producers, and both structural emitters. Strict focused probes reproduce Verilator unexpected interconnect through direct C4 (line 78), public APB (3134), reusable use (924), and spawn (598); public AHB fabric and AXI read labels pass Verilator plus Yosys. The syntax-only VHDL emitter accepts process and renders process : entity work.child_module; ghdl/nvc are unavailable and the full probed VHDL composition shapes remain separately target-gated. Decision 0027 selects a target-case-aware portable keyword union, fail-closed authored labels, deterministic generated keyword/collision allocation, authored/generated report separation, and emitter defenses. The exact repository-local audit and gate scratch is removed. All 36 mdBook chapters pass rustdoc and HTML build; feature-backlog/live-book/relative-path audits pass with Files=3, Tests=40; Knowledge Map validation passes at 1,072 facts / 5,521 question keys; memory architecture, diff hygiene, README 246-line and Memory 60-line caps pass. No parser, generator, test, config, artifact, report/API, HDL/runtime, backend, protocol, transaction, or target behavior changes in .1.`
  Commit: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1: select portable identifier contract`

- ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.2`
  Status: `done`
  Goal: `Implement and verify the selected portable child-instance identifier contract.`
  Acceptance: `From a separate clean activation, add one shared portable keyword registry and deterministic generated-name allocator; fail authored C4/spawn/library/ATL instance keywords at their nearest bounded source boundary; add structural-emitter defenses; integrate APB/AHB generated allocation; preserve every legal non-colliding AHB/AXI/ISF label; update APB generated interconnect wiring/report identity to interconnect_instance; cover direct, protocol, reusable-library, actor-network, SystemVerilog, and VHDL emitter routes with focused regressions; update user docs and public report expectations. Do not expand into module/top/port/net/parameter identifier families.`
  Verification: `Activated only from clean audit/decision commit 53a54c6c9. One shared SystemVerilog/VHDL-2008 keyword registry, authored-label validator, and case-safe generated allocator now cover direct C4, spawn, reusable-library use, ATL static instances, APB/AHB protocol children, and both structural emitters. Public APB uses interconnect_instance consistently in generated IAL0, derived HDL carriers, wiring, and reports; legal AHB fabric and fixed AXI labels remain stable. t1546 passes with Files=1, Tests=7 and exact verifier-stage assertions for verilator_lint/yosys_synthesis; the complete APB t1472 suite passes with Files=1, Tests=101; AHB, library, ATL, composition, and structural-emitter preservation tests pass. All ten changed Perl/test files report syntax OK. A confirmatory six-file guarded rerun was stopped before test execution because host memory measured 95.4% above the configured 88% cutoff; the already-recorded green focused results are retained rather than rerunning unbounded. Preservation testing exposed only an unrelated stale exact assertion expectation in t1502, traced by git log -S to grouped-rendering commit 80aa203ab and durably owned by proposed inactive ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.3. All 36 mdBook chapters pass mdbook test and HTML build; feature-backlog/live-book/relative-path audits pass with Files=3, Tests=40; Knowledge Map passes at 1,072 facts / 5,523 question keys. Repository-local book scratch is removed. Decision 0027, the audit, fact card, user docs, task/index, Memory, and changelog are synchronized. DEVELOPMENT_NOTES.md is unchanged because decision 0027 owns the rationale; ROADMAP_STATUS.md and LIVE_ACHIEVEMENT_STATUS.md remain untouched.`
  Commit: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.2: enforce portable instance identifiers`

## Decisions

- `2026-07-30`: Clean parent selector commit `b0bcb12b5` selects only `.1`;
  this continuity slice activates the no-behavior inventory/probe audit while
  leaving all identifier producers and generated outputs unchanged.
- `2026-07-30`: `.1` finds one shared syntax-only boundary across direct C4,
  protocol, library, spawn, and ATL producers. Decision `0027` selects a
  portable keyword union, authored fail-closed diagnostics, and deterministic
  generated allocation; proposed `.2` owns implementation and the explicit APB
  generated-label/report delta.
- `2026-07-30`: Clean audit commit `53a54c6c9` activates only `.2` so source
  implementation can begin from an explicit continuity boundary.
- `2026-07-30`: `.2` implements decision `0027`; public APB changes only its
  generated interconnect child identity to `interconnect_instance`, while legal
  AHB/AXI labels stay stable and authored keyword labels now fail at source.

## Blockers

- None. `.1` and `.2` are complete; the tree is exhausted.

## Acceptance Checklist — `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.2` (enforced)

- [x] **ROOT CAUSE (WHY + WHERE)** — Pre-fix strict direct-C4, public-APB,
  reusable-library, and spawn probes produced Verilator `%Error-` diagnostics
  for `unexpected interconnect` at generated lines 78, 3134, 924, and 598;
  source inspection localized the bypass to syntax-only validators and
  collision-only APB/AHB allocators.
- [x] **ADDRESSED (verified)** — `prove -Iperl
  t/1546-hdl-instance-identifier-policy.t` moves every authored route to an
  origin/target-aware early diagnostic, emits APB `interconnect_instance`, and
  passes public APB `verilator_lint` plus `yosys_synthesis`; the test reports
  `Files=1, Tests=7`.
- [x] **NO REGRESSION** — Focused policy and full APB runs report `All tests
  successful` at `Files=1, Tests=7` and `Files=1, Tests=101`; the AHB, library,
  ATL, composition, and structural-emitter preservation set is green, all ten
  changed Perl/test files report `syntax OK`, and Knowledge Map validation
  reports `knowledge-map: OK`. The final staged doctrine driver remains
  required before commit.
