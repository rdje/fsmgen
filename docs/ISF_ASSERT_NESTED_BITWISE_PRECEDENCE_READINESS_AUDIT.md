# ISF Nested-Bitwise Assertion Precedence Readiness Audit

## Outcome

`ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.1` selects one bounded general
repair for implementation `.2`: when concurrent-check rendering substitutes an
inlineable intermediate `SignalRef` with that signal's driving AST, the
rendered replacement must remain one explicitly grouped SystemVerilog
subexpression.

This preserves the semantic boundary that the intermediate occupied without
changing the expression grammar, CoreAST operator registry, behavioral
lowering, AXI admission set, temporal-property operators, or emitter. The audit
itself changes no product behavior. It adds a deterministic readiness
characterization of the current defect in
`t/1544-isf-assert-nested-bitwise-precedence-readiness.t`; implementation `.2`
must turn that characterization into the repaired contract.

## Deterministic Reproduction

The public fixed-four AXI read composition generates a coordinator assertion
whose source carrier contains this exact nested boundary predicate:

```text
(! (& cmd_read_addr[11] cmd_read_addr[10] ... cmd_read_addr[4]
      (| cmd_read_addr[3] cmd_read_addr[2])))
```

The behavioral path materializes the nested OR and consumes its signal as one
AND operand:

```systemverilog
assign intermediate_complex_expr_10 =
    cmd_read_addr[3] | cmd_read_addr[2];
assign intermediate_and_intermediate_complex_expr_10_11 =
    cmd_read_addr[11] & cmd_read_addr[10] & cmd_read_addr[9]
    & cmd_read_addr[8] & cmd_read_addr[7] & cmd_read_addr[6]
    & cmd_read_addr[5] & cmd_read_addr[4]
    & intermediate_complex_expr_10;
```

Concurrent-check rendering follows that intermediate's driving AST and emits:

```systemverilog
cmd_read_addr[11] & cmd_read_addr[10] & cmd_read_addr[9]
& cmd_read_addr[8] & cmd_read_addr[7] & cmd_read_addr[6]
& cmd_read_addr[5] & cmd_read_addr[4]
& cmd_read_addr[3] | cmd_read_addr[2]
```

SystemVerilog gives bitwise AND higher precedence than bitwise OR. The property
therefore means `(high & bit3) | bit2`, not `high & (bit3 | bit2)`. A legal
four-byte-aligned address `0x00000004` has bit 2 high and all high boundary
bits low, so the behavioral guard admits it while the malformed assertion
rejects it.

The readiness test proves all of the following through the public generator:

- direct `FSM::CoreAST::BinaryOp` rendering produces
  `high & (bit3 | bit2)` correctly;
- the generated assertion root is an overlapping-implication property whose
  consequent enters `GeneratedModuleInfoBuilder` through an inlineable
  `FSM::CoreAST::SignalRef`;
- the behavioral HDL retains the OR intermediate and consumes it as one AND
  operand; and
- `condition_sv` plus final concurrent-property HDL reproduce the missing
  grouping.

Run the tracked reproduction with project-local temporary storage and the
canonical macOS verification profile:

```bash
scripts/run_with_ram_guard.sh --host-max-pct 100 --process-max-rss-mb 4096 -- \
  env TMPDIR=.artifacts/tmp/tests \
  prove -v t/1544-isf-assert-nested-bitwise-precedence-readiness.t
```

## Exact Root Cause

The parsed coordinator does not mix `FSM::AST` and `FSM::CoreAST`. Its property
leaves, inlineable signal references, binary operators, unary operators,
indexed references, and literals are all `FSM::CoreAST` objects.

`FSM::CoreAST::BinaryOp->to_systemverilog` is precedence-aware. When it receives
the actual nested OR object as the right child of AND, it passes the parent
precedence into that child and inserts the required parentheses.

`GeneratedModuleInfoBuilder::_render_check_condition_sv` has an additional
responsibility: inline intermediate signals so property text does not depend
on generated temporary names. When a `SignalRef` is inlineable, the helper
recursively renders the driving AST and returns the resulting string. If the
driving AST is a top-level OR, its standalone rendering correctly needs no
parentheses. The caller then concatenates that already-rendered string into an
AND expression, after the child-parent AST relationship and precedence context
have been erased. Parenthesizing the whole outer AND does not restore the lost
boundary.

The ownership boundary is consequently the intermediate-substitution branch
of `_render_check_condition_sv`. Neither the parser, assertion carrier,
CoreAST operator registry, behavioral lowerer, nor
`GeneratedModuleEmitter::immediate_assertion_runtime_lines` loses the grouping.

## Candidate Comparison

### Selected: group every successfully substituted intermediate

After recursively rendering an inlineable signal's driving AST, return that
replacement as one parenthesized expression. This is the textual equivalent of
substituting an AST node at the original `SignalRef` position. It is independent
of the parent operator and therefore covers nested AND/OR/XOR, arithmetic,
comparison, shift, unary, concatenation, conditional, and property-leaf
contexts without enumerating fragile precedence pairs. Parentheses around a
SystemVerilog expression preserve meaning even when they are redundant.

Cycle handling and fail-closed behavior remain unchanged: a detected cycle
continues to fall back to the signal name, and an unrenderable driving AST still
does not surface a check.

### Rejected: repair only OR beneath AND

Special-casing `&` with a `|` child repairs the observed string but leaves every
other lower-precedence substituted expression exposed. The failure mechanism
is erased AST context, not one operator pair.

