# IAL2 Post-AHB Aggregate BUSY-Park Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.785`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.785` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.786`, a no-behavior readiness audit for
bounded **requester-side single BUSY-beat insertion** — teaching the AHB
requester to drive `HTRANS = BUSY` for one held beat inside an active
`WRAP4`/`INCR4` burst — after the entire subordinate/aggregate BUSY-park
`.ppif`/`.ahb` family (endpoint `.776`/`.778`, aggregate `.782`/`.784`) is
complete.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the completed BUSY-park family — the endpoint BUSY-park
`.ppif`/`.ahb` (`.776`/`.778`) and the aggregate BUSY-park `.ppif`/`.ahb`
(`.782`/`.784`) — with its `.773`/`.774`/`.775`/`.777`/`.779`/`.780`/`.781`/`.783`
selector/audit/contract lineage, the aggregate HBURST-aware byte-lane `SEQ`
`.ppif`/`.ahb` propagation family (`.770`/`.772`), the `AhbRequester`,
`AhbSubordinate`, `AhbInterconnect`, and PPIF adapter code owners, the shipped
AHB residue lists, support accounting, language-surface and capability
boundaries, focused AHB tests (`t/1491`–`t/1497`, `t/248`, `t/297`), README,
ROADMAP_V2, the AHB mdBook chapter, the feature backlog, the active task tree,
Memory, Knowledge Map, and relevant decisions.

Relevant decisions remain:

- `0014`, protocol/platform intent uses layered lowering;
- `0015`, protocol-specific extensions are profile aliases over IAL2;
- `0016`, `.ppif` is the first generic IAL2 container;
- `0018`, IAL contracts and the mdBook are backend-language-neutral; and
- `0003`, `0005`, `0006`, and `0007` for autonomous PNT, push gating,
  mdBook synchronization, and frozen legacy blobs.

## Completed Family

The BUSY-park family is now shipped end to end on the receiving
(subordinate/interconnect) side, at both the endpoint and the aggregate, with a
matching `.ppif` source and `.ahb` profile alias at each level:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif                  (.776)
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb                   (.778)
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif                      (.782)
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif      (.782)
ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ahb                       (.784)
ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ahb       (.784)
```

Every one of these sources holds the byte-only `WRAP4`/`INCR4` in-word `SEQ`
burst context across an `HTRANS = BUSY` beat instead of clearing it: the
subordinate (endpoint and interconnect child) declares `(ignored-transfer idle)`
+ `(parked-transfer busy)`, `AhbSubordinate::_normalize_transfer` accepts the
`{idle}`-ignored + `{busy}`-parked split (`AhbSubordinate.pm:224`–`245`),
`ahb_seq_idle_clear` fires on IDLE only so a BUSY beat holds,
`_hburst_seq_policy_report` drops `busy` from `clears_on` and adds
`parks_on = [busy]`, and the interconnect `_seq_policy_propagation_report`
forwards each child's parked shape verbatim into
`composition.seq_policy_propagation`. The shipped `SEQ`-beat `seq_ok_base`
validation stays the fail-closed path for a drifting BUSY resume.

## The Open Loop After BUSY-Park

BUSY-park is now complete on the side that **receives** a `BUSY` beat, but no
FSMGen-generated AHB actor **drives** one. The requester's HTRANS table defines
only `idle = 2'b00`, `nonseq = 2'b10`, and `seq = 2'b11`
(`AhbRequester::_normalize_transfer`, `AhbRequester.pm:224`–`232`); there is no
`busy = 2'b01` encoding and no `transfer_busy` drive block. The requester emits
IDLE, one NONSEQ first beat, and SEQ later beats (`transfer_nonseq` at
`AhbRequester.pm:326`, `transfer_seq` at `:338`). The `local_status.busy` field
(`AhbRequester.pm:175`, driven with default `1` in `_status_drive_lines` at
`:474`) is an internal "requester is mid-command" activity flag, unrelated to
the AHB bus `HTRANS = BUSY` encoding.

So the shipped BUSY-park behavior can currently be exercised only by an external
master's BUSY stimulus (as `t/1494` drives it directly). Teaching the requester
to insert one BUSY beat closes the loop end to end within FSMGen: the requester
would drive the `BUSY` beat that the subordinate is now built to park across.

## Why Requester-Side BUSY Insertion Is the Next Increment

Requester-side single BUSY-beat insertion is the smallest **remaining** AHB
feature-completeness increment that is both bounded and coherent with the shipped
line, and it reuses the most existing machinery among the remaining candidates.

1. **It closes the loop the BUSY-park family just opened.** Nine leaves
   (`.774`–`.784`) built the receiving side of BUSY handling; nothing drives a
   `BUSY` beat. Requester-side insertion is the direct, natural complement that
   makes the shipped subordinate/aggregate BUSY-park behavior demonstrable end to
   end from FSMGen-generated actors, not just from external stimulus.

2. **It is self-contained on the requester and reuses the burst machinery.** The
   requester already models the full burst substrate — `beat_index_q` (width 5),
   `beats_remaining_q` (width 5), `burst_active_q`, `wrap_base_q`/`wrap_high_q`/
   `wrap_span_q`/`wrap_mode_q`, all eight burst encodings
   (`single`/`incr`/`wrap4`/`incr4`/`wrap8`/`incr8`/`wrap16`/`incr16`), and the
   NONSEQ→SEQ drive blocks. A single BUSY insertion adds a `busy = 2'b01` HTRANS
   encoding, a `transfer_busy` drive block that holds the address/control/write
   constant while driving `HTRANS = BUSY`, and a bounded insertion decision for
   one beat — with no change to the burst address progression itself.

