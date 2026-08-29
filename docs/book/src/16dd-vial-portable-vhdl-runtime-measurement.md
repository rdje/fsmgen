# Portable VHDL Runtime Measurement

Portable-VHDL runtime measurement follows the provider-free runtime-stream
construction and the structural backend-emission matrix. Decision `0090`
selects the missing trace and lifecycle architecture. Trace-v2 truth is
implemented under `.17.3.6.1`, and `.17.3.6.2` now materializes both authored
scale sources through the canonical structural route. `.17.3.6.3` now provides
the shared GHDL lifecycle and process supervisor. `.17.3.6.4` now measures the
applicable profiles through the common controller; immutable-set publication
is active under `.17.3.6.5`. This chapter does not make a performance,
capacity, or support claim.

<!-- CLAIM-VERIFICATION:BEGIN vial-portable-vhdl-runtime-selection-v1 -->
- Claim: The checked portable-VHDL v2 fixture produces 77 trace records across 35 real inactive-edge observation barriers; its authenticated four-entry/66-bit catalog and one snapshot per barrier establish `records(N)=N+74`, reset/timeout candidates 9,926/16,384 and 99,926/131,072 for 10,000/100,000 records, and unchanged GHDL deadline/capture pairs 10/65,536, 120/8,388,608, 60/8,388,608, and 30/67,108,864.
- Re-derive: Run the guarded exact GHDL qualifier; independently census the 42 pre-snapshot records, 19/16 scenario sample partition, ordered observation catalog, normalized result, and emitted sample-call placement.
- Falsify: Hostile controls mutate canonical encoding, schema, framing, sequence, catalog identity/order/digest/width, sample identity/phase/width/symbols, logical time, counts, footer closure, and checked qualification evidence; every mutation fails closed before result production.
- Durability: Retain decision 0090, the exact task frontier, this chapter, its Knowledge Map card, the bounded claim record, checked portable/OSVVM reports and galleries, doctrine watcher, and work-unit Git chain.
<!-- CLAIM-VERIFICATION:END vial-portable-vhdl-runtime-selection-v1 -->

<!-- CLAIM-VERIFICATION:BEGIN vial-portable-vhdl-runtime-structural-materialization-v1 -->
- Claim: The tracked 10,000/100,000-record portable-VHDL candidates preserve 21 operations and 39 ExecutionIR maps, and emit exact 17-artifact/six-source/59-map graphs with 21 passing structural checks while retaining the unchanged 67,108,864-byte runtime envelope.
- Re-derive: Run prove -Iperl t/1672-vial-architecture-scale-portable-vhdl-runtime-materialization.t; independently diff each candidate against the reference and rebuild Parser, bridge, ExecutionIR, plan, and portable-VHDL emission twice.
- Falsify: Mutate a source byte, report claim/count, non-selected scenario value, await window, route, artifact inventory, map/check result, or cap; exact source identities, structural comparison, closed report regeneration, and focused controls reject it.
- Durability: Retain both tracked candidate sources, the sealed materializer and watcher, decision 0090, task .17.3.6.2, this chapter, Knowledge Map card, bounded claim record, and work-unit Git chain.
<!-- CLAIM-VERIFICATION:END vial-portable-vhdl-runtime-structural-materialization-v1 -->

<!-- CLAIM-VERIFICATION:BEGIN vial-portable-vhdl-runtime-measurement-v1 -->
- Claim: The guarded exact GHDL adapter accepts one 77-record reference validation, one validation plus three retained 10,000-record gate measurements, and one validation plus five retained 100,000-record qualification measurements; all 11 controller/lifecycle roots clean without residue, while limit and over-limit remain tool-free.
- Re-derive: Run `FSMGEN_VIAL_PORTABLE_VHDL_RUNTIME_MEASUREMENT_EXACT=1 scripts/run_with_ram_guard.sh -- prove -Iperl t/1674-vial-architecture-scale-portable-vhdl-runtime-measurement.t`; independently reload every report and reconstruct its materializer, controller, provider, source, command, transcript, trace, result, predecessor, and cleanup identities.
- Falsify: Direct callers, absent guards, foreign levels/keys, changed applicability, malformed lifecycle authority, rejected captures, source/command/transcript/trace/result identity drift, wrong repetition counts, and retained residue fail closed; the shared-lifecycle watcher separately proves collision, replay, mutation, timeout/failure evidence, and cleanup controls.
- Durability: Retain the private adapter, materializer/provider seams, common controller and lifecycle, t/1673 and t/1674, decision 0090, task .17.3.6.4, this chapter, Knowledge Map card, bounded claim inventory, and work-unit Git chain.
<!-- CLAIM-VERIFICATION:END vial-portable-vhdl-runtime-measurement-v1 -->

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

The generated scheduler actually crosses 35 genuine inactive-edge sample
barriers: six reset cycles, 28 transaction-active cycles, and one final
unsupported-size response-settlement cycle after active coverage stops. At each barrier
it observes the bound endpoints and probe before react/check. Trace v1 records
coverage and completion activity only while a transaction is active; it emits
nothing for reset samples. Merely changing reset `3` to a larger number would
therefore increase simulation work but not the requested trace records.

