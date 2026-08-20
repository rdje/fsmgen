---
id: ial2-apb-foundational-claim-evidence
title: Foundational APB claim evidence separates generated behavior from contract numerals
answers:
  - "how are foundational APB completer and multi-register claims verified?"
  - "what proves APB 16-bit data 3-bit protection and 2-bit strobe behavior?"
  - "what proves APB queue depth 1 and overflow reject behavior?"
  - "which APB status register and sideband numerals are contract selections?"
date: 2026-08-21
status: current
tags: [ial2, apb, claim-verification, completer, composition]
evidence: >-
  perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm;
  perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm;
  perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm;
  ppif/apb_completer.ppif;
  ppif/apb_completer_multi_register.ppif;
  ppif/apb_composition_multi_register_sideband_data16_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif;
  t/1471-ial2-apb-completer.t;
  t/1472-ial2-apb-composition.t;
  doctrine/claim_verification/dispositions.jsonl;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report &&
  prove -Iperl t/1471-ial2-apb-completer.t
  t/1472-ial2-apb-composition.t
---

Foundational APB behavior claims use three ordinary generated producers. The
requester owns sampled requests, queue depth, overflow rejection, bus widths,
and sideband drive. The completer owns wait timing, source-ordered register
decode, mapped reads/writes, byte-lane masking, and unmapped errors. The
composition producer owns endpoint wiring, APB-specific interconnect routing,
and the combined review-artifact/report surface. Focused endpoint and
composition suites exercise the matching `.ppif`/`.apb`, report, IAL1, IAL0,
HDL, and rejecting-control paths.

The claim-disposition review therefore treats current base-completer,
multi-register, data16, `PPROT`/`PSTRB`, and queued back-to-back statements as
derived gates. Numerals inside earlier status-field, multi-register, and
sideband contract-selection records remain structural inputs to those later
implementations. They are preserved as selection history and are not counted
again as independent runtime measurements.
