---
id: ial2-non-axi-profile-alias-taxonomy-evidence-prerequisite
title: Non-AXI alias taxonomy separates generic containers from protocol aliases
answers:
  - "what did IAL2-FEATURE-COMPLETENESS-FRONTIER.546 classify?"
  - "are .pif and .ppi protocol aliases?"
  - "which non-AXI suffix candidates are protocol-profile aliases?"
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.547?"
date: 2026-06-26
status: current
tags: [ial2, profile-alias, non-axi, taxonomy, pif, ppi]
evidence: docs/IAL2_NON_AXI_PROFILE_ALIAS_TAXONOMY_EVIDENCE_PREREQUISITE.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0017-ppif-valid-ready-bundle-contract.md; bin/fsmgen; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/Support/LanguageSurfaceSection.pm; perl/FSM/Support/RegressionCorpus.pm; ppif/valid_ready_handshake.ppif; ppif/valid_ready_dual_channel_bundle.ppif; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: rg -n 'IAL2-FEATURE-COMPLETENESS-FRONTIER\\.546|IAL2-FEATURE-COMPLETENESS-FRONTIER\\.547|generic-container alias policy|not protocol profile aliases|protocol-profile alias candidates|Proves IAL2 is not AXI-only|must not accept' docs/IAL2_NON_AXI_PROFILE_ALIAS_TAXONOMY_EVIDENCE_PREREQUISITE.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md docs/TASK_TREE.md MEMORY.md README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md bin/fsmgen perl/FSM/Adapter/IAL2/PPIF.pm perl/FSM/Support/LanguageSurfaceSection.pm perl/FSM/Support/RegressionCorpus.pm
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.546` classifies `.pif` and `.ppi` as
generic-container spelling candidates, not protocol-profile aliases. `.chi`,
`.ace`, `.ahb`, `.apb`, `.atb`, `.smbus`, and `.i2s` remain unsupported
protocol-profile alias candidates and are not ready for contract selection.

The taxonomy records that `(profile valid-ready)` under `.ppif` is real
protocol-neutral/non-AXI IAL2 evidence. It proves IAL2 is not AXI-only, but it
does not define a protocol suffix contract.

`.546` selects `.547`, a generic-container alias policy selector for `.pif`
and `.ppi`. `.547` must not accept a new suffix or change behavior.
