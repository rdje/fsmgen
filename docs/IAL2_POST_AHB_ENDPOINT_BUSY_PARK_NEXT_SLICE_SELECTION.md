# IAL2 Post-AHB Endpoint BUSY-Park Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.779`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.779` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.780`, a no-behavior readiness audit for
bounded **aggregate AHB BUSY-parking propagation** — holding a child
subordinate's in-word HBURST `SEQ` burst context across an `HTRANS = BUSY` beat
inside the interconnect aggregate propagation, mirroring the shipped endpoint
BUSY-park behavior — after the endpoint BUSY-park `.ppif`/`.ahb` family is
complete.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.778` endpoint BUSY-park `.ahb` alias behavior, the
`.776` endpoint BUSY-park `.ppif` source and its `.775`/`.774`/`.773`
contract/audit/selector lineage, the `.772`/`.770` aggregate HBURST-aware
byte-lane `SEQ` `.ahb`/`.ppif` propagation family, the `AhbSubordinate`,
`AhbInterconnect`, `AhbRequester`, and PPIF adapter code owners, support
accounting, language-surface and capability boundaries, focused AHB tests
(`t/1491`, `t/1492`, `t/1493`, `t/1494`, `t/1495`, `t/248`, `t/297`), README,
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

The endpoint BUSY-park family is now shipped with a matching `.ppif` source and
`.ahb` profile alias:

```text
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif   (.776)
ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ahb    (.778)
```

The shipped endpoint holds the byte-only `WRAP4`/`INCR4` in-word `SEQ` burst
context across an `HTRANS = BUSY` beat instead of clearing it: the source
declares `(ignored-transfer idle)` + `(parked-transfer busy)`
(`ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif:47`–`48`),
`AhbSubordinate::_normalize_transfer` accepts the `{idle}`-ignored + `{busy}`-parked
split (`AhbSubordinate.pm:224`–`245`), `ahb_seq_idle_clear` fires on IDLE only
so a BUSY beat holds, and `_hburst_seq_policy_report` drops `busy` from
`clears_on` and adds `parks_on = [busy]` (`AhbSubordinate.pm:1014`–`1016`). The
shipped `SEQ`-beat `seq_ok_base` validation stays the fail-closed path for a
drifting BUSY resume.

The endpoint BUSY-park residue now says parking is shipped *for this endpoint
source* and explicitly defers **aggregate propagation**
(`AhbSubordinate.pm:1031`).

## Current Burst-SEQ Residue

The aggregate `ahb_burst_seq_support_deferred` residue
(`AhbInterconnect.pm:1401`, HBURST variant) still reads:

> The interconnect decodes active transfers by `HTRANS != IDLE` and ships
> subordinate-owned byte-only HBURST `WRAP4`/`INCR4` in-word `SEQ` propagation
> for selected aggregate HBURST byte-lane sources; indefinite `INCR`,
> `WRAP8`/`INCR8`/`WRAP16`/`INCR16`, halfword/word burst `SEQ`, **BUSY-in-burst
> handling**, multi-word/register-bank `SEQ` progression, ... remain future work.

The non-HBURST aggregate variant (`AhbInterconnect.pm:1403`) also lists
`BUSY-in-burst handling` first among its remaining burst items. The endpoint
BUSY-park residue (`AhbSubordinate.pm:1031`) is the mirror: it already ships
BUSY-park and defers `aggregate propagation`. The two residue lists now bracket
exactly one increment — aggregate BUSY-park propagation.

## Why Aggregate BUSY-Park Propagation Is the Next Increment

Aggregate BUSY-park propagation is the smallest natural increment and is best
supported by the machinery the shipped endpoint BUSY-park and aggregate HBURST
`SEQ` paths already build.

1. **The established endpoint → aggregate cadence points here.** Every prior AHB
   burst feature shipped at the endpoint first and then propagated through the
   interconnect: byte-lane (`.700`s), byte-lane `SEQ`, and HBURST-aware byte-lane
   `SEQ` (`.764` endpoint → `.770` aggregate `.ppif` → `.772` aggregate `.ahb`).
   BUSY-park is now shipped at the endpoint (`.776`/`.778`); its aggregate
   propagation is the next step in the same cadence, and both the endpoint and
   aggregate residue strings name it as the immediate next item.

2. **The propagation report already forwards the parked shape.** The
   interconnect `_seq_policy_propagation_report` clones each child's
   `seq_policy` verbatim (`AhbInterconnect.pm:1177`, `:1207`
   `seq_policy => _clone_jsonish($seq_policy)`), so a child subordinate declared
   with `(parked-transfer busy)` automatically forwards its `parks_on = [busy]`
   and BUSY-free `clears_on` into the aggregate `composition.seq_policy_propagation`
   report. No new interconnect report field is required — the aggregate inherits
   the endpoint report shape.

3. **The source delta is the same bounded edit, one layer up.** The aggregate
   sources inline the child subordinate transfer block
   (`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif`), so the delta is to add
   new aggregate stems whose child transfer uses `(ignored-transfer idle)` +
   `(parked-transfer busy)` in place of `(ignored-transfer idle)` +
   `(ignored-transfer busy)`. The parser and normaliser changes that made this
   legal for the endpoint (`.776`) already exist and are shared by the aggregate
   child path; no new parser/normaliser vocabulary is needed.

4. **It stays inside the shipped byte-only `WRAP4`/`INCR4` in-word window.** No
   change to `supported_sizes`, `beats_per_burst`, `window_bytes`, the address
   progression masks, the `subordinate_owned_hburst_in_word_seq_policy` mode
   (`AhbInterconnect.pm:1185`), or the `.ahb` alias suppression in the PPIF
   adapter. The behavior narrows the aggregate residue at
   `AhbInterconnect.pm:1401`/`:1403` (drop `BUSY-in-burst handling`), exactly the
   residue-narrowing pattern the last several slices used, and the matching
   `.ahb` alias path needs at most residue-string narrowing.

### Why the Alternatives Are Larger

- **requester-side BUSY insertion.** The shipped requester never drives
  `HTRANS = BUSY` on the bus (`local_status.busy` at `AhbRequester.pm:473` is an
  internal flag), so requester-side BUSY is a new requester behavior — inserting
  bus BUSY beats — not a propagation of the shipped subordinate behavior. It is a
  separate, larger owner and stays deferred (as the `.774` audit already found).

- **halfword/word burst `SEQ`.** The HBURST report hard-codes
  `supported_sizes = [byte]`, `beats_per_burst = 4`, and `window_bytes = 4`, and
  the advance masks address to a single 32-bit word. Larger sizes cross the
  single-word window and require the separately deferred multi-word/register-bank
  progression.

- **wider/indefinite `WRAP8`/`INCR8`/`WRAP16`/`INCR16`/indefinite `INCR`.**
  These are explicitly `fail_closed_hburst_modes`, and `seq_beats_remaining_q` is
  width 2 (max four beats), so they need a wider beat counter and multi-word wrap
  windows. Largest change.

- **optional/property-gated `HPROT`/`HMASTLOCK`/AHB5 signals.** These have no bus
  binding, no DSL surface, and no state today. This is a fresh signal family, not
  a burst-machinery extension.

## Selected `.780` Scope

`.780` owns a no-behavior readiness audit for bounded aggregate AHB BUSY-park
propagation. It must decide whether the next behavior-bearing owner can be a
direct aggregate implementation (new aggregate BUSY-park sources) or whether a
public contract selection or narrower prerequisite must come first.

The audit must cover:

- the child transfer-block change in a new aggregate source stem
  (`(ignored-transfer idle)` + `(parked-transfer busy)`), and whether the shared
  `AhbSubordinate::_normalize_transfer` parked-busy path already covers the child
  role with no interconnect-side parser change;
- whether `_seq_policy_propagation_report` (`AhbInterconnect.pm:1177`) needs any
  change beyond its existing verbatim `seq_policy` clone, and how the parked
  `parks_on = [busy]` / BUSY-free `clears_on` surfaces on the aggregate
  `composition.seq_policy_propagation` report and each child entry;
- the aggregate residue narrowing at `AhbInterconnect.pm:1401` (HBURST variant,
  drop `BUSY-in-burst handling`) and `:1403` (non-HBURST variant), and whether
  the base-`SEQ` aggregate residue should stay unchanged;
- the fail-closed behavior for a child BUSY beat whose control signals
  (`HBURST`/`HWRITE`/`HSIZE`/address) drift from the armed burst, confirming the
  child `seq_ok_base` path still fail-closes through the interconnect;
- whether one aggregate stem (`ahb_interconnect_byte_lane_hburst_seq_busy_park.ppif`)
  or both the one-subordinate and two-subordinate stems
  (`ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park.ppif`) ship in
  the first behavior slice, and the matching support identity, coverage key,
  source kind, generated artifact names (module `ahb_tb`), and later `.ahb` alias
  sequencing;
- focused test shape (modeled on `t/1492`/`t/1493` aggregate tests and `t/1494`
  endpoint BUSY-park), `t/248` corpus-accounting and `t/297` capability-manifest
  impact, language-surface entries, mdBook example, and Knowledge Map updates;
- rollback and preservation boundaries for the shipped endpoint BUSY-park,
  aggregate HBURST `SEQ`, requester, and `.ppif`/`.ahb` behavior.

## Explicit Non-Selections

`.780` must not implement aggregate BUSY-park propagation, add public sources or
`.ahb` aliases, change endpoint BUSY-park behavior, change requester behavior,
change existing aggregate HBURST `SEQ` behavior, add requester-side BUSY
insertion, add halfword/word burst `SEQ`, add wider or indefinite bursts
(`INCR`/`WRAP8`/`INCR8`/`WRAP16`/`INCR16`), add multi-word/register-bank
progression, add optional/property-gated AHB signals, add legacy two-bit
subordinate `HRESP`, broaden interconnect/decode, add scoreboards, add
full-manager behavior, add direct backend behavior, add verification-output
generation, add backend-language variants, add AXI/APB behavior, add broader AHB
behavior, or add VHDL behavior.

## Validation

Closeout for `.779` is documentation-only plus targeted current-state probes on
already-shipped sources:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
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
