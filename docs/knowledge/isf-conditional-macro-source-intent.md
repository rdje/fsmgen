---
id: isf-conditional-macro-source-intent
title: Existing ISF macros need explicit branch intent and inline procedure cond normalization
answers:
  - "at which layer is macro support being repaired?"
  - "why does a first sample-only conditional macro become an entry guard?"
  - "does successful source checking prove correct macro branch intent?"
  - "why does cond inside an inline procedure refuse?"
  - "which macro repair precedes generated output reads?"
  - "how are independently loaded conditional origins authenticated?"
  - "why must conditional origins have an independent source authority?"
date: 2026-10-02
status: current
tags: [isf, ial1, macros, branch, normalization, procedures]
evidence: >-
  docs/audits/conditional-macro-intent-20261002/scope.txt;
  docs/audits/conditional-macro-intent-20261002/manifest.json;
  docs/audits/conditional-macro-intent-20261002/verify.py;
  docs/audits/procedure-cond-normalization-20261002/scope.txt;
  docs/audits/procedure-cond-normalization-20261002/verify.py;
  t/2041-isf-conditional-macro-intent-qualification.t;
  t/2042-isf-procedure-cond-normalization.t;
  t/2043-isf-conditional-origin-parser.t;
  t/2044-isf-conditional-origin-source-authority.t;
  docs/audits/conditional-origin-parser-20261002/scope.txt;
  docs/audits/conditional-origin-authority-20261002/scope.txt;
  perl/FSM/Adapter/ISF/Parser.pm;
  perl/FSM/Scheduler/ISF/LoweringIR.pm;
  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2041-isf-conditional-macro-intent-qualification.t
  t/2043-isf-conditional-origin-parser.t
  t/2044-isf-conditional-origin-source-authority.t
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
normalization qualifies. SEM `.60.4.3.3.5.2.1.5.4.1` demonstrates why a
standalone normalization is unsafe: first sample-only procedure cond was
refused, but the candidate newly admits it as activation with one later branch.
Complete actual check/semantic/schedule native/API/newline admission and the
independent desired-branch RED establish the gap. Exact committed production
is restored and public refusal requalified; `.5.2` explicit source intent is
now next, then `.5.4.2` safe normalization and `.5.3` branch integration.
Scalar literal and record-output read/write prerequisites follow separately.

Detached parser-origin qualification retains original operation/form/owner and
actual inline call context through rewrites; min/max retain intent through
select. Whole actors/kinds and inline cond refusal stay unchanged. Authored when
and select can yield identical actors with distinct origins, falsifying clause
shape inference. The original observer compares its retained producer; fresh
instances only check structure. Independent source authentication and its
successive boundaries live in [source-bound tests](../../t/2044-isf-conditional-origin-source-authority.t),
[same-source linkage](isf-same-source-library-conditional-origins.md),
[document sets](isf-library-document-origin-authority.md),
[resolved ATL](isf-atl-document-origin-authority.md), and
[file origins](isf-file-document-origin-authority.md). Local authority refuses
imports; later observers separately qualify canonical external producers and
portable actual root/use/ATL reads. Embedded digests cannot authenticate original
intent. Formal/generated/domain preparation remains .5.2.2.3, before adoption
and branch integration.

Complete products and literal predicates/effects/aliases/roles re-derive scope;
desired-intent RED and shared corruption falsify admission/parity signoff. Tests,
sources, recipes, raw receipts and immutable seals preserve durability. No
production change, HDL/macro/output runtime or route/public widening is proved.
