---
id: vial-portable-vhdl-runtime-scale
title: Portable VHDL runtime scale uses compact sample snapshots and one staged GHDL lifecycle
answers:
  - "how will portable VHDL reach 10,000 and 100,000 runtime trace records?"
  - "why can portable VHDL not copy the portable SystemVerilog reset recipe?"
  - "what does portable VHDL trace version 2 record?"
  - "how will exact GHDL qualification and scale measurement share execution?"
  - "does portable VHDL runtime measurement mean IASIM execution?"
date: 2026-08-27
status: current
tags: [vial, vhdl, ghdl, runtime, trace, scalability]
evidence: >-
  docs/decisions/0090-portable-vhdl-runtime-scale-uses-sample-snapshots-and-one-shared-ghdl-lifecycle.md;
  perl/FSM/VIAL/Backend/VHDLPortableGHDL.pm;
  perl/FSM/VIAL/Backend/VHDLPortableGHDLQualification.pm;
  perl/FSM/VIAL/Backend/VHDLPortableTraceValidator.pm;
  perl/FSM/VIAL/ArchitectureScaleRuntimeStream.pm;
  vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json;
  t/1595-vial-vhdl-portable-ghdl-qualification.t;
  t/1671-vial-vhdl-portable-trace-v2.t;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16dd-vial-portable-vhdl-runtime-measurement.md
reverify: >-
  scripts/run_with_ram_guard.sh --
  scripts/run_vial_vhdl_portable_ghdl_qualification.pl --check &&
  rg -n 'vial_inactive_barrier|vial_emit_sample_trace|record_count|N \+ 74|9,926|99,926|admitted|prepared|tool_verified'
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
`records(N)=N+74`; authored reset candidates 9,926 and 99,926 target exact
10,000 and 100,000 records. The unchanged 64-MiB envelope remains authoritative
and may honestly dominate the larger candidate.

One caller-sealed GHDL lifecycle will own provider verification, preparation,
analysis, elaboration, run, trace validation, result production, assembly, and
cleanup for both exact qualification and common-controller measurement. The
separate four-state probe remains qualification evidence. This external GHDL
execution is not IASIM execution and adds no OSVVM, support, budget, or capacity
claim.

Related: [[vial-architecture-scale-proof]],
[[hial-vial-verification-fixture-architecture]].
