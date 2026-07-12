# IAL2 AHB Subordinate BUSY-in-Burst Parking Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.774`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.774` audits bounded AHB subordinate
BUSY-in-burst parking readiness (holding the in-word `SEQ` burst context across
an `HTRANS = BUSY` beat rather than clearing it) and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.775`, a no-behavior public contract
selection for the endpoint BUSY-parking source.

Direct implementation is not selected in this slice. The endpoint burst
machinery is ready and the behavior delta is bounded, but the public contract
surface (how a subordinate declares "BUSY parks" versus the current
`(ignored-transfer busy)`, whether the endpoint source is widened in place or a
new source stem is added, and the support identity / coverage key / report field
naming) is not yet selected.

This audit changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The audit read:

- `.773`, the selector that chose BUSY-parking as the next increment;
- `.772`/`.770` aggregate HBURST `.ahb`/`.ppif` behavior and `.766`/`.764`
  endpoint HBURST behavior;
- `ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif` (endpoint source);
- `perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm` (endpoint generator);
- `perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm` (aggregate report/residue);
- `perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm` (requester bus drive);
- `perl/FSM/Adapter/IAL2/PPIF.pm` (parser/alias adapter);
- support-accounting, language-surface, and capability boundaries;
- focused AHB tests `t/1491`, `t/1492`, `t/1493`, `t/248`, `t/297`;
- README, ROADMAP_V2, mdBook backlog/AHB chapter, task tree, Memory,
  Knowledge Map, and decisions `0014`, `0015`, `0016`, and `0018`.

## Current Boundary

The endpoint source declares `HTRANS = BUSY` as an ignored transfer alongside
IDLE (`ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif:47`–`:48`):

```text
(seq-policy hburst-in-word-progressive)
(ignored-transfer idle)
(ignored-transfer busy)
```

The generator turns that into a single burst-history clear that fires on either
IDLE or BUSY. `_seq_policy_idle_clear_transaction_lines`
(`AhbSubordinate.pm:708`–`:714`) emits:

```text
(transaction ahb_seq_idle_clear
  (when (& HSEL HREADY (| (== HTRANS idle) (== HTRANS busy)))
    ...clear seq_* registers...
    (complete ahb_seq_idle_done_q)))
