# PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT: Audit Generated Instance Names

## Metadata

- Tree ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT`
- Status: `proposed`
- Roadmap lane: `HDL quality / protocol composition identifiers`
- Created: `2026-07-23`
- Last updated: `2026-07-23`
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
  Status: `proposed`
  Goal: `Audit generated child instance names against target-language reserved words before selecting a shared policy.`
  Children: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1`

- ID: `PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1`
  Status: `pending`
  Goal: `Inventory and probe reserved generated instance identifiers without changing behavior.`
  Acceptance: `Enumerate composition instance-name producers, run focused target-language parser/lint probes for every risky identifier, and select a bounded shared remediation contract or close the concern with evidence. Make no behavior change in this audit.`
  Verification: `pending`
  Commit: `pending`

## Blockers

- Activation/order follows the task-tree pivot doctrine after ongoing active
  work dries out.
