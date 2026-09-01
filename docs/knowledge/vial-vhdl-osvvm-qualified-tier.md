---
id: vial-vhdl-osvvm-qualified-tier
title: OSVVM 2026.05 is a separately qualified advanced VHDL provider above the portable core
answers:
  - "is exact OSVVM 2026.05 installed for FSMGen?"
  - "how is the recursive OSVVM provider identity verified?"
  - "where is the OSVVM VHDL adapter gallery?"
  - "has OSVVM 2026.05 plus GHDL 6.0.0 been qualified?"
  - "how is exact OSVVM provider verification reused safely?"
  - "how are portable VHDL source maps preserved in the OSVVM wrapper?"
  - "how are authored portable VHDL runtime sources materialized through OSVVM?"
  - "how is the exact OSVVM GHDL execution plan sealed?"
  - "how does the provider-aware GHDL lifecycle execute the exact OSVVM plan?"
  - "how are OSVVM runtime reference gate and qualification records measured?"
  - "how is the complete OSVVM runtime measurement matrix published and reloaded?"
  - "how are OSVVM supplementary provider report bytes bounded before publication?"
  - "how are OSVVM persisted lifecycle-request integers and both provider authorities admitted?"
date: 2026-09-01
status: current
tags: [hial, vial, vhdl, osvvm, ghdl, review-gallery, verification]
evidence: >-
  docs/decisions/0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md;
  docs/decisions/0075-backend-emission-scale-uses-profile-specific-anchored-routes.md;
  perl/FSM/VIAL/Backend/OSVVM2026_05Materialization.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVM2026_05.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMStaticValidator.pm;
  perl/FSM/VIAL/Backend/GHDLLifecycle.pm; perl/FSM/VIAL/Backend/VHDLOSVVMGHDLQualification.pm;
  perl/FSM/VIAL/ArchitectureScaleBackendEmission/OSVVM.pm;
  perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMaterialization.pm; perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeExecutionPlan.pm; perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMeasurement.pm; perl/FSM/VIAL/ArchitectureScaleOSVVMRuntimeMeasurementMatrix.pm;
  perl/FSM/VIAL/BackendEmissionAuthority.pm; perl/FSM/Support/VIALVHDLEmissionContract.pm;
  scripts/refresh_vial_vhdl_osvvm_gallery.pl;
  scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl;
  scripts/run_vial_osvvm_runtime_measurement_matrix.pl;
  t/1598-vial-vhdl-osvvm-emission.t;
  t/1599-vial-vhdl-osvvm-ghdl-qualification.t;
  t/1642-vial-vhdl-osvvm-provider-evaluation.t; t/1644-vial-backend-emission-authority-alignment.t;
  t/1648-vial-architecture-scale-backend-emission-osvvm.t;
  t/1676-vial-architecture-scale-osvvm-runtime-materialization.t;
  t/1677-vial-architecture-scale-osvvm-runtime-execution-plan.t;
  t/1678-vial-ghdl-provider-aware-lifecycle.t;
  t/1679-vial-architecture-scale-osvvm-runtime-measurement.t;
  t/1680-vial-architecture-scale-osvvm-runtime-measurement-matrix.t; t/1740-vial-osvvm-persisted-request-scalar-types.t; t/1741-vial-osvvm-persisted-provider-admission.t; t/1742-vial-osvvm-persisted-ghdl-provider-admission.t;
  .artifacts/qualification/vial-scale/v1/osvvm-runtime-matrix-v1/matrix.json;
  .artifacts/qualification/vial-scale/v1/osvvm-runtime-complete-matrix-v1/complete-matrix.json;
  vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/README.md;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/provider-materialization.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/advanced-mapping-matrix.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/semantic-preservation.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/qualification-reference.json;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md; docs/book/src/16de-vial-osvvm-runtime-execution-plan.md
