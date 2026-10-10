---
id: isf-record-output-source-contexts
title: Output-only record source/sample/clock-domain gates
answers:
  - "which source checks must run for an output-only record actor?"
  - "do output record scalar samples preserve signed and state traits?"
  - "why do record output field reads cross clock-domain boundaries?"
  - "can scalar formals borrow an outer record output layout?"
  - "what inventories original parser refusal source bodies?"
  - "does the original parser source inventory qualify active native paths?"
  - "what qualifies original parser function argument and helper context joins?"
date: 2026-10-10
status: current
tags: [isf, record, output, contexts, samples, domains, shadows]
evidence: >-
  docs/audits/record-value-parser-path-models-20261006/scope.txt; docs/audits/record-value-parser-context-join-20261006/scope.txt; docs/audits/record-value-parser-path-publication-20261006/scope.txt;
  docs/audits/record-value-original-parser-sources-20261005/scope.txt;
  docs/audits/record-value-parser-source-publication-20261005/scope.txt;
  docs/audits/record-output-source-contexts-20261001/manifest.json;
  t/2031-isf-record-output-source-contexts.t;
  perl/FSM/Support/ISFRecordPortSamples.pm;
  perl/FSM/Support/ISFRecordPortContexts.pm;
  perl/FSM/Scheduler/ISF/RecordSamples.pm;
  perl/FSM/Scheduler/ISF/LoweringIR.pm;
  perl/FSM/Adapter/ISF/Parser.pm
reverify: >-
  scripts/run_with_ram_guard.sh -- prove -Iperl -It/lib
  t/2031-isf-record-output-source-contexts.t
  t/2030-isf-record-output-writer-admission.t
  t/1991-isf-record-port-sample-contexts.t &&
  scripts/run_with_ram_guard.sh -- python3 -B
  docs/audits/record-value-parser-path-publication-20261006/verify.py &&
  scripts/run_with_ram_guard.sh -- python3 -B scripts/check_record_value_publication.py
---

At 8f31768d, actor_has_record_input-only selection bypassed prepared output-only context/sample consumers. Same actual
parsed declarations projected into outputs accepted literal whole-record targets/member writes/bus-owned field reads
from core; scalar captures lacked new private type declarations. Authored output syntax already refused: latent
shared-module prerequisites, not shipped behavior.

actor_has_record_port validates whole input/output lists without changing legacy input selection or autovivifying
malformed callers. Parser context, rule/enum scope, shared-module and scalar-sample consumers also select resolved
output roles. Source callers explicitly choose whole_output_writes_only; prepared toolkit retains broader member facts.
Exact record copy identity, readonly inputs and nearest formal/local/drive masks apply. Output-derived scalar captures
retain exact width/signedness/state model and cannot overwrite declarations or invent layouts. Mixed actors cannot hide
malformed output suffixes behind known input.

Actual output domain maps mark resolved record roots. Dotted/indexed paths reach the ownership validator rather than
possible-namespace delegation. Exact bus-to-core violations refuse; actual same-domain whole copy passes. No implicit
crossing/reset is introduced. Failed binary selection predicates are explicitly scalar, so malformed policy names its
failure rather than an argument-count error.

T2031 uses actual parsed facts/private prototypes; independent whole probe retains parsed storage/inputs before role
projection. Exact baseline snapshots replay the same probe/test without tree edits. Literal range/type/readonly/shadow/
alias/omission, full caller JSON/exact domain-message controls falsify broader claims. Full source/IR/receipts/baseline
objects/sealed verification/task/Git retain durability. Current input public/context/sample/carrier/ownership/replay
passes. SEM .60.4.3.3.4.3 integrates authored outputs/whole copies; [source
admission](isf-record-output-source-admission.md). Full public/generated/ execution/output fields remain
.3.4.4-.5/.60.4.3.4-owned. Original preparation is immutable.

## Original parser source inventory

Finite original source inventory binds whole own facade/parser/record-context texts. Lexical declarations, selected
whole function bodies, supplied parameter roles and ordered source call/guard statements regenerate independently. Exact
committed prerequisites qualify source inputs, primary causes, API/parser boundaries and helper context separately.

Output-field writes and aggregate actor-port type admission have distinct source guards. Source order establishes
provenance, not executed branches or returned calls remaining active. Native traces do not select intended sources.
Missing/borrowed bodies/statements/parameters/declaration membership/JSON kinds reject.

Default parser replay authenticates original source and historical publication. Its earlier --current route checks its
dated fact/question/book epoch; current publication uses the maintained current reader, retaining direct/cache ownership
and complete scoped book command/guidance obligations. Earlier command: `python3 -B
docs/audits/record-value-parser-path-publication-20261006/verify.py --current`. Active path/argument models and own
joins have separate proofs. Original own coordinates have separate core-fact qualification. Framework/display,
reference/address lifetimes, consumer/alias/cold and permanent/native repairs retain separate owners. Visual mdBook QA
is pending.

Related: [[record-value-original-observer-helper-paths]].

Finite source models distinguish original refusals: list actor-port admission stops before record contexts; output-field
writes reach the write guard. Whole positional/named roles identify supplied expressions. Receiver, normalized AST and
partial-actor payloads remain unmeasured. Returned callees are excluded from active own ancestry. Whole nested API
allocations reuse dated source-family proofs; own native/API/helper matching qualifies separately. Original refusals
match source-selected own function order/visible arguments across parser/API/observer/ helper/subtest phases. Core
overlap/order, helper/load adjacency and whole own frame membership qualify. Completed nested calls retain empty
errors/no throw frames. False is source predicate truth, not native encoding; reference kinds/ prefixes prove neither
referents nor hidden suffixes. Framework/formatter/external coordinates/addresses remain unmeasured.
