# AXI IAL2 Manager Post-Interleaving Alignment Next Slice Selection

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.83`

Date: 2026-06-14

## Inputs Read

This selector reads:

- `.82` read-data interleaving residue alignment;
- live schedule JSON for
  `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`;
- generated burst-last read response demux behavior;
- generated raw-ARLEN capture and beat-count/RLAST runtime validation;
- generated multi-beat output-bank behavior;
- generated scalar `RRESP` aggregation behavior;
- same-ID ordering residue and response-demux residue;
- roadmap, mdBook, task tree, Memory, and Knowledge Map context.

The live public multi-beat report now has:

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

## Selection

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.84
```

Goal:

```text
Audit AXI burst payload/output readiness after read-data interleaving residue
alignment.
```

## Rationale

After `.82`, `bursts` is the only remaining `response_demux` residue and is
also still present in `same_id_ordering`. The current public multi-beat sample
already has most burst-adjacent behavior: burst-last `RLAST` demux, raw ARLEN
capture, expected-beat and beat-count runtime validation, per-beat output
banks, valid masks, length outputs, and scalar aggregate `RRESP`.

That does not automatically mean FSMGEN should remove all burst residue. The
next audit must decide whether the shipped per-beat output bank is enough to
claim a bounded burst-output subset, whether the public surface needs an
explicit packed burst payload contract first, whether report/static text can
move without new behavior, or whether a lower-layer prerequisite is required.

Concrete-ID same-ID ordering and per-ID issue-order queues remain important,
but selecting them before resolving the now-isolated burst residue would widen
ordering behavior while leaving the current public multi-beat sample's most
visible remaining report gap unresolved.

## Deferrals

This selector does not implement:

- packed burst payload outputs;
- full burst payload assembly;
- authored concrete-ID same-ID ordering;
- per-ID issue-order queues or response scoreboards;
- queued/blocking policy;
- profile aliases;
- full-manager behavior;
- verification-code generation;
- direct backend lowering;
- VHDL behavior.

## Validation For `.84`

The `.84` audit should prove it is selector/readiness-only:

- direct schedule JSON probe for the public multi-beat sample;
- review of generated read response demux, ARLEN capture, beat-count/RLAST,
  output-bank, and scalar `RRESP` behavior;
- docs, mdBook, roadmap, task tree, Memory, and Knowledge Map sync;
- Knowledge Map generation/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- diff hygiene and stale-frontier scan.
