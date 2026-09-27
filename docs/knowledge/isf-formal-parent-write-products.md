---
id: isf-formal-parent-write-products
title: Potential parent storage-write products share canonical handoff planning
answers:
  - "are parent child-storage write data and enable names retained before formal allocation?"
  - "what does parent_storage_write_products include in source preparation?"
  - "does collecting parent write handoffs admit competing storage writers?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, storage, writers, children, ownership]
evidence: perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1949-isf-formal-parent-write-products.t; t/1917-isf-generated-child-scalar-writes.t
reverify: scripts/run_with_ram_guard.sh prove -Iperl t/1949-isf-formal-parent-write-products.t t/1946-isf-formal-completion-products.t t/1917-isf-generated-child-scalar-writes.t
---

plan_child_storage_write_handoffs shares the actual allocation and handoff
products used by connect_child_storage_writes. Executable connection retains
its generated-writer and parent-writer checks before invoking the planner,
then installs the actual ports, widths/types, owner-side write DTs and explicit
links. The planner also returns allocation input_names and typed
actor_storage_write identities containing actor, instance and storage name.
It does not infer ownership from helper prefixes.

Source preparation retains detached parent_storage_write_products using actual
registered instances, generated child storage-write contracts and declaration
membership. The common _formal_parent_declaration_names helper supplies the
pre-completion namespace; real completion declarations extend it before write
planning. Membership never becomes an executable storage width, and conflicting
raw parent formal width/role maps remain separate. These are potential handoff
products, not writer admission or a finalized parent. A source plan may exist
for competing writers that executable connection must reject.

T1949 observes the actual production planner result and compares complete
allocation inputs, ports, widths/types, DTs and typed instance/storage links
before and after detached formal projection. Scalar, scalar alias, packed
record/list and distinct-target cases retain the original owner and strict
parent carriers. Exact/case-folded fixed and formal helper collisions exercise
real allocation changes; typed ownership and portable inventory coverage remain.
Source/product mutation controls preserve detached snapshots. Raw formal/storage
role overlap, parent/generated competition and multiple generated writers keep
their executable refusals. A child with no actor write creates no handoff.

The complete parent/child/completion/scalar-writer/schedule cohort passes,
including existing native/API/newline report checks. This does not add a register
cycle, new writer arbitration or new runtime qualification. The native schedule
is unchanged by the planner extraction. Read, named-completion,
library-readback and outer domain namespace coverage remain later gates before
complete reservations or automatic production formal renaming. Storage behavior
remains canonical in [isf-generated-child-scalar-writes](isf-generated-child-scalar-writes.md).
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.1.
