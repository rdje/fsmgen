# IAL2 Post Direct-VHDL Reduction Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.832` selects proposed no-behavior audit
`ISF-ASSERT-NESTED-BITWISE-PRECEDENCE-REPAIR.1` as the next bounded owner.

The selected leaf must reproduce and isolate the concurrent-property
intermediate-inlining path that changes a parsed nested bitwise expression's
meaning. It then selects the smallest general AST-preserving repair and exact
assertion-enabled regression contract before implementation `.2`. This
selector changes no parser, lowerer, generated HDL, assertion, runtime, or
public surface.

## Reconciled Shipped Boundary

Clean behavior commit `2879f22af` completes the direct-VHDL reduction tree.
Generated scalar and static-bit reductions now lower by identity/complement;
declared vectors use required-only backend-owned `std_logic` folds; signed
vectors cast explicitly; invalid ranges/selects, unresolved/compound shapes,
residual tokens, and helper collisions fail closed. Named-drive, AMBA
`HRESP`, and APB `wait_ctr`/`addr_q` paths are token-free. Public source arity
does not widen, and external VHDL compile/runtime qualification remains
separate because no authoritative compiler is installed.

AHB requester `busy-beats` remains canonical decimal `2..16`; public
accounting remains 332 protocol fixtures, 373 supported-smoke plus strict
fixtures, and 56 AHB paths split 28 `.ppif` / 28 `.ahb`. HIAL/VIAL, scale,
simulator profiles, and decision `0020` remain independently owned.

## Current Assertion Defect Evidence

The shipped fixed-four AXI read source contains a 4-KiB admission condition
whose high-address conjunction includes the nested expression
`cmd_read_addr[3] | cmd_read_addr[2]`. Behavioral lowering preserves the AST
through two generated assignments:

```systemverilog
assign intermediate_complex_expr_10 =
    cmd_read_addr[3] | cmd_read_addr[2];
assign intermediate_and_intermediate_complex_expr_10_11 =
    cmd_read_addr[11] & ... & cmd_read_addr[4]
    & intermediate_complex_expr_10;
```

The generated concurrent assertion instead inlines the intermediate without
retaining the nested OR grouping:

```systemverilog
cmd_read_addr[11] & ... & cmd_read_addr[4]
    & cmd_read_addr[3] | cmd_read_addr[2]
```

SystemVerilog bitwise precedence reads that as `(high & bit3) | bit2`, not
`high & (bit3 | bit2)`. Legal address `0x00000004` therefore launches through
the correct behavioral guard but makes the generated boundary assertion
false. The dated fact card records the prior assertion-enabled Verilator
failure. Current regeneration under `.832` reproduces the exact malformed
property in one repository-local 94,171-byte HDL file while retaining the
correct factored behavioral path.

The existing t1507 runtime deliberately invokes Verilator with
`--no-assert`, so it passes without exercising this boundary. The current
t1410-t1412 property carriers/emitters plus t1507 all pass 4 files/21 top-level
tests, proving the surrounding baseline but also confirming the missing
assertion-enabled legal-bit-2 regression.

## Candidate Comparison

