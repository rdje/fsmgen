# IAL2 AHB Paired BUSY Composition `.ahb` Profile Alias Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.795`

Date: 2026-07-23

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.795` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.796`, direct data-only implementation of
the matching bounded AHB paired-BUSY composition `.ahb` profile alias:

```text
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
```

The alias must be a byte-identical mirror of the generic source shipped by
`.794`:

```text
ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ppif
```

This selection does not create a second implementation or a separate lowering
path. The `.ahb` file is an AHB-vocabulary entrypoint over the same IAL2 model
and must generate the same requester, subordinate, interconnect, composition
top, and HDL behavior.

This selector changes no parser, generator, public source, support catalog,
test, generated artifact, HDL/runtime behavior, direct backend, verification
output, backend-language variant, AXI/APB behavior, broader AHB behavior, or
VHDL behavior. Decision `0020` and its protocol-neutral transaction-layer
horizon remain proposed/inactive until ongoing work explicitly dries out.

## Evidence Read

The selector read and reconciled:

- `.791`-`.794`, including the paired readiness audit, public contract,
  shipped behavior, source, t/1513 generated-HDL proof, and bounded phase
  prerequisite corrections;
- the requester BUSY `.ppif`/`.ahb` pair and its `.789`/`.790` alias contract
  and behavior;
- the endpoint and aggregate BUSY-park `.ppif`/`.ahb` families, including the
  `.783`/`.784` aggregate alias precedent;
- `AhbRequester`, `AhbSubordinate`, `AhbInterconnect`, the PPIF adapter,
  `RegressionCorpus`, `LanguageSurfaceSection`, t/248, t/297, t/1497,
  t/1512, and t/1513;
- README, ROADMAP_V2, the AHB mdBook chapter and feature backlog, Knowledge
  Map, task tree, Memory, the proposed boundary-free-pipeline and reserved-
  instance-name audits, and decision `0020`.

## Current Probe Evidence

An in-memory adapter probe parsed the shipped generic source using the reserved
future `.ahb` label. It succeeded through the existing aggregate generator and
reported:

```text
layer:       IAL2
kind:        protocol_intent.ahb_interconnect
child count: 3

IAL1:
  amba_requester_busy_insert.isf
  ahb_lite_subordinate_byte_lane_hburst_seq.isf
  ahb_interconnect.isf

IAL0:
  amba_requester_busy_insert.fsm
  ahb_lite_subordinate_byte_lane_hburst_seq.fsm
  ahb_interconnect.fsm
  ahb_tb.fsm

requester child busy_insertion:
  generated_behavior: true
  htrans_busy_encoding: 2'b01
  before_beat: 2
  beats: single

subordinate child parks_on: [busy]
```

The same probe showed that current suffix-keyed alias handling removes the
aggregate, requester-child, and subordinate-child profile-alias residues while
retaining `ahb_requester_busy_insert_support` and the narrowed aggregate burst
support residue. No adapter, endpoint, interconnect, report, or lowering change
is needed. The missing support match is expected because the tracked alias and
catalog entry do not exist yet.

## Why The Alias Comes Next

The matching alias is the smallest coherent follow-on to `.794`:

1. It completes the established `generic .ppif -> matching .ahb` public
   cadence already used by the requester BUSY, subordinate BUSY-park, and
   aggregate BUSY-park families.
2. It reuses the exact generated behavior already proven by t/1513 instead of
   opening a new transfer, topology, status, burst, or timing contract.
3. The live adapter probe proves that alias parsing, child report propagation,
   artifact generation, and alias-only residue cleanup already generalize to
   this source.
4. A two-subordinate paired source would introduce a new topology and runtime
   proof. Broader BUSY policies, local bus-BUSY status, larger burst
   progression, and optional signals each introduce new behavior. They are
   therefore larger than this data-only surface completion.

The proposed boundary-free active-transfer audit and cross-protocol reserved-
instance-name audit remain inactive. Selecting either would pivot away from
the still-running feature-completeness lineage rather than complete the paired
source's matching public surface.

## Selected `.796` Contract

