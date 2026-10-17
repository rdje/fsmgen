---
id: vial-portable-vhdl-runtime-scale
title: Portable VHDL runtime scale uses compact sample snapshots and one staged GHDL lifecycle
answers:
  - how will portable VHDL reach 10,000 and 100,000 runtime trace records?
  - why can portable VHDL not copy the portable SystemVerilog reset recipe?
  - what does portable VHDL trace version 2 record?
  - how will exact GHDL qualification and scale measurement share execution?
  - what exact portable VHDL profiles have been measured with GHDL?
  - does portable VHDL runtime measurement mean IASIM execution?
  - which diagnostic wins when a portable VHDL phase and cleanup both fail?
  - which diagnostic wins when the separate GHDL probe and its abort both fail?
  - how does the GHDL lifecycle admit normalized result bytes?
  - how are GHDL result fixture and random decisions bound to plan authority?
  - how are GHDL scenario expectation diagnostic and cancelled fiber identities admitted?
  - how is the GHDL scenario logical-time domain bound to plan authority?
  - how are GHDL result scenario boundary times bound to the authenticated trace?
  - how are GHDL passing diagnostic codes and logical times bound to VHDL emitter behavior?
  - how is GHDL diagnostic cardinality bound to authenticated expectation trace counts?
  - how are GHDL fault applications and scoreboard comparisons bound to trace records?
  - how do fake GHDL lifecycle providers avoid host executable admission?
  - how does GHDL resume authenticate portable and OSVVM capture evidence?
  - how does GHDL resume authenticate command trace result and assembly evidence?
  - how does GHDL resume semantically authenticate terminal trace result and assembly payloads?
  - why must GHDL lifecycle object descriptors be append-only across states?
  - how does GHDL resume bind lifecycle authority version and OSVVM settings object bytes?
  - how does GHDL authenticate object descriptor JSON types and file modes?
  - how does GHDL authenticate lifecycle state and owner marker file size and mode?
  - how does GHDL authenticate handle and state scalar JSON types?
  - how does GHDL authenticate caller request storage and command-plan JSON integer types?
date: 2026-09-01
status: current
tags: [vial, vhdl, ghdl, runtime, trace, scalability]
evidence: >-
  docs/decisions/0090-portable-vhdl-runtime-scale-uses-sample-snapshots-and-one-shared-ghdl-lifecycle.md;
  perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm;
  perl/FSM/VIAL/Backend/VHDLPortableGHDLQualification.pm;
  perl/FSM/VIAL/Backend/GHDLLifecycle.pm; perl/FSM/VIAL/Backend/VHDLResultSchema.pm;
  perl/FSM/VIAL/Backend/ProcessSupervisor.pm;
  perl/FSM/VIAL/Backend/VerilatorLifecycle.pm;
  perl/FSM/VIAL/Backend/VHDLPortableTraceValidator.pm;
  perl/FSM/VIAL/ArchitectureScaleRuntimeStream.pm;
  perl/FSM/VIAL/ArchitectureScalePortableVHDLRuntimeMaterialization.pm;
  perl/FSM/VIAL/ArchitectureScalePortableVHDLRuntimeMeasurement.pm;
  perl/FSM/VIAL/ArchitectureScalePortableVHDLRuntimeMeasurementMatrix.pm;
  scripts/run_vial_portable_vhdl_runtime_measurement_matrix.pl;
  vial/qualification/vhdl_portable_ghdl_runtime_gate.vial;
  vial/qualification/vhdl_portable_ghdl_runtime_qualification.vial;
  vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json;
  t/1595-vial-vhdl-portable-ghdl-qualification.t;
  t/1664-vial-verilator-shared-lifecycle.t;
  t/1671-vial-vhdl-portable-trace-v2.t;
  t/1672-vial-architecture-scale-portable-vhdl-runtime-materialization.t;
  t/1673-vial-ghdl-shared-lifecycle.t;
  t/1731-vial-ghdl-capture-evidence-admission.t;
  t/1732-vial-ghdl-state-evidence-admission.t;
  t/1733-vial-ghdl-terminal-payload-resume-admission.t;
  t/1735-vial-ghdl-authority-object-admission.t; t/1736-vial-ghdl-object-descriptor-admission.t; t/1737-vial-ghdl-state-owner-file-admission.t; t/1738-vial-ghdl-handle-state-scalar-types.t; t/1739-vial-ghdl-request-scalar-types.t;
  t/1678-vial-ghdl-provider-aware-lifecycle.t;
  t/1725-vial-ghdl-cleanup-diagnostic-authority.t;
  t/1726-vial-ghdl-admission-cleanup-evidence.t;
  t/1727-vial-ghdl-probe-timeout-diagnostic-authority.t;
  t/1728-vial-ghdl-probe-abort-cleanup-authority.t; t/1729-vial-ghdl-result-record-admission.t;
  t/1674-vial-architecture-scale-portable-vhdl-runtime-measurement.t;
  t/1675-vial-architecture-scale-portable-vhdl-runtime-measurement-matrix.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16dd-vial-portable-vhdl-runtime-measurement.md
