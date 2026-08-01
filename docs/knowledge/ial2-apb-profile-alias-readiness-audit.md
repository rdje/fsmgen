---
id: ial2-apb-profile-alias-readiness-audit
title: APB .apb is ready for public profile-alias contract selection
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.552?"
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.552 select?"
  - "what changed in the APB .apb readiness audit?"
date: 2026-06-26
status: historical
tags: [ial2, apb, ppif, profile-alias, task-tree]
evidence: >-
  docs/IAL2_APB_PROFILE_ALIAS_READINESS_AUDIT.md; docs/IAL2_POST_APB_REQUESTER_TRANSFER_NEXT_SLICE_SELECTION.md; docs/IAL2_APB_PPIF_REQUESTER_TRANSFER_BEHAVIOR.md; docs/IAL2_APB_PPIF_SOURCE_SHAPE_CONTRACT_SELECTION.md; docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; docs/decisions/0018-ial-contracts-are-backend-language-neutral.md; ppif/apb_requester_transfer.ppif; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; t/1436-ial2-ppif-parser-cli.t; t/297-capability-manifest.t;
  docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: >-
  ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_requester_transfer.ppif && rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\.552|IAL2-FEATURE-COMPLETENESS-FRONTIER\.553|APB \.apb public profile-alias contract|known unsupported IAL2 alias candidate|source_kind => .ppif.|source_kind => .ial2_profile_alias.|unsupported_first_slice_aliases|must not accept \.apb' docs/IAL2_APB_PROFILE_ALIAS_READINESS_AUDIT.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/LanguageSurfaceSection.pm
  perl/FSM/Support/RegressionCorpus.pm t/1436-ial2-ppif-parser-cli.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.552` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.553`, APB `.apb` public profile-alias
contract selection.

The audit found that `ppif/apb_requester_transfer.ppif` now gives enough APB
IAL2 evidence to write the `.apb` alias contract: explicit `(profile apb)`,
one `(apb-requester apb_requester ...)` object, generated
`apb_requester.isf`, generated `apb_requester.fsm`, report schema
`fsmgen.ial2.protocol_intent.apb_requester_transfer.v1`, strict check JSON,
semantic JSON, and support accounting for
`intent.ppif_apb_requester_transfer`.

FSMGen did not accept `.apb` in `.552`. `.553` owned public alias contract
selection for explicit profile policy, authored `.apb` source-path identity,
support-accounting identity/source kind, manifest wording, diagnostics, and the
mandatory generated `.isf` review step before generated `.fsm`.

The `.552` slice changed only documentation and continuity surfaces. It also
fixed stale mdBook wording that still described `.axi` as unshipped; `.axi` is
shipped for the bounded AXI AW Valid-Ready profile-alias sample, while `.apb`
and the other non-AXI aliases remain unsupported.
