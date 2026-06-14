# AXI IAL2 Manager Read-Data Interleaving Queue Readiness Audit

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.81`

Date: 2026-06-14

## Inputs Read

This audit reads:

- generated scalar `RRESP` aggregation behavior from `.79`;
- generated multi-beat read-data output-bank behavior from `.74`;
- generated burst-last response demux, raw ARLEN capture, and
  beat-count/RLAST runtime validation;
- generated auto-ID same-ID avoidance behavior;
- the live public multi-beat schedule report;
- README, roadmap, mdBook, task tree, and Knowledge Map context.

The live public multi-beat sample reports:

```text
read_data.residue: []
auto_id_lifecycle.residue: []
response_demux.residue:
  - read_data_interleaving
  - bursts
same_id_ordering.residue:
  - concrete_id_same_id_ordering
  - per_id_issue_order_queues
  - read_data_interleaving
  - bursts
```

## Finding

The current public multi-beat sample already has a bounded generated
`multi_beat_by_rid` data path for generated auto-ID transactions:

- generated auto-ID same-ID avoidance prevents two active auto-ID transactions
  in the same family from holding the same selected ID;
- read response demux and read-data capture rules match accepted read beats by
  `RID` against each transaction's selected ID;
- each read transaction owns independent raw ARLEN, expected-beat, beat-count,
  output-bank, valid-mask, length, and scalar aggregate status state;
- lane capture rules use the existing matched-read-beat plus
  `!request_event` plus current beat-count equality boundary.

That is enough to claim the first bounded generated auto-ID
different-ID/multi-beat-by-RID output-bank subset. It is not enough to claim
full AXI read-data interleaving or per-ID queue support.

The remaining `read_data_interleaving` residue in `response_demux` and
`same_id_ordering` is therefore too broad for the covered generated auto-ID
multi-beat sample. The next step should align the machine-readable residue and
static prose with the shipped bounded subset before adding new behavior.

## Selection

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.82
```

Goal:

```text
Align AXI read-data interleaving residue after generated multi-beat by-RID
output-bank behavior.
```

The selected `.82` slice should:

- remove `read_data_interleaving` residue from `response_demux` for the
  covered generated auto-ID multi-beat read-data output-bank sample;
- remove `read_data_interleaving` residue from `same_id_ordering` only for the
  same covered generated auto-ID multi-beat-by-RID subset;
- preserve `concrete_id_same_id_ordering`, `per_id_issue_order_queues`, and
  broader `bursts` residue;
- update report/static prose, focused tests, README, roadmap, mdBook, task
  tree, Memory, and Knowledge Map;
- preserve generated `.isf`, `.fsm`, and HDL behavior.

## Deferrals

This audit does not select implementation of:

- authored concrete-ID same-ID ordering;
- per-ID issue-order queues or response scoreboards;
- multiple outstanding authored transactions sharing an ID;
- dynamic user-ID arbitration for multiple same-family requests in one cycle;
- packed burst outputs;
- full burst payload assembly;
- queued/blocking policy;
- profile aliases;
- full-manager behavior;
- verification-code generation;
- direct backend lowering;
- VHDL behavior.

## Validation

The `.82` implementation should prove report-only behavior movement:

- focused generator and PPIF/CLI tests for residue/report shape;
- direct schedule JSON probe for the public multi-beat sample;
- generated `.isf`, `.fsm`, and SystemVerilog no-drift checks where practical;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- diff hygiene and stale-frontier scan.
