# IAL2-T1436-PREEXISTING-FAILURES: pre-existing t/1436 failures (discovered, not introduced)

## Metadata

- Tree ID: `IAL2-T1436-PREEXISTING-FAILURES`
- Status: `proposed` (needs director prioritization; not PNT-eligible until then)
- Roadmap lane: `infra / test + HDL-quality hygiene`
- Created: `2026-07-12`
- Last updated: `2026-07-12`
- Owner: repo-local workflow

## Origin — discovered while verifying `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.4`

While running `t/1436-ial2-ppif-parser-cli.t` as a regression check for the AXI
AW-driver slice, 5 sub-assertions failed. Root-cause proved they are
**pre-existing and unrelated to the AW-driver change** (the `.4` commit
`21bdd0947` touched neither the failing code paths nor the failing tests; verified
with `git show --stat`/`git show`). They were already red before this session and
are surfaced here so they are tracked, not lost. `.4` itself is correctly verified
(its own `t/1499` passes, including `--verify-hdl`).

Note: `t/1436` is a very heavy test (hundreds of CLI + `--verify-hdl` invocations)
and appears not to be part of the routine gate (`scripts/check_doctrines.sh` +
targeted tests), which is likely why these drifted undetected.

## Findings

### Finding 1 — stale APB cardinality diagnostic regex (test drift)

- `t/1436-ial2-ppif-parser-cli.t` (subtest "PPIF adapter rejects malformed APB
  requester-transfer source shapes", the "apb profile rejects valid-ready object
  diagnostic is targeted" case, ~line 3686) asserts the APB cardinality error via
  a regex that ends `... or the explicit one-requester/one-completer/one-composition shape in this slice`.
- The actual message (`perl/FSM/Adapter/IAL2/PPIF.pm:459`, and the `.apb` variant
  at `:245`) was extended to `... the explicit one-requester/one-completer/one-composition shape, or the selected one-requester/multi-peripheral APB composition shape in this slice`.
- The test regex was not updated when the message gained the multi-peripheral
  clause. **Fix:** update the expected regex to match the current message (trivial,
  test-only).

### Finding 2 — `WIDTHTRUNC` verilator lint in generated capacity/status SV (HDL-quality)

- `t/1436` subtest "CLI --verify-hdl accepts AXI manager write multi-group same-ID
  queue-head response-demux behavior .ppif" (~line 5935) fails: verilator
  `--lint-only` exits nonzero on the generated
  `axi_write_multi_group_same_id_queue_head_response_demux.sv` (module
  `axi0_capacity_status`, from `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`).
- Cause: `%Warning-WIDTHTRUNC ... Logical operator LOGNOT expects 1 bit on the LHS,
  but LHS's VARREF 'concatenation_expr_plus_concatenation_expr' generates 3 bits`
  (`assign ..._eq_const_0 = !concatenation_expr_plus_concatenation_expr;`). The
  generated equality-to-zero lowering applies `!` to a 3-bit concatenation instead
  of a reduction/`== 0`.
- This is the same width-lint class the AW-driver ISF investigation flagged as
  pre-existing in some shipped generators. **Fix:** a real generator/lowering fix
  (emit `(… == 0)` or a reduction) — larger than a test edit; needs an owner.

## Non-Goals

- Not owned by, and not to be fixed inside, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.4`
  (kept clean and separately committed).
- No change to the AW-driver behavior.

## Acceptance Criteria (when activated)

- Finding 1: update the `t/1436` APB diagnostic regex; the subtest passes.
- Finding 2: correct the capacity/status equality-to-zero lowering so
  `--verify-hdl` passes verilator lint for the affected source(s); add/keep a
  guarding assertion; no behavior regression.
- Re-run `t/1436` (under resource-aware conditions) to green; record which other
  sources shared the width-lint pattern.

## Task Tree

- ID: `IAL2-T1436-PREEXISTING-FAILURES`
  Status: `proposed`
  Goal: `Fix the two pre-existing t/1436 failures discovered during the AW-driver slice: (1) the stale APB cardinality diagnostic regex, and (2) the WIDTHTRUNC verilator lint in the generated capacity/status equality-to-zero lowering.`
  Children: `(none yet — split into a test-fix leaf and a generator-lowering leaf when activated)`

## Notes

- Discovered under heavy machine-wide CPU contention from unrelated concurrent
  workloads (cargo-mutants/nexsim, LinkedSpec, phase0_regression); the `t/1436`
  run itself was killed mid-way (resource pressure), but the 5 failures reproduce
  deterministically from the assertions above (not resource-induced): Finding 1 is
  a pure-Perl message mismatch, Finding 2 is a deterministic verilator lint.
