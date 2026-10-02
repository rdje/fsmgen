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

Existing ISF/IAL1 shorthand/scheduling is being repaired; `.fsm`/IAL0 stays the
target, with no new macro language.
Baseline `9bf0bd4c8af8c8aab5ab6865e66f6729d9583b3c` retains the precise first-when
sample-only entry gate, but conditional expansion still loses source intent.

Select/min/max, bit/field tests and cond become when lists. First action bodies
refuse; sample-only bit/field/cond can still enter as activation, including
zero-wait and owning-domain cases. Complete native/API/newline phases admit them,
but desired-branch RED disproves delivery. Authored sample-only first when, also
inline, retains its distinct documented activation meaning.

Cond scans precede procedure insertion: inline cond stays unexpanded and refuses
in first and explicitly activated later positions. Inline select/bit-test expand
after insertion with their own placement results; this is not every procedure
macro. Actual parser root history is retained without submodule inspection.

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

Parser-origin observation carries operation/form/owner and inline call context
through rewrites; min/max retain intent through select. Whole actors/kinds and
inline cond refusal stay unchanged. Authored when and select can yield identical
actors with distinct origins, disproving clause-shape inference. The original
observer trusts its retained producer; fresh instances only check structure.
[Source-bound tests](../../t/2044-isf-conditional-origin-source-authority.t)
independently reconstruct actor/ledger from source, reject embedded-digest intent
forgeries and refuse imports. Later canonical qualifications have separate facts:
[same-source](isf-same-source-library-conditional-origins.md),
[document sets](isf-library-document-origin-authority.md),
[ATL](isf-atl-document-origin-authority.md), and
[file roots](isf-file-document-origin-authority.md). Preparation .5.2.2.3 still
precedes adoption/branch integration.

Complete products and literal predicates/effects/aliases/roles re-derive scope;
desired-intent RED and shared corruption falsify admission/parity signoff. Tests,
sources, recipes, raw receipts and immutable seals preserve durability. No
production change, HDL/macro/output runtime or route/public widening is proved.
