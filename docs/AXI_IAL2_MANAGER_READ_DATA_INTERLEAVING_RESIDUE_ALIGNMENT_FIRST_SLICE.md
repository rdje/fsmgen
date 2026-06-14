# AXI IAL2 Manager Read-Data Interleaving Residue Alignment First Slice

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.82`

Date: 2026-06-14

## Scope

This slice aligns report/static residue after the generated auto-ID
multi-beat-by-RID output-bank subset became covered.

No generated `.isf`, `.fsm`, or SystemVerilog behavior changes in this slice.
The generated payload path, beat-count state, lane capture rules, valid-mask
outputs, length outputs, scalar `RRESP` aggregation, and assertions remain the
same. Only the public report/static residue moves.

## Report Movement

For the public multi-beat read-data sample:

```text
read_data.residue: []
auto_id_lifecycle.residue: []
response_demux.residue:
  - bursts
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
  - bursts
```

`read_data_interleaving` is removed from `response_demux` and
`same_id_ordering` only when the report can prove the covered generated subset:

- generated same-ID avoidance covers the read family;
- generated read response demux covers the read family with burst-last
  matched-`RID` behavior;
- generated read-data capture is `capture_scope: multi_beat`;
- `interleaving_policy` is `multi_beat_by_rid`;
- beat matching and beat-count matching both use
  `response_demux_matched_read_beat`;
- beat storage is per transaction;
- output shape is per-beat output bank;
- valid and length outputs are per transaction;
- beat-count/RLAST runtime validation and multi-beat output-bank behavior are
  generated.

The same movement applies to no-scalar-aggregation multi-beat contracts because
the by-RID output-bank coverage does not depend on scalar `RRESP` aggregation.
Those contracts still keep `read_data.residue: [rresp_aggregation]`.

## Static Prose

The unsupported-residue prose now says the generated multi-beat output-bank
behavior covers the auto-ID multi-beat-by-RID subset. It still keeps
authored/general different-ID interleaving outside that subset, per-ID
same-ID response queues, dynamic user-ID arbitration, and broader burst payload
assembly as residue.

## Deferrals

This slice does not implement:

- authored concrete-ID same-ID ordering;
- per-ID issue-order queues or response scoreboards;
- dynamic user-ID arbitration for multiple same-family requests in one cycle;
- packed burst outputs;
- full burst payload assembly;
- queued/blocking policy;
- profile aliases;
- full-manager behavior;
- verification-code generation;
- direct backend lowering;
- VHDL behavior.

## Next Owner

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.83
```

`.83` should select the next AXI manager residue owner after the report now
shows `response_demux.residue: [bursts]` and
`same_id_ordering.residue: [concrete_id_same_id_ordering,
per_id_issue_order_queues, bursts]`.
