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
  - "how do local conditional origins survive formal preparation clones?"
  - "does private formal origin qualification change macro admission?"
date: 2026-10-03
status: current
tags: [isf, ial1, macros, branch, normalization, procedures]
evidence: >-
  docs/audits/conditional-macro-intent-20261002/scope.txt;
  docs/audits/procedure-cond-normalization-20261002/scope.txt;
  t/2041-isf-conditional-macro-intent-qualification.t;
  t/2042-isf-procedure-cond-normalization.t;
  t/2043-isf-conditional-origin-parser.t;
  t/2044-isf-conditional-origin-source-authority.t;
  t/2052-isf-local-formal-origin-authority.t;
  docs/audits/local-formal-diagnostic-correction-20261002/scope.txt;
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
  t/2052-isf-local-formal-origin-authority.t
  t/2055-isf-local-formal-helper-diagnostic-causes.t
---

Repair existing ISF/IAL1 shorthand; `.fsm`/IAL0 remains the target.
Baseline `9bf0bd4c8af8c8aab5ab6865e66f6729d9583b3c` retains the first-when
sample-only entry gate while expansions lose branch intent.

Select/min/max, bit/field tests and cond become when lists. First assignments
refuse; first sample-only bit/field/cond can become activation, including
zero-wait/domain cases. Native/API/newline admission fails desired-branch RED. Authored sample-only
first when, also inline, retains documented activation meaning. Use explicit activation
before shorthand; keep cond at the transaction call site and call procedures
from its branches until normalization qualifies.

Cond scans precede procedure insertion: first/later inline cond stays unexpanded
and refuses. Later inline select/bit tests expand; their placement results are not universal.
Parser history is retained without submodule inspection. `.60.4.3.3.5.2.1.5.4.1` proved standalone cond normalization unsafe: refused first sample-only procedure
cond newly became activation with one later branch. Check/semantic/schedule
native/API/newline admission fails desired-branch RED. Production/refusal restored. Explicit intent `.5.2` precedes safe
normalization `.5.4.2` and branch integration `.5.3`; scalar literal and record
output read/write prerequisites follow.

The detached parser carries form/operation/owner/calls through actual rewrites,
including min/max through select. Whole actors/kinds
and inline-cond refusal stay unchanged. Equal authored-when/select actors disprove shape inference. Retained producers
authenticate origin; fresh observers check structure only. T2044
reconstructs complete actor/ledger from independent source, rejects digest
forgeries and closes imports. Separate qualifications cover
[same-source](isf-same-source-library-conditional-origins.md),
[documents](isf-library-document-origin-authority.md),
[ATL](isf-atl-document-origin-authority.md) and
[files](isf-file-document-origin-authority.md).

T2052 privately authenticates local source, follows actual LoweringIR/Storable
clone references into canonical FormalLowering/ClauseResolver, and binds returned clauses to catalog/call/path/ordinal and explicit input/output
formal identities/aliases/roles; whole literal clauses/products/kinds agree.
Sibling/pin shadows, locals, nested calls/clauses, equal-body origins, first
samples and existing declines qualify; opaque forgery, missing clone and
comparison-bypass controls falsify omissions. Reload/residual checks compare complete first causes.
[Repair](../audits/local-formal-helper-cause-repair-20261003/scope.txt) rejects real parser-label/object-class echoes; prior helper/source bypass fail. Wider helper/cold review stays open. Carp stacks echo regex text. The old invalid actors fixture/full-stack matcher falsely qualified a network
reason. A valid instance/actual echo RED supersedes it; prior archives stay intact.
Views detach. Imports, networks,
generated specialization and domains refuse. Qualification/adoption remain `.5.2.2.3` successors; production/admission unchanged.

No new language,
HDL/macro/output runtime, public route widening or completed delivery is proved.
