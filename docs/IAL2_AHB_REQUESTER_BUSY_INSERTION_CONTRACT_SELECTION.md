# IAL2 AHB Requester BUSY-Beat Insertion Contract Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.787`

Date: 2026-07-12

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.787` selects the public contract for the
requester-side AHB single BUSY-beat insertion source and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.788`, the direct implementation of that
bounded requester BUSY-insertion source.

This selector changes no parser behavior, generator behavior, public source
sample, support-accounting catalog, capability-manifest behavior, focused test
behavior, schedule/check/semantic JSON behavior, generated artifact,
HDL/runtime behavior, direct-backend behavior, verification-output generation,
backend-language variant, AXI/APB behavior, broader AHB behavior, or VHDL
behavior.

## Evidence Read

The selector read the `.786` readiness audit, the requester sources
`ppif/ahb_requester.ppif` and `ppif/ahb_requester.ahb`, the `AhbRequester`
generator (transfer table `AhbRequester.pm:224`–`232`, drive blocks
`request_bus` `:314`/`transfer_nonseq` `:326`/`transfer_seq` `:338`, beat loop
`:430`–`466`, `_unsupported_residue` `:566`–`590`), the shipped
subordinate/aggregate BUSY-park family that already parks on a driven BUSY beat,
the PPIF adapter, support accounting (`t/248` corpus counts 297 protocol / 338
total; capability manifest via `t/297`), the language surface
(`RegressionCorpus.pm:52`, `LanguageSurfaceSection.pm:154` — the shipped
requester source generates HDL module `amba_requester`), focused AHB tests
(`t/1473` requester, `t/1494` BUSY stimulus), README, ROADMAP_V2, the mdBook AHB
chapter and backlog, the task tree, Memory, Knowledge Map, and decisions `0014`,
`0015`, `0016`, and `0018`.

## Selected Contract

### Source Surface — new additive stem

The BUSY-insertion behavior ships as a **new additive source stem**, not an
in-place widening of the shipped `ahb_requester` source. This preserves the
shipped `ppif/ahb_requester.ppif`, its `ppif/ahb_requester.ahb` mirror, its
generated `amba_requester` artifacts, and its `t/1473` assertions with zero
regression, matching the additive cadence used throughout the AHB thread.

```text
source path:      ppif/ahb_requester_busy_insert.ppif
intent name:      ahb_requester_busy_insert
actor name:       amba_requester_busy_insert
source object:    fsmgen-ahb-requester-busy-insert
support identity: intent.ppif_ahb_requester_busy_insert
coverage key:     ial2_ppif_ahb_requester_busy_insert_pipeline_cli
source kind:      ppif
generated IAL1:   amba_requester_busy_insert.isf
generated IAL0:   amba_requester_busy_insert.fsm
HDL module:       amba_requester_busy_insert
```

The source is a copy of the shipped `ppif/ahb_requester.ppif` with the actor
renamed (so the generated module is distinct) and exactly the two transfer
declarations below added. The contract `kind` stays `ahb_requester` — BUSY
insertion is a bounded option on the existing requester contract, not a new
protocol kind.

### `.ppif` BUSY-insertion declaration

The shipped requester declares three transfer types
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

The BUSY-insertion source adds a `busy` HTRANS encoding and a bounded
single-beat insertion clause:

```text
(transfer
  (idle 2'b00)
  (busy 2'b01)              ; NEW: the AHB HTRANS=BUSY encoding
  (nonseq 2'b10)
  (seq 2'b11)
  (first-beat nonseq)
  (later-beats seq)
  (advance-on ready)
  (busy-before-beat 2))     ; NEW: insert one held BUSY beat before SEQ beat index 2
```

`(busy 2'b01)` is the new HTRANS encoding, parallel to `idle`/`nonseq`/`seq`.
`(busy-before-beat N)` is the bounded insertion clause: the requester drives
exactly one `HTRANS = BUSY` beat immediately before the `SEQ` beat whose
`beat_index_q` equals `N`, holding that beat's address/control. It is preferred
over a separate `(busy …)`/`(throttle …)` block because it keeps the insertion
declaration at the transfer level where `first-beat`/`later-beats` already live
and reads as a bounded, self-describing contract term.

Because AHB BUSY holds the address of the *next* transfer of the burst and the
first beat is always `NONSEQ`, `N` ranges over the `SEQ` beats only:
`1 <= N <= max_beats - 1` (`max_beats = 16`, so `N` in `1..15`). The sample uses
`N = 2`.

### Parser change (`AhbRequester::_normalize_transfer`)

`_normalize_transfer` (`AhbRequester.pm:224`–`232`) gains two optional fields,
both defaulting to absent so every shipped source is untouched:

- `busy` — if present, must be the exact scalar `2'b01`;
- `busy_before_beat` — if present, must be a literal integer `N` with
  `1 <= N <= 15`, and requires the `busy` encoding to be present.

Fail-closed at parse: reject `busy_before_beat` without `busy`, `N` outside
`1..15`, a non-literal `N`, a duplicate insertion clause, or a `busy` encoding
other than `2'b01`. When neither field is present the transfer set is exactly the
shipped `idle`/`nonseq`/`seq` and no behavior changes.

### Generator change (`transfer_busy` drive block + beat-loop insertion)

Current-baseline note (2026-07-23): before `.788` implementation resumed,
prerequisite `ISF-MULTIBIT-LOOP-PREDICATE-TRUTHINESS-REPAIR.2` made the
existing accepted-beat terminal and non-terminal updates mutually exclusive:
remaining count `1` takes the terminal zero/clear path, while only values
strictly greater than `1` decrement and advance. This baseline correctness
repair changes none of the selected BUSY-insertion surface below.

