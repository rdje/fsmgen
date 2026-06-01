# ISF-COUNTED-REPEAT-TERMINATION: Counted `(repeat N …)` Loops Must Terminate

## Metadata

- Tree ID: `ISF-COUNTED-REPEAT-TERMINATION`
- Status: `active`
- Roadmap lane: `R14` (ISF lowering correctness)
- Created: `2026-06-01`
- Last updated: `2026-06-01`
- Owner: repo-local workflow

## Goal

Fix a **correctness** bug: counted `(repeat N …)` loops lower to hardware that **never
terminates** for `N >= 2`. The body runs forever and the transaction's completion never
asserts. This is foundational — `(repeat …)` underlies the UART/I2C/SPI fixtures, the
`for`-loop desugar (`ISF-FOR-LOOP`), and most counted control flow.

## Evidence (simulation, 2026-06-01)

Verilator `--binary` testbenches (the gates do **not** simulate — they are all structural:
verilator lint, yosys synth, lowering-structure, `--check-json` wiring):

- No-loop FSM (`(on start)(update …)(complete done)`) → `done` asserts at cycle 2
  (testbench is sound).
- Plain `(repeat 4 (update result din))` → **no `done` in 60 cycles** (spins).
- `(for (i 4) …)` desugar → body runs repeatedly, index climbs past N, **no `done`**.
- Hand-fixed `.fsm` (counter loaded once, loop-back to the body not init, decision
  `(?cnt (=0 -> done)(>0 (-- cnt)(-> body)))`) → terminates; an accumulating body yields
  `result == N` (exactly N iterations). **Fix shape proven.**

## Root cause (two coupled defects, downstream of correct IR)

The lowering IR is correct: `_link_states` builds `repeat_check` transitions as
`{counter != 0 -> loop}` / `{counter == 0 -> done}`. Two defects corrupt it on the way to
HDL:

1. **Topology** — `_ir_repeat` sets the loop-back `loop_target = $s[0]{name}`, the
   `repeat_init` state, which **reloads the counter** (`cnt <= N`) on every loop-back, so
   the decrement never sticks and `cnt` never reaches 0 at the check.
2. **Decision rendering** — `Emitter/FSM.pm` renders the IR's `op '!='` (nonzero /
   continue) edge as `(=1 -> …)`. But `(=1)` means "== 1" in the `.fsm` language, so the
   core SV emitter produces `main_cnt == 1'b1` (true only at value 1), not a nonzero test.
   (The `=0` / done edge correctly renders `~|cnt`.)

## Design (Option B — body-first, minimal churn; correct for static/runtime/zero counts)

Keep the current `init -> body … -> check` state order (so the spawn/do/await-in-repeat
and cross-domain-handshake machinery, which depend on body adjacency and re-run the body
from its first state each iteration, are undisturbed). Three coordinated changes:

1. `_ir_repeat`: `loop_target` = the **first body state** (`$s[1]`) instead of
   `repeat_init` (`$s[0]`) — the loop-back skips the counter reload. (Empty body: loop
   back to the check itself.)
2. `_repeat_count_load_value`: load **`count - 1`** instead of `count`. Body-first runs the
   body once before the first check, so loading `N-1` yields exactly `N` iterations
   (`cnt = N-1 … 0`, continue while `!= 0`). Runtime/param counts: literal/param decrement
   numerically; a runtime signal loads `(- signal 1)` — and runtime `count == 0` is
   **already** handled by the existing `_link_repeat_init_state` zero-branch (skips to
   done before the body), so the `- 1` is only reached for `count >= 1`.
3. `Emitter/FSM.pm` `repeat_check`: render the `!=` (continue) edge as `(>0 (-> loop))`
   and the `=` (done) edge as `(=0 (-> done))`. `(>0)` renders a correct nonzero test
   (`cnt > 1'b0`) instead of the broken `== 1'b1`.

Why not check-first (init→check→body): it also works and is arguably cleaner for
`count == 0`, but it reorders states and rewires body→check adjacency, which is riskier
for the heavily-developed spawn/do/await-in-repeat-body features. Option B is correct for
all count kinds with far less churn.

## Slice plan

