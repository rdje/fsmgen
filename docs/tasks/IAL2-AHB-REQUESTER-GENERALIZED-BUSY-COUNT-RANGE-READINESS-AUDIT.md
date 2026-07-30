# IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT: Generalized Literal BUSY Count Readiness

## Metadata

- Tree ID: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT`
- Status: `active`
- Roadmap lane: `IAL2 / AHB requester BUSY insertion`
- Created: `2026-07-30`
- Last updated: `2026-07-30`
- Owner: repo-local workflow

## Goal

Determine the safe reusable public literal-count range above four for AHB
requester BUSY insertion, and the minimum verification contract needed to widen
that range without continuing an unbounded exact-count fixture cadence.

## Current Boundary

The shipped requester accepts absence as exact-one and literal `busy-beats`
values `2..4`. Exact-one through exact-four generic/profile requester sources
and one-/two-window paired generic/profile sources ship at 332 protocol
fixtures, 373 supported-smoke plus strict fixtures, and 56 AHB paths split 28
`.ppif` / 28 `.ahb`.

An in-memory exact-five transform fails only at the current literal `2..4`
normalization diagnostic. The lowerer already derives minimum unsigned counter
width by integer iteration: 5 and 7 map to width 3, 8 and 15 to width 4, and 16
and 31 to width 5. The existing retirement rules compare `> 1` and `== 1` and
do not special-case four. Report residue and focused diagnostics still encode
the exact-four ceiling and therefore require deliberate contract work.

## Non-Goals

- Do not assume the final upper bound before evidence compares protocol,
  source-width, runtime-cost, diagnostic, and verification constraints.
- Do not add an exact-five public fixture merely to extend the existing
  one-count-at-a-time sequence.
- Do not introduce runtime-selected, random, policy-driven, or symbolic BUSY
  counts, multiple insertion points, distinct bus-BUSY status, new burst modes,
  optional AHB signals, or new topology.
- Do not activate the protocol-neutral rule/transaction output-priority repair,
  HIAL/VIAL, verification generation, VHDL, mixed-language portability,
  large-design scalability, another protocol/backend, or decision `0020`.
- Do not change parser, generator, public source, support, test, artifact,
  report, semantic/MCP API, HDL/runtime, or simulator behavior during audit
  leaf `.1`.

## Task Tree

- ID: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT`
  Status: `active`
  Goal: `Select and prove a reusable bounded literal BUSY-count range above four before any public widening.`
  Children: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1`, `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.2`, `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.3`

- ID: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1`
  Status: `done`
  Goal: `Audit generalized literal AHB requester BUSY-count readiness and select one exact next owner.`
  Acceptance: `Activate only after clean parent selector IAL2-FEATURE-COMPLETENESS-FRONTIER.829 commit. Reconcile exact-one-through-four generic/profile requester and one-/two-window paired behavior, current 332/373/56 split 28/28 support/language/capability surfaces, AhbRequester normalization/minimum-width lowering/qualified retirement/report/residue, PPIF scalar parsing, exact-four diagnostics and assertion runtime, roadmap, mdBook, Knowledge Map, decisions 0004/0008/0020, generic selector priority, HIAL/VIAL, VHDL/portability, and scale. Compare candidate upper bounds using repository-derived same-volume disposable lowerings at every counter-width transition and assertion-enabled representative runtimes, including the first admitted value above four, ready-low and grant-low non-retirement, exact qualified-event count, one resumed SEQ, unchanged data-beat completion, zero final counter, deterministic artifact/report/semantic/read-only-MCP behavior, and fail-closed zero/one/above-bound/non-literal diagnostics. Decide whether one reusable literal range can ship without new catalog fixtures, whether a smaller exact bounded increment is required, or whether a lower-layer repair is needed. Freeze the public range, minimum-width rule, report/residue wording, focused and broader validation, preservation, support-accounting impact, documentation, cleanup, rollback, and next implementation owner before behavior changes. Keep runtime/policy/random/symbolic counts, multiple insertion points, bus-BUSY status, new burst/signal/topology semantics, generic rule/transaction priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, portability implementation, scale implementation, and decision 0020 separate. Use authorized host100/process4096, canonical Stats-compatible capacity plus separate kernel pressure, exact same-volume cleanup, and COMMIT.md.`
  Verification: `Activated only after clean parent selector commit a2750d8a6 through clean activation commit 9ff1e6ba0. Reconciled current literal 2..4 behavior, 332/373/56 split 28/28 support/language/capability surfaces, exact-four runtime and diagnostics, minimum-width lowering, reports/residue, roadmap/mdBook/Knowledge Map, decisions 0004/0008/0020, generic priority, HIAL/VIAL, VHDL/portability, and scale. The repo-local Arm AHB specification permits BUSY between burst beats and requires fixed-length bursts to terminate with SEQ, but sets no numeric BUSY-cycle maximum. Selected future literal 2..16 as FSMGen's bounded profile: it matches the requester's declared max_beats=16 and existing five-bit local length/status class; count 16 needs width 5, while values above 16 remain a deliberate future expansion rather than an AHB prohibition. A disposable repository-local module widened only normalization/static-rule/residue text and unified numeric residue. Counts 5/8/16 normalize/report exactly, derive widths 3/4/5, initialize literally, preserve unmatched support, and pass real read-only shell-disabled semantic MCP; 0/1/17/32/symbolic fail with the future 2..16 diagnostic. The structural/report/MCP/diagnostic probe passes 46 assertions. Public strict generation and --verify-hdl pass for all three candidates. Verilator 5.046 --timing/-j1 with generated selector assertions enabled passes seven runs: count 5 continuous/32-clock ready-low/32-clock grant-low, count 8 continuous, and count 16 continuous/32-clock ready-low/32-clock grant-low. Every run observes 5 transfer presentations, 4 completed data beats, 1 BUSY episode, exactly N qualified BUSY events, minimum width, stable pending address/control/data and beat state, one resumed SEQ, and zero final counter. No warning-specific suppression or --no-assert is used; standard -Wno-fatal remains. The exact 92-file/7,016,808-byte workspace is removed with no residue; only the pre-existing 491-byte xcrun_db cache remains. Selected proposed no-behavior contract `.2`: freeze literal 2..16, canonical decimal validation, unchanged minimum-width lowering, unified numeric residue, future t1541 plus a generic assertion harness, unchanged support counts and existing source bytes, preservation/rollback, and separate implementation. Dynamic/policy/random/symbolic counts, multiple insertion points, bus-BUSY status, new burst/signal/topology semantics, generic priority, HIAL/VIAL, VHDL, verification generation, portability, scale, other protocols/backends, and decision 0020 remain separate. Current public behavior remains literal 2..4 until later implementation. Current t1535+t248+t297 preservation passes 3 files/7,036 tests in 49 seconds; documentation gates pass 3 files/22 tests. Knowledge Map generation/check passes at 1,049 facts/5,378 question keys. mdBook builds to exactly 72 files/16,399,631 bytes and the exact ignored render is removed. MEMORY.md is 60 lines, README.md is 2,333 lines, .artifacts/tmp/tests is empty, diff hygiene, memory architecture, and all six doctrine gates pass. Final canonical Stats-compatible capacity is 12,597,084,160/25,769,803,776 bytes = 11.732/24.000 GiB = 48.88%, with separate macOS kernel pressure level 1; guard occupancy is excluded from capacity truth. No tracked behavior changes and no background job remains.`
  Commit: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.1: audit generalized AHB BUSY count range`

- ID: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.2`
  Status: `done`
  Goal: `Freeze the generalized literal AHB requester BUSY-count 2..16 public contract before implementation.`
  Acceptance: `Activate only after clean .1 audit commit. Read the canonical audit record/fact, repo-local Arm AHB BUSY rules, current AhbRequester normalization/minimum-width/qualified retirement/report/residue, exact-one-through-four sources/tests/runtime, support/language/capability surfaces, roadmap, mdBook, Knowledge Map, generic priority, HIAL/VIAL, VHDL/portability, scale, and decisions 0004/0008/0020. Freeze canonical decimal literal busy-beats values 2..16, absence as exact-one, zero/one/17+/leading-zero/signed/symbolic/expression/duplicate fail-closed behavior, exact diagnostic, unchanged ceil(log2(count+1)) integer-loop widths, generic qualified retirement, unified numeric residue wording, and unchanged reports/schema/artifact shapes. Freeze one future implementation that changes only AhbRequester admission/static-rule/residue plus focused t1541 and a generic assertion-enabled harness covering parse/report/diagnostic boundaries 2/4/5/7/8/15/16/17, generated widths 2/3/3/3/4/4/5, strict/schedule/artifact/semantic/real read-only MCP/public verifier, 5/8/16 runtime with required continuous and 32-clock ready/grant stalls, exact qualified events, stable ownership, one resumed SEQ, four data beats, and zero final counter. Preserve all existing source bytes and support identities, leave accounting at 332/373/56 split 28/28, require no public sample per count, and select a separate implementation leaf only if reconfirmed. Keep dynamic/policy/random/symbolic counts, multiple insertion points, bus-BUSY status, new burst/signal/topology semantics, generic priority, other protocols/backends, HIAL/VIAL, VHDL, verification generation, portability implementation, scale implementation, and decision 0020 separate. Use repository-derived same-volume workspaces, authorized host100/process4096, canonical Stats-compatible capacity plus separate kernel pressure, exact cleanup, preservation gates, docs/Knowledge Map, rollback, and COMMIT.md. Make no behavior change in contract selection.`
  Verification: `Activated only after clean .1 audit commit 18f63a971 through clean activation commit ff7206d46. Read the canonical audit record/fact, repo-local Arm AHB BUSY rules, current AhbRequester admission/width/retirement/report/residue, exact-one-through-four sources/tests/runtime, support/language/capability surfaces, roadmap, mdBook, Knowledge Map, generic priority, HIAL/VIAL, VHDL/portability, scale, and decisions 0004/0008/0020. Selected proposed lowerer/test-only `.3`. It admits only canonical decimal 2..16 through regex-equivalent [2-9]|1[0-6], preserves absence exact-one and the existing prerequisites/duplicate gate, freezes exact diagnostic 'AHB requester transfer.busy_beats must be a canonical decimal literal integer in 2..16 in this slice', preserves the ceil(log2(count+1)) integer loop and qualified >1/==1 retirement, changes only static-rule range wording plus one numeric singular/plural residue template, and adds no report/schema/artifact/semantic/MCP shape or public fixture/support identity. Frozen exact-one-through-four source blobs are db5ebaac37735cbb80a3ed7c5954eee9112e7cf8, 82d4649e24eb3da3010e1a06b529861e60491fa1, ed40621f07dc89e5cd92563d4d1c4da228baaeab, and 2f01702633a8698f7057e6f5b663f8bca6d29989; current AhbRequester is 08dcdbc107b89a0e6733d8764660d58d7bd4f359. Selected future t1541 plus one generic assertion-enabled harness for boundary/report/strict/artifact/semantic/real read-only MCP/verifier and seven 5/8/16 runtime scenarios; both future files remain absent in selection. Contract review root-caused two t1535 File::Temp calls without a repository-derived DIR; `.3` now owns their migration to .artifacts/tmp/tests while updating that already-touched test. t248+t297 pass 2 files/7,031 tests at unchanged 332/373/56 split 28/28. Focused t1518+t1256+t1414 pass 3 files/22 tests. Knowledge Map generation/check passes at 1,050 facts/5,386 question keys. The mdBook builds under authorized host100/process4096 to exactly 72 files/16,406,559 bytes and the exact render is removed. MEMORY.md is 60 lines, README.md is 2,334 lines, .artifacts/tmp/tests is empty, and only the pre-existing 491-byte xcrun_db cache contains data. Diff hygiene, memory architecture, and all six doctrine gates pass, including project-data locality. Final canonical Stats-compatible capacity is 11,705,532,416/25,769,803,776 bytes = 10.902/24.000 GiB = 45.42%, with separate macOS kernel pressure level 1 and memory_pressure 66% free; guard occupancy is excluded from capacity truth. Current public behavior remains literal 2..4; no parser, generator, public source, support, test, checked-in artifact, report/schema, semantic/MCP API, HDL/runtime, simulator, backend, protocol, HIAL/VIAL, VHDL, verification-generation, portability, scale, decision-0020, or transaction behavior changes and no background job remains.`
  Commit: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.2: select generalized BUSY count contract`

- ID: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.3`
  Status: `active`
  Goal: `Ship the selected canonical literal 2..16 AHB requester BUSY-count range through the existing lowerer without adding count-specific public fixtures.`
  Acceptance: `Activate only after the clean .2 contract-selection commit. Implement exactly the frozen contract record/fact: change only AhbRequester canonical-decimal admission from 2..4 to 2..16, its static-rule text, and the ahb_requester_busy_insert_support residue to one numeric singular/plural template; preserve absence as exact-one, busy-before-beat prerequisites, duplicate rejection, qualified >1/==1 retirement, ceil(log2(count+1)) integer-loop widths, report/schema/artifact/semantic/MCP shapes, and every existing public source byte/support identity at 332/373/56 split 28 .ppif/28 .ahb. Use exact diagnostic 'AHB requester transfer.busy_beats must be a canonical decimal literal integer in 2..16 in this slice'; accept only 2..9 and 10..16 without sign, leading zero, base prefix, fraction, symbol, reference, or expression. Add focused t/1541-ial2-ahb-requester-generalized-busy-count-range.t and t/data/ahb_requester_generalized_busy_count_tb.svt without a public fixture per count. Cover absence and 2/4/5/7/8/15/16/17 boundaries, widths 2/3/3/3/4/4/5 for admitted values, exact numeric reports, unified residue, strict/check/schedule/artifacts/semantic/real read-only shell-disabled MCP/public verifier for repository-local unmatched 5/8/16 candidates, and assertion-enabled Verilator 5.046 -j1 runtime for 5/8/16 continuous plus 32-clock ready/grant stalls at 5 and 16. Require exactly N qualified BUSY events, one episode, five presentations, four data beats, stable pending ownership/state, one resumed SEQ, zero final counter, no --no-assert, and no warning-specific suppression beyond standard -Wno-fatal. Update t1535 expectations from a 5 rejection to a 17 rejection and migrate its two File::Temp workspaces to .artifacts/tmp/tests so all touched verification is same-volume. Preserve exact-one-through-four source hashes, t1498/t1512/t1521-t1540 behavior, t248/t297 accounting, focused docs, mdBook, Knowledge Map, canonical Stats-compatible RAM plus separate pressure, exact cleanup/residue, rollback, and COMMIT.md. Keep runtime/policy/random/symbolic counts, multiple insertion points, bus-BUSY status, new burst/signal/topology semantics, generic priority, other protocols/backends, HIAL/VIAL, verification generation, VHDL, portability, scale, and decision 0020 separate.`
  Verification: `Activated only after clean .2 contract-selection commit 7e2b436cf. Activation changes task/index/Memory/roadmap/mdBook/audit/contract/facts/related-owner continuity only; current literal 2..4 behavior, 332/373/56 split 28/28 accounting, parser, generator, sources, support, tests, artifacts, reports, semantic/MCP APIs, HDL/runtime, simulator profiles, HIAL/VIAL, VHDL, portability, scale, decision 0020, and transaction behavior remain unchanged. Focused t1518+t1256+t1414 pass 3 files/22 tests. Knowledge Map generation/check passes at 1,050 facts/5,386 question keys. The mdBook builds under authorized host100/process4096 to exactly 72 files/16,408,362 bytes and the exact render is removed. MEMORY.md is 60 lines, README.md is 2,334 lines, .artifacts/tmp/tests is empty, and only the pre-existing 491-byte xcrun_db cache contains data. Diff hygiene, memory architecture, and all six doctrine gates pass, including project-data locality. Final canonical Stats-compatible capacity is 12,663,750,656/25,769,803,776 bytes = 11.794/24.000 GiB = 49.14%, with separate macOS kernel pressure level 1 and memory_pressure 67% free; guard occupancy is excluded from capacity truth. Implementation is active with no background job.`
  Commit: `IAL2-AHB-REQUESTER-GENERALIZED-BUSY-COUNT-RANGE-READINESS-AUDIT.3: ship generalized AHB BUSY count range`

