# IAL2 Post-Generalized AHB BUSY Count Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.830` selects proposed
`ISF-RULE-TRANSACTION-OUTPUT-PRIORITY-ENFORCEMENT.1` as the next bounded owner.

The selected leaf is a no-behavior readiness audit. It must reduce the known
AHB assertion failure to a protocol-neutral actor and distinguish the already
working direct rule/transaction assignment path from the unresolved case in
which a transaction invokes a named drive. No scheduler, selector, parser,
generator, public source, or runtime behavior changes in this selector.

## Reconciled Shipped Boundary

Clean behavior commit `2f64611ca` ships canonical decimal requester
`busy-beats` values `2..16` through the existing width-generic lowerer. Focused
t1541 proves admission, exact diagnostics, reports, normalized semantic and
read-only MCP identity, verifier acceptance, and seven assertion-enabled
count-5/8/16 runtime scenarios. No count-specific public fixture or support
entry was added, so accounting remains 332 protocol fixtures, 373
supported-smoke plus strict fixtures, and 56 AHB paths split 28 `.ppif` / 28
`.ahb`.

The value 16 is the deliberate bounded `max_beats=16` profile limit rather
than a protocol maximum. Immediate widening above it would extend a chosen
verification boundary without adding a new semantic dimension.

## Priority Evidence Reconciliation

The original AHB finding remains real, but its exact seam is narrower than the
old shorthand “rule versus transaction output priority” suggested.

Direct transaction assignments already participate in
`_apply_rule_transaction_priority_resolution` in
`perl/FSM/Scheduler/ISF/LoweringIR.pm`. That pass collects rule and transaction
data assignments, applies actor-level priority, adds the winner condition to
the lower assignment's guard, and reports `priority_suppressed_by`. Focused
test `t/1220-isf-arbitration-schedule-report.t` declares `force_out over main`
for a rule assigning `out 1` and transaction `main` assigning `out 0`; it
passes and reports the expected rule-over-transaction suppression.

The rejected AHB candidate used a different shape: its requester transaction
invoked a named drive selecting `HTRANS=SEQ`, while a concurrent higher-priority
rule selected `HTRANS=BUSY`. Named-drive bodies are separate lowering blocks
with owner kind `drive`, not `transaction`. They are therefore outside the
current rule/transaction data-assignment pass. Conflict analysis classifies
the remaining rule/drive pair as `isf_unproven_rule_drive_overlap`, and the two
different-value selectors can remain enabled together until the generated
assertion fails with `selector multi-value conflict: HTRANS`.

This is a protocol-neutral correctness seam. The audit must determine whether
actor-level transaction priority can and should propagate through the named-
drive invocation to mask the lower selector, or whether unsupported cases
must fail closed before HDL generation. It must not assume the answer and must
not weaken the assertion.

## Candidate Comparison

| Candidate | Selection result | Evidence |
| --- | --- | --- |
| Rule versus transaction-invoked named-drive output priority | **selected for readiness audit** | Existing assertion failure, protocol-neutral correctness impact, and a narrow provenance/activation seam; the adjacent AHB tree has now dried out. |
| Literal counts above 16 | not selected | Sixteen is the deliberate bounded profile maximum; widening it immediately would not add semantics or close a correctness gap. |
| Symbolic/policy/runtime/random count selection | deferred | Requires new dynamic ownership and public semantics beyond the shipped compile-time literal contract. |
| Multiple insertion points | deferred | Adds ordering, per-point ownership, and reporting semantics rather than repairing the proven selector seam. |
| Bus-BUSY status, burst, signal, or topology work | deferred | Adds new AHB surface and has no evidence-backed prerequisite relationship to the shipped count range. |
| HIAL/VIAL and verification generation | remains proposed | Strategically important peer-intent architecture, but substantially broader than this bounded correctness audit. |
| VHDL/portability | remains deferred/separate | Direct VHDL work remains gated behind SystemVerilog-backed feature completeness and independent qualification. |
| End-to-end large-design scalability | remains proposed | Foundational requirement, but its workload and budget contract is not a prerequisite to this narrow correctness audit. |
| Other protocols/backends | deferred | No current evidence establishes a tighter blocker than the reproduced protocol-neutral selector conflict. |
| Decision `0020` transaction roles | inactive by decision | Directional North Star remains explicitly ineligible for PNT until director activation. |

