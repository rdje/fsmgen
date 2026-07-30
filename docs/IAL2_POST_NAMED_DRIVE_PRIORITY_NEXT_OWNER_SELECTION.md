# IAL2 Post-Named-Drive Priority Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.831` selects proposed
`DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING.1` as the next bounded owner.

The selected leaf is a no-behavior audit of direct-VHDL unary reduction
expressions. It must distinguish scalar identity cases from true vector
reductions for unary OR, AND, and XOR, then select the smallest correct
translation or an explicit fail-closed boundary. This selector does not change
the parser, scheduler, lowering, backend, generated HDL, or runtime.

## Reconciled Shipped Boundary

Clean behavior commit `1dbff8fc6` ships protocol-neutral, bidirectional
rule/transaction priority for a transaction-invoked named drive when the drive
has exactly one distinct local transaction caller and no generated caller.
Masking is target-local, unrelated outputs and transaction lifecycle survive,
unique unordered different-value conflicts remain fail-closed, same-value
fan-in remains compatible, and prioritized shared/generated/mixed ownership
fails deterministically before HDL generation. Public report and normalized
semantic schemas remain unchanged.

Focused `t/1542-isf-rule-transaction-named-drive-priority-readiness.t` provides
assertion-enabled SystemVerilog runtime proof and native-Verilog compilation.
AHB requester `busy-beats` remains canonical decimal `2..16`; public accounting
remains 332 protocol fixtures, 373 supported-smoke plus strict fixtures, and 56
AHB paths split 28 `.ppif` / 28 `.ahb`.

## Direct-VHDL Correctness Evidence

The named-drive contract probe exposed an independent backend defect. Direct
VHDL generation completed but emitted:

```vhdl
drive_zero_en and (|drive_zero_start)
```

The `(|...)` token is SystemVerilog unary reduction syntax, not truthful VHDL.
Decision `0023` therefore forbids treating generation success as VHDL syntax or
runtime qualification and routes the defect to
`DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING`.

Code inspection identifies one narrow ownership seam:
`_sv_expr_to_vhdl` in `perl/FSM/HDL/FlattenedDT/Backend/VHDL.pm` translates
spaced binary `|` and `&`, but has no branch for unary reduction OR, AND, or
XOR and does not reject those tokens. Existing direct-backend coverage belongs
primarily to `t/1420-vhdl-direct-backend-scaffold.t`; facade boundaries are
covered by `t/386-hdl-generator.t` and `t/404-cli-output-routing.t`. No `ghdl`,
`nvc`, or `vcom` executable is installed, so the audit can select internal
translation or fail-closed behavior but cannot claim authoritative executable
VHDL qualification.

## Candidate Comparison

| Candidate | Selection result | Evidence |
| --- | --- | --- |
| Direct-VHDL unary reduction handling | **selected for audit** | A current supported command emits a proven foreign-language token; the owner function and regression surface are narrow and decision `0023` already separates the defect. |
| HIAL/VIAL verification-fixture architecture | remains proposed | Foundational and explicitly retained, but its source model, typed bridge, native extensions, multiple backends, simulator profiles, migration, parity, and scale decomposition are much broader than this exact backend correctness seam. |
| End-to-end large-design scalability | remains proposed | Required product direction, but workload and measurement-contract selection is independent of repairing an already-observed invalid output. |
| AHB counts above 16 or new BUSY policy/status/burst/signal/topology semantics | deferred | `2..16` is the deliberate current profile and no adjacent AHB correctness prerequisite outranks the reproduced backend defect. |
| Broader ISF priority/resource/conflict work | deferred | Named-drive priority's selected unique-caller boundary is complete and no smaller unresolved conflict is established by the closeout evidence. |
| Verification output and simulator-capability profiles | remains separate | Verilator remains the event-capable compiled portable-fast supported-subset profile; full-language/UVM, VHDL, and mixed-language qualification require independent capability owners. |
| Startup alignment tasks | remain proposed | The import-tree, mdBook wording, and frozen-legacy workflow findings are durable, but do not supersede a generated-HDL correctness defect. |
| Known nested-assertion and mdBook fence defects | remain proposed | Independently owned and not prerequisites to the selected VHDL audit. |
| `IAL2-T1436-PREEXISTING-FAILURES` | not PNT-eligible | Its task explicitly requires director prioritization before activation. |
| Other protocols/backends | deferred | No evidence identifies a smaller blocker than the exact direct-VHDL token leak. |
| Decision `0020` layered transactor roles | inactive by decision | The future North Star is explicitly not PNT-eligible until director activation. |

