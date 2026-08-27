# Portable VHDL Runtime Measurement

Portable-VHDL runtime measurement follows the provider-free runtime-stream
construction and the structural backend-emission matrix. Decision `0090`
selects the missing trace and lifecycle architecture; implementation proceeds
under `.17.3.6.1` through `.17.3.6.5`. This chapter describes the selected
contract, not a completed performance, capacity, or support claim.

<!-- CLAIM-VERIFICATION:BEGIN vial-portable-vhdl-runtime-selection-v1 -->
- Claim: The checked portable-VHDL v1 fixture produces 42 trace records while its scheduler traverses 34 real inactive-edge observation barriers; decision 0090 selects one v2 snapshot per barrier, `records(N)=N+73`, reset/timeout candidates 9,927/16,384 and 99,927/131,072 for 10,000/100,000 records, and unchanged GHDL deadline/capture pairs 10/65,536, 120/8,388,608, 60/8,388,608, and 30/67,108,864.
- Re-derive: Run the guarded exact GHDL qualifier, independently census raw trace families, and count reset plus active inactive-edge barriers from the authored fixture, normalized result, and emitter.
- Falsify: MISSING - Trace-v2 malformed-catalog, missing/duplicate/reordered snapshot, wrong-width/symbol, and candidate-equation RED controls are not implemented yet (owner: HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.17.3.6.1)
- Durability: Retain decision 0090, the exact task frontier, this chapter, its Knowledge Map card, the bounded claim record, checked qualifier evidence, doctrine watcher, and work-unit Git chain; close the owned falsification gap with trace v2.
<!-- CLAIM-VERIFICATION:END vial-portable-vhdl-runtime-selection-v1 -->

This “execution” is external execution of generated VHDL-2008 with the exact
qualified GHDL 6.0.0 LLVM-JIT profile. It is not IASIM execution. IASIM's
reference-semantics role remains separate.

## Why the existing reset recipe does not scale VHDL traces

The checked portable-VHDL qualification is real and deterministic: exact GHDL
analysis, elaboration, two fixture runs, a four-state probe, a closed trace,
two passing scenario outcomes, and exact cleanup all pass. Its v1 trace has 42
records:

| Record family | Count |
| --- | ---: |
| header and footer | 2 |
| scenario start and end | 4 |
| coverage | 28 |
| events | 2 |
| expectations | 2 |
| faults | 2 |
| scoreboards | 2 |

The generated scheduler nevertheless crosses 34 genuine inactive-edge sample
barriers: six reset cycles plus 28 transaction-active cycles. At each barrier
it observes the bound endpoints and probe before react/check. Trace v1 records
coverage and completion activity only while a transaction is active; it emits
nothing for reset samples. Merely changing reset `3` to a larger number would
therefore increase simulation work but not the requested trace records.

FSMGen will not patch generated VHDL, manufacture JSONL, or duplicate thousands
of scenarios to hit a benchmark. The first two create a second truth; the last
mixes the runtime-stream axis with scenario and operation scale.

## Selected trace v2

`fsmgen.vial_vhdl_runtime_trace.v2` adds one compact `samples` snapshot after
every real inactive-edge observation and before react. The header carries the
ordered output-endpoint/probe catalog once: sample and semantic identities,
widths, order, and a content digest. Each snapshot then needs only logical time
and one normalized `0/1/X/Z` bit string in that declared order. This keeps the
record self-validating without repeating long identifiers 100,000 times.

The dedicated validator checks canonical JSONL, exact keys and vocabulary,
header/footer uniqueness, contiguous sequence, plan/run/scenario identity,
logical-time order, observation-catalog identity, exact bit length and symbol
domain, scenario framing, and record-family counts. A missing, duplicated,
reordered, malformed, wrong-width, or unknown-symbol record fails before the
normalized result can be produced. The separately qualified four-state probe
continues to prove VHDL `std_logic` normalization.

Version 1 remains historical evidence. Version 2 switches emitter, validator,
checked galleries, qualification reports, support truth, and documentation
together; a run never mixes the schemas.

## Authored candidate equation

The unchanged reference adds 34 snapshots to its existing 42 records:

```text
reference_v2 = 76
records(N) = 76 + (N - 3) = N + 73
```

Only the success scenario's authored reset and matching timeout may differ:

| Level | Reset cycles `N` | Scenario timeout | Expected records |
| --- | ---: | ---: | ---: |
| reference | 3 | 256 | 76 |
| gate candidate | 9,927 | 16,384 | 10,000 |
| qualification candidate | 99,927 | 131,072 | 100,000 |

The source, SemanticIR reset operation, ExecutionIR/source map, emitted loop,
sample snapshots, validator projection, and normalized result must all agree.
An exact candidate remains subject to the existing 64-MiB runtime and artifact
envelopes. If 100,000 genuine records do not fit, that earlier cap wins and a
new decision selects any backend-specific revision. Output is never truncated
and limits are never widened to rescue a target.

## Shared GHDL lifecycle

One caller-sealed lifecycle serves exact qualification and scale measurement:

```text
admitted -> prepared -> tool_verified -> analyzed -> elaborated -> ran
         -> trace_validated -> result_produced -> assembled -> cleaned
```

Every transition reloads and validates its complete content-addressed
predecessor chain. Source, emission, provider, binary, command, output, trace,
result, and cleanup identities stay below one repository-derived same-volume
root. The four-state provider probe remains a distinct qualification oracle;
fixture execution has only this lifecycle.

The shared production process supervisor records containment, spawn, successful
`exec`, first output, exit, timeout/capture status, signal, and complete process-
tree cleanup. Lifecycle-owned public work and outer-worker-owned measurement
use sealed policies over the same mechanism. GHDL keeps these exact inner
bounds:

| Stage | Deadline | Capture ceiling |
| --- | ---: | ---: |
| version | 10 seconds | 65,536 bytes |
| analysis | 120 seconds | 8,388,608 bytes |
| elaboration | 60 seconds | 8,388,608 bytes |
| run | 30 seconds | 67,108,864 bytes |

The common measurement controller adds its independent host/RAM and worker
envelopes. Accepted gate and qualification sets require correctness validation
before three and five retained samples respectively. Limit/excess shapes remain
tool-free when an earlier structural or byte authority dominates.

## Nonclaims

Selection does not claim OSVVM runtime, another simulator, complete VHDL-2008,
PSL, mixed-language execution, IASIM execution, a promoted performance budget,
public support, architecture capacity, or a reached record limit. Those claims
remain with their separately owned qualification and promotion tasks.
