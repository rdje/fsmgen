---
id: core-expression-width-inference
title: Core exact width inference has explicit source-reference and unsized literal boundaries
answers:
  - "where is the shared Core expression width inference kernel?"
  - "how can a target supply unsized literal widths without changing Core defaults?"
  - "does exact width inference prove a generated helper placeholder or symbolic ancestry?"
  - "why can nested unsized literal helpers truncate a guards high bit?"
  - "how are nested literal child holders joined before live parser integration?"
date: 2026-10-30
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
  t/2257-source-nested-literal-transitions.t; docs/audits/source-nested-literal-transitions-20261029.json.gz; t/2258-source-nested-literal-allocation.t; t/2259-source-nested-literal-publication.t; t/2260-source-nested-literal-closure.t; docs/audits/literal-target-consumers-20261030/verify.py
  perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/SourceLiteralWidthSupport.pm; t/2261-target-source-literal-width.t; t/2262-target-source-literal-numeric-inference.t; t/2263-verilog-prepared-maximum-range.t; t/2264-target-source-literal-generic-range.t; t/2265-target-source-literal-selection.t
reverify: scripts/run_with_ram_guard.sh -- prove -Iperl t/2265-target-source-literal-selection.t t/2264-target-source-literal-generic-range.t; python3 -B docs/audits/literal-generic-range-20261030/verify.py --qualify
---

CoreExpressionWidthSupport::infer_width is the bounded direct builder exact-width
walk. Its ordinary call leaves unsized literal widths unknown. An explicit
unsized_literal_width callback receives detached raw literal value/radix/width
with source JSON kinds intact; it supplies a validated width without changing
Core. Explicit literal widths bypass it. Unknown future classes cannot borrow it.
Scalar wrappers keep their results; cycles and over-bound walks remain unknown.
Ordinary references read selected widths without expanding Signals' definitions.

Selected widths do not prove ancestry or placeholder exactness. The full source/
target diagnosis, ordinary versus injected capture, manual evidence limits and
open consumers remain in `docs/book/src/11a-perl-api-reference.md`.

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
source_reference_width receives actual whole refs: undef uses selected width;
a closed nullable record resolves or withholds. Malformed results withhold;
scalar/slice/literal and walk rules preserve. This supplies no source proof.
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
T2258 covers fixed/mutable Parser/facade writes. T2259 qualifies publication:
the original birth's phase/digest projection must match actual completed child
capsules. T2260 closes source edge/conservation/lifetime controls; target sizing remains separate.

Target-only SourceLiteralWidthSupport prepares current source literal widths;
prepare_inference joins actual rows/epoch before compatibility metadata (T2261/2).
Shared WidthExpressionEmitter lower_maximum_range retains independent prepared
contracts/floors under overrides (T2263). Generic joins (T2264), typed selection
(T2265), physical proof (T2267) and live ledgers/fences (T2268) are canonical in
`docs/book/src/11a-perl-api-reference.md`. Sized mutable emission now passes;
unsized mutable final Core agreement remains open. Private target-record seams
alone qualify no generation.
