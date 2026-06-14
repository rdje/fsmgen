# AXI IAL2 Manager Post-RRESP Aggregation Next Slice Selection

Owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.80`

Date: 2026-06-14

## Inputs Read

This selector reads the shipped scalar `RRESP` aggregation behavior from
`IAL2-FEATURE-COMPLETENESS-FRONTIER.79`, the live public multi-beat sample
schedule report, README, roadmap, mdBook feature backlog, task tree, and
Knowledge Map.

The live report after `.79` has:

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
unsupported_residue:
  - blocking_or_queued_policy
  - axi_id_ordering_and_response_matching
  - profile_aliases_and_full_manager_behavior
  - vhdl_backend_or_reroute
```

That means the current public sample has generated bounded auto-ID lifecycle,
same-ID avoidance for auto-ID families, read/write response demux, burst-last
completion, ARLEN capture, beat-count/RLAST validation, multi-beat output
banks, and scalar `RRESP` aggregation. The next unresolved AXI manager cluster
is no longer scalar status reporting; it is the deeper relationship between
read-data interleaving, bursts, per-ID issue/response queues, and concrete-ID
same-ID ordering.

## Selection

The next exact owner is:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.81
```

Goal:

```text
Audit AXI per-ID read-data interleaving and queue readiness after generated
scalar RRESP aggregation behavior.
```

The audit must decide whether the next implementation path should start with:

- public per-ID queue/interleaving contract selection;
- authored concrete-ID same-ID ordering before data interleaving;
- generated per-ID issue/response queue substrate;
- burst payload assembly beyond the current bounded output-bank sample;
- report/static alignment first;
- an IAL1/IAL0/SystemVerilog prerequisite; or
- a smaller docs/support-accounting slice.

No parser, generator, HDL, sample, support-accounting, check JSON, semantic
JSON, or validation behavior changes belong to `.81` unless the audit itself
explicitly selects a smaller behavior owner after reading the substrate.

## Verification Output Disposition

The brainstormed verification route is valid for FSMGEN, but it should be a
separate roadmap lane from the current synthesizable RTL/HDL feature-complete
path.

The intended shape is: one IAL1/IAL2 source can eventually feed multiple
targets:

- synthesizable HDL targets, such as SystemVerilog RTL and future VHDL;
- verification-code targets, such as SystemVerilog/UVM agents, monitors,
  scoreboards, protocol checkers, coverage, and reusable verification IP.

Verification output should be free to use non-synthesizable target-language
constructs. It should not weaken or complicate the synthesizable route by
mixing UVM/testbench semantics into the RTL lowering path. A later task tree
should own the verification-output roadmap once the current SV-backed IAL2 RTL
feature-completeness path is stable enough to provide a durable source
contract.

## Deferrals

This selector does not implement:

- per-ID read-data queues;
- authored concrete-ID same-ID ordering;
- burst payload assembly beyond the current bounded output-bank sample;
- queued/blocking issue policy;
- profile aliases;
- full-manager behavior;
- verification-code generation;
- direct backend lowering;
- VHDL behavior.

## Validation

Selector validation is documentation and continuity oriented:

- direct live schedule probe for the public multi-beat sample residue;
- Knowledge Map regeneration/check;
- mdBook build;
- docs relative-path audit;
- memory architecture check;
- diff hygiene;
- stale frontier scan.
