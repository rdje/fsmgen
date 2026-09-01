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
- Claim: The checked portable-VHDL v2 fixture produces 77 trace records across 35 real inactive-edge observation barriers; its authenticated four-entry/66-bit catalog and one snapshot per barrier establish `records(N)=N+74`, while ordered exact trace scenario boundaries independently bind every admitted result start/end cycle, phase, and ordinal. Reset/timeout candidates remain 9,926/16,384 and 99,926/131,072 for 10,000/100,000 records, with unchanged GHDL deadline/capture pairs 10/65,536, 120/8,388,608, 60/8,388,608, and 30/67,108,864.
- Re-derive: Run the guarded exact GHDL qualifier; independently census the 42 pre-snapshot records, 19/16 scenario sample partition, ordered observation catalog, exact trace/result scenario boundaries, normalized result, and emitted sample-call placement.
- Falsify: Hostile controls mutate canonical encoding, schema, framing, sequence, catalog identity/order/digest/width, sample identity/phase/width/symbols, scenario start/end logical time, result boundary projection, counts, footer closure, and checked qualification evidence; every mutation fails closed before result persistence.
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
| reference | 238,857 | 118,301 | 46,501 |
| gate candidate | 239,140 | 118,314 | 46,512 |
| qualification candidate | 239,557 | 118,326 | 46,523 |

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

Resume also authenticates the meaning of every capture record. The lifecycle
requires real JSON booleans for success/failure flags, the exact phase
containment, deadline, and byte ceiling, consistent spawn/exec/first-output/
exit arithmetic, and `output_bytes` equal to the sealed transcript object.
Empty transcripts must have no first-output timing. Transcript digests and
one-versus-two-run determinism are rederived from the same objects. Thus a
rehashed state cannot preserve valid transcript bytes while claiming a foreign
process outcome or policy. Focused control:

```console
prove -Iperl t/1731-vial-ghdl-capture-evidence-admission.t
```

Resume reconstructs the rest of the evidence too. The admitted authority
digest, prepared source/library inventory, workspace digest, and every
analysis/elaboration/run command digest must equal the caller-sealed inputs.
Trace count/hash evidence is derived from the canonical sealed validation
payload; result status/hash and assembly count/hash are derived from their
canonical sealed payloads. Payload reads retain regular-file and same-volume
checks. Consequently, rehashing a state cannot preserve valid objects while
claiming a foreign command, trace count, result status, or assembly inventory.
This focused control covers both portable and OSVVM state forms:

```console
prove -Iperl t/1732-vial-ghdl-state-evidence-admission.t
```

Content-addressing alone does not make caller-owned object bytes authoritative.
Every resumed state therefore compares its sealed `lifecycle_authority` object
with the canonical reconstructed session authority. From `tool_verified`
onward, the sealed version transcript must equal the selected multi-line GHDL
version followed by exactly one LF; live capture enforces that same canonical
form before writing the object. Provider-aware states at or beyond `prepared`
also compare the sealed generated-settings bytes with the selected command-plan
content. Rehashing the complete state chain around a foreign but internally
consistent authority, version, or settings object now rejects. Focused control:

```console
prove -Iperl t/1735-vial-ghdl-authority-object-admission.t
```

Object descriptors are admission claims too, not passive summaries. Both the
writer and every resume now require a closed descriptor with a valid kind and
SHA-256, a canonical numeric nonnegative byte count, a real JSON boolean
`executable` flag, and the exact content-addressed repository-relative path.
The same check binds the regular same-volume object to those bytes and digest
and to mode `0600` when non-executable or `0700` when executable. Thus a JSON
string such as `"19"` cannot masquerade as byte count `19`, numeric `0` cannot
masquerade as JSON false, and permission drift rejects even when content is
unchanged. Focused field/type/mode controls are runnable with:

```console
prove -Iperl t/1736-vial-ghdl-object-descriptor-admission.t
```

The chain and cleanup authorities now have byte and permission admission before
decode. Every state must be a same-volume regular `0600` file no larger than
1 MiB. The fixed `.owner.json` marker must be canonical JSON no larger than
4 KiB, use exact `0600`, contain only schema, numeric schema version, lifecycle
identity, and staging identity, and match the selected session. The atomic
writer normalizes `0600` explicitly instead of depending on process umask.
State mode/size drift therefore rejects before JSON semantics; owner drift
makes ownership unprovable, so cleanup refuses to remove that root. Focused
controls are runnable with:

