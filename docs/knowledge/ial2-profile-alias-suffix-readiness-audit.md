---
id: ial2-profile-alias-suffix-readiness-audit
title: IAL2 profile-alias suffixes need public inventory sync before implementation
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.537 find?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.538?"
  - "could FSMGen accept .axi files before .540?"
  - "are IAL2 profile aliases ready to implement?"
  - "which IAL2 profile-alias suffixes need inventory sync?"
date: 2026-06-26
status: historical
tags: [ial2, ppif, profile-alias, suffix, readiness-audit]
evidence: docs/IAL2_PROFILE_ALIAS_SUFFIX_READINESS_AUDIT.md; docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md; docs/IAL2_POST_NEUTRAL_VALID_READY_BUNDLE_NEXT_SLICE_SELECTION.md; docs/IAL2_PROTOCOL_NEUTRAL_VALID_READY_BUNDLE_BEHAVIOR.md; docs/IAL2_PROTOCOL_GENERALITY_GUARDRAIL_PUBLIC_SURFACE_SYNC.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/297-capability-manifest.t; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.537|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.538|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.540|unsupported_first_slice_aliases|\\.axi|\\.chi|\\.ace|\\.ahb|\\.apb|\\.atb|\\.smbus|\\.i2s|AXI remains only the first profile-alias example' docs/IAL2_PROFILE_ALIAS_SUFFIX_READINESS_AUDIT.md docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md docs/knowledge/ial2-profile-alias-suffix-readiness-audit.md
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.537` found that profile-alias suffixes are
architecturally allowed but not ready for implementation until the public
unsupported-alias inventory is synchronized.

At `.537`, FSMGen did not accept `.axi` or other profile-alias files. `.540`
later shipped the first bounded `.axi` alias for the AXI AW Valid-Ready sample.
All other profile-alias candidates from this audit remain unsupported until a
future exact owner selects them.