## Selected Audit Contract

Audit `.1` must create a repository-owned protocol-neutral reproducer with one
concurrent rule, one transaction that invokes a named drive, a declared actor-
level priority, and different values for one registered output. It must prove
all of the following before contract selection:

- direct rule/transaction assignment suppression remains working and bounded;
- the named-drive variant reproduces the selector conflict with generated
  assertions enabled;
- schedule, lowering IR, provenance, named-drive activation, output family,
  unified selector, report, normalized semantic, and diagnostics identify the
  exact propagation boundary;
- same-value fan-in, rule/rule, transaction/transaction, storage and resource
  priorities, existing reports, and supported backends have explicit
  preservation requirements; and
- the evidence selects either a precise masking contract or the smallest
  fail-closed prerequisite in a later leaf.

Audit `.1` makes no behavior change. Contract leaf `.2` will freeze the chosen
semantics and implementation leaf `.3` will be eligible only after that
contract commits cleanly.

## Preserved Boundaries

Selection leaves canonical decimal requester `busy-beats` values `2..16`, all
public source bytes, 332/373/56 split 28/28 accounting, reports, generated
artifacts, semantic/read-only-MCP APIs, HDL/runtime, simulator profiles,
backends, protocols, HIAL/VIAL, verification generation, VHDL, portability,
scale, decision `0020`, and transaction behavior unchanged.

Verilator remains the event-capable compiled portable-fast supported-subset
profile, separate from a qualified full-language/SystemVerilog-UVM authority.
VHDL and mixed-language profiles remain independently qualified.

## Validation, Resources, And Rollback

Focused `t/1220-isf-arbitration-schedule-report.t` proves the existing direct
assignment path. The selector also closes with current documentation gates,
Knowledge Map generation/check, mdBook rendering and exact cleanup, diff
hygiene, and all doctrine gates. Heavy commands use authorized
`--host-max-pct 100 --process-max-rss-mb 4096`. Capacity truth uses the
canonical Stats-compatible Mach-page formula and reports kernel pressure
separately; guard occupancy is not capacity truth. Project-owned temporary
data remains on repository-derived same-volume paths.

Rollback removes this selector and fact, restores `.830` to active, and leaves
all shipped behavior unchanged. Clean selector commit activation may change
continuity pointers only.

Closeout proof passes focused t1220+t1518+t1256+t1414 as 4 files/24
top-level tests, Knowledge Map generation/check at 1,052 facts/5,403 question
keys, and all six doctrine gates. The mdBook builds to exactly 72 files/
16,425,535 bytes and the exact render is removed; `.artifacts/tmp/tests` is
empty. Canonical Stats-compatible capacity is
14,837,874,688/25,769,803,776 bytes = 13.819/24.000 GiB = 57.58%, with separate
kernel pressure level 1 and `memory_pressure` 69% free.

Clean selector commit `f67705356` activates only the selected audit `.1`.
Activation changes continuity pointers and no scheduler, selector, generated
HDL, runtime, AHB, HIAL/VIAL, VHDL, scale, or transaction behavior.

Completed audit `.1` selects proposed no-behavior contract `.2` for
unique-caller target-local named-drive priority and ambiguous-caller
fail-closed handling. Current lowering and all AHB behavior remain unchanged.
Clean audit commit `e715a34c7` activates only contract `.2`; activation is
continuity-only and changes no product behavior.

Completed contract `.2` selects proposed implementation `.3` for unique local
caller target-local priority and deterministic ambiguous ownership rejection.
SystemVerilog and native Verilog are executable gates; the separately owned
direct-VHDL unary-reduction defect does not alter AHB behavior.
