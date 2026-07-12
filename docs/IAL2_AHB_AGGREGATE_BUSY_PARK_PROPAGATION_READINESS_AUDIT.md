# IAL2 AHB Aggregate BUSY-Park Propagation Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.780`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.780` audits bounded aggregate AHB
BUSY-parking propagation readiness (holding a child subordinate's in-word HBURST
`SEQ` burst context across an `HTRANS = BUSY` beat inside the interconnect
aggregate propagation, mirroring the shipped endpoint BUSY-park) and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.781`, a no-behavior public contract
selection for the aggregate BUSY-park source(s).

Direct implementation is not selected in this slice. The aggregate machinery is
already fully ready — more ready than the endpoint was before `.774`, because the
`(parked-transfer busy)` DSL vocabulary, the `parked_transfer` parser field, the
IDLE-only clear gating, and the `parks_on` report already exist and are shared by
the child subordinate role, and the interconnect already composes child
subordinate FSMs and forwards each child `seq_policy` verbatim. What remains open
is purely a public contract choice: the aggregate source stem(s), how many ship
in the first behavior slice, and their support identity / coverage keys / residue
scope.

This audit changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The audit read:

- `.779`, the selector that chose aggregate BUSY-park propagation as the next
  increment, and its selection doc;
- `.778`/`.776` endpoint BUSY-park `.ahb`/`.ppif` behavior, and `.775`/`.774`
  endpoint contract/readiness lineage;
- `.772`/`.770` aggregate HBURST-aware byte-lane `SEQ` `.ahb`/`.ppif`
  propagation behavior, and its `.769`/`.768` contract/readiness lineage;
- `ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif` (endpoint
  BUSY-park source);
- `ppif/ahb_interconnect_byte_lane_hburst_seq.ppif` and
  `ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif` (aggregate
  HBURST `SEQ` sources);
- `perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm` (aggregate
  composition/propagation report/residue);
- `perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm` (child generator, parked-busy
  path);
- `perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm` (requester bus drive);
- `perl/FSM/Adapter/IAL2/PPIF.pm` (parser/alias adapter);
- support accounting, language surface, focused AHB tests (`t/1491`–`t/1495`,
  `t/248`, `t/297`), README, ROADMAP_V2, the AHB mdBook chapter, the feature
  backlog, the active task tree, Memory, Knowledge Map, and relevant decisions.

## Current Boundary

The aggregate HBURST `SEQ` sources inline the child subordinate transfer block
with `(ignored-transfer idle)` + `(ignored-transfer busy)`
(`ppif/ahb_interconnect_byte_lane_hburst_seq.ppif`), so a child BUSY beat is
folded into the burst-history clear exactly as the pre-`.776` endpoint did. The
aggregate `ahb_burst_seq_support_deferred` residue therefore still lists
`BUSY-in-burst handling` first among its remaining burst work
(`AhbInterconnect.pm:1401` HBURST variant, `:1403` non-HBURST variant), and the
endpoint BUSY-park residue mirrors it by deferring `aggregate propagation`
(`AhbSubordinate.pm:1031`).

## The Child Generator And Report Substrate Are Already Present

Aggregate BUSY-park propagation needs no interconnect generator or report
substrate repair before contract selection:

1. **The interconnect composes child subordinate FSMs as-is.** For each child
   subordinate contract the interconnect calls `AhbSubordinate->generate($_)`
   (`AhbInterconnect.pm:38`–`41`) and composes the generated results into a
   `(?fsmc:...)` top (`:585`–`588`). A child declared with `(parked-transfer
   busy)` therefore parks BUSY through the exact endpoint machinery shipped in
   `.776` — IDLE-only `ahb_seq_idle_clear` and the held burst-context registers —
   with no interconnect-side generator change.

2. **The propagation report forwards the parked shape verbatim.** The
   interconnect `_seq_policy_propagation_report` clones each child `seq_policy`
   verbatim (`AhbInterconnect.pm:1177`, `:1207`
   `seq_policy => _clone_jsonish($seq_policy)`), so the child's
   `parks_on = [busy]` and BUSY-free `clears_on` surface on each aggregate
   subordinate entry and on `composition.seq_policy_propagation` with no new
   interconnect report field.

3. **The parked-busy vocabulary already exists and is child-role-shared.** The
   `(parked-transfer busy)` declaration, the `parked_transfer` parser field, the
   relaxed `{idle}`-ignored + `{busy}`-parked validation, and the
   `parks_on`/BUSY-free `clears_on` report all live in the shared
   `AhbSubordinate` parser/normaliser path shipped in `.776`
   (`AhbSubordinate.pm:224`–`245`, `:1014`–`1016`) and apply to the child
   subordinate role without a PPIF-adapter or interconnect parser change.

4. **The fail-closed path carries through composition unchanged.** The child
   `SEQ`-beat `seq_ok_base` validation remains the fail-closed path for a BUSY
   beat whose control signals drift from the armed burst; because the child FSM
   is composed as-is, that fail-closed behavior propagates through the
   interconnect without a new aggregate guard.

## Bounded Behavior Delta

The behavior slice is therefore bounded to source data plus residue narrowing:

- one or both new aggregate source stems whose child subordinate transfer block
  uses `(ignored-transfer idle)` + `(parked-transfer busy)` in place of
  `(ignored-transfer idle)` + `(ignored-transfer busy)`, keeping every other
  interconnect/requester/child field identical to the shipped aggregate HBURST
  `SEQ` sources;
- narrowing the aggregate `ahb_burst_seq_support_deferred` residue at
  `AhbInterconnect.pm:1401` (drop `BUSY-in-burst handling` from the HBURST
  variant) once parking ships aggregate-side, keeping the non-HBURST-`SEQ` base
  variant honest;
- support accounting, focused test, `t/248`/`t/297` count bumps, language
  surface, docs, and the later matching `.ahb` alias.

## Requester Scope Clarification

Aggregate BUSY-park propagation is subordinate-side, exactly as the endpoint
BUSY-park was. The shipped requester never drives `HTRANS = BUSY` on the bus
(`local_status.busy` at `AhbRequester.pm:473` is an internal flag), so the parked
behavior is exercised by a child subordinate observing an `HTRANS = BUSY` beat
mid-burst, not by the requester emitting one. Requester-side BUSY insertion
stays a separate, larger deferred owner.

## Readiness Decision

No interconnect generator, report, or parser substrate repair is required before
contract selection: the aggregate HBURST `SEQ` sources already parse, report,
compose child subordinate FSMs, emit generated review artifacts, and lower
through HDL, and the parked-busy machinery and verbatim `seq_policy` clone are
all present.

Direct implementation is still not selected, because the public contract surface
is genuinely open:

- the aggregate source stem name(s): a new additive
  `ahb_interconnect_byte_lane_hburst_seq_busy_park` (one subordinate) and whether
  the two-subordinate sibling
  `ahb_interconnect_two_subordinate_byte_lane_hburst_seq_busy_park` ships in the
  same slice or a follow-on;
- the per-stem support identity, coverage key, source kind, generated artifact
  names (HDL entry `ahb_tb`), and semantic root kind;
- whether only the HBURST-variant aggregate residue narrows, or the base-`SEQ`
  aggregate residue text is also touched;
- the focused test shape (aggregate BUSY-park propagation, modeled on
  `t/1492`/`t/1493` and the endpoint `t/1494`) and the `t/248`/`t/297` count
  deltas;
- the later matching aggregate `.ahb` alias sequencing.

## Selected `.781` Contract Selector

`.781` must select the public contract for the aggregate BUSY-park source(s). It
must settle:

- source path(s), intent name(s), source-object anchor(s), support identity,
  coverage key(s), and source kind for the one-subordinate stem and, if included,
  the two-subordinate stem;
- whether one or both stems ship in the first behavior slice, and the
  preservation consequences for the shipped aggregate HBURST `SEQ` sources and
  `t/1492`/`t/1493`;
- confirmation that the child transfer declaration reuses the shipped
  `(parked-transfer busy)` vocabulary with no interconnect parser change, and
  that `_seq_policy_propagation_report` needs no change beyond its verbatim clone;
- the aggregate residue narrowing scope (`AhbInterconnect.pm:1401` HBURST
  variant, and whether `:1403` non-HBURST base variant is touched) while
  retaining true halfword/word burst `SEQ`, wider/indefinite burst,
  multi-word/register-bank, optional-signal, requester-side-BUSY, broader-AHB,
  direct-backend, verification-output, backend-variant, AXI/APB, and VHDL
  residue;
- the focused test shape, `t/248` corpus-accounting and `t/297`
  capability-manifest impact, language-surface entries, mdBook example,
  preservation matrix, and rollback; and
- the later matching aggregate `.ahb` alias sequencing.

## Explicit Deferrals

Aggregate BUSY-park implementation, the matching aggregate `.ahb` alias,
requester-side BUSY insertion, halfword/word burst `SEQ`, wider or indefinite
bursts, multi-word/register-bank progression, optional/property-gated AHB
signals, legacy two-bit subordinate `HRESP`, broader interconnect/decode,
scoreboards, full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, broader AHB behavior,
and VHDL remain deferred.

## Validation

Closeout for `.780` is documentation-only plus targeted current-state probes and
code-read audit:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_two_subordinate_byte_lane_hburst_seq.ppif
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

Rollback is documentation-only: remove this audit, its Knowledge Map fact card,
task-tree advancement, README/ROADMAP_V2/mdBook sync, Memory pointer update, and
regenerated Knowledge Map entries. No runtime behavior is affected.