```console
prove -Iperl t/1737-vial-ghdl-state-owner-file-admission.t
```

Canonical terminal payloads are not trusted merely because their evidence
summaries agree with them. On every resume at or beyond trace validation, the
lifecycle extracts the trace from the sealed runtime transcript and reruns the
full trace validator. At or beyond result production it decodes the original
runtime result and reruns all plan, scenario, time, outcome, aggregate, and
diagnostic checks against that reconstructed trace. At assembly it rebuilds
the exact portable or OSVVM assembly payload from the authenticated object
inventory. Each reconstructed canonical value must equal the sealed terminal
object byte for byte. Successor states must also retain every predecessor
object descriptor as an exact ordered prefix; they may only append the objects
owned by the new phase. A fully rehashed chain therefore cannot substitute a
foreign trace, minimal passing result, assembly, or earlier object while
remaining resumable. Focused falsification:

```console
prove -Iperl t/1733-vial-ghdl-terminal-payload-resume-admission.t
```

That distinct probe also preserves deadline authority: a supervisor
`timed_out` result reports `VIAL_VHDL_QUALIFICATION_TIMEOUT` at
`/resource_controls` before capture overflow or generic execution handling.
The probe is never retried, and its selected timeout and capture values do not
change.

Probe failure cleanup has separate authority. The qualifier accepts an abort
only when the lifecycle reports `aborted_cleaned`, exact removal, zero residue,
and zero diagnostics. A failed or malformed abort instead reports
`VIAL_VHDL_QUALIFICATION_CLEANUP_ERROR` at `/cleanup` with a bounded, sanitized
lifecycle reason. An exact successful abort rethrows the original probe error
unchanged; it does not retry the probe or alter any deadline or capture limit.

Normalized result admission is byte exact as well. The lifecycle checks the
JSON payload against the selected result byte ceiling before decode,
then requires its runtime bytes to equal their canonical JSON encoding before
persisting the normalized object. It also derives the exact top-level
vocabulary from the shared result-manifest producer: any missing or foreign
member rejects. This closure exposed an omitted `samples` member in the VHDL
producer itself; the emitter, both checked galleries, and both exact GHDL
qualification reports now carry the repaired complete manifest. The outer
result and its VHDL parity projection must also carry the exact plan identity
already sealed for trace validation. Adding that check exposed a missing plan
identity in the projection producer; producer and authenticated evidence are
repaired together. The ordered result scenarios must then match every sealed
trace run and its derived scenario identity, while the ordered parity outcomes
must name those same scenarios. Omission, duplication, reordering, or foreign
identity rejects before persistence. Every scenario result must also have the
shared `ResultProducer` scenario vocabulary. One `VHDLResultSchema` authority
defines the parity projection schema/version and its exact projection/outcome
vocabularies; the emitter consumes its schema identity and lifecycle admission
consumes its closed keys. Because the outer result already claims `pass`, every
scenario and parity outcome must also say `pass`. Missing or foreign nested
members, schema drift, or status drift rejects at the exact field path. Exact
scenario values are closed as well: both times have exactly
`domain_id/cycle/phase/ordinal`; start is cycle zero, `drive`, ordinal zero;
end is the same domain, `check`, ordinal zero, and cycle
`logical_cycle_count - 1`; the count is positive; passing completion is
`completed`; and all three identity collections are arrays of unique safe IDs.
This exposed a producer defect: generated VHDL used its one-based final sample
counter as both end cycle and count. It now stores `vial_time.cycle + 1` as the
count and serializes `count - 1` as the zero-based end cycle. Exact equality
passes; one excess byte or a semantically identical noncanonical spelling
rejects without a result object. The surrounding run-capture ceiling remains
an independent earlier defense.

Parity outcomes are value-closed before persistence too. All four counters are
nonnegative and no greater than the matching scenario cycle count; passing
ready/response scalars are exactly zero or one; read-data and storage strings
use only `0/1/X/Z` and match their authenticated observation-catalog widths.
A known nonzero final read, asserted final response, or deasserted final ready
also requires the corresponding nonzero counter. The checked two-scenario
projection remains:

