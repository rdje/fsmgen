# IAL2 AHB Paired BUSY Composition Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.792`

Date: 2026-07-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.792` confirms that one bounded aggregate
can directly reuse the shipped AHB requester BUSY-insertion and subordinate
BUSY-parking machinery. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.793`, a no-behavior public contract
selection for the paired source, its aggregate report surface, and its exact
generated-HDL proof.

No lower-layer parser, endpoint generator, interconnect wiring, composition-top,
or HDL substrate repair is required. Direct implementation is not selected in
this audit because the public source/identity and report/test contract still
need to be frozen. In particular, the aggregate must expose the requester
child's existing `busy_insertion` metadata instead of silently dropping it.

This audit changes no parser, generator, public source, support-accounting,
test, generated artifact, HDL/runtime, direct-backend, verification-output,
backend-language, AXI/APB, broader AHB, or VHDL behavior. Decision `0020` and
the protocol-neutral transaction-layer horizon remain proposed/inactive until
the ongoing active work dries out.

## Evidence Read and Reverified

The audit read `.791`, the complete `.776`-`.790` BUSY lineage, both endpoint
sources and aliases, the aggregate BUSY-park sources and aliases,
`AhbRequester`, `AhbSubordinate`, `AhbInterconnect`, the PPIF adapter,
support/language/capability surfaces, focused tests `t/1494`, `t/1496`,
`t/1498`, and `t/1512`, support tests `t/248` and `t/297`, README, ROADMAP_V2,
the AHB mdBook chapter and backlog, Knowledge Map, task tree, Memory, and
relevant decisions.

The audit also:

- constructed the candidate one-subordinate contract in memory from
  `ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif` by substituting
  the shipped `amba_requester_busy_insert` requester and its `(busy 2'b01)` /
  `(busy-before-beat 2)` transfer clauses;
- parsed and generated that candidate through the existing aggregate path;
- inspected the resulting artifacts, child reports, aggregate propagation, and
  residue; and
- generated the current aggregate HDL to confirm the top-level command/status
  ports and deterministic internal bus/child observation points available to a
  focused runtime harness.

## Source and Generation Readiness

The candidate uses the existing one-requester/one-subordinate static-window
aggregate shape. The only source-data differences from the shipped aggregate
BUSY-park sample are:

1. requester object `amba_requester` becomes
   `amba_requester_busy_insert`;
2. requester `transfer` adds `busy = 2'b01` and
   `busy-before-beat = 2`; and
3. the interconnect requester child reference names
   `amba_requester_busy_insert`.

The PPIF adapter already routes the inlined requester through
`AhbRequester`. `AhbInterconnect::generate` already clones the requester
contract, invokes `AhbRequester`, invokes the BUSY-parking subordinate through
`AhbSubordinate`, builds the interconnect, and composes the top. The candidate
therefore generates the exact expected review artifacts:

```text
IAL1:
  amba_requester_busy_insert.isf
  ahb_lite_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert.fsm
  ahb_lite_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

HDL entry/module:
  ahb_tb.fsm / ahb_tb
```

The requester child keeps `transfer.busy = 2'b01`,
`transfer.busy_before_beat = 2`, and
`ahb_requester_busy_insert_support`. The subordinate child keeps
`seq_policy.parks_on = [busy]`, and
`composition.seq_policy_propagation` clones that parked policy. No bus binding
changes: requester `HTRANS`, address/control/data, and interconnect ready/
response continue to feed the subordinate through the existing deterministic
wiring.

## Aggregate Report Gap and Minimal Repair

The standalone requester report includes:

```text
busy_insertion.generated_behavior   = true
busy_insertion.htrans_busy_encoding = 2'b01
busy_insertion.before_beat          = 2
busy_insertion.beats                = single
```

The candidate aggregate child report does not. The cause is local and explicit:
`AhbInterconnect::_child_report` copies `source_object`, `target_protocol`,
`bindings`, `transfer`, generated artifacts, and residue, then conditionally
copies `narrow_transfer_policy`, `burst`, `response`, and `output_defaults`.
It has no conditional copy for `busy_insertion`.

The minimal repair is additive:

```text
if child result report has busy_insertion:
    clone it into the aggregate child report
```

That changes only aggregates containing a BUSY-inserting requester. Existing
base-requester aggregates have no `busy_insertion` field and remain structurally
unchanged. No new top-level summary is mechanically required: requester-child
`busy_insertion` plus subordinate/aggregate `parks_on = [busy]` exposes both
ends of the paired behavior. `.793` must decide whether that two-part shape is
the selected first-slice contract or whether a small composition-level summary
is warranted.

## Generated-HDL Proof Is Feasible

The generated `ahb_tb` top already exposes all command and completion signals
needed to drive the transaction:

