---
id: vial-portable-vhdl-runtime-scale
title: Portable VHDL runtime scale uses compact sample snapshots and one staged GHDL lifecycle
answers:
  - "how will portable VHDL reach 10,000 and 100,000 runtime trace records?"
  - "why can portable VHDL not copy the portable SystemVerilog reset recipe?"
  - "what does portable VHDL trace version 2 record?"
  - "how will exact GHDL qualification and scale measurement share execution?"
  - "what exact portable VHDL profiles have been measured with GHDL?"
  - "does portable VHDL runtime measurement mean IASIM execution?"
  - "which diagnostic wins when a portable VHDL phase and cleanup both fail?"
  - "which diagnostic wins when the separate GHDL probe and its abort both fail?"
  - "how do fake GHDL lifecycle providers avoid host executable admission?"
date: 2026-08-31
status: current
tags: [vial, vhdl, ghdl, runtime, trace, scalability]
evidence: >-
  docs/decisions/0090-portable-vhdl-runtime-scale-uses-sample-snapshots-and-one-shared-ghdl-lifecycle.md;
  perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm;
  perl/FSM/VIAL/Backend/VHDLPortableGHDLQualification.pm;
  perl/FSM/VIAL/Backend/GHDLLifecycle.pm;
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
  t/1678-vial-ghdl-provider-aware-lifecycle.t;
  t/1725-vial-ghdl-cleanup-diagnostic-authority.t;
  t/1726-vial-ghdl-admission-cleanup-evidence.t;
  t/1727-vial-ghdl-probe-timeout-diagnostic-authority.t;
  t/1728-vial-ghdl-probe-abort-cleanup-authority.t;
  t/1674-vial-architecture-scale-portable-vhdl-runtime-measurement.t;
  t/1675-vial-architecture-scale-portable-vhdl-runtime-measurement-matrix.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16dd-vial-portable-vhdl-runtime-measurement.md
reverify: >-
  prove -Iperl t/1595-vial-vhdl-portable-ghdl-qualification.t
  t/1664-vial-verilator-shared-lifecycle.t
  t/1673-vial-ghdl-shared-lifecycle.t
  t/1678-vial-ghdl-provider-aware-lifecycle.t
  t/1725-vial-ghdl-cleanup-diagnostic-authority.t
  t/1726-vial-ghdl-admission-cleanup-evidence.t
  t/1727-vial-ghdl-probe-timeout-diagnostic-authority.t
  t/1728-vial-ghdl-probe-abort-cleanup-authority.t
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

One caller-sealed GHDL lifecycle now owns provider verification, preparation,
analysis, elaboration, run, trace validation, result production, assembly, and
cleanup for exact qualification and the common-controller measurement adapter.
It reloads content-addressed state/object chains and uses the same
sealed process supervisor extracted from the byte-stable Verilator lifecycle.
The qualifier's separate four-state probe uses that supervisor and the fresh
exact rerun remains byte-identical to its checked report. This external GHDL
execution is not IASIM execution and adds no OSVVM, support, budget, or capacity
claim.

The `.17.4.7` cleanup audit found that the shared GHDL exception boundary
recorded failed removal and exact residue but retained the earlier phase
diagnostic. Cleanup failure now becomes the authoritative
`VIAL_GHDL_LIFECYCLE_CLEANUP_ERROR` at `/cleanup`, including a sanitized
fallback for unexpected host exceptions. Successful cleanup still preserves
the original timeout/execution diagnostic and reports zero residue. This
changes no GHDL command, deadline, capture ceiling, accepted output, provider
role, or scale claim.

Admission cleanup is exact before an owner marker exists. The lifecycle
directly remembers whether it removed the absent root it just created after a
later admission write failed. Successful removal retains the triggering
diagnostic and reports removal with zero residue; removal failure becomes the
cleanup diagnostic with the exact residual staging identity. This authority
does not infer ownership from an owner file that may not yet have been written.
Adjacent lifecycle-suite runs exposed intermittent exact-deadline timeouts in
fake-provider version probes. Native doubles produced AMFI `-423` traffic, but
`env perl`, configured-absolute Perl, and a stable tracked Perl script also
timed out. Three compact captures place successful `exec` handoff at
1.421–2.080 milliseconds followed by 10.034–10.053 seconds with zero output
before TERM, falsifying native signing, ambient path lookup, fresh inode
identity, containment mode, and parent capture scheduling as sufficient causes.
The final fixtures use one stable tracked POSIX-shell provider when `/bin/sh`
exists and retain configured Perl only as a portability fallback. Five guarded
predecessor passes and three full seven-file passes retain real supervisor,
process-group, failure, report, and cleanup coverage; no launch crosses the
two-second sampling threshold, no phase is retried, and the ten-second product
deadline is unchanged.

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

The guarded exact adapter accepts one 77-record reference validation, one gate
validation plus three retained 10,000-record measurements, and one
qualification validation plus five retained 100,000-record measurements. Each
of the 11 isolated records reconstructs canonical authority, authenticates the
six-source emission, four command/transcript identities, lifecycle predecessor
chain, trace and normalized result, and proves lifecycle plus controller
cleanup. No sample is excluded and no owned staging residue remains. Limit and
over-limit shapes remain controller- and tool-free under the earlier structural
authority; the measurement creates no promoted budget, support, capacity,
parity, IASIM, or public-API claim.

Clean measurement commit `e7203c278` activates `.17.3.6.5` as the sole owner of
five-profile immutable publication and independent fresh-process reload. The
new producer-derived publisher isolates every profile, retains raw canonical
reports before returning compact coordinator entries, seals only one clean
Git/host/GHDL/guard identity, and rejects collision, ambiguity, mutation,
oversize, signal, or incomplete state. It reuses the earlier runtime-capture
byte authority as a conservative file ceiling. Its first clean exact attempt
failed closed before publication because a copied aggregate check required the
portable-Verilator six-artifact graph; the underlying accepted portable-VHDL
lifecycle correctly retained seventeen. Raw and compact validators now share
that exact producer authority, with an executable seventeen-artifact manifest
control. Clean revision `d85256aa806a8dbdcf89c0e14b6bad9521521168` now
seals five profiles plus family/complete manifests as seven files totaling
1,354,895 bytes. The largest is 787,082 bytes. A separate guarded reload returns
complete identity
`portable-vhdl-runtime-matrix/cf0844de188b3a07ec7ed8026dcdfd95551cf7202b3df528659456da6e00e329`;
the aggregate retains three validations, eight raw/zero excluded records, two
preflights, 11 cleanup/zero residue, one common GHDL/host/guard identity, and no
staging. The retained 66,321,782-byte ceiling headroom is containment evidence,
not a performance, capacity, support, parity, OSVVM, IASIM, or API claim.

Related: [[vial-architecture-scale-proof]],
[[hial-vial-verification-fixture-architecture]].
