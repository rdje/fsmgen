---
id: ial2-apb-multi-peripheral-interconnect-behavior
title: APB multi-peripheral interconnect/decode ships for generated composition sources
answers:
  - "what is IAL2-FEATURE-COMPLETENESS-FRONTIER.585?"
  - "does FSMGen support APB multi-peripheral interconnect/decode?"
  - "which APB multi-peripheral samples are shipped?"
  - "what generated APB interconnect artifacts exist?"
  - "how does APB multi-peripheral decode handle unmapped addresses?"
  - "why does the generated APB top use status_peripheral?"
  - "what APB multi-peripheral residue remains?"
date: 2026-06-27
status: current
tags: [ial2, ial1, apb, interconnect, multi-peripheral, decode, composition, ppif, profile-alias, task-tree]
evidence: docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_BEHAVIOR.md; docs/IAL2_APB_MULTI_PERIPHERAL_INTERCONNECT_CONTRACT_SELECTION.md; ppif/apb_composition_multi_peripheral.ppif; ppif/apb_composition_multi_peripheral.apb; perl/FSM/Adapter/IAL2/PPIF.pm; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/Support/LanguageSurfaceSection.pm; t/1470-ial2-apb-profile-alias.t; t/1472-ial2-apb-composition.t; t/248-regression-corpus-accounting.t; t/297-capability-manifest.t; docs/REGRESSION_CORPUS.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/TASK_TREE.md; MEMORY.md; README.md; ROADMAP_V2.md; docs/book/src/14-feature-backlog.md
reverify: ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral.ppif && ./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral.ppif && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_multi_peripheral.ppif && ./bin/fsmgen --quiet --emit-schedule-json ppif/apb_composition_multi_peripheral.apb && ./bin/fsmgen --quiet --strict --check --json ppif/apb_composition_multi_peripheral.apb && ./bin/fsmgen --quiet --strict --emit-semantic-json ppif/apb_composition_multi_peripheral.apb && prove -Iperl t/1470-ial2-apb-profile-alias.t t/1472-ial2-apb-composition.t t/248-regression-corpus-accounting.t t/297-capability-manifest.t
---

`IAL2-FEATURE-COMPLETENESS-FRONTIER.585` ships bounded APB multi-peripheral
interconnect/decode for generated APB composition sources.

The shipped public samples are
`ppif/apb_composition_multi_peripheral.ppif` and
`ppif/apb_composition_multi_peripheral.apb`. They use one requester, two APB
completer peripherals, static non-overlapping address windows, overlap
rejection, source-order deterministic decode, and unmapped-address error
response.

Generated artifacts include `apb_interconnect.isf` and
`apb_interconnect.fsm` alongside requester/peripheral endpoint artifacts and
the generated `apb_tb.fsm` top. The interconnect fans out decoded `PSEL`,
translates local `PADDR` by subtracting the selected window base, muxes
selected responses, and returns `PREADY=1`, `PRDATA=0`, `PSLVERR=1` for an
active unmapped access.

The generated top uses deterministic collision-free child instance names. The
authored `status` peripheral in the shipped sample collides with the public
requester `status` output, so the generated top uses `status_peripheral`;
reports preserve both `instance_name` and `generated_instance_name`.

The multi-peripheral composition report removes
`apb_interconnect_multi_peripheral_decode_deferred`. `.609` later ships the
selected 32-bit no-sideband multi-peripheral status back-to-back timing-policy
family while preserving the same propagation-only interconnect shape.
Sideband/strobe, alternate-width, protection, broader back-to-back policy,
direct backend, verification-output, backend-language variants, AXI/AHB
interconnects, and VHDL remain deferred.