- `.1` select (this doc) with the simulation evidence + proven fix shape.
- `.2` the termination fix (Option B): the three changes above; update the ~18 affected
  `.fsm`/SV goldens; verify with **simulation** (static N, runtime count, count 0/1,
  nested, do-in-repeat) + full `isf` regression. The decision becomes `(>0 -> body)
  (=0 -> done)`; counter loads `N-1`; loop-back targets the body.
- `.3` (frontier) width-cleanliness: the `(>0)` edge renders `cnt > 1'b0`
  (WIDTHEXPAND — 3-bit vs 1-bit literal). Make the nonzero decision edge verilator-clean
  (width-matched literal or `|cnt` reduction) so counted loops pass `--verify-hdl`.

## Non-Goals

- Reworking the loop structure beyond what termination requires (no check-first rewrite).
- The general multi-bit decision-literal width issue beyond the repeat counter edge
  (handled in `.3` for the repeat path; a broader sweep is separate if wanted).

## Acceptance Criteria

- A counted `(repeat N …)` loop runs its body **exactly N times** and then completes, for
  static literal, actor/transaction-param, package-constant, and runtime-signal counts
  (and 0/1 edge counts), proven by simulation; spawn/do/await-in-repeat and
  cross-domain-handshake-in-repeat still behave correctly; full `isf` regression green;
  goldens updated to the corrected structure. `.3` additionally makes counted loops pass
  `--verify-hdl`. Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-COUNTED-REPEAT-TERMINATION`
  Status: `active`
  Goal: `Counted (repeat N …) loops must terminate after exactly N iterations (currently spin forever for N>=2).`
  Children: `.1` (select + evidence), `.2` (termination fix, Option B), `.3` (frontier: decision-edge width-cleanliness)

- ID: `ISF-COUNTED-REPEAT-TERMINATION.1`
  Status: `done`
  Goal: `Select; prove the bug + fix shape by simulation; design Option B (body-first, loop-back to body, init count-1, (>0)/(=0) decision).`
  Acceptance: `Task tree committed before any code change; root cause + proven fix recorded.`
  Verification: `verilator --binary sims (no-loop terminates; plain repeat + for-loop spin; hand-fixed .fsm terminates exactly N); mdbook build; git diff --check`
  Commit: `this slice`

- ID: `ISF-COUNTED-REPEAT-TERMINATION.2`
  Status: `done`
  Goal: `Termination fix (check-first): init -> check (load count once, raw copy); repeat_check loop_target -> first body state; decrement via the '--' operator; Emitter/FSM.pm repeat_check continue edge -> (>0 -> body)(=0 -> done).`
  Acceptance: `Counted (repeat N …) runs body exactly N times then completes for static literal, param/constant, and runtime-signal counts and 0/1 edges; spawn/do/await-in-repeat + cross-domain-handshake-in-repeat re-arm correctly each iteration; goldens updated to the corrected .fsm structure; full suite PASS; simulation confirms exactly-N termination. A runtime (wait …) as the FIRST statement of a repeat body fails closed with a clear diagnostic (deferred to .3); non-first and static waits unaffected.`
  Verification: `Simulated (verilator --binary): static N=1/4/7 -> result==N; runtime n=5/0/1 -> exactly n (0 -> immediate done); non-first runtime wait-in-repeat -> count==3 terminates; runtime-wait-FIRST -> fail-closed. Implemented as Option A (check-first) not Option B (count-1 load) because a (- n 1) load is a second counter expression-assignment that aliases the one-hot selector enable. Goldens updated across t/1202 1360 1095 1228 1310 1311 1244 1379 1381 1383 1387 1215 1103 1111. Full suite prove -j6 -Iperl t/ -> 1402 files / 10165 tests PASS; perl -c; mdbook build; git diff --check.`
  Commit: `this slice`

- ID: `ISF-COUNTED-REPEAT-TERMINATION.3`
  Status: `frontier`
  Goal: `(a) Support a runtime (wait …) as the FIRST statement of a repeat body (currently fail-closed in .2): the check-first loop must (re)load the wait counter on the loop-back edge and compute the correct zero-bypass target; restore the t/1244 coverage converted to fail-closed assertions in .2. (b) Make the counted-loop decision edge verilator-clean: the (>0) continue edge renders cnt > 1'b0 (WIDTHEXPAND, 3-bit vs 1-bit literal), so counted loops do not yet pass --verify-hdl; width-match the literal or use a |cnt reduction.`
  Acceptance: `TBD when scheduled.`
  Verification: `TBD`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `.1` | `done` | Bug proven by simulation; fix shape proven; design recorded. |
