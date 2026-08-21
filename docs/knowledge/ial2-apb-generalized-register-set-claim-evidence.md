---
id: ial2-apb-generalized-register-set-claim-evidence
title: APB generalized register-set claims retain width, stride, count, and policy evidence
answers:
  - "how are APB generalized register-set claims verified?"
  - "which generalized APB two-peripheral measurements are current behavior?"
  - "how are APB register count and adjacent excess boundaries proved?"
  - "why are generalized APB headings and contract numerals reviewed separately?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, apb, generalized-register-set, cardinality, protection, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm;
  perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_five_register_status_back_to_back.ppif;
  t/1470-ial2-apb-profile-alias.t;
  t/1472-ial2-apb-composition.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report && prove -Iperl
  t/1638-claim-verification-dispositions.t
  t/1470-ial2-apb-profile-alias.t
  t/1472-ial2-apb-composition.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.5` reviews the exact 37 inventory
candidates on `docs/book/src/14h-protocol-profiles-and-apb.md` lines
1700-1999. Fourteen current behavior candidates use derived gates. The other
23 candidates are headings or immutable readiness, selector, contract, and
guard-history inputs, so they use reviewed-incidental dispositions rather
than being counted again as runtime proof.

The derived candidates remain separated into six evidence families:

- the selected 32-bit protected two-peripheral `reg0`/`reg1` composition;
- 32-bit no-policy generalized two-to-four-register composition;
- data16 no-policy generalized two-to-four-register composition;
- 32-bit protected generalized two-to-four-register composition;
- data16 protected generalized two-to-four-register composition; and
- the 32-bit no-policy two-to-five-register widening.

Each family is rederived from the ordinary completer/composition predicates
and its exact public `.ppif`/`.apb` pair. The composition oracle distinguishes
16- versus 32-bit data, two- versus four-byte stride, status/control windows,
matching register arrays on both peripherals, source order, reset values,
byte-lane masks, no-policy versus protected storage, `reg0` versus `regN`
access policy, peripheral-owned enforcement, queue behavior, generated
storage/read/write artifacts, and support identities. Too-few, mismatched,
adjacent-excess-five or adjacent-excess-six, wrong-policy, wrong-address, and
wrong-width controls prevent an aggregate count or width from standing in for
the actual accepted family.

The reviewed chronology remains attached to exact records at commits
`c1ac86b48624cd55d785a3de36dbf757105c5039` (`.654`),
`c1137c429a688bee914616cb652246aa573372a6` (`.655`),
`fa29977c468a3036e4ca51373f1497a233f5a3b7` (`.657`),
`80f0c9fed52fe045e4b7958579856fa1e3bcfa65` (`.658`),
`e95f83b39bc12e1a33d297733b287a0ccd1bb686` (`.659`),
`c031a6dca119b9f56e4375e8683e3b23551f1423` (`.661`),
`b9b301203915d440016f85356df355132f6d92b4` (`.663`),
`68d10dfba74c602a00978e59d62dfebdfcd26261` (`.664`),
`1f27bc585166fc496835dc3ba3a7c0106097b925` (`.666`),
`420db066b641f3dd75055a51eb16c99d18b5eb4c` (`.667`),
`b5903a73cd56613e31bad029bb0198e9156d59df` (`.669`),
`288582ec4eb7a55e02de3d957e9ac5cc2bb63b30` (`.670`), and
`8d115617b80c9608ced9367069d743d33195b946` (`.671`). Four candidate lines
are section headings whose numerals are navigation, not independent
capability claims. Current public fixtures and regressions separately prove
the behavior that followed those selections.
