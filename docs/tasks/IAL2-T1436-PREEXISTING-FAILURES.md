# IAL2-T1436-PREEXISTING-FAILURES: pre-existing t/1436 failures (discovered, not introduced)

## Metadata

- Tree ID: `IAL2-T1436-PREEXISTING-FAILURES`
- Status: `done`
- Roadmap lane: `infra / test + HDL-quality hygiene`
- Created: `2026-07-12`
- Last updated: `2026-08-10`
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
- The exact ordering failure crosses two registry copies. Consolidated
  normalization correctly infers widths on its merged signal set, while the
  live backend and factorizer registries retain the provisional one-bit copy
  until after expression rendering. `ASTSupport` consults those live copies,
  so the later correct declaration width cannot protect the earlier rewrite.
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
  Status: `done`
  Goal: `Fix the two pre-existing t/1436 failures discovered during the AW-driver slice: (1) the stale APB cardinality diagnostic regex, and (2) the WIDTHTRUNC verilator lint in the generated capacity/status equality-to-zero lowering.`
  Children: `IAL2-T1436-PREEXISTING-FAILURES.1, IAL2-T1436-PREEXISTING-FAILURES.2`

- ID: `IAL2-T1436-PREEXISTING-FAILURES.1`
  Status: `done`
  Goal: `Align the stale APB cardinality diagnostic expectation with the shipped multi-peripheral diagnostic.`
  Acceptance: `Update only the obsolete t/1436 expectation after proving the shipped diagnostic and its provenance; run the focused APB subtest or t/1436 and the directly relevant APB tests.`
  Verification: `Commit 73013cb4f proves the product diagnostic gained the selected one-requester/multi-peripheral clause while the t1436 expectation retained the older fixed-composition wording. Updated only that regex; an in-memory valid-ready/profile-apb rejection probe reports targeted APB diagnostic: PASS. perl -Iperl -c t/1436 reports syntax OK. With TMPDIR=.artifacts/tmp/tests, t1470 profile aliases and t1472 APB composition report All tests successful, Files=2, Tests=115. Product parser, diagnostics, PPIF sources, generators, and behavior are unchanged.`
  Commit: `IAL2-T1436-PREEXISTING-FAILURES.1: align APB diagnostic expectation`

- ID: `IAL2-T1436-PREEXISTING-FAILURES.2`
  Status: `done`
  Goal: `Prevent multi-bit factored intermediates from being simplified as Boolean before authoritative width inference.`
  Acceptance: `Add a focused x==0/x==1 multi-bit intermediate regression; repair the width/simplification ordering or fail-closed classifier; prove the exact queue-head response-demux reproducer and representative read/write affected shapes with Verilator and Yosys; run t/1436 to green without weakening lint.`
  Verification: `Factorization now records unresolved_factorization_ast instead of claiming one bit; consolidated normalization publishes inferred width and provenance to both live registries before rendering; unresolved intermediate classification fails closed. Focused factorization/AST/width/normalization tests pass Files=5 Tests=6, adjacent fixpoint tests pass Files=4 Tests=6, and truthiness tests pass Files=2 Tests=8. The exact write multi-group reproducer plus read multi-group, write mixed-depth, and read-burst mixed-depth representatives all pass --verify-hdl with Verilator and Yosys; generated zero/one assignments are (~|three_bit_value) and three_bit_value == 3'd1. The complete t1436 suite passes All tests successful, Files=1, Tests=346, in 6457 wall-clock seconds. A required RAM-guard rerun later stopped safely at host memory 88.6% versus the 88% cutoff (exit 137, complete PID tree terminated); per COMMIT.md it was recorded and not continued unbounded. Existing mdBook truthiness prose already states the repaired reduction contract, so no user-contract text changed.`
  Commit: `IAL2-T1436-PREEXISTING-FAILURES.2: preserve multi-bit truthiness comparisons`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| — | none | `done` | Both repair leaves are complete; return to `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.4`. |

## Decisions

- `2026-08-09`: Activate this existing repair tree as a prerequisite discovered
  during `IAL2-MDBOOK-COHERENCE-AXI-COVERAGE.3`. The director delegated roadmap
  choice and autonomous engineering decisions; `.4` cannot truthfully call the
  affected response-demux/queue-head examples lowering-clean until `.2` is
  repaired. Complete the independent APB expectation leaf first, then the
  width/simplification leaf, committing each separately before returning.
- `2026-08-10`: Treat factorizer width as unresolved until backend inference,
  publish normalized widths to every live registry before expression rendering,
  and classify an unresolved intermediate conservatively. This removes false
  metadata at its source, repairs the copied-registry ordering, and preserves
  the existing optimized form only when one-bit width is authoritative.

## Acceptance Checklist (enforced) — `.2` intermediate-width ordering repair

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'width         => 1' --
  perl/FSM/HDL/ASTFactorization.pm` locates the provisional scalar seed at
  `57563dcaa4`; `git log -S '_simplify_truthiness_comparison' --
  perl/FSM/Synthesis/EnableGraph/ASTSupport.pm` locates the rewrite at
  `425f03d1b`. Runtime inspection then proved consolidated width inference
  updated only the merged copy before render, while live backend/factorizer
  copies still reported one bit.
- [x] **ADDRESSED (verified)** — Factorization now emits unresolved width
  metadata, normalization publishes inferred width/provenance before any
  expression render, and unresolved AST classification fails closed. The exact
  former Verilator failure now emits
  `(~|concatenation_expr_plus_concatenation_expr)` for zero and preserves
  `concatenation_expr_plus_concatenation_expr == 3'd1` for one; the exact source
  plus three representative read/write and mixed-depth shapes pass both
  `verilator_lint` and `yosys_synthesis` through `--verify-hdl`.
- [x] **NO REGRESSION** — Focused and adjacent clusters report `All tests
  successful` at `Files=5, Tests=6`, `Files=4, Tests=6`, and `Files=2,
  Tests=8`. The complete `t/1436-ial2-ppif-parser-cli.t` run reports `All tests
  successful`, `Files=1, Tests=346`. A subsequent mandated RAM-guard rerun
  stopped safely at host memory 88.6% versus the 88% cutoff (exit 137); its PID
  tree is gone and the already-complete green run remains the regression
  result.

## Acceptance Checklist (enforced) — `.1` APB expectation alignment

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S 'selected
  one-requester/multi-peripheral APB composition shape'` identifies
  `73013cb4f`: the product diagnostic gained the multi-peripheral alternative,
  while the older `t/1436` regex still ended at fixed composition.
- [x] **ADDRESSED (verified)** — The test expectation now matches the complete
  shipped diagnostic. The in-memory valid-ready/profile-apb rejection probe
  prints `targeted APB diagnostic: PASS`; `perl -Iperl -c t/1436-ial2-ppif-parser-cli.t`
  reports `syntax OK`.
- [x] **NO REGRESSION** — With repository-local `TMPDIR`, `t/1470` plus
  `t/1472` report `All tests successful`, `Files=2, Tests=115`. Only the stale
  expectation changed; parser code, product diagnostics, public PPIF sources,
  generated artifacts, and behavior are byte-identical to the parent commit.

## Notes

- Discovered under heavy machine-wide CPU contention from unrelated concurrent
  workloads (cargo-mutants/nexsim, LinkedSpec, phase0_regression); the `t/1436`
  run itself was killed mid-way (resource pressure), but the 5 failures reproduce
  deterministically from the assertions above (not resource-induced): Finding 1 is
  a pure-Perl message mismatch, Finding 2 is a deterministic verilator lint.
