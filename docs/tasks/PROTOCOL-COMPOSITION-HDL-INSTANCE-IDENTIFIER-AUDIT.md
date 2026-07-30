# PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT: Audit Generated Instance Names

## Metadata

- Tree ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT`
- Status: `active`
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
  Status: `active`
  Goal: `Audit generated child instance names against target-language reserved words before selecting a shared policy.`
  Children: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1`, `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.2`

- ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1`
  Status: `done`
  Goal: `Inventory and probe reserved generated instance identifiers without changing behavior.`
  Acceptance: `Enumerate composition instance-name producers, run focused target-language parser/lint probes for every risky identifier, and select a bounded shared remediation contract or close the concern with evidence. Make no behavior change in this audit.`
  Verification: `Activated only after clean selector commit b0bcb12b5 through clean continuity commit dc8df309c. Inventory covers direct C4, APB one-to-one/multi-peripheral, AHB, five AXI compositions, reusable-library use, spawn/generated do/rule-trigger, ATL static network, parent/domain/CDC producers, and both structural emitters. Strict focused probes reproduce Verilator unexpected interconnect through direct C4 (line 78), public APB (3134), reusable use (924), and spawn (598); public AHB fabric and AXI read labels pass Verilator plus Yosys. The syntax-only VHDL emitter accepts process and renders process : entity work.child_module; ghdl/nvc are unavailable and the full probed VHDL composition shapes remain separately target-gated. Decision 0027 selects a target-case-aware portable keyword union, fail-closed authored labels, deterministic generated keyword/collision allocation, authored/generated report separation, and emitter defenses. The exact repository-local audit and gate scratch is removed. All 36 mdBook chapters pass rustdoc and HTML build; feature-backlog/live-book/relative-path audits pass with Files=3, Tests=40; Knowledge Map validation passes at 1,072 facts / 5,521 question keys; memory architecture, diff hygiene, README 246-line and Memory 60-line caps pass. No parser, generator, test, config, artifact, report/API, HDL/runtime, backend, protocol, transaction, or target behavior changes in .1.`
  Commit: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1: select portable identifier contract`

- ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.2`
  Status: `active`
  Goal: `Implement and verify the selected portable child-instance identifier contract.`
  Acceptance: `From a separate clean activation, add one shared portable keyword registry and deterministic generated-name allocator; fail authored C4/spawn/library/ATL instance keywords at their nearest bounded source boundary; add structural-emitter defenses; integrate APB/AHB generated allocation; preserve every legal non-colliding AHB/AXI/ISF label; update APB generated interconnect wiring/report identity to interconnect_instance; cover direct, protocol, reusable-library, actor-network, SystemVerilog, and VHDL emitter routes with focused regressions; update user docs and public report expectations. Do not expand into module/top/port/net/parameter identifier families.`
  Verification: `Activated only from clean audit/decision commit 53a54c6c9. This continuity slice changes task/index/Memory/changelog pointers only; the shared registry/allocator, source diagnostics, emitters, protocol generators, reports, tests, generated HDL, and target behavior remain unchanged. Decision 0027 and the audited implementation boundary are unchanged. Feature-backlog/live-book/relative-path audits pass with Files=3, Tests=40; Knowledge Map, Memory architecture at 60 lines, mdBook HTML build, and diff hygiene pass; exact book scratch is removed. The lifecycle review and all director-gated directions remain inactive; ROADMAP_STATUS.md and LIVE_ACHIEVEMENT_STATUS.md remain untouched.`
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

## Blockers

- None. `.2` is active from clean audit commit `53a54c6c9`.
