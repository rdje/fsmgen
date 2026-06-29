---
id: ial2-ahb-current-boundary-mdbook-coverage
title: AHB mdBook coverage documents bounded PPIF plus direct FSM coverage
answers:
  - "where is the AHB current-boundary mdBook chapter?"
  - "is AHB IAL2 shipped?"
  - "is .ahb accepted by fsmgen?"
  - "what AHB support exists today?"
  - "what must happen before AHB guided more-control or raw full-control IAL2 modes ship?"
date: 2026-06-29
status: current
tags: [ial2, ahb, amba, mdbook, protocol-intent, profile-alias, documentation]
evidence: docs/book/src/16c-ial2-ahb.md; docs/book/src/16-ial2-protocol-platform-intent.md; ppif/ahb_requester.ppif; fsm/amba_requester.fsm; perl/FSM/Support/RegressionCorpus.pm; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; bin/fsmgen; docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md
reverify: rg -n 'AHB IAL2 Current Boundary|ppif/ahb_requester\.ppif|intent\.ppif_ahb_requester|protocol\.amba_requester|source_kind.*ppif|source_kind.*fsm|source suffix.*\.ahb.*known IAL2 alias candidate|16c-ial2-ahb' docs/book/src/16c-ial2-ahb.md docs/book/src/16-ial2-protocol-platform-intent.md docs/book/src/SUMMARY.md docs/tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md perl/FSM/Support/RegressionCorpus.pm ppif/ahb_requester.ppif fsm/amba_requester.fsm
---

`docs/book/src/16c-ial2-ahb.md` is the user-facing AHB current-boundary
chapter under the IAL2 protocol/platform intent mdBook section.

The chapter now documents two AHB surfaces: bounded requester IAL2 coverage via
`ppif/ahb_requester.ppif`, support-accounted as `intent.ppif_ahb_requester`
with `source_kind` `ppif`, and the older direct `.fsm` coverage at
`fsm/amba_requester.fsm`, support-accounted as `protocol.amba_requester` with
`source_kind` `fsm`.

AHB IAL2 is shipped only for the bounded generic `.ppif` requester. The `.ppif`
path lowers through generated `amba_requester.isf` before generated
`amba_requester.fsm`; `.ahb` remains a known unsupported IAL2 alias candidate.

Future `.ahb` profile aliases, AHB completers/subordinates,
interconnect/decode, scoreboards, full-manager behavior, direct backend,
verification-output generation, backend-language variants, and VHDL remain
task-tree-owned residue.
