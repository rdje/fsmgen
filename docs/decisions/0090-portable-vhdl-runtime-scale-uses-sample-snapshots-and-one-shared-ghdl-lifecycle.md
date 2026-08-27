# Decision 0090: Portable VHDL runtime scale uses sample snapshots and one shared GHDL lifecycle

- **Status:** Accepted
- **Date:** 2026-08-27
- **Owner:** `HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6`
- **Refines:** [0051](0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md), [0055](0055-vial-scale-proof-uses-orthogonal-workloads-and-stage-local-oracles.md), [0056](0056-vial-scale-measurements-use-pinned-evidence-and-bounded-failure.md)

## Context

The provider-free runtime constructor selects portable VHDL reference,
10,000-record gate, 100,000-record qualification, limit, and excess roles with
exact GHDL 6.0.0 commands and bounds. The checked GHDL qualifier is exact for
one gallery, but it owns version, analysis, elaboration, two fixture runs, two
four-state-probe runs, trace/result validation, and cleanup as one monolithic
call. Its `IPC::Cmd` capture checks output size only after collection and is
not a reusable process-isolated measurement lifecycle.

A fresh guarded rerun at clean selection revision `cf2899e564c4` matches the
checked qualification report and leaves no staging residue. An independent
repository-local run confirms the 42-record trace families:

| Family | Records |
| --- | ---: |
| header/footer | 2 |
| scenario start/end | 4 |
| coverage | 28 |
| events | 2 |
| expectations | 2 |
| faults | 2 |
| scoreboards | 2 |

The emitter performs 34 real inactive-edge barriers: six authored reset
cycles, sixteen active success cycles, and twelve active unsupported-size
cycles. Every barrier samples bound endpoints and probes before react/check,
but v1 emits no trace record for that sample phase. Increasing reset cycles
therefore leaves the trace count unchanged. Copying the portable-SystemVerilog
reset recipe, patching generated VHDL, padding output, or multiplying scenarios
would respectively measure no new trace work, create a second source truth, or
mix the runtime axis with the separately measured scenario/operation axes.

## Decision

### Versioned compact sample snapshots

Portable VHDL moves to `fsmgen.vial_vhdl_runtime_trace.v2` before scale
materialization. The trace header owns one ordered observation catalog for the
public output endpoints and declared probes, including exact semantic/sample
identities, normalized widths, and a content digest. Every real inactive-edge
barrier emits exactly one `samples` record after observation and before react.
That record carries the existing logical time plus one compact normalized
`0/1/X/Z` bit string in the header-declared order. The catalog makes widths and
boundaries recoverable without repeating long semantic IDs in every record;
the normalized string preserves VIAL four-state meaning while the separately
qualified probe continues to verify VHDL-symbol normalization.

A dedicated validator admits only canonical LF JSONL with exact schema,
closed keys and record vocabulary, one header/footer, contiguous sequence,
known plan/run/scenario identities, monotonic logical time, catalog digest and
ordering, exact normalized length, allowed symbols, scenario framing, and
expected family counts. It rejects missing, duplicate, reordered, malformed,
unknown-width, unknown-symbol, or post-footer data before result production.
The normalized result remains `fsmgen.verification_result_manifest.v1` and
retains the exact two-scenario outcome/parity projection.

Version 1 remains immutable historical evidence in Git and the checked pre-v2
qualification. It is not silently reinterpreted. The current portable profile
switches to v2 atomically with its emitter, validator, galleries, qualification
reports, support truth, Knowledge Map, and mdBook; there is no mixed v1/v2 run.

The unchanged reference adds one genuine snapshot for each of its 34 barriers:

```text
reference_v2 = 42 + 34 = 76 records
records(N) = 76 + (N - 3) = N + 73
```

The authored gate candidate uses success reset `N=9,927` and scenario timeout
16,384, producing exactly 10,000 records. The authored qualification candidate
uses `N=99,927` and timeout 131,072, producing exactly 100,000 records. Those
sources may change only the success reset and its enclosing timeout. Parser,
bridge, ExecutionIR, plan, emitted loop, catalog, trace, and result evidence
must independently bind the count end to end.

The 100,000-record shape remains a candidate, not a promise that it fits. The
existing 67,108,864-byte runtime capture and artifact limits remain
authoritative. Materialization must run an exact guarded candidate and retain
any earlier byte/time/tool failure. If the unchanged envelope dominates, work
stops for a superseding backend-specific count decision; it must not truncate,
compress away semantic evidence, widen a limit, or relabel a smaller run as
100,000.

### One staged GHDL lifecycle

One private caller-sealed GHDL lifecycle owns fixture execution for both exact
qualification and architecture-scale measurement:

```text
admitted -> prepared -> tool_verified -> analyzed -> elaborated -> ran
         -> trace_validated -> result_produced -> assembled -> cleaned
```

Each forward-only state is content-addressed canonical JSON and names its exact
predecessor, legal successor, provider/archive/binary hashes, source/emission
identity, command seals, bounded capture evidence, owned objects, and cleanup
authority. No caller can skip, replay, reorder, or manufacture a state.
Qualification uses an atomic adapter over this lifecycle for the checked
fixture; its separate four-state probe remains provider-qualification evidence
but uses the same bounded production process supervisor.

The production supervisor is extracted once from the already qualified
Verilator mechanism. It supports sealed lifecycle-owned and outer-worker-owned
containment policies, close-on-exec handoff evidence, nonblocking bounded
stdout/stderr capture, monotonic spawn/exec/first-output/exit times, complete
process-tree TERM/KILL cleanup, and exact reap/residue proof. Verilator public
and measurement behavior must remain byte-identical through the extraction.

GHDL retains the selected 10-second version, 120-second analysis, 60-second
elaboration, and 30-second run deadlines; capture ceilings remain 65,536 bytes,
8,388,608 bytes, 8,388,608 bytes, and 67,108,864 bytes respectively. The common
controller applies its independently sealed outer worker and RAM/host bounds.
No retry, timeout widening, alternate tool, system cache, or off-volume stage
is permitted.

### Ordered implementation

Task `.17.3.6` proceeds in five cleanly committed children: v2 trace truth;
authored runtime materialization; shared process supervisor and GHDL lifecycle;
common-controller measurement; then immutable publication and fresh-process
reload. Each child owns RED controls and impacted portable-VHDL/OSVVM evidence
refreshes before the next activates.

## Claim verification

- **Re-derive:** rebuild the checked source through Parser, bridge,
  ExecutionIR, portable-VHDL emission, exact GHDL analysis/elaboration/run, and
  independently census trace families, barrier count, normalized result, and
  cleanup.
- **Falsify:** compare the unchanged reset-count trace, raw 42-record family
  census, malformed trace/catalog/order/value controls, provider/tool/command
  mutations, timeout/capture/signal/descendant failures, and exact candidate
  execution against the selected equations and unchanged envelopes.
- **Durability:** retain this decision, task children, mdBook chapter,
  Knowledge Map card, checked sources/reports, focused watchers, claim records,
  and work-unit Git history as the only authority chain.

## Consequences

- VHDL traces gain useful compact sample-phase evidence rather than benchmark
  padding; the observation catalog is recorded once to keep large traces
  bounded.
- Portable VHDL and OSVVM share the provider-free trace semantics, but `.17.3.6`
  makes no OSVVM runtime, mixed-language, support, budget, or capacity claim.
- Exact GHDL qualification and measurement cannot drift into separate tool
  runners or process-containment policies.
- A 100,000-record rejection is a valid earlier-cap result. Only a new durable
  decision may revise that backend-specific candidate.
