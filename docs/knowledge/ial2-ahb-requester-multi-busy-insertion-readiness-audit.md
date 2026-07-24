---
id: ial2-ahb-requester-multi-busy-insertion-readiness-audit
title: Multiple requester BUSY events are feasible, but shipped single cardinality must be repaired first
answers:
  - "is bounded multiple AHB requester BUSY insertion ready?"
  - "does the shipped AHB requester emit exactly one BUSY event?"
  - "how many ready-qualified BUSY clocks does busy-before-beat currently emit?"
  - "does AHB permit BUSY to change to SEQ while HREADY is low?"
  - "what does IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1 select?"
  - "how should multiple requester BUSY presentations be counted?"
date: 2026-07-24
status: current
tags: [ial2, ahb, requester, busy, htrans, hready, hgrant, cardinality, runtime, audit]
evidence: docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md; docs/vendor/arm/amba/ahb/IHI0033_C_2021-09_AMBA_5_AHB_Protocol_Specification.pdf; perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm; t/1498-ial2-ahb-requester-busy-insert.t; t/data/ahb_requester_busy_insert_tb.svt; t/1513-ial2-ahb-paired-busy-composition.t; docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
reverify: rg -n 'qualified BUSY edges|ten accepted|busy_remaining|BUSY-to-SEQ|IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT\.2' docs/IAL2_AHB_REQUESTER_MULTI_BUSY_INSERTION_READINESS_AUDIT.md docs/tasks/IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.md
---

The current public source requests `busy-before-beat 2` and reports
`busy_insertion.beats=single`, but generated HDL with `HGRANT=HREADY=1`
produces one contiguous BUSY episode spanning ten ready-qualified BUSY clock
edges. t/1498 and the paired harnesses count only transfer-type changes, so they
prove one episode and four data beats rather than one accepted BUSY event.

The repo-local Arm AHB specification permits fixed-length BUSY-to-SEQ changes
while `HREADY=0`, provided SEQ is then held until ready. That transition is not
the defect. The defect is the mismatch between `single` and ten qualified BUSY
edges when continuously ready.

Assertion-enabled disposable candidates prove a single-event accept rule plus
outer procedural gate yields exactly one qualified BUSY edge, survives a
32-clock ready-low stretch, resumes the same SEQ, and completes four data beats.
A width-two remaining counter proves exactly two qualified BUSY edges under
both continuously-ready and ready-low-then-ready conditions with no data beat,
response, address, or counter aliasing. `.1` therefore selects `.2`, exact
single-BUSY event-cardinality repair contract selection, before any public
multiple-BUSY syntax or behavior.