reverify: >-
  prove -Iperl t/1595-vial-vhdl-portable-ghdl-qualification.t
  t/1664-vial-verilator-shared-lifecycle.t
  t/1673-vial-ghdl-shared-lifecycle.t
  t/1678-vial-ghdl-provider-aware-lifecycle.t
  t/1731-vial-ghdl-capture-evidence-admission.t
  t/1732-vial-ghdl-state-evidence-admission.t
  t/1733-vial-ghdl-terminal-payload-resume-admission.t
  t/1735-vial-ghdl-authority-object-admission.t t/1736-vial-ghdl-object-descriptor-admission.t t/1737-vial-ghdl-state-owner-file-admission.t t/1738-vial-ghdl-handle-state-scalar-types.t t/1739-vial-ghdl-request-scalar-types.t
  t/1725-vial-ghdl-cleanup-diagnostic-authority.t
  t/1726-vial-ghdl-admission-cleanup-evidence.t
  t/1727-vial-ghdl-probe-timeout-diagnostic-authority.t
  t/1728-vial-ghdl-probe-abort-cleanup-authority.t t/1729-vial-ghdl-result-record-admission.t
  t/1675-vial-architecture-scale-portable-vhdl-runtime-measurement-matrix.t &&
  scripts/run_with_ram_guard.sh --
  scripts/run_vial_portable_vhdl_runtime_measurement_matrix.pl --validate &&
  FSMGEN_VIAL_PORTABLE_VHDL_RUNTIME_MEASUREMENT_EXACT=1
  scripts/run_with_ram_guard.sh --
  prove -Iperl t/1674-vial-architecture-scale-portable-vhdl-runtime-measurement.t &&
  rg -n 'vial_inactive_barrier|vial_emit_sample_trace|record_count|N \+ 74|9,926|99,926|admitted|prepared|tool_verified'
  perl/FSM/VIAL/ArchitectureScalePortableVHDLRuntimeMaterialization.pm
  perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm
  vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json
  docs/decisions/0090-portable-vhdl-runtime-scale-uses-sample-snapshots-and-one-shared-ghdl-lifecycle.md
  docs/book/src/16dd-vial-portable-vhdl-runtime-measurement.md
---

The historical portable-VHDL/GHDL v1 trace has 42 records. Trace-v2
implementation independently proves 35 real inactive-edge sample barriers:
19 in success and 16 in unsupported-size, including one final response-
settlement barrier omitted by the provisional selection census. Reset barriers
sample endpoints and probes but v1 emitted no corresponding record, so reset
inflation alone could not reach the runtime-stream targets. Decision `0090`
and `.17.3.6.1` implement a v2 trace whose header authenticates one ordered
four-entry/66-bit observation catalog and whose every real barrier emits one
compact normalized snapshot. The reference is 77 records and
`records(N)=N+74`. Two tracked authored sources now use success reset/timeout
9,926/16,384 and 99,926/131,072 for exact 10,000 and 100,000 projections.
Their only source deltas are those two literals. A sealed materializer rebuilds
Parser, bridge, ExecutionIR, plan, and portable-VHDL emission twice; it proves
21 operations, 39 ExecutionIR maps, 17 artifacts, six VHDL sources, 59 emitted
maps, and 21 checks with exact byte/content identities. Limit/excess remain
tool-free. The unchanged 64-MiB envelope remains authoritative, actual runtime
bytes remain unclaimed, and later GHDL measurement may honestly reject the
larger candidate.

One caller-sealed GHDL lifecycle owns exact qualification and dynamic measurement
from provider verification through same-volume cleanup. It reloads addressed
state/objects and uses the Verilator-derived process supervisor. The qualifier's
four-state probe shares that supervisor and reruns byte-identically. External
GHDL is not IASIM and adds no OSVVM, support, budget, or capacity claim.

