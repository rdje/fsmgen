---
id: ial2-one-language-profiles-and-axi-mdbook-coverage-gap
title: IAL2 is one language with per-protocol profiles/aliases; AXI mdBook coverage lags the shipped surface
answers:
  - "is IAL2 one dialect or one per protocol (AXI/AHB/APB)?"
  - "what is the purpose/end goal of IAL2 protocol-platform intent?"
  - "are .axi/.ahb/.apb separate languages or profile aliases?"
  - "how does IAL2 lower to HDL?"
  - "does the mdBook document the AXI IAL2 surface thoroughly?"
  - "why does the IAL2 work feel like many disconnected slices?"
date: 2026-07-12
status: current
tags: [ial2, ppif, profile, alias, axi, ahb, apb, mdbook, coverage, architecture]
evidence: docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md; docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md; docs/decisions/0016-ppif-is-first-public-ial2-container.md; docs/decisions/0018-ial-contracts-are-backend-language-neutral.md; docs/tasks/IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.md; docs/book/src/16-ial2-protocol-platform-intent.md; docs/book/src/16a-ial2-axi.md; docs/book/src/16c-ial2-ahb.md; perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm; ppif/ahb_requester.ppif
reverify: rg -n 'one architectural layer|profile|IAL2 -> IAL1|vocabulary/profile alias' docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md docs/decisions/0016-ppif-is-first-public-ial2-container.md; ls ppif/axi_*.ppif | wc -l; wc -l docs/book/src/16a-ial2-axi.md docs/book/src/16c-ial2-ahb.md
---

**One language, not three dialects.** IAL2 is a single protocol/platform-intent
architectural layer (decision `0015`: "IAL2 remains one architectural layer"),
protocol/platform-generic across AXI, CHI, ACE, AHB, APB, ATB, and future
protocols (`0014`). The one generic file container is `.ppif` (Protocol/Platform
Intent Format, `0016`); a `.ppif` file selects a protocol **vocabulary** via a
`(profile …)` clause. Each protocol contributes its own vocabulary within that
one language — AXI `(manager-capacity-status …)`/`(valid-ready-channel …)`, AHB
`(ahb-requester …)`/`(ahb-subordinate …)`/`(ahb-interconnect …)`, APB
`(apb-completer …)`/composition. The `.axi`/`.ahb`/`.apb` file suffixes are
**optional profile aliases**, not separate layers (`0015`: "not separate language
layers, do not get special direct-lowering privileges, must not fragment the
compiler architecture"); the shipped alias files are byte-identical mirrors of
the generic `.ppif` sources. Everything lowers through one mandatory chain
(`0014`): `IAL2 → IAL1/.isf → IAL0/.fsm → HDL` (direct IAL2 → IAL0 is forbidden).
The IAL layers + mdBook are backend-language-neutral contracts (`0018`).

**Purpose:** express protocol/platform *intent* ("an AHB requester issuing
bursts", "an AXI manager tracking outstanding-transaction capacity and demuxing
responses", "an APB completer with these registers") and lower it to synthesizable
HDL through the shared, reviewable IAL1/IAL0 pipeline. Adding a new protocol =
adding a vocabulary/profile + generator, not a new language.

**Documentation gap (tracked by proposed `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE`):**
the mdBook chapters are inversely proportional to what they document. AHB (16
`.ppif` + 16 `.ahb`) has a ~1,834-line thorough chapter (`16c`) referencing all
32 sources; AXI (142 `.ppif`, one ~9,773-line generator, 140 sources → one
`axi0_capacity_status` module) has a ~190-line `16a` referencing ~4% of the
surface, with whole shipped feature classes (mixed dynamic/static, write-BID/read-RID
response-demux, same-ID issue-order queues, dynamic-ID capture, read-data,
ARLEN/RLAST validation, multi-beat banks, cardinalities) unmentioned; `13k` carries
no AXI content. The AXI thread is a coherent-but-partial spine (a capacity/status +
response-demux + read-data-capture core that self-labels a "capacity-status-shell",
not yet a bus-driving initiator). This is why the IAL2 work can read as many
disconnected slices: the coherent whole is real in code but under-documented.
