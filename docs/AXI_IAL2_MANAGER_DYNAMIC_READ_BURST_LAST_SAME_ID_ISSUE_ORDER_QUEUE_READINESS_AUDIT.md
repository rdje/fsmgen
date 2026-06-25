# AXI IAL2 Manager Dynamic Read Burst-Last Same-ID Issue-Order Queue Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.461`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.461` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.462`, public contract selection for
generated dynamic read burst-last `RID && RLAST` same-ID `issue-order-queue`
behavior.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, queue, scoreboard, or VHDL behavior.

## Inputs Read

The audit read the `.460` selector, `.459` generated dynamic read single-beat
queue behavior, `.458` contract selection, `.457` dynamic read queue readiness
audit, `.455` generated dynamic write queue behavior, `.454` runtime-ID queue
representation selection, generated dynamic read burst-last response-demux,
dynamic read `RLAST` transaction-ID capture, multiple all-dynamic read
burst-last response-demux, dynamic read-data, raw `ARLEN`, runtime
beat-count/`RLAST`, multi-beat output-bank, and recapture records, concrete
read burst-last queue-head readiness and behavior records, current parser,
normalizer, queue builder, assertion, read-data coverage, support-accounting,
focused-test, README, ROADMAP_V2, mdBook, MEMORY, task tree, and Knowledge
Map surfaces.

## Current Boundary

The parser and policy metadata already admit read dynamic same-ID
`issue-order-queue` policy:

```lisp
(same-id-ordering
  (read (dynamic-id-reuse issue-order-queue)))
```

The dynamic read queue planner already requires the correct structural
ingredients:

- exactly two read transactions;
- both read transactions are `(id dynamic)`;
- no read `auto-id-lifecycle`;
- `read-max-pending` at least `2`;
- present read ID-family metadata;
- one shared read request ID source; and
- compact runtime-ID issue-order slots keyed by captured `ARID`.

The current response-demux normalization intentionally fails closed for the
burst-last sibling:

```text
response_demux.read dynamic-id-reuse issue-order-queue supports only
response_scope single-beat in this slice
```

That fail-closed diagnostic is still correct until the public burst-last
queue contract is selected.

## Adjacent Shipped Behavior

Generated dynamic read burst-last response-demux already exists without
dynamic same-ID queues. It emits final `RID && RLAST` completion pulses through
`generated_dynamic_demux_last_beat`, while active and unique response
assertions intentionally check raw accepted read beats by `RID` without
requiring `RLAST`. That makes non-final beats legal and still checked.

Generated scalar last-beat read-data, report-only raw `ARLEN`, runtime
beat-count/`RLAST` validation, and multi-beat output banks already compose
over that non-queue dynamic burst-last completion source.

Generated concrete read burst-last queue-head behavior already proves that
queue dequeue can be final-beat-only. Its response-demux rules include
`RLAST`, and its queue assertions include a non-last no-dequeue check when a
one-bit `last_signal` is present.

The `.459` dynamic read single-beat queue behavior already proves the compact
runtime-ID slot representation, slot-local captured `ARID`, earliest matching
`RID`, same-cycle selected dequeue plus one enqueue, generated completion
outputs, queue-specific assertions, and report/residue movement for exactly
two all-dynamic read transactions.

## Readiness Finding

No lower parser, report-schema, IAL1, IAL0, or SystemVerilog prerequisite is
required before selecting the public burst-last dynamic queue contract. The
existing substrate can carry the required one-bit `RLAST` input, generated
completion pulses, compact queue slots, captured runtime IDs, guarded rules,
pulse actions, and assertions.

Direct behavior is still too broad without a contract-selection owner. The
current dynamic queue selected-match helpers use `response_event && RID`
without `RLAST`; if reused directly for burst-last, they would dequeue on a
non-final matching beat. The next slice must pin the public contract before
implementation changes:

- final-beat-only selected dequeue must be `response_event && RID match &&
  RLAST`;
- raw active response matching must remain `response_event && RID match`
  without `RLAST`, so non-final beats are legal and checked;
- selected completion pulses must fire only on the final selected match;
- dynamic queue assertions need a non-final no-dequeue role analogous to the
  concrete queue-head path;
- generated response-demux reports need distinct burst-last queue vocabulary;
- downstream read-data, raw `ARLEN`, runtime validation, multi-beat, and
  recapture consumers must remain preserved but not accidentally enabled over
  the new queue completion source in the first behavior slice.

## Selected .462 Boundary

`.462` must select the public contract for the first generated dynamic read
burst-last queue. The expected scope is:

- exactly two all-dynamic read transactions;
- `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- explicit `response-demux.read`;
- `response-scope burst-last`;
- one-bit `last-signal`;
- generated transaction completions;
- compact runtime-ID issue-order slots;
- slot-local captured `ARID`;
- earliest matching captured runtime ID with `RLAST` as the selected final
  dequeue condition;
- raw non-final beat preservation through active/unique response checks;
- response-demux-only public sample for the first behavior slice; and
- no read-data, raw `ARLEN`, runtime-validation, multi-beat, mixed queue,
  scoreboard, direct-backend, backend-language variant, or VHDL behavior in
  the contract-selection slice.

The contract selection should choose exact report vocabulary, including the
mode name, completion source name, completion semantics, completion-validity
string for later consumers, queue assertion roles, residue movement,
diagnostics, support-accounting identity for the future public sample,
validation gates, rollback, and non-goals.

## Deferred Work

These remain future exact owners after `.461`:

- direct generated dynamic read burst-last queue behavior;
- read-data over generated dynamic read queues;
- raw `ARLEN`, runtime beat-count/`RLAST`, and multi-beat output-bank
  behavior over generated dynamic read queues;
- same-cycle recapture widening over generated dynamic read burst-last queues;
- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- dynamic scoreboards;
- validation and memory retry follow-up;
- direct backend behavior;
- backend-language variants; and
- VHDL.

## Validation

This is a docs-only readiness audit. Closeout validation should cover
Knowledge Map regeneration/check, mdBook build, docs relative-path audit,
memory architecture check, diff whitespace check, and doctrine gate. Runtime
Perl, PPIF, schedule/check/semantic JSON, generated HDL, focused tests, and
broad `prove` gates are not required because no parser or generated behavior
changed.

## Rollback

Rollback is the `.461` commit. Reverting it removes this audit, its Knowledge
Map fact, and the README/ROADMAP_V2/mdBook/task-tree/MEMORY frontier movement,
restoring `.461` as the active audit after the `.460` selector.