```text
inputs:  cmd_valid, cmd_write, cmd_addr, cmd_wdata, cmd_wdata_step,
         cmd_size, cmd_prot, cmd_lock, cmd_burst, cmd_len, wait_cycles
outputs: cmd_ready, busy, beat_done, done, burst_active, wrap_active,
         beat_index, beats_remaining, active_addr, active_hburst,
         last_error, last_retry, last_split, last_resp, last_read_data
```

The structural top also gives the focused test deterministic hierarchical
observation points without adding user ports:

```text
dut.comp_link_requester_HTRANS
dut.comp_link_requester_HADDR / HWRITE / HSIZE / HBURST / HWDATA
dut.comp_link_interconnect_HREADY / HRESP
dut.regs.seq_valid_q / seq_expected_addr_q / seq_beats_remaining_q
dut.regs.reg_data_q
```

A first-slice runtime proof can command a byte `INCR4` with zero wait cycles and
check:

1. `NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)`;
2. BUSY holds the requester's pending address/control/data and counters;
3. the subordinate's `seq_valid_q`, expected address, and remaining count hold
   across BUSY, with no register write or accepted data beat on that cycle;
4. resumed `SEQ` consumes the same pending beat and continues the parked burst;
5. exactly four data beats complete, `beats_remaining` reaches zero, response
   status is OKAY, and final storage matches the four byte writes; and
6. base requester, standalone BUSY requester, endpoint BUSY park, aggregate
   BUSY park, aliases, and existing child reports remain green.

Using `cmd_wdata = 32'h11111111` and
`cmd_wdata_step = 32'h11111111` makes the four little-endian byte writes
observable as final register value `32'h44332211`.

## Why Contract Selection Still Comes First

The mechanics are ready, but these public choices remain open:

- exact source path, intent name, source-object anchor, and whether the name
  emphasizes requester insertion, subordinate parking, or paired BUSY flow;
- support identity and coverage key;
- whether the first slice ships generic `.ppif` only and sequences `.ahb` later
  (recommended for consistency), or ships both together;
- whether child-level `busy_insertion` + aggregate `parks_on` is sufficient or
  a composition-level paired-BUSY summary is added;
- exact focused test and testbench names, assertions, counts, and preservation
  matrix; and
- whether the two-subordinate sibling is deferred (recommended smallest scope).

Those are contract choices, not substrate blockers, so `.793` owns them before
implementation.

## Selected `.793` Scope

`.793` must select the exact public contract for one bounded generic `.ppif`
paired BUSY composition. It must freeze:

- source/intent/source-object/support/coverage names, expected module
  `ahb_tb`, semantic root `top`, and generated artifact list;
- the exact data delta from the shipped one-subordinate aggregate BUSY-park
  source and preservation of all existing sources;
- aggregate requester-child `busy_insertion` propagation, including whether a
  composition-level paired summary is selected;
- top residue movement and the explicit remaining broader-BUSY/burst/alias
  deferrals;
- generated-HDL test shape and stable observation points, including the
  `32'h44332211` final-storage proof or an evidence-backed alternative;
- support-accounting/capability/language surface, expected count increments,
  diagnostics, docs/mdBook/Knowledge Map, rollback, and preservation gates;
- generic `.ppif` before matching `.ahb`; and
- one subordinate only, with the two-subordinate sibling deferred unless the
  contract proves that pairing it is equally bounded and independently useful.

`.793` remains no-behavior and must not implement the contract.

## Explicit Deferrals

The matching `.ahb` alias, two-subordinate paired composition, multi-beat/
policy/runtime BUSY, distinct local bus-BUSY status, halfword/word or wider/
indefinite bursts, multi-word/register-bank progression, optional AHB signals,
legacy two-bit subordinate `HRESP`, broader manager/interconnect behavior,
scoreboards, direct backend, verification output, backend variants, AXI/APB,
and VHDL remain deferred.

## Validation

Closeout is documentation-only plus the current-state source/report/top probes:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester_busy_insert.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
rg -n 'sub _child_report|busy_insertion|sub _top_port_specs|comp_link_requester_HTRANS' perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm
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

Rollback is documentation-only: remove this audit and its Knowledge Map fact,
restore `.792` as the active frontier, and revert README, roadmap, mdBook,
task-tree, Memory, and generated Knowledge Map entries. No runtime behavior is
affected.

## Contract Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.793` now selects `.794`, direct
implementation of
`ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif`.
The selected report uses requester-child `busy_insertion` plus existing
aggregate `parks_on = [busy]` without a duplicated top summary; focused t/1513
and its Verilator harness own the exact end-to-end proof. The canonical contract
is `docs/IAL2_AHB_PAIRED_BUSY_COMPOSITION_CONTRACT_SELECTION.md`.
