---
id: ial2-apb-width-sideband-timing-claim-evidence
title: APB width sideband protection and timing claims retain separate current and historical evidence
answers:
  - "how are APB data16 and remaining-width claims verified?"
  - "how are APB 32-bit and data16 protection claims verified?"
  - "how are APB depth-1 back-to-back and sideband queue claims verified?"
  - "which APB width and timing numerals are historical readiness or contract selections?"
date: 2026-08-21
status: current
tags: [ial2, apb, claim-verification, data16, sideband, protection, timing]
evidence: >-
  perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm;
  perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm;
  perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm;
  ppif/apb_completer_multi_register_sideband_data16.ppif;
  ppif/apb_completer_multi_register_sideband_protection.ppif;
  ppif/apb_completer_multi_register_sideband_data16_protection.ppif;
  ppif/apb_composition_multi_peripheral_status_back_to_back.ppif;
  ppif/apb_requester_transfer_sideband_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_sideband_status_back_to_back.ppif;
  t/1470-ial2-apb-profile-alias.t;
  t/1471-ial2-apb-completer.t;
  t/1472-ial2-apb-composition.t;
  doctrine/claim_verification/dispositions.jsonl;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  scripts/run_with_ram_guard.sh -- prove -Iperl
  t/1470-ial2-apb-profile-alias.t
  t/1471-ial2-apb-completer.t
  t/1472-ial2-apb-composition.t
---

Current APB width, protection, and timing claims use the ordinary requester,
completer, and composition producers. The selected fixtures and focused
oracles derive 16-bit data and two strobe lanes, preserve the 16/32-bit
boundary, enforce register-local protection, queue one accepted request,
capture and relaunch `PPROT/PSTRB`, admit adjacent setup, and propagate queued
setup through fixed and two-peripheral compositions. The same oracles inspect
reports, aliases, IAL1, IAL0, HDL, and rejecting boundary cases.

Earlier readiness, selector, and contract-selection numerals remain durable
chronology rather than independent current capability evidence. In particular,
pre-data16 hard-coded width guards, selected family sizes, and temporary
32-bit-only timing or protection guards are preserved through their exact Git
records. Later shipped behavior is verified separately, so those historical
inputs are not double-counted as runtime measurements.
