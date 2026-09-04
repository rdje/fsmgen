---
id: vial-architecture-scale-regression-promotion-capture
title: VIAL regression promotion captures eleven current profiles through isolated v2 publication
answers:
  - "how will the VIAL architecture scale regression corpus be captured?"
  - "why does the VIAL current promotion corpus use eleven workers instead of 44 workers?"
  - "what does 44 invocations mean in the VIAL regression promotion policy?"
  - "which existing measurement adapters feed the VIAL v2 promotion corpus?"
  - "does the structural OSVVM promotion route execute GHDL?"
  - "how are VIAL promotion dispatch paths content addressed?"
  - "how does one VIAL regression-promotion profile run in isolation?"
  - "how is the VIAL v2 current corpus resumed and published?"
  - "how are regression-promotion report coordinates authenticated separately from policy selection?"
  - "did the repaired VIAL regression-promotion current corpus complete?"
  - "what is the current VIAL regression-promotion corpus identity and how can it be independently verified?"
  - "why is current VIAL regression-promotion corpus loading CPU bound?"
  - "why is balanced VIAL report validation expensive?"
  - "how is VIAL canonicalization cost measured without changing returned values?"
  - "why does VIAL complete-corpus validation separate capture and execution revisions?"
  - "why does VIAL complete-corpus validation isolate each whole profile operation?"
  - "how is the current VIAL regression-promotion budget qualification stored atomically?"
  - "how is the current VIAL regression-promotion budget qualification published or validated explicitly?"
  - "what is the real current VIAL regression-promotion budget qualification publication identity?"
  - "how is the current VIAL regression-promotion budget qualification independently verified?"
  - "how are copied VIAL current-budget qualification mutations and later-run applicability falsified?"
  - "how is VIAL current-budget qualification closed?"
  - "what is the VIAL regression-promotion gate contract?"
  - "when does a VIAL regression-promotion gate enforce performance?"
  - "does a VIAL regression gate recalibrate its own qualification?"
  - "where does the VIAL regression gate publish its latest observation?"
  - "how does one VIAL regression gate profile execute without publishing calibration evidence?"
  - "why does the VIAL regression gate use an anonymous report spool?"
  - "how does the VIAL regression gate distinguish provider absence from provider drift?"
  - "how are all eleven VIAL regression gate profiles coordinated in memory?"
  - "what is the VIAL regression gate aggregate precedence?"
  - "how is the latest VIAL regression gate result replaced atomically?"
  - "can a prior VIAL gate result influence qualification or execution?"
  - "how do I run or validate the latest VIAL regression gate result?"
  - "does the VIAL regression gate CLI run work by default?"
  - "how do I run the authenticated VIAL regression gate through local CI?"
  - "how will VIAL regression gate evidence reach hosted CI?"
  - "how is the tracked VIAL regression gate evidence bundle authenticated?"
  - "how do I materialize the tracked VIAL regression gate evidence?"
  - "how does VIAL regression gate evidence cleanup avoid deleting pre-existing evidence?"
  - "which VIAL regression gate profiles run in hosted CI?"
  - "why does hosted VIAL regression CI not install substitute HDL tools?"
  - "why did VIAL regression gate ordinals 8-10 report correctness changed?"
  - "which VIAL lifecycle correctness fields are stable?"
  - "does the VIAL gate ignore process telemetry or recalibrate?"
  - "did the exact-pinned VIAL regression promotion gate pass?"
  - "what is the final independently closed VIAL regression gate observation?"
  - "where is the machine-readable VIAL architecture-scale regression capability?"
  - "where is the human VIAL architecture-scale regression operator guide?"
  - "how is VIAL architecture-scale regression public truth closed independently?"
