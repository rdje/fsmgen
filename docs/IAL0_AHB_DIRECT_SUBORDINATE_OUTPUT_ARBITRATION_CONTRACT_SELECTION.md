# IAL0 AHB Direct Subordinate Output-Arbitration Contract Selection

Task-tree owner: `IAL0-AHB-DIRECT-SUBORDINATE-OUTPUT-ARBITRATION.1`

Date: 2026-07-29

## Outcome

Select the smallest direct-seed repair: remove exactly four redundant zero
writes from `fsm/ahb_lite_subordinate.fsm` and rely on the existing IAL0 HDL
emitter's zero-valued combinational output baseline only where a conditional
nonzero owner already exists.

This contract selection changes documentation and task state only. Proposed
implementation `.2` owns the seed and test changes after this selector commits
cleanly.

## Selected Four Writes

| State | Remove | Conditional owner that remains | Zero behavior |
| --- | --- | --- | --- |
| `access` | `HREADYOUT = 0` | successful completion writes `HREADYOUT = 1` | emitter baseline remains `0` for wait/error paths |
| `access` | `HRESP = 0` | size/address errors write `HRESP = 1` | emitter baseline remains OKAY (`0`) otherwise |
| `access` | `HRDATA = 0` | successful reads write `HRDATA = reg_data_q` | emitter baseline remains zero for waits/errors/writes |
| `unsupported` | `HRESP = 0` | final first-error cycle writes `HRESP = 1` | emitter baseline remains OKAY (`0`) while waiting |

No other IAL0 line is selected for removal. In particular, `unsupported`
retains explicit `HREADYOUT = 0` and `HRDATA = 0`, because those sources are
already exclusive and clearly document the state's output mode.

## Preserved Output Modes

- `idle` explicitly drives ready, OKAY, and zero read data.
- `access` uses the implicit zero baseline while waiting, drives ready on a
  completed supported word access, returns `reg_data_q` on reads, writes
  `HWDATA` on writes, and drives ERROR for bad size/address.
- `unsupported` explicitly stays not-ready with zero read data while its
  counter drains, then drives the first ERROR response.
- `error_complete` explicitly drives ready, ERROR, and zero read data for the
  second ERROR cycle.
- Q-named completion-edge capture and the existing idle/NONSEQ/SEQ/ERROR state
  dispatch remain unchanged.

The emitted SystemVerilog already starts each output mux with:

```systemverilog
HRDATA    = 32'b0;
HREADYOUT = 1'b0;
HRESP     = 1'b0;
```

Removing the four conflicting source writes therefore changes selector
ownership, not values or timing.

## Feasibility Evidence

A repository-local candidate removed exactly the four selected writes, then
lowered through public `bin/fsmgen`, compiled with Verilator without
`--no-assert`, and ran the existing t1520 harness. Every generated selector
assertion remained enabled. The exact results were unchanged:

```text
DIRECT_SUCCESS_ACTIVE_REPAIRED bus_accepts=2 internal_captures=2 internal_completions=2 ready_low_cycles=4 response_error_cycles=0 second_write=0 sampled_write=0 storage=11111111
DIRECT_ERROR_ACTIVE_REPAIRED bus_accepts=2 internal_captures=2 internal_completions=2 response_error_cycles=2 storage=aaaaaaaa
DIRECT_SUCCESS_SEQ_REPAIRED bus_accepts=2 internal_captures=2 internal_completions=2 response_error_cycles=2 storage=55555555
DIRECT_ERROR_IDLE_CANCEL bus_accepts=1 internal_captures=1 internal_completions=1 response_error_cycles=2 storage=00000000
```

The emitted selector set retained HRDATA/HREADYOUT/HRESP same-value and
multi-value assertions but removed the conflicting access zero owners and the
unsupported HRESP-zero owner. Unsupported HREADYOUT-zero and HRDATA-zero
owners remained.

An earlier six-write probe also passed but removed the already-exclusive
unsupported HREADYOUT/HRDATA writes. It was rejected as broader than
necessary. Its 28-file/1,116,367-byte workspace and the selected candidate's
27-file/1,102,673-byte workspace were both deleted; neither path has residue.

## Proposed Implementation `.2`

After this selector commits cleanly, implementation `.2` must:

- remove only the four selected zero writes from
  `fsm/ahb_lite_subordinate.fsm`;
- retain all other state/output/storage/transition source text;
- update t1520 structural expectations to prove the four removals, the two
  retained unsupported zero drives, explicit idle/final-ERROR ownership, and
  the emitted zero mux baselines;
- remove only Verilator's `--no-assert` option from t1520 and run all four
  existing scenarios with generic assertions enabled;
- preserve module/source/support/artifact identities, strict/check JSON,
  Q-named capture, word-only access, wait timing, read/write data, SEQ,
  two-cycle ERROR, IDLE cancellation, and exact results;
- preserve generated IAL2 endpoints and their assertion-enabled tests, generic
  selector/priority behavior, other protocols/backends/VHDL, HIAL/VIAL, and
  decision 0020;
- synchronize current seed behavior, README, roadmap, mdBook, task/index,
  Memory, and Knowledge Map; and
- use repository-derived same-volume storage plus the authorized macOS
  `--host-max-pct 100 --process-max-rss-mb 4096` profile, reporting exact
  Stats-compatible capacity and separate kernel pressure.

## Validation Boundary

Focused implementation validation is t1520 without `--no-assert`, t1211/t1219
for generic selector/priority preservation, direct strict/check JSON, and
structural emitted-HDL checks. Broader preservation includes the generated AHB
endpoint runtime t1519 plus support/capability accounting t248/t297, mdBook,
Knowledge Map, and doctrines. No new public behavior or support entry is
expected.

## Rollback

Before `.2` activation, rollback removes this contract/fact and the proposed
implementation leaf. After implementation, rollback restores the four zero
writes and t1520's `--no-assert` option as one unit; generic assertions must
not be weakened.
