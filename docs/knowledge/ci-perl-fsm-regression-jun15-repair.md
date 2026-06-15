---
id: ci-perl-fsm-regression-jun15-repair
title: June 15 Perl FSM Regression CI repair owns public source facade and stale contract drift
answers:
  - "what owns the June 15 Perl FSM Regression CI failure?"
  - "why did GitHub run 27531373582 fail?"
  - "what is CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1?"
  - "why was HDLGenerator rejecting .isf and .ppif?"
  - "does HDLGenerator generate_hdl_from_file accept .isf and .ppif?"
  - "which local gate repaired GitHub run 27531373582?"
date: 2026-06-15
status: current
tags: [ci, regression, hdlgenerator, isf, ppif, capability-manifest, task-tree]
evidence: docs/tasks/CI-PERL-FSM-REGRESSION-JUN15-REPAIR.md; perl/FSM/Pipeline/HDLGenerator.pm; perl/FSM/Support/HDLGeneratorFacadeContract.pm; t/296-regression-corpus-supported-behavior.t; t/193-forward-structural-rtl-ir-builder-direct-root.t; t/370-capability-manifest-section-discovery-audit.t; t/1215-isf-spawn-parameter-binding.t; t/409-hdl-generator-facade-generation-argument-shape-boundary-audit.t; t/416-hdl-generator-facade-generation-argument-list-shape-boundary-audit.t
reverify: rg -n 'CI-PERL-FSM-REGRESSION-JUN15-REPAIR\\.1|27531373582|supported \\.fsm, \\.isf, or \\.ppif source root|file_surfaces|multi-pending await_any requires later same-body' docs/tasks/CI-PERL-FSM-REGRESSION-JUN15-REPAIR.md perl/FSM/Pipeline/HDLGenerator.pm perl/FSM/Support/HDLGeneratorFacadeContract.pm perl/FSM/Support/CapabilityManifestContract.pm t/296-regression-corpus-supported-behavior.t t/193-forward-structural-rtl-ir-builder-direct-root.t t/370-capability-manifest-section-discovery-audit.t t/1215-isf-spawn-parameter-binding.t t/409-hdl-generator-facade-generation-argument-shape-boundary-audit.t t/416-hdl-generator-facade-generation-argument-list-shape-boundary-audit.t
---

`CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` owns the completed repair for GitHub
`Perl FSM Regression` run `27531373582`.

The failure reproduced locally as a mix of real facade drift and stale tests:
`FSM::Pipeline::HDLGenerator` rejected supported `.isf` and `.ppif` public
source roots under a `.fsm`-only guard, `t/193` bypassed generated-module
analysis enrichment before StructuralRTLIR extraction, `t/370` missed the
`language_surface.file_surfaces` contract key, and `t/1215` expected an older
repeat-body diagnostic string.

The repair widened the public HDLGenerator source facade to supported `.fsm`,
`.isf`, and `.ppif` source roots while preserving scalar/exact-one-argument
validation, updated the facade capability contract, and aligned stale tests.
Local `./bin/ci-regression` passed after the repair (`Files=1437`,
`Tests=11200`) and its trailing mdBook build completed successfully.