date: 2026-09-04
status: current
tags: [hial, vial, scalability, regression, measurement, publication]
evidence: >-
  docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md; docs/decisions/0097-regression-gates-publish-replaceable-observations-without-recalibrating.md; docs/decisions/0098-hosted-regression-gates-materialize-immutable-tracked-evidence.md; docs/decisions/0099-regression-correctness-excludes-only-sealed-process-telemetry-derivatives.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/book/src/16df-vial-architecture-scale-cap-closeout.md;
  perl/FSM/Support/VIALArchitectureScaleRegressionContract.pm; perl/FSM/Support/VIALToolingContract.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionQualification.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateContract.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateProfile.pm; .github/workflows/regression.yml; bin/ci-regression; scripts/run_vial_regression_promotion_gate.pl; vial/qualification/regression_promotion_gate/evidence-v1/transport-manifest.json; t/1555-vial-public-source-tooling.t; t/1786-vial-regression-promotion-gate-profile.t; t/1790-vial-regression-promotion-evidence-transport.t; t/1793-vial-regression-promotion-gate-correctness-stability.t; t/1794-vial-architecture-scale-regression-capability.t; t/1795-vial-architecture-scale-regression-public-closeout.t
reverify: >-
  scripts/verify_vial_regression_promotion_current_corpus.pl; scripts/verify_vial_regression_promotion_budget_qualification.pl; perl scripts/verify_vial_regression_promotion_evidence_transport.pl;
  env FSMGEN_VIAL_REGRESSION_GATE_CONTRACT_EXACT=1 scripts/run_with_ram_guard.sh -- prove -Iperl t/1785-vial-regression-promotion-gate-contract.t; prove -Iperl t/1786-vial-regression-promotion-gate-profile.t t/1787-vial-regression-promotion-gate-coordinator.t t/1788-vial-regression-promotion-gate-store.t t/1789-vial-regression-promotion-gate-cli.t t/1790-vial-regression-promotion-evidence-transport.t;
  scripts/run_with_ram_guard.sh -- prove -Iperl t/1791-vial-regression-promotion-evidence-materialization.t; prove -Iperl t/1183-ci-regression-tier-selection.t t/1792-vial-regression-promotion-hosted-result-verifier.t t/1793-vial-regression-promotion-gate-correctness-stability.t;
  ./bin/fsmgen vial capabilities --json; ./bin/fsmgen --capability-manifest; prove -Iperl t/1555-vial-public-source-tooling.t t/1794-vial-architecture-scale-regression-capability.t t/1795-vial-architecture-scale-regression-public-closeout.t; ./bin/ci-regression vial-gate --dry-run --no-book; scripts/run_with_ram_guard.sh -- scripts/run_vial_regression_promotion_gate.pl --validate-result
---

Decision 0096 selects eleven v2 profiles, each with one validation and three raw
calls: 44 controller records across eleven guarded lifecycles. `.17.5.2`
authenticates seven adapters, bounds same-volume storage, isolates workers and
reload, supports exact resume, and falsifies copied evidence. Clean `610ed7869`
sealed nothing after exposing a report-coordinate mismatch; `.17.5.2.4.2`
corrected only producer-derived coordinate authority. Revision-1 matrices,
coordinate mutation, aliasing, and history swaps remain inadmissible.

The repaired capture at clean `155aa22ea` contains 11 selected reports,
11 validations, 33 fresh raw measurements, 44 accepted invocations, and zero
exclusions. Its atomic same-volume corpus is
`regression-promotion-corpus/ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505`;
its publication identity is `regression-promotion-corpus-publication/865c5cce3deee3eaaca9b66cd5d7f007a6e10b6423ac7d5dff2dc7484cd8432e`;
the complete file-set digest is `dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f`.
Producer-free validate/inventory reproduced every identity/count with eleven
present, zero missing, and no staging. Copied-artifact falsification is complete.

The production-independent verifier authenticates the 13-file/6,220,126-byte
corpus, 11/33/44/0 counts, identities, cleanup, nonclaims, and 7/1/3 provider
split; t1777 rejects 17 copied mutation classes. All paths agreed at
`1da11b2e3`; sampled timings remain characterization, never budgets.

`.17.5.3` atomically seals source, formula, budgets, environment/provider,
correctness, applicability, publisher, and recalibration authority in a fixed
two-file v2 namespace. From `8667f766c`, publication `1c2a3832...945f` and file
set `28ba972c...9095` reject content, schema, formula, identity, provenance,
path, alias, staging, or residue drift. Correctness precedes eligibility;
environment drift is informational, deterministic drift rejects, provider
absence is not pass, and recalibration needs separately owned old/new evidence.

