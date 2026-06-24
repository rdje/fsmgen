# AXI IAL2 Manager Multiple Dynamic Write Recapture Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.378`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.378` ships same-cycle
release-and-recapture for the existing support-accounted multiple all-dynamic
write response-demux sample:

```text
ppif/axi_manager_capacity_status_dynamic_write_response_demux_multi.ppif
```

The source syntax, support-accounting identity, generated completion names, and
`bounded_multi_dynamic_write_bid_demux_contract` report mode are unchanged.

## Generated Rules

Each dynamic write transaction keeps its selected-ID and busy state:

```text
axi0_w0_dynamic_id_q
axi0_w0_dynamic_busy_q
axi0_w1_dynamic_id_q
axi0_w1_dynamic_busy_q
```

FSMGen emits one release-recapture rule per dynamic write transaction:

```text
axi0_w0_dynamic_id_release_recapture
axi0_w1_dynamic_id_release_recapture
```

For transaction `wN`, the release-recapture guard requires:

- the same transaction has an admitted write request in the cycle;
- the same transaction has its generated matched-`BID` completion in the cycle;
- the same transaction is busy before the update;
- no sibling dynamic write has an admitted request in the cycle; and
- no active sibling dynamic write already holds the new `AWID`.

The rule writes the new `AWID` into that transaction's selected-ID state and
keeps the busy bit asserted. The raw response-demux match still uses the
pre-update selected ID, so the response being completed and the newly admitted
request remain ordered inside the generated IAL1/IAL0 update cycle.

The release-only rule remains per transaction and clears busy only when the
transaction completes without a same-cycle own request:

```text
axi0_wN_complete && axi0_wN_dynamic_busy_q && !axi0_wN_request
```

Under that completion guard, `!axi0_wN_request` is equivalent to excluding the
same transaction's admitted same-cycle request because completion contributes
to the admission fan-in.

## Report Contract

Each entry in `response_demux.write.dynamic_capture.transactions[]` now reports:

```yaml
release_recapture_rule: axi0_wN_dynamic_id_release_recapture
same_cycle_release_recapture_policy: multi_active_unique_dynamic_write
release_recapture_source: generated_dynamic_demux_completion
release_recapture_transaction: wN
```

The per-transaction request assertions are now
`axi0_w0_dynamic_request_idle_or_releasing` and
`axi0_w1_dynamic_request_idle_or_releasing`. The slice preserves:

- `axi0_write_dynamic_request_onehot0`;
- per-transaction no-active-same-ID assertions;
- pairwise active dynamic ID uniqueness;
- raw response active-match;
- pairwise response unique-match; and
- per-transaction completion-active assertions.

## Residue

This slice does not widen request arbitration beyond onehot0 and does not add
queues or scoreboards. Multiple dynamic read single-beat recapture, multiple
dynamic read burst-last recapture, mixed dynamic/static recapture, static busy
recapture, backend-language variants, VHDL, and full AXI manager behavior
remain future exact-owner work.

## Validation

Focused validation covers the generated IAL1, scheduled IAL0, report JSON, and
SystemVerilog lowering expectations through:

```bash
env -u PERL5LIB perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm
env -u PERL5LIB perl -c t/1436-ial2-ppif-parser-cli.t
env -u PERL5LIB perl -c t/1437-axi-ial2-manager-capacity-status-generator.t
env -u PERL5LIB perl -c t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
scripts/run_with_ram_guard.sh -- env FSMGEN_DYNAMIC_CASE_FILTER=dynamic_write_demux_multi FSMGEN_DYNAMIC_SKIP_CLI_JSON=1 prove -l t/1438-axi-ial2-manager-dynamic-transaction-id-focused.t
```

Additional closeout probes for schedule JSON, strict check JSON, semantic JSON,
plain SystemVerilog generation, mdBook, Knowledge Map, memory, diff, and
doctrine gates are recorded in the task-tree validation ledger.

## Rollback

Rollback is the `.378` implementation commit. Reverting it removes the
multi-dynamic write release-recapture rules and report fields, restores the
per-transaction request-not-busy assertions for the multiple dynamic write
sample, and leaves the earlier `.247` multiple dynamic write response-demux
behavior intact.
