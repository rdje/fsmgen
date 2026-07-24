# IAL2 AHB Paired BUSY Composition `.ahb` Profile Alias Behavior

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.796`

Date: 2026-07-23

## Outcome

FSMGen ships the bounded paired AHB BUSY composition through both public IAL2
source surfaces:

```text
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
```

The files are byte-identical. The `.ppif` suffix is the generic
Protocol/Platform Intent container; `.ahb` is the protocol-profile alias. They
are not separate generators. Both enter the same PPIF adapter, select the same
AHB requester/subordinate/interconnect generators, and follow the same mandatory
lowering chain:

```text
IAL2 source (.ppif or .ahb)
  -> amba_requester_busy_insert.isf
   + ahb_lite_subordinate_byte_lane_hburst_seq.isf
   + ahb_interconnect.isf
  -> amba_requester_busy_insert.fsm
   + ahb_lite_subordinate_byte_lane_hburst_seq.fsm
   + ahb_interconnect.fsm
   + ahb_tb.fsm
  -> SystemVerilog module ahb_tb
```

## Shared Behavior

Both surfaces describe one requester, one zero-base four-byte interconnect
window, and one HBURST-aware byte-lane subordinate. The requester inserts one
held `HTRANS=BUSY` presentation before beat index two. The subordinate parks
its byte-only `INCR4`/`WRAP4` in-word `SEQ` context across BUSY.

The shared report exposes the two ends independently:

```text
children[0].busy_insertion:
  generated_behavior: true
  htrans_busy_encoding: 2'b01
  before_beat: 2
  beats: single

children[2].transfer.seq_policy.parks_on: [busy]
composition.seq_policy_propagation.subordinates[0].seq_policy.parks_on: [busy]
```

There is no duplicate top-level `busy_flow` summary. The requester-child block
states what is driven; the subordinate/aggregate block states how it is
received.

t/1513 remains the shared generated-HDL runtime proof. It observes:

```text
NONSEQ(0) -> SEQ(1) -> BUSY(2 held) -> SEQ(2 resumed) -> SEQ(3)
```

and proves one BUSY transition episode, four data beats, held requester/
subordinate state and storage, OKAY completion, zero remaining beats, and final
register value `32'h44332211`. It does not count every ready-qualified BUSY
edge; the alias inherits the current requester `beats=single` cardinality
contradiction recorded by
`IAL2-AHB-REQUESTER-MULTI-BUSY-INSERTION-READINESS-AUDIT.1` until the selected
single-event repair ships.

## Alias-Only Difference

The `.ahb` suffix requires explicit `(profile ahb)` and activates the existing
profile-alias residue cleanup. Relative to the generic `.ppif` report, the alias
removes only:

- top `ahb_aggregate_profile_alias_deferred`;
- requester-child `ahb_profile_alias_deferred`;
- subordinate-child `ahb_subordinate_profile_alias_deferred`; and
- `.ahb alias exposure` wording inside the remaining burst residue.

It preserves `ahb_requester_busy_insert_support`, the bounded
`ahb_burst_seq_support_deferred` residue, generated artifacts, child count,
module, BUSY metadata, and runtime behavior. Non-AHB profiles and missing
explicit profiles still fail closed.

## Support Accounting

```text
support id:
  intent.ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park

coverage:
  ial2_ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli

family:         protocol_fixture
classification: supported_smoke
source kind:    ial2_profile_alias
strict:         true
HDL module:     ahb_tb
child count:    3
semantic root:  top
```

The support corpus now contains 312 protocol fixtures and 353
supported-smoke/strict entries.

## Public Inventory Reconciliation

While adding the alias, `.796` reconciled the AHB chapter's enumerated source
list against the tracked `ppif/ahb*.(ppif|ahb)` inventory. The list had omitted
three already-shipped entries even though their detailed sections were present:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb
ppif/ahb_requester_busy_insert.ppif
ppif/ahb_requester_busy_insert.ahb
```

Git history traces those omissions to their `.778`, `.788`, and `.790`
shipments. `.796` restores them and the new paired alias in the canonical list
and lowering map, so the chapter now accurately enumerates all 36 shipped AHB
IAL2 source paths. This is a documentation repair only; the sources, support
catalog, and behavior were already present.

## Use It

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb

./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb

./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb

./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
```

Use the `.ppif` path instead when a protocol-neutral generic container is more
appropriate. The generated module and bus behavior are identical.

## Verification

t/1514 proves byte parity; parse, strict check, schedule JSON, semantic JSON,
outdir, HDL, and support surfaces; generated IAL1/IAL0 parity; BUSY insertion
and parking reports; alias-only residue cleanup; malformed profile diagnostics;
and clean alias `--verify-hdl`.

t/1513 retains the shared runtime proof, while t/1512 and t/1497 preserve the
requester-only and aggregate-BUSY-park alias families.

## Explicit Deferrals

The generic two-subordinate paired source and its matching `.ahb` alias now
ship as documented in
`docs/IAL2_AHB_TWO_SUBORDINATE_PAIRED_BUSY_COMPOSITION_PROFILE_ALIAS_BEHAVIOR.md`.
Multi-beat/policy/runtime BUSY, a distinct local bus-BUSY status,
general/deeper request or response queues and multiple outstanding transfers,
halfword/word or wider/indefinite burst progression, multi-word/register-bank
behavior, optional AHB signals, legacy two-bit subordinate `HRESP`, broader
manager/interconnect behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, and VHDL remain
deferred. Decision `0020` and all proposed audits remain inactive.

The alias shares the depth-one active-phase pipeline documented in
`docs/IAL2_AHB_PIPELINED_ACTIVE_TRANSFER_REPAIR.md`; it is not a separate
generator.
