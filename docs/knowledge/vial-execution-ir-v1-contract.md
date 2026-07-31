---
id: vial-execution-ir-v1-contract
title: VIAL execution v1 is deterministic logical time above backend methodology
answers:
  - "what is VIALExecutionIR version 1?"
  - "how does VIAL bind SemanticIR to the HIAL bridge?"
  - "what is the VIAL execution profile?"
  - "how are VIAL drive sample react check phases ordered?"
  - "how are VIAL fiber ties and cancellations deterministic?"
  - "how does VIAL random replay work?"
  - "what random algorithm does VIAL use?"
  - "are random values chosen separately by each VIAL backend?"
  - "what is fsmgen.vial_plan.v1?"
  - "what is fsmgen.verification_result_manifest.v1?"
  - "how does VIAL compare SV UVM and VHDL result parity?"
  - "what is a VIAL native extension manifest?"
  - "does VIAL reuse the Perl extension callback mechanism?"
  - "do UVM phases and objections appear in VIALExecutionIR?"
  - "what owns VIAL execution implementation next?"
  - "is VIAL execution implementation currently blocked?"
date: 2026-07-31
status: current
tags: [vial, execution-ir, logical-time, binding, determinism, random, replay, native-extension, plan, result, parity]
evidence: docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/VIAL_PUBLIC_TOOLING_V1_CONTRACT.md; docs/VIAL_PORTABLE_SYSTEMVERILOG_BACKEND_V1_CONTRACT.md; docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md; docs/decisions/0037-vial-semantic-types-bind-to-hial-carriers-through-directional-proof-relations.md; docs/decisions/0039-vial-public-tooling-is-intent-oriented-and-artifact-atomic.md; docs/decisions/0043-vial-portable-systemverilog-is-a-deterministic-known-value-profile.md; perl/FSM/VIAL/ExecutionBuilder.pm; perl/FSM/VIAL/ExecutionIR.pm; perl/FSM/VIAL/ExecutionRandom.pm; perl/FSM/VIAL/ExecutionReport.pm; perl/FSM/Support/VIALExecutionContract.pm; t/1552-vial-execution-ir.t; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; docs/book/src/16d-hial-vial-verification-architecture.md; ROADMAP_V2.md
reverify: prove -Iperl t/1550-vial-semantic-ir.t t/1551-hial-vial-bridge-manifest.t t/1552-vial-execution-ir.t t/297-capability-manifest.t && rg -n 'fsmgen\.vial_execution_ir\.v1|core_directed_single_clock_execution_v1|sha256_counter_rejection_v1|bit_domain_identity_v1|known_value_injection_v1|enum_encoding_injection_v1|shipped_private_target_neutral_no_backend' perl/FSM/VIAL/ExecutionBuilder.pm perl/FSM/VIAL/ExecutionIR.pm perl/FSM/VIAL/ExecutionRandom.pm perl/FSM/VIAL/ExecutionReport.pm perl/FSM/Support/VIALExecutionContract.pm
---

Decision `0036` selects private immutable
`fsmgen.vial_execution_ir.v1` / `core_directed_single_clock_execution_v1`.
It binds exact SemanticIR IDs/types/access to the review-routed bridge and
builds a target-neutral operational graph. SV/UVM/VHDL scheduling and
methodology plumbing remain backend implementation choices.

Portable time is `(domain, cycle, phase, ordinal)` with exact
drive/sample/react/check order and stable operation/fiber/emission tie ranks.
Actions, temporal evaluators, model/scoreboard/coverage/fault updates,
join-any winners, cancellation, timeout, and completion therefore do not
depend on host threads, simulator regions, callbacks, or delta cycles.

Random choices are resolved once during elaboration through the keyed arbitrary-
width `sha256_counter_rejection_v1` algorithm. Every backend receives the same
normalized value. Strict `fsmgen.vial_replay.v1` input rejects missing, extra,
wrong-type, out-of-range, or constraint-breaking occurrences.

Native implementations use declarative, repository-relative,
content-addressed `fsmgen.vial_native_extension.v1` manifests with logical
lifecycle hooks, typed I/O, closed deterministic effects, capabilities, and
required/paired/fallback policy. They are not Perl callback objects, UVM phase
hooks, or anonymous target blocks. The first checked AHB plan has no native
extension and retains its probe-adapter requirement explicitly.

Sanitized `fsmgen.vial_plan.v1` reports binding/schedule/capability/replay
facts. `.7.3` now ships the private immutable builder/IR/random/report family,
strict defensive plan construction, all ten checked AHB directional proofs,
resolved event/adapter bindings, one scenario-scoped decision occurrence,
exact resource accounting, atomic diagnostics, and private capability
discovery. Result-manifest and parity-report schemas are selected future
contracts with explicit `.10`/`.11` implementation owners; neither is
advertised as a satisfied `.7.3` capability. It writes no file and exposes no
supported public CLI/API. Runtime backends later produce
`fsmgen.verification_result_manifest.v1`; parity compares only canonical
portable/paired-native logical outcomes through a deep-validated parity
projection/report. Audit `.7.1` proved that the checked transaction could not
satisfy the former exact VIAL/HIAL field-type rule. Director-approved decision
`0037` and `.7.2` selected closed directional identity, known-value injection,
and enum-encoding proof records; `.7.3` implements them. Clean implementation
commit `44dbecd1a` permitted `.8` to select public plan placement under
decision `0039`. The public API returns only the sanitized plan, never
ExecutionIR. Decision `0043` now selects the first known-value plain-
SystemVerilog backend contract. Completed `.10.1` now ships only the public
source-tooling boundary; plan/result files, generated backends, compile,
simulation, runtime, and parity remain unshipped. Clean `.10.1` implementation
commit `50a0d7d39` activates `.10.2` for planning/artifacts without behavior;
active parent `.10` retains the later children and `.11` retains parity.
See
`docs/VIAL_HIAL_TYPE_BINDING_MISMATCH_AUDIT.md`.
