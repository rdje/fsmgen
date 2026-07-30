# ISF Rule/Transaction Named-Drive Priority Contract Selection

Task-tree owner:
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.2`

Date: `2026-07-30`

## Outcome

Contract `.2` selects implementation `.3` for a backend-neutral lowering
repair with a deliberately bounded ownership model:

- a local named drive with exactly one distinct invoking transaction may
  participate in actor-level rule/transaction priority;
- priority is applied to each conflicting drive-body assignment, never to the
  aggregate drive request or the whole drive;
- rule-over-transaction and transaction-over-rule are both supported;
- a prioritized rule/drive conflict with shared, generated-child, mixed, or
  otherwise ambiguous activation ownership fails closed before HDL; and
- a different-value unique-caller rule/drive conflict without an ordering now
  fails closed through the existing rule/transaction conflict family.

The parser syntax does not change. Current direct rule/transaction assignments
remain the reference behavior, and generated selector assertions remain
authoritative. Contract selection changes no lowering or runtime behavior.

## Frozen Source Semantics

Existing actor-level priority syntax is sufficient:

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

The declared actors are still `force_out` and `main`; `drive_zero` remains a
reusable lowering/provenance owner rather than becoming a new public priority
actor. One transaction may call the drive at multiple source sites and still
counts as one distinct local caller. A second distinct transaction makes the
drive shared and is outside this first repair.

No new source keyword, priority spelling, drive annotation, support identity,
or public file is selected.

## Caller Ownership Metadata

Implementation `.3` must retain explicit deterministic metadata when building
each drive DT:

```text
local_transaction_callers = [sorted distinct transaction names]
generated_call_sources    = [sorted generated source descriptors]
```

The local caller set is collected while each non-generated parent transaction
is walked. Generated `do`/`spawn`/rule-trigger drive handoffs remain separately
classified and must not be collapsed into local callers. The drive DT and its
internal assignment provenance retain:

```text
owner        = drive_zero
owner_kind   = drive
source_kind  = drive_body
```

Only priority analysis receives a logical transaction actor for the exact
`one local caller / zero generated source` classification. This preserves
reviewable drive provenance while allowing the existing actor-priority model
to compare the rule with its invoking transaction.

The selected field spelling for internal provenance is
`invoking_transactions`, containing the sorted local caller list. It is not a
new schedule-JSON or normalized-semantic public key.

## Target-Local Priority Semantics

For each same-target, different-value rule/unique-caller-drive pair with equal
timing operators:

| Declared relation | Winner condition | Lower assignment change | Schedule resolution |
| --- | --- | --- | --- |
| `rule over transaction` | the rule action's full activation condition | add the inverse rule condition only to the conflicting drive-body assignment | winner is the rule; loser is the invoking transaction |
| `transaction over rule` | the drive-body assignment's full activation condition, including `drive_start` | add the inverse drive-body condition only to the conflicting rule assignment | winner is the invoking transaction; loser is the rule |

Priority dominance remains transitive through the existing owner-priority
graph. A cycle still fails with `isf_priority_cycle_conflict`; mixed timing
still fails with `isf_priority_mixed_timing_conflict`.

The suppressor is assignment-local. In the example above, rule-over-main must
produce the semantic equivalent of:

```lisp
(-drive_zero
  (<- (out> 0) <(& drive_zero_start (! override_req))>)
  (<- (side> 1) <drive_zero_start>)
```

The `drive_zero_start` request, transaction state progression, `done`, drive
parameters, and non-conflicting `side` assignment remain active. Masking the
whole drive or its start request is forbidden.

For transaction-over-rule, the inverse condition is based on the target's
drive-body activation, not on generic activity of any other transaction state.
The lower rule therefore remains eligible whenever this drive target is not
being selected.

## Conflict And Diagnostic Contract

The following behavior is selected:

- Exact-one local caller, different value, applicable acyclic priority:
  resolve and emit no compile issue.
- Exact-one local caller, same target/value/operator: preserve compatible
  fan-in and current same-value assertion behavior; no priority resolution is
  required.
- Exact-one local caller, different value, no priority in either direction:
  fail closed with existing code `isf_conflicting_rule_transaction_writes`.
- Exact-one local caller, applicable priority cycle: fail closed with existing
  code `isf_priority_cycle_conflict`.
- Exact-one local caller, mixed timing: fail closed with existing code
  `isf_priority_mixed_timing_conflict`.
- Multiple distinct local callers, any generated-child drive source, or a mix
  of local/generated sources, when actor priority attempts to order the rule
  against a candidate transaction: fail closed with new internal conflict code
  `isf_ambiguous_rule_transaction_drive_priority` and
  `proof_status=ambiguous_drive_caller`.
- A drive body with no activation source is not assigned a synthetic
  transaction owner. A zero-local-caller generated source is classified as
  generated/ambiguous by the preceding rule; a truly unused drive remains
  outside transaction-priority application.
- Ambiguous rule/drive overlap with no applicable actor-level priority retains
  the existing warning `isf_unproven_rule_drive_overlap/not_doable`; this leaf
  does not pretend to solve general rule/drive overlap proof.

The new ambiguous diagnostic uses the existing conflict object shape:
`code`, `severity=error`, `target`, `domain=data`, `proof_status`, `reason`, and
two source summaries. Its deterministic reason names the rule, drive, sorted
candidate callers, sorted generated-source descriptors, and ambiguity class;
the source summaries retain operator and RHS values. The rendered failure
therefore names the conflict code, target, rule, drive, candidates, source
kinds, operators, and values. `--check --json` must return `success=false`, one
diagnostic carrying that message, and `generated_output.emitted=false`.

This is an internal ISF conflict code consistent with the existing conflict
families, not a new capability-manifest stable-code registry entry.

## Reports, Provenance, And Semantic Projection

Resolved unique-caller cases must project exactly one bounded
`priority_resolutions[]` entry with logical actor names and kinds:

```json
{
  "target": "out",
  "winner": "force_out",
  "winner_kind": "rule",
  "loser": "main",
  "loser_kind": "transaction"
}
```

The reverse relation swaps those actor fields. Resolved cases expose an empty
`compile_issues[]`. Raw provenance keeps drive ownership and adds the private
sorted `invoking_transactions`; the losing assignment records
`priority_suppressed_by` with the logical winning actor and carries the exact
combined guard.

Normalized semantic JSON keeps the existing output-family schema and driver
identity. For `out`, blocks remain `-drive_zero` and `-force_out`, RHS values
remain `0` and `1`, and family/driver enable signal names remain stable. The
exclusivity repair is represented in the scheduled assignment guard and HDL
enable logic, not by adding a semantic-report key.

Support accounting, language/capability manifests, MCP schema, public source
discovery, and artifact inventories remain unchanged.

## HDL Qualification

The semantic contract is backend-neutral, but current executable evidence is
qualified per backend:

- SystemVerilog: required. Preserve `$onehot0` multi-value selector assertions,
  prove the target-local inverse guard structurally, and pass assertion-enabled
  Verilator runtime for both priority directions and the multi-output case.
- Verilog: required. Generate through the native Verilog target, prove the
  same target-local enable structure, compile with installed Icarus Verilog,
  and run the compatible focused fixture. Verilog does not gain SystemVerilog
  assertion syntax.
- VHDL: not currently qualified for this expression family. A same-volume
  contract probe generated the current source successfully but exposed
  `drive_zero_en and (|drive_zero_start)`. `_sv_expr_to_vhdl` translates
  spaced binary OR but neither translates nor rejects unary reduction OR, and
  no `ghdl`, `nvc`, or `vcom` is installed. Decision `0023` and proposed task
  `DIRECT-VHDL-REDUCTION-EXPRESSION-LOWERING` own that independent defect.
  `.3` must report the VHDL outcome and make no VHDL-validity claim; it must not
  broaden into a backend repair.

The three-file/19,070-byte Verilog/VHDL probe workspace was repository-local
and is removed without residue.

## Implementation And Test Boundary

Implementation `.3` is limited to the caller inventory, drive-priority record
selection, ambiguity conflict, assignment-local suppressor reuse, and focused
tests/docs needed by this contract. Expected primary product owner is
`perl/FSM/Scheduler/ISF/LoweringIR.pm`.

Focused t1542-derived coverage must include:

1. unchanged direct rule-over-transaction control;
2. unique-caller rule-over-drive structural/report/provenance/semantic and
   assertion-enabled runtime success;
3. unique-caller drive-over-rule structural/report/provenance and runtime
   success;
4. multi-output proof that only the conflicting target is masked;
5. unique-caller no-priority, cycle, and mixed-timing fail-closed boundaries;
6. multiple-caller and generated-source prioritized ambiguity diagnostics;
7. same-value fan-in preservation;
8. native Verilog generation, Icarus compile/runtime, and explicit VHDL
   unqualified characterization; and
9. exact same-volume cleanup.

Broader preservation must cover current rule/rule, direct rule/transaction,
rule/drive issue projection, priority schedule reporting, compatible fan-in,
port-binding conflicts, enum/aggregate drive values, generated-child drive
handoffs, public check JSON failure shape, strict/schedule/semantic paths,
docs, Knowledge Map, mdBook, doctrines, and the authorized host100/process4096
profile with canonical Stats-compatible RAM plus separate kernel pressure.

## Validation And Cleanup

The unchanged priority/conflict preservation set passes 9 files/28 top-level
tests. The corrected backend/documentation set passes 7 files/396 tests,
including the direct-VHDL scaffold, external-validation contract, public live-
book paths, explicit feature-matrix categories, current AHB book truthfulness,
feature-backlog status, and repository-relative paths. Knowledge Map generation
and checking pass at 1,055 facts/5,420 question keys.

The mdBook builds under the authorized `host100/process4096` profile to exactly
72 files/16,443,056 bytes, and the exact generated render is removed. The
three-file/19,070-byte HDL probe is also removed; `.artifacts/tmp/tests` is
empty, `git_message_brief.txt` is zero bytes, `MEMORY.md` is 50 lines, and
`README.md` is 2,339 lines. Diff hygiene and all six doctrine gates pass,
including project-data locality.

Final canonical Stats-compatible capacity is
19,557,990,400/25,769,803,776 bytes = 18.215/24.000 GiB = 75.89%, with separate
macOS kernel pressure level 1 and `memory_pressure` 73% free. The RAM guard's
occupancy display is excluded from capacity truth. Contract selection changes
no product behavior, and no background job remains.

## Non-Goals

- No parser or source-language extension.
- No whole-drive arbitration, call-site cloning, general shared-drive
  disambiguation, or generated-child ownership reconstruction.
- No weakening/removal of selector assertions.
- No public report/semantic/MCP schema expansion.
- No support-accounting, protocol, AHB, HIAL/VIAL, VHDL-backend, verification-
  generation, scale, transaction-layer, or decision-`0020` expansion.

## Rollback

Before `.3`, rollback restores `.2` active and removes this record/fact plus
its selection references. During `.3`, rollback restores the current warning
and assertion-failing named-drive behavior together with the tracked t1542
characterization. It must not delete the separate VHDL defect task, fact, or
decision unless independent evidence disproves that finding.

Clean contract commit `b44afcc51` activates implementation `.3` continuity-
only. The frozen contract above remains unchanged, and activation changes no
lowering or runtime behavior.
