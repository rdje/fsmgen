---
id: ial2-apb-pprot-effects-behavior
title: APB PPROT access-policy behavior ships register-local privileged enforcement
answers:
  - "does APB PPROT enforce access control now?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.597?"
  - "how does APB access-policy behave?"
  - "what APB PPROT policy samples are supported?"
  - "who enforces APB PPROT policies in composition?"
date: 2026-06-27
status: current
tags: [ial2, apb, pprot, protection, access-policy, behavior, task-tree]
evidence: >-
  docs/IAL2_APB_PPROT_EFFECTS_BEHAVIOR.md; docs/IAL2_APB_PPROT_EFFECTS_CONTRACT_SELECTION.md; ppif/apb_completer_multi_register_sideband_protection.ppif; ppif/apb_completer_multi_register_sideband_protection.apb; ppif/apb_composition_multi_register_sideband_protection.ppif; ppif/apb_composition_multi_register_sideband_protection.apb; ppif/apb_composition_multi_peripheral_sideband_protection.ppif; ppif/apb_composition_multi_peripheral_sideband_protection.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t;
  t/297-capability-manifest.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband_protection.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband_protection.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral_sideband_protection.ppif && prove -Iperl t/1470-ial2-apb-profile-alias.t t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.597` ships the first APB `PPROT`
access-control effects behavior. The supported policy syntax is register-local
`(access-policy ...)` inside sideband-aware 32-bit APB completer storage
registers, with `read` and `write` clauses that either `allow` or `require
(privileged 0|1)`.

The FSMGen-local `privileged` predicate is sampled `PPROT[0] == VALUE`.
Completers evaluate the selected register policy after address decode at the
normal APB response point.

Allowed mapped reads and writes keep the sideband-aware behavior, including
`PSTRB` byte-lane writes and successful no-byte writes when `PSTRB=0`.
Denied mapped accesses complete with `PREADY=1` and `PSLVERR=1`; denied reads
drive `PRDATA=0`, and denied writes are side-effect-free even when `PSTRB=0`.
Unmapped accesses remain owned by the existing unmapped-address error policy.

Fixed and multi-peripheral composition do not enforce policies in this first
slice. They propagate `PPROT/PSTRB`, mux selected responses, and report that
selected completers or peripheral completers own enforcement.

Selected protection reports add `protection_policy` metadata and replace
`apb_protection_policy_effects_deferred` with
`apb_additional_protection_policies_deferred`. Existing sideband-aware samples
without `access-policy`, including data16 samples, keep their previous residue.
