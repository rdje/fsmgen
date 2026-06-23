# AXI IAL2 Manager Broader Mixed Dynamic/Static Cardinality Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.316`

Date: 2026-06-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.316` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.317`, public contract selection for the
first broader mixed dynamic/static transaction-cardinality shape after the
one-dynamic plus one- or two-concrete-static mixed path reached multi-beat
output banks.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check/semantic JSON, or HDL
behavior changes in `.316`.

## Evidence Read

The audit read:

- `.315` post multiple mixed multi-beat selector;
- `.314` multiple mixed multi-beat behavior;
- `.313` multiple mixed multi-beat readiness audit;
- `.312` multiple mixed runtime-validation behavior;
- `.307` multiple mixed scalar read-data behavior;
- `.303` and `.299` multiple mixed read response-demux behavior;
- `.295` multiple mixed write response-demux behavior;
- `.291` one-dynamic plus one-static mixed multi-beat behavior;
- `.268` multiple all-dynamic multi-beat behavior;
- mixed dynamic/static response-demux constructors, normalization gates,
  read-data coverage predicates, multi-beat residue predicates, focused t/1438
  assertions, support-accounting surfaces, README, ROADMAP_V2, mdBook, task
  tree, Memory, and Knowledge Map.

## Readiness Findings

The current mixed dynamic/static response-demux admission is intentionally
bounded. The write and read dynamic matching plan selectors both reject any
mixed dynamic/static shape unless it is exactly one dynamic transaction plus
one or two pairwise-distinct concrete static transactions.

The mixed demux constructors repeat that invariant internally:

- `_response_demux_mixed_dynamic_static_write_transaction` requires one
  dynamic and one or two static write transactions.
- `_response_demux_mixed_dynamic_static_read_transaction` requires one
  dynamic and one or two static read transactions.

The read burst-last normalizer also repeats the selected boundary before
building mixed `RID && RLAST` response-demux report metadata. The read-data
coverage predicates then split the exact one-dynamic plus one-static and
one-dynamic plus two-static shapes into separate completion-validity branches.
The multi-beat residue predicate for the multiple mixed branch is exact
one-dynamic plus two-static as well.

Some downstream substrate is already more general:

- static transaction handling loops over the static state list;
- generated mixed active-match and unique-match assertions are pairwise over
  all dynamic/static states passed to them;
- the all-dynamic path already supports multiple dynamic transactions;
- the multi-beat read-data report helper can check arbitrary transaction
  lists; and
- output-bank and beat-count artifacts are mostly transaction-list driven once
  read-data coverage admits a transaction set.

That is not enough for direct broadening. Multiple dynamic plus static shapes
need a selected public policy for dynamic-vs-dynamic ID uniqueness, dynamic
request mutual exclusion, dynamic-vs-static exclusions, and generated report
vocabulary. One dynamic plus more than two static transactions is probably a
smaller extension, but it still needs a public cap, sample naming, support
accounting, diagnostics, and residue vocabulary selected before
implementation.

## Selected Next Owner

Select `.317`, public contract selection for broader mixed dynamic/static
cardinality.

`.317` should decide the first public shape before any behavior changes. The
main candidates are:

- one dynamic transaction plus three concrete static transactions;
- two dynamic transactions plus one concrete static transaction; or
- a capped mixed set with at least one dynamic and at least one concrete
  static transaction, explicit maximum dynamic/static counts, pairwise
  distinct concrete static IDs, and explicit dynamic ID uniqueness rules.

The selection should also decide whether the next behavior-bearing ladder
starts with write response-demux, read single-beat response-demux, read
burst-last response-demux, scalar read-data, burst-length/runtime validation,
or multi-beat output banks. The existing project pattern suggests starting at
the response-demux boundary before widening read-data.

## Candidate Future Sample Stems

`.317` may accept, reject, or refine these candidates:

```text
ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static3_burst_last.ppif
```

No such sample is added by `.316`.

## Validation Strategy For Later Behavior

After `.317` selects a contract, the first behavior-bearing implementation
should use focused syntax checks, filtered t/1438 coverage, t/248 support
accounting if a public sample is added, direct schedule/check/semantic/HDL
probes where host memory permits, preservation filters for `.314`, `.312`,
`.307`, `.303`, `.299`, `.295`, `.291`, and `.268`, plus mdBook, Knowledge
Map, memory, diff, and doctrine gates.

Host-memory caveats remain relevant: broad fsmgen/prove probes should stay
behind `scripts/run_with_ram_guard.sh` and must not raise the default 88%
host-memory cutoff merely to force completion.

## Explicit Residue

Broader mixed dynamic/static cardinalities remain fail-closed until a future
behavior owner ships them. Same-cycle request widening, release-and-recapture,
dynamic same-ID queues, scoreboards, direct backend behavior,
backend-language variants, VHDL, profile aliases, queued/blocking policy, and
full-manager behavior remain separate exact owners.

## Rollback

Rollback is documentation-only: remove this audit note, remove its Knowledge
Map fact card, restore `.316` to pending, and restore Memory, README,
ROADMAP_V2, mdBook, and task-tree frontier pointers to the post-`.315` state.