| Scenario | Accepts | Ready-low | Response-error | Nonzero-read | Final ready/response | Final read data | Final storage |
| --- | ---: | ---: | ---: | ---: | --- | --- | --- |
| `success` | 1 | 15 | 0 | 0 | `1/0` | 32 zero bits | `11001010111111101011101010111110` |
| `unsupported_size` | 1 | 11 | 2 | 0 | `1/0` | 32 zero bits | 32 zero bits |

The fixed outer result is value-closed too: schema/version, execution and
backend profiles, capability/backend evidence, passing status, null result and
parity identities, false portable-parity eligibility, collection domains,
metric vocabulary, coverage/fault/scoreboard projections, and diagnostic
records must match the VHDL projection contract. Metrics must equal their
records and collection cardinalities; a passing result has zero scoreboard
mismatches. Coverage also equals the authenticated trace coverage count—not
the scenario-cycle total—because reset barriers are sampled cycles but emit no
coverage event. Fault applications and scoreboard comparisons bind to trace
counts as well: the emitter writes paired arm/apply fault records and paired
enqueue/compare scoreboard records. Self-consistent zero or excess aggregates
therefore reject even when their metrics agree. Lifecycle authority also seals
the selected fixture and SHA-256
of canonical plan-owned random decisions. Fixed qualification authority is
independently reproduced from the canonical plan; dynamic measurement callers
derive both from ExecutionIR. A foreign fixture or any decision-projection
mutation rejects before persistence without copying the nested decision object
into lifecycle state. The authority also seals the plan's single logical-time
domain: both scenario timestamp domains must equal it, so even an internally
consistent foreign start/end pair rejects. Fixed qualification reproduces that
domain from the canonical plan, while dynamic callers select it from ExecutionIR.
The authenticated trace now supplies a second, independent authority for the
scenario boundary values themselves. Its normalized projection retains each
run's exact `scenario_start` and `scenario_end` logical time in run order.
Starts must be the complete cycle/phase/static/local origin; ends must use the
CHECK phase and local index zero. Result admission maps trace cycle directly,
phase rank through `drive/sample/react/check`, and trace local index to result
ordinal, then supplies only the separately sealed plan domain. Both start and
end must match that projection exactly before the result object can persist.
This closes internally consistent forged cycle/count pairs as well as foreign
domains. Real GHDL exposed the producer side of the same defect: only the cycle
had been reset between scenarios, and `scenario_end` was emitted after the
inactive barrier had restored DRIVE. Generated VHDL now resets the complete
logical-time record for every scenario and emits the end boundary in CHECK.
The passing diagnostic collection is exact too: one record per scenario in
scenario order, emitter-selected `VIAL_EXPECT_SUCCESS`/`VIAL_EXPECT_ERROR` code,
the matching scenario end cycle, and logical-time ranks `0/3/3`. Missing, extra,
reordered, foreign, or mistimed diagnostics reject before persistence. Their
cardinality must also equal the authenticated `expectations` trace count.
The portable-VHDL producer emits no scenario-owned
expectation, diagnostic, or cancelled-fiber records, so each matching identity
projection must be exactly `[]`; any non-empty array rejects at its collection
path. This restriction is VHDL-projection-specific: trace-backed result
production for richer backends still derives these arrays from authenticated
expectation and fiber records.

Those values stay canonical in each checked qualification report and are shown
here for bounded reviewer visibility. The compact OSVVM gallery reference keeps
only the report path, identity, and digest: copying the nested projection there
would create a second value authority rather than improve verification.

The earlier result-contract correction added 127 fixed source bytes and moved the structural witness to `T=29,505`; the boundary-time correction adds 112 fixed bytes without moving it.
The unchanged 16-MiB cap accepts `T=29,505` at 16,776,778 bytes/29,543 maps; adjacent `T=29,506` renders 16,777,346 bytes and rejects, 130 bytes over.
OSVVM adds its fixed 4,351-byte adapter only after portable admission, producing 16,781,129 selected bytes; both revision-2 graph identities regenerate without changing the cap or a runtime/support/capacity claim.

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
  t/1728-vial-ghdl-probe-abort-cleanup-authority.t \
  t/1729-vial-ghdl-result-record-admission.t \
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
