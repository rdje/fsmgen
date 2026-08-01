---
id: ial2-apb-protection-back-to-back-behavior
title: APB sideband protection back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.628?"
  - "which APB protection back-to-back samples ship?"
  - "does APB adjacent setup support protected two-register completers?"
  - "does fixed APB composition propagate protected back-to-back timing?"
  - "what APB back-to-back variants remain deferred after .628?"
date: 2026-06-28
status: current
tags: [ial2, apb, protection, pprot, sideband, completer, composition, back-to-back, behavior, task-tree]
evidence: >-
  docs/IAL2_APB_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_completer_multi_register_sideband_protection_back_to_back.ppif; ppif/apb_completer_multi_register_sideband_protection_back_to_back.apb; ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.ppif; ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md;
  ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband_protection_back_to_back.ppif | rg '"setup_admission"|"protection_policy"|"reg0"|"reg1"|"apb_additional_back_to_back_policies_deferred"'; ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.ppif | rg '"back_to_back_policy"|"protection_policy"|"accepted"|"status"|"apb_additional_protection_policies_deferred"'; prove -Iperl t/1470-ial2-apb-profile-alias.t t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.628` ships the bounded APB
sideband-aware protection back-to-back timing-policy family selected by
`.627`.

The shipped public sources are:

- `ppif/apb_completer_multi_register_sideband_protection_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_protection_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_protection_status_back_to_back.apb`

The selected standalone completer is 32-bit, sideband-aware, has `PPROT width
3`, `PSTRB width 4`, and exactly two protected registers. `reg0` is at byte
address `0` with read allow/write privileged-1. `reg1` is at byte address `4`
with read/write privileged-1. Adjacent setup admission samples
`PPROT/PSTRB/PWDATA` on every admitted setup phase while preserving allowed,
denied, zero-strobe, and unmapped access behavior.

The selected fixed composition combines the `.612` sideband requester
`accepted/busy/status` depth-1 queued timing policy with that protected
two-register completer. It propagates `PPROT/PSTRB/PWDATA`, exposes aggregate
`back_to_back_policy`, and leaves protection enforcement owned by the
completer.

Reports remove broad `apb_back_to_back_policy_deferred` for the four selected
surfaces and retain narrowed future timing, broader protection-policy,
remaining-width, and multi-peripheral decode residue.

Combined data16-protection timing, multi-peripheral multi-register timing,
deeper queues, alternate overflow, accepted-less requesters, multiple active
APB transfers, direct backend, verification-output, backend-language variants,
AXI, AHB, and VHDL remain deferred after `.628`.