reverify: >-
  prove -Iperl t/1598-vial-vhdl-osvvm-emission.t
  t/1599-vial-vhdl-osvvm-ghdl-qualification.t
  t/1642-vial-vhdl-osvvm-provider-evaluation.t
  t/1644-vial-backend-emission-authority-alignment.t
  t/1648-vial-architecture-scale-backend-emission-osvvm.t
  t/1676-vial-architecture-scale-osvvm-runtime-materialization.t
  t/1677-vial-architecture-scale-osvvm-runtime-execution-plan.t &&
  prove -Iperl t/1678-vial-ghdl-provider-aware-lifecycle.t
  t/1680-vial-architecture-scale-osvvm-runtime-measurement-matrix.t t/1740-vial-osvvm-persisted-request-scalar-types.t t/1741-vial-osvvm-persisted-provider-admission.t t/1742-vial-osvvm-persisted-ghdl-provider-admission.t &&
  scripts/run_with_ram_guard.sh -- env
  FSMGEN_VIAL_OSVVM_RUNTIME_MEASUREMENT_EXACT=1 prove -Iperl
  t/1679-vial-architecture-scale-osvvm-runtime-measurement.t &&
  scripts/run_with_ram_guard.sh --
  scripts/run_vial_osvvm_runtime_measurement_matrix.pl --validate &&
  perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check &&
  perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
---

Decision `0051` keeps OSVVM a separately qualified advanced provider, never the
portable semantic core. Its exact 2026.05 graph locks 14 repositories, 13
gitlinks, 14 Apache-2.0 licence files, zero notices, clean identities, and the
Documentation repository's explicit metadata absence. Seven adapter mappings
precede all 59 portable entries translated to wrapper paths and identities, so
the exact graph has 66 maps, 12 checks, and six guards beside unchanged
portable semantics. Schema, artifact-digest, identity, span, or coverage drift
fails before the wrapper publishes an artifact graph.

The GHDL 6.0.0 tuple compiles 61 provider sources, analyzes seven generated
sources plus its probe, and double-runs both tops. Portable trace, result, and
19-path parity stay authoritative; provider random, coverage, scoreboard,
report, memory, and barrier evidence is supplementary.

One callback evaluation verifies the exact provider once and keeps its root and
result digest behind an opaque capability. Matching emissions receive defensive
copies; mismatched, forged, stale, or failure-retained handles return no
artifacts. Standalone emission still verifies independently and remains
byte-identical, so reuse changes neither qualification nor semantic authority.

Catalog and capability discovery now consume one closed shared authority. It
separates six portable sources, one fixed 4,351-byte wrapper adapter, seven
total sources, and provider materialization; the 16-MiB boundary applies only
to the portable six-source foundation. Reference discovery reports 16 total
artifacts, 66 maps, twelve wrapper checks, and 21 prerequisite portable
checks. Unknown, missing, stale, or contradictory fields fail closed.

The caller-sealed architecture-scale profile owns T=21/128/512/29,505 plus
adjacent portable-foundation T=29,506 rejection. One provider verification is
reused only inside its callback for two defensive emissions. Accepted source
totals are 122,654/181,023/392,991/16,781,129 bytes with
66/173/557/29,550 complete maps; every wrapper map, provider/source identity,
mapping status, semantic guard, and evidence encoding is checked before the
content-addressed report is accepted. The adjacent excess publishes no
partial provider evidence or graph. This generator proof executes no external
compiler or runtime and adds no product support, performance, or capacity
claim.

Related: [[vial-vhdl-portable-profile]],
[[hial-vial-verification-fixture-architecture]].

Decision `0092` selects `.17.3.7` as a five-leaf runtime-measurement chain. It reuses the tracked portable-VHDL runtime sources, adds a profile-specific OSVVM materializer, extracts one caller-sealed provider/tool plan, and admits that plan through a provider-aware role of the shared GHDL lifecycle before measurement and publication. Provider verification, FSMGen work, and external tool stages remain distinct; selection adds no measurement or promoted claim.

