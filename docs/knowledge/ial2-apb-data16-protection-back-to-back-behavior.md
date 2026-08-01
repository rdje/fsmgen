---
id: ial2-apb-data16-protection-back-to-back-behavior
title: APB sideband data16 protection back-to-back behavior shipped
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.631?"
  - "which APB data16 protection back-to-back samples ship?"
  - "does APB adjacent setup support protected data16 two-register completers?"
  - "does fixed APB composition propagate protected data16 back-to-back timing?"
  - "what APB back-to-back variants remain deferred after .631?"
date: 2026-06-28
status: current
tags: [ial2, apb, data16, protection, pprot, sideband, completer, composition, back-to-back, behavior, task-tree]
evidence: >-
  docs/IAL2_APB_DATA16_PROTECTION_BACK_TO_BACK_BEHAVIOR.md; ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.ppif; ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.apb; ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif; ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.apb; perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1471-ial2-apb-completer.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md;
  README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.ppif | rg '"data_width"|"strobe_width"|"setup_admission"|"protection_policy"|"reg0"|"reg1"|"apb_additional_back_to_back_policies_deferred"'; ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif | rg '"back_to_back_policy"|"protection_policy"|"data_width"|"strobe_width"|"accepted"|"status"|"apb_additional_protection_policies_deferred"'; prove -Iperl t/1470-ial2-apb-profile-alias.t t/1471-ial2-apb-completer.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.631` ships the bounded APB
sideband-aware data16-protection back-to-back timing-policy family selected by
`.630`.

The shipped public sources are:

- `ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.ppif`
- `ppif/apb_completer_multi_register_sideband_data16_protection_back_to_back.apb`
- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.ppif`
- `ppif/apb_composition_multi_register_sideband_data16_protection_status_back_to_back.apb`

The selected standalone completer is sideband-aware, uses 32-bit `PADDR`,
16-bit `PWDATA/PRDATA/register` data, `PPROT width 3`, `PSTRB width 2`, and
exactly two protected registers. `reg0` is at byte address `0` with read
allow/write privileged-1. `reg1` is at byte address `2` with read/write
privileged-1. Adjacent setup admission samples `PPROT/PSTRB/PWDATA` on every
admitted setup phase while preserving allowed, denied, zero-strobe,
byte-lane, and unmapped access behavior.

The selected fixed composition combines the `.625` sideband data16 requester
`accepted/busy/status` depth-1 queued timing policy with that protected
data16 two-register completer. It propagates `PPROT/PSTRB/PWDATA`, exposes
aggregate `back_to_back_policy`, and leaves protection enforcement owned by
the completer.

Reports remove broad `apb_back_to_back_policy_deferred` for the four selected
surfaces and retain narrowed future timing, broader protection-policy,
remaining-width, and multi-peripheral decode residue.

Multi-peripheral data16-protection timing, broader multi-peripheral
multi-register timing, deeper queues, alternate overflow, accepted-less
requesters, multiple active APB transfers, direct backend, verification-output,
backend-language variants, AXI, AHB, and VHDL remain deferred after `.631`.