### Rejected: pass precedence through the whole property renderer

Adding parent-precedence parameters to every property, CoreAST, unary,
concatenation, and conditional branch could also work, but it duplicates the
canonical operator registry contract and expands the change surface. Grouping
the substituted AST boundary is both smaller and semantically complete.

### Rejected: stop inlining intermediate signals

Keeping temporary names would preserve this generated module today, but would
change the established property portability boundary and make checks depend on
whether a temporary survives later generated-module analysis. That larger
contract change is unnecessary.

### Rejected: change CoreAST or rewrite the AXI predicate

The direct CoreAST renderer is correct. A De Morgan or source-level AXI rewrite
would only hide this compiler defect from the current fixture and leave other
generated checks vulnerable.

## Implementation And Coverage Contract

Implementation `.2` is limited to the concurrent-check rendering boundary and
focused preservation proof:

1. In `GeneratedModuleInfoBuilder`, preserve one explicit grouping boundary
   around every successfully rendered inline-intermediate replacement. Do not
   change `_check_signal_ref_should_inline`, property combinator spelling,
   formal-only classification, assertion kind/message handling, or the
   emitter.
2. Extend t1410 only as needed to prove the nested carrier remains a CoreAST
   tree with the authored AND/OR relationship. Parser syntax and carrier
   semantics must not change.
3. Extend t1411 with direct and inline-intermediate render cases. The two forms
   must be equivalent, and the inlined form must include grouping at the
   substitution boundary.
4. Extend t1412 so nested boolean leaves retain grouping inside overlapping
   implication and sampled/temporal wrappers without changing their SVA
   operators or formal-only status.
5. Reconcile t1544 from defect characterization to the repaired general and
   AXI outputs.
6. Run t1507 with assertions enabled, add a legal `0x00000004` command, and
   prove the generated design accepts it without a false property failure.
   Existing illegal-address, ID, RLAST, error-drain, reset, and cardinality
   coverage must remain intact.

Focused gates are t1410-t1412, t1544, and t1507. Broader preservation includes
the generated-HDL/backend facade gate used by t404 plus the ordinary book,
Knowledge Map, task/status/path, doctrine, and clean-artifact checks.

## Preserved Boundaries

The selected repair does not:

- widen IAL0, IAL1, IAL2, HIAL, or VIAL syntax;
- alter AXI fixed-four read admission, output, timing, or cardinality;
- weaken, disable, or synthesize away verification checks;
- change direct SystemVerilog/VHDL behavioral expression rendering;
- claim full-SystemVerilog/UVM support from Verilator;
- change formal-only delayed-property classification;
- alter report, semantic, MCP, support-accounting, or capability schemas; or
- activate HIAL/VIAL, big-design scale, simulator qualification, protocol
  expansion, maintenance, or decision-`0020` work.

## Closeout Evidence

- Tracked t1544 passes 2 top-level subtests/13 nested assertions. It freezes
  correct direct CoreAST precedence, the overlapping-property and inlineable-
  consequent shape, correct behavioral factoring, malformed `condition_sv`,
  and the same malformed emitted property.
- The focused t1410-t1412+t1544+t1507 aggregate passes 5 files/23 top-level
  tests. This preserves the carrier, builder/emitter, temporal implication,
  public AXI/report/semantic/verifier surfaces, and current assertion-disabled
  runtime while `.2` remains inactive. The HDL facade t404 passes 1 file/4
  tests.
- Book/status/path truth gates pass 4 files/46 tests. One broader command
  accidentally included the already tracked pre-existing t1250 focused-index
  drift and failed only that stale list comparison; rerunning the exact current
  gate without the separately owned test passed, and no product failure was
  observed.
- Knowledge Map generation/check passes at 1,060 facts/5,456 question keys.
  The mdBook renders exactly 72 files/16,513,744 bytes.
- The first mdBook invocation exposed that its `-d` path is command-working-
  directory-relative: `../../book/build` created the exact rendered output
  outside the repository, although still on the same volume. That exact
  72-file/16,513,744-byte directory was censused, deleted, and proved absent.
  The book was then rebuilt successfully at repository-local `book/build` with
  the identical census and removed with zero residue. This is verification
  command correction, not a persisted project path or product change.
- Eight disposable generated probe files totaling 116,777 bytes are removed;
  `.artifacts/tmp/tests` is empty. `MEMORY.md` is 49 lines, `README.md` is
  2,346 lines, syntax and diff hygiene pass, and all six doctrine gates pass.
- Final canonical Stats-compatible capacity is
  17,515,790,336/25,769,803,776 bytes = 16.313/24.000 GiB = 67.97%, with
  separate macOS kernel pressure level 1 and `memory_pressure` 75% free. Guard
  occupancy is not used as capacity truth. No background job remains.

The audit changes no parser, carrier, renderer, emitter, generated HDL,
diagnostic, runtime, support accounting, report/semantic/MCP schema, public API,
protocol behavior, HIAL/VIAL boundary, scale claim, or simulator profile.
Implementation `.2` requires a separate clean continuity activation.
Clean audit commit `628ca0c33` now activates `.2` continuity-only. The selected
contract and current malformed generated property remain unchanged during that
transition.

## Rollback

Audit rollback removes t1544 and this record, restores `.1` to active, and
leaves the malformed property unchanged. After `.2` activation, implementation
rollback must restore only the previous substitution rendering and its tests;
it must not rewrite the AXI predicate or retain assertion disabling as a
substitute for correctness.
