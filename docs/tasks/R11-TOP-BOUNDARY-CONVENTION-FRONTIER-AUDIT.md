# R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT: Top-Boundary Convention Frontier Audit

## Metadata

- Tree ID: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the shipped top-boundary convention and declared connect-by-name
surface, then select one bounded next contract slice or an explicit deferral
from evidence.

## Non-Goals

- Do not implement new composition inference, connect-by-name, explicit-link,
  public-port, or child-to-child wiring behavior in the activation leaf.
- Do not widen hidden child-to-child inference, interface bundle syntax,
  protocol grouping, or generic meta-programming before the audit identifies
  one exact contract.
- Do not change parser, planner, report, generated artifact, HDL, CLI, public
  API, source, test, or generated behavior during the activation leaf.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any
  top-boundary convention behavior-bearing work.
- The audit leaf maps shipped evidence across omitted/empty `?ports`
  inference, same-name top-input fanout, same-name top-output adoption,
  internal-carrier inference/re-export, declared `=name` connect-by-name,
  explicit local overrides, provenance/block reporting, structural IR
  surfaces, generated/RTL child mixes, and explicit deferrals.
- The audit leaf records one next implementation slice or an explicit deferral
  if the remaining work depends on a stronger top-boundary convention,
  interface bundle, protocol, package/import, reusable-module, portable-type,
  or architecture contract.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT`
  Status: `done`
  Goal: `Audit the R11 top-boundary convention/connect-by-name frontier and choose the next bounded slice.`
  Children: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1`,
    `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2`

- ID: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the top-boundary convention frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any convention or connect-by-name behavior change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1: select top-boundary frontier`

- ID: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2`
  Status: `done`
  Goal: `Audit shipped top-boundary convention and connect-by-name behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any top-boundary convention behavior change.`
  Verification: `passed: focused top-boundary convention evidence, feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2: audit top-boundary frontier`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2` | `done` | The next R11 left item is the declared top-port/connect-by-name convention family, and the remaining directions required an evidence-led bounded selection before code. |

Current frontier: `closed`.

## Decisions

- `2026-05-24`: Select a top-boundary convention frontier audit after the
  portable-type audit closed. The roadmap names remaining work around
  asymmetric declared top-port connect-by-name, convention-over-configuration
  widening, explicit local override ergonomics, internal re-export policy, and
  keeping convention top-boundary-oriented rather than hidden child-to-child
  inference, so the next safe step is to map shipped evidence and choose one
  bounded implementation slice or deferral.
- `2026-05-24`: Defer new top-boundary convention implementation for now. The
  shipped bounded contract is already regression-backed across single-child
  passthrough, explicit-link omitted/empty `?ports` inference, same-name
  top-input fanout, same-name top-output adoption, internal-carrier inference
  and re-export, direction-asymmetric declared `=name` / `:same-name`
  connect-by-name, generated/RTL/mixed child lanes, declared-type
  compatibility checks, provenance/override/block reporting, `Intent HIR`,
  and `Structural RTL IR`. Broader interface bundles, protocol groups,
  hidden child-to-child inference, automatic priority/merge/arbitration,
  wider public re-export policy, and non-top-boundary convention semantics
  should wait for one exact composition contract.

## Audit Result

Supported shipped evidence:

- `C1` single-child passthrough supports omitted or empty `?ports` for one
  generated or external RTL child, preserving the child interface as the top
  interface.
- Explicit-link `C2` / `C3` lanes support omitted/empty `?ports` when
  `?wiring` endpoints provide one consistent public boundary, including
  renamed top-boundary endpoints, top expressions, concat/repeat source
  expressions, and aggregate-path width evidence.
- Same-name top-input inference fans out one inferred or plain explicit top
  input to compatible child inputs when directions, widths, type metadata, and
  preserved declared type contracts agree.
- Same-name top-output inference adopts one unique top-facing child output,
  and rejects ambiguous same-name output families.
- Same-name internal carrier inference builds an internal net when one unique
  child output and one or more child inputs share a compatible name family and
  no explicit link already owns that family. Internal carriers stay internal
  by default.
- A compatible explicit same-name top output may re-export one inferred
  internal carrier without forcing the author to restate the child-to-child
  movement.
- Declared compact `=name` and verbose `:same-name` / `(same-name)` /
  `:connect-by-name` / `(connect-by-name)` ports use the C4
  connect-by-name contract across generated children, external RTL children,
  and mixed generated/RTL compositions. Top outputs require exactly one
  compatible child output; top inputs may fan out to one or more compatible
  child inputs.
- Explicit `?wiring` overrides convention locally. Composition reports,
  `module_info`, statistics, and CLI summaries preserve declared, inferred,
  override, and blocked convention events with examples.
- Forward metadata preserves the bounded top-boundary convention surface
  through composition plans, `Intent HIR`, `Structural RTL IR`, resolved links,
  declared links, port origins, instance bindings, and block/override event
  contexts.

Deferred surfaces:

- interface bundles and protocol groups;
- broader hidden child-to-child auto-wiring beyond exact declared or inferred
  top-boundary convention;
- automatic priority, merge, or arbitration semantics for same-name conflicts;
- wider default public re-export policy for internal carriers;
- non-top-boundary convention semantics that would make child-to-child routing
  implicit everywhere;
- richer local override syntax that is not already covered by `?ports` and
  `?wiring`.

No implementation slice is selected from this tree. The next R11 activity
should move to another roadmap family, while future top-boundary convention
work should be task-tree-selected only when one prerequisite is ready.

## Open Questions

- None. `.2` owns the evidence-gathering audit and next-frontier decision.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2` | `prove -Iperl t/24-composition-connect-by-name.t t/86-composition-single-child-connect-by-name.t t/87-composition-mixed-connect-by-name.t t/92-composition-multi-rtl-connect-by-name.t t/94-composition-multi-generated-plus-rtl-connect-by-name.t t/95-composition-connect-by-name-input-fanout.t t/96-composition-implicit-single-child-ports.t t/97-composition-implicit-multi-child-inputs.t t/98-composition-implicit-multi-child-outputs.t t/99-composition-implicit-internal-carriers.t t/100-composition-internal-carrier-top-reexport.t t/101-composition-explicit-link-implicit-ports.t t/102-composition-explicit-port-convention.t t/103-composition-provenance-metadata.t t/104-composition-provenance-reporting.t t/105-composition-override-reporting.t t/106-composition-blocked-reporting.t t/160-composition-top-forward-ir-surface.t t/162-composition-top-structural-rtl-ir-surface.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused top-boundary convention evidence Files=19, Tests=65; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1` | `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.1: select top-boundary frontier` | `selection slice` |
| `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2` | `R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.2: audit top-boundary frontier` | `audit/deferral slice` |

## Changelog

- `2026-05-24`: Created active `R11` top-boundary convention frontier audit
  tree and selected `.2` as the evidence-gathering frontier.
- `2026-05-24`: Completed `.2`, recorded that no new top-boundary convention
  implementation slice is selected now, and closed the tree.
