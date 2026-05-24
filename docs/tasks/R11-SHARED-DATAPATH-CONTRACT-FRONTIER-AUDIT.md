# R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT: Shared-Datapath Contract Frontier Audit

## Metadata

- Tree ID: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`
- Status: `done`
- Roadmap lane: `R11`
- Created: `2026-05-24`
- Last updated: `2026-05-24`
- Owner: repo-local workflow

## Goal

Audit the shipped shared-datapath extraction surface and select one bounded
next contract slice or an explicit deferral from evidence.

## Non-Goals

- Do not implement new shared-datapath behavior in the activation leaf.
- Do not widen route mux/storage, fan-in/fan-out, ready/backpressure, or
  payload-protocol semantics before the audit selects one exact surface.
- Do not change composition planning, structural IR, backend lowering, HDL
  emission, or generated artifacts during the activation leaf.

## Acceptance Criteria

- The activation leaf creates clear task-tree ownership before any
  shared-datapath behavior-bearing work.
- The audit leaf maps shipped shared-datapath evidence across candidate
  discovery, metadata, helper HDL, runtime HDL, assertions, visibility,
  registered peer-read cases, combinational cases, public fanout, and forward
  IR export surfaces.
- The audit leaf records one next implementation slice or an explicit deferral
  if the remaining work depends on a stronger route/storage/protocol,
  reusable-module, portable-type, or architecture contract.
- Focused validation passes.
- Live docs and roadmap status are updated where project state changed.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT`
  Status: `done`
  Goal: `Audit the R11 shared-datapath contract frontier and choose the next bounded slice.`
  Children: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1`,
    `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2`

- ID: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1`
  Status: `done`
  Goal: `Activate the shared-datapath contract frontier audit task tree.`
  Acceptance: `The active tree, roadmap status, task-tree table, live docs, and README index name this tree, and the next leaf is limited to an evidence-gathering audit before any shared-datapath behavior change.`
  Verification: `passed: feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1: select shared-datapath frontier`

- ID: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2`
  Status: `done`
  Goal: `Audit shipped shared-datapath behavior and choose the next bounded slice or deferral.`
  Acceptance: `The audit records current evidence, remaining gaps, and one implementation direction or deferral decision before any shared-datapath behavior change.`
  Verification: `passed: focused shared-datapath evidence, feature-backlog audit, mdBook build, and diff check`
  Commit: `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2: audit shared-datapath frontier`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2` | `done` | The next R11 left item is the shared-datapath contract family, and the shipped surface is broad enough to require an evidence-led bounded selection before code. |

Current frontier: `closed`.

## Decisions

- `2026-05-24`: Select a shared-datapath contract frontier audit after the
  parameter/generic audit closed. The roadmap names several remaining
  shared-datapath directions across ownership, lifted mux/register behavior,
  public re-export/default visibility, and combinational behavior, so the next
  safe step is to map shipped evidence and choose one bounded implementation
  slice or deferral.
- `2026-05-24`: Do not select a new shared-datapath implementation slice now.
  The shipped bounded contract already covers same-name generated-FSM output
  families, contributor and peer-read metadata, helper wires, SystemVerilog
  assertion hooks, registered lifted runtimes, combinational lifted carriers,
  public fanout, typed structural nets, CLI summaries, and forward-IR export
  surfaces. Broader route mux/storage, arbitrary fan-in/fan-out protocols,
  ready/backpressure, payload protocols, dynamic scheduling, external-RTL or
  standalone-DT contributors, mixed storage-class lifting, and wider shared
  data movement should wait for a precise route/storage/protocol,
  reusable-module, portable-type, or architecture contract.

## Audit Result

Supported shipped evidence:

- Candidate discovery is bounded to compatible same-name output families
  across multiple realized `?fsmc` children with matching width, interface
  type, and declared type identity when present.
- Candidate metadata reports contributor identity, bound connection
  expressions, contributor forward IR, output-drive-family summaries,
  peer-read endpoints, top-output bindings, storage class, lifted-visibility
  planning, aggregate enable families, conflict signals, and assertion
  metadata.
- Generated composition tops emit shared-datapath helper wiring from hidden
  child source-enable exports through aggregate value-enable, same-value
  conflict, whole-target enable, and multi-value conflict signals.
- SystemVerilog tops emit verification-only same-value and multi-value guard
  assertions; Verilog tops keep metadata but do not emit SystemVerilog
  assertion syntax.
- Registered families with a consistent reset and usable composition
  clock/reset lift into `*_shared_next` / `*_shared_q` runtimes for bounded
  peer-read public-preserving, peer-read internal-only, mixed public/internal,
  and public-fanout cases.
- Combinational families lift into `*_shared_comb` runtimes for bounded
  peer-read public-preserving, peer-read internal-only, and public-fanout
  cases without inventing state.
- Typed shared families preserve declared type contracts on candidate metadata,
  private raw contributor nets, and lifted runtime carriers.
- The mdBook now documents the full shipped contract and its backlog boundary.

No implementation slice is selected from this tree. The next R11 activity
should move to another roadmap family while future shared-datapath work should
be selected only when one broader route/storage/protocol, reusable-module,
portable-type, or architecture prerequisite is ready.

## Open Questions

- None. `.2` owns the evidence-gathering audit and deferral decision.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-24` | `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1` | `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: feature-backlog audit Files=1, Tests=15` |
| `2026-05-24` | `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2` | `prove -Iperl t/139-composition-shared-datapath-candidate-metadata.t t/140-composition-shared-datapath-drive-intent-metadata.t t/141-composition-shared-datapath-aggregate-enable-metadata.t t/142-composition-shared-datapath-assertion-metadata.t t/143-composition-shared-datapath-visibility-metadata.t t/144-composition-shared-datapath-combinational-peer-read-policy.t t/145-composition-shared-datapath-runtime-hdl.t t/146-composition-shared-datapath-lifted-register-runtime.t t/147-composition-shared-datapath-internal-lifted-register-runtime.t t/148-composition-shared-datapath-mixed-reexport-runtime.t t/149-composition-shared-datapath-combinational-runtime.t t/150-composition-shared-datapath-combinational-internal-runtime.t t/151-composition-shared-datapath-assertion-runtime-hdl.t t/152-composition-shared-datapath-public-fanout-register-runtime.t t/153-composition-shared-datapath-combinational-public-fanout-runtime.t t/159-composition-shared-datapath-forward-ir-exports.t t/178-composition-shared-datapath-support.t t/183-composition-shared-datapath-candidate-builder.t`; `prove -Iperl t/1256-feature-backlog-status-audit.t`; `mdbook build docs/book`; `git diff --check` | `passed: focused shared-datapath evidence Files=18, Tests=36; feature-backlog audit Files=1, Tests=15` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1` | `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.1: select shared-datapath frontier` | `selection slice` |
| `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2` | `R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.2: audit shared-datapath frontier` | `audit/deferral slice` |

## Changelog

- `2026-05-24`: Created active `R11` shared-datapath contract frontier audit
  tree and selected `.2` as the evidence-gathering frontier.
- `2026-05-24`: Completed `.2`, recorded that no new shared-datapath
  implementation slice is selected now, documented the shipped bounded
  contract in the mdBook, and closed the tree.
