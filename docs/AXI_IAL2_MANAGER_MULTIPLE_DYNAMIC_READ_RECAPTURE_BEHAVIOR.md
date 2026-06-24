# AXI IAL2 Manager Multiple Dynamic Read Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.381`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.381` ships same-cycle
release-and-recapture for the existing support-accounted multiple all-dynamic
read single-beat response-demux sample:

```text
ppif/axi_manager_capacity_status_dynamic_read_response_demux_multi.ppif
```

The source syntax, support-accounting identity, generated completion names, and
`bounded_multi_dynamic_read_rid_demux_contract` report mode are unchanged.
Scalar single-beat read-data over generated multiple dynamic read completions
continues to consume the generated completion pulses without widening its
capture semantics.

## Generated Rules

Each dynamic read transaction keeps its selected-ID and busy state:

```text
axi0_r0_dynamic_id_q
axi0_r0_dynamic_busy_q
axi0_r1_dynamic_id_q
axi0_r1_dynamic_busy_q
```

FSMGen emits one release-recapture rule per dynamic read transaction:

```text
axi0_r0_dynamic_id_release_recapture
axi0_r1_dynamic_id_release_recapture
```

For transaction `rN`, the release-recapture guard requires:

- the same transaction has an admitted read request in the cycle;
- the same transaction has its generated matched single-beat `RID` completion
  in the cycle;
- the same transaction is busy before the update;
- no sibling dynamic read has an admitted request in the cycle; and
- no active sibling dynamic read already holds the new `ARID`.

The rule writes the new `ARID` into that transaction's selected-ID state and
keeps the busy bit asserted. The raw response-demux match still uses the
pre-update selected ID, so the response being completed and the newly admitted
request remain ordered inside the generated IAL1/IAL0 update cycle.

The release-only rule remains per transaction and clears busy only when the
transaction completes without a same-cycle own request:

```text
axi0_rN_complete && axi0_rN_dynamic_busy_q && !axi0_rN_request
```

Under that completion guard, `!axi0_rN_request` is equivalent to excluding the
same transaction's admitted same-cycle request because completion contributes
to the admission fan-in.

## Report Contract

Each entry in `response_demux.read.dynamic_capture.transactions[]` now reports:

```yaml
release_recapture_rule: axi0_rN_dynamic_id_release_recapture
same_cycle_release_recapture_policy: multi_active_unique_dynamic_read
release_recapture_source: generated_dynamic_demux_completion
release_recapture_transaction: rN
```

The per-transaction request assertions are now
`axi0_r0_dynamic_request_idle_or_releasing` and
`axi0_r1_dynamic_request_idle_or_releasing`. The slice preserves:

- `axi0_read_dynamic_request_onehot0`;
- per-transaction no-active-same-ID assertions;
- pairwise active dynamic ID uniqueness;
- raw response active-match;
- pairwise response unique-match; and
- per-transaction completion-active assertions.

## Residue

This slice does not widen request arbitration beyond onehot0 and does not add
queues or scoreboards. Multiple dynamic read burst-last recapture, mixed
dynamic/static recapture, static busy recapture, backend-language variants,
VHDL, and full AXI manager behavior remain future exact-owner work.

## Validation

Focused validation covers the generated IAL1, scheduled IAL0, report JSON, and
SystemVerilog lowering expectations through:

```bash
env PERL5LIB=perl perl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env PERL5LIB=perl perl -c t/1436-ial2-ppif-parser-cli.t
env PERL5LIB=perl perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env PERL5LIB=perl perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env FSMGEN_DYNAMIC_CASE_FILTER=dynamic_read_demux_multi FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -l t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Additional closeout probes for adapter/generator report shape, mdBook,
Knowledge Map, memory, diff, and doctrine gates are recorded in the task-tree
validation ledger.

## Rollback

Rollback is the `.381` implementation commit. Reverting it removes the
multi-dynamic read release-recapture rules and report fields, restores the
per-transaction request-not-busy assertions for the multiple dynamic read
single-beat sample, and leaves the earlier `.251` multiple dynamic read
response-demux behavior intact.