3. **It stays inside the shipped byte-only `WRAP4`/`INCR4` window.** No change to
   `supported_sizes`, `beats_per_burst`, `window_bytes`, or multi-word
   addressing. The receiving side already parks correctly, so a single held BUSY
   beat needs no new subordinate/interconnect behavior — the increment is
   entirely on the requester.

### Why the Alternatives Are Larger / Deferred

- **halfword/word burst `SEQ`.** The HBURST `SEQ` report hard-codes
  `supported_sizes = [byte]`, `beats_per_burst = 4`, and an in-word address
  progression (`AhbSubordinate::_hburst_seq_policy_report`, byte lanes within
  `HADDR[1:0]`). A byte `WRAP4`/`INCR4` covers exactly four bytes = one 32-bit
  word; a 4-beat halfword burst spans 8 bytes and a 4-beat word burst spans 16
  bytes, so both **cross the single-word window** and require the separately
  deferred multi-word/register-bank progression first. Larger, and dependent on a
  prerequisite.

- **wider/indefinite `WRAP8`/`INCR8`/`WRAP16`/`INCR16`/indefinite `INCR`.** These
  are explicitly `fail_closed_hburst_modes` today, `seq_beats_remaining_q` is
  width 2 (max four beats), and 8-/16-beat byte bursts also cross the single-word
  window. They need a wider beat counter, new accepted HBURST encodings,
  `WRAP8`/`WRAP16` wrap-boundary math, unbounded handling for indefinite `INCR`,
  and the same multi-word progression prerequisite. Largest change.

- **multi-word/register-bank `SEQ` progression.** This is a foundational new
  address-progression model (progression beyond the single 32-bit word, with a
  wider address compare) and is the enabler for halfword/word and wider bursts.
  It is itself a medium-to-large substrate slice, not the smallest next step.

- **optional/property-gated AHB signals** (`HPROT`, `HMASTLOCK`, exclusive
  access, protection-policy effects, legacy two-bit subordinate `HRESP`
  compatibility; `ahb_optional_signal_residue`, `AhbInterconnect.pm:1411`). These
  have no bus binding, no DSL surface, and no state today. This is a fresh, broad
  signal family orthogonal to the burst/BUSY line rather than an extension of the
  machinery the shipped slices build, so even a single additive signal opens an
  unanchored new direction. Deferred as its own future owner.

## Selected `.786` Scope

`.786` owns a no-behavior readiness audit for bounded requester-side single
BUSY-beat insertion. It must decide whether the next behavior-bearing owner can
be a direct requester implementation or whether a public contract selection or
narrower prerequisite must come first.

The audit must cover:

- how the requester source would declare BUSY insertion (a new `transfer.busy`
  HTRANS encoding plus an insertion clause — e.g. a bounded "insert one BUSY beat
  before beat N" or a single-beat throttle marker — versus reusing an existing
  clause), and whether it is a new additive source stem or an in-place widen of a
  shipped requester source, with the preservation consequences for the shipped
  requester source and its focused test;
- the `transfer_busy` drive block: driving `HTRANS = BUSY` (`2'b01`) while
  holding `HADDR`/`HWRITE`/`HSIZE`/`HBURST`/`HWDATA` constant across the held
  beat, and not advancing `beat_index_q`/`beats_remaining_q` during BUSY;
- where the BUSY beat is inserted in the NONSEQ→SEQ sequence and how the
  requester FSM re-enters SEQ after the BUSY beat, so the following SEQ resumes
  from the same armed address/beat count;
- the fail-closed policy for a malformed or out-of-range insertion request, and
  whether insertion is bounded to one beat in the first slice;
- the `local_status` reporting (whether a distinct bus-BUSY indicator is exposed,
  kept separate from the internal `local_status.busy` activity flag) and any
  report/residue movement in the requester report and the
  `ahb_burst_seq_support_deferred` / requester residue strings;
- whether the shipped subordinate/interconnect BUSY-park path needs any change to
  receive a requester-driven BUSY beat (expected: none — the receiving side is
  already built to park), and whether a paired requester+subordinate composition
  demonstration is in scope for a later slice;
- support identity, coverage key, source kind, generated artifact names, focused
  test shape (modeled on the requester tests and `t/1494` BUSY stimulus),
  `t/248` corpus-accounting and `t/297` capability-manifest impact,
  language-surface entries, mdBook example, and Knowledge Map updates;
- rollback and preservation boundaries for the shipped requester, endpoint and
  aggregate BUSY-park, HBURST `SEQ`, and `.ppif`/`.ahb` behavior.

## Explicit Non-Selections

`.786` must not implement requester-side BUSY insertion, add or change the
requester's HTRANS encodings or drive blocks, add public sources or `.ahb`
aliases, change endpoint or aggregate BUSY-park behavior, change subordinate or
interconnect behavior, add halfword/word burst `SEQ`, add wider or indefinite
bursts (`INCR`/`WRAP8`/`INCR8`/`WRAP16`/`INCR16`), add multi-word/register-bank
progression, add optional/property-gated AHB signals, add legacy two-bit
subordinate `HRESP`, broaden interconnect/decode, add scoreboards, add
full-manager behavior, add direct backend behavior, add verification-output
generation, add backend-language variants, add AXI/APB behavior, add broader AHB
behavior, or add VHDL behavior.

## Validation

Closeout for `.785` is documentation-only plus targeted current-state probes on
already-shipped sources confirming the requester drives no bus BUSY today and the
subordinate parks on one:

```bash
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif
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
card, the task-tree advancement, the Memory pointer update, and the regenerated
Knowledge Map entries. No runtime behavior is affected.