## Dependencies

- `IAL2-FEATURE-COMPLETENESS-FRONTIER.829`
- `IAL2-AHB-REQUESTER-EXACT-FOUR-BUSY-INSERTION-READINESS-AUDIT`
- `IAL2-AHB-TWO-SUBORDINATE-EXACT-FOUR-PAIRED-BUSY-COMPOSITION-READINESS-AUDIT`
- decisions `0004`, `0008`, and `0020`

## Activation Gate

Active from clean parent selector commit `a2750d8a6`. Activation itself changes
continuity pointers only; all public and generated behavior remains unchanged.

## Current Frontier

Audit `.1` selected literal `2..16`; completed contract `.2` freezes exact
admission, diagnostics, numeric residue, verification, preservation, and
rollback. Implementation `.3` is active from clean contract commit
`7e2b436cf`; current public behavior remains `2..4` until `.3` ships.

## Decisions

- `2026-07-30`: The AHB protocol imposes transfer-sequencing rules but no
  numeric BUSY-cycle cap. FSMGen's selected maximum 16 is a bounded profile
  decision aligned with the requester's `max_beats=16` design class, not a
  claim that AHB forbids larger counts.
- `2026-07-30`: Select one reusable literal `2..16` contract without adding a
  catalog source or support entry per count. Preserve minimum-width lowering
  and verify the first new count, width transitions, and maximum.
- `2026-07-30`: Keep runtime/policy/random/symbolic counts and multiple
  insertion points separate from this compile-time literal widening.
- `2026-07-30`: Contract `.2` selects one lowerer/test-only `.3` implementation
  with no count-specific catalog source or support entry. It also brings the
  touched t1535 disposable workspaces onto `.artifacts/tmp/tests`.

## Rollback

Before `.3`, rollback removes the contract record/fact and proposed leaf,
restores `.2` active, and leaves literal `2..4` behavior untouched. After `.3`,
restore the three AhbRequester text/code regions plus t1535 expectations,
remove t1541 and its testbench, retain the existing source/support corpus, and
rerun every named preservation gate.
