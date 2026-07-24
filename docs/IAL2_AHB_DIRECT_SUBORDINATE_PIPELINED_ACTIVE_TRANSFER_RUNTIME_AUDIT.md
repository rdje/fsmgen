# IAL2 AHB Direct Subordinate Pipelined Active-Transfer Runtime Audit

Task-tree owner: `IAL2-AHB-PIPELINED-ACTIVE-TRANSFER-AUDIT.4`

Date: 2026-07-23

Later finding: `.5` selected atomic direct-state completion-edge capture through
the existing phase registers, but `.6` proved that internal realization unsafe
under register-input mux lowering and restored the failed attempt. `.7` selected
a Q-named `<-` four-state contract without pending/relaunch, and `.8`
implemented it. This document is historical pre-repair evidence; current
behavior is in
`docs/IAL2_AHB_DIRECT_SUBORDINATE_REGISTER_OUTPUT_COMPLETION_REPAIR.md`.

## Outcome

Before `.8`, generated-HDL t/1520 proved that the direct lower-layer seed
`fsm/ahb_lite_subordinate.fsm` silently drops a selected active address phase
accepted on either a successful or final-ERROR completion edge.

This is distinct from the generated public IAL2 family repaired by `.3`. The
generated family now has an accepted address/control bank; the direct seed is a
separate hand-authored `?fsm` source whose `ACCESS` and `ERROR_COMPLETE` states
raise ready and return to `IDLE` without sampling the simultaneously accepted
next phase.

The `.4` audit made no seed, support, artifact, port, generated-HDL, or runtime
behavior change. It historically selected `.5`; `.6` later invalidated that
leaf's D-input realization, and `.8` has since repaired the seed.

## Successful-Completion Probe

The first scenario presents a selected word-write `NONSEQ` at address zero,
then holds a distinct selected word-read `NONSEQ` while the write data phase is
not ready. When the write completes, the bus accepts that read address phase.
The direct seed does not capture or evaluate it:

```text
bus_accepts=2
internal_captures=1
internal_completions=1
second_write=0
sampled_write=1
response_error_cycles=0
storage=0x11111111
```

The differing `HWRITE` value proves that the second acceptance is a new
address/control phase rather than a duplicate observation of the first write.
Only the first write changes storage; no second read data phase completes.

## Final-ERROR Probe

The second scenario starts an unsupported selected `SEQ`, then holds a
supported selected word-write `NONSEQ` through its two-cycle ERROR response.
The final ready/ERROR edge accepts the NONSEQ address phase, but
`ERROR_COMPLETE` returns directly to `IDLE` without capturing it:

```text
bus_accepts=2
internal_captures=1
internal_completions=1
response_error_cycles=2
storage=0x00000000
```

Thus the source-backed two-cycle ERROR timing remains exact, but its active
continuation is lost. An `IDLE` presentation on the final ERROR edge would
correctly mean cancellation; the defect is specifically the absence of a path
for a selected active acceptance.

## State Root Cause

The direct seed samples address/control only in `IDLE`:

```text
IDLE + HSEL + HREADY + NONSEQ -> sample HADDR/HWRITE/HSIZE/wait_cycles -> ACCESS
IDLE + HSEL + HREADY + SEQ    -> sample wait_cycles -> UNSUPPORTED
```

On a successful word access, `ACCESS` drives `HREADYOUT=1`, performs the read
or write effect, and transitions to `IDLE`. It does not inspect HSEL, HADDR, or
HTRANS. Likewise, `ERROR_COMPLETE` drives `HREADYOUT=1`, `HRESP=1`, and
transitions to `IDLE` without inspecting the next address phase.

Because `HREADY` feeds back from `HREADYOUT` in the subordinate proof, each of
those ready edges is a bus-visible acceptance edge. Sampling after the state
transition is too late: a compliant manager may advance or retire HTRANS after
that edge. Requiring an artificial boundary would recreate the endpoint
deadlock/loss problem already established by `.1`.

## Selected Follow-On

`.5` must select the smallest direct-FSM equivalent of the generated-family
protocol contract without assuming identical internal syntax. It must freeze:

- successful and final-ERROR completion-edge detection;
- capture of one selected accepted HADDR/HTRANS/HWRITE/HSIZE/wait_cycles phase;
- live data-phase HWDATA ownership rather than address-phase capture;
- active continuation versus IDLE/BUSY/unselected handling;
- direct relaunch without a second bus acceptance;
- ready/response priority and exactly one completion/storage effect per
  accepted phase;
- preservation of the direct seed's bounded word-only/unsupported-SEQ policy,
  support identity `protocol.ahb_lite_subordinate`, ports, artifact name, and
  generated-family behavior; and
- a later lowering-safe contract, implementation/regression ownership, and rollback.

This is depth-one protocol bookkeeping, not general queueing, multiple
outstanding transfers, broader manager/interconnect behavior, or activation of
decision `0020`.

## Knowledge Map Routing Correction

Startup consultation found that historical `.807` selector fact
`ial2-post-current-surface-repair-next-owner-selection` still answered a
present-tense current-generated-subordinate question using the pre-`.3`
`ahb_access_active_q` state. `.4` makes that question and card explicitly
historical. The current generated-family answer routes to
`ial2-ahb-pipelined-active-transfer-repair`; this direct-seed result routes to
the fact accompanying this record.

## Verification And Resources

The focused t/1520 structural subtest proves that only `IDLE` samples active
address/control and that neither `ACCESS` nor `ERROR_COMPLETE` has an
HSEL/HADDR/HTRANS capture path. Its generated-HDL Verilator subtest proves the
two exact runtime outcomes above. The RAM-guarded run passes two top-level
subtests in four seconds with the 4-GiB descendant limit active.

## Rollback

Rollback removes t/1520, its testbench, this audit record/fact, the historical
Knowledge Map routing correction, and the later repair leaves, then
restores `.4` to pending. It does not repair the direct seed. Any later repair
rollback must restore seed behavior, t/1520 expectations, current seed docs,
task state, and user-facing book statements together.
