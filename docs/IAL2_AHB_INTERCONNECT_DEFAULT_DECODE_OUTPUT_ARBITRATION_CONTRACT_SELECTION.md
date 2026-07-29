# IAL2 AHB Interconnect Default/Decode Output-Arbitration Contract Selection

Task-tree owner:
`IAL2-AHB-INTERCONNECT-DEFAULT-DECODE-OUTPUT-ARBITRATION.2`

Date: 2026-07-29

## Outcome

The selected repair is local to the generated IAL0 authored by
`FSM::IAL2::ProtocolIntent::AhbInterconnect`. It replaces overlapping output
defaults with explicit, mutually exclusive arbitration modes. Generic
lowered-RTL selector analysis and generated `onehot0` assertions remain
unchanged.

Child `.3` owns implementation and is active after clean contract commit
`3883c3a0d`. This contract slice changes no
parser, generator, public source, support identity, report/schema, review
artifact, semantic/MCP API, HDL, runtime, backend, protocol, VHDL, or
transaction-layer behavior.

An assertion-enabled feasibility probe also found a separate generated AHB
subordinate overlap after only the interconnect assertion block was
suppressed. Consequently, `.3` will prove the interconnect directly with its
assertions enabled but will not remove `--no-assert` from the paired aggregate
family. Proposed task
`IAL2-AHB-SUBORDINATE-DEFAULT-PHASE-OUTPUT-ARBITRATION` owns the newly exposed
endpoint audit.

## Selected Per-Window Arbitration

For each subordinate window, the interconnect must emit exactly two
complementary address/select modes in `idle`:

```text
mapped hit for this window:
  HSEL_*  <- 1
  HADDR_* <- local_address

not this window's mapped hit:
  HSEL_*  <- 0
  HADDR_* <- 0
```

The not-hit predicate is the logical inverse of that window's current mapped
hit predicate, including active-transfer qualification. One-window and
two-window generation use the same loop-derived form. No source-order priority
is introduced between windows, and the existing overlap-reject address-map
validation remains authoritative.

The current redundant subordinate select/address zero assignments inside the
first-cycle unmapped block are removed: every window is already in its not-hit
mode there. The `unmapped_error_complete` state retains unconditional zero
select/address assignments because that state is exclusive from `idle`.

This preserves:

- the exact static decode windows;
- zero-base local address passthrough and nonzero-base subtraction;
- the current non-`IDLE` transfer classification, including `BUSY`;
- selected and unselected subordinate visibility; and
- all generated port, signal, artifact, and module names.

## Selected Global Response Arbitration

`HREADY`, `HRESP`, and `HRDATA` use three exclusive mode families in `idle`:

1. one retained data-phase owner;
2. an interconnect-owned first-cycle unmapped error with no retained owner;
3. an ordinary default with neither a retained owner nor an unmapped address.

The exact ordinary-default predicate is:

```text
(! any_owner) && (! unmapped_address)
```

The existing first-cycle unmapped predicate remains:

```text
unmapped_address && (! any_owner)
```

The values remain unchanged:

| Mode | `HREADY` | `HRESP` | `HRDATA` |
| --- | --- | --- | --- |
| retained owner `N` | `HREADYOUT_N` | subordinate OKAY/ERROR mapped to requester `2'b00`/`2'b01` | `HRDATA_N` |
| unmapped first cycle | `0` | `2'b01` | `0` |
| ordinary default | `1` | `2'b00` | `0` |

Each owner block remains independently conditioned by its owner bit. The
repair must not encode priority between owner bits: an impossible multiple-
owner state must still activate multiple selector families and trip the
existing generated assertions.

## Preserved Phase And Error Semantics

The repair does not change:

- fixed `HGRANT=1` or the input-visibility guard;
- owner capture on an accepted mapped active address phase;
- owner hold through subordinate wait states;
- owner clear on completion without replacement;
- same-edge completion plus accepted mapped-address replacement;
- `next_state` generation;
- the `unmapped_error_complete` state's second-cycle ready/ERROR response;
- subordinate one-bit ERROR to requester two-bit ERROR mapping; or
- wait, data, response, and requester feedback behavior.

