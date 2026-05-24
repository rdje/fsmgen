# R11-PARAMETER-GENERIC-FRONTIER-AUDIT: Parameter/Generic Frontier Audit

## Metadata

- Tree ID: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the current semantic parameter/generic contract and select one bounded
next slice or deferral from evidence.

## Non-Goals

- Do not implement VHDL generic-map lowering in the activation leaf.
- Do not widen scalar or aggregate parameter/generic expression domains before
  the audit identifies one bounded, testable surface.
- Do not change direct-root `+params`, `.rtlif`, generated-child, package, IR,
  or backend behavior during the activation leaf.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any
  parameter/generic behavior-bearing work.
- The audit leaf maps shipped parameter/generic evidence across direct roots,
  `.rtlif`, external `?rtl`, generated `?fsmc` / `?dtc`, package defaults,
  scalar expressions, aggregate values, leafwise aggregate operators,
  structural IR, and SystemVerilog instance emission.
- The audit leaf records one next implementation slice or an explicit deferral
  if the remaining work depends on VHDL backend support, the portable type
  lane, or a stronger aggregate-expression contract.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT`
  Status: `done`
  Goal: `Audit the R11 semantic parameter/generic frontier and choose the next bounded slice.`
  Children: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1`,
    `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2`

- ID: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the parameter/generic frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any parameter/generic behavior change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1: select parameter frontier`

- ID: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2`
  Status: `done`
  Goal: `Audit shipped semantic parameter/generic behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any parameter/generic behavior change.`
  Verification: `passed: focused parameter/generic and VHDL-deferral evidence, feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2: audit parameter frontier`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2` | `done` | The next R11 left item is semantic parameter/generic widening, and the remaining directions were broad enough to require an evidence-led bounded selection before code. |

Current frontier: `closed`.

## Decisions

- `2026-05-24`: Select a parameter/generic frontier audit after the `.rtlif`
  direction decision closed. The roadmap names several remaining
  parameter/generic directions, so the next safe step is to map shipped
  evidence and choose one bounded implementation slice or deferral.
- `2026-05-24`: Defer new parameter/generic implementation for now. The
  shipped contract is already regression-backed across direct `+params`,
  `.rtlif` defaults, external `?rtl` overrides, generated `?fsmc` / `?dtc`
  overrides, package-qualified defaults, scalar expressions, aggregate values,
  matching-shape leafwise aggregate operators, unary aggregate complement,
  Intent HIR, structural RTL IR, and SystemVerilog `#(...)` emission. VHDL
  generic-map lowering remains blocked behind the active VHDL
  backend/composition target boundary, and richer non-leafwise or mixed
  aggregate expression domains should stay deferred until the portable type or
  aggregate-operator contract names one exact type/shape/result rule.

## Audit Result

Supported shipped evidence:

- Direct roots: `(+params ...)` preserves semantic parameter declarations,
  resolves constants/enums/defines/other parameters through an acyclic graph,
  preserves parameter references in direct HDL, and emits SystemVerilog module
  parameters.
- External RTL: `.rtlif` `(params ...)` declarations support scalar and
  aggregate defaults, package-qualified defaults, scalar expressions,
  matching-shape leafwise aggregate operators, and unary aggregate complement.
- Composition instances: external `?rtl` and generated `?fsmc` / `?dtc`
  parameter override blocks resolve composition-top/package symbols, validate
  names and aggregate shape, preserve provenance, and flow through the
  composition plan, Intent HIR, structural RTL IR, and SystemVerilog instance
  `#(...)` lowering.
- Deferred surfaces are already explicit: VHDL generic-map lowering waits for
  active VHDL backend/composition target support; mixed scalar/aggregate
  operators, mismatched shapes, non-leafwise typed aggregate operators,
  backend-rendered aggregate operators, and runtime aggregate operator paths
  wait for a stronger type/shape/result contract.

No implementation slice is selected from this tree. The next R11 activity
should move to another roadmap family, while future parameter/generic work
should be task-tree-selected only when one prerequisite is ready.

## Open Questions

- None. `.2` owns the evidence-gathering audit and next-frontier decision.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2` | `prove -Iperl t/30-language-contract-symbol-definitions.t t/51-language-contract-symbol-definition-boundary.t t/88-rtlif-typed-port-contract.t t/91-composition-multi-rtl-children.t t/272-composition-package-imports.t t/274-package-aggregate-values.t t/275-composition-top-aggregate-values.t t/292-composition-generated-child-parameter-overrides.t t/114-composition-target-support-diagnostics.t t/386-hdl-generator-facade-target-language-boundary-audit.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused parameter/generic and VHDL-deferral evidence Files=10, Tests=203; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1` | `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.1: select parameter frontier` | `selection slice` |
| `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2` | `R11-PARAMETER-GENERIC-FRONTIER-AUDIT.2: audit parameter frontier` | `audit/deferral slice` |

## Changelog

- `2026-05-24`: Created active `R11` parameter/generic frontier audit tree
  and selected `.2` as the evidence-gathering frontier.
- `2026-05-24`: Completed `.2`, recorded that no new parameter/generic
  implementation slice is selected now, and closed the tree.
