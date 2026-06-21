# AXI IAL2 Manager Mixed Auto-ID + Queue-Head Response-Demux Behavior

Work unit: `IAL2-FEATURE-COMPLETENESS-FRONTIER.194`

Date: 2026-06-21

## Scope

This slice ships the bounded response-demux-only combination of:

- one same-family `auto-id-lifecycle` transaction, and
- one concrete duplicate-ID `same-id-ordering` `issue-order-queue` group
  under the same selected `response-demux` family.

The shipped public shapes are:

- read `response-scope single-beat`
- read `response-scope burst-last` with one-bit `last-signal`
- write `BID` response demux

No new PPIF syntax is introduced. The public fixtures use the existing
`auto-id-lifecycle`, `same-id-ordering`, and `response-demux` forms:

- `ppif/axi_manager_capacity_status_read_single_beat_mixed_auto_id_same_id_queue_head_response_demux.ppif`
- `ppif/axi_manager_capacity_status_read_burst_last_mixed_auto_id_same_id_queue_head_response_demux.ppif`
- `ppif/axi_manager_capacity_status_write_mixed_auto_id_same_id_queue_head_response_demux.ppif`

## Generated Behavior

For the selected family, the response demux now normalizes a mixed entry with
`transaction_completion_source` set to
`generated_demux_and_queue_head_demux`.

The generated completion outputs cover both sides of the family:

- the auto-ID transaction completion pulse, matched by active selected ID
- the concrete queue-head transaction completion pulses, matched by concrete
  response ID and queue-head slot state
- for read burst-last, the generated rules are also gated by `RLAST`

The generated response-demux rule and assertion sets are built over the
combined state list. For a one-auto plus two-concrete fixture this produces
three generated completion rules and one active-match assertion plus the three
pairwise unique-match assertions.

## Request-ID Ownership

Mixed auto/concrete families share the same request-ID bus. In this slice the
request-ID signal remains a generated output owned by the auto-ID lifecycle
family. Concrete transactions in that same family get generated request-ID
drive rules that assign their concrete ID value on their request event.

To keep those generated writes disjoint, auto-ID allocation guards are widened
to exclude same-family concrete request events, and concrete request-ID drive
guards exclude same-family auto-ID request events. The concrete-ID report still
records request/response checks, but `id_response_rule_engine.id_signal_inputs`
reports only the effective interface inputs; the generated request-ID output is
not duplicated as an input.

## Non-Goals

The slice does not add:

- read-data consumption for mixed auto-ID plus queue-head demux
- group-local simultaneous enqueue widening
- packed burst-vector outputs
- alternate full burst payload assembly
- direct IAL2-to-IAL0 lowering
- verification-output generation
- VHDL or backend-language variants