Child `.17.3.7.1` materializes the exact authored portable-VHDL reference, 10,000-record gate, and 100,000-record qualification sources through the qualified OSVVM wrapper. Each role stays at 21 operations and 39 ExecutionIR maps, verifies the pinned provider once for two byte-identical emissions, and closes 16 artifacts, seven sources, 66 maps, twelve checks, seven advanced mappings, six preserved portable sources/guards, and the exact provider census. The seven-source totals are 122,652/122,665/122,677 bytes; t1676 re-derives and falsifies these identities, while the module, task tree, and this card retain them durably. Limit/excess are provider-, route-, staging-, and tool-free.

Child `.17.3.7.2` seals three in-memory OSVVM/GHDL plans: each binds 61 provider analyses, seven emitted sources plus the checked probe, separate fixture/probe commands, four reports, exact tool/resource authority, and repository-relative storage. t1677 re-derives the full identities and falsifies widening; the qualifier consumes the same private authority and stays byte-identical to its checked 74,976-byte executable oracle. Evaluation creates no stage or process and limit/excess stay plan-free.

Child `.17.3.7.3` admits only that plan through a distinct provider-aware role of the shared GHDL lifecycle. The role preserves portable v1 authority, uses the same supervisor and forward state/object/cleanup implementation, records ordered provider/generated captures plus separate fixture/probe evidence, seals supplementary reports, revalidates tool/source/settings authority, and leaves both checked qualifier reports byte-identical. t1678 owns hostile plan/settings/report/caller/cleanup controls.

The `.17.4.7` runtime-envelope audit closes file-report and persisted-request
admission. Four OSVVM file reports receive a closed same-volume census and
67,108,864-byte aggregate preflight before read or object write; exact equality
passes, adjacent excess and post-preflight drift reject before persistence.
Persisted lifecycle-request reload admits envelope version/run repetitions only as canonical JSON integers and re-derives both plan-selected provider projections
before predecessor, lifecycle, or tool work: six OSVVM checkout fields and seven GHDL executable/archive fields. Strings, booleans, or one changed authority
field reject; t1740-t1742 falsify those boundaries while qualification, accepted reports, measurement identities, and cap values remain unchanged.

Child `.17.3.7.4` maps that exact authority onto the common controller without adding a competing process path. Guarded t1679 accepts eleven independent records: reference validation, gate validation plus three measured records, and qualification validation plus five measured records. Every record retains 61 provider-analysis captures, 68 lifecycle sources, separate fixture/probe elaborations, one fixture and one provider-probe run, four reports, portable trace/result truth, stable provider identity, and zero controller/lifecycle residue. Exact trace counts are 77/10,000/100,000; limit/excess remain provider-, plan-, controller-, lifecycle-, and tool-free. Publication, performance, support, capacity, provider-generality, mixed-language, and public-API claims remain deferred.

Clean measurement commit `03292cd1e` activates `.17.3.7.5` as the sole owner
of OSVVM-specific immutable five-role publication and independent fresh-
process reload. The exact-class publisher now derives producer order, isolates
profile workers, publishes full canonical reports before bounded compact
entries, and binds only one clean revision/host/provider/tool/guard identity.
Its runner and t1680 reject mixed, reordered, incomplete, collided, signalled,
oversized, or ambiguous state. The implementation is present, but no aggregate
was claimed until clean guarded capture and a distinct fresh-process reload
both completed.

Clean revision `ef10332d6610df717de1471d12d3a8f0a678aebf` now seals the
five-role OSVVM matrix as seven immutable files totaling 6,105,680 bytes. The
largest profile is 3,398,045 bytes; family dominance retains three validations,
eight raw and zero excluded measurements, two preflight-dominated profiles,
eleven cleanups, and zero residue. Every executable profile retains the exact
16-artifact, 61-provider-analysis, 68-source, four-report evidence graph. A
separate guarded process revalidates complete identity
`osvvm-runtime-matrix/5429888419a848d28ff4250833e6bd60e31d583d3054a7929d1df3e21420e219`
under the pinned provider/GHDL tuple, Apple M4 Pro/APFS host identity, and active
repository guard. The publication remains evidence for these measured profiles
only; it promotes no budget, capacity, support, parity, or provider-generality
claim.
