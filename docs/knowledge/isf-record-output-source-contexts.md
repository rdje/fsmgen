---
id: isf-record-output-source-contexts
title: Output-only records require scoped source, sample and clock-domain gates
answers:
  - "which source checks must run for an output-only record actor?"
  - "do output record scalar samples preserve signed and state traits?"
  - "why do record output field reads cross clock-domain boundaries?"
  - "can scalar formals borrow an outer record output layout?"
  - "what inventories original parser refusal source bodies?"
  - "does the original parser source inventory qualify active native paths?"
date: 2026-10-01
status: current
tags: [isf, record, output, contexts, samples, domains, shadows]
evidence: >-
  docs/audits/record-value-parser-path-models-20261006/scope.txt;
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
  docs/audits/record-value-parser-path-models-20261006/verify.py --current
---

At baseline 8f31768d, prepared output-only actors bypassed source context/sample
consumers selected solely by actor_has_record_input. The same actual parsed
declarations projected into output roles accepted literal whole-record targets,
output member writes and a bus-owned field read from core. Scalar captures
lacked their new private type declaration. Authored record output syntax was
already refused, so these were latent shared-module prerequisites rather than
shipped output behavior.

actor_has_record_port now validates complete input/output lists without changing
legacy input selection or autovivifying malformed callers. Parser context,
rule/enum scope, shared module and scalar sample consumers select resolved
output roles too. Source callers explicitly choose whole_output_writes_only;
the prepared toolkit retains its broader member facts. Exact record copy
identity, readonly inputs and nearest formal/local/drive masks still apply.
Output-derived scalar captures preserve exact width, signedness and state model
and cannot overwrite declarations or invent record layouts. Mixed actors cannot
hide a malformed output suffix behind a known input.

The actual output domain map now marks resolved record roots. Dotted/indexed
paths therefore reach the existing ownership validator instead of being
delegated as possible namespaces. Exact bus-to-core violations refuse; an
actual same-domain whole copy remains valid. No implicit crossing or reset is
introduced. Failed binary selection predicates are explicitly scalar, so a
malformed policy names its policy failure rather than an argument-count error.

T2031 uses actual parsed declaration facts plus explicit private prototype
clauses; the independent full probe additionally retains actual parsed storage
and input bodies before role projection. Exact baseline module snapshots run
the same probe/test without changing the worktree. Literal ranges/types,
readonly/shadow/alias/omission controls, complete caller JSON and the exact
domain message falsify broader interpretations. Full source/IR/receipts,
baseline objects, sealed verification, the task tree and Git provide durability.
Input public/context/sample/carrier/ownership/replay contracts pass current
checks. SEM .60.4.3.3.4.3 now integrates authored output declarations and whole
copies; see [source admission](isf-record-output-source-admission.md). Complete
public/generated/execution and output field qualification remain .3.4.4-.5
and .60.4.3.4. The original preparation evidence is immutable.

## Original parser source inventory

The finite original source inventory binds whole own facade, parser and
record-context texts. Their lexical declarations, selected complete function
bodies, supplied parameter roles and ordered source call/guard statements
are independently regenerated. Exact committed prerequisites qualify source
inputs, primary causes, API/parser boundaries and helper context separately.

Output-field source writes and aggregate actor-port type admission have distinct
source guards. Source order records provenance; it does not establish which
branches ran or whether a returned call remained active. No native trace supplies
the intended source selection. Missing or borrowed source bodies, statements,
parameters, declaration membership and JSON kinds reject.

The default replay authenticates original source and historical publication.
Explicit current replay also checks this whole fact, actual direct/cache question
ownership and the scoped book command and guidance. Independent active path and
argument models, complete native/API/helper joins, framework/display contracts,
raw coordinates, reference/address lifetimes, consumer/alias/cold meanings and
permanent/native repairs remain separate owners. Visual mdBook QA is pending.

Related: [[record-value-original-observer-helper-paths]].

Finite source models distinguish the original refused paths: list actor-port
admission stops before record contexts; output-field writes reach the write guard.
Complete positional/named roles identify supplied source expressions. Receiver,
normalized AST and partial-actor payloads remain unmeasured. Returned callees are
excluded from active own ancestry. Complete nested API allocations reuse dated
source-family proofs; native/API/helper frame matching remains separate.