| Candidate | Selection result | Evidence |
| --- | --- | --- |
| Nested bitwise concurrent-assertion precedence | **selected for audit** | Shipped verification HDL is syntactically accepted but semantically wrong for a legal public AXI command; the deterministic expression, owner path, and missing focused coverage are already bounded. |
| HIAL/VIAL verification-fixture architecture | remains proposed | Director-endorsed and foundational, but its topology, typed bridge, portable/native semantics, two verification backends, simulator profiles, migration, parity, and scale decomposition are broader than repairing an already-proven generated assertion defect. |
| End-to-end big/really-big scalability | remains proposed | Required product direction, but workload and measurement-contract selection does not supersede current generated-verification correctness. |
| Frozen-legacy workflow, import-tree, VHDL introduction, public-sync, and mdBook-fence maintenance | remains proposed | These bounded truth-sync owners remain valid. Current frozen-blob policy is being obeyed, doctrine gates pass, HTML book rendering passes, and none repairs the executable semantic mismatch selected here. |
| Remaining AHB counts/policy/status/burst/signal/topology | deferred | `2..16` is the deliberate requester profile, and no adjacent AHB correctness dependency outranks the assertion defect. |
| Further direct-VHDL or compiler qualification | deferred | The reduction repair is complete; native VHDL qualification requires an independently selected compiler profile. |
| Protocol instance-name audit, HIR, host builder, MCP write horizon, other protocols/backends | deferred | No evidence makes these a prerequisite for the exact assertion repair. |
| RAM-guard metric refinement | remains separate | Capacity truth already uses the director-approved Stats-compatible formula and reports kernel pressure separately; changing the safety guard remains an independent owner. |
| `IAL2-T1436-PREEXISTING-FAILURES` | not PNT-eligible | Its task explicitly requires director prioritization before activation. |
| Decision `0020` layered transactor roles | inactive by decision | The future North Star remains director-gated and is not PNT-eligible. |

## Selected Audit Contract

Audit `.1` must:

- reproduce legal-address behavioral admission beside concurrent-property
  rejection without changing product behavior;
- trace the exact assertion condition from IAL1 carrier through parsed CoreAST,
  intermediate `SignalRef`/`driving_ast`,
  `GeneratedModuleInfoBuilder::_render_check_condition_sv`, and
  `GeneratedModuleEmitter` consumption;
- distinguish a general precedence-aware AST renderer repair from source-only
  rewrites, added blanket parentheses, or AXI-specific workarounds;
- freeze exact direct and intermediate/inlined mixed-precedence matrices for
  assert, assume, and cover paths where applicable;
- freeze the assertion-enabled `0x00000004` t1507 extension while preserving
  the existing admission set, counts, renderer-safe write predicate, and
  t1410-t1412 property behavior;
- record diagnostics, documentation, same-volume cleanup, resource profile,
  rollback, and implementation `.2`; and
- make no behavior change until the audit commits cleanly.

## Validation, Resources, And Rollback

The audit validation plan centers on t1410-t1412 and t1507, with the smallest
additional focused renderer probe justified by code tracing. It must compile
and run the legal-bit-2 case with assertions enabled, keep existing AXI read
runtime totals unchanged, and preserve assertion-enabled write behavior.
Broader property/backend tests, documentation, Knowledge Map, mdBook, diff
hygiene, and doctrine gates remain mandatory.

Heavy commands use the authorized `--host-max-pct 100
--process-max-rss-mb 4096` profile with repository-derived same-volume
workspaces. Capacity truth uses the canonical Stats-compatible Mach-page
formula and reports kernel pressure separately; guard occupancy is not
capacity truth.

Rollback removes this selector and fact, restores `.832` to active, and leaves
the current assertion defect and every shipped behavior unchanged. A clean
selector commit may activate only the selected audit `.1` through a separate
continuity commit.

## Closeout Evidence

- Current t1410-t1412 plus t1507 pass 4 files/21 tests. This is preservation
  evidence, not a false assertion-repair claim: t1507 explicitly uses
  `--no-assert` and omits the legal-bit-2 case.
- Book/status/path truth gates pass 4 files/45 tests. Knowledge Map generation
  and checking passes at 1,060 facts/5,454 question keys.
- The mdBook renders exactly 72 files/16,504,505 bytes; its exact
  repository-local output is removed. The one-file 94,171-byte selector probe
  is also removed, and `.artifacts/tmp/tests` is empty.
- `MEMORY.md` is 49 lines, `README.md` is 2,345 lines, diff hygiene passes, and
  all six doctrine gates pass, including project-data locality.
- Final canonical Stats-compatible capacity is
  17,011,163,136/25,769,803,776 bytes = 15.843/24.000 GiB = 66.01%, with
  separate macOS kernel pressure level 1 and `memory_pressure` 75% free. Guard
  occupancy is excluded from capacity truth. No background job remains.
