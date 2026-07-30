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
  Children: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1`

- ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1`
  Status: `active`
  Goal: `Inventory and probe reserved generated instance identifiers without changing behavior.`
  Acceptance: `Enumerate composition instance-name producers, run focused target-language parser/lint probes for every risky identifier, and select a bounded shared remediation contract or close the concern with evidence. Make no behavior change in this audit.`
  Verification: `Activated only after clean selector commit b0bcb12b5. Current-HEAD evidence remains exact: APB seeds the generated interconnect role as interconnect, AHB seeds fabric, both local helpers avoid only declared-name collisions, and strict verification of public ppif/apb_composition_multi_peripheral.ppif fails Verilator at generated line 3134 on apb_interconnect interconnect (. Activation updates continuity surfaces only and changes no source, test, artifact, report/API, generated HDL, target behavior, or selected remediation. Feature-backlog status, live-book-path, and relative-path audits pass with Files=3, Tests=40; Knowledge Map generation/check passes at 1,071 facts / 5,513 question keys; mdBook HTML build and diff hygiene pass; Memory remains 60 lines and README remains 246 lines. The scheduled lifecycle review and every director gate remain inactive, both legacy status files remain untouched, and no probe artifact remains.`
  Commit: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1: activate generated identifier audit`

## Decisions

- `2026-07-30`: Clean parent selector commit `b0bcb12b5` selects only `.1`;
  this continuity slice activates the no-behavior inventory/probe audit while
  leaving all identifier producers and generated outputs unchanged.

## Blockers

- None. `.1` is active from the clean selector boundary.
