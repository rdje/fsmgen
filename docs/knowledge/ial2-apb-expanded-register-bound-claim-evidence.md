---
id: ial2-apb-expanded-register-bound-claim-evidence
title: APB expanded register-bound claims retain five/six-register boundary evidence
answers:
  - "how are APB five-register and six-register claims verified?"
  - "which expanded APB generalized register bounds are currently supported?"
  - "how are APB excess-six and excess-seven controls retained?"
  - "which protected APB six-register families remain deferred?"
date: 2026-08-21
status: current
tags: [claim-verification, ial2, apb, five-register, six-register, cardinality, protection, evidence]
evidence: >-
  doctrine/claim_verification/inventory.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  perl/FSM/IAL2/ProtocolIntent/ApbCompleter.pm;
  perl/FSM/IAL2/ProtocolIntent/ApbComposition.pm;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_five_register_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_protection_generalized_five_register_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_protection_generalized_five_register_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_generalized_six_register_status_back_to_back.ppif;
  ppif/apb_composition_multi_peripheral_multi_register_sideband_data16_generalized_six_register_status_back_to_back.ppif;
  t/1470-ial2-apb-profile-alias.t;
  t/1472-ial2-apb-composition.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report && prove -Iperl
  t/1638-claim-verification-dispositions.t
  t/1470-ial2-apb-profile-alias.t
  t/1472-ial2-apb-composition.t
---

`CLAIM-VERIFICATION-ADOPTION.5.4.6` reviews the exact 28 inventory
candidates on `docs/book/src/14h-protocol-profiles-and-apb.md` lines 2000 to
the end. Nine current behavior candidates use derived gates. The other 19
candidates are a section heading or immutable selector, readiness, contract,
and guard-history inputs and therefore use reviewed-incidental dispositions.

The derived candidates remain separated into five evidence families:

- data16 no-policy two-to-five-register composition;
- 32-bit protected two-to-five-register composition;
- data16 protected two-to-five-register composition;
- 32-bit no-policy two-to-six-register composition; and
- data16 no-policy two-to-six-register composition.

The exact `.ppif`/`.apb` pairs and ordinary completer/composition predicates
rederive each family. The composition oracle checks register order and local
addresses, 16/32-bit data, two/four-byte stride and lane masks, windows,
queueing, no-policy versus protected storage, peripheral-owned enforcement,
`reg3/reg4/reg5` generated storage/read/write/byte-lane and denied branches,
support/capability identities, reports, artifacts, and profile-alias parity.
Counts two through five or two through six are accepted only in their selected
families; mismatched arrays, excess six before widening, excess seven after
widening, wrong policies, and protected six-register candidates remain
separating RED boundaries.

The reviewed chronology stays attached to commits
`b97bb1da53ae4458184290fadcbda2211b7529e5` (`.673`),
`3657a74871d1ebfffb017e39aaff995d27887aa0` (`.674`),
`2a622535a278e19e4cb49699e590ea1380f5053f` (`.676`),
`79a0e696a320629ed5b5890361753642ae93e0a9` (`.677`),
`08bbbc98be938ea29dcdb019902574e250a7d442` (`.679`),
`18fe486a94234da1b93d6318651c354a9b93e4c6` (`.680`),
`218ab9d618207dd45d43ebfd87c3bc69a17d9e37` (`.682`),
`4472f9d25b93bd54622c0a0d84b2a6688c2d3de5` (`.683`),
`2c40f767260607115456fa340ee57611f54c70b9` (`.684`),
`8d9d4a7fa9fb67c07b34372a6f9fac791b84dada` (`.686`), and
`96d6a812b04b3685ecaebd8bff976731b34eb659` (`.687`). The candidate line
containing “32-bit” in the post-selector heading is navigation, not an
independent measurement. Current fixtures and focused regressions separately
prove the behavior that followed those selections.