When `busy_before_beat` is set, the generator adds one drive block and one
bounded one-shot insertion into the existing beat loop:

1. **`transfer_busy` drive block** — drives `HTRANS = BUSY`, holds `request = 1`
   and `lock`, and re-drives the same `addr_q`/`write_q`/`size_q`/`burst_q`/
   `prot_q`/`wdata_q` as the pending beat. It performs no `set`, so
   `beat_index_q`, `beats_remaining_q`, and the address do **not** advance across
   the held beat.
2. **One-shot insertion** — a `busy_inserted_q (width 1)` local (reset 0) gates a
   single BUSY cycle inside `(when HGRANT …)` in the beat loop
   (`AhbRequester.pm:432`–`466`): when `beat_index_q == N` and
   `busy_inserted_q == 0`, drive `transfer_busy` and `(set busy_inserted_q 1)`
   for exactly one cycle, skipping the `NONSEQ`/`SEQ` drive and the
   `ready`/advance handling for that cycle. The next iteration
   (`beat_index_q == N`, `busy_inserted_q == 1`) drives `transfer_seq`
   (`N >= 1`, so never `NONSEQ`) and processes `ready` normally, resuming the
   burst from the armed address/beat count.

This inserts exactly one held BUSY beat, stays inside the shipped byte-only
`WRAP4`/`INCR4` window, and adds no new register beyond the one-bit
`busy_inserted_q` flag.

### Fail-closed policy

- **Parse-time** as above (`busy` required with `busy_before_beat`, `N` literal
  in `1..15`, no duplicate).
- **Runtime** — `busy_before_beat N` is a safe no-op for any burst that never
  reaches `beat_index_q == N` (a `single` burst, an `incr` with `len = 0`, or any
  burst with fewer than `N + 1` beats): the insertion guard simply never fires,
  so the source remains valid for every runtime command without a separate error
  path.

### Report change

For the BUSY-insertion source only, the requester schedule JSON adds a
`busy_insertion` report block — `generated_behavior: true`,
`htrans_busy_encoding: "2'b01"`, `before_beat: N`, and `beats: single` (one held
BUSY beat) — and `_unsupported_residue` (`AhbRequester.pm:566`–`590`) gains a new
`ahb_requester_busy_insert_support` residue recording that bounded single held
BUSY-beat insertion is shipped while multi-beat BUSY throttling, a runtime-driven
insertion point, and requester BUSY beyond one held beat remain future work. The
shipped `ahb_requester` source keeps its exact transfer set, report, and residue.

### `local_status` reporting

No new bus-BUSY output port is added in the first slice. The inserted BUSY beat
is already observable on the existing `HTRANS` bus output; the internal
`local_status.busy` activity flag (`AhbRequester.pm:175`/`:474`) is unchanged and
keeps its "transaction in progress" meaning. A distinct `local_status.bus_busy`
indicator is deferred to a future slice if a downstream consumer needs it.

## Selected `.788` Implementation Scope

`.788` ships exactly this contract:

- add `ppif/ahb_requester_busy_insert.ppif` (copy of `ppif/ahb_requester.ppif`
  with actor `amba_requester_busy_insert`, `(busy 2'b01)`, and
  `(busy-before-beat 2)`);
- add the optional `busy` encoding and `busy_before_beat` parser fields plus
  fail-closed validation in `AhbRequester::_normalize_transfer` (and the PPIF
  adapter transfer-block parse);
- add the `transfer_busy` drive block and the `busy_inserted_q` one-shot
  beat-loop insertion, both gated on `busy_before_beat`;
- add the `busy_insertion` report block and the
  `ahb_requester_busy_insert_support` residue, gated on the insertion clause;
- support-account the source as `intent.ppif_ahb_requester_busy_insert` with
  coverage key `ial2_ppif_ahb_requester_busy_insert_pipeline_cli` and source
  kind `ppif`;
- add focused test `t/1498-ial2-ahb-requester-busy-insert.t` asserting the
  generated FSM inserts one `HTRANS = BUSY` beat before `beat_index N` that
  re-drives the same address/control and does not advance the counters, the
  following `SEQ` beat resumes from the armed address/beat count, the report
  `busy_insertion` shape and residue, parse fail-closed for `N = 0` / `N >= 16` /
  non-literal `N` / missing `busy` encoding / duplicate clause, CLI
  check/schedule/outdir, and preservation of `ppif/ahb_requester.ppif` and
  `t/1473`;
- extend `t/248` corpus accounting (protocol entries 297 → 298, total
  338 → 339) and the `t/297` capability manifest;
- add the language-surface entry and mdBook example/residue update;
- Knowledge Map, task tree, Memory, README, ROADMAP_V2 sync, and closeout
  validation (including `--verify-hdl` on the generated module).

## Explicit Deferrals

The matching `.ahb` profile alias, a paired requester+subordinate composition
demonstration, multi-beat/policy BUSY throttling, a runtime-driven insertion
point, a distinct `local_status.bus_busy` output, halfword/word burst `SEQ`,
wider or indefinite bursts, multi-word/register-bank progression,
optional/property-gated AHB signals, legacy two-bit subordinate `HRESP`, broader
interconnect/decode, scoreboards, full-manager behavior, direct backend
behavior, verification-output generation, backend-language variants, AXI/APB
behavior, broader AHB behavior, and VHDL remain deferred.

## Validation

Closeout for `.787` is documentation-only plus targeted current-state probes and
code-read audit:

```bash
./bin/fsmgen --quiet --strict --check --json ppif/ahb_requester.ppif
./bin/fsmgen --quiet --emit-schedule-json ppif/ahb_requester.ppif
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
Map fact card, the task-tree advancement, the Memory pointer update, and the
regenerated Knowledge Map entries. No runtime behavior is affected.
