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
date: 2026-07-31
status: current
tags: [vial, execution-ir, logical-time, binding, determinism, random, replay, native-extension, plan, result, parity]
evidence: docs/VIAL_EXECUTION_IR_V1_CONTRACT.md; docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md; docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md; docs/VIAL_SOURCE_AND_SEMANTIC_IR_V1_CONTRACT.md; docs/HIAL_VIAL_BRIDGE_MANIFEST_V1_CONTRACT.md; docs/book/src/16d-hial-vial-verification-architecture.md; ROADMAP_V2.md
reverify: rg -n 'fsmgen\.vial_execution_ir\.v1|core_directed_single_clock_execution_v1|domain.*cycle.*phase.*ordinal|sha256_counter_rejection_v1|fsmgen\.vial_native_extension\.v1|fsmgen\.vial_plan\.v1|fsmgen\.verification_result_manifest\.v1|fsmgen\.vial_parity_report\.v1|Active `.7`|eaf3f95dc' docs/VIAL_EXECUTION_IR_V1_CONTRACT.md docs/decisions/0036-vial-execution-is-deterministic-logical-time-above-backend-methodology.md docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md docs/book/src/16d-hial-vial-verification-architecture.md ROADMAP_V2.md
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
facts. Runtime backends later produce
`fsmgen.verification_result_manifest.v1`; parity compares only canonical
portable/paired-native logical outcomes through a deep-validated parity
projection/report. Clean selection commit `eaf3f95dc` permits active `.7` to
own private no-backend implementation after separate continuity activation;
implementation remains unperformed and activation changes no product behavior.
