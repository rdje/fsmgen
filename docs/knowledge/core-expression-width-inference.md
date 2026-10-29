---
id: core-expression-width-inference
title: Core exact width inference has explicit source-reference and unsized literal boundaries
answers:
  - "where is the shared Core expression width inference kernel?"
  - "how can a target supply unsized literal widths without changing Core defaults?"
  - "does exact width inference prove a generated helper placeholder or symbolic ancestry?"
  - "why can nested unsized literal helpers truncate a guards high bit?"
  - "how are nested literal child holders joined before live parser integration?"
date: 2026-10-29
status: current
tags: [widths, literals, core, expression, source-capture]
evidence: >-
  perl/FSM/CoreExpressionWidthSupport.pm; perl/FSM/Adapter/FSMGenFull/ExpressionBuilder.pm;
  t/2250-core-expression-width-contract.t; docs/audits/core-expression-width-contract-20261029.json.gz;
  docs/audits/literal-width-ownership-20261029/receipt.json.gz;
  perl/FSM/SourceLiteralWidthAllocationSupport.pm; t/2251-source-literal-width-holder.t;
  docs/audits/source-literal-holder-20261029.json.gz; t/2252-source-literal-width-birth.t;
  docs/audits/source-literal-birth-20261029.json.gz; t/2253-source-literal-width-transitions.t;
  docs/audits/source-literal-transitions-20261029.json.gz;
  t/2254-source-literal-width-publication.t; docs/audits/source-literal-publication-20261029.json.gz;
  t/2255-core-source-reference-width.t; docs/audits/source-reference-width-20261029.json.gz;
  t/2256-source-nested-literal-holder.t; docs/audits/source-nested-literal-holder-20261029.json.gz;
  t/2257-source-nested-literal-transitions.t; docs/audits/source-nested-literal-transitions-20261029.json.gz
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/225[0-7]*.t
---

CoreExpressionWidthSupport::infer_width is the bounded direct builder exact-width
walk. Its ordinary call leaves unsized literal widths unknown. An explicit
unsized_literal_width callback receives detached raw literal value/radix/width
with source JSON kinds intact; it supplies a validated width without changing
Core. Explicit literal widths bypass it. Unknown future classes cannot borrow it.
Scalar wrappers keep their results; cycles and over-bound walks remain unknown.
Ordinary references read selected widths without expanding Signals' definitions.

Selected widths alone prove neither allocation ancestry nor that a helper's
compatibility placeholder is exact. This preparatory API does not yet alter the
backend consumer or symbolic floors. Required repair continues under
ISF-REDUCTION-DELIVERY.3.4.3.2.3.4.4.1.2. Actual mutable literal sources retain the
final source/target disagreement; fixed sources currently generate without that
same final check. Full qualification remains .6.

Revision-bound ownership diagnosis at the preparation commit: an unknown literal
helper retains nominal Core width. A nested parent reads that width as exact and
can emit a narrow destination that discards the literal high bit. Strict CLI and
debug trace reproduce the ordinary fixed artifact. Injected declaration capture
instead refuses; preserve those separate conditions. Source birth/unknown
propagation .1.2.2 and target/final agreement .1.2.3 own the immediate P1 repair.
The adjacent audit verify.py --current --qualify authenticates producer bytes,
source/target products and independent mask algebra while rejecting hostile
saved variants. It is manual, revision-bound diagnosis, not an unconditional
current-state watcher or external HDL runtime proof.

SourceLiteralWidthAllocationSupport now validates detached direct bitwise literal
allocation holders with nullable exact width and raw literal value/radix/size.
Actual identities, weak lifetime tokens, tracked revisions and a complete raw
capture barrier reject matching writes and late mutation. T2251 distinguishes
explicit floors and JSON kinds; an isolated omitted-barrier variant fails its
late-write control. This validator publishes no live source policy. The builder
captures fresh direct literal births in a separate source_literal_events bucket;
actual name/registry ownership and parsed Core kinds are required (T2252).
Exact named role/reference/width-metadata transitions now preserve complete source
state and registry ownership, including repeated slots (T2253); other writes withhold.
Completed Parser/facade transactions now publish detached Core literal intent.
Common allocation clear/revision revokes matching writes and failed replacements;
completion preserves the staged epoch with a final raw registry join (T2254).
The preparatory source_reference_width callback now receives actual whole refs:
undef uses selected width; a closed nullable width record resolves or withholds.
Malformed results withhold; scalar/slice/literal rules and walk bounds preserve.
It supplies no source proof. Targets remain open.
The opt-in literal holder children boundary now joins actual typed child edges
to current birth capsules or actual installed completed policy, with explicit
phases. It expands raw source text while separately binding ordered child edges;
unknown child widths never borrow nominal widths or independent floors. Shared
walk bounds cover all helper expansion. Complete raw/capsule barriers reject
late matching writes and completed-policy removal (T2256); isolated fallback
and omitted-barrier variants fail. Default direct captures preserve.
Named transport reconstructs each original child capsule under only the declared
delta through bounded captures; original edge digest and whole projected parent
must agree. A current child cannot hide unrelated kinds or source data (T2257);
omitting original-child proof fails the record-kind control. Matching references,
helper roles, mutable metadata and completed refresh preserve. Strict UTF-8
digests preserve raw Unicode without interpreting literals. Actual source capture
now resolves local child births before parent registration: unknown or revoked
intent cannot lend a nominal width or old binary maximum policy. Fresh nested
births and child-first transport preserve independent floors and scalar results.
T2258 covers fixed/mutable Parser/facade writes; completed nested publication and
target sizing remain separate.