| 2 | `.2` | `done` | Termination fix landed (check-first); simulation confirms exactly-N for static/runtime/zero; full suite PASS (1402 files). Runtime-wait-first-in-repeat fails closed (deferred to `.3`). |
| 3 | `.3` | `frontier` | Restore runtime-wait-first-in-repeat (+ its t/1244 coverage); make the `(>0)` decision edge verilator-clean (`cnt > 1'b0` WIDTHEXPAND) so counted loops pass `--verify-hdl`. |

## Decisions

- `2026-06-01`: chosen as a stop-everything correctness fix (user: "fix repeat
  termination first") on discovering counted `(repeat N …)` spins forever. Option B
  (body-first, minimal churn) over check-first because it leaves the spawn/do/await and
  cross-domain-handshake-in-repeat machinery undisturbed while being correct for all count
  kinds (the existing init zero-branch already handles runtime `count == 0`). The
  `ISF-FOR-LOOP.2` desugar is parked (stashed) until this lands, since it desugars onto
  `(repeat …)`.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-01` | `.1` | verilator `--binary` sims (no-loop terminates @ cy2; plain repeat-4 + for-loop spin; hand-fixed .fsm terminates, accumulating body == N); `mdbook build`; `git diff --check` | `PASS` |
| `2026-06-01` | `.2` | verilator `--binary`: static N=1/4/7 → result==N; runtime n=5/0/1 → exactly n; non-first runtime wait-in-repeat → count==3 terminates; runtime-wait-FIRST → fail-closed. Full suite `prove -j6 -Iperl t/` → 1402 files / 10165 tests PASS; `perl -c`; `mdbook build`; `git diff --check` | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `.1` | `ISF-COUNTED-REPEAT-TERMINATION.1: select + prove counted-repeat non-termination` | `bb… (committed)` |
| `.2` | `ISF-COUNTED-REPEAT-TERMINATION.2: check-first counted-repeat termination` | this slice |

## Changelog

- `2026-06-01`: Created on discovering (by simulation) that counted `(repeat N …)` loops
  never terminate for `N >= 2` — the loop-back reloads the counter at `repeat_init` and
  the continue edge mis-renders as `main_cnt == 1'b1`. The bug hid because no verification
  gate simulates. Fix shape (counter loaded once, loop-back to the body, `(=0 -> done)
  (>0 (-- cnt) -> body)` decision) proven by simulation.
- `2026-06-01`: `.2` shipped — **check-first** counted-repeat lowering. `repeat_init` now
  loads the count once (raw copy) and flows to `repeat_check`; the check decrements via
  `--`, continues to the first body state on `(>0 …)`, and exits on `(=0 …)`. This
  terminates after exactly N iterations for static literal, param/constant, and
  runtime-signal counts (and 0/1 edges), proven by `verilator --binary` simulation; the
  spawn/do/await-in-repeat and cross-domain-handshake-in-repeat machinery re-arm correctly
  each iteration (the body re-runs from its first state). Chosen over the body-first
  `count-1`-load variant because a `(- n 1)` load is a second counter expression-assignment
  that aliases the one-hot write-enable selector and trips a false multi-driver assertion;
  the raw-copy load keeps the decrement the only counter expression. Goldens updated across
  `t/1202 1360 1095 1228 1310 1311 1244 1379 1381 1383 1387 1215 1103 1111`. A runtime
  `(wait …)` as the FIRST statement of a repeat body fails closed with a clear diagnostic
  (its t/1244 coverage was converted to fail-closed assertions) — deferred to `.3`;
  non-first and static waits are unaffected. Full suite (`prove -j6 -Iperl t/`) → 1402
  files / 10165 tests PASS.
