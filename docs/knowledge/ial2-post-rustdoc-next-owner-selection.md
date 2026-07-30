---
id: ial2-post-rustdoc-next-owner-selection
title: Generated HDL instance-identifier audit follows the mdBook rustdoc repair
answers:
  - "what does IAL2-FEATURE-COMPLETENESS-FRONTIER.838 select?"
  - "what follows the completed mdBook rustdoc fence repair?"
  - "why is the protocol-composition instance-identifier audit selected?"
  - "does APB still emit interconnect as a SystemVerilog instance name?"
  - "why does APB multi-peripheral HDL verification fail at interconnect?"
  - "does the post-rustdoc selector activate the four-document lifecycle review?"
date: 2026-07-30
status: current
tags: [ial2, selector, hdl, identifier, systemverilog, apb, ahb]
evidence: docs/IAL2_POST_RUSTDOC_NEXT_OWNER_SELECTION.md; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md; docs/tasks/PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.md; perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm; perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm; ppif/apb_composition_multi_peripheral.ppif
reverify: scratch=.artifacts/tmp/apb-instance-identifier-reverify; trap 'rm -rf "$scratch"' EXIT; mkdir -p "$scratch"; ./bin/fsmgen --strict --verify-hdl --output "$scratch/apb_multi.sv" ppif/apb_composition_multi_peripheral.ppif
---

Parent selector `.838` chooses proposed
`PROTOCOL-COMPOSITION-HDL-INSTANCE-IDENTIFIER-AUDIT.1`. Current HEAD still
seeds the APB generated interconnect-role instance as `interconnect`, while AHB
uses legal `fabric`; both local uniqueness helpers avoid declared-name
collisions but do not check target-language reserved words.

Strict HDL verification of public
`ppif/apb_composition_multi_peripheral.ppif` emits
`apb_interconnect interconnect (`. Verilator rejects that generated instance
token as the SystemVerilog keyword `interconnect`. The exact repository-local
probe output was removed after inspection.

The selected child is a no-behavior inventory/probe audit across composition
producers and target languages. It must select a shared diagnostic or stable
rename/sanitization contract before any implementation change, so FSMGen does
not accumulate protocol-specific keyword workarounds.

The scheduled four-document lifecycle review stays proposed under interim
decision `0025`; both legacy status files remain untouched. Explicitly
director-gated directions remain inactive.

Clean selector commit `b0bcb12b5` activates only the selected identifier audit
continuity-only. Source producers, reports, generated HDL, and target behavior
remain unchanged during activation.
