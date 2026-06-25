# AXI IAL2 Manager Dynamic Read Same-ID Issue-Order Queue Read-Data Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.465`

Date: 2026-06-25

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.465` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.466`, public contract selection for paired
bounded scalar read-data routing over generated dynamic read same-ID
`issue-order-queue` completions.

The next contract owner should cover both scalar single-beat read-data over the
generated dynamic read single-beat queue and scalar last-beat read-data over
the generated dynamic read burst-last queue. The paired boundary is the
smallest coherent public contract because both queue completion sources now
ship and both already have matching scalar read-data precedent in the ordinary
generated dynamic read-data path.

This audit changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check/
semantic JSON, HDL, runtime behavior, direct backend behavior,
backend-language variant, or VHDL behavior.

## Evidence Read

The audit read:

- `.464` post dynamic read burst-last same-ID issue-order queue selector.
- `.463` generated dynamic read burst-last `RID && RLAST` same-ID
  `issue-order-queue` behavior.
- `.462` dynamic read burst-last queue contract selection.
- `.459` generated dynamic read single-beat `RID` same-ID
  `issue-order-queue` behavior.
- `.455` generated dynamic write `BID` same-ID `issue-order-queue` behavior.
- Single-active and multiple all-dynamic scalar read-data behavior records.
- Concrete same-ID queue-head read-data readiness and behavior records.
- Current read-data coverage, artifact, report, residue, parser/CLI,
  generator-test, support-accounting, README, ROADMAP_V2, mdBook, MEMORY, task
  tree, and Knowledge Map surfaces.

## Current Boundary

The generated dynamic read queue response-demux reports expose distinct queue
completion sources:

```text
generated_dynamic_issue_order_queue_demux
generated_dynamic_issue_order_queue_demux_last_beat
```

Current read-data coverage accepts ordinary generated dynamic read demux
sources:

```text
generated_dynamic_demux
generated_dynamic_demux_last_beat
```

but it does not yet accept the generated dynamic issue-order queue completion
sources. Downstream read-data artifact generation is otherwise already
source-agnostic once coverage supplies the covered transactions, generated
completion signals, and completion-validity vocabulary.

The existing public syntax is sufficient. The selected future samples can add
the existing `read-data.read` clauses to the two shipped dynamic queue
response-demux samples:

- `capture-scope single-beat`, `completion-source response-demux`, and
  `interleaving single-beat-by-rid` for the single-beat queue.
- `capture-scope last-beat`, `completion-source response-demux`,
  `status-policy last-beat`, and `interleaving last-beat-by-rid` for the
  burst-last queue.

## Selected `.466` Contract Scope

`.466` must select the exact public contract before behavior changes. The
selected contract should stay bounded to:

- exactly two all-dynamic read transactions;
- `same-id-ordering.read (dynamic-id-reuse issue-order-queue)`;
- explicit generated `response-demux.read`;
- `read-max-pending` at least `2`;
- complete `read-data.read` transaction coverage for the two generated queue
  transactions;
- scalar single-beat read-data over
  `generated_dynamic_issue_order_queue_demux`;
- scalar last-beat read-data over
  `generated_dynamic_issue_order_queue_demux_last_beat`;
- no `read-data.read.burst-length` metadata in the first behavior owner.

The contract should pin queue-specific read-data completion-validity names:

```text
generated_dynamic_read_issue_order_queue_response_demux_completion_pulse
generated_dynamic_read_issue_order_queue_response_demux_last_beat_completion_pulse
```

The read-data report modes should remain the existing scalar modes:

```text
bounded_single_beat_read_data_contract
bounded_last_beat_read_data_contract
```

The response-demux report modes and transaction completion sources should
remain the generated dynamic queue modes:

```text
bounded_dynamic_read_rid_issue_order_queue_demux_contract
bounded_dynamic_read_rid_rlast_issue_order_queue_demux_contract
generated_dynamic_issue_order_queue_demux
generated_dynamic_issue_order_queue_demux_last_beat
```

For scalar queue read-data, the first behavior should preserve response-demux
residue for broader interleaving and burst work while clearing only read-data
residue that the scalar owner actually covers.

## Required Diagnostics

The future behavior owner selected by `.466` must fail closed when:

- `read-data.read` omits a generated dynamic queue transaction;
- `read-data.read` names a transaction outside the generated dynamic queue;
- transaction bindings are duplicated;
- generated completion-signal count does not match the covered queue
  transaction count;
- single-beat read-data is paired with burst-last response scope;
- last-beat read-data is paired with single-beat response scope;
- first-scope scalar queue read-data attempts `burst-length`, runtime
  validation, multi-beat output banks, broader queue cardinality, mixed
  dynamic/static queues, scoreboards, direct backend behavior,
  backend-language variants, or VHDL.

## Non-Goals

`.465` changes no behavior. The following remain future exact owners until a
later task-tree leaf selects them:

- read-data generation over dynamic queues;
- raw `ARLEN` capture over dynamic queues;
- runtime beat-count/`RLAST` validation over dynamic queues;
- multi-beat output banks over dynamic queues;
- queue recapture widening;
- broader dynamic queue cardinality;
- mixed dynamic/static queues;
- dynamic scoreboards;
- direct backend behavior;
- backend-language variants;
- VHDL.

## Validation Plan

Because `.465` is docs-only, closeout is documentation and continuity focused:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
mdbook build docs/book
prove -Iperl t/1414-docs-relative-paths-audit.t
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

No syntax, parser, generator, PPIF, support-accounting, schedule/check/
semantic JSON, HDL, or runtime behavior validation is claimed for `.465`
because it changes no behavior.

## Rollback

Rollback removes this audit document and fact card, reverts the `.465` task
tree/memory/README/roadmap/mdBook updates, and returns the active frontier to
`.465`. No code or runtime behavior rollback is needed.
