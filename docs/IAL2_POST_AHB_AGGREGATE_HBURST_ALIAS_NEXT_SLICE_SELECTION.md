# IAL2 Post-AHB Aggregate HBURST Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.773`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.773` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.774`, a no-behavior readiness audit for
bounded AHB subordinate **BUSY-in-burst parking** (holding the in-word `SEQ`
burst context across an `HTRANS = BUSY` beat rather than clearing it), after the
byte-only `WRAP4`/`INCR4` in-word HBURST `SEQ` endpoint and aggregate
`.ppif`/`.ahb` family is complete.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.772` aggregate HBURST-aware `.ahb` alias behavior, the
`.771` alias contract selection, the `.770` aggregate `.ppif` behavior, the
`.769`/`.768`/`.767` aggregate HBURST contract/audit/selector, the `.766`/`.764`
endpoint HBURST behavior, the `AhbSubordinate`, `AhbInterconnect`,
`AhbRequester`, and PPIF adapter code owners, support accounting,
language-surface and capability boundaries, focused AHB tests (`t/1491`,
`t/1492`, `t/1493`, `t/248`, `t/297`), README, ROADMAP_V2, the AHB mdBook
chapter, the feature backlog, the active task tree, Memory, Knowledge Map, and
relevant decisions.

Relevant decisions remain:

- `0014`, protocol/platform intent uses layered lowering;
- `0015`, protocol-specific extensions are profile aliases over IAL2;
- `0016`, `.ppif` is the first generic IAL2 container;
- `0018`, IAL contracts and the mdBook are backend-language-neutral; and
- `0003`, `0005`, `0006`, and `0007` for autonomous PNT, push gating,
  mdBook synchronization, and frozen legacy blobs.

## Completed Family

The byte-only `WRAP4`/`INCR4` in-word HBURST `SEQ` family is now shipped at both
the endpoint and aggregate levels, with matching `.ppif` sources and `.ahb`
profile aliases:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif            (.764)
ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ahb             (.766)
ppif/ahb_interconnect_byte_lane_hburst_seq.ppif                (.770)
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif (.770)
ppif/ahb_interconnect_byte_lane_hburst_seq.ahb                 (.772)
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ahb (.772)
```

The endpoint report `_hburst_seq_policy_report`
(`perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm:974`) pins the shipped bound:
`supported_hburst_modes = [WRAP4, INCR4]`,
`fail_closed_hburst_modes = [INCR, WRAP8, INCR8, WRAP16, INCR16]`,
`supported_sizes = [byte]`, `beats_per_burst = 4`, `window_bytes = 4`. The
aggregate forwards requester/global `HBURST` to child-local `HBURST_REGS`,
`HBURST_STATUS`, and `HBURST_CONTROL` and reuses
`composition.seq_policy_propagation` mode
`subordinate_owned_hburst_in_word_seq_policy`.

## Current Burst-SEQ Residue

The endpoint `ahb_burst_seq_support_deferred` residue
(`AhbSubordinate.pm:1000`, HBURST variant) reads:

> Byte-only HBURST `WRAP4`/`INCR4` in-word `SEQ` is shipped for this endpoint
> source; indefinite `INCR`, `WRAP8`/`INCR8`/`WRAP16`/`INCR16`, halfword/word
> burst `SEQ`, **BUSY-in-burst continuation**, multi-word/register-bank
> progression, ... remain future work.

The aggregate `ahb_burst_seq_support_deferred` residue
(`AhbInterconnect.pm:1401`) reads:

> The interconnect decodes active transfers by `HTRANS != IDLE` and ships
> subordinate-owned byte-only HBURST `WRAP4`/`INCR4` in-word `SEQ` propagation
> for selected aggregate HBURST byte-lane sources; indefinite `INCR`,
> `WRAP8`/`INCR8`/`WRAP16`/`INCR16`, halfword/word burst `SEQ`, **BUSY-in-burst
> handling**, multi-word/register-bank `SEQ` progression, ... remain future work.

Both residue lists enumerate the remaining burst work in the same order and put
BUSY-in-burst first.

## Why BUSY-in-burst Parking Is the Next Increment

BUSY-in-burst parking is the smallest natural increment and is best supported by
the machinery the shipped `WRAP4`/`INCR4` in-word `SEQ` path already builds.

1. **All required state already exists.** The endpoint burst context registers
   `seq_valid_q`, `seq_expected_addr_q`, `seq_size_q`, `seq_write_q`,
   `seq_hburst_q`, and `seq_beats_remaining_q` (width 2) are already declared for
   the shipped `WRAP4`/`INCR4` path (`AhbSubordinate.pm:683`,
   `_hburst_seq_arm_lines` at `:729`). Parking needs no new register, no wider
   beat counter, and no cross-word addressing.

2. **The delta is a single, well-isolated decode point.** BUSY is currently
   folded into the burst-history clear alongside IDLE. The `ahb_seq_idle_clear`
   transaction fires on
   `(| (== HTRANS idle) (== HTRANS busy))` (`AhbSubordinate.pm:710`), and the
   report advertises `clears_on = [reset, idle, busy, error, new_nonseq,
   final_beat]` (`:989`). Parking means holding the burst context across a BUSY
   beat instead of clearing it: split `busy` out of the clear condition and move
   it to a park/hold branch, and move `busy` out of `clears_on` into a
   `parks_on`/`holds_on` report field.

