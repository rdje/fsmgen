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
date: 2026-09-03
status: current
tags: [hial, vial, scalability, regression, measurement, publication]
evidence: >-
  docs/decisions/0096-regression-promotion-uses-a-current-eleven-profile-corpus.md; docs/decisions/0097-regression-gates-publish-replaceable-observations-without-recalibrating.md; docs/decisions/0098-hosted-regression-gates-materialize-immutable-tracked-evidence.md; docs/decisions/0099-regression-correctness-excludes-only-sealed-process-telemetry-derivatives.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/book/src/16df-vial-architecture-scale-cap-closeout.md;
  perl/FSM/VIAL/ArchitectureScaleRegressionPromotionQualification.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateContract.pm; perl/FSM/VIAL/ArchitectureScaleRegressionPromotionGateProfile.pm; .github/workflows/regression.yml; bin/ci-regression; scripts/run_vial_regression_promotion_gate.pl; vial/qualification/regression_promotion_gate/evidence-v1/transport-manifest.json; t/1786-vial-regression-promotion-gate-profile.t; t/1790-vial-regression-promotion-evidence-transport.t; t/1793-vial-regression-promotion-gate-correctness-stability.t
reverify: >-
  scripts/verify_vial_regression_promotion_current_corpus.pl; scripts/verify_vial_regression_promotion_budget_qualification.pl; perl scripts/verify_vial_regression_promotion_evidence_transport.pl;
  env FSMGEN_VIAL_REGRESSION_GATE_CONTRACT_EXACT=1 scripts/run_with_ram_guard.sh -- prove -Iperl t/1785-vial-regression-promotion-gate-contract.t; prove -Iperl t/1786-vial-regression-promotion-gate-profile.t t/1787-vial-regression-promotion-gate-coordinator.t t/1788-vial-regression-promotion-gate-store.t t/1789-vial-regression-promotion-gate-cli.t t/1790-vial-regression-promotion-evidence-transport.t;
  scripts/run_with_ram_guard.sh -- prove -Iperl t/1791-vial-regression-promotion-evidence-materialization.t; prove -Iperl t/1183-ci-regression-tier-selection.t t/1792-vial-regression-promotion-hosted-result-verifier.t t/1793-vial-regression-promotion-gate-correctness-stability.t;
  ./bin/ci-regression vial-gate --dry-run --no-book
---

Decision 0096 selects eleven v2 gate profiles. Each adapter call owns one
validation plus three raw calls: 44 records in eleven guarded lifecycles.
Revision-1 matrices are inadmissible.

`.17.5.2` authenticates seven adapters, bounds same-volume storage, isolates workers and parent reload, supports exact resume, exposes closed CLI modes, and falsifies copied v2 evidence. Only clean capture can seal. Complete coordinates enforce 11/33/44/0, common host/guard, provider order, and no history swap.

Clean `610ed7869` exposed a policy/report-coordinate mismatch and sealed no corpus. Its exact four-report/600,036-byte prefix remains independently verifiable in revision-keyed failed history. `.17.5.2.4.2` corrected only the capture-plan coordinate authority: schema v2 authenticates producer-derived coordinates independently of unchanged selection keys and rejects coordinate mutation or aliasing.

The repaired capture at clean `155aa22ea` contains 11 selected reports,
11 validations, 33 fresh raw measurements, 44 accepted invocations, and zero
exclusions. Its atomic same-volume corpus is
`regression-promotion-corpus/ab2df8992d85b8466f4afca530a5af36984031c453002534fc92ff5678a2e505`;
its publication identity is `regression-promotion-corpus-publication/865c5cce3deee3eaaca9b66cd5d7f007a6e10b6423ac7d5dff2dc7484cd8432e`;
the complete file-set digest is `dc5b315b827389eb466776716f6851cdd9ddd13b2f1aec441f8a51b7d72dc66f`.
Producer-free validate/inventory reproduced every identity/count with eleven
present, zero missing, and no staging. Copied-artifact falsification is complete.

The independent verifier imports no production module and authenticates the
13-file/6,220,126-byte corpus, 11/33/44/0 counts, identities, cleanup,
nonclaims, and 7/1/3 provider split; t1777 rejects 17 copied mutation classes.
Value-preserving JSON/clone/SHA instrumentation guided plan reuse and
whole-profile isolation, then all paths agreed at `1da11b2e3`. The sampled
timings are characterization, never stable budgets.

`.17.5.3` derives and atomically seals the current qualification in a fixed
two-file v2 namespace, binding source, formula, budgets, environment/provider,
correctness, applicability, publisher, and immutable recalibration/rollback.
From `8667f766c`, its 764,010-byte report and 28,148-byte manifest bind
publication `1c2a3832...945f` and file set `28ba972c...9095`; distinct validation
returns 793,084 canonical bytes. Independent and copied-hostile verification
rejects content, schema, type, formula, budget, identity, provenance, path,
alias, staging, or residue drift. Later exact identity is eligible only after
correctness; environment drift is informational, deterministic drift rejects,
provider absence is not pass, and recalibration needs separately owned old/new
immutable evidence. T1784 closes both real censuses with no owned residue.

