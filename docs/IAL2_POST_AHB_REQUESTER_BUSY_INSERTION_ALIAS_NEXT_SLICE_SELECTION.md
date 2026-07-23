# IAL2 Post-AHB Requester BUSY-Insertion Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.791`

Date: 2026-07-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.791` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.792`, a no-behavior readiness audit for a
bounded **paired requester/subordinate BUSY composition**. The target direction
is one generated AHB aggregate in which the shipped requester inserts its one
held `HTRANS=BUSY` presentation and the shipped HBURST-aware byte-lane
subordinate parks its `SEQ` context across that presentation.

Direct implementation is not selected. A current-state construction probe shows
that the aggregate generator can already compose the two shipped endpoint
behaviors and emit their review artifacts, but it also exposes a report-boundary
gap: `AhbInterconnect::_child_report` copies the requester child's `transfer`,
artifacts, and residue but not its optional `busy_insertion` report block. The
readiness audit must settle whether report propagation is a prerequisite and
freeze the exact public/runtime proof contract before a source is shipped.

This selector changes no parser, generator, public source, support-accounting,
test, generated artifact, HDL/runtime, direct-backend, verification-output,
backend-language, AXI/APB, broader AHB, or VHDL behavior. Decision `0020` and
the protocol-neutral transaction-layer horizon remain proposed/inactive until
the ongoing active work dries out.

## Evidence Read

The selector read:

- `.785`-`.790`, covering requester BUSY readiness, contract, behavior, and
  matching `.ahb` alias;
- the endpoint and aggregate BUSY-park `.ppif`/`.ahb` family from `.776`-`.784`;
- `ppif/ahb_requester_busy_insert.ppif` and its `.ahb` alias;
- `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif` and its alias;
- `AhbRequester`, `AhbSubordinate`, `AhbInterconnect`, and the PPIF adapter;
- focused requester and BUSY-park tests `t/1494`, `t/1496`, `t/1498`, `t/1512`,
  plus support/capability tests `t/248` and `t/297`;
- README, ROADMAP_V2, the AHB mdBook chapter and backlog, Knowledge Map, task
  tree, Memory, and relevant decisions.

## Why Paired Composition Is Next

The two endpoint behaviors now exist independently and through both public
containers:

```text
requester:   one BUSY before beat index 2, then resume that beat as SEQ
subordinate: park HBURST in-word SEQ context across BUSY
```

Their missing link is an end-to-end generated composition proof. That is smaller
and more coherent than broadening either behavior: it reuses the exact shipped
requester, subordinate, and interconnect machinery, stays within byte-only
`WRAP4`/`INCR4`, and needs no new arbitration, address progression, transfer
encoding, or BUSY policy.

A source-shape probe built from the one-subordinate aggregate BUSY-park source by
substituting the shipped BUSY requester contract. The current adapter accepted
the candidate and generated:

```text
amba_requester_busy_insert.isf
ahb_lite_subordinate_byte_lane_hburst_seq.isf
ahb_interconnect.isf

amba_requester_busy_insert.fsm
ahb_lite_subordinate_byte_lane_hburst_seq.fsm
ahb_interconnect.fsm
ahb_tb.fsm
```

The candidate requester child retained
`ahb_requester_busy_insert_support`; the subordinate child and aggregate
propagation both reported `parks_on = [busy]`. This proves that endpoint
generation and bus wiring are already composable in the current architecture.

## Report Boundary Found by the Probe

The same probe found that the aggregate schedule/report does not currently carry
the requester child's `busy_insertion` object. The standalone requester report
contains:

```text
busy_insertion.generated_behavior   = true
busy_insertion.htrans_busy_encoding = 2'b01
busy_insertion.before_beat          = 2
busy_insertion.beats                = single
```

However, `AhbInterconnect::_child_report` constructs a selected child view from
`source_object`, `target_protocol`, `bindings`, `transfer`, generated artifacts,
and unsupported residue, plus a bounded set of optional subordinate fields. It
does not copy `busy_insertion`. Generated behavior is present, but aggregate
introspection cannot yet state the requester's insertion contract.

This is not evidence that endpoint behavior is broken. It is a public reporting
and verification boundary that must be decided explicitly before the aggregate
is support-accounted. A composition claiming end-to-end BUSY behavior should
make both halves observable: requester insertion and subordinate parking.

## Selected `.792` Audit Scope

`.792` must audit and select the next contract owner for exactly one bounded
one-requester/one-subordinate composition. It must determine:

- the source path, intent/source-object names, support identity, coverage key,
  source kind, top module, and whether generic `.ppif` ships before `.ahb`;
- whether the source is a data-only derivative of
  `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif`, with only the
  requester block/child reference and BUSY transfer clauses changed;
- whether `AhbInterconnect::_child_report` must propagate the optional requester
  `busy_insertion` block, how that appears in schedule/check/semantic JSON, and
  the preservation boundary for all existing aggregate child reports;
- the exact end-to-end generated-HDL proof: command one byte `INCR4`, observe
  `NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`, prove that
  the subordinate does not clear or complete a data beat on BUSY, and prove four
  accepted beats plus correct final storage/status;
- report/residue movement, support-accounting and capability-surface impact,
  focused test naming, docs/mdBook/Knowledge Map updates, and rollback; and
- whether a two-subordinate sibling is deferred until after the one-subordinate
  proof (the expected smallest boundary).

The audit must not implement the source, report propagation, tests, generated
artifacts, or runtime behavior.

## Larger Alternatives Deferred

- Multi-beat, policy-driven, or runtime-selected requester BUSY control changes
  the requester contract and state instead of composing shipped behavior.
- A distinct `local-status.bus_busy` signal changes the public requester port
  surface and remains separate from the existing transaction-active `busy`.
- Halfword/word, wider, or indefinite burst `SEQ` depends on multi-word/
  register-bank progression beyond the shipped single-word byte window.
- Optional AHB signals, legacy two-bit subordinate `HRESP`, broader manager/
  interconnect features, direct backend, verification output, backend variants,
  AXI/APB, and VHDL are orthogonal or larger directions.

## Validation

Closeout is documentation-only, backed by current-state parsing/generation
probes and source inspection:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
rg -n 'sub _child_report|busy_insertion|parks_on' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind `scripts/run_with_ram_guard.sh` or equivalent monitoring.

## Rollback

Rollback is documentation-only: remove this selector and its Knowledge Map fact
card, restore `.791` as the active frontier, and revert the README, roadmap,
mdBook, task-tree, Memory, and generated Knowledge Map entries. No runtime
behavior is affected.
