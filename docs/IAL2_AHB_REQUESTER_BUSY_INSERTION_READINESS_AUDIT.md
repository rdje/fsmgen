# IAL2 AHB Requester BUSY-Beat Insertion Readiness Audit

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.786`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.786` audits bounded requester-side single
BUSY-beat insertion readiness — teaching the AHB requester to drive
`HTRANS = BUSY` for one held beat inside an active `WRAP4`/`INCR4` burst, holding
the address/control constant and not advancing the beat counters — and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.787`, a no-behavior public contract
selection for the requester BUSY-insertion source.

Direct implementation is not selected in this slice. The requester burst
machinery is fully present and the behavior delta is bounded, but the public
contract surface (how the source declares BUSY insertion, the new `HTRANS = BUSY`
encoding, the `transfer_busy` drive block, where the BUSY beat inserts in the
`NONSEQ`→`SEQ` sequence and how the FSM re-enters `SEQ`, the fail-closed policy,
`local_status` reporting, and whether the shipped requester source is widened in
place or a new source stem is added) is not yet selected.

This audit changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The audit read:

- `.785`, the selector that chose requester-side BUSY insertion as the next
  increment, and its `docs/IAL2_POST_AHB_AGGREGATE_BUSY_PARK_NEXT_SLICE_SELECTION.md`;
- the completed subordinate/aggregate BUSY-park family (endpoint `.776`/`.778`,
  aggregate `.782`/`.784`) that built the receiving side of BUSY handling;
- `ppif/ahb_requester.ppif` and `ppif/ahb_requester.ahb` (the requester sources);
- `perl/FSM/IAL2/ProtocolIntent/AhbRequester.pm` (requester generator and FSM);
- `perl/FSM/IAL2/ProtocolIntent/AhbSubordinate.pm` and
  `perl/FSM/IAL2/ProtocolIntent/AhbInterconnect.pm` (the receiving side that
  already parks on BUSY);
- `perl/FSM/Adapter/IAL2/PPIF.pm` (parser/alias adapter);
- support-accounting, language-surface, and capability boundaries;
- focused AHB tests `t/1473` (requester), `t/1491`–`t/1497`, `t/248`, `t/297`;
- README, ROADMAP_V2, mdBook backlog/AHB chapter, task tree, Memory,
  Knowledge Map, and decisions `0014`, `0015`, `0016`, and `0018`.

## Current Boundary

The requester source declares only three `HTRANS` transfer types
(`ppif/ahb_requester.ppif:65`–`71`):

```text
(transfer
  (idle 2'b00)
  (nonseq 2'b10)
  (seq 2'b11)
  (first-beat nonseq)
  (later-beats seq)
  (advance-on ready))
```

`AhbRequester::_normalize_transfer` (`AhbRequester.pm:224`–`232`) mirrors exactly
this set — there is no `busy = 2'b01` encoding — and the generator emits four
transfer-driving blocks: `request_bus` (`HTRANS = IDLE` while waiting for grant,
`AhbRequester.pm:314`), `transfer_nonseq` (`HTRANS = NONSEQ`, `:326`),
`transfer_seq` (`HTRANS = SEQ`, `:338`), and the completion blocks
`okay_beat`/`retry_seen`/`split_seen`/`error_done`/`finish` (all `HTRANS = IDLE`,
`:350`–`:375`). There is no `transfer_busy` drive block.

The beat loop (`AhbRequester.pm:430`–`466`) is:

```text
(while beats_remaining_q
  (drive request_bus)                         ; HTRANS = IDLE until grant
  (when HGRANT
    (when (== beat_index_q 0) (drive transfer_nonseq))   ; first beat
    (when (! (== beat_index_q 0)) (drive transfer_seq))  ; later beats
    (when HREADY
      (when (== HRESP okay)
        (drive okay_beat)
        (when (== beats_remaining_q 1) (set beats_remaining_q 0) ...)
        (when (! (== beats_remaining_q 1))
          (set beats_remaining_q (- beats_remaining_q 1))
          (set beat_index_q (+ beat_index_q 1))
          ...address progression...))
      ...error/retry/split...)))
```

`local_status.busy` (`AhbRequester.pm:175`, driven with default `1` in
`_status_drive_lines` at `:474`) is an internal "transaction in progress"
activity flag set on `accept_command` and cleared on `finish`; it is not the AHB
`HTRANS = BUSY` bus code.

The requester `_unsupported_residue` (`AhbRequester.pm:566`–`590`) lists
`ahb_profile_alias_deferred`, `ahb_completer_subordinate_deferred`,
`ahb_interconnect_decode_deferred`, `ahb_full_manager_deferred`, and
`ahb_verification_output_deferred`. There is **no** existing "BUSY-insertion
deferred" residue on the requester today — the requester's transfer set is simply
IDLE/NONSEQ/SEQ with no statement about master-inserted BUSY — so an eventual
implementation adds (and later narrows) a new requester residue rather than
narrowing an existing one.

## Burst Machinery Is Already Present

The requester already models the full burst substrate needed to insert one held
beat without disturbing progression (`AhbRequester.pm:388`–`417`):

- `beat_index_q` (width 5) and `beats_remaining_q` (width 5) with `beats_total_q`;
- `burst_active_q`, `wrap_base_q`/`wrap_high_q`/`wrap_span_q`/`wrap_mode_q`;
- all eight burst encodings arm exactly (`single`/`incr`/`wrap4`/`incr4`/
  `wrap8`/`incr8`/`wrap16`/`incr16`), with the shipped `WRAP4`/`INCR4` giving a
  four-beat burst; and
- `addr_step_q` sizing and the wrap/incr address progression already computed per
  OKAY beat.

A held BUSY beat must simply drive `HTRANS = BUSY` while re-driving the *same*
`addr_q`/`write_q`/`size_q`/`burst_q`/`wdata_q` and **not** advancing
`beat_index_q`/`beats_remaining_q` or the address — no new register, no wider
counter, and no address-progression change are required. This stays entirely
inside the shipped byte-only `WRAP4`/`INCR4` window.

## Receiving-Side Clarification

The subordinate/interconnect side is already complete. The BUSY-park family
(`.776`–`.784`) makes the subordinate hold its in-word `SEQ` burst context across
an `HTRANS = BUSY` beat: `ahb_seq_idle_clear` fires on IDLE only, and the
report advertises `parks_on = [busy]` with BUSY-free `clears_on`
(confirmed at runtime — the aggregate BUSY-park schedule JSON reports
`parks_on = [busy]` per child). So a requester-driven BUSY beat is exactly what
the receiving side is already built to park across; no subordinate or
interconnect change is expected for the requester to drive one. Whether to add a
paired requester+subordinate composition that demonstrates the loop end to end is
a later-slice question, not a prerequisite for the requester source itself.

## Bounded Behavior Delta

An eventual implementation is bounded to the requester side:

1. add a `busy = 2'b01` `HTRANS` encoding to the requester transfer table
   (source clause + `AhbRequester::_normalize_transfer`);
2. add a `transfer_busy` drive block that drives `HTRANS = BUSY`, holds
   `request = 1`, and re-drives `HADDR`/`HWRITE`/`HSIZE`/`HBURST`/`HWDATA`
   constant, without advancing `beat_index_q`/`beats_remaining_q` or the address;
3. add a bounded single-beat insertion decision to the beat loop
   (`AhbRequester.pm:430`–`466`) — for one chosen point in the `NONSEQ`→`SEQ`
   sequence, drive `transfer_busy` for one cycle and then re-enter the `SEQ`
   path at the same `beat_index_q`;
4. expose the insertion in the source (a new `transfer.busy` encoding plus an
   insertion clause) and add the fail-closed policy for a malformed or
   out-of-range insertion request;
5. add/narrow a requester residue for BUSY insertion and add a focused test that
   drives a burst with an inserted BUSY beat and asserts the held beat re-drives
   the same control signals, does not advance the counters, and the following
   `SEQ` beat resumes from the armed address/beat count.

## Readiness Decision

No requester generator substrate repair is required before contract selection:
the requester source already parses, reports, emits generated review artifacts,
and lowers through HDL, and all burst-progression state exists.

Direct implementation is still not selected, because the public contract surface
is genuinely open:

- **Source syntax.** The transfer block needs a `busy = 2'b01` encoding plus a
  way to declare insertion — a bounded "insert one BUSY beat before beat N"
  clause (e.g. `(busy-before-beat N)` / `(insert-busy-at N)`), a single-beat
  throttle marker, or a per-transfer policy. The exact spelling, its placement in
  `(transfer …)` versus a new `(busy …)` or `(throttle …)` block, and how
  `PPIF.pm` / `AhbRequester` record it, are open.
- **New stem vs. in-place widen.** Whether to widen `ppif/ahb_requester.ppif`
  (which would change the shipped `ahb_requester` behavior and its `t/1473`
  assertions and the `.ahb` mirror) or add a new additive source stem
  (e.g. `ahb_requester_busy_insert`) with its own support identity, coverage key,
  and generated artifact names, is open.
- **Insertion semantics.** One beat versus a policy; which point in the burst;
  and how the FSM re-enters `SEQ` after BUSY so the following beat is `SEQ` (not a
  spurious `NONSEQ`), given the current `(== beat_index_q 0)` NONSEQ/SEQ split.
- **Reporting and fail-closed.** Whether a distinct bus-BUSY indicator is exposed
  on `local_status` (kept separate from the internal activity flag), the report
  field/residue movement, and the fail-closed policy for an out-of-range or
  malformed insertion request.
- **Later sequencing.** The matching `.ahb` alias and any paired
  requester+subordinate composition demonstration.

## Selected `.787` Contract Selector

`.787` must select the public contract for the requester BUSY-insertion source.
It must settle:

- source path, intent name, source-object anchor, support identity, coverage
  key, and source kind;
- in-place widening of `ppif/ahb_requester.ppif` versus a new additive source
  stem, and the preservation consequences for `t/1473` and the shipped requester
  source and its `.ahb` mirror;
- the `.ppif` declaration for the `busy = 2'b01` encoding and the insertion
  clause, and how the parser records it (`PPIF.pm` / `AhbRequester` contract
  fields), including whether insertion is bounded to exactly one beat in the
  first slice;
- the `transfer_busy` drive block shape (drive `HTRANS = BUSY`, hold
  address/control/write-data, do not advance counters) and the beat-loop
  insertion point plus the `SEQ` re-entry so the following beat is `SEQ`;
- the fail-closed policy for a malformed or out-of-range insertion request;
- `local_status` reporting (whether a bus-BUSY indicator is exposed, kept
  separate from the internal `local_status.busy` activity flag) and the requester
  residue add/narrow, while retaining true halfword/word burst `SEQ`,
  wider/indefinite burst, multi-word/register-bank, optional-signal,
  broader-AHB, direct-backend, verification-output, backend-variant, AXI/APB, and
  VHDL residue;
- focused test shape (modeled on `t/1473` and the `t/1494` BUSY stimulus),
  `t/248` corpus-accounting and `t/297` capability-manifest impact,
  language-surface entries, mdBook example, preservation matrix, rollback; and
- the matching `.ahb` alias and any paired requester+subordinate composition
  sequencing.

## Explicit Deferrals

Requester BUSY-insertion implementation, the matching `.ahb` alias, any paired
requester+subordinate composition, halfword/word burst `SEQ`, wider or indefinite
bursts (`INCR`/`WRAP8`/`INCR8`/`WRAP16`/`INCR16`), multi-word/register-bank
progression, optional/property-gated AHB signals, legacy two-bit subordinate
`HRESP`, broader interconnect/decode, scoreboards, full-manager behavior, direct
backend behavior, verification-output generation, backend-language variants,
AXI/APB behavior, broader AHB behavior, and VHDL remain deferred.

## Validation

Closeout for `.786` is documentation-only plus targeted current-state probes and
code-read audit:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --strict --check --json ppif/ahb_lite_subordinate_byte_lane_hburst_seq_busy_park.ppif
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
the task-tree advancement, the Memory pointer update, and the regenerated
Knowledge Map entries. No runtime behavior is affected.
