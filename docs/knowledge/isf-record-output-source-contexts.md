---
id: isf-record-output-source-contexts
title: Output-only records require scoped source, sample and clock-domain gates
answers:
  - "which source checks must run for an output-only record actor?"
  - "do output record scalar samples preserve signed and state traits?"
  - "why do record output field reads cross clock-domain boundaries?"
  - "can scalar formals borrow an outer record output layout?"
date: 2026-10-01
status: current
tags: [isf, record, output, contexts, samples, domains, shadows]
evidence: >-
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
  t/1991-isf-record-port-sample-contexts.t
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
checks. Authored outputs, output fields, generated mappings and output execution
remain separately gated under SEM .60.4.3.3.4-.5 and .60.4.3.4.
