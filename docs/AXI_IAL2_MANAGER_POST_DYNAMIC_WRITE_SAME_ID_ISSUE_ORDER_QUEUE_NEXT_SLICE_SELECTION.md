# AXI IAL2 Manager Post Dynamic Write Same-ID Issue-Order Queue Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.456`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.456` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.457`, readiness audit for generated
dynamic read same-ID `issue-order-queue` behavior after the first generated
dynamic write `BID` queue shipped.

This selector changes no parser, generator, PPIF sample, support-accounting
catalog, focused test, generated artifact, schedule/check/semantic JSON, HDL,
runtime behavior, direct backend behavior, backend-language variant, queue,
scoreboard, or VHDL behavior.

## Inputs Read

The selection used the `.455` generated dynamic write queue behavior record,
`.454` runtime-ID representation selection, `.453` contract selection, `.452`
readiness audit, `.450` metadata-first dynamic issue-order policy behavior,
generated dynamic write/read/read-burst-last response-demux records, dynamic
read-data, burst-length/runtime, multi-beat, and recapture records, generated
dynamic same-ID reject mapping records, concrete same-ID queue-head behavior
records, current parser/report/residue/support-accounting/test/code surfaces,
README, ROADMAP_V2, mdBook, MEMORY, task-tree, and Knowledge Map facts.

The code boundary confirms that the first generated dynamic queue path is
write-only. `response-demux.write` can select
`generated_dynamic_issue_order_queue_demux`, but `response-demux.read` still
rejects `same-id-ordering.read` beyond covered dynamic reject mappings before
normal generated dynamic read demux planning runs.

## Selection Rationale

Dynamic read queue readiness is the next exact owner because it is the closest
uncovered sibling of the shipped write queue and has more coupling risk than
broader write cardinality. Existing read-side dynamic behavior already includes
single-beat `RID` demux, burst-last `RID && RLAST` demux, read-data consumers,
raw `ARLEN`/runtime validation, multi-beat output banks, and same-cycle
recapture. A dynamic read queue must decide how queue dequeue and completion
selection interact with final-beat-only completion, raw non-final matched
beats, read-data capture, burst-length/runtime validation, multi-beat banks,
and active-response assertions before implementation can be safe.

Broader write cardinality remains useful, but it is a mechanical widening of
the already generated write queue. Mixed dynamic/static queues require a
separate ownership model for static concrete reservations plus runtime-ID
queue entries. Dynamic scoreboards are a different public policy and must not
share queue semantics by accident. Validation retry, report cleanup, direct
backend, backend-language variants, and VHDL do not close the nearest
user-visible dynamic issue-order queue residue.

## Selected .457 Boundary

`.457` must be an audit-only slice unless it explicitly selects a smaller
contract owner. It must decide whether the next behavior path can be:

- dynamic read single-beat `RID` issue-order queue;
- dynamic read burst-last `RID && RLAST` issue-order queue;
- a shared read queue representation or report contract prerequisite;
- broader generated write queue cardinality first; or
- another narrower prerequisite exposed by the audit.

The audit must record:

- supported source shape and fail-closed diagnostics;
- whether the first read queue is single-beat, burst-last, or both;
- required `response-demux.read` fields and generated completion ownership;
- runtime-ID key source, slot state, queue depth, full/empty/head predicates,
  admitted enqueue source, dequeue source, and same-cycle dequeue/enqueue
  policy;
- response matching for `RID` and, when selected, `RID && RLAST`;
- raw non-final read beat policy and active-response assertion scope;
- preservation of scalar read-data, raw `ARLEN`, runtime beat-count/`RLAST`,
  multi-beat output-bank, and recapture consumers;
- generated report fields and residue movement;
- support-accounting and sample impact, if any;
- focused validation gates, RAM-guard caveats, rollback boundary, docs, and
  Knowledge Map impact.

## Non-Goals

`.456` does not implement dynamic read queue behavior. `.457` must not change
behavior until it finishes the readiness audit and either selects a contract
slice or records that a narrower prerequisite is needed.

The following remain future exact owners unless `.457` explicitly selects a
narrow prerequisite:

- generated dynamic read queue implementation;
- generated dynamic write queue cardinality beyond the existing two-write
  sample;
- mixed dynamic/static same-ID queues;
- dynamic scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

This selector is documentation/task-tree only. Closeout gates should cover
Knowledge Map regeneration/check, mdBook build, docs relative-path audit,
memory-architecture check, diff hygiene, and the full doctrine gate. Focused
Perl, PPIF, schedule/check/semantic JSON, generated HDL, and broad `prove`
gates are not required for `.456` because no runtime or generated behavior is
changed.

## Rollback

Rollback is the `.456` selector commit. Reverting it removes this selection
record, the new fact card/map entry, README/ROADMAP/mdBook wording, task-tree
frontier movement, and MEMORY pointer update, restoring `.456` as the active
selector after the generated dynamic write queue behavior.
