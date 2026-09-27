---
id: isf-formal-parent-read-products
title: Parent storage-read products retain actual shared owner views and consumers
answers:
  - "are parent storage read handoffs retained before formal allocation?"
  - "what does parent_storage_read_products contain?"
  - "how does read planning reserve completion and write handoffs?"
date: 2026-09-27
status: current
tags: [isf, formals, reservations, storage, readers, children, ownership]
evidence: perl/FSM/Scheduler/ISF/ChildStorageOwnership.pm; perl/FSM/Scheduler/ISF/LoweringIR.pm; t/1951-isf-formal-parent-read-products.t; t/1950-isf-child-read-block-collisions.t
reverify: FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME=1 scripts/run_with_ram_guard.sh prove -Iperl t/1951-isf-formal-parent-read-products.t t/1950-isf-child-read-block-collisions.t t/1949-isf-formal-parent-write-products.t
---

plan_child_storage_read_handoffs shares executable reader allocation and
products with detached formal preparation. It copies input name membership,
allocates in actual spawn/read order and retains ports, type aliases, read DTs,
typed actor_storage_read identities and explicit per-instance child links.
Multiple readers of the same storage use the same owner view. Executable
connection installs exactly those products; port widths remain on the ports,
without adding a register, cycle or parent signal_widths declaration.

prepare_formal_source retains parent_storage_read_products after actual
completion and potential write planning, extending declaration membership with
write widths/DT names before reader allocation. Names remain separate from raw
formal widths/roles. This allows potential reads to be collected before raw
storage/formal aliases pass executable ownership checks. The plans neither
admit conflicting writers nor finalize a synthetic parent.

T1951 observes the production planner, compares complete allocation inputs and
products with prepared source/physical plans, and checks actual installed
ports, aliases, DTs, typed ownership and shared links. Scalar, named scalar,
record, list, selected bank, multiple-reader and read/write cases retain strict
parent carriers. Exact/case-folded formal, fixed and rule-name collisions
preserve portable reservation coverage after projection. Input/product mutation
controls preserve source, child and preceding write snapshots. Raw role
conflicts still fail executable admission; absent reads create no handoff.
T1950 independently checks the previously repaired rule guard collision.

These are partial namespace products. Named-completion, library-readback and
outer domain coverage remain gates before complete reservations and automatic
production formal rewriting. Canonical live-read behavior remains in
[isf-generated-child-aggregate-reads](isf-generated-child-aggregate-reads.md).
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.49.2.2.3.2.2.2.3.2.2.2.2.2.2.2.2.1.2.
