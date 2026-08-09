# IAL2-T1436-PREEXISTING-FAILURES: pre-existing t/1436 failures (discovered, not introduced)

## Metadata

- Tree ID: `IAL2-T1436-PREEXISTING-FAILURES`
- Status: `active`
- Roadmap lane: `infra / test + HDL-quality hygiene`
- Created: `2026-07-12`
- Last updated: `2026-08-09`
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
  diagnostic is targeted" case) asserts the APB cardinality error via a regex
  at current line `3677` that ends `... or the explicit
  one-requester/one-completer/one-composition shape in this slice`.
- The actual message (`perl/FSM/Adapter/IAL2/PPIF.pm:702`, and the `.apb` variant
  at `:275` on `2026-08-09`) was extended to `... the explicit
  one-requester/one-completer/one-composition shape, or the selected
  one-requester/multi-peripheral APB composition shape in this slice`.
- The test regex was not updated when the message gained the multi-peripheral
  clause. **Fix:** update the expected regex to match the current message (trivial,
  test-only).
- Exact provenance: commit `73013cb4f` shipped multi-peripheral decode and
  changed both product diagnostics. The current `t/1436` case at line `3677`
  retains the earlier expectation. This is expectation drift, not a product
  diagnostic regression.

### Finding 2 — `WIDTHTRUNC` verilator lint in generated capacity/status SV (HDL-quality)

- `t/1436` subtest "CLI --verify-hdl accepts AXI manager write multi-group same-ID
  queue-head response-demux behavior .ppif" (~line 5935) fails: verilator
  `--lint-only` exits nonzero on the generated
  `axi_write_multi_group_same_id_queue_head_response_demux.sv` (module
  `axi0_capacity_status`, from `perl/FSM/IAL2/ProtocolIntent/AxiManagerCapacityStatus.pm`).
- Cause: `%Warning-WIDTHTRUNC ... Logical operator LOGNOT expects 1 bit on the LHS,
  but LHS's VARREF 'concatenation_expr_plus_concatenation_expr' generates 3 bits`
  (`assign ..._eq_const_0 = !concatenation_expr_plus_concatenation_expr;`). A
  paired `..._eq_const_1` assignment also copies the same three-bit expression
  into a one-bit wire. The generated equality-to-zero/equality-to-one lowering
  has treated a multi-bit intermediate as Boolean.
- The exact standalone reproducer is
  `ppif/axi_manager_capacity_status_write_multi_group_same_id_queue_head_response_demux.ppif`:
  `./bin/fsmgen --verify-hdl` fails under Verilator `5.046`, while the generated
  declaration correctly gives the intermediate width `[2:0]`.
- Root-cause locus: `perl/FSM/HDL/ASTFactorization.pm` seeds every factored
  intermediate with `width => 1`; then
  `perl/FSM/Synthesis/EnableGraph/ASTSupport.pm::_simplify_truthiness_comparison`
  consults that stale width through `_node_is_booleanish` and rewrites `x == 0`
  to `!x` or `x == 1` to `x`. The later SystemVerilog
  `IntermediateSignalWidthSupport` correctly infers the declaration width, but
  it runs too late to recover the removed comparison. The default-width seed
  dates to `57563dcaa4`; the truthiness rewrite was introduced by `425f03d1b`.
- The same mechanism reproduces across write/read multi-group, multi-depth-3,
  mixed-depth response-demux, and read-data queue-head fixtures observed in the
  `2026-08-09` run; this is one shared lowering defect, not several fixture
  defects.
- This is the same width-lint class the AW-driver ISF investigation flagged as
  pre-existing in some shipped generators. **Fix:** a real generator/lowering fix
  (emit `(… == 0)` or a reduction) — larger than a test edit; needs an owner.

## Non-Goals

- Not owned by, and not to be fixed inside, `IAL2-AXI-MANAGER-INITIATOR-FRONTIER.4`
  (kept clean and separately committed).
- No change to the AW-driver behavior.

## Acceptance Criteria (when activated)

- Finding 1: update the `t/1436` APB diagnostic regex; the subtest passes.
- Finding 2: make truthiness simplification consume authoritative intermediate
  width or fail closed when that width is unresolved. Preserve multi-bit
  comparisons/reductions so `x == 0` and `x == 1` cannot become `!x` and `x` for
  a multi-bit factored expression. Add a focused lowering regression covering
  both constants and prove `--verify-hdl` with Verilator and Yosys on the exact
  reproducer plus representative read/write multi-group and mixed-depth sources.
- Re-run `t/1436` (under resource-aware conditions) to green; record which other
  sources shared the width-lint pattern.

## Task Tree

- ID: `IAL2-T1436-PREEXISTING-FAILURES`
  Status: `active`
  Goal: `Fix the two pre-existing t/1436 failures discovered during the AW-driver slice: (1) the stale APB cardinality diagnostic regex, and (2) the WIDTHTRUNC verilator lint in the generated capacity/status equality-to-zero lowering.`
  Children: `IAL2-T1436-PREEXISTING-FAILURES.1, IAL2-T1436-PREEXISTING-FAILURES.2`

- ID: `IAL2-T1436-PREEXISTING-FAILURES.1`
  Status: `pending`
  Goal: `Align the stale APB cardinality diagnostic expectation with the shipped multi-peripheral diagnostic.`
  Acceptance: `Update only the obsolete t/1436 expectation after proving the shipped diagnostic and its provenance; run the focused APB subtest or t/1436 and the directly relevant APB tests.`
  Verification: `pending`
  Commit: `pending`

- ID: `IAL2-T1436-PREEXISTING-FAILURES.2`
  Status: `pending`
  Goal: `Prevent multi-bit factored intermediates from being simplified as Boolean before authoritative width inference.`
  Acceptance: `Add a focused x==0/x==1 multi-bit intermediate regression; repair the width/simplification ordering or fail-closed classifier; prove the exact queue-head response-demux reproducer and representative read/write affected shapes with Verilator and Yosys; run t/1436 to green without weakening lint.`
  Verification: `pending`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `IAL2-T1436-PREEXISTING-FAILURES.1` | `pending` | Align the stale APB expectation first as the smaller independent failure. |
| 2 | `IAL2-T1436-PREEXISTING-FAILURES.2` | `pending` | Repair authoritative intermediate width before resuming the AXI queue-head documentation examples. |

## Decisions

- `2026-08-09`: Activate this existing repair tree as a prerequisite discovered
  during `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.3`. The director delegated roadmap
  choice and autonomous engineering decisions; `.4` cannot truthfully call the
  affected response-demux/queue-head examples lowering-clean until `.2` is
  repaired. Complete the independent APB expectation leaf first, then the
  width/simplification leaf, committing each separately before returning.

## Notes

- Discovered under heavy machine-wide CPU contention from unrelated concurrent
  workloads (cargo-mutants/nexsim, LinkedSpec, phase0_regression); the `t/1436`
  run itself was killed mid-way (resource pressure), but the 5 failures reproduce
  deterministically from the assertions above (not resource-induced): Finding 1 is
  a pure-Perl message mismatch, Finding 2 is a deterministic verilator lint.