Decision 0097 and `.17.5.4.1` add the metadata-only gate contract at
`regression-promotion-gate-contract/0150f4b3...e368`. It joins all eleven
canonical dispatches to the sealed qualification without executing work,
requires correctness and exact deterministic identity before applicability,
compares every fresh metric maximum only on an exact environment, and permits
no enforcement override. Unmatched performance is informational; unavailable
providers remain unavailable. Repeated gates will atomically replace one
latest observation under the v2 gate namespace without changing qualification
bytes or creating budget evidence. `.17.5.4.2` owns execution and publication.

`.17.5.4.2.1` implements one profile only. One fresh child calls the selected
adapter once; child and parent validate the full canonical report through an
immediately unlinked same-volume spool, while IPC carries bounded metadata.
The qualification's caller-sealed projection verifies correctness before
maximum timing. Exact environment uses inclusive pass/fail, mismatch is
informational, absence is unavailable, and present provider drift rejects.
T1786 is synthetic and leaves no spool or process residue; all three real
exact-provider preflights report available without running a workload.

`.17.5.4.2.2` derives one contract, visits ordinals 1-11 once through the
sealed profile seams, and re-admits every full result into one bounded in-memory
aggregate. It separates required 11/33/44 totals from honest observed counts
when providers are unavailable; precedence is fail, unavailable,
informational, pass. T1787 is synthetic and publishes nothing.

`.17.5.4.2.3` rederives the contract, admits only the complete coordinator
aggregate, and atomically replaces one canonical result through a same-volume
content-addressed stage. The 1,048,576-byte store reloads before rename,
preserves valid prior bytes on failure, recovers at most one exact stage, and
cleans staging. Producer-free load never uses prior observations as evidence;
t1788 rejects identity, byte, recovery, alias, file-shape, and mutation attacks.

`.17.5.4.2.4` exposes only explicit `--run` and producer-free
`--validate-result`; there is no default execution. Run publishes then reloads,
while validate only loads. Both print canonical result JSON through the
1,048,576-byte ceiling. Usage is status 2; operational failure is status 1
with empty stdout and one sanitized diagnostic capped at 4,096 bytes. T1789
uses copied fresh-process store fixtures and runs no real workload; t1786-t1788
retain the worker, aggregate, and storage adversarial layers.

Decision 0098's durable source now tracks the exact 13 corpus plus two
qualification payloads, 7,012,284 byte-identical canonical JSON bytes, beneath
`vial/qualification/regression_promotion_gate/evidence-v1/`. Its 8,725-byte
closed manifest binds transport `3b4c486e...2bbc6`, every safe fixed
source/destination path, byte count, digest, classification, and the accepted
corpus/qualification seals. The repository-derived verifier takes no caller
input, imports no production module, writes nothing, and re-derives both source
content identities and file sets. T1790 copies the bundle and rejects schema,
order, path, canonicality, byte, digest, source-seal, identity, extra/missing,
link, alias, and special-file mutations while proving generated coordinates
unchanged.

The fixed materializer owns one no-overwrite same-volume transaction; exact
prior evidence stays unowned. Local `vial-gate` and unsharded `full` run the
five-step lifecycle; T1183/T1791 retain selection, recovery, and cleanup.

Hosted CI now adds one required unsharded Ubuntu 24.04 family. It rejects
ambient Verilator/fixed GHDL, materializes exact OSVVM 2026.05, calls public
`vial-gate`, and guards a production-independent canonical-result verifier.
T1792 locks ordinals 1-7/11 informational, 8-10 unavailable-not-pass, required
11/33/44 versus observed 8/24/32, and closed input/staging. Always-cleanup owns
only evidence, OSVVM, latest-result, and stage; real execution remains `.4`.

Gates found ordinal 10 at 4 x 29/165,285 bytes, ordinal 8 at 4 x 24/77,952 bytes, and ordinal 9 at 4 x 29/81,709 bytes; semantics agreed and ordinal 11 passed. Decision 0099 keeps raw equality and normalizes only exact OSVVM, portable-Verilator, and portable-VHDL/GHDL lifecycle coordinates. Eight other profiles plus all semantic/topology fields stay exact; qualified identity and budgets stay fixed. T1786/T1793 retain hostile rejection.

Related: [[vial-architecture-scale-proof]], [[vial-common-worker-output-census-admission]],
[[vial-portable-vhdl-runtime-scale]], [[vial-vhdl-osvvm-qualified-tier]],
[[hosted-perl-regression-sharding]].