FSMGen will not patch generated VHDL, manufacture JSONL, or duplicate thousands
of scenarios to hit a benchmark. The first two create a second truth; the last
mixes the runtime-stream axis with scenario and operation scale.

## Selected trace v2

Implemented `fsmgen.vial_vhdl_runtime_trace.v2` adds one compact `samples` snapshot after
every real inactive-edge observation and before react. The header carries the
ordered output-endpoint/probe catalog once: sample and semantic identities,
widths, order, and a content digest. Each snapshot then needs only logical time
and one normalized `0/1/X/Z` bit string in that declared order. This keeps the
record self-validating without repeating long identifiers 100,000 times.

The dedicated validator checks canonical JSONL, exact keys and vocabulary,
header/footer uniqueness, contiguous sequence, caller-sealed plan/run identity,
non-regressing cycles, closed phase ranks, observation-catalog identity, exact bit length and symbol
domain, scenario framing, and record-family counts. A missing, duplicated,
reordered, malformed, wrong-width, or unknown-symbol record fails before the
normalized result can be produced. The separately qualified four-state probe
continues to prove VHDL `std_logic` normalization.

Version 1 remains historical evidence. Version 2 switches emitter, validator,
checked galleries, qualification reports, support truth, and documentation
together; a run never mixes the schemas.

The checked header catalog is exact:

| Observation | Width |
| --- | ---: |
| output endpoint `HRDATA` | 32 |
| output endpoint `HREADYOUT` | 1 |
| output endpoint `HRESP` | 1 |
| probe `reg_data_q` | 32 |

Its total is 66 normalized bits. The catalog digest authenticates schema,
ordered identities, roles, semantic paths, and widths; changing any entry or
reordering the four entries invalidates the trace before result projection.

## Authored candidate materialization

The unchanged reference adds 35 snapshots to its existing 42 records. The
provisional 34-barrier selection omitted the final unsupported-size response-
settlement sample; the direct v2 GHDL run corrects that count:

```text
reference_v2 = 77
records(N) = 77 + (N - 3) = N + 74
```

Only the success scenario's authored reset and matching timeout may differ:

| Level | Reset cycles `N` | Scenario timeout | Expected records |
| --- | ---: | ---: | ---: |
| reference | 3 | 256 | 77 |
| gate candidate | 9,926 | 16,384 | 10,000 |
| qualification candidate | 99,926 | 131,072 | 100,000 |

The gate source is
`vial/qualification/vhdl_portable_ghdl_runtime_gate.vial`; the qualification
source is
`vial/qualification/vhdl_portable_ghdl_runtime_qualification.vial`. They are
4,991 and 4,993 bytes. Exact projection from the 4,986-byte reference proves
that only the success timeout and reset literals differ; both 256-cycle await
windows and the complete unsupported-size scenario remain byte-identical.

The private materializer reconstructs each source through Parser, bridge,
ExecutionIR, backend inputs, target-neutral plan, and portable-VHDL emission
twice. Both candidates retain 21 operations and 39 ExecutionIR source maps;
each emission has 17 artifacts, six VHDL sources, 59 emitted source maps, and
21 passing structural checks:

| Level | Complete artifact bytes | VHDL source bytes | Fixture bytes |
| --- | ---: | ---: | ---: |
| reference | 238,618 | 118,062 | 46,262 |
| gate candidate | 238,901 | 118,075 | 46,273 |
| qualification candidate | 239,318 | 118,087 | 46,284 |

The materialization report alone closes source-to-emission structure, not
external execution. The measurement adapter now independently makes the
emitted loop, sample snapshots, validator projection, and normalized result
agree under GHDL. It authenticates trace content instead of promoting an
unowned trace-byte budget.

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
fixture execution has only this lifecycle. The checked qualifier now consumes
that lifecycle, runs its distinct probe through the same supervisor, and still
reproduces the checked qualification report byte for byte.

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

## Common-controller measurement

The private portable-VHDL adapter reconstructs the canonical materializer,
blessed route, emitted six-source compiler order, and qualified GHDL provider
inside every isolated worker. The common stages map onto the lifecycle without
adding a second executor: emit admits; compile/analyze prepares, verifies, and
analyzes; elaborate, run, trace validation, and result production each advance
one state; publish assembles and cleans.

The exact guarded proof retains 11 accepted records:

| Profile | Correctness validations | Measured repetitions | Trace records per run |
| --- | ---: | ---: | ---: |
| reference | 1 | 0 | 77 |
| gate candidate | 1 | 3 | 10,000 |
| qualification candidate | 1 | 5 | 100,000 |

Measured records retain the common controller's raw 250-ms observations for
all eleven stages. Published correctness evidence binds the six-source graph,
four exact GHDL commands and transcript identities, complete predecessor chain,
validated trace and normalized result, exclusions, and both lifecycle and
outer-controller cleanup. The exact campaign excludes no sample and leaves no
owned staging residue. Limit and over-limit reports execute neither controller
nor GHDL because their earlier materialization authority already dominates.

## Nonclaims

Selection does not claim OSVVM runtime, another simulator, complete VHDL-2008,
PSL, mixed-language execution, IASIM execution, a promoted performance budget,
public support, architecture capacity, or a reached record limit. Those claims
remain with their separately owned qualification and promotion tasks.
