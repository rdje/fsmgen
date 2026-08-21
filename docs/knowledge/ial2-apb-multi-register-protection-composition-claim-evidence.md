---
id: ial2-apb-multi-register-protection-composition-claim-evidence
title: APB multi-register, protection, and composition claims retain family-specific evidence
answers:
  - "how are APB multi-register protection and composition claims verified?"
  - "which Chapter 14h APB claims are current generated behavior rather than selection history?"
  - "how are 16-bit and 32-bit APB multi-peripheral measurements kept separate?"
  - "why are APB readiness and contract numerals reviewed instead of derived twice?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, apb, multi-register, protection, composition, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/ApbRequesterTransfer.pm;
  perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm;
  perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm;
  ppif/apb_completer_multi_register_sideband_back_to_back.ppif;
  ppif/apb_completer_multi_register_sideband_data16_back_to_back.ppif;
  ppif/apb_completer_multi_register_sideband_protection_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_sideband_data16_protection_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_sideband_protection_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_status_back_to_back.ppif;
  t/1470-ial2-apb-profile-alias.t;
  t/1471-ial2-apb-completer.t;
  t/1472-ial2-apb-composition.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report && prove -Iperl
  t/1638-claim-verification-dispositions.t
  t/1470-ial2-apb-profile-alias.t
  t/1471-ial2-apb-completer.t
  t/1472-ial2-apb-composition.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.4` reviews the exact 46 inventory
candidates on `docs/book/src/14h-protocol-profiles-and-apb.md` lines
1200-1699. Seventeen current behavior candidates use derived gates. The other
29 candidates are immutable readiness, selector, or contract inputs and use
reviewed-incidental dispositions so the selected values are not counted a
second time as runtime proof.

The derived candidates remain separated into nine evidence families:

- fixed 32-bit no-policy multi-register completer/composition;
- fixed data16 requester/completer/composition;
- fixed 32-bit protected completer/composition;
- data16 protected status/control multi-peripheral composition;
- 32-bit protected status/control multi-peripheral composition;
- 32-bit no-policy multi-peripheral `reg0`/`reg1` composition;
- data16 no-policy multi-peripheral `reg0`/`reg1` composition;
- data16 protected multi-peripheral `reg0`/`reg1` composition; and
- the selected status/control protected-storage report-residue cleanup.

The ordinary requester, completer, and composition builders rederive each
family from its exact public fixture. The profile-alias, completer, and
composition oracles separately inspect queue capture and relaunch, overflow
rejection, adjacent setup, local register addresses, status/control window
decode, address translation, byte-lane masking, policy ownership, allowed and
denied accesses, unmapped completion, report residue, generated artifacts, and
`.ppif`/`.apb` parity. That separation prevents equal widths or counts in one
family from standing in for another family with a different register map,
window alignment, or protection policy.

The 29 reviewed candidates retain exact Git-backed chronology. Their durable
records span commits `fbd82b6172a304784db04fa3b9cf2cf9e2425899` (`.619`),
`da0c9489bcaf3f1f2a6b14fe925b6688df47c538` (`.620`),
`d81ef354421ccc28e154d09954ec0e1293d56b55` (`.621`),
`3923c4290d5c20c3d3fb1d48b9e20a45178388de` (`.623`),
`f7cb12913ffae904553233f9894153d529ba5e9d` (`.624`),
`4d1c31984e619ede9f5ae77c9ba3a6f89ebce1f9` (`.627`),
`86f2e9ae7767e203c887b3baf7d062a44c972652` (`.629`),
`f3b10c9ae685ebfee16a49742f7053c6d58ea25e` (`.630`),
`d19e338a18d85d184439903e86803e19fe1dbe33` (`.632`),
`ed369f5dd1129326c2b0e994226ff48cd9991d5b` (`.633`),
`e32191f37f35d85d63f117deff48f27302c608c9` (`.636`),
`9726a306362407fd95fc2b316d90c2db666f5b89` (`.637`),
`566656ee37647613856a3a590ae41d983efc1ad5` (`.639`),
`4045d2860a9b60445d70451a30342c0b33f0dbd3` (`.640`),
`ecedad38ee9b6ea781e51affc1dc34b37168bc93` (`.641`),
`b317ef89d7a358edf53627d8f3cc5c7084061f96` (`.643`),
`79553fecb0a4a797540c234d780a9c10dc991d5e` (`.644`),
`bb8f1ba26ba803dff7d728dec943c6cf5ee20663` (`.646`),
`79ed817fe579f06670b019db6d38c310f4553269` (`.648`),
`f94db8e2edb5e0b1bc9877c91533c5fde7f85093` (`.650`),
`bab845c747a49b1e342a47448f61ddc5ac34d815` (`.651`), and
`71a55c53005bf98837612145a32def25681724f4` (`.652`). The linked selection
documents preserve the exact source shape and decision boundary; later public
fixtures and focused regressions independently prove the behavior that
eventually shipped.