```

The `SEQ`/`NONSEQ` access transaction only fires on
`(| (== HTRANS nonseq) (== HTRANS seq))` (`AhbSubordinate.pm:378`), so on a BUSY
beat the access transaction does not fire and the clear transaction does. The
machine-readable report advertises `clears_on = [reset, idle, busy, error,
new_nonseq, final_beat]` (`AhbSubordinate.pm:989`).

## Burst-Context State Is Already Present

The in-word `SEQ` burst context is fully built for the shipped `WRAP4`/`INCR4`
path (`AhbSubordinate.pm:683`–`:694`): `seq_valid_q`, `seq_expected_addr_q`,
`seq_size_q`, `seq_write_q`, `seq_hburst_q`, and `seq_beats_remaining_q`
(width 2). No new register, no wider counter, and no cross-word addressing are
required to park across a BUSY beat.

Because unassigned registers hold their value, the minimal parking behavior is to
stop the clear from firing on BUSY: when neither the access transaction nor the
clear transaction fires, every `seq_*` register retains its value and no
register data changes, which is exactly "park and resume." The fail-closed
question the contract must settle is what happens when a BUSY beat presents
control signals (`HBURST`/`HWRITE`/`HSIZE`/address) that drift from the armed
burst — hold, or clear as a protocol violation.

## Bounded Behavior Delta

An eventual implementation is bounded to:

1. split `busy` out of the `ahb_seq_idle_clear` firing condition
   (`AhbSubordinate.pm:710`) so a BUSY beat holds rather than clears (a guarded
   edit or a separate park branch/transaction);
2. drop `busy` from the report `clears_on` list and add a `parks_on`/`holds_on`
   field (`AhbSubordinate.pm:989`);
3. narrow the endpoint residue string (`AhbSubordinate.pm:1000`) and, if the
   aggregate carries a BUSY-parking subordinate, the aggregate residue string
   (`AhbInterconnect.pm:1401`) to drop "BUSY-in-burst continuation/handling";
4. add a focused test that drives `HTRANS = BUSY` mid-burst into the standalone
   subordinate and asserts the burst context is held and the following `SEQ`
   beat resumes from the parked address/beat count.

## Requester Scope Clarification

The shipped requester does not emit `HTRANS = BUSY` on the bus. Its
`local_status.busy` output (`AhbRequester.pm:473`–`:484`) is an internal
"transaction in progress" status flag, not the AHB `HTRANS` bus code; the
requester drives IDLE/NONSEQ/SEQ only. BUSY-in-burst parking is therefore a
subordinate-side capability, verified by driving `HTRANS = BUSY` as input
stimulus into the standalone subordinate (the same standalone-subordinate style
already used by the endpoint tests). Requester-side BUSY insertion (a manager
pausing its own burst) is a separate, larger concern and remains deferred.

## Readiness Decision

No endpoint generator substrate repair is required before contract selection:
the HBURST-aware endpoint source already parses, reports, emits generated review
artifacts, and lowers through HDL, and all burst-context state exists.

Direct implementation is still not selected, because the public contract surface
is genuinely open:

- the source currently says `(ignored-transfer busy)`; parking needs a distinct
  declaration (for example `(parked-transfer busy)`, `(seq-hold-transfer busy)`,
  or a `busy-parks` flag on `(seq-policy ...)`) so the generator can tell "busy
  parks" from "busy clears";
- whether the endpoint source is widened in place (which would change the
  shipped `ahb_lite_subordinate_byte_lane_hburst_seq` behavior and its `t/1491`
  assertions) or a new additive source stem
  (`ahb_lite_subordinate_byte_lane_hburst_seq_busy_park`) is added with its own
  support identity, coverage key, and generated artifact names;
- the exact report field name (`parks_on` vs. `holds_on`) and the fail-closed
  policy for a drifting BUSY beat;
- the later aggregate/`.ahb`-alias sequencing.

## Selected `.775` Contract Selector

`.775` must select the public contract for the endpoint BUSY-parking source. It
must settle:

- source path, intent name, source-object anchor, support identity, coverage
  key, and source kind;
- in-place widening versus a new additive source stem, and the preservation
  consequences for `t/1491` and the shipped endpoint source;
- the `.ppif` declaration for "BUSY parks" and how the parser records it
  (`PPIF.pm` / `AhbSubordinate` contract fields);
- the transaction shape (guarded edit of `ahb_seq_idle_clear` versus a dedicated
  park branch/transaction) and the fail-closed policy for a drifting BUSY beat;
- the report change (`clears_on` minus `busy`, plus `parks_on`/`holds_on`);
- endpoint (and, if applicable, aggregate) residue narrowing while retaining
  true halfword/word burst `SEQ`, wider/indefinite burst, multi-word/register-
  bank, optional-signal, requester-side-BUSY, broader-AHB, direct-backend,
  verification-output, backend-variant, AXI/APB, and VHDL residue;
- focused test shape, `t/248` corpus-accounting and `t/297` capability-manifest
  impact, language-surface entries, mdBook example, preservation matrix,
  rollback; and
- later matching `.ahb` alias and aggregate BUSY-parking sequencing.

## Explicit Deferrals

BUSY-parking implementation, the matching `.ahb` alias, aggregate BUSY-parking,
requester-side BUSY insertion, halfword/word burst `SEQ`, wider or indefinite
bursts, multi-word/register-bank progression, optional/property-gated AHB
signals, legacy two-bit subordinate `HRESP`, broader interconnect/decode,
scoreboards, full-manager behavior, direct backend behavior, verification-output
generation, backend-language variants, AXI/APB behavior, broader AHB behavior,
and VHDL remain deferred.

## Validation

Closeout for `.774` is documentation-only plus targeted current-state probes and
code-read audit:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_lite_subordinate_byte_lane_hburst_seq.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_interconnect_byte_lane_hburst_seq.ppif
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
