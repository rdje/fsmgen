---
id: isf-conditional-macro-source-intent
title: Existing ISF macros need explicit branch intent and inline procedure cond normalization
answers:
  - "at which layer is macro support being repaired?"
  - "why does a first sample-only conditional macro become an entry guard?"
  - "does successful source checking prove correct macro branch intent?"
  - "why does cond inside an inline procedure refuse?"
  - "which macro repair precedes generated output reads?"
date: 2026-10-02
status: current
tags: [isf, ial1, macros, branch, normalization, procedures]
evidence: >-
  docs/audits/conditional-macro-intent-20261002/scope.txt;
  docs/audits/conditional-macro-intent-20261002/manifest.json;
  docs/audits/conditional-macro-intent-20261002/verify.py;
  t/2041-isf-conditional-macro-intent-qualification.t;
  perl/FSM/Adapter/ISF/Parser.pm;
  perl/FSM/Scheduler/ISF/LoweringIR.pm;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2041-isf-conditional-macro-intent-qualification.t
---

This repairs existing ISF/IAL1 shorthand expansion and transaction scheduling.
It introduces no new macro language/framework; `.fsm`/IAL0 remains the target.
Baseline `9bf0bd4c8af8c8aab5ab6865e66f6729d9583b3c` retains the precise first-when
sample-only entry gate, but conditional expansion still loses source intent.

Select/min/max, bit/field conditionals and cond desugar to ordinary when lists.
First action bodies now refuse at the entry gate. First sample-only bit/field
and cond macros can still admit as activation entries, including zero-wait and
owning-domain witnesses, instead of ordinary branch decisions. Actual complete
native/API/newline phases admit those sources. The desired-intent producer is
genuine RED against their branch topology; admission is not correct delivery.
An authored sample-only first when, including inline substitution, retains its
documented activation meaning and must remain distinct from macro intent.

Cond expansion scans transactions before procedure expansion inserts bodies.
An inline proc cond therefore remains an unexpanded cond and refuses in both
first and explicitly activated later positions. Select and bit-test inline
controls expand after insertion and have their own qualified placement results;
do not infer that every procedure macro is broken. Root history is preserved
for the actual parser producers; no submodule implementation is inspected.

Use explicit activation before conditional shorthand. Keep cond at the
transaction call site and call ordinary procedures from its branches until
normalization qualifies. SEM `.60.4.3.3.5.2.1.5.4` owns that P2 repair next,
before `.5.2` explicit source intent and `.5.3` integration; scalar literal and
record-output read/write prerequisites follow separately.

Literal predicates/effects/aliases/roles and complete current products
re-derive each scoped result. Genuine desired-intent RED and shared-corruption
rejection falsify admission/parity-only signoff. Permanent tests, full sources,
producers/recipes/raw receipts, sealed membership and immutable predecessors
provide durability. This qualification changes no production code and proves
no HDL execution, macro/output runtime or record-output route/public widening.
