# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.457`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.457` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.458`, public contract selection for the
first generated dynamic read same-ID `issue-order-queue` behavior.

The first read-side contract should be bounded to all-dynamic read
single-beat `RID` response demux. It must not include read burst-last
`RID && RLAST`, read-data capture, raw `ARLEN`, runtime beat-count/`RLAST`,
multi-beat output banks, mixed dynamic/static queues, broader write
cardinality, scoreboards, direct backend behavior, backend-language variants,
or VHDL.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, focused test,
schedule/check/semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The audit read the `.456` post-write selector, `.455` generated dynamic write
queue behavior, `.454` runtime-ID representation selection, `.453` dynamic
queue contract selection, `.452` readiness audit, `.450` metadata-first
dynamic issue-order policy behavior, generated dynamic read single-beat
`RID`, read burst-last `RID && RLAST`, read-data, raw `ARLEN`, runtime
validation, multi-beat output-bank, and recapture records, generated dynamic
same-ID reject mapping records, concrete read same-ID queue-head records,
current parser/report/residue/support-accounting/code/test surfaces, README,
ROADMAP_V2, mdBook, MEMORY, task tree, and Knowledge Map facts.

## Current Boundary

The parser already accepts family-local dynamic issue-order policy metadata:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

The generated read response-demux path already supports all-dynamic read
single-beat and burst-last matching when no incompatible same-ID policy is
selected. It captures `ARID`, matches `RID` or `RID && RLAST`, emits generated
completion pulses, and supports same-cycle release-and-recapture for covered
single-active and multiple all-dynamic read shapes.

The current dynamic queue generator is intentionally write-only. The read
normalizer still fails closed when `same-id-ordering.read` selects
`dynamic-id-reuse issue-order-queue`, and no read dynamic queue report mode or
read dynamic queue behavior is generated.

## Readiness Finding

The substrate is ready for a public contract selector, not direct behavior.
The existing dynamic write queue proved the core runtime-ID queue
representation:

- compact slots with one-hot transaction identity;
- slot-local captured request ID;
- response-time earliest matching runtime-ID selection;
- same-cycle selected dequeue plus one enqueue; and
- queue-specific assertions that replace reject-only active-ID uniqueness.

The read single-beat `RID` path is the safest first read contract because it
has the same response shape as the generated write queue, but with read-family
request and response ID signals. It has no final-beat-only dequeue, no raw
non-final response beat, no `RLAST`, and no burst-length/runtime/multi-beat
consumer coupling.

Read burst-last `RID && RLAST` is not first because a dynamic queue would need
to select whether only final matching beats dequeue, how raw non-final matching
beats participate in active-response and unique-match assertions, and how
last-beat read-data, raw `ARLEN`, runtime validation, multi-beat output banks,
and recapture consumers stay coherent. That is a larger contract than the
first read queue should carry.

## Selected .458 Boundary

`.458` must select the public contract for the first generated dynamic read
single-beat queue before implementation. It should settle:

- exact source shape, expected to be two all-dynamic read transactions,
  explicit `response-demux.read` with `response-scope single-beat`, and
  `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- whether the first implementation is exactly two dynamic reads or "two or
  more" with a first public two-read sample;
- required read ID-family metadata, generated completion ownership, event
  collision checks, and fail-closed diagnostics;
- reuse or refinement of `compact_runtime_id_issue_order_slots`,
  `captured_request_id`, and `dynamic_issue_order_earliest_matching_slot` for
  read `RID`;
- admitted enqueue source, full/empty/head predicates, dequeue source, and
  same-cycle selected dequeue plus enqueue policy;
- response-demux mode, completion source, transaction implementation status,
  same-ID policy fields, assertion roles, and residue movement;
- whether read-data remains explicitly unsupported for the first generated
  read queue or whether it only becomes a later exact owner over generated
  queue completion pulses;
- support-accounting sample boundaries and focused validation gates; and
- rollback, docs, mdBook, and Knowledge Map updates.

## Deferred Work

These remain future exact owners:

- generated dynamic read queue implementation;
- read burst-last `RID && RLAST` dynamic queues;
- read-data over generated dynamic read queues;
- raw `ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank
  behavior over generated dynamic read queues;
- dynamic queue cardinality beyond the first selected bounded public shape;
- mixed dynamic/static same-ID queues;
- dynamic scoreboards;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

This readiness audit is documentation/task-tree only. Closeout gates should
cover Knowledge Map regeneration/check, mdBook build, docs relative-path audit,
memory-architecture check, diff hygiene, and the full doctrine gate. Runtime
Perl, PPIF, schedule/check/semantic JSON, generated HDL, focused tests, and
broad `prove` gates are not required because no parser or generated behavior
changed.

## Rollback

Rollback is the `.457` selector commit. Reverting it removes this readiness
record, the new fact card/map entry, README/ROADMAP/mdBook wording, task-tree
frontier movement, and MEMORY pointer update, restoring `.457` as the active
readiness audit after the `.456` selector.