`.796` owns direct implementation of exactly:

```text
alias path:
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb

support id:
  intent.ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park

coverage:
  ial2_ahb_profile_alias_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park_pipeline_cli

source kind:   ial2_profile_alias
family:        protocol_fixture
classification: supported_smoke
strict:        true
HDL module:    ahb_tb
child count:   3
semantic root: top
```

The implementation must:

- add the `.ahb` source as a byte-identical mirror of the `.ppif` source;
- add one support-accounting entry and move the corpus from 311 to 312
  protocol fixtures and from 352 to 353 supported-smoke/strict entries;
- extend `LanguageSurfaceSection` and t/297 for the matching alias boundary;
- preserve the exact generated IAL1/IAL0 artifact set and HDL module `ahb_tb`;
- preserve requester-child `busy_insertion`, subordinate/aggregate
  `parks_on = [busy]`, the absence of a duplicated top `busy_flow`, and all
  bounded support residue other than alias-only cleanup;
- rely on existing suffix-keyed removal of
  `ahb_aggregate_profile_alias_deferred`, requester-child
  `ahb_profile_alias_deferred`, subordinate-child
  `ahb_subordinate_profile_alias_deferred`, and `.ahb alias exposure` wording;
- add focused
  `t/1514-ial2-ahb-paired-busy-composition-profile-alias.t` covering source
  parity, parse/check/schedule/semantic/outdir/HDL surfaces, support identity,
  generated artifacts, report parity, alias-only residue cleanup, malformed
  alias diagnostics, and preservation of the generic source; and
- retain t/1513 as the shared generated-HDL runtime proof and run public
  `--verify-hdl` on the alias.

The behavior documentation and mdBook must explain that `.ppif` and `.ahb` are
two public source surfaces for one generator architecture, not two generators.

## Preservation And Non-Goals

`.796` must preserve every shipped requester, subordinate, interconnect,
byte-lane, `SEQ`, HBURST, BUSY-park, aggregate, `.ppif`, and `.ahb` behavior
except for the additive alias fixture/catalog/language/docs entries and the
selected alias-only residue cleanup.

It must not add a two-subordinate paired source, new requester/subordinate/
interconnect logic, a top BUSY summary, multi-beat/policy/runtime BUSY, a
distinct local bus-BUSY status, true boundary-free active-transfer pipelining,
halfword/word or wider/indefinite burst progression, multi-word/register-bank
behavior, optional AHB signals, legacy two-bit subordinate `HRESP`, broader
manager/interconnect behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, or VHDL behavior.

## Validation

`.795` closeout is documentation-only plus the in-memory `.ahb`-label probe
described above. `.796` must run:

```bash
./bin/fsmgen --quiet --strict --check --json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --emit-schedule-json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --emit-semantic-json \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
./bin/fsmgen --quiet --strict --verify-hdl \
  ppif/ahb_interconnect_requester_busy_insert_byte_lane_hburst_seq_busy_park.ahb
prove -Iperl t/1514-ial2-ahb-paired-busy-composition-profile-alias.t \
  t/1513-ial2-ahb-paired-busy-composition.t \
  t/1512-ial2-ahb-requester-busy-insert-profile-alias.t \
  t/1497-ial2-ahb-interconnect-byte-lane-hburst-seq-busy-park-profile-alias.t \
  t/248-regression-corpus-accounting.t t/297-capability-manifest.t
```

Broad or potentially heavyweight Perl, `prove`, or `fsmgen` commands remain
behind `scripts/run_with_ram_guard.sh` or equivalent monitoring. Documentation
closeout includes Knowledge Map generation/check, mdBook build, relative-path,
memory, diff, and doctrine gates.

## Rollback

`.795` rollback is documentation-only: remove this selection and its Knowledge
Map fact, restore `.795` as active, and revert README, ROADMAP_V2, mdBook,
task-tree, Memory, and generated Knowledge Map changes. `.796` has its own
data-only rollback boundary: remove the alias fixture, its support/language/
test/doc entries, and restore the prior counts without reverting `.794`.
