# Portable VHDL Runtime Measurement

Portable-VHDL runtime measurement follows the provider-free runtime-stream
construction and the structural backend-emission matrix. Decision `0090`
selects the missing trace and lifecycle architecture. Trace-v2 truth is
implemented under `.17.3.6.1`, and `.17.3.6.2` now materializes both authored
scale sources through the canonical structural route. `.17.3.6.3` now provides
the shared GHDL lifecycle and process supervisor. `.17.3.6.4` now measures the
applicable profiles through the common controller. `.17.3.6.5` now seals and
independently reloads the complete immutable set, closing `.17.3.6`. This
chapter does not make a performance, capacity, or support claim.

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

That distinct probe also preserves deadline authority: a supervisor
`timed_out` result reports `VIAL_VHDL_QUALIFICATION_TIMEOUT` at
`/resource_controls` before capture overflow or generic execution handling.
The probe is never retried, and its selected timeout and capture values do not
change.

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

Failure cleanup has its own diagnostic authority. If a GHDL phase fails and
the lifecycle then cannot remove its proven-owned staging root, the result
reports `VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR` at `/cleanup` and names that exact
staging identity as residue. It does not hide the integrity failure behind the
earlier timeout or execution diagnostic. When cleanup succeeds, the original
phase diagnostic remains authoritative and the residue list is empty.

Admission uses the same rule even before an owner marker exists. The lifecycle
knows it created an absent repository-local root, so a later owner/state write
failure carries the direct removal outcome into the failure result. Successful
removal reports `removed=true`. Removal error, path replacement, or retained
content reports the cleanup diagnostic and the exact staging identity as
residue; it never claims proof from an owner file that may not have been
written.

The lifecycle regressions still cross the real shared process supervisor, but
their fake GHDL providers do not compile transient host-native executables.
On hosts with `/bin/sh`, both tests use one stable, tracked repository-local
POSIX provider; a configured-Perl script remains the fallback where that shell
is absent. The stable provider avoids compiler, code-sign, ambient `PATH`, and
intermittent Apple-Perl pre-main work while retaining version output, nonzero
analysis, provider reports, process-group containment, capture, deadline, and
cleanup coverage. If a supervised phase times out, the tests also print its
bounded spawn/`exec`/first-output/finish evidence. They never retry the failed
phase. The production GHDL provider and its ten-second version deadline are
unchanged.

```sh
prove -Iperl t/1725-vial-ghdl-cleanup-diagnostic-authority.t \
  t/1726-vial-ghdl-admission-cleanup-evidence.t \
  t/1727-vial-ghdl-probe-timeout-diagnostic-authority.t \
  t/1673-vial-ghdl-shared-lifecycle.t \
  t/1678-vial-ghdl-provider-aware-lifecycle.t
```

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

## Immutable publication and independent reload

`FSM::VIAL::ArchitectureScalePortableVHDLRuntimeMeasurementMatrix` derives its
closed order directly from the measurement producer. The reference, gate, and
qualification profiles execute in separate guard-visible child lifecycles;
limit and over-limit follow afterward and may only inherit the common capture
identity established by executable evidence. A child publishes its complete
canonical report before returning a separately bounded compact entry to the
coordinator, so the parent never transports or retains the raw report through
its IPC envelope.

Publication is repository-relative and same-volume. Each content-addressed
profile directory contains one immutable report. Only after every profile
reloads with the same clean Git revision, host, qualified GHDL tool, and active
guard identity may the family manifest and complete manifest appear. Byte-equal
crash staging is recoverable; a conflicting target, malformed or ambiguous
stage, changed digest/size/order/sample/identity, signal, nonzero exit, or
oversized child result fails closed without an aggregate seal. The conservative
file ceiling reuses the already-authoritative GHDL runtime-capture byte limit;
it does not promote a budget or claim that the qualification candidate fits.

Inspect the producer-owned inventory without executing GHDL:

```console
scripts/run_vial_portable_vhdl_runtime_measurement_matrix.pl --inventory
```

Capture only from a clean revision under the real repository guard, then use a
separate guarded process to reload the immutable result:

```console
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_portable_vhdl_runtime_measurement_matrix.pl
scripts/run_with_ram_guard.sh -- \
  scripts/run_vial_portable_vhdl_runtime_measurement_matrix.pl --validate
```

