# R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT: Portable-Type Contract Frontier Audit

## Metadata

- Tree ID: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`
- Status: `active`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the shipped portable synthesizable type surface and select one bounded
next contract slice or an explicit deferral from evidence.

## Non-Goals

- Do not implement new portable-type behavior in the activation leaf.
- Do not add new `+types` syntax, inference, aggregate member/index access,
  backend lowering, or VHDL behavior before the audit selects one exact
  surface.
- Do not change parser, type validation, composition planning, backend
  lowering, HDL emission, or generated artifacts during the activation leaf.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any
  portable-type behavior-bearing work.
- The audit leaf maps shipped evidence across scalar widths, enums, aggregate
  aliases, declared type identity, structural nets/ports, composition typed
  bindings, backend-owned typedef emission, package imports, direct roots,
  generated children, and explicit deferrals.
- The audit leaf records one next implementation slice or an explicit deferral
  if the remaining work depends on a stronger portable-type, inference,
  member/index access, backend-lowering, VHDL, or architecture contract.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT`
  Status: `active`
  Goal: `Audit the R11 portable synthesizable type frontier and choose the next bounded slice.`
  Children: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1`,
    `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2`

- ID: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the portable-type contract frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any portable-type behavior change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1: select portable-type frontier`

- ID: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2`
  Status: `pending`
  Goal: `Audit shipped portable-type behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any portable-type behavior change.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2` | `pending` | The next R11 left item is the portable synthesizable-type contract family, and the remaining directions require an evidence-led bounded selection before code. |

Current frontier: `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.2`.

## Decisions

- `2026-05-24`: Select a portable-type contract frontier audit after the
  reusable-module audit closed. The roadmap names several remaining
  directions across type-core settlement, future `+types` coexistence with
  enums, inference extent, inferred declarations, member/field and fixed-size
  array access, explicit type overrides, SystemVerilog lowering, and future
  VHDL lowering, so the next safe step is to map shipped evidence and choose
  one bounded implementation slice or deferral.

## Open Questions

- Does the remaining portable-type frontier contain one bounded immediate
  implementation slice, or should the next behavior-bearing work wait for a
  stronger portable-type, inference, member/index access, backend-lowering,
  VHDL, or architecture contract?

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1` | `R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.1: select portable-type frontier` | `selection slice` |

## Changelog

- `2026-05-24`: Created active `R11` portable-type contract frontier audit
  tree and selected `.2` as the evidence-gathering frontier.