The `.17.4.7` cleanup audit found that the shared GHDL exception boundary
recorded failed removal and exact residue but retained the earlier phase
diagnostic. Cleanup failure now becomes the authoritative
`VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR` at `/cleanup`, including a sanitized
fallback for unexpected host exceptions. Successful cleanup still preserves
the original timeout/execution diagnostic and reports zero residue. This
changes no GHDL command, deadline, capture ceiling, accepted output, provider
role, or scale claim.

Before an owner marker, admission records exact root removal/residue; cleanup
failure overrides the triggering diagnostic without inferring unwritten ownership.
Intermittent fake-provider deadlines persisted across native, `env`, absolute,
and tracked Perl. Three captures show 1.421–2.080-ms `exec` handoff, then no output
until TERM at 10.034–10.053 s, excluding signing, lookup, inode, containment, and
parent scheduling as sufficient causes. Fixtures prefer one tracked POSIX shell
with configured Perl fallback. Five guarded predecessor and three full passes
retain process/failure/cleanup coverage without retry or deadline change.

The qualifier's distinct four-state probe uses the same supervisor but retains
its own error translation. A timed-out probe now reports
`VIAL_VHDL_QUALIFICATION_TIMEOUT` at `/resource_controls` before capture-limit
or generic execution handling. Focused timeout-only and combined
timeout-plus-overflow controls prove that precedence; capture-only, nonzero
exit, successful output, and the live checked qualification remain unchanged.
The qualifier now also consumes the lifecycle abort result after any rejected
probe. Only `aborted_cleaned` with removal, zero residue, and zero diagnostics
preserves the original probe failure; failed, malformed, or unexpectedly
throwing aborts become the qualifier cleanup diagnostic at `/cleanup` with a
sanitized reason. No probe is retried and its process policy is unchanged.

The shared lifecycle now reauthenticates capture meaning whenever portable or
OSVVM state is resumed. It requires exact JSON supervisor booleans, successful
exit/signal/exec status, phase/profile containment plus timeout and capture
ceiling, consistent monotonic timing arithmetic, and an output byte count that
equals the sealed transcript object. Transcript and OSVVM report-set digests
and one-versus-two-run determinism are rederived from the same objects. t1731
falsifies foreign policy, byte, boolean, timing, transcript, report-set, and
determinism evidence; both live checked qualifiers remain byte-identical.

The same resume boundary reconstructs every remaining state summary. Admitted
authority, prepared source/library/settings, workspace, and portable/OSVVM
command evidence must match the caller-sealed inputs. Trace count/hash, passing
result status/hash, and assembly count/hash must match canonical sealed
same-volume payloads. t1732 rejects foreign values for every command family
and terminal digest while exact portable and provider-aware chains finish with
unchanged output and cleanup.

Caller-owned content objects are rebound rather than trusted for self-consistent hashes; every resumed state compares canonical `lifecycle_authority` bytes with reconstructed session authority.
Version and OSVVM-settings objects equal selected bytes in their applicable states; t1735 rejects foreign authority/version/settings/newline forms while both checked qualifiers remain exact.

Object descriptors are admitted values: writer/resume require valid kind/digest/path, numeric byte count, and JSON-boolean executable authority.
The validator rechecks same-volume bytes/SHA-256 and exact `0600`/`0700` mode; t1736 rejects string bytes, numeric false, invalid kinds, and mode disagreement while qualifiers stay byte-identical and residue-free.

State files are same-volume regular `0600` files at or below 1 MiB; `.owner.json` is a closed four-field numeric-version canonical marker at or below 4 KiB and exact `0600`.
The atomic writer normalizes `0600`; t1737 rejects state mode/size drift and owner mode/size/shape/type drift while both checked qualifiers remain byte-identical and residue-free.
Owner drift makes cleanup authority unprovable, so the lifecycle refuses to remove that root.

Handle/state versions/ordinals plus caller provider/source bytes, expected counts/catalog widths, repetition, storage version, OSVVM command-plan version, and settings bytes are canonical JSON integers; enum, identity, and path fields are scalars.
t1738 rejects foreign handle/rehashed-state types before comparison or digest reconstruction; t1739 rejects request/storage/plan strings or booleans before root creation while both checked qualifiers remain byte-identical and residue-free.

Terminal admission reconstructs trace/result/assembly meaning from sealed runtime bytes and requires each canonical reconstruction to equal its object; successor inventories retain predecessor descriptors as an ordered prefix and append only phase-owned objects.
t1733 rejects substituted terminal payloads and replaced/reordered/missing predecessor descriptors; live portable and OSVVM qualification remain byte-identical with zero staging residue.

