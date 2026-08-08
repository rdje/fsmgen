---
id: ci-perl-fsm-regression-jun15-repair
title: Perl FSM supported-runtime regression facade and oracle contracts
answers: ["what owns the June 15 Perl FSM Regression CI failure?", "why did GitHub run 27531373582 fail?", "what is CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1?", "why was HDLGenerator rejecting .isf and .ppif?", "does HDLGenerator generate_hdl_from_file accept .isf and .ppif?", "which local gate repaired GitHub run 27531373582?"]
answers: ["why does t296 use a different PPIF module oracle for the pipeline and CLI?", "what does expected_pipeline_module_name mean in RegressionCorpus?", "does PPIF pipeline HDL contain the public aggregate top?", "how is generated_hdl_entry_artifact checked by the supported-smoke audit?", "how many PPIF smoke entries have distinct pipeline and CLI modules?", "can a PPIF pipeline entry artifact filename differ from its HDL module?", "does HDLGenerator accept .ahb .apb or .axi profile-alias paths?", "why does t296 exclude IAL2 profile aliases from its pipeline loops?", "are IAL2 profile aliases still checked through the CLI by t296?", "how many supported-smoke profile aliases are CLI-only in t296?"]
date: 2026-08-07
status: current
tags: [ci, regression, hdlgenerator, ppif, supported-smoke, profile-alias, pipeline, cli]
evidence: docs/tasks/CI-PERL-FSM-REGRESSION-JUN15-REPAIR.md; docs/tasks/SUPPORTED-SMOKE-PPIF-PIPELINE-CLI-ORACLE-SPLIT.md; perl/FSM/Pipeline/HDLGenerator.pm; perl/FSM/Support/RegressionCorpus.pm; t/296-regression-corpus-supported-behavior.t
reverify: >-
  prove -Iperl t/248-regression-corpus-accounting.t t/249-regression-corpus-classified-behavior.t t/296-regression-corpus-supported-behavior.t t/491-regression-corpus-runtime-defensive-copy-boundary-audit.t
---

`CI-PERL-FSM-REGRESSION-JUN15-REPAIR.1` repaired GitHub run `27531373582`.
HDLGenerator had rejected supported `.isf` and `.ppif` roots under a
`.fsm`-only guard; tests also had three stale contracts recorded in the task.
The repaired facade accepts scalar, exact-one-argument `.fsm`, `.isf`, and
`.ppif` roots. Local `./bin/ci-regression` passed (`Files=1437`, `Tests=11200`)
with its trailing mdBook build.

For PPIF, the in-memory facade compiles one generated `.fsm` entry artifact
and reports it as `source_info.generated_hdl_entry_artifact`; the CLI can emit
the aggregate top. The registry therefore keeps `expected_module_name` as the
shared/CLI oracle and declares `expected_pipeline_module_name` for the 62 of
240 strict entries whose pipeline module differs: 18 AHB, 37 APB, five AXI
composition, and two valid-ready bundles. `t/296` checks the pipeline module
and exact entry artifact independently; the bundles explicitly override the
artifact expectation because wrapper filenames and emitted monitor modules
differ. CLI assertions retain the aggregate-module oracle.

The default/strict pipeline/CLI cohorts use deterministic self-workers—one
pipeline entry or four CLI entries—so allocator and file-cache growth is
released below the unchanged 4096-MiB descendant-RSS cap. The facade remains
limited to `.fsm`, `.isf`, and `.ppif`; 86 supported profile aliases (28
`.ahb`, 57 `.apb`, one `.axi`) remain CLI-only, are excluded from both pipeline
cohorts, and remain checked in both CLI cohorts.