## Selected Audit Contract

Audit `.1` must:

- reproduce scalar and vector unary OR, AND, and XOR shapes through the direct
  VHDL path without modifying behavior;
- trace operand declarations, resolved widths, expression contexts, and the
  conversion path through `_sv_expr_to_vhdl`;
- distinguish scalar identity lowering from vector reduction semantics rather
  than performing an unsafe token substitution;
- select either exact VHDL translation for the proven shapes or the smallest
  deterministic pre-emission rejection for unsupported shapes;
- freeze diagnostics, focused backend/facade tests, preservation of other
  expression families and HDL targets, documentation, same-volume cleanup,
  external-compiler qualification limits, and rollback; and
- route implementation to `.2` only after the audit commits cleanly.

The audit makes no behavior change. In particular it does not silently infer
full VHDL expression parity, install or nominate an external compiler, broaden
VHDL composition/package/aggregate/verification output, or alter named-drive
priority semantics.

## Validation, Resources, And Rollback

The audit validation plan uses `t/1420-vhdl-direct-backend-scaffold.t` as the
primary direct-backend regression, bounded facade preservation from t386/t404,
and the tracked t1542 named-drive characterization where needed. Documentation,
Knowledge Map, mdBook, diff-hygiene, and doctrine gates remain mandatory.
Heavy commands use the director-authorized `--host-max-pct 100
--process-max-rss-mb 4096` profile with repository-derived same-volume
workspaces. Capacity truth uses the canonical Stats-compatible Mach-page
formula and reports kernel pressure separately; guard occupancy is not capacity
truth.

## Closeout Evidence

- Direct-VHDL baseline t1420 passes 1 file/64 tests; correctly named facade
  baselines t386+t404 pass 2 files/100 tests. The first aggregate invocation
  used obsolete short t386/t404 filenames after t1420 had passed; the corrected
  paths pass and no product failure occurred.
- Book/status/path truth gates pass 4 files/45 tests.
- Knowledge Map generation/check passes at 1,057 facts/5,433 question keys.
- The mdBook renders exactly 72 files/16,479,283 bytes. An initial output
  argument resolved from the process directory to the same-volume but
  off-repository destination two levels above the repository; that exact
  72-file disposable render was positively identified and deleted. The gate
  was rerun to repository-local `book/build`, censused, deleted, and both
  locations have zero residue.
- `MEMORY.md` is 50 lines, `README.md` is 2,341 lines,
  `.artifacts/tmp/tests` is empty, diff hygiene passes, and all six doctrine
  gates pass, including project-data locality.
- Final canonical Stats-compatible capacity is
  19,021,234,176/25,769,803,776 bytes = 17.715/24.000 GiB = 73.81%, with
  separate macOS kernel pressure level 1 and `memory_pressure` 72% free. Guard
  occupancy is excluded from capacity truth.

Rollback removes this selector and fact, restores `.831` to active, and leaves
all shipped behavior unchanged. A later clean selector commit may activate only
the selected audit `.1` through continuity changes.

Clean selector commit `5f904d2d2` activates only the selected audit `.1`.
Activation changes continuity pointers and no parser, scheduler, backend,
generated HDL, runtime, AHB, HIAL/VIAL, scale, or transaction behavior.