The default `t/1675-vial-architecture-scale-portable-vhdl-runtime-measurement-matrix.t`
controls producer order, mode routing, tool-free dominance, process isolation,
bounded canonical IPC, immutable collision/recovery, aggregate partition drift,
and staging cleanup without running the exact campaign. Its guarded
`FSMGEN_VIAL_PORTABLE_VHDL_RUNTIME_MATRIX_EXACT=1` mode owns capture, aggregate
sealing, and fresh-process identity equality. The similarly named portable-
Verilator trigger cannot activate it.

The provider-qualified OSVVM route deliberately uses a separate matrix class,
schemas, profile IDs, staging namespace, runner, and aggregate identities. It
reuses this publication pattern but binds the pinned provider inside its common
tool identity and retains the larger provider/source/report evidence in each
raw profile publication. See [OSVVM Runtime Execution and Measurement](16de-vial-osvvm-runtime-execution-plan.md)
for its now-sealed clean guarded capture, independent reload, exact seven-file
census, and provider-bound complete identity.

Every executable profile must carry the producer-authoritative seventeen-
artifact portable-VHDL emission graph. The first clean exact publication
attempt exposed and failed closed on a copied six-artifact portable-Verilator
expectation in the new aggregate validator. The matrix now applies one exact
seventeen-artifact authority to both the raw terminal lifecycle and its compact
manifest entry; a focused synthetic manifest would fail if that backend-
specific cardinality drift returned. No malformed aggregate was published.

<!-- CLAIM-VERIFICATION:BEGIN vial-portable-vhdl-runtime-matrix-seal-d85256aa8-v1 -->
- Claim: Clean revision `d85256aa806a8dbdcf89c0e14b6bad9521521168` seals the five-profile portable-VHDL runtime matrix as seven immutable files totaling 1,354,895 bytes; the largest profile is 787,082 bytes, the accepted aggregate retains three validation-route and two measured-route profiles, eight raw and zero excluded records, two preflight-dominated profiles, eleven cleanup and zero residue records, and a separate guarded reload returns complete identity `portable-vhdl-runtime-matrix/cf0844de188b3a07ec7ed8026dcdfd95551cf7202b3df528659456da6e00e329`.
- Re-derive: Run guarded `--validate`, census only the five portable-VHDL runtime profile publications plus family and complete manifests independently with `find` and `wc`, hash all seven files with `shasum -a 256`, and project common identity/dominance with `jq`.
- Falsify: Run exact guarded t1675 from an empty namespace and require rejection for any producer order, route, artifact cardinality, sample, exclusion, dominance, common identity, checksum, collision, process result, cleanup, or staging disagreement.
- Durability: Preserve the content-addressed profile publications plus family/complete manifests on the repository volume, and retain the exact task, book, Knowledge Map, publisher, runner, watcher, claim record, and Git closure chain.
<!-- CLAIM-VERIFICATION:END vial-portable-vhdl-runtime-matrix-seal-d85256aa8-v1 -->

The exact file census is:

| Publication | Bytes | SHA-256 |
| --- | ---: | --- |
| reference | 96,509 | `595fa131eff99fa757a3525b527a9501532f6552267016c72235ddc7a6e3b82f` |
| gate candidate | 444,601 | `69645cdaf83b266af90067c0050d9a5ef1defc6660b257f59ae2998b63946e87` |
| qualification candidate | 787,082 | `9281d49f449373ac957880f1082651838ddaaabcdd6b4166aefae67986682def` |
| limit preflight | 6,723 | `95239333b5ea49af1549280d200a1e960844c13f6a553a05c005314dc47ed004` |
| over-limit preflight | 6,733 | `691dad9e2bd7a43f8526f073c9fabf6291eb18ffb6015602556b9c8773394743` |
| family manifest | 10,201 | `51f0dd36a5d2aa39c7f23b4f5e65df3e9580c0feafff2814757dca57949dd835` |
| complete manifest | 3,046 | `17963981c274a83c62278065c5a1d704628e63bab97298d584ac9105e0a212b0` |

The largest file remains 66,321,782 bytes below the unchanged 67,108,864-byte
containment ceiling. That headroom is publication containment evidence, not a
runtime performance budget or an architecture-capacity claim.

## Nonclaims

Selection does not claim OSVVM runtime, another simulator, complete VHDL-2008,
PSL, mixed-language execution, IASIM execution, a promoted performance budget,
public support, architecture capacity, or a reached record limit. Those claims
remain with their separately owned qualification and promotion tasks.
