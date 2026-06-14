# AXI IAL2 Manager Burst Residue Alignment First Slice

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.85`

Date: 2026-06-14

## Scope

This slice aligns report/static `bursts` residue after the generated auto-ID
multi-beat output-bank subset became covered by shipped behavior.

No generated `.isf`, `.fsm`, or SystemVerilog behavior changes in this slice.
The generated burst-last response demux, raw ARLEN capture, runtime
beat-count/RLAST assertions, per-beat data/status output lanes, valid masks,
length outputs, scalar `RRESP` aggregation when selected, and same-ID
avoidance behavior remain unchanged. Only the public report/static residue
moves.

## Report Movement

For the public multi-beat read-data sample:

```text
ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
```

the schedule report now shows:

```text
read_data.residue: []
auto_id_lifecycle.residue: []
response_demux.residue: []
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
```

`bursts` is removed from `response_demux` and `same_id_ordering` only when
the report can prove the covered generated subset:

- generated same-ID avoidance covers the read family;
- generated read response demux covers the read family with burst-last
  matched-`RID` behavior;
- read-data capture is `capture_scope: multi_beat`;
- `interleaving_policy` is `multi_beat_by_rid`;
- beat matching and beat-count matching both use
  `response_demux_matched_read_beat`;
- burst length comes from ARLEN, uses ARLEN+1 expected-beat encoding, and has
  generated raw-ARLEN capture;
- runtime beat-count/RLAST validation is generated;
- beat storage is per transaction;
- output shape is a per-beat output bank;
- generated data/status output lanes are present for every configured beat of
  every covered transaction;
- valid-mask and length outputs are present per transaction;
- generated multi-beat output-bank behavior is enabled.

Scalar `RRESP` aggregation is not required for this movement because the
bounded output-bank shape already generates per-beat status lanes. Multi-beat
contracts without scalar aggregation still report
`read_data.residue: [rresp_aggregation]`, but they no longer keep
`bursts` residue in `response_demux` or `same_id_ordering` when the per-beat
status lanes and other predicates above are present.

## Static Prose

The unsupported-residue prose now distinguishes the covered bounded
per-beat output-bank shape from future packed/full burst shapes. It lists
bounded burst payload/output behavior through that per-beat output bank as
supported, while keeping packed burst-vector outputs, alternate full burst
payload assembly, and aggregate-only status output shapes outside this
capacity/status shell.

## Deferrals

This slice does not implement:

- packed burst-vector outputs;
- alternate full burst payload assembly;
- aggregate-only status output shapes;
- authored concrete-ID same-ID ordering;
- per-ID issue-order queues or response scoreboards;
- dynamic user-ID arbitration for multiple same-family requests in one cycle;
- queued/blocking policy;
- profile aliases;
- full-manager behavior;
- verification-code generation;
- direct backend lowering;
- VHDL behavior.

## Next Owner

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.86
```

`.86` should select the next AXI manager feature-completeness slice after the
public multi-beat sample now reports empty `response_demux.residue` and only
`concrete_id_same_id_ordering` plus `per_id_issue_order_queues` under
`same_id_ordering.residue`.