Normalized result admission applies the selected 67,108,864-byte ceiling,
exact shared/VHDL vocabularies, one parity schema/version, sealed plan identity,
and ordered trace identities. Closure added omitted `samples`/projection-plan
members and `completed` status.
Scenario times are exact `domain_id/cycle/phase/ordinal` records:
zero/drive/zero start; same-domain check/zero end at positive count minus one.
This repaired the VHDL one-based end-cycle defect. The normalized authenticated
trace now retains exact ordered start/end boundaries too: every start is the
complete logical-time origin, every end is CHECK/local-zero, and lifecycle
admission maps trace cycle, phase rank, and local index to result cycle, phase,
and ordinal while taking only the domain from sealed plan authority. Real GHDL
proved that the emitter had reset only cycle between scenarios and emitted end
after the barrier restored DRIVE; it now resets the full time record and
selects CHECK before the end record. A self-consistent foreign domain,
cycle/count pair, phase, or ordinal therefore rejects before persistence.
Missing, foreign, duplicate, reordered, non-pass, excess, noncanonical, or
malformed records reject.
Parity counters are nonnegative and cycle-bounded; scalars are `0|1`; vectors
use `0/1/X/Z` at authenticated HRDATA/reg-data widths. Known nonzero final read
data, asserted response, or deasserted ready requires its nonzero counter.
The mdBook shows the canonical two-outcome projection; the compact OSVVM gallery
keeps only checked report path/identity/digest to avoid a second value authority.
Fixed schema/profile/evidence/flags, projection collections, aggregates, and
diagnostic records are closed; metrics equal records/cardinalities, zero passing
mismatches, and authenticated trace coverage (reset barriers are sampled cycles,
not coverage events). Lifecycle authority seals the plan fixture, its single
logical-time domain, and SHA-256 of canonical decisions; fixed authority is
independently plan-derived, dynamic callers derive from ExecutionIR, and result
mismatches reject before persistence. Both scenario timestamp domains must equal
that sealed domain, so even an internally consistent foreign pair rejects.
Passing diagnostics are ordered `VIAL_EXPECT_SUCCESS` or
`VIAL_EXPECT_ERROR` at each scenario end cycle with ranks `0/3/3`; mismatches reject.
Their count also equals the authenticated `expectations` trace count.
Fault applications and scoreboard comparisons each equal half their authenticated
trace count: the emitter writes arm/apply and enqueue/compare record pairs.
Portable VHDL emits no scenario-owned expectation, diagnostic, or cancelled-fiber
records, so each corresponding identity array must be exactly empty; this
VHDL-specific admission does not narrow richer trace-backed ResultProducer
behavior.
The earlier 127-byte result-contract repair moved the unchanged 16-MiB
portable/OSVVM structural witness to `T=29,505`. The boundary-time repair adds
112 fixed bytes without moving it: portable accepts 16,776,778 bytes and
adjacent `T=29,506` renders 16,777,346 bytes before atomic rejection; OSVVM
adds its fixed adapter to 16,781,129 selected bytes. Both graph oracles remain
v2 with regenerated identities.

The guarded exact adapter retains one 77-record reference, three gate
10,000-record measurements, and five qualification 100,000-record measurements:
11 isolated records, no excluded sample, and zero owned residue. Every record
reconstructs the six-source emission, four commands/transcripts, lifecycle
chain, trace/result, and cleanup. Structural limit/excess remains tool-free;
no budget, support, capacity, parity, IASIM, or API claim is promoted.

Commit `e7203c278` gives `.17.3.6.5` sole ownership of five-profile immutable
publication and fresh-process reload. After a copied six-artifact Verilator
assumption failed closed, raw and compact validators shared the producer's
seventeen-artifact VHDL authority. Revision
`d85256aa806a8dbdcf89c0e14b6bad9521521168` seals five profiles plus family and
complete manifests: seven files/1,354,895 bytes, largest 787,082. Guarded reload
identity is `portable-vhdl-runtime-matrix/cf0844de188b3a07ec7ed8026dcdfd95551cf7202b3df528659456da6e00e329`;
it retains three validations, eight raw/zero-excluded records, two preflights,
11 cleanup/zero residue, one common GHDL/host/guard identity, and no staging.
The 66,321,782-byte headroom is containment evidence only.

Related: [[vial-architecture-scale-proof]],
[[hial-vial-verification-fixture-architecture]].
