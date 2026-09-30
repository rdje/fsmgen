# Decision 0092: OSVVM runtime scale reuses authored VHDL sources and one provider-aware GHDL lifecycle

- **Status:** Accepted
- **Date:** 2026-08-30
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.7`
- **Refines:** [0051](../../0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md), [0056](../../0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md), [0090](../../0090-portable-vhdl-runtime-scale-uses-sample-snapshots-and-one-shared-ghdl-lifecycle.md)

## Context

Portable-VHDL measurement already owns reviewable reference, gate, and
qualification VIAL sources, their exact trace-v2 projections, one staged GHDL
lifecycle, common-controller measurement, and immutable publication. OSVVM is
an additive advanced-methodology profile over those same portable semantics;
duplicating the VIAL sources or patching generated VHDL would create a second
runtime axis and source truth.

The live provider/tool tuple was reverified from clean activation revision
`402ccada52f504accaece74235132c7f63e8fc42`: OSVVM 2026.05 remains at commit
`2f7c391051dfb11890fa4bdbda9918d1db492250` and tree
`bd4fdc594f2c26d564cf8907ff599578b9a39e22`; its recursive materializer
accepts 14 repositories, 13 gitlinks, 14 licence files, and zero notice files.
The guarded exact OSVVM/GHDL qualifier matches its checked report and removes
its operation stage.

The existing authorities are intentionally separate. Runtime-stream
construction knows the OSVVM profile and requested trace levels but runs no
provider or tool. Callback-scoped backend emission verifies the provider and
produces the adapter plus portable graph but runs no compiler. The checked
qualifier owns the exact provider build, generated settings, fixture, provider
probe, supplementary reports, trace, and result, but its monolithic
`IPC::Cmd` workflow is not a measured lifecycle. The shared GHDL lifecycle
accepts only one portable six-source analysis command and one top, so it
cannot honestly encode the provider build by concatenating commands or
pretending the probe is the fixture.

## Decision

### One authored semantic axis

The OSVVM reference, gate, and qualification profiles reuse the exact tracked
VIAL sources selected by decision `0090`. A new caller-sealed OSVVM runtime
materializer constructs its own `vhdl_osvvm_qualified` workload identity,
rebuilds Parser, bridge, ExecutionIR, backend inputs, and plan, then invokes
the existing callback-scoped OSVVM emitter. It must prove the seven-source
wrapper graph, byte-identical portable foundation, adapter mappings, translated
source maps, static checks, semantic guards, provider identity, trace
projection, rerun, failure, and cleanup. Limit and over-limit roles remain
preflight-dominated and access neither provider nor GHDL.

Shared private source/route helpers may be extracted only behind exact caller
seals. Existing portable materialization reports, identities, emitted bytes,
tests, and publications must remain unchanged.

### One exact provider/tool execution plan

The qualifier's source order and generated settings become one private closed
OSVVM/GHDL execution-plan authority. It retains the exact ordered provider
analyses, one generated-source analysis over the seven emitted sources plus
the checked provider probe, separate fixture and probe elaborations, separate
fixture and probe runs, qualified deadlines/capture limits, work libraries,
supplementary report inventory, and normalized command identities. Provider
sources stay read-only under the repository-derived dependency root; generated
settings, work libraries, reports, and all other outputs stay below the
operation-owned repository-volume stage.

The plan is reconstructed from the exact provider manifest, GHDL authority,
emission, and checked probe. Callers cannot provide an alternate source order,
library, settings body, report set, top, command, tool, provider, timeout, or
path.

### One provider-aware shared GHDL lifecycle

`FSM::VIAL::Backend::GHDLLifecycle` gains a distinct caller-sealed OSVVM role
and versioned multi-command plan while preserving its portable role and bytes.
The same production process supervisor, state persistence, containment,
capture, process-tree termination, object sealing, predecessor validation,
and cleanup code executes both roles. OSVVM analysis records every command and
capture in order; elaboration and run retain separate fixture/probe evidence.
Provider output and reports remain supplementary and cannot redefine portable
trace or normalized-result truth.

The checked OSVVM qualifier is refactored onto that lifecycle and must remain
byte-identical to its current report. Its deterministic double-run contract is
qualification evidence. Measurement uses one fixture and one provider-probe
execution per controller record; validation plus the required independent
records supply the repetition contract. Workspace-dependent paths are retained
only in raw evidence and have separate normalized identities.

Provider materialization verification is read-only prerequisite evidence,
not an HDL tool execution. It is retained separately from FSMGen emission and
from lifecycle captures even when the outer common-controller stage includes
canonical authority reconstruction. Provider identity is checked before
emission and again before terminal publication; lifecycle transitions also
revalidate every exact provider source they consume.

### Common-controller measurement and publication

The fixed decision-`0056` stage vocabulary remains unchanged:

| Measurement stage | OSVVM authority |
| --- | --- |
| `construct` through `bind_plan` | canonical authored VIAL route |
| `emit` | exact provider verification plus OSVVM adapter/portable graph |
| `compile_analyze` | exact provider and generated-source analysis plan |
| `elaborate` | fixture and provider-probe elaboration |
| `run` | fixture and provider-probe execution plus supplementary reports |
| `trace_validate` / `result_produce` | portable trace-v2 and normalized-result authorities |
| `publish` / `cleanup` | compact evidence assembly, post-provider check, and exact owned removal |

Reference remains correctness-only. Gate and qualification retain one
validation plus three and five measured records. Every accepted record keeps
the outer controller sample and the lifecycle's per-command captures, so
provider verification, FSMGen work, and external-tool work remain separately
inspectable. No timing is discarded merely because provider compilation is a
fixed prerequisite.

One OSVVM-specific matrix publisher derives all five roles from producer
ownership, isolates capture and reload, binds one clean revision/host/provider/
tool/guard identity, and withholds family/complete seals until every profile
validates. It rejects incomplete, reordered, mixed, stale, collided,
signalled, oversized, or ambiguous state and preserves every raw/excluded
sample, dominance classification, cleanup record, and nonclaim.

### Provider-report byte preflight refinement (2026-09-01)

The provider probe writes four supplementary reports outside stdout/stderr, so
process capture alone does not bound those files. The provider-aware lifecycle
now validates the exact closed same-volume inventory, stats every regular
report, and rejects when the report-only aggregate exceeds the existing
67,108,864-byte publication ceiling before reading or sealing any report
content. Exact equality remains admissible. A size change between preflight and
read is an object-integrity failure before persistence. The matrix publisher
retains its independent terminal complete-publication check; no new limit,
provider role, accepted report, or qualification identity is introduced.

### Capture-evidence resume refinement (2026-09-01)

The provider-aware role now applies the shared semantic capture admission to
every provider/generated analysis, fixture/probe elaboration, and
fixture/provider execution. Each resumed capture must match its selected
timeout and distinct 8-MiB or 64-MiB ceiling, successful supervisor outcome,
timing arithmetic, and sealed output-object bytes. Ordered transcript digests,
report-set digests, and deterministic-rerun evidence are rederived from the
sealed objects rather than trusted from state JSON. This closes evidence
forgery only; the supervisor, commands, accepted reports, qualification bytes,
deadlines, and limits do not change.

### Remaining state-evidence resume refinement (2026-09-01)

Provider-aware resume additionally reconstructs generated-settings and library
identity evidence from the selected plan. It recomputes the ordered provider
and generated analysis, fixture/probe elaboration, and fixture/provider run
command digests instead of trusting their state fields. The shared canonical
trace/result/assembly and workspace checks then bind terminal evidence to the
same-volume objects. This closes internally rehashed evidence claims without
changing provider invocation, supplementary reports, execution policy, or
accepted bytes.

## Ordered implementation

The active leaf proceeds through five clean children:

1. `.17.3.7.1` implements exact OSVVM runtime materialization;
2. `.17.3.7.2` extracts the closed provider/tool execution-plan authority;
3. `.17.3.7.3` adds the provider-aware lifecycle role and refactors the checked qualifier;
4. `.17.3.7.4` implements common-controller OSVVM measurement; and
5. `.17.3.7.5` publishes and independently reloads the immutable matrix.

Each child commits its own RED controls and impacted portable/OSVVM evidence
before the next activates.

## Claim verification

- **Re-derive:** rebuild each tracked source through the complete semantic and
  OSVVM emission route; independently verify provider commit/tree/manifest and
  licence/notice census; reconstruct the provider/tool plan; execute the exact
  qualifier and later the required guarded measurement records.
- **Falsify:** mutate source/profile/provider/tool/manifest/order/library/
  settings/adapter/map/command/state/predecessor/probe/report/trace/result,
  force timeout/signal/capture/collision/consumer failure, and require closed
  rejection with no partial publication or residue.
- **Durability:** retain this decision, five task children, checked provider and
  qualification reports, implementation/tests, mdBook, Knowledge Map, claim
  records, immutable measurement publications, and work-unit Git history.

## Consequences and nonclaims

- OSVVM runtime scale measures one exact advanced-methodology tuple without
  cloning the semantic workload or process supervisor.
- Provider verification, provider compilation/probe work, portable semantic
  execution, and supplementary reports remain distinguishable.
- Existing portable-VHDL qualification, measurement, publication, support,
  limits, and identities cannot drift as a side effect.
- The work adds no provider-generality, complete OSVVM/VHDL breadth, UVVM,
  PSL, verification-component transaction, another simulator, mixed-language,
  cross-backend parity, public API, promoted budget, support, or capacity claim.