The existing mapped-owner-to-unmapped boundary remains intentionally outside
this repair. While a retained owner is completing, a simultaneous new
unmapped address is not promised to enter the interconnect-owned unmapped
sequence. This contract neither broadens nor silently changes that documented
non-promise.

## Paired Assertion Feasibility Result

The contract-selection probe generated the shipped one-window paired source
into a repository-local disposable workspace. It changed only the generated
`ahb_interconnect` assertion preprocessor guard in the disposable HDL, leaving
requester and subordinate assertions enabled, then compiled the existing
`ahb_paired_busy_composition_tb` without `--no-assert`.

The runtime stopped at cycle 345 in `dut.regs`:

```text
selector same-value conflict: HRDATA_REGS 0 enables=01100000
```

For the emitted assertion's ordered eight-source vector, `01100000` means
exactly these two sources were active:

```text
ahb_lite_byte_lane_hburst_seq_access_idle_0: HRDATA_REGS <- 0
ahb_phase_capture:                              HRDATA_REGS <- 0
```

The source trace is generator-local to `AhbSubordinate.pm`: the generated
transaction idle state carries the interface output default, while the
generated `ahb_phase_capture` rule redundantly writes the same zero value on
the first selected ready active phase. The generic emitter correctly reports
the two independently enabled same-value selectors. This finding is
independent of the interconnect overlap and is not repaired or masked here.

The probe establishes that removing `--no-assert` from t1513-t1516, t1523,
and t1525 in the interconnect slice would simply expose a different failure.
Those tests therefore retain their existing compile boundary until the
separate subordinate audit maps its complete output set and selects the
correct owner.

## Future Implementation Gate

Active `.3` must:

1. change only the generated interconnect IAL0 shape in
   `AhbInterconnect.pm`;
2. update t1478/t1480 structural expectations for explicit not-hit and
   ordinary-default predicates;
3. add focused t1530 plus task-owned SystemVerilog harness data;
4. instantiate the generated one-window and two-window `ahb_interconnect`
   modules directly so unrelated endpoint assertion gaps cannot be hidden or
   conflated;
5. compile without `--no-assert` and prove mapped address zero, mapped
   nonzero/local translation, ordinary success, retained-owner wait,
   subordinate ERROR, first/second-cycle unmapped ERROR, status/control
   selection, and same-edge mapped owner replacement;
6. retain every paired runtime's current `--no-assert` option and rerun the
   exact-one/exact-two generic/alias one-/two-subordinate family as functional
   preservation; and
7. prove unchanged public source bytes, ports, support/accounting, report
   schemas and payloads, exact IAL1/IAL0 artifact names, normalized semantic
   JSON, read-only MCP behavior, and mdBook examples.

Focused validation includes t1478, t1480, t1530, t1513-t1516, t1523, t1525,
t1518, t248, t297, syntax, strict/check/schedule/artifact/verifier,
semantic/MCP, Knowledge Map, mdBook, memory/path/diff, and doctrine gates as
warranted by the implementation blast radius.

All broad or heavyweight commands use repository-derived same-volume
temporary paths and the unchanged 88% host / 4096-MiB descendant RAM guard.
The feasibility run was admitted at 70.9% for its definitive runtime. Earlier
attempts were safely refused when external compiler pressure put the host
above the fixed cutoff. The exact disposable workspace contained 45 files and
53,032,662 bytes; it was deleted after evidence capture and a residue census
returned none.

## Non-Selections

This contract does not select:

- weaker or disabled generic selector assertions;
- source-order masking of multiple owners;
- generic FSM output-priority lowering;
- the proposed ISF rule/transaction priority owner;
- AHB subordinate output-arbitration repair;
- mapped-owner-to-unmapped expansion;
- new public syntax, signals, windows, queues, managers, protocols, backends,
  or VHDL behavior; or
- decision 0020.

## Rollback

Rollback of `.3` must restore the old generated interconnect IAL0 and its
focused assertion-enabled expectations together. It must not weaken or remove
generic selector assertions, alter endpoint behavior, or claim that the
paired `--no-assert` boundary has been retired.
