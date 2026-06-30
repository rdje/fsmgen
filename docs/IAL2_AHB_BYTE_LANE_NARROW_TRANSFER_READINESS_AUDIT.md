# IAL2 AHB Byte-Lane/Narrow-Transfer Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.735`

Date: 2026-06-30

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.735` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.736`, a no-behavior public contract
selection for the first bounded AHB byte-lane and narrow-transfer subordinate
source.

The audit changes no parser behavior, generator behavior, public source sample,
support-accounting catalog, capability manifest, focused test behavior,
schedule/check/semantic JSON behavior, generated artifact, HDL/runtime
behavior, direct backend behavior, verification-output generation,
backend-language variant, AXI behavior, APB behavior, broader AHB behavior, or
VHDL behavior.

## Current Boundary

The shipped public subordinate sources remain word-only:

```text
ppif/ahb_lite_subordinate.ppif
ppif/ahb_lite_subordinate.ahb
```

The lower-layer seed remains:

```text
fsm/ahb_lite_subordinate.fsm
```

Current subordinate behavior starts only selected `NONSEQ` transfers, accepts
only 32-bit word size (`HSIZE == 3'b010`) at address `0`, ignores `IDLE` and
`BUSY`, and returns two-cycle ERROR for `SEQ`, unsupported sizes, and unmapped
addresses. Current aggregate interconnect sources forward the relevant AHB
signals but should not be the first implementation target for byte-lane
semantics:

```text
HADDR
HSIZE
HWRITE
HWDATA
HRDATA
```

The current implementation already has a small, explicit word-only policy
boundary in the AHB subordinate generator and direct seed:

```text
NONSEQ && HSIZE == 3'b010 && HADDR == 0
```

That makes byte-lane/narrow-transfer work suitable for a public contract
selection leaf before behavior changes.

## Readiness Decision

No lower-layer generated-IAL1/IAL0 substrate repair, source-fact cleanup,
report-schema cleanup, or support-accounting cleanup is required before a
contract selector.

The next leaf should select a new public generic `.ppif` subordinate source,
not mutate the already shipped word-only `ppif/ahb_lite_subordinate.ppif` or
its `.ahb` alias. A likely implementation source path is:

```text
ppif/ahb_lite_subordinate_byte_lane.ppif
```

`.736` must either confirm that exact path or record a stronger exact path
before selecting an implementation owner. Matching `.ahb` alias support and
aggregate/interconnect byte-lane propagation should stay deferred until the
generic subordinate contract is selected and shipped.

## Selected Contract Questions For `.736`

The first bounded contract should stay on the existing 32-bit, single-register,
AHB-Lite/common-AHB subordinate shape and settle these points before any
generator behavior changes:

- accepted sizes: byte (`HSIZE == 3'b000`), halfword (`HSIZE == 3'b001`), and
  word (`HSIZE == 3'b010`);
- rejected sizes: every larger or unsupported `HSIZE` encoding;
- byte lane: `HADDR[1:0]`;
- halfword lane: `HADDR[1]` with `HADDR[0] == 0`;
- word alignment: `HADDR[1:0] == 0`;
- selected storage word: `HADDR[31:2] == 0`;
- byte writes update only the selected byte in `reg_data_q`;
- halfword writes update only the selected adjacent two-byte lane group;
- word writes update the full `reg_data_q`;
- byte and halfword reads drive the active lane bits from `reg_data_q` and
  zero-fill inactive `HRDATA` lanes for deterministic fixture behavior;
- word reads drive the full `reg_data_q`;
- unaligned halfword accesses, unaligned word accesses, outside-word accesses,
  and any access that would cross the selected storage word fail closed with
  the existing two-cycle ERROR policy;
- ERROR completion keeps `HRDATA` zero and performs no write update;
- wait-cycle behavior, output reset/default behavior, ignored `IDLE`/`BUSY`,
  unsupported `SEQ`, and one-bit subordinate `HRESP` remain as shipped.

The active-byte-lane fact comes from the imported AHB source inventory; the
zero-fill inactive-lane policy is a selected FSMGen fixture determinism rule
for this first public source, not a claim that inactive lanes are
architecturally meaningful.

## Report And Support Expectations

`.736` should settle a new support-accounting identity and focused coverage
name for the selected generic source. The likely shape is:

```text
entry_id: intent.ppif_ahb_lite_subordinate_byte_lane
coverage: ial2_ppif_ahb_lite_subordinate_byte_lane_pipeline_cli
source_kind: ppif
schema: fsmgen.ial2.protocol_intent.ahb_subordinate.v1
```

The report should make the selected narrow-transfer policy explicit, including
accepted size encodings, lane-selection policy, alignment/crossing ERROR
policy, deterministic read projection, and no-write-on-ERROR behavior.

Residue movement should remove byte-lane/narrow-transfer residue only from the
new selected byte-lane source after implementation. The existing word-only
sources should keep their current behavior and residue unless a later owner
explicitly migrates them.

## Validation Scope

`.736` should require the later implementation leaf to include:

```text
perl -Iperl -c perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm
prove -v t/1482-ial2-ahb-subordinate-byte-lane.t
prove -v t/1475-ial2-ahb-subordinate.t
prove -v t/1476-ial2-ahb-subordinate-profile-alias.t
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane.ppif
./bin/fsmgen --quiet --strict --emit-semantic-json ppif/ahb_lite_subordinate_byte_lane.ppif
```

Broader support-accounting and capability-manifest gates should run when the
implementation adds catalog or manifest entries. Closeout must run Knowledge
Map generation/check, mdBook build, docs path audit, memory architecture
check, diff check, and the doctrine driver. Broad or potentially heavyweight
Perl/`prove`/`fsmgen` commands must remain RAM-guarded.

## Deferred Axes

This audit does not select direct seed mutation, mutation of the existing
word-only subordinate `.ppif` or `.ahb` sources, aggregate/interconnect
byte-lane propagation, optional/property-gated AHB signals, burst `SEQ`
continuation, broader interconnect/decode, legacy two-bit subordinate
`HRESP`, scoreboards, full-manager behavior, direct backend behavior,
verification-output generation, backend-language variants, AXI, APB, broader
AHB behavior, or VHDL behavior.
