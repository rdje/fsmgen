# IAL2 AHB Requester Exact-Two BUSY Event Contract Selection

Task-tree owner:
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.4`

Date: 2026-07-24

## Outcome

This slice selects the smallest public extension from the shipped exact-one
requester BUSY contract to exactly two qualified BUSY events at one literal
insertion point. The selected transfer syntax is:

```text
(transfer
  (idle 2'b00)
  (busy 2'b01)
  (nonseq 2'b10)
  (seq 2'b11)
  (first-beat nonseq)
  (later-beats seq)
  (advance-on ready)
  (busy-before-beat 2)
  (busy-beats 2))
```

`busy-before-beat` continues to select the zero-based pending `SEQ` beat.
`busy-beats 2` selects exactly two rising events where:

```text
HGRANT && HREADY && HTRANS == 2'b01
```

The two events are normally consecutive qualified clocks inside one contiguous
BUSY episode. Ready-low or grant-low clocks do not consume the count. Address,
control, write data, beat index, and remaining data-beat count stay stable
through the whole episode. After the second event, the same pending transfer is
presented as `SEQ`; neither BUSY event completes a data beat or consumes a
response.

This contract selection changes no parser, generator, source, report, support,
artifact, HDL, runtime, backend, AXI, APB, or VHDL behavior. Implementation is
owned by
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.5`.

## Why A Separate `busy-beats` Clause

The existing `(busy-before-beat N)` has one stable responsibility: choose the
pending transfer before which BUSY is inserted. Overloading it with a second
positional scalar would conflict with the PPIF literal-block convention that
each clause carries one scalar and would make diagnostics less precise.

The selected `(busy-beats 2)` clause:

- sits in the existing transfer block beside the insertion point;
- aligns with the existing `busy_insertion.beats` report key;
- keeps old sources canonical: absence means the already-shipped exact-one
  contract and still reports `beats: single`;
- makes the event count explicit without adding policy, runtime, or random
  throttling; and
- leaves room for a later separately selected bounded general count without
  promising it now.

The legacy word `beats` denotes qualified BUSY bus events, not raw clocks and
not changes of `HTRANS`. Current exact-one documentation and runtime tests
already establish that meaning.

## Bounded Parser And Normalization Contract

`PPIF.pm` adds `busy-beats` to the optional AHB requester transfer literals and
records it as `transfer.busy_beats`. `AhbRequester::_normalize_transfer`
accepts only the exact literal integer `2` in this first extension.

The selected fail-closed rules are:

- `busy-beats` requires both `(busy 2'b01)` and `busy-before-beat`;
- absence of `busy-beats` is the canonical exact-one spelling;
- literal `0`, `1`, values above `2`, symbols, expressions, references, and
  other non-literals are rejected;
- duplicate `busy-beats` clauses retain the existing literal-block duplicate
  diagnostic; and
- all existing `busy-before-beat` constraints remain: literal `1..15`, BUSY
  encoding exactly `2'b01`, and safe no-op when the runtime burst never reaches
  the insertion index.

The intentionally exact-two validation avoids presenting a generalized count
range before resource limits, reporting, and broader protocol policy are
selected.

## Additive Public Source

`.5` adds only the generic source:

```text
path:          ppif/ahb_requester_busy_insert_two.ppif
intent:        ahb_requester_busy_insert_two
source object: fsmgen-ahb-requester-busy-insert-two
actor/module:  amba_requester_busy_insert_two
IAL1:          amba_requester_busy_insert_two.isf
IAL0:          amba_requester_busy_insert_two.fsm
support id:    intent.ppif_ahb_requester_busy_insert_two
coverage:      ial2_ppif_ahb_requester_busy_insert_two_pipeline_cli
source kind:   ppif
```

The source is the current exact-one `.ppif` requester with distinct identity
and the single added `(busy-beats 2)` clause. It reuses the existing
`AhbRequester` generator; it is not a new generator.

The matching `.ahb` alias and paired one-/two-subordinate exact-two sources are
not part of `.5`. Current exact-one `.ppif`/`.ahb` requester and paired sources
remain preservation gates. A later clean selector may add the obvious alias
and composition surfaces after direct exact-two requester behavior ships.

At the current baseline, one additive generic supported-smoke/strict fixture
moves protocol fixtures from 314 to 315 and supported-smoke/strict entries from
355 to 356. The AHB IAL2 source inventory moves from 38 to 39 paths.

## Event-Owned Generated IAL1 Contract

Existing sources without `busy_beats` retain the current exact-one generated
IAL1 shape. The exact-two branch adds one actor-owned storage variable:

```text
(var ahb_busy_remaining_q (width 2) (reset 0))
```

It resets/initializes to zero for each command. At the selected insertion point,
the transaction sets `ahb_busy_remaining_q` to `2` before driving BUSY and
marks existing `busy_inserted_q=1`. Initializing before BUSY becomes visible is
required so the first qualified BUSY edge cannot observe a zero count.

Two semantically disjoint concurrent rules own retirement:

1. **Non-final BUSY event:** when grant, ready, and BUSY are qualified and
   `ahb_busy_remaining_q > 1`, decrement the counter and leave BUSY active.
2. **Final BUSY event:** when grant, ready, and BUSY are qualified and
   `ahb_busy_remaining_q == 1`, clear the counter, set existing
   `ahb_address_pending_q=1`, and drive `HTRANS=SEQ`.

The final acceptance rule and non-final continuation rule both keep priority
over `ahb_request`. The final rule also has an explicit priority over the
non-final rule because the current conflict checker does not prove the `== 1`
and `> 1` guards disjoint. The exact-two transaction uses an outer
`HTRANS==BUSY` continue gate so it cannot schedule the normal `SEQ` path while
either event remains. The existing no-grant behavior and the BUSY gate hold the
pending presentation through grant/ready stalls.

Existing `busy_inserted_q` remains necessary after the counter reaches zero so
the same beat index cannot reinitialize the count. No new response, data,
address, command, or status owner is introduced.

### Implementation correction recorded by `.5`

The `.4` selection initially described `ahb_busy_remaining_q` as a transaction
local. Direct implementation proved concurrent retirement rules require the
counter in actor-owned storage. Strict checking also requires the explicit
`ahb_busy_accept over ahb_busy_continue` priority because guard disjointness is
not inferred. `.5` therefore uses the storage and priority shape shown above.
The public syntax, qualified-event semantics, report, resource width, and
runtime contract selected by `.4` are unchanged.

## Report And Residue Contract

The exact-one report stays byte-for-byte compatible in shape and value:

```text
busy_insertion.before_beat = 2
busy_insertion.beats       = single
```

The new exact-two source reports:

```text
busy_insertion.generated_behavior   = true
busy_insertion.htrans_busy_encoding = 2'b01
busy_insertion.before_beat          = 2
busy_insertion.beats                 = 2
```

`beats` is therefore a bounded union of legacy string `single` and the newly
supported integer `2`; existing reports do not change type or value. No new
event-qualification field is added because the current canonical contract
already defines grant-and-ready qualification.

The existing `ahb_requester_busy_insert_support` residue ID remains. Its detail
becomes source-specific and truthful: exact-one reports name the separate
exact-two source, exact-two reports name the shipped two-event subset, and both
defer counts beyond two, policy/runtime/random throttling, and multiple
insertion points. Base requesters still omit the residue entirely.

No distinct `local-status.bus_busy` port is added; bus-visible `HTRANS` remains
the observation surface and existing `local-status.busy` continues to mean
transaction in progress.

## Selected Regression Contract

New focused test `t/1521-ial2-ahb-requester-two-busy-insert.t` owns source,
parser, report, support, CLI/artifact, and generated-HDL behavior. Its public
runtime harness must keep generated selector assertions enabled and run one
compiled requester through:

| Scenario | Held clocks | Qualified BUSY events | Data beats |
|---|---:|---:|---:|
| continuously qualified | 0 | 2 | 4 |
| ready low after first visible BUSY | 32 | 2 after release | 4 |
| grant low after first visible BUSY | 32 | 2 after release | 4 |

Every scenario requires one BUSY transition episode, stable pending fields and
counters, zero BUSY data completions, the same resumed `SEQ`, four completed
data beats, and zero remaining. The harness must count every qualified BUSY
edge and must not inspect generated state numbers.

Malformed tests cover missing insertion/BUSY prerequisites, literals
`0`/`1`/`3`, non-literal input, and duplication. CLI gates cover strict check,
schedule JSON, outdir, semantic JSON, and `--verify-hdl`.

Preservation requires current base requester t/1473, exact-one generic t/1498,
exact-one alias t/1512, paired generic/alias t/1513-t/1516, current-surface
t/1518, phase t/1519/t1520 as warranted, t/248/t/297 accounting/capability,
and byte-identical current exact-one generated IAL1/IAL0/HDL apart from the
selected source-specific support-residue text. Broad commands remain under the
4-GiB descendant RSS cap.

## Explicit Deferrals

Literal BUSY counts other than one/two, generalized count width, multiple
insertion points, runtime-selected counts/points, policy/random throttling,
distinct local bus-BUSY status, exact-two `.ahb` alias and paired compositions,
larger/broader bursts, optional AHB signals, managers, queues/outstanding
transfers, direct seeds/backends, verification-output generation, backend
variants, AXI/APB changes, VHDL, the separate interconnect selector repair, the
separate generic output-priority repair, and decision 0020 remain deferred.

## Follow-On Alias Selection

After `.5` shipped and verified the generic exact-two behavior, `.6` selected
the byte-identical matching `.ahb` profile-alias contract. The alias remains
unshipped until `.7`; its current contract is
`docs/IAL2_AHB_REQUESTER_EXACT_TWO_BUSY_EVENT_PROFILE_ALIAS_CONTRACT_SELECTION.md`.

## Rollback

Before implementation, rollback removes this selection record/fact and returns
the active frontier to exact-two contract selection. After `.5`, rollback must
remove the additive source/support/test and conditional `busy_beats` parser/
counter branch together, restore exact-one residue text/accounting/inventory,
and leave the shipped exact-one requester repair untouched.
