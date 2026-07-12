# IAL2 AHB Subordinate BUSY-in-Burst Parking Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.775`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.775` selects the public contract for the
endpoint AHB subordinate BUSY-in-burst parking source and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.776`, the direct implementation of that
bounded endpoint BUSY-parking source.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.774` readiness audit, the endpoint HBURST-aware
byte-lane `SEQ` source `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif`,
the `AhbSubordinate`/`AhbInterconnect`/PPIF code owners, support accounting
(`t/248` corpus counts 291 protocol entries / 332 total; capability manifest via
`t/297`), the language surface, focused AHB tests (`t/1491`), README,
ROADMAP_V2, the mdBook AHB chapter and backlog, the task tree, Memory, Knowledge
Map, and decisions `0014`, `0015`, `0016`, and `0018`.

## Selected Contract

### Source Surface — new additive stem

The BUSY-parking behavior ships as a **new additive source stem**, not an
in-place widening of the shipped `ahb_lite_subordinate_byte_lane_hburst_seq`
source. This preserves the shipped source, its generated artifacts, and its
`t/1491` assertions with zero regression, matching the additive cadence used
throughout the AHB thread.

```text
source path:      ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
intent name:      ahb_lite_subordinate_byte_lane_hburst_seq_busy_park
source object:    fsmgen-ahb-lite-subordinate-byte-lane-hburst-seq-busy-park
support identity: intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park
coverage key:     ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli
source kind:      ppif
generated IAL1:   ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.isf
generated IAL0:   ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.fsm
HDL module:       ahb_lite_subordinate_byte_lane_hburst_seq_busy_park
```

The source is a copy of the shipped endpoint source with exactly one transfer
declaration change (below).

### `.ppif` "BUSY parks" declaration

The shipped source declares `HTRANS = BUSY` as an ignored transfer alongside
IDLE:

```text
(ignored-transfer idle)
(ignored-transfer busy)
```

The BUSY-parking source instead declares BUSY as a **parked** transfer:

```text
(ignored-transfer idle)
(parked-transfer busy)
```

`(parked-transfer …)` is the new vocabulary, parallel to the existing
`(ignored-transfer …)`. It is preferred over a `(seq-policy … busy-parks)` flag
because it keeps the BUSY classification at the transfer level where IDLE is
already classified, and because it reads as a bounded, self-describing contract
term.

### Parser Change (`AhbSubordinate::_normalize_transfer`)

`_normalize_transfer` (`AhbSubordinate.pm:214`) currently fail-closes unless
`ignored_transfer` is exactly `{idle, busy}` (`:221`–`:222`) and hard-codes
`ignored_transfer => [qw(idle busy)]` (`:236`). The behavior slice adds an
optional `parked_transfer` field and relaxes the validation to accept exactly
one of:

- classic: `ignored_transfer = {idle, busy}`, `parked_transfer = {}` (existing
  sources, unchanged); or
- BUSY-park: `ignored_transfer = {idle}`, `parked_transfer = {busy}` (new
  source).

Any other combination still fail-closes. `parked_transfer` defaults to `[]` so
every shipped source is untouched.

### Generator Change (transaction shape)

When `parked_transfer` includes `busy`, the `ahb_seq_idle_clear` transaction
(`AhbSubordinate.pm:708`–`:714`) fires only on IDLE:

```text
(when (& HSEL HREADY (== HTRANS idle)) ...clear seq_* registers... )
```

On a BUSY beat, neither the `NONSEQ`/`SEQ` access transaction
(`AhbSubordinate.pm:378`) nor the clear transaction fires, so every `seq_*`
register (`seq_valid_q`, `seq_expected_addr_q`, `seq_size_q`, `seq_write_q`,
`seq_hburst_q`, `seq_beats_remaining_q`) and `reg_data_q` retains its value: the
burst context is parked and no data changes. No new register, no wider counter,
and no cross-word addressing are added.

### Fail-Closed Policy

The BUSY beat itself performs no control-signal drift check. Correctness of a
resume is already enforced by the existing `SEQ`-beat validation `seq_ok_base`
(`AhbSubordinate.pm:526`), which requires the resuming `SEQ` beat to match the
armed context (`addr_q == seq_expected_addr_q`, `size_q == seq_size_q`,
`write_q == seq_write_q`, `burst_q == seq_hburst_q`, a non-zero
`seq_beats_remaining_q`, a supported HBURST mode, and a valid byte access). A
BUSY beat that is followed by a drifting `SEQ` beat therefore still fail-closes
into the existing error-first / error-complete path. This reuses shipped
machinery and adds no new drift-detection logic.

### Report Change (`_hburst_seq_policy_report`)

Gated on the parked-BUSY flag, `_hburst_seq_policy_report`
(`AhbSubordinate.pm:974`) changes for the BUSY-park source only:

```text
clears_on: [reset, idle, error, new_nonseq, final_beat]   # busy removed
parks_on:  [busy]                                          # new field
```

The shipped source keeps `clears_on = [reset, idle, busy, error, new_nonseq,
final_beat]` and has no `parks_on` field.

### Residue Change

For the BUSY-park source only, `_unsupported_residue`
(`AhbSubordinate.pm:993`) narrows the `ahb_burst_seq_support_deferred` detail to
drop "BUSY-in-burst continuation" while retaining halfword/word burst `SEQ`,
wider/indefinite bursts, multi-word/register-bank progression, `.ahb` alias
exposure, aggregate propagation, requester-side BUSY insertion, and the
backend/protocol residue. The shipped source keeps its full residue.

## Selected `.776` Implementation Scope

`.776` ships exactly this contract:

- add `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif`;
- add the `parked_transfer` parser field and relaxed validation in
  `AhbSubordinate::_normalize_transfer`;
- gate the `ahb_seq_idle_clear` IDLE-only firing, the `parks_on` report field,
  and the residue narrowing on the parked-BUSY flag;
- support-account the source as
  `intent.ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park` with
  coverage key
  `ial2_ppif_ahb_lite_subordinate_byte_lane_hburst_seq_busy_park_pipeline_cli`
  and source kind `ppif`;
- add focused test
  `t/1494-ial2-ahb-subordinate-byte-lane-hburst-seq-busy-park.t` driving
  `NONSEQ → SEQ → BUSY → SEQ` and asserting the burst context holds across BUSY
  and the following `SEQ` beat resumes from the parked address/beat count, plus
  the `parks_on`/`clears_on` report shape and narrowed residue;
- extend `t/248` corpus accounting (protocol entries 291 → 292, total
  332 → 333) and the `t/297` capability manifest;
- add the language-surface entry and mdBook example/residue update;
- Knowledge Map, task tree, Memory, README, ROADMAP_V2 sync, and closeout
  validation.

## Explicit Deferrals

The matching `.ahb` profile alias, aggregate BUSY-parking, requester-side BUSY
insertion, halfword/word burst `SEQ`, wider or indefinite bursts,
multi-word/register-bank progression, optional/property-gated AHB signals,
legacy two-bit subordinate `HRESP`, broader interconnect/decode, scoreboards,
full-manager behavior, direct backend behavior, verification-output generation,
backend-language variants, AXI/APB behavior, broader AHB behavior, and VHDL
remain deferred.

## Validation

Closeout for `.775` is documentation-only plus targeted current-state probes and
code-read audit:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
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

Rollback is documentation-only: remove this contract selection, its Knowledge
Map fact card, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory
pointer update, and regenerated Knowledge Map entries. No runtime behavior is
affected.
