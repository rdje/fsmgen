---
id: vial-vhdl-osvvm-qualified-tier
title: OSVVM 2026.05 is a separately qualified advanced VHDL provider above the portable core
answers:
  - "is exact OSVVM 2026.05 installed for FSMGen?"
  - "how is the recursive OSVVM provider identity verified?"
  - "where is the OSVVM VHDL adapter gallery?"
  - "has OSVVM 2026.05 plus GHDL 6.0.0 been qualified?"
date: 2026-08-10
status: current
tags: [hial, vial, vhdl, osvvm, ghdl, review-gallery, verification]
evidence: >-
  docs/decisions/0051-vial-vhdl-uses-a-provider-free-core-and-osvvm-qualified-tier.md;
  perl/FSM/VIAL/Backend/OSVVM2026_05Materialization.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVM2026_05.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMStaticValidator.pm;
  perl/FSM/VIAL/Backend/VHDLOSVVMGHDLQualification.pm;
  scripts/refresh_vial_vhdl_osvvm_gallery.pl;
  scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl;
  t/1598-vial-vhdl-osvvm-emission.t;
  t/1599-vial-vhdl-osvvm-ghdl-qualification.t;
  vial/qualification/vhdl_osvvm_ghdl/osvvm-2026.05-ghdl-6.0.0-qualification.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/README.md;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/provider-materialization.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/advanced-mapping-matrix.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/semantic-preservation.json;
  vial/review_gallery/vhdl_osvvm_qualified/ahb_base_output_advanced_services/evidence/qualification-reference.json;
  docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md;
  docs/book/src/16d-hial-vial-verification-architecture.md
reverify: >-
  prove -Iperl t/1598-vial-vhdl-osvvm-emission.t
  t/1599-vial-vhdl-osvvm-ghdl-qualification.t &&
  perl scripts/refresh_vial_vhdl_osvvm_gallery.pl --check &&
  perl scripts/run_vial_vhdl_osvvm_ghdl_qualification.pl --check
---

Decision `0051` keeps OSVVM a separately capability-qualified advanced
methodology provider, never the portable semantic core. Completed `.15.6` owns
exact recursive OSVVM 2026.05 materialization and structurally reviewed
adapter/gallery emission; completed `.15.7` owns the combined exact
provider/tool qualification.

The advanced graph locks 14 repositories, 13 gitlinks, 14 Apache-2.0 licence
files, zero notice files, and clean tree identities. The pinned Documentation
repository has no tracked licence/notice file, so no coverage is inferred.
Seven mappings emit beside the portable graph with 13 maps, 12 checks, and six
semantic guards. The exact tuple compiles 61 OSVVM/Common sources, analyzes
the seven generated sources plus its probe, and double-runs both tops.
Portable trace, result, and 19-path parity remain authoritative while the probe
executes random, coverage, scoreboard, report, memory, and barrier services;
the Common address-bus type is analysis-only.

Provider or tool behavior cannot redefine logical time, values, or results, so
this tier adds qualified services on top of the portable profile rather than
replacing its meaning.

Related: [[vial-vhdl-portable-profile]],
[[hial-vial-verification-fixture-architecture]].
