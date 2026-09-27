---
id: isf-generated-child-writer-contract-frontier
title: Broader child writers separate aggregate transfer, partial merge, bank ownership and contention
answers:
  - "what is the next generated child storage writer contract?"
  - "does storage_port arbitrate generated child transaction writes?"
  - "is set-field a partial child storage write?"
date: 2026-09-27
status: current
tags: [isf, storage, writers, arbitration, aggregates, banks]
evidence: perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; perl/FSM/Adapter/ISF/Parser.pm; t/1261-isf-aggregate-storage-leaf-writes.t; t/1403-isf-set-field.t; t/1218-isf-rule-slot-resource-arbitration.t; docs/decisions/0107-actor-storage-has-one-owner-across-generated-children.md
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1261-isf-aggregate-storage-leaf-writes.t t/1403-isf-set-field.t t/1218-isf-rule-slot-resource-arbitration.t
---

Sole full-width scalar and packed aggregate generated-child writes are qualified, including in
independent domains. Decision 0107 requires owner-held storage and original-edge
handoffs. Broader work is split under SEMANTIC-INTROSPECTION-MCP-FRONTIER.39.2.2.4:

- .4.2 qualifies whole packed record/list transfers in T1917/T1919, preserving exact types.
- .4.3 qualifies source-supported partial and scalar-leaf updates without
  clobbering untouched bits. Parser-supported aggregate leaves are distinct from
  arbitrary slice targets. set-field currently desugars to a full-register
  masked read-modify-write; it is not a physical partial assignment.
- .4.4 qualifies scalarized bank stores. LoweringIR's bank assignment builder
  emits literal-selected entries or guarded dynamic entries. Literal out-of-range
  indexes fail; unmatched dynamic indexes enable no entry. Existing report policy
  is read_before_write. Runtime qualification must preserve these semantics.
- .4.5 defines competing-writer progress and explicit arbitration before accepting
  parent/child or multiple-child contention. Existing storage_port users must be
  declared rules, and members name concrete storage signals rather than bank
  roots or aggregate paths. Gating a rule for a cycle does not specify child
  request retention, denied-state progress or lifetime ownership.

ChildStorageOwnership currently rejects partial/member/bank write targets and
all competing owners. These boundaries remain until the corresponding runtime,
report and documentation qualification is complete. No silent priority or memory
backend is implied by the scalarized representation.

The actor-storage book introduction retained pre-qualification refusal wording
from commit 5c0f802646c69108d15995f7e8cd7e29c32ebdf5 after the composition chapter
advanced. The .4.1 audit corrects that stale introduction against T1911/T1916/
T1917/T1918 and links the detailed composition contract.
