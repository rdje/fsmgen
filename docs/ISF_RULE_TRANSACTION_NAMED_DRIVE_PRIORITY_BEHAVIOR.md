# ISF Rule/Transaction Named-Drive Priority Behavior

Task-tree owner:
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.3`

Date: `2026-07-30`

## Outcome

FSMGen now enforces actor-level rule/transaction priority through a local named
drive when that drive has exactly one distinct local transaction caller and no
generated activation source. The repair is target-local and bidirectional:

- a higher-priority rule masks only the conflicting drive-body assignment;
- a higher-priority transaction masks only the conflicting rule assignment
  while that drive target is active;
- the drive request, transaction progression, completion, parameters, and
  non-conflicting drive outputs continue; and
- generated selector assertions remain enabled and pass for the resolved
  shapes.

The parser and source spelling are unchanged.

## Source Examples

Rule over transaction:

```lisp
(priority force_out over main)

(drive drive_zero
  (out 0)
  (side 1))

(transaction main
  (on start)
  (drive drive_zero)
  (complete done))

(rule force_out override_req
  (out 1))
```

When `override_req` and `drive_zero_start` are both active, `out` is selected
only by `force_out`; `side` is still selected by `drive_zero`.

Transaction over rule uses the same actors with the reverse declaration:

```lisp
(priority main over force_out)
```

The rule can drive `out` whenever the named-drive target is inactive. During
the drive activation, the transaction's `out=0` assignment wins and the rule
resumes afterward.

## Ownership Classification

Each drive DT now carries deterministic private lowering metadata:

```text
local_transaction_callers = [sorted distinct transaction names]
generated_call_sources    = [sorted generated-source descriptors]
```

Calling one drive multiple times from the same transaction still produces one
distinct caller. The first repair classifies ownership as follows:

| Local callers | Generated sources | Priority behavior |
| --- | --- | --- |
| exactly one | none | use that transaction as the logical priority actor |
| multiple | none | ambiguous; prioritized overlap fails closed |
| none | one or more | ambiguous generated ownership; prioritized overlap fails closed |
| one or more | one or more | ambiguous mixed ownership; prioritized overlap fails closed |
| none | none | unused drive; no synthetic transaction owner |

Drive-body provenance remains `owner=<drive>`, `owner_kind=drive`, and
`source_kind=drive_body`. It additionally carries private sorted
`invoking_transactions`. Public schedule and normalized-semantic schemas do not
gain these private fields.

## Target-Local Lowering

For `force_out over main`, the scheduled assignment is equivalent to:

```lisp
(-drive_zero
  (<- (out> 0) <(& drive_zero_start (! override_req))>)
  (<- (side> 1) <drive_zero_start>)
)
```

Only the conflicting `out` assignment receives the inverse rule guard. The
drive-start request is not masked.

For `main over force_out`, the lower-priority rule assignment receives the
inverse full drive-body activation condition. The drive assignment remains
unchanged. Resolution records use the logical actors rather than replacing
drive provenance:

```json
{
  "target": "out",
  "winner": "main",
  "winner_kind": "transaction",
  "loser": "force_out",
  "loser_kind": "rule"
}
```

## Conflict Behavior

- Unique caller, different values, valid acyclic priority: resolve with no
  compile issue.
- Unique caller, same value/operator: preserve compatible fan-in; no priority
  resolution is required.
- Unique caller, different values, no priority: fail closed through
  `isf_conflicting_rule_transaction_writes`.
- Unique caller, priority cycle: fail closed through
  `isf_priority_cycle_conflict`.
- Mixed timing operators: retain the existing
  `isf_priority_mixed_timing_conflict` gate.
- Shared/generated/mixed ownership with applicable actor priority: fail before
  HDL through `isf_ambiguous_rule_transaction_drive_priority`, severity
  `error`, proof status `ambiguous_drive_caller`.
- Shared/generated/mixed overlap without applicable priority: retain
  `isf_unproven_rule_drive_overlap/not_doable` as a nonfatal warning.

The ambiguity diagnostic deterministically names the rule, drive, target,
ambiguity class, sorted local callers, sorted generated-source descriptors,
candidate transactions, source kinds, operators, and values. Public
`--check --json` returns `success=false`, one diagnostic, and
`generated_output.emitted=false` for the covered shared-caller case.

## Reports And Semantic Projection

Resolved schedules expose one bounded `priority_resolutions[]` entry with
logical rule/transaction names and an empty `compile_issues[]`. The existing
public key sets do not change.

Normalized semantic output-drive families retain their block names, RHS value
sets, and enable identities. For the rule-over-drive example, `out` still
reports `-drive_zero` and `-force_out` with values `0` and `1`; `side` still
reports only `-drive_zero` with value `1`. Exclusivity lives in the scheduled
assignment guard and generated enable logic.

## Backend Qualification

- SystemVerilog is executable: assertion-enabled Verilator proves both
  priority directions and the non-conflicting multi-output case.
- Native Verilog is executable: Icarus compiles and runs the rule-over-drive
  fixture, and Verilog remains free of SystemVerilog assertion syntax.
- Direct VHDL is characterization-only for this expression family. Generation
  still leaks SystemVerilog unary-reduction syntax around `drive_zero_start`.
  Decision `0023` and proposed
  `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING` own that independent correction;
  this behavior does not claim valid VHDL.

## Public Surface And Compatibility

No parser keyword, source suffix, support identity, capability-manifest stable
code registry, schedule schema, normalized-semantic schema, MCP schema, or
artifact inventory changes. Direct rule/transaction assignments, rule/rule
priority, same-value selector assertions, resource arbitration, transaction/
transaction conflict behavior, and broader shared-drive proof remain intact.

## Verification And Cleanup

Focused t1542 passes 7 top-level subtests and 92 nested assertions. The final
affected preservation set passes 13 files/145 top-level tests across drive
boundaries, provenance, static conflicts, selector instrumentation, schedule
projection, direct rule/transaction priority, arbitration reports,
expression diagnostics, binding conflicts, golden reports, public failure
JSON, and named-drive behavior. Accounting/capability preservation passes 2
files/7,031 tests; bounded book/status/path gates pass 4 files/305 tests.

An attempted full supported-corpus public-JSON/semantic gate was intentionally
stopped by the authorized 4,096-MiB descendant guard when the unrelated
existing AXI dynamic-write same-ID queue fixture reached 5,082.6 MiB RSS. The
guard terminated the exact process tree before the semantic sweep; the empty
repository-local workspace was removed. The targeted strict check, failed
check JSON, schedule JSON, and normalized-semantic surfaces are covered by
t1542, so no cap increase or unguarded retry was used.

Knowledge Map generation/check reaches 1,056 facts/5,426 question keys. The
mdBook renders exactly 72 files/16,468,460 bytes and that exact repository-
local render is removed. `.artifacts/tmp/tests` is empty. Final canonical
Stats-compatible RAM is 15,157,477,376/25,769,803,776 bytes =
14.117/24.000 GiB = 58.82%, with separate kernel pressure level 1 and
`memory_pressure` 71% free; guard occupancy is not capacity truth.

## Rollback

Rollback restores the pre-`.3` rule/drive warning plus assertion-failing
unique-caller behavior, removes the caller/source metadata and focused shipped
fixtures, and keeps the independent VHDL defect task/decision unless separate
evidence disproves it.