Decision 0097 and `.17.5.4.1` add the metadata-only gate contract at
`regression-promotion-gate-contract/0150f4b3...e368`. It joins all eleven
canonical dispatches to the sealed qualification without executing work,
requires correctness and exact deterministic identity before applicability,
compares every fresh metric maximum only on an exact environment, and permits
no enforcement override. Unmatched performance is informational; unavailable
providers remain unavailable. Repeated gates will atomically replace one
latest observation under the v2 gate namespace without changing qualification
bytes or creating budget evidence. `.17.5.4.2` owns execution and publication.

`.17.5.4.2` runs each adapter once in a fresh child, validates full reports in
child and parent through anonymous same-volume spools, and carries only bounded
IPC metadata. It visits ordinals in order and re-admits them into a bounded
aggregate with fail, unavailable, informational, pass precedence and honest
required-versus-observed topology. The store atomically replaces one canonical
latest result, reloads before rename, preserves valid prior bytes on failure,
and cleans exact staging. The CLI exposes only explicit `--run` and
producer-free `--validate-result`; prior observations never become evidence.
T1786-T1789 own worker, aggregate, storage, command, mutation, and residue
attacks.

Decision 0098 tracks the exact 13 corpus plus two qualification payloads:
15 files/7,012,284 canonical bytes. Manifest `3b4c486e...2bbc6` binds every
safe path, byte, digest, class, and seal. The caller-free,
production-independent verifier re-derives both source identities/file sets;
T1790 rejects schema, order, path, canonicality, content, seal, census, link,
alias, and special-file mutations without touching generated coordinates.

The materializer owns one no-overwrite same-volume transaction; exact prior
evidence stays unowned. Local `vial-gate` and unsharded `full` share the
five-step lifecycle; T1183/T1791 retain selection, recovery, and cleanup.

Hosted CI adds one required unsharded Ubuntu-24.04 family: reject ambient
Verilator/fixed GHDL, materialize OSVVM 2026.05, run public `vial-gate`, then
guard the independent result verifier. T1792 locks informational 1-7/11,
unavailable-not-pass 8-10, required 11/33/44 versus observed 8/24/32, and closed
input/staging; cleanup owns only evidence, OSVVM, result, and stage.

Gates found ordinal 10 at 4 x 29/165,285 bytes, ordinal 8 at 4 x 24/77,952, and ordinal 9 at 4 x 29/81,709; semantics agreed. Decision 0099 normalizes only those exact telemetry derivatives; eight profiles and all semantic/topology fields stay exact. Clean ef59330ab then passed all eleven pinned profiles and published canonical 60,097-byte result c7787a02...02f2 with exact 11/33/44 topology, zero exclusions, and no process/stage residue. This observation neither recalibrates nor promotes support/capacity; t1786/t1787/t1793 retain hostile and non-pass classifications.

Public VIAL JSON and the complete manifest expose one pure
`vial.architecture_scale.regression_gate.v1` snapshot: commands, evidence,
ordered budgets, 11/33/44 topology, applicability, cleanup, bounded scope, and
nonclaims. T1555/T1794 join it to executable and tracked authorities without
reading ignored evidence or the replaceable result. The mdBook is the operator
guide; T1795 joins both machine entrypoints to every human row, runs its dry run
without result mutation, and rejects row, provider, budget, host, or nonclaim
drift.

The independent final closeout ran clean `840c895f3`: all profiles passed and
canonical result `f4b022fa...f5f97` has SHA-256 `d9d8788c...54729` and exact
11/33/44/0 topology. Independent joins and the full hostile band passed; all
evidence stayed immutable and atomic publication left no owned residue. This is
one revision/environment observation, not recalibration, support, or capacity.

Related: [[vial-architecture-scale-proof]], [[vial-common-worker-output-census-admission]],
[[vial-portable-vhdl-runtime-scale]], [[vial-vhdl-osvvm-qualified-tier]],
[[hosted-perl-regression-sharding]].