3. **The residue text already names the exact delta.** The endpoint HBURST
   residue says `BUSY-in-burst continuation` and the base in-word residue says
   `BUSY-in-burst continuation rather than history clearing`
   (`AhbSubordinate.pm:1000`, `:1002`); the aggregate says `BUSY-in-burst
   handling` (`AhbInterconnect.pm:1401`). The behavior slice narrows these
   strings once parking ships.

4. **It stays within the shipped byte-only `WRAP4`/`INCR4` in-word window.** No
   change to `supported_sizes`, `beats_per_burst`, `window_bytes`, the address
   progression masks (`AhbSubordinate.pm:747`–`748`), the aggregate
   `composition.seq_policy_propagation` report
   (`AhbInterconnect.pm:1177`), or the `.ahb` alias suppression in the PPIF
   adapter. The `.ahb` alias path needs at most residue-string narrowing, which
   is exactly the pattern the last several slices used.

### Why the Alternatives Are Larger

- **halfword/word burst `SEQ`.** The HBURST report hard-codes
  `supported_sizes = [byte]`, `beats_per_burst = 4`, and `window_bytes = 4`
  (`AhbSubordinate.pm:981`, `:985`–`:987`), and the advance masks address to a
  single 32-bit word (`:747`–`:748`). Larger sizes cross the single-word window
  and require the separately deferred multi-word/register-bank progression.

- **wider/indefinite `WRAP8`/`INCR8`/`WRAP16`/`INCR16`/indefinite `INCR`.**
  These are explicitly `fail_closed_hburst_modes` (`AhbSubordinate.pm:983`), and
  `seq_beats_remaining_q` is width 2 (max four beats), so `WRAP8`/`INCR16` need a
  wider beat counter and multi-word wrap windows. Largest change.

- **optional/property-gated `HPROT`/`HMASTLOCK`/AHB5 signals.** These have no bus
  binding, no DSL surface, and no state today (residue at
  `AhbSubordinate.pm:995` and `AhbInterconnect.pm:1393`). This is a fresh signal
  family, not a burst-machinery extension.

## Selected `.774` Scope

`.774` owns a no-behavior readiness audit for bounded AHB subordinate
BUSY-in-burst parking. It must decide whether the next behavior-bearing owner
can be a direct endpoint implementation or whether a public contract selection
or narrower prerequisite must come first.

The audit must cover:

- the exact clear-versus-park decode change at `AhbSubordinate.pm:710` and how
  a held BUSY beat must preserve `seq_valid_q`, `seq_expected_addr_q`,
  `seq_size_q`, `seq_write_q`, `seq_hburst_q`, and `seq_beats_remaining_q`;
- whether parking requires a new transaction/branch or a guarded edit of
  `ahb_seq_idle_clear`, and the fail-closed behavior for a BUSY beat whose
  control signals (`HBURST`/`HWRITE`/`HSIZE`/address) drift from the armed burst;
- the `_hburst_seq_policy_report` change (drop `busy` from `clears_on`, add a
  `parks_on`/`holds_on` field), and the residue narrowing at
  `AhbSubordinate.pm:1000`/`:1002` and `AhbInterconnect.pm:1401`;
- whether the endpoint source is widened in place or a new
  `*_hburst_seq_busy_park` source stem is added, and the matching support
  identity, coverage key, source kind, generated artifact names, and later
  `.ahb` alias sequencing;
- whether the aggregate propagation report needs any change or only residue
  narrowing;
- focused test shape (modeled on `t/1491`/`t/1492`), `t/248` corpus-accounting
  and `t/297` capability-manifest impact, language-surface entries, mdBook
  example, and Knowledge Map updates;
- rollback and preservation boundaries for the shipped endpoint, requester, and
  aggregate `.ppif`/`.ahb` behavior.

## Explicit Non-Selections

`.774` must not implement BUSY-in-burst parking, add public sources or `.ahb`
aliases, change endpoint HBURST behavior, change requester HBURST behavior,
change existing aggregate HBURST `SEQ` behavior, add halfword/word burst `SEQ`,
add wider or indefinite bursts (`INCR`/`WRAP8`/`INCR8`/`WRAP16`/`INCR16`), add
multi-word/register-bank progression, add optional/property-gated AHB signals,
add legacy two-bit subordinate `HRESP`, broaden interconnect/decode, add
scoreboards, add full-manager behavior, add direct backend behavior, add
verification-output generation, add backend-language variants, add AXI/APB
behavior, add broader AHB behavior, or add VHDL behavior.

## Validation

Closeout for `.773` is documentation-only plus targeted current-state probes on
already-shipped sources:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
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

Rollback is documentation-only: remove this selector, its Knowledge Map fact
card, task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer
update, and regenerated Knowledge Map entries. No runtime behavior is affected.
