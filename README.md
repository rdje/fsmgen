# FSMGen
This file is the **single entry point** for the project.
Use it first for objective, navigation, and where to find code/docs quickly.

## Memory & continuity (read this to resume in any harness)
- **`MEMORY_ARCHITECTURE.md`** (repo root) is the durable-agent-memory standard for
  this repo — MANDATORY reading, and mechanically enforced. It defines four layers
  by lifecycle and how a fresh agent (any model, any harness) resumes deterministically:
  - **A — resume pointer**: `MEMORY.md` (bounded, overwrite-only — current state + the single next action).
  - **B — work memory**: task-trees under `docs/tasks/` (index: `docs/TASK_TREE.md`).
  - **C — decision records**: durable cross-cutting facts under `docs/decisions/` (index: `docs/decisions/INDEX.md`).
  - **D — audit trail**: `git log` (commit subjects carry the work-unit id).
- Resume order: this `README.md` → `MEMORY_ARCHITECTURE.md` → `MEMORY.md` → the active
  task-tree's frontier row → only the relevant `docs/decisions/` records.
- **Route every durable thing to a layer and commit before the turn ends** — nothing
  important may live only in the conversation. Before committing run
  `scripts/check_memory_architecture.sh` (git hooks and CI run it too; a non-compliant
  change cannot merge). The tool-neutral bootstrap files (`AGENTS.md`, `CLAUDE.md`,
  `.cursorrules`, `.github/copilot-instructions.md`, `GEMINI.md`, `.windsurfrules`) are
  one-line pointers back here.

## Session safety invariant
- The commit workflow in `COMMIT.md` is mandatory and non-negotiable.
- Before any code, test, source, generated-artifact, or config change, the work
  must already have task-tree ownership in `docs/TASK_TREE.md` and
  `docs/tasks/*.md`.
- After every completed task, slice, lane, or task-scoped activity, run that workflow before starting or switching to the next one.
- Do not ask the user whether to run it after completion; run it automatically.
- Do not batch several finished tasks into one later cleanup commit.
- Run git index-mutating steps in that workflow sequentially; never overlap `git add`, `git rm`, `git mv`, or `git commit`.
- The reason is operational, not stylistic: task-scoped commits are the project's crash-recovery mechanism for session loss, app crashes, and machine crashes.
- If a task is complete but not committed, that task is not safely finished yet.

## Documentation path invariant
- Paths in live docs and the mdBook must be relative to the repository root.
- Do not record machine-local absolute paths such as user home directories in
  tracked documentation.
- If a note references an external workspace, describe it without linking to a
  local filesystem path.

## Documentation synchronization invariant
- The mdBook is a required user-facing artifact for every future slice that
  changes behavior, syntax, diagnostics, workflow, public contracts, or any
  other user-visible FSMGen behavior.
- Keep the mdBook, live specs, roadmap/task-tree status, and public contract
  docs synchronized in the same slice as the code change.
- For downstream-visible `.isf` changes, also keep
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` synchronized with the codebase,
  live specs, mdBook, public contract, manifest metadata, tests, and explicit
  deferrals. That file is the single SPECFORGE-style integration handoff.
- Do not treat a user-visible implementation slice as complete until the book
  describes the shipped behavior accurately enough for review without reading
  the codebase.

## Project objective
FSMGen compiles Lisp-like `.fsm` state machine specifications into synthesizable HDL, and now accepts `.isf` intent-scheduling sources that lower into explicit scheduled `.fsm` before HDL generation.
FSMGen is currently implemented in Perl 5, but IAL0, IAL1, IAL2, their public
file formats, reports, diagnostics, examples, and this mdBook-facing
documentation are backend-language-neutral contracts. Future Rust, Rust/Wasm,
browser-capable JavaScript, and Dart/web implementations should target those
same observable contracts, with the Perl implementation serving as the current
reference/oracle rather than the definition of the IAL layers; see
[docs/decisions/0018-ial-contracts-are-backend-language-neutral.md](docs/decisions/0018-ial-contracts-are-backend-language-neutral.md).
Current primary target is SystemVerilog, with Verilog conversion support and a scoped direct-root VHDL scaffold for the accepted single-FSM subset, including delayed-pulse clock-branch lowering, generic-bearing direct-root module headers with typed scalar/vector sized-literal defaults, signed vector and signed scalar direct-root ports, scalar/vector two-state `bit` input-port and internal declaration lowering, signed scalar/vector, non-signed four-state `logic` input-port/internal declaration lowering, and vector `logic signed` internal declaration lowering, scalar and signed scalar addition/subtraction/multiplication RHS/chain lowering, vector numeric-literal addition/subtraction emitted by compound update/shorthand forms, same-width unsigned-style addition/subtraction/multiplication/division/modulo/XOR RHS/chain lowering, same-width signed vector addition/subtraction/multiplication/division/modulo RHS lowering for signed targets and operands, signed vector numeric-literal addition/subtraction/multiplication/division/modulo RHS lowering including signed vector negative decimal addition, subtraction, multiplication, division, and modulo literals, non-signed vector positive decimal multiplication/division/modulo literal lowering in signal-first, literal-first, and literal-literal order, non-signed vector negative decimal addition/subtraction/multiplication/division/modulo literal lowering, bounded generated AMBA wrap arithmetic for `fsm/amba_requester.fsm`, bounded non-signed vector, signed vector, and scalar output-port decimal literal assignment lowering including non-signed vector, signed vector, and scalar negative decimal literals, bounded direct aggregate-output packed-vector lowering, a bounded C3 external-RTL literal/concat composition VHDL structural top for `t/corpus/composition_intent_integer_literals.fsm`, bounded external-RTL scalar integer, scalar integer expression, one-bit sized bitstring, multi-bit sized bitstring, and resolved packed aggregate VHDL generic maps including resolved package-backed constants, a bounded C1 standalone-DT child composition VHDL passthrough top for `t/corpus/standalone_dtc_explicit_system_autowire.fsm`, bounded C1 standalone-DT scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized bitstring, packed-list, and packed-map VHDL generic maps, a bounded C2 generated-FSM child composition VHDL scalar-autowire top for `t/corpus/implicit_composition_system_autowire.fsm`, bounded C2 generated-FSM scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized bitstring, and resolved packed aggregate VHDL generic maps, and a bounded APB/C4 generated-FSM child composition VHDL top for `fsm/apb_tb.fsm` with scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized bitstring, resolved packed aggregate, and resolved package-backed generic maps in the same APB/C4 shape.
Scalar division/modulo, including signed scalar division/modulo, in the direct
VHDL scaffold remains an explicit fail-closed boundary; full aggregate
record/array VHDL, broader generated-FSM/C4 composition VHDL beyond the exact
shipped fixtures, internal-net-heavy composition tops beyond APB, VHDL package
declaration/emission, full composition VHDL parity, and generic-map families
remain deferred outside these shipped sets: external-RTL scalar integer,
scalar integer expression, one-bit sized bitstring, multi-bit sized bitstring
literal/resolved-package-constant, and resolved packed aggregate actuals;
standalone-DT scalar integer, scalar expression, one-bit sized bitstring,
multi-bit sized bitstring, packed-list, and packed-map actuals; generated-FSM
scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized
bitstring, and resolved packed aggregate actuals; and APB/C4 generated-FSM
scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized
bitstring, resolved packed aggregate, and resolved package-backed actuals.
External-RTL, standalone-DT, and generated-FSM aggregate actuals that do not
lower to one packed literal are locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.97.1`,
`BACKEND-API-VALIDATION-FRONTIER.98.1`, and
`BACKEND-API-VALIDATION-FRONTIER.99.1`, not treated as record/array generic
support; package-root direct HDL generation is locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.100.1`: `?pkg` roots remain import-only
declaration containers, not standalone SystemVerilog or VHDL package HDL
output roots. Declared aggregate structural VHDL ports/nets/types are locked
fail-closed by `BACKEND-API-VALIDATION-FRONTIER.101.1` before record/array
emission; GHDL validation remains blocked by
`BACKEND-API-VALIDATION-FRONTIER.102.1` because `ghdl` is unavailable in the
current environment. Direct roots now expose declaration-only internal
storage/helper nets plus generated enable wires in `structural_rtl_ir.nets[]`,
expose generated enable assignments in machine-readable
`structural_rtl_ir.assignment_records[]` with structured `lhs`, `rhs`,
rendered text, and provenance, populate generated-enable net
`source`/`targets[]` connectivity from those assignment records, reroute the
direct SystemVerilog top state/standalone-DT generated-enable condition block
through `StructuralRTLIR`, populate direct input-port generated-enable RHS
`targets[]` connectivity on `structural_rtl_ir.ports[]`, populate direct
output-port source summaries on `structural_rtl_ir.ports[]` from lowered
output-drive families, and retain `structural_rtl_ir.auxiliary_assignments[]`
as the scalar-string compatibility mirror. Broader output-drive/always-block
body consumer modeling remains outside the compact source summary.
Direct instance/link selector `R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1`
confirmed direct roots are leaf structural summaries and intentionally keep
`instances[]`, `declared_links[]`, and `resolved_links[]` empty; populated
instances and links remain a composition-top structural contract. Selector
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` deferred broader/full direct
SystemVerilog rerouting through `StructuralRTLIR` until direct behavior-body,
state-update, output, and assertion regions have exact structural ownership.
Direct VHDL backend/reroute work through `StructuralRTLIR` is deferred by
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` until the SystemVerilog-backed
IAL0/IAL1/IAL2 path is feature complete. The first exact private ISF
lowerer extraction is shipped as `FSM::Scheduler::ISF::ATLGeneratedTop` for
ATL generated-top report projection and data-link child-interface marking;
broader parser/lowerer extraction remains deferred behind future exact owners. IAL2
protocol/platform intent has its first behavior-bearing in-process generator
slice: `FSM::IAL2::ProtocolIntent::ValidReadyChannel` accepts one AXI
Valid-Ready contract object, emits reviewable `.isf`, lowers through existing
IAL1 to reviewable `.fsm`, and returns a source-anchor/residue report. `.ppif`
is the first public generic IAL2 file suffix and `bin/fsmgen` now accepts one
`.ppif` Valid-Ready source object with the existing single-channel HDL/semantic
path, plus bounded multi-channel Valid-Ready bundles for aggregate reports,
check JSON, aggregate semantic JSON, generated `.isf`/`.fsm` review artifacts,
and an aggregate wrapper/top SystemVerilog HDL entry with `--verify-hdl`
support for the tracked AW/W sample. Public `.pif`/`.ppi`/`.axi` aliases and
the full AXI manager remain unshipped. Mandatory lowering remains
`IAL2 -> IAL1 -> IAL0`. IAL2 feature completeness on the
SystemVerilog-backed path is now the active priority under
`IAL2-FEATURE-COMPLETENESS-FRONTIER`, including any explicitly selected IAL1
or IAL0/SV prerequisites needed for IAL2 to lower cleanly. The first
in-process AXI manager outstanding-capacity and acceptance/status generator is
now shipped as `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`; it
accepts a structured AXI4 manager contract, emits generated `.isf` before
`.fsm`, reaches SystemVerilog through the existing IAL1/IAL0 path, and reports
schema `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`. The
public `.ppif` capacity/status parser/CLI first slice is now shipped for one
`(manager-capacity-status NAME ...)` object under
`(protocol-platform-intent ...)`, `(profile axi4)`, and top-level source
anchors, with sample, support-accounting, check JSON, semantic JSON, generated
review artifacts, default HDL, and `--verify-hdl` coverage. The next AXI
manager subset is selected as ID-family declaration and static validation, and
the additive optional `(id-families ...)` public `.ppif` extension is now
shipped for the existing capacity/status object with report metadata, a
separate sample, support accounting, check JSON, semantic JSON source identity,
and unchanged generated `.isf`, `.fsm`, and HDL behavior. The next exact AXI
manager subset is selected as a machine-readable AST/structural logical
read/write transaction envelope and static-validation contract; the readiness
audit selects an additive optional `(transactions ...)` static/report metadata
extension under the existing `manager-capacity-status` object, with no
IAL1/IAL0/SV prerequisite for the first slice because transaction events bind
to existing direction-level abstract events. That optional `(transactions ...)`
public `.ppif` extension is now shipped for the existing capacity/status
object with machine-readable AST/structural report metadata, a separate
sample, support accounting, check JSON, semantic JSON source identity, and
initially unchanged generated `.isf`, `.fsm`, and HDL behavior. Transaction
event dispatch and direction fan-in are now shipped for that same object:
distinct per-transaction request/completion events become generated IAL1
inputs, write or read directions with multiple transaction events use OR
fan-in guards, the existing IAL1/IAL0/SystemVerilog path carries the behavior,
and schedule JSON additively reports `transaction_event_dispatch` metadata.
The concrete transaction ID assertion slice is now shipped: transactions with
concrete requested IDs declare used ID-family request/response ID signals as
generated IAL1 inputs, lower assertion-only checks to `.fsm` `+assert`
carriers, emit verification-only SystemVerilog assertions, and report
`id_response_rule_engine` metadata. Auto-ID allocation, ID release, response
demux, ordering, bursts, queued policy, aliases, full-manager behavior, and
VHDL remained residue before the explicit lifecycle work. The AXI manager
auto-ID lifecycle readiness audit is now
complete: the current IAL1/IAL0/SystemVerilog substrate can carry a bounded
scalar request-ID lifecycle, but auto-ID allocation must not be inferred
directly from ID width or existing `(id auto)` syntax. The bounded contract is
now selected as an explicit optional `(auto-id-lifecycle (write (pool ...))
(read (pool ...)))` clause under `manager-capacity-status`; existing
`(id auto)` remains structural/report-only when that clause is absent. That
parser/report metadata and static-validation slice is now shipped with
`auto_id_lifecycle` report metadata, a runnable `.ppif` sample, support
accounting, check JSON, semantic JSON, and initially unchanged generated
`.isf`, `.fsm`, and HDL behavior. Bounded request-ID drive behavior is now
shipped for explicit auto-ID lifecycle families: request ID signals become
generated IAL1 outputs, per-auto-transaction selected-ID/busy state is
generated, deterministic first-free allocation and completion-event release
rules lower through `.fsm` to SystemVerilog, runtime assertions cover
no-ID-available and illegal same-family simultaneous requests, and
`auto_id_lifecycle.generated_behavior` is true. Same-ID ordering, read-data
interleaving/reassembly, bursts, queued policy, aliases, full-manager behavior,
and VHDL remain residue. The bounded AXI write response-demux parser/report
metadata slice is now shipped for explicit
`(response-demux (write (response-event EVENT) (transaction-completion
generated)))` opt-in syntax. The generated behavior follow-up is now shipped:
the generator adds `BID` as a generated IAL1 input, treats write transaction
completion names as generated pulse outputs, emits one guarded response-demux
rule per auto-ID write transaction using `(pulse COMPLETION)`, keeps capacity
and auto-ID release driven by those pulses, emits unmatched/ambiguous response
assertions, and reports `response_demux.generated_behavior` true with
generated rules, completion signals, assertions, and write-demux residue
removed.
The generated behavior readiness audit concluded that write `BID` demux needed
a small IAL1 prerequisite first: generated transaction completion names must
be one-cycle pulse actions, not sticky flopped rule assignments. That
prerequisite is now shipped as bounded IAL1 `(pulse TARGET)` rule actions that
lower as `<1` pulse-domain assignments. The
post-demux report alignment follow-up is now shipped:
`auto_id_lifecycle.residue` removes stale `response_demux` residue when
generated write `BID` demux drives auto-ID release. The first bounded
same-ID step is now shipped as generated auto-ID same-ID avoidance: FSMGen
emits pairwise active selected-ID assertions, reports machine-readable
`same_id_ordering` metadata, removes covered same-ID residue from generated
auto-ID lifecycle and write response-demux reports, and keeps concrete-ID
same-ID ordering plus per-ID response queues as residue. Selector `.36` chose
read response-demux readiness as the next exact slice, readiness audit `.37`
concluded that the public contract must be selected before parser/report or
behavior changes, and selector `.38` chose the explicit bounded read arm with
`(response-scope single-beat)`. The parser/report metadata slice `.39` is now
shipped: `.ppif` accepts read, write, or mixed `response-demux` family arms;
the read arm requires `response-event`, `response-scope single-beat`, and
`transaction-completion generated`; schedule JSON reports structural
`response_demux.read` metadata with `generated_behavior` false; and the new
read-demux sample is covered by check JSON, semantic JSON, and support
accounting. Readiness audit `.40` concluded that bounded single-beat generated
read `RID` response-demux behavior can be implemented directly with no new
IAL1/IAL0/SystemVerilog prerequisite. The generated behavior slice `.41` is
now shipped: response-demux helpers are family-aware, the generator adds
`RID` as a generated input, emits generated read completion pulse
outputs/rules/assertions, and keeps read capacity release plus read auto-ID
release on those generated completion pulses. Schedule JSON reports
`response_demux.read.generated_behavior` true with generated rules, completion
signals, assertions, and read-demux residue removed. Selector `.42` chose
`.43` as the next readiness audit over the interdependent read-data payload,
burst/`RLAST`, and per-ID ordering/reassembly residues after generated read
demux. Audit `.43` concluded that the bounded public read-data payload/status
contract must be selected before parser/report metadata or generated behavior
changes. Selector `.44` chose explicit bounded `(read-data (read ...))`
syntax for single-beat `RDATA`/`RRESP` capture, with generated read
response-demux as the completion source and `RLAST`/bursts deferred. The
`.45` slice now ships parser/report metadata and static validation for that
read-data contract: `.ppif` accepts the structural `read-data` AST form,
check JSON and semantic JSON support-account the new sample, and generated
behavior was initially deferred behind the `.46` readiness audit.
Readiness audit `.46` concluded that generated single-beat `RDATA`/`RRESP`
capture can be implemented directly with no new IAL1/IAL0/SystemVerilog
prerequisite: existing width-bearing IAL1 inputs/outputs and normal guarded
rule assignments can hold captured payload/status values under the generated
read demux completion pulse. Slice `.47` now ships that behavior: explicit
`read-data` contracts generate width-bearing `RDATA`/`RRESP` inputs,
per-transaction data/status outputs, one normal guarded capture rule per read
transaction, schedule JSON generated artifact lists, and
`read_data.generated_behavior: true` with generated-capture residue removed.
Selector `.48` chose `IAL2-FEATURE-COMPLETENESS-FRONTIER.49`, AXI
burst/`RLAST` completion readiness, as the next exact prerequisite before
multi-beat read-data reassembly or broader read-side manager behavior.
Readiness audit `.49` concluded that no new IAL1/IAL0/SystemVerilog substrate
prerequisite is evident for a later bounded `RLAST` implementation, but the
public source contract had to be selected first.
Selector `.50` chose an additive read `response-demux` contract:
`response-scope burst-last` plus one-bit `last-signal`. It keeps generated
transaction completion as the last-beat pulse, publishes no per-transaction
beat-valid output, uses `RLAST` rather than `ARLEN`/beat-count metadata for
this first boundary, rejects the current single-beat `read-data` contract when
paired with burst-last response demux, and leaves multi-beat read-data
reassembly deferred. Slice `.51` ships parser/report metadata and static
validation for that contract, including a support-accounted sample and
structural report fields with `generated_behavior: false`, while generated
`.isf`, `.fsm`, and HDL behavior remain unchanged. Audit `.52` found no new
IAL1/IAL0/SystemVerilog prerequisite. Slice `.53` ships generated
burst-last/`RLAST` completion behavior: explicit burst-last read response
demux now emits the raw response beat input, generated `RID` input, generated
one-bit `RLAST` input, generated transaction completion pulse outputs,
RLAST-gated response-demux rules, assertions, auto-ID lifecycle residue
movement, same-ID coverage movement, and HDL reachability. The active frontier
selector `.54` found one remaining report-contract drift: generated schedule
report prose still describes burst-last `RLAST` metadata as report-only and
generated burst/last-beat tracking as outside the capacity/status shell.
Slice `.55` aligns that report/static text: reports now say burst-last
response-demux generates matched-`RID`-and-`RLAST` last-beat completion
behavior, and list generated burst-last `RLAST` response-demux completion as
supported. Selector `.56` chose
`IAL2-FEATURE-COMPLETENESS-FRONTIER.57`, public AXI burst read-data contract
selection, because the current `read-data` shape is single-beat-only and
cannot yet express burst capture scope, output binding, beat-count/depth,
`RRESP` aggregation, or interleaving semantics. Selector `.57` chooses
explicit last-beat read-data capture as the first bounded burst-side contract:
`capture-scope last-beat`, `status-policy last-beat`, and
`interleaving last-beat-by-rid` under `read-data`, paired only with generated
`response_scope burst_last` response demux. Slice `.58` ships parser/report
metadata and static validation for that contract: `.ppif` accepts the new
last-beat read-data shape, requires generated burst-last read response-demux
metadata, reports `bounded_last_beat_read_data_contract` with
`generated_behavior: false`, adds a strict support-accounted sample, and keeps
generated `.isf`, `.fsm`, HDL behavior, check JSON semantics, and existing
single-beat read-data behavior unchanged. Readiness audit `.59` found no new
IAL1/IAL0/SystemVerilog prerequisite because the existing read-data
input/output/capture-rule helpers can use the generated burst-last completion
pulses from response demux. Slice `.60` now ships generated last-beat
`RDATA`/`RRESP` capture behavior: the last-beat sample emits generated data and
status inputs, per-transaction last-beat data/status outputs, normal guarded
capture rules driven by generated burst-last completion pulses, `.fsm`
assignments, HDL reachability, and read-data generated artifact report lists.
Selector `.61` chooses public AXI burst read-data beat-count/depth contract
selection as the next exact owner, because full multi-beat reassembly,
per-beat outputs, `RRESP` aggregation, missing/extra beat validation, and
per-ID reassembly all need an explicit expected-count/depth contract first.
Selector `.62` chooses an additive ARLEN-based `burst-length` contract:
`source arlen`, width-8 `axlen-plus-one` encoding, transaction-request
capture, required `max-beats` in range `1..256`, and `validation report-only`.
Slice `.63` ships parser/report metadata and static validation for that
contract: `.ppif` accepts optional last-beat `read-data` `burst-length`
metadata, reports ARLEN/max-beats fields, adds a support-accounted sample,
and splits vague beat-count residue into explicit generated-capture and
validation owners. Selector `.64` chooses a generated ARLEN burst-length
capture readiness audit before behavior changes, audit `.65` finds no new
IAL1/IAL0/SystemVerilog substrate prerequisite for raw ARLEN capture, and
implementation `.66` ships that behavior: `axi0_arlen` is a generated width-8
input, each covered read transaction gets raw-ARLEN storage
(`axi0_r0_arlen_q`, `axi0_r1_arlen_q`), request-event guarded capture rules,
`.fsm`/SystemVerilog lowering, `burst_length_generated_behavior: true`, and
generated burst-length input/storage/rule report fields. Audit `.67` finds
the IAL1/IAL0/SystemVerilog substrate ready for generated beat-count/RLAST
validation, but preserves `validation report-only` as no-runtime-check
behavior. Selector `.68` chooses `(validation runtime-assertion)` with
normalized report value `runtime_assertion`, preserves
`validation report-only` as no-runtime-check behavior, and requires parser
support plus generated validation behavior to ship together. Implementation
`.69` ships that first runtime-validation behavior: `.ppif` accepts
`validation runtime-assertion`, the generator emits per-transaction
expected-beat storage, matched-read-beat counters, initialization and
increment rules, runtime assertions for ARLEN bounds, extra beats, early
`RLAST`, and missing final `RLAST`, and schedule JSON reports generated
beat-count validation artifacts while report-only behavior remains unchanged.
Implementation `.72` ships parser/report metadata and static validation for
the public AXI multi-beat read-data reassembly/output contract selected by
`.71`: `capture-scope multi-beat` with mandatory ARLEN `burst-length`
runtime assertions, per-beat status, `multi-beat-by-rid` interleaving,
per-transaction data/status output prefixes, valid-mask outputs, and length
outputs. Audit `.73` found no new IAL1/IAL0/SystemVerilog prerequisite for
generated output-bank behavior. Implementation `.74` ships that behavior:
the public multi-beat sample now emits generated `RDATA`/`RRESP` inputs,
per-transaction data/status lane outputs, valid-mask outputs, length outputs,
request-time output-bank clearing, and lane capture rules guarded by matched
read beat, `!request_event`, and current beat-count equality. Schedule JSON
reports `multi_beat_reassembly_generated_behavior: true`, lists generated
multi-beat output/init/capture artifacts, and reduces read-data residue to
`rresp_aggregation`. Selector `.75` chooses public scalar `RRESP`
aggregation contract selection as the next exact owner before parser/report
metadata or generated behavior changes. Selector `.76` chooses additive
scalar `RRESP` aggregation syntax: read-level
`(status-aggregation (policy worst-observed))` plus transaction-local
`(status-aggregate-output NAME)`, reported as `worst_observed`. Per-beat
`RRESP` lanes remain mandatory. Implementation `.77` ships parser/report
metadata and static validation for that public contract: the multi-beat sample
now accepts `status-aggregation`, reports `status_aggregation` as
`worst_observed`, `status_aggregation_generated_behavior: false`,
`status_aggregate_output: per_transaction_scalar`, per-transaction aggregate
output names/widths, and narrows read-data residue to
`generated_rresp_aggregation` while leaving generated `.isf`, `.fsm`, and HDL
output-bank behavior unchanged. Audit `.78` finds no new
IAL1/IAL0/SystemVerilog prerequisite for first generated width-2
`worst_observed` scalar behavior. Implementation `.79` ships that behavior:
the multi-beat sample now emits width-2 scalar aggregate outputs such as
`axi0_r0_rresp`, initializes them to `2'd0` on request in the existing
output-bank init rule, updates them on matched accepted read-data beats when
the current aggregate is less than the current `RRESP` under `!request_event`,
reports generated aggregate output/init/update artifacts, and removes
`generated_rresp_aggregation` from read-data residue. Width-3 responses
remain deferred. Selector `.80` chooses `.81`, AXI per-ID read-data
interleaving and queue readiness, because the live public sample now has empty
`read_data` residue while `response_demux` and `same_id_ordering` still carry
read-data interleaving, bursts, concrete-ID same-ID ordering, and per-ID queue
residue. Audit `.81` finds the current generated auto-ID multi-beat sample
already has bounded `multi_beat_by_rid` output-bank behavior through generated
same-ID avoidance, matched-`RID` response demux, and per-transaction beat
counters/output banks. The broad `read_data_interleaving` residue is therefore
too conservative for that covered subset. Implementation `.82` aligns that
report/static residue: the public multi-beat sample now reports
`response_demux.residue: [bursts]` and
`same_id_ordering.residue: [concrete_id_same_id_ordering,
per_id_issue_order_queues, bursts]` while keeping `read_data.residue: []`.
Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. Selector
`.83` chooses `IAL2-FEATURE-COMPLETENESS-FRONTIER.84`, AXI burst
payload/output readiness, because `bursts` is now the only
`response_demux` residue and remains shared with `same_id_ordering` while the
public multi-beat sample already has burst-last `RLAST` demux, raw ARLEN
capture, beat-count/RLAST runtime validation, per-beat output banks, valid
masks, length outputs, and scalar aggregate `RRESP`. Audit `.84` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.85`, report/static `bursts` residue
alignment for the covered generated auto-ID multi-beat output-bank subset,
because the selected per-beat output bank is already the bounded burst
payload/output shape for that subset. Packed/full burst assembly remains a
separate deferred contract. Verification-code generation
(`SV/UVM` agents, monitors, scoreboards, checkers, coverage, and reusable VIP)
is a valid future FSMGEN route, but it is tracked as a separate roadmap lane
from the current synthesizable RTL/HDL feature-completeness path.
Implementation `.85` ships that report/static alignment: the public
multi-beat sample now reports `response_demux.residue: []` and
`same_id_ordering.residue: [concrete_id_same_id_ordering,
per_id_issue_order_queues]` while keeping `read_data.residue: []`.
Generated `.isf`, `.fsm`, and SystemVerilog behavior is unchanged. The next
selector was `IAL2-FEATURE-COMPLETENESS-FRONTIER.86`, which chose the
next AXI manager feature-completeness owner and carried the IAL2 factoring
question: keep a small common semantic core only where reuse across multiple
profiles is proven, and leave premature one-protocol abstractions in
protocol/platform vocabularies until evidence justifies sharing.
Selector `.86` chooses `IAL2-FEATURE-COMPLETENESS-FRONTIER.87`, AXI
concrete-ID same-ID ordering readiness. The public multi-beat sample now
leaves only `concrete_id_same_id_ordering` and `per_id_issue_order_queues`
under `same_id_ordering.residue`, while concrete-ID samples still keep
`same_id_ordering` under `id_response_rule_engine.residue`. Audit `.87`
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.88`, conservative fail-closed
static validation for multiple concrete-ID transactions in the same read or
write response family that share one concrete ID value. Implementation `.88`
now rejects that unsupported authored same-ID reuse before any per-ID queue,
scoreboard, public same-ID policy, or full same-ID ordering behavior, while
leaving valid single-concrete-ID samples behavior-stable. Selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.89` selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.90`, AXI per-ID issue-order queue
readiness, because direct queue behavior needs a public same-ID reuse policy
and substrate audit before implementation. Audit `.90` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.91`, AXI same-ID reuse policy contract
selection, because the lower layers can carry bounded scalar/bank state but
the public source still does not define reject, queue, stall, block, or
scoreboard semantics for accepted same-ID reuse. Selector `.91` chooses an
optional AXI-profile-local `(same-id-ordering (read|write
(concrete-id-reuse reject)))` source contract and selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.92`, which now ships parser/report
metadata plus static validation for that explicit reject policy. The PPIF
adapter accepts one optional `(same-id-ordering ...)` clause, duplicate or
missing policy arms fail closed, omitted policy preserves the `.88`
unselected-policy diagnostic, explicit `reject` emits a policy-specific
same-family concrete-ID reuse diagnostic, and `scoreboard` remains rejected.
Schedule JSON reports
`same_id_ordering.mode: concrete_id_reuse_policy` and
`concrete_id_reuse_policy.<family>.generated_queue_behavior: false`; generated
`.isf`, `.fsm`, and SystemVerilog stay unchanged for valid sources. Selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.93` chooses
`IAL2-FEATURE-COMPLETENESS-FRONTIER.94`, public AXI same-ID issue-order queue
policy contract selection, before parser/report metadata or generated queue
behavior. Selector `.94` chooses family-local
`(concrete-id-reuse issue-order-queue)` under the existing
`same-id-ordering` clause, with queue depth bounded by family `max-pending`
and concrete transaction inventory. It requires queue-head response demux for
accepted same-ID reuse and selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.95`,
a behavior-readiness audit, before parser/report metadata or generated queue
behavior. Audit `.95` finds generated queue-head behavior is too broad to
ship directly because current response demux is auto-ID selected-ID matching,
concrete transactions have no queue-head state, and queue enqueue needs an
admitted per-transaction request boundary. It selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.96`, parser/report metadata and static
validation for `issue-order-queue`, with `implementation_status:
selected_not_generated` and duplicated concrete same-ID reuse still
fail-closed until generated queue-head behavior ships. Implementation `.96`
now accepts `(concrete-id-reuse issue-order-queue)` in read/write
`same-id-ordering` arms, normalizes the report policy to `issue_order_queue`,
reports `accepted_same_id_reuse: false` and `generated_queue_behavior: false`,
keeps duplicated concrete same-ID transactions fail-closed with a
selected-not-generated diagnostic, and adds
`ppif/axi_manager_capacity_status_same_id_issue_order_queue_policy.ppif` as a
support-accounted metadata-only sample. Audit `.97` finds that queue state and
queue-head response demux remain too broad for the next slice. The smaller
prerequisite is admitted per-transaction request pulses for selected
`issue-order-queue` families. Implementation `.98` now emits one internal
admitted-request pulse storage target plus one pulse rule per concrete
transaction in the selected family, with the guard derived from the
transaction request event, current direction pending storage, family
`max-pending`, and same-cycle completion fan-in, not from the generated
`can_accept` status output. Schedule JSON reports
`enforcement: admitted_request_boundary`,
`implementation_status: admitted_request_pulses_generated`,
`accepted_same_id_reuse: false`, `generated_queue_behavior: false`, and the
`admitted_request_boundary` pulse/rule/guard payload under
`same_id_ordering.concrete_id_reuse_policy.<family>`. Multi-transaction
selected families also emit a request mutual-exclusion assertion so one
direction-level capacity increment cannot admit multiple concrete identities
in the same cycle. Duplicated concrete same-ID reuse, queue state,
queue-head response demux, accepted same-ID reuse, direct backend lowering,
and VHDL remain fail-closed/deferred. `.98` advances the active frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.99`, the next AXI manager selector after
admitted request pulses. Selector `.99` chooses
`IAL2-FEATURE-COMPLETENESS-FRONTIER.100`, AXI same-ID issue-order queue state
and queue-head demux readiness audit, because admitted request pulses solve
only the enqueue boundary. Accepted same-ID reuse still needs bounded
queue storage, enqueue/dequeue semantics, queue-head response demux,
duplicate-ID validation changes, assertions, and residue movement to be
audited together before generated behavior changes.
Audit `.100` confirms the next behavior step should still not be direct
queue-state or queue-head demux implementation. The selected same-ID sample
reports admitted request pulses, but `accepted_same_id_reuse` and
`generated_queue_behavior` remain false. Existing generated response demux is
auto-ID busy/selected-ID matching, including the read burst-last path, so
queue-head demux needs queue identity state first. The active frontier is now
`IAL2-FEATURE-COMPLETENESS-FRONTIER.101`, bounded AXI same-ID issue-order
queue state representation selection, to pin down grouping, bounds, storage
shape, transaction identity encoding, diagnostics, assertions, report
vocabulary, and the later implementation split before duplicate concrete
same-ID reuse can be accepted.
Selector `.101` chooses `compact_onehot_transaction_slots` as the future
generated queue representation: family-local and concrete-ID-value-local
compacted slots, slot `0` as head, one explicit transaction identity bit per
slot/transaction, depth bounded by `min(max-pending, concrete transaction
inventory)`, enqueue sourced only from admitted request pulses, and no arrays,
dynamic indexed left-hand sides, hidden unbounded queues, or pointer modulo
arithmetic. It also finds that implementation still needs a concrete same-ID
queue-head response-demux source contract because the current
`response-demux` syntax and implementation are auto-ID-lifecycle oriented.
The active frontier is now `IAL2-FEATURE-COMPLETENESS-FRONTIER.102`, AXI
same-ID queue-head response-demux contract selection.
Selector `.102` reuses the existing `response-demux` read/write family arms
for concrete same-ID queue-head demux, but only when the same family selects
`concrete-id-reuse issue-order-queue`, has duplicate concrete-ID groups, and
does not also require same-family auto-ID demux in the first contract. The
selected report modes are `bounded_write_bid_queue_head_demux_contract` and
`bounded_read_rid_queue_head_demux_contract`, both selected-not-generated
until behavior ships. The active frontier is now
`IAL2-FEATURE-COMPLETENESS-FRONTIER.103`, AXI same-ID queue-head
response-demux metadata/static validation.
Implementation `.103` ships that selected-not-generated metadata and static
validation. The public sample
`ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif`
uses two concrete read transactions sharing ID `3`, selected
`issue-order-queue`, and a burst-last read `response-demux` arm. Schedule JSON
reports `bounded_read_rid_queue_head_demux_contract`,
`implementation_status: selected_not_generated`,
`transaction_completion_source: generated_queue_head_demux`, and the duplicate
concrete-ID queue group, while `accepted_same_id_reuse` and
`generated_queue_behavior` remain false. Read-data consumption of this
selected-not-generated queue-head demux fails closed. The active frontier is
now `IAL2-FEATURE-COMPLETENESS-FRONTIER.104`, generated same-ID queue
state/queue-head behavior readiness. Audit `.104` finds no obvious new
IAL1/IAL0/SystemVerilog substrate prerequisite for the first bounded generated
same-ID behavior slice, but direct broad implementation is still too large:
queue state needs a queue-head-demux dequeue event, and queue-head demux needs
queue-head transaction identity from queue state. The active frontier advances
to `IAL2-FEATURE-COMPLETENESS-FRONTIER.105`, first generated AXI same-ID queue
state and queue-head behavior slice selection, before generated queue behavior
or accepted same-ID reuse can change. Selector `.105` chooses the first
generated behavior implementation boundary as the existing read burst-last
queue-head sample shape: one duplicate concrete read-ID group, two read
transactions, computed depth 2, generated compact one-hot queue state, and
generated queue-head completion demux shipped together. The active frontier
advances to `IAL2-FEATURE-COMPLETENESS-FRONTIER.106`, generated AXI same-ID
read burst-last queue state and queue-head demux behavior. Implementation
`.106` now ships that bounded behavior for the public sample: `r0`/`r1`
completion names are generated pulse outputs, raw read response/RID/RLAST are
generated inputs, compact one-hot depth-2 queue slots track issue order, finite
enqueue/dequeue/same-cycle update rules maintain the queue, and queue-head
last-beat matches pulse the covered transaction completions. Schedule JSON now
reports `response_demux.generated_behavior: true`,
`same_id_ordering.generated_behavior: true`,
`accepted_same_id_reuse: true`, and `generated_queue_behavior: true` only for
that covered read burst-last two-transaction depth-2 shape. Write behavior,
read `single-beat`, deeper or multiple groups, same-family mixed auto-ID,
read-data consumption of concrete queue-head demux, direct backend, and VHDL
remain deferred. The active frontier advances to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.107`, the next same-ID queue behavior
expansion audit/selector. Selector `.107` chooses the next behavior owner as
`IAL2-FEATURE-COMPLETENESS-FRONTIER.108`: generated write-family concrete
same-ID queue-head behavior for exactly one duplicate write-ID group of two
transactions at depth 2. That next slice should reuse compact one-hot queue
slots and queue-head `BID` demux, while keeping read `single-beat`, deeper or
multiple groups, same-family mixed auto-ID, read-data consumption, direct
backend, and VHDL deferred.
Implementation `.108` ships that bounded write behavior for
`ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif`.
The covered write sample generates admitted write enqueue pulses, compact
one-hot depth-2 queue slots for concrete write ID `3`, finite queue updates,
generated `axi0_w0_complete`/`axi0_w1_complete` pulse outputs, and queue-head
`BID` demux rules guarded by `axi0_write_complete`, `axi0_bid == 4'd3`, and
the slot-0 transaction bit. Schedule JSON reports
`generated_write_bid_queue_head_demux`, accepted same-ID reuse, and generated
queue behavior for that write shape. At that point, read `single-beat`
remained deferred until `.110`; deeper or multiple groups, same-family mixed
auto-ID, read-data consumption of concrete queue-head demux, direct backend,
and VHDL remain deferred.
After `.108`, the frontier advanced to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.109`, the same-ID queue behavior
expansion audit/selector after shipped read burst-last and write depth-2
queue-head behavior.
Selector `.109` chooses
`IAL2-FEATURE-COMPLETENESS-FRONTIER.110`: generated read `single-beat`
concrete same-ID queue-head behavior for one duplicate read-ID group of two
transactions at depth 2. Implementation `.110` ships that bounded shape for
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif`:
compact one-hot read queue slots, admitted read enqueue pulses, generated read
completion pulse outputs, queue-head `RID` demux rules without `RLAST`,
support-accounting coverage, and Verilator-clean generated SystemVerilog.
Read-data consumption, deeper or multiple groups, same-family mixed auto-ID,
generalized per-ID queues, direct backend, and VHDL remain deferred. The
`.111` selector chooses `IAL2-FEATURE-COMPLETENESS-FRONTIER.112`, AXI
read-data consumption of generated concrete same-ID queue-head demux
readiness. Existing generated read-data capture consumes generated auto-ID
read response-demux completion pulses, but the current contract still
fail-closes when `read_data` consumes a concrete queue-head read demux. Audit
`.112` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.113`,
generated single-beat read-data capture for the bounded read single-beat
concrete same-ID queue-head demux shape. No lowerer prerequisite is evident:
the behavior slice must make read-data coverage source-aware for generated
queue-head completion signals instead of only auto-ID transaction lists, then
add the combined public sample, tests, support accounting, and docs.
Implementation `.113` now ships that bounded behavior for
`ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif`:
generated `RDATA`/`RRESP` inputs, per-transaction data/status outputs,
capture rules guarded by generated queue-head completion pulses, and
`completion_validity: generated_queue_head_response_demux_completion_pulse`
while preserving existing auto-ID read-data report values. Selector `.114`
selected `.115`, generated last-beat read-data capture for the bounded read
burst-last concrete same-ID queue-head demux shape. Implementation `.115` now
ships that bounded behavior for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_read_data.ppif`:
the generator reuses the already generated `RLAST`-qualified queue-head
completion pulses, emits generated `RDATA`/`RRESP` inputs plus
per-transaction last-beat data/status outputs, guards capture rules with the
generated queue-head last-beat completion pulses, and reports
`generated_queue_head_response_demux_last_beat_completion_pulse` while
preserving existing auto-ID last-beat and queue-head single-beat read-data
report values. Selector `.116` chose `.117`, generated raw-`ARLEN`
burst-length capture for the bounded queue-head last-beat read-data shape.
Implementation `.117` now ships that bounded report-only burst-length behavior
for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length.ppif`:
the generator emits generated `axi0_arlen` input, per-transaction raw-`ARLEN`
storage, request-guarded burst-length capture rules, the existing queue-head
last-beat `RDATA`/`RRESP` capture rules, and report fields with
`burst_length_generated_behavior: true` while keeping
`completion_validity: generated_queue_head_response_demux_last_beat_completion_pulse`.
Selector `.118` chose `.119`, generated queue-head beat-count/RLAST runtime
validation for the bounded queue-head last-beat read-data shape.
Implementation `.119` now ships that runtime-validation sibling for
`ppif/axi_manager_capacity_status_read_last_beat_same_id_queue_head_burst_length_runtime_assertion.ppif`:
the generator preserves request-bound raw-`ARLEN` capture and queue-head
last-beat `RDATA`/`RRESP` capture, adds expected-count storage,
matched-read-beat counters, initialization/increment rules, and runtime
assertions for request-time `ARLEN` bounds, over-count/extra beats, early
`RLAST`, and missing final `RLAST`. It keeps the queue-head last-beat
completion-validity report and counts matched read beats from raw response
event plus concrete `RID` plus active queue-head transaction identity before
any multi-beat queue-head read-data, deeper or multiple queue groups, mixed
auto-ID, direct backend, or VHDL work.
Implementation `.121` now ships generated multi-beat read-data output-bank
behavior for the same bounded read burst-last concrete same-ID queue-head
demux shape in
`ppif/axi_manager_capacity_status_read_multi_beat_same_id_queue_head_read_data.ppif`.
The generated path emits request-time output-bank clearing, per-beat
`RDATA`/`RRESP` lane captures guarded by raw matched queue-head read beat
plus beat-count lane index, valid-mask and length outputs, scalar `RRESP`
aggregation, generated beat-count/`RLAST` validation artifacts, and empty
`read_data`/`response_demux` residue for that bounded sample.
Selector `.122` chose `.123`, a readiness audit for multiple independent read
burst-last depth-2 concrete same-ID queue-head response-demux groups. Audit
`.123` selected `.124`, generated read burst-last response-demux-only
queue-head behavior for two or more duplicate concrete read-ID groups, each
exactly two transactions at computed depth `2`. Implementation `.124` now
ships that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif`.
The generated path emits concrete-ID-scoped compact one-hot queue storage,
finite depth-2 transition rules, generated completion pulse outputs, and
queue-head response-demux rules for `RID` `3` and `RID` `5` groups while
preserving the existing family-wide admitted-request onehot boundary.
Selector `.125` chose `.126`, readiness audit for read-data coverage over
multiple generated read burst-last concrete same-ID queue-head groups. Audit
`.126` selected `.127`, generated multi-group queue-head multi-beat read-data
output-bank behavior. Implementation `.127` now ships that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif`.
The generated path flattens the `RID` `3` and `RID` `5` generated queue groups
into multi-beat read-data coverage, emits per-transaction output-bank clearing,
`RDATA`/`RRESP` lane capture, valid masks, length outputs, scalar `RRESP`
aggregation, raw-`ARLEN` capture, and beat-count/`RLAST` runtime validation,
and reports empty `read_data`/`response_demux` residue for the bounded sample.
Audit `.129` selected `.130`, generated multi-group queue-head last-beat
read-data capture. Implementation `.130` now ships that behavior for
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_read_data.ppif`.
The generated path flattens the `RID` `3` and `RID` `5` generated queue groups
into scalar last-beat read-data coverage, emits generated `RDATA`/`RRESP`
inputs, per-transaction last-beat data/status outputs, and scalar capture rules
guarded by generated queue-head last-beat completion pulses, while keeping
`burst_length` metadata absent. Implementation `.132` now ships report-only
raw-`ARLEN` burst-length capture for the same multi-group queue-head scalar
last-beat shape:
`ppif/axi_manager_capacity_status_read_multi_group_last_beat_same_id_queue_head_burst_length.ppif`
adds the shared generated `axi0_arlen` input, per-transaction raw-`ARLEN`
storage for `r0`, `r1`, `r2`, and `r3`, request-guarded burst-length capture
rules, and preserves the generated queue-head last-beat scalar capture rules.
The report records `burst_length_validation: report_only`, the four
generated burst-length storage elements/rules, and
`generated_beat_count_validation` residue. Runtime beat-count/`RLAST`
multi-group scalar validation, same-family auto-ID, deeper queues, write or
read single-beat multi-group queue-head behavior, packed outputs, direct
backend, and VHDL remain deferred.
Selector `.131` chose `.132`, generated report-only raw-`ARLEN` burst-length
capture for the multi-group queue-head scalar last-beat read-data shape, and
`.132` completed that implementation boundary. Selector `.133` chose `.134`,
readiness audit for generated runtime-validation multi-group queue-head scalar
last-beat read-data, because the next behavior would add expected-beat
storage, matched-beat counters, and beat-count/`RLAST` assertions across
multiple queue groups while preserving scalar final outputs.
The IAL2 factoring stance remains evidence-driven: keep AXI-specific same-ID
ordering in the AXI vocabulary until another profile proves the same semantic
need.
Full-manager behavior, profile aliases, queued/blocking policy, direct
backend lowering, and VHDL remain residue. VHDL remains behind SV-backed IAL
feature completeness.

The project objective is robust, traceable FSM-to-HDL generation with clear assignment semantics, optimization via AST factorization, and behavior-preserving refactoring toward a modular architecture.

## Fast ramp-up order
1. `README.md` (this file): project objective + navigation.
2. `COMMIT.md`: mandatory commit workflow and safety invariant for crash recovery.
3. `SESSION_BOOTSTRAP.md`: default first task for a new engineering session.
4. `ROADMAP_STATUS.md`: canonical live roadmap/workstream status.
5. `docs/TASK_TREE_README.md`: setup guide for adopting this task-tree tracking workflow in another project.
6. `docs/TASK_TREE.md`: repo-local task-tree workflow, active tree index, and PNT frontier rules.
7. `ROADMAP_V2.md`: detailed post-`R0`..`R7` roadmap intent and sequencing.
8. `docs/book/src/SUMMARY.md`: progressive mdBook table of contents.
9. `docs/USER_GUIDE.md`: broad live reference during the book split.
10. `docs/COMPOSITION_SCOPE.md`: concrete `R6` composition scope and acceptance boundary.
11. `docs/COMPOSITION_LEGACY_MAPPING.md`: historical `fx/bin/fsmgen` composition behavior mapped onto the active `R6` plan.
12. `docs/EXTENSION_MODEL.md`: active `R7` typed extension boundary replacing legacy `.plg` / `PPlugin` as architecture direction.
13. `docs/SPECFORGE_FEEDBACK_RESPONSE.md`: FSMGen's tracked response and alignment plan for SPECFORGE adapter feedback.
14. `docs/INTENT_SCHEDULING_BRAINSTORM.md`: living brainstorm log for an intent-scheduling layer above explicit cycle-authored `.fsm`.
15. `docs/ISF_ATL_DESIGN_PROPOSAL.md`: live design proposal for ISF Actor Transfer Level actor-network orchestration.
16. `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`: single self-contained downstream `.isf` integration handoff.
17. `docs/DOWNSTREAM_ISSUE_REPORTING.md`: strict downstream issue-reporting protocol for local FSMGen reproduction.
18. `docs/ISF_SPEC.md`: active R14 `.isf` Intent Scheduling Format specification.
19. `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`: live downstream-consumer API contract for ISF parser/scheduler surfaces.
20. `docs/ISF_LIBRARY_CATALOG.md`: live catalog of shipped reusable ISF library definitions.
21. `docs/BIN_FSMGEN_IMPORT_TREE.md`: live `bin/fsmgen` import-tree and runtime-spine architecture snapshot.
22. `docs/REGRESSION_CORPUS.md`: human-readable regression/support-accounting corpus companion.
23. `docs/INTENT_CAPTURE_AXI_CASE_STUDY.md`: AXI intent-capture case-study notes for future high-level synthesis work.
24. `docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md`: first non-code IAL2 protocol/platform intent evaluation and go/no-go criteria.
25. `docs/AXI_VALID_READY_INTENT_PROBE.md`: first AXI Valid-Ready source-anchor evidence inventory for future IAL2 design/probe work.
26. `docs/AXI_MANAGER_USER_API_BRAINSTORM.md`: captured AXI manager user-facing API direction for future IAL2 work.
27. `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md`: first AXI ID/order/concurrency source-anchor evidence inventory for future IAL2 manager rule-engine work.
28. `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md`: first AXI manager source-to-rule responsibility matrix for future IAL2 work.
29. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md`: selected the first post-Valid-Ready AXI manager subset: outstanding-capacity plus acceptance/status feedback.
30. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT.md`: readiness audit for the selected AXI manager capacity/status subset and first in-process generator boundary.
31. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md`: first in-process AXI manager capacity/status generator slice and report surface.
32. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md`: selected public `.ppif` syntax/readiness boundary for one AXI manager capacity/status object.
33. `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md`: first public `.ppif` parser/CLI slice for one AXI manager capacity/status object.
34. `docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md`: selected the next AXI manager subset: ID-family declaration and static validation.
35. `docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md`: readiness audit for the additive ID-family/static-validation implementation boundary.
36. `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md`: shipped additive `.ppif` ID-family metadata slice for one AXI manager capacity/status object.
37. `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md`: selected the next AXI manager subset: logical read/write transaction envelope and static validation.
38. `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md`: readiness audit for the additive transaction-envelope/static-validation implementation boundary.
39. `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md`: shipped additive `.ppif` transaction-envelope metadata slice for one AXI manager capacity/status object.
40. `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md`: selected the next prerequisite: transaction event dispatch and direction fan-in.
41. `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md`: readiness audit for additive per-transaction event dispatch and direction fan-in.
42. `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md`: shipped additive `.ppif` transaction event dispatch/fan-in slice for one AXI manager capacity/status object.
43. `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md`: selected the next AXI manager subset: ID/response rule-engine readiness.
44. `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md`: readiness audit for additive concrete transaction ID request/response assertions.
45. `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md`: shipped additive concrete transaction ID request/response assertions for the public AXI manager capacity/status object.
46. `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md`: selected AXI manager auto-ID lifecycle/request-ID drive readiness as the next subset.
47. `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md`: readiness audit selecting bounded auto-ID pool/request-ID drive contract selection before implementation.
48. `docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md`: selected explicit optional `auto-id-lifecycle` bounded-pool syntax before parser/report implementation.
49. `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md`: shipped additive `.ppif` auto-ID lifecycle parser/report metadata for one AXI manager capacity/status object.
50. `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md`: shipped bounded auto-ID request-ID drive behavior for explicit lifecycle families.
51. `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md`: selected AXI manager generated response-demux readiness after bounded auto-ID request-ID drive.
52. `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md`: readiness audit selecting bounded write response-demux public contract before implementation.
53. `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md`: selected explicit write-only `response-demux` public syntax before parser/report implementation.
54. `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`: shipped write-only `response-demux` parser/report metadata for one AXI manager capacity/status object.
55. `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`: readiness audit selecting the IAL1 rule-pulse prerequisite before generated write `BID` demux behavior.
56. `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`: shipped generated write `BID` response-demux behavior for explicit `response-demux` contracts.
57. `docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md`: selected report-residue alignment after generated write `BID` demux before larger ordering/read-response work.
58. `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md`: shipped auto-ID lifecycle report-residue alignment after generated write `BID` demux.
59. `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md`: selected same-ID ordering readiness after generated write response demux and residue alignment.
60. `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md`: readiness audit selecting bounded auto-ID same-ID avoidance assertions/report metadata before per-ID queues.
61. `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md`: shipped bounded generated auto-ID same-ID avoidance assertions/report metadata.
62. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md`: selected read `RID` response-demux readiness after generated auto-ID same-ID avoidance.
63. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md`: readiness audit selecting a bounded read response-demux public contract before parser/report or behavior changes.
64. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md`: selected explicit `response-scope single-beat` read response-demux syntax before parser/report implementation.
65. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`: shipped read response-demux parser/report metadata and static validation without generated read behavior.
66. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md`: readiness audit selecting bounded generated single-beat read `RID` response-demux behavior before implementation.
67. `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md`: shipped bounded generated single-beat read `RID` response-demux behavior.
68. `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md`: selected read-data payload/burst readiness after generated read response demux.
69. `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md`: readiness audit selecting bounded read-data contract selection before parser/report or behavior changes.
70. `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md`: selected explicit bounded `read-data` syntax for single-beat `RDATA`/`RRESP` metadata.
71. `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md`: shipped read-data parser/report metadata and static validation without generated data-capture behavior.
72. `docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md`: readiness audit selecting direct generated single-beat `RDATA`/`RRESP` capture behavior before implementation.
73. `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md`: shipped generated single-beat `RDATA`/`RRESP` capture behavior for explicit `read-data` contracts.
74. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md`: readiness audit selecting public burst/`RLAST` completion contract selection before parser/report or generated behavior changes.
75. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md`: selected additive `response-scope burst-last` plus one-bit `last-signal` syntax before parser/report implementation.
76. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for `response-scope burst-last` with generated behavior deferred.
77. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md`: readiness audit selecting direct generated burst-last/`RLAST` completion behavior.
78. `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md`: shipped generated burst-last/`RLAST` completion behavior.
79. `docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md`: selected AXI `RLAST` report/static-text alignment after generated `RLAST` behavior.
80. `docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md`: shipped AXI `RLAST` schedule-report prose alignment after generated behavior.
81. `docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md`: selected public AXI burst read-data contract selection after generated `RLAST` completion/report alignment.
82. `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md`: selected explicit last-beat `RDATA`/`RRESP` capture as the first bounded burst read-data contract.
83. `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for explicit last-beat `RDATA`/`RRESP` capture with generated behavior deferred.
84. `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md`: readiness audit selecting direct generated last-beat `RDATA`/`RRESP` capture behavior.
85. `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md`: shipped generated last-beat `RDATA`/`RRESP` capture behavior.
86. `docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`: selected public AXI burst read-data beat-count/depth contract selection after generated last-beat capture.
87. `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md`: selected ARLEN-based `burst-length` syntax and report contract before parser/report metadata.
88. `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for ARLEN-based `burst-length` contracts.
89. `docs/AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md`: selected generated ARLEN burst-length capture readiness audit after report-only metadata.
90. `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md`: audited generated raw-ARLEN capture readiness and selected direct behavior.
91. `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md`: shipped generated raw-ARLEN capture behavior for opt-in last-beat read-data `burst-length` contracts.
92. `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md`: audited beat-count/RLAST validation readiness and selected public runtime-validation contract selection before behavior.
93. `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md`: selected `(validation runtime-assertion)` / `runtime_assertion` as the public beat-count/RLAST validation contract before behavior.
94. `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md`: shipped generated beat-count/RLAST runtime validation for `(validation runtime-assertion)` burst-length contracts.
95. `docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md`: selected public multi-beat read-data reassembly/output contract selection after generated beat-count/RLAST validation.
96. `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md`: selected per-beat output-bank public contract for multi-beat read-data reassembly/output.
97. `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for the public multi-beat read-data output-bank contract.
98. `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md`: audited generated output-bank behavior readiness and selected direct scalar-lane behavior.
99. `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md`: shipped generated multi-beat read-data output-bank behavior for the public multi-beat sample.
100. `docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md`: selected public scalar `RRESP` aggregation contract selection after generated multi-beat read-data output-bank behavior.
101. `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md`: selected additive scalar `RRESP` aggregation syntax and report contract before parser/report metadata.
102. `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md`: shipped parser/report metadata and static validation for the selected scalar `RRESP` aggregation contract.
103. `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md`: audited generated scalar `RRESP` aggregation readiness and selected direct generated behavior.
104. `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md`: shipped generated scalar `RRESP` aggregation outputs/init/update behavior.
105. `docs/AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md`: selected per-ID read-data interleaving and queue readiness after scalar `RRESP` aggregation.
106. `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md`: audited read-data interleaving/queue readiness and selected report/static residue alignment for the covered generated auto-ID multi-beat-by-RID subset.
107. `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md`: aligned read-data interleaving residue for the covered generated auto-ID multi-beat-by-RID subset.
108. `docs/AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION.md`: selected AXI burst payload/output readiness audit after read-data interleaving residue alignment.
109. `docs/AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT.md`: audited bounded burst payload/output readiness and selected report/static `bursts` residue alignment.
110. `docs/AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md`: aligned broad `bursts` residue for the covered generated auto-ID multi-beat output-bank subset.
111. `docs/AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md`: selected AXI concrete-ID same-ID ordering readiness after bounded burst residue alignment.
112. `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md`: audited concrete-ID same-ID ordering readiness and selected fail-closed static validation.
113. `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md`: shipped fail-closed static validation for unsupported same-family concrete-ID reuse.
114. `docs/AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md`: selected per-ID issue-order queue readiness after concrete-ID static validation.
115. `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md`: audited per-ID issue-order queue readiness and selected same-ID reuse policy contract selection.
116. `docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md`: selected explicit same-ID reuse reject policy syntax before parser/report metadata.
117. `docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md`: shipped parser/report metadata and static validation for explicit same-ID reuse reject policy.
118. `docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md`: selected same-ID issue-order queue policy contract selection after explicit reject policy.
119. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md`: selected the public AXI same-ID `issue-order-queue` policy contract and the follow-up behavior-readiness audit.
120. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md`: audited same-ID `issue-order-queue` behavior readiness and selected metadata-first support.
121. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md`: shipped metadata-first parser/report support for selected-not-generated `issue-order-queue`.
122. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md`: audited admitted enqueue readiness and selected admitted request pulses before queue state.
123. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md`: shipped admitted request pulse generation for selected same-ID `issue-order-queue` families while accepted same-ID reuse remains deferred.
124. `docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md`: selected same-ID issue-order queue state and queue-head demux readiness after admitted request pulses.
125. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md`: audited same-ID issue-order queue state and queue-head demux readiness after admitted request pulses.
126. `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md`: selected compact one-hot transaction slots as the future bounded same-ID queue representation.
127. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md`: selected the public/report contract for concrete same-ID queue-head response demux.
128. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md`: shipped selected-not-generated same-ID queue-head response-demux parser/report metadata and static validation.
129. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md`: audited generated same-ID queue state plus queue-head behavior readiness and selected the first generated behavior slice selector.
130. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md`: selected the first generated same-ID queue behavior implementation boundary.
131. `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md`: shipped bounded generated read burst-last depth-2 concrete same-ID queue state plus queue-head response demux.
132. `docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped bounded generated write depth-2 concrete same-ID queue state plus queue-head `BID` response demux.
133. `docs/AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md`: selected read `single-beat` depth-2 concrete same-ID queue-head response demux as the next bounded behavior slice.
134. `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped bounded generated read single-beat depth-2 concrete same-ID queue state plus queue-head `RID` response demux without `RLAST`.
135. `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md`: selected queue-head read-data consumption readiness after generated read single-beat same-ID queue-head behavior.
136. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`: audited queue-head read-data readiness and selected generated single-beat queue-head read-data capture.
137. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md`: shipped generated single-beat queue-head `RDATA`/`RRESP` capture for the bounded read single-beat concrete same-ID queue-head sample.
138. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`: selected generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
139. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
140. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`: selected generated raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data shape.
141. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`: shipped report-only raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data sample.
142. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md`: selected generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data shape.
143. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md`: shipped generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data sample.
144. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md`: selected generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head demux shape.
145. `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head sample.
146. `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md`: selected multiple independent read burst-last depth-2 concrete same-ID queue-head response-demux group readiness after generated queue-head multi-beat read-data.
147. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md`: audited multiple depth-2 read burst-last queue-head response-demux groups and selected the narrow implementation owner.
148. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md`: shipped generated multiple read burst-last depth-2 concrete same-ID queue-head response-demux groups.
149. `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md`: selected read-data-over-multiple-generated-queue-groups readiness after generated multi-group queue-head demux.
150. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md`: audited read-data coverage over multiple generated queue-head groups and selected multi-beat output-bank behavior.
151. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md`: shipped generated multi-group queue-head multi-beat read-data output-bank behavior.
152. `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md`: selected last-beat-only read-data over multiple generated queue-head groups as the next audit owner.
153. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md`: audited scalar last-beat read-data over multiple generated queue-head groups and selected the narrow implementation owner.
154. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md`: shipped generated multi-group queue-head scalar last-beat read-data capture.
155. `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md`: selected generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
156. `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md`: shipped generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
157. `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md`: selected runtime-validation multi-group queue-head scalar last-beat readiness audit.
158. `docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md`: selected first AXI-derived IAL2 implementation subset and pre-code contract.
159. `docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md`: code/test/docs/report owner map for the future AXI Valid-Ready IAL2 implementation.
160. `docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md`: first in-process AXI Valid-Ready IAL2 generator slice and report surface.
161. `docs/decisions/0016-ppif-is-first-public-ial2-container.md`: selects `.ppif` as the first public generic IAL2 file surface.
162. `docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md`: first public `.ppif` parser/CLI slice for one AXI Valid-Ready source object.
163. `docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md`: readiness map for future multi-channel `.ppif` Valid-Ready support.
164. `docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md`: selected future aggregate bundle contract for multi-channel `.ppif` Valid-Ready support.
165. `docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md`: shipped bounded multi-channel `.ppif` Valid-Ready bundle report/review-artifact behavior.
166. `docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md`: shipped aggregate semantic JSON for multi-channel `.ppif` bundles.
167. `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md`: selected aggregate wrapper/top HDL entry contract for multi-channel `.ppif` bundles.
168. `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md`: shipped aggregate wrapper/top HDL entry for the tracked multi-channel `.ppif` bundle.
169. `docs/PDF_EXTRACTION_WORKFLOW.md`: portable workflow for source-anchored PDF text, table, diagram, and image extraction.
170. `docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md`: generic IAL2 file-surface candidates and layered lowering decision.
171. `docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md`: IAL2 protocol-profile extension refinement.
172. `docs/decisions/0017-ppif-valid-ready-bundle-contract.md`: future multi-channel `.ppif` bundle contract decision.
173. `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md`: IAL contracts and mdBook stay backend-language-neutral for future Rust, Rust/Wasm, browser-capable JavaScript, and Dart/web parity.
174. `docs/FEATURE_BACKLOG.md`: pointer to the canonical mdBook feature backlog for deferred/not-fully-shipped user-visible work.
175. `CHANGES.md`: chronological technical changes.
176. `DEVELOPMENT_NOTES.md`: design rationale and decisions.
177. `MEMORY.md`: continuity/handoff state.
178. `LIVE_ACHIEVEMENT_STATUS.md`: latest completed roadmap-aligned slice.
179. `WARP.md`: repository-specific agent/development guidance.
180. `.agents/workflows/commit.md`: automation-oriented commit workflow description.

## Documentation index (all `.md` files in this repo)
- `README.md` — single entry point and navigation hub.
- `SESSION_BOOTSTRAP.md` — canonical first-task file for a new engineering session.
- `ROADMAP_STATUS.md` — canonical live roadmap/workstream status board.
- `ROADMAP_V2.md` — detailed post-`R0`..`R7` roadmap intent and sequencing.
- `docs/book/` — mdBook source for the progressive FSMGen book.
- `docs/BOOK_PLAN.md` — migration plan from the monolithic guide into the mdBook.
- `docs/USER_GUIDE.md` — broad live reference and command usage during the split.
- `docs/TASK_TREE_README.md` — setup guide for adopting the task-tree tracking workflow in another project.
- `docs/TASK_TREE.md` — repo-local task-tree workflow, active tree index, and PNT frontier rules.
- `docs/tasks/TEMPLATE.md` — reusable template for one top-level task tree.
- `docs/tasks/PROJECT-REMAINING-WORK-TASKTREE-OWNERSHIP.md` — completed roadmap-maintenance task tree that routed the 2026-06-05 remaining-work inventory to existing active owners or new broad owner trees.
- `docs/tasks/COMPOSITION-TYPE-BACKLOG-EXHAUSTION.md` — completed Composition/type backlog tree; shipped aggregate parameter/generic equality/inequality, closed the remaining Composition/type leaves behind exact prerequisites, and routed VHDL-dependent work through the completed backend/API frontier.
- `docs/tasks/ISF-REMAINING-BROAD-FRONTIER.md` — proposed broad `R14` ISF frontier owner tree for deferred ISF backlog directions not already owned by narrower active trees.
- `docs/tasks/BACKEND-API-VALIDATION-FRONTIER.md` — completed backend/API frontier owner tree for VHDL, external validation, ABC, structured generation, embedding API, and normalized export backlog through `.132`.
- `docs/tasks/ARCHITECTURE-DEBT-FRONTIER.md` — completed architecture-debt frontier owner tree; direct-backend structural internal declaration nets shipped, and ISF parser/lowerer extraction remains deferred behind future exact ownership.
- `docs/tasks/ISF-FRONTIER-SPAWN-AWAITANY-BOOK-RUNNABLE-EXAMPLES.md` — completed `R14` task tree that added runnable `lisp` book examples (in `13d`) for the shipped loop-contained spawn + `(await_all done)` and multi-pending `(await_any done)` + drain features (`t/1376` count 36 → 38); all repeat-body-activation frontier shapes now have copy-pasteable book examples.
- `docs/tasks/ISF-LOOP-AND-DEEPER-REPEAT-BODY-MULTI-PENDING-AWAITANY-LOWERING.md` — completed `R14` task tree (scheduler-frontier #6) that lifted the multi-pending `(await_any done)` + later `(await_all done)` deferral for loop-contained / deeper-nested repeats, locked by `t/1384`; **completes the repeat-body-activation nesting frontier** (cross-domain `do` is excluded — net-new CDC lowering).
- `docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-REPEAT-BODY-SPAWN-LOWERING.md` — completed `R14` task tree (scheduler-frontier #5) that enabled the basic `(spawn ...)` + same-body `(await_all done)`/single-pending `(await_any done)` subset inside a loop-contained or deeper-nested repeat (lowering + composition parity with the top-level repeat-body spawn); gate relaxation + drain-requirement rule + multi-pending-await_any deferral, locked by `t/1383`. Undrained/multi-pending spawn and cross-domain stay deferred; the full-HDL composition-wiring limitation is pre-existing (top-level too).
- `docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-GENERATED-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #4) that enabled a same-domain generated `(do child (params ...))` at deeper branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`) to lower + instantiate its child; a 3-part lowering change (collector recursion, param threading, validator relaxation) locked by `t/1382` with verified `.fsm`↔`_top` ordinal agreement, cross-domain and spawn deferred.
- `docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #3) that enabled a plain local `(do child)` at deeper branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`) to lower; a clean validator relaxation locked by `t/1381` (deeper-nested generated-do and spawn stay deferred).
- `docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-GENERATED-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #2) that enabled a same-domain generated `(do child (params ...))` inside a `(repeat ...)` directly in one `(while ...)`/`(until ...)` body to lower and instantiate its child in the `_top`; threaded the generated-child activation through the loop-body path + added loop-body discovery to the collector, locked by `t/1380` (cross-domain do and spawn stay deferred).
- `docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-LOCAL-DO-LOWERING.md` — completed `R14` task tree (scheduler-frontier #1) that enabled a plain local `(do child)` inside a `(repeat ...)` directly contained in one `(while ...)`/`(until ...)` body to lower; a validator-only gate relaxation locked by `t/1379` (spawn, generated-do, and deeper nesting stay deferred).
- `docs/tasks/ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.md` — completed `R14` task tree answering SPECFORGE's 2026-05-29 clarity request on the actor-local `(types)`↔`(enums)` relationship; documents that an enum name is not an auto type alias (co-declare `(type NAME (bits k))`), replies in `docs/SPECFORGE_FEEDBACK_RESPONSE.md`, and locks the rule with `t/1378`.
- `docs/tasks/R14-ASPECT-COVERAGE-AUDIT.md` — completed `R14` roadmap-maintenance task tree confirming every ISF backlog aspect is task-tree owned; registered `ISF-FULL-WIDTH-INFERENCE` (Proposed) and recorded IAL2 as a non-R14 horizon exploration.
- `docs/tasks/ISF-CROSS-DOMAIN-ACTIVATION-VIA-CROSSING.md` — active `R14` task tree (CDC lane) enabling a blocking cross-domain `(do)`/`(spawn)` through a new `(crossings (activation child (from SRC)(to DEST)))` kind that routes the activation start/done through two acknowledged-event CDC children; validator-acceptance and CDC routing ship together (a validator-only relaxation would emit an unsynchronized cross-clock handoff).
- `docs/tasks/ISF-FULL-WIDTH-INFERENCE.md` — completed `R14` task tree: activated, probed, and found no decidable multi-unknown extract/assemble width-inference sub-case beyond the shipped single-missing inference (2+-unknown is underdetermined → correctly fail-closed); recorded the fail-closed terminal and locked it with `t/1385`.
- `docs/tasks/BOOK-COOKBOOK-COMPOSITION-RUNNABLE.md` — completed `R14` task tree that upgraded cookbook composition recipes 3/4/5 from `text` schematics to verified inline-runnable `lisp` examples (C1/C2/C3 patterns proven by `t/101`); `t/1377` now gates 14 standalone `.fsm` fixtures.
- `docs/tasks/BOOK-NONISF-FSM-EXAMPLE-CORRECTNESS.md` — completed `R14` task tree that extended the example-correctness build gate from the ISF surface to the non-ISF `.fsm` (IAL0) book chapters; demoted 19 multi-file/schematic blocks to `text` and added `t/1377-book-fsm-example-generation-audit.t` (11 standalone `.fsm` fixtures gated).
- `docs/tasks/CI-CORPUS-SYSTEM-INCOMPLETE-SECTION-FIX.md` — completed CI-maintenance task tree that fixed the stale `t/corpus/system_incomplete_section.fsm` fixture.
- `docs/tasks/ISF-G8-HEADING-DENSITY.md` — completed `R14` task tree that added 4 sub-headings to the Pipeline section of 13-intent-scheduling.md.
- `docs/tasks/ISF-G4-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree that appended a dated status snapshot to 14-feature-backlog.md.
- `docs/tasks/ISF-G2-LOW-DENSITY-EXAMPLES.md` — completed `R14` task tree that added constants_demo (13a), bank_demo + dataop_demo (13e) examples.
- `docs/tasks/ISF-G5-13-INTENT-EXAMPLES.md` — completed `R14` task tree that added blinker + handshake_intent examples to 13-intent-scheduling.md.
- `docs/tasks/ISF-G6-13J-EXAMPLES.md` — completed `R14` task tree that added 3 complete actor examples (type_alias_demo, enum_demo, aggregate_storage_demo) to 13j.
- `docs/tasks/ISF-G7-13D-ACCEPT-PATH-EXAMPLES.md` — completed `R14` task tree that added 4 complete accept-path control-flow actor examples (when/switch+default/while/until) to 13d.
- `docs/tasks/ISF-DOWNSTREAM-CONTRACT-HANDOFF-SYNC.md` — completed `R14` task tree that propagated the recent diagnostic surface (cross-domain, sub-axis, loop-contained, deeper-nested, `t/1372-1376`) to `ISF_PUBLIC_INTERFACE_CONTRACT.md` and `SPECFORGE_FEEDBACK_RESPONSE.md`.
- `docs/tasks/ISF-BOOK-EXAMPLE-LOWERING-BUILD-GATE.md` — completed `R14` task tree that added `t/1376-isf-book-example-lowering-audit.t`. The test extracts every `lisp`-tagged book block and verifies it parses + lowers; failures block the test suite. 20 fixtures currently lower cleanly.
- `docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-G3.md` — completed `R14` task tree that added 4 representative examples for the remaining `remains deferred` template families and adopted the `lisp` vs `text` block-tag convention (`lisp` for accept-path fixtures only).
- `docs/tasks/ISF-COOKBOOK-WALKTHROUGHS.md` — completed `R14` task tree that added clause-by-clause walkthroughs to cookbook ISF recipes 9-13.
- `docs/tasks/ISF-BOOK-EXAMPLE-CORRECTNESS-FIX.md` — completed `R14` task tree that fixed 14 broken ISF examples identified in the example-correctness audit addendum. Re-audit reports 20 complete fixtures lower cleanly, 0 failures.
- `docs/tasks/ISF-COOKBOOK-RECIPES-G1.md` — completed `R14` task tree that addressed audit gap G1 by adding five ISF recipes to cookbook chapter 12 (basic actor, spawn, parameterized blocking do, rule trigger, repeat-body generated do).
- `docs/tasks/ISF-MDBOOK-COVERAGE-AUDIT.md` — completed `R14` doc-only task tree that published `docs/audits/ISF-MDBOOK-COVERAGE-AUDIT-2026-05-27.md` identifying eight gap categories (G1-G8) and a prioritized slice queue for closing the coverage gap between the codebase and the mdBook.
- `docs/tasks/ISF-DIAGNOSTIC-EXAMPLES-BOOK-COVERAGE.md` — completed `R14` task tree that added user-facing `.fsm` source examples to book chapters 13b (five examples) and 13d (two examples) for the seven targeted diagnostics shipped this session (cross-domain repeat-body do, four activation-override sub-axes, loop-contained, deeper-nested).
- `docs/tasks/ISF-LOOP-CONTAINED-AND-DEEPER-NESTED-DIAGNOSTIC-TRUTH-SYNC.md` — completed `R14` task tree that extended the targeted-diagnostic synchronization for the loop-contained and deeper-nested slices to book chapters `13b-transactions.md`, `13d-control-flow.md`, `13h-lowering-reference.md`, and `13k-isf-feature-support-matrix.md`.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-DIAGNOSTIC-PRECISION-REFRESH.md` — completed bootstrap architecture-maintenance task tree consolidating the import-tree note refresh for the four R14 diagnostic-precision slices; recorded `LoweringIR.pm` line count moved from `11144` to `11309`; topology unchanged.
- `docs/tasks/ISF-DEEPER-NESTED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that shipped a targeted `deeper-nested repeat-body <do|spawn> remains deferred` diagnostic for deeper-when and when-inside-switch cases at the two repeat-body subset entry points; broader deeper-nested implementation remains a future leaf; regression `t/1375-isf-deeper-nested-repeat-body-activation-diagnostic.t`.
- `docs/tasks/ISF-LOOP-CONTAINED-REPEAT-BODY-ACTIVATION-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that shipped a targeted `loop-contained repeat-body <do|spawn> remains deferred` diagnostic when a `(repeat ...)` with `do` or `spawn` body clauses is nested inside `(while ...)` or `(until ...)`; broader loop-contained implementation remains a future leaf; regression `t/1374-isf-loop-contained-repeat-body-activation-diagnostic.t`.
- `docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that split the aggregated static-timing override gate into four sub-axis-specific gates (repeat-count, wait-count, latency-bound, watchdog-limit) each with its own targeted diagnostic; regression `t/1373-isf-timing-param-sub-axis-diagnostic.t`.
- `docs/tasks/ISF-CROSS-DOMAIN-REPEAT-BODY-DO-DIAGNOSTIC-PRECISION.md` — completed `R14` task tree that shipped a targeted cross-domain repeat-body `do` diagnostic; broader cross-domain `do` implementation remains a separate future leaf of this tree; regression `t/1372-isf-cross-domain-repeat-body-do-diagnostic.t`.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTIVATION-OVERRIDE-WIDTH-GATE.md` — completed `R14` task tree that extended the activation-site parameter override-specialized default-preserving gate to transaction port widths (`(ports (input/output NAME (width PARAM)))`); regression `t/1371-isf-transaction-port-activation-override-width-gate.t`.
- `docs/tasks/ISF-DATA-OP-ACTIVATION-OVERRIDE-WIDTH-GATE.md` — completed `R14` task tree that extended the activation-site parameter override-specialized default-preserving gate from timing parameters (wait, repeat, latency, watchdog, contract) to data-operation width parameters (`shift_left`, `shift_right`, `assemble`, `extract`); regression `t/1370-isf-data-op-activation-override-width-gate.t`.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the same-domain generated `(do worker (params ...) (bind ...) (domain core))` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets, completing the BEFORE-POST-DO-AWAITANY missing-drain matrix across the five generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the bound generated `(do worker (params ...) (bind ...))` before post-do multi-pending `(await_any done)` without final drain shape on the when-body subset (switch already existed).
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the static-parameter generated `(do worker (params ...))` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the plain generated-child `(do worker)` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-LOCALDO-BEFORE-POST-DO-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the local `(do child)` before post-do multi-pending `(await_any done)` without final drain shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the static-parameter generated `(do worker (params ...))` prior-`await_any` plus spawn-after-do without final drain shape on the switch-branch subset, completing the SPAWN-AFTER-DO without-drain matrix across the five generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the plain generated-child `(do worker)` prior-`await_any` plus spawn-after-do without final drain shape on the switch-branch subset.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the bound generated `(do child (params ...) (bind ...))` prior-`await_any` plus second post-spawn `await_any` shape on both branch-contained subsets, completing the SECOND-AWAITANY missing-drain matrix across the five generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the static-parameter generated `(do child (params ...))` prior-`await_any` plus second post-spawn `await_any` shape on both branch-contained subsets.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the plain generated-child `(do child)` prior-`await_any` plus second post-spawn `await_any` shape on the switch-branch subset.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SECOND-AWAITANY-MISSING-DRAIN-COVERAGE.md` — completed `R14` task tree for defensive missing-drain regression coverage of the same-domain generated `do` prior-`await_any` plus second post-spawn `await_any` shape.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-DOMAIN-SECOND-AWAITANY-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after the R14 same-domain generated-do prior-`await_any` plus second post-spawn `await_any` repeat-body slice.
- `docs/tasks/ISF-REPEAT-GENDO-PRIOR-AWAITANY-SECOND-AWAITANY-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for prior-observation second post-spawn `await_any` mdBook and `t/1307` audit wording across the local-do plus four generated-do families.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained same-domain generated `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-BOUND-SECOND-AWAITANY-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after the R14 static-parameter and bound generated-do prior-`await_any` plus second post-spawn `await_any` repeat-body slices.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained bound generated `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained static-parameter generated `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-GENDO-SECOND-AWAITANY-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after the R14 generated-child second-`await_any` slice.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained plain generated-child `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-R14-REPEAT-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after recent R14 repeat-body child-activation slices.
- `docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-SECOND-AWAITANY.md` — completed `R14` task tree for branch-contained local `do` after prior multi-pending `await_any`, later generated `spawn`, second post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained same-domain generated `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained bound generated `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained static-parameter generated `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-PRIOR-AWAITANY-SPAWN-AFTER-DO-TRUTH-SYNC.md` — completed `R14` documentation/audit truth-sync task tree for prior-`await_any` spawn-after-do repeat wording.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained plain generated-child `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-LOCALDO-PRIOR-AWAITANY-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained local `do` after prior multi-pending `await_any`, later generated `spawn`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained same-domain generated `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained bound generated `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained static-parameter generated `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained local `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO-POST-AWAITANY.md` — completed `R14` task tree for branch-contained plain generated-child `do` followed by generated `spawn`, post-spawn `await_any`, and same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained same-domain generated `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-BOUND-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained bound generated `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PARAM-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained static-parameter generated `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-PLAIN-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained plain generated-child `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-LOCALDO-SPAWN-AFTER-DO.md` — completed `R14` task tree for branch-contained local `do` followed by generated `spawn` before same-body drain.
- `docs/tasks/ISF-REPEAT-GENDO-DOMAIN-POST-AWAITANY.md` — completed `R14` task tree for same-domain generated `do` before post-do multi-pending `await_any` in branch-contained nested repeats.
- `docs/tasks/ISF-MDBOOK-STATIC-ZERO-REPEAT-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for mdBook static-zero repeat child-activation wording.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-STATIC-ZERO-REPEAT-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note after static-zero repeat pruning.
- `docs/tasks/ISF-STATIC-ZERO-REPEAT-SPECIALIZED-CHILD-PRUNE.md` — completed `R14` task tree for bounded static-zero repeat specialized child-activation artifact pruning.
- `docs/tasks/ISF-STATIC-ZERO-REPEAT-CHILD-PRUNE.md` — completed `R14` task tree for bounded static-zero repeat child-activation artifact pruning.
- `docs/tasks/BIN-FSMGEN-IMPORT-TREE-BOOTSTRAP-REFRESH.md` — completed bootstrap architecture-maintenance task tree for refreshing the `bin/fsmgen` import-tree note.
- `docs/tasks/ISF-STATIC-ZERO-REPEAT-NOOP.md` — completed `R14` task tree for bounded static zero-count repeat no-op lowering.
- `docs/tasks/ROADMAP-R14-REPEAT-ZERO-STATUS-TRUTH-SYNC.md` — completed `R14` roadmap maintenance task tree for repeat zero status truth sync.
- `docs/tasks/NO-RESET-SCHEDULED-FSM-HDL.md` — completed `R14` task tree for reset-free scheduled `.fsm` HDL support.
- `docs/tasks/ISF-CDC-NO-RESET-FIXTURE.md` — completed `R14` task tree for no-reset acknowledged-event CDC fixture coverage.
- `docs/tasks/ISF-DATA-OP-WIDTH-BACKLOG-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for data-operation width backlog wording.
- `docs/tasks/ISF-SCHEDULE-REPORT-STORAGE-ROLES.md` — completed `R14` task tree for additive schedule-report storage-role metadata.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-TRANSACTION-PARAM-ZERO.md` — completed `R14` task tree for same-transaction-parameter-zero runtime divisor safety.
- `docs/tasks/ISF-STATIC-TIMING-FAIL-CLOSED-LIST-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for static timing fail-closed checklist wording.
- `docs/tasks/ISF-TIMING-PARAM-ACTIVATION-OVERRIDE-GATES.md` — completed `R14` task tree for generated child static timing parameter activation override gates.
- `docs/tasks/ISF-WATCHDOG-TRANSACTION-PARAM-LIMITS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in top-level await-local watchdog limits.
- `docs/tasks/ISF-LATENCY-TRANSACTION-PARAM-BOUNDS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in latency bounds.
- `docs/tasks/ISF-WAIT-TRANSACTION-PARAM-COUNTS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in wait counts.
- `docs/tasks/R11-TOP-BOUNDARY-CONVENTION-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the top-boundary convention/connect-by-name frontier.
- `docs/tasks/R11-PORTABLE-TYPE-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the portable synthesizable-type frontier.
- `docs/tasks/R11-REUSABLE-MODULE-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the reusable standalone-DT/module-library frontier.
- `docs/tasks/R11-SHARED-DATAPATH-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the shared-datapath contract frontier.
- `docs/tasks/R11-PARAMETER-GENERIC-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the semantic parameter/generic frontier.
- `docs/tasks/R11-RTLIF-INTERFACE-SOURCE-DIRECTION.md` — completed `R11` task tree for deciding the `.rtlif` interface-source direction.
- `docs/tasks/R11-COMPOSITION-CONTRACT-FRONTIER-AUDIT.md` — completed `R11` task tree for auditing the next composition-contract frontier.
- `docs/tasks/R10-DIAGNOSTIC-PROVENANCE-EXIT-AUDIT.md` — completed `R10` task tree for auditing the diagnostic/provenance exit frontier.
- `docs/tasks/R10-D-INPUT-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md` — completed `R10` task tree for cleaning D-input self-dependency diagnostic implementation leakage.
- `docs/tasks/R10-SELF-DEPENDENCY-DIAGNOSTIC-CLEANUP.md` — completed `R10` task tree for cleaning direct self-dependency diagnostic stack leakage.
- `docs/tasks/R10-CLI-QUIET-BANNER-CLEANUP.md` — completed `R10` task tree for aligning quiet CLI banner behavior with diagnostics.
- `docs/tasks/R10-DIAGNOSTIC-PROVENANCE-FRONTIER-AUDIT.md` — completed `R10` task tree for auditing and cleaning up the next source-provenance and diagnostic frontier.
- `docs/tasks/R9-STRICT-MODE-FRONTIER-AUDIT.md` — completed `R9` task tree for auditing the strict-mode support-tier frontier.
- `docs/tasks/R8-LANGUAGE-CONTRACT-EXIT-AUDIT.md` — completed `R8` task tree for auditing the language-contract exit criteria.
- `docs/tasks/RICHER-AGGREGATE-OPERATORS.md` — completed aggregate-types task tree for richer aggregate operator widening.
- `docs/tasks/R8-LANGUAGE-SURFACE-GRAY-ZONE-AUDIT.md` — completed `R8` task tree for resolving the next parser-accepted language-surface gray zone.
- `docs/tasks/BACKEND-OWNED-STRUCT-RECORD-DEFAULT-LOWERING.md` — completed aggregate-types task tree for backend-owned structured aggregate lowering audit.
- `docs/tasks/AGGREGATE-AUTOGROWTH-FROM-USAGE.md` — completed aggregate-types task tree for bounded automatic aggregate growth from usage.
- `docs/tasks/DYNAMIC-DIVISOR-SAFETY-FRONTIER.md` — completed language-ergonomics task tree for direct runtime literal-zero divisor rejection.
- `docs/tasks/INFERENCE-FIRST-SCALAR-AUTHORING.md` — completed language-ergonomics task tree for the first inference-first scalar authoring slice.
- `docs/tasks/COMPOSITION-WIRING-LISPISH.md` — completed `R11` task tree for canonical Lisp-ish `?wiring` list forms.
- `docs/tasks/R8-STRICT-SUPPORT-TIER-CUTS.md` — completed `R8` task tree for the latest strict-mode support-tier cut.
- `docs/tasks/FEATURE-BACKLOG-OWNER-COVERAGE-SYNC.md` — completed roadmap-maintenance task tree for broad feature-backlog owner coverage synchronization.
- `docs/tasks/TASK-TREE-COMMIT-EVIDENCE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for synchronizing stale completed task-tree commit evidence.
- `docs/tasks/TASK-TREE-THIS-COMMIT-EVIDENCE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for synchronizing stale `this commit` completed task-tree evidence.
- `docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNTS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in repeat counts.
- `docs/tasks/ROADMAP-R14-ACTIVE-LANE-STATUS-SYNC.md` — completed `R14` roadmap-maintenance task tree for detailed active-lane roadmap status truth sync.
- `docs/tasks/ISF-GENERATED-DO-BINDING-TIMING-COVERAGE.md` — completed `R14` task tree for generated blocking `do` binding timing regression coverage.
- `docs/tasks/ROADMAP-R14-BINDING-TIMING-HISTORICAL-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for binding timing history truth sync.
- `docs/tasks/ROADMAP-R14-RULE-TRIGGER-OUTPUT-HISTORY-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for rule-trigger output-binding history truth sync.
- `docs/tasks/ISF-DIRECT-ON-PARAM-DIAGNOSTIC.md` — completed `R14` task tree for direct `(on ... (params ...))` diagnostic hardening.
- `docs/tasks/ISF-CONFLICT-RESOLUTION.md` — completed `R14` task tree for ISF same-cycle conflict semantics.
- `docs/tasks/ISF-TRANSACTION-OVER-RULE-PRIORITY.md` — completed `R14` task tree for covered transaction-over-rule same-target priority.
- `docs/tasks/ISF-TRANSACTION-OVER-RULE-DOC-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for stale transaction-over-rule priority mdBook wording.
- `docs/tasks/ISF-COMPOSITION-INSTANTIATION.md` — completed `R14` task tree for generated child instantiation and spawn parameter binding.
- `docs/tasks/ISF-STORAGE-PORT-ROUND-ROBIN.md` — completed `R14` task tree for bounded storage-port round-robin resource arbitration.
- `docs/tasks/ISF-OUTPUT-BUNDLE-ROUND-ROBIN.md` — completed `R14` task tree for bounded output-bundle round-robin resource arbitration.
- `docs/tasks/ISF-TRANSACTION-START-ROUND-ROBIN.md` — completed `R14` task tree for bounded transaction-start round-robin resource arbitration.
- `docs/tasks/ISF-ROUND-ROBIN-RESOURCE-ARBITRATION.md` — completed `R14` task tree for bounded round-robin resource arbitration.
- `docs/tasks/ISF-OUTPUT-BUNDLE-RESOURCE-PRIORITY.md` — completed `R14` task tree for output-bundle priority resource enforcement.
- `docs/tasks/ISF-STORAGE-PORT-RESOURCE-PRIORITY.md` — completed `R14` task tree for storage-port priority resource enforcement.
- `docs/tasks/ISF-STORAGE-PORT-MEMBER-TRUTH-SYNC.md` — completed `R14` task tree for storage-port member documentation truth sync.
- `docs/tasks/ISF-RESOURCE-PRIORITY.md` — completed `R14` task tree for resource arbitration and priority enforcement.
- `docs/tasks/ISF-RESOURCE-CATALOG.md` — completed `R14` task tree for the shareable resource kind registry.
- `docs/tasks/ISF-RULE-ACTIONS.md` — completed `R14` task tree for expression-valued rule assignments.
- `docs/tasks/ISF-STAGES-CONTRACTS.md` — completed `R14` task tree for transaction stages and temporal contracts.
- `docs/tasks/ISF-DATA-WIDTHS.md` — completed `R14` task tree for data-operation width inference.
- `docs/tasks/ISF-DATA-OP-TRANSACTION-PARAM-WIDTHS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in data-operation width evidence.
- `docs/tasks/ISF-ASSEMBLE-STATIC-PART-WIDTHS.md` — completed `R14` task tree for optional `assemble` part-width evidence.
- `docs/tasks/ISF-DATA-OP-STATIC-WIDTH-SOURCES.md` — completed `R14` task tree for actor-local static value sources in data-operation width evidence.
- `docs/tasks/ISF-SHIFT-LEFT-EXPLICIT-WIDTH.md` — completed `R14` task tree for optional `shift_left` width evidence.
- `docs/tasks/ISF-SCHEDULE-REPORTS.md` — completed `R14` task tree for schedule-report storage classes and schema stabilization.
- `docs/tasks/ISF-FIXTURE-COVERAGE.md` — completed `R14` task tree for realistic fixtures and strict-mode coverage.
- `docs/tasks/ISF-BURST-FIXTURE-PROMOTION.md` — completed `R14` task tree for burst-reader fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-UART-FIXTURE-PROMOTION.md` — completed `R14` task tree for UART-like fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-PHASE-FIXTURE-PROMOTION.md` — completed `R14` task tree for phase fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-SWITCH-FIXTURE-PROMOTION.md` — completed `R14` task tree for switch fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-WHEN-FIXTURE-PROMOTION.md` — completed `R14` task tree for `when` fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-GENERATED-COMPOSITION-FIXTURE-PROMOTION.md` — completed `R14` task tree for generated-composition fixture strict/outdir/HDL promotion.
- `docs/tasks/ISF-RULE-RESOURCE-FIXTURE-PROMOTION.md` — completed `R14` task tree for rule/resource arbitration fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-STAGE-CONTRACT-FIXTURE-PROMOTION.md` — completed `R14` task tree for stage/contract fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-FIFO-CONTROLLER-FIXTURE-PROMOTION.md` — completed `R14` task tree for FIFO controller fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-FIFO-DATAPATH-FIXTURE-PROMOTION.md` — completed `R14` task tree for FIFO datapath bank-access fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-FIFO-LIBRARY-FIXTURE-PROMOTION.md` — completed `R14` task tree for FIFO reusable-library fixture schedule/strict/outdir/HDL promotion.
- `docs/tasks/ISF-I2C-FIXTURE-PROMOTION.md` — completed `R14` task tree for I2C-like fixture schedule/strict/HDL promotion.
- `docs/tasks/ISF-COMPATIBILITY-SURFACE.md` — completed `R14` task tree for legacy handshake and removed assign compatibility policy.
- `docs/tasks/ISF-PORT-BINDING.md` — completed `R14` task tree for transaction ports and actor pin access.
- `docs/tasks/ISF-RULE-TRIGGER-GENERATED-OUTPUT-BINDINGS.md` — completed `R14` task tree for generated-child rule-trigger output bindings.
- `docs/tasks/ISF-CONTROL-FLOW.md` — completed `R14` task tree for transaction-local waits and dynamic loops.
- `docs/tasks/ISF-WAIT-ZERO.md` — completed `R14` task tree for zero-count transaction wait semantics.
- `docs/tasks/ISF-DYNAMIC-WAIT.md` — completed `R14` task tree for non-literal transaction wait counts.
- `docs/tasks/ISF-PARAM-WAIT-COUNTS.md` — completed `R14` task tree for actor-parameter-backed static transaction wait counts.
- `docs/tasks/ISF-WAIT-PACKAGE-CONSTANT-COUNTS.md` — completed `R14` task tree for qualified package scalar constants in static transaction wait counts.
- `docs/tasks/ISF-DYNAMIC-WAIT-COMPLETE-SAMPLE.md` — completed `R14` task tree for completion zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SET-SAMPLE.md` — completed `R14` task tree for independent setter zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-UPDATE-SAMPLE-COVERAGE.md` — completed `R14` task tree for explicit independent update zero-bypass coverage.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-SHIFT-SAMPLE.md` — completed `R14` task tree for independent shift zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-ASSEMBLE-SAMPLE.md` — completed `R14` task tree for independent assemble zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-EXTRACT-SAMPLE.md` — completed `R14` task tree for independent extract zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-LOAD-SAMPLE.md` — completed `R14` task tree for independent bank-load zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-INDEPENDENT-BANK-STORE-SAMPLE.md` — completed `R14` task tree for independent bank-store zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-CONSECUTIVE-SAMPLE.md` — completed `R14` task tree for carrying pending samples across consecutive runtime wait zero-count links.
- `docs/tasks/ISF-DYNAMIC-WAIT-STAGE-SAMPLE.md` — completed `R14` task tree for stage zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-CONTRACT-SAMPLE.md` — completed `R14` task tree for contract arm zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-LOOP-CHECK-SAMPLE.md` — completed `R14` task tree for loop decision zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-BANK-PREDECESSOR.md` — completed `R14` task tree for dynamic waits after bank load/store predecessors.
- `docs/tasks/ISF-DYNAMIC-WAIT-SYNC-SAMPLE.md` — completed `R14` task tree for await_all/await_any zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-SPAWN-SAMPLE.md` — completed `R14` task tree for spawn zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-DYNAMIC-WAIT-PHASE-SAMPLE.md` — completed `R14` task tree for transaction phase zero-bypass pending-sample dynamic waits.
- `docs/tasks/ISF-SPAWN-IN-REPEAT.md` — completed `R14` task tree for static child spawn inside repeat bodies.
- `docs/tasks/ISF-REPEAT-SPAWN-PARAMS.md` — completed `R14` task tree for repeat-body spawn parameter overrides.
- `docs/tasks/ISF-REPEAT-BODY-CHILD-ACTIVATION.md` — completed `R14` task tree for repeat-body child activation widening.
- `docs/tasks/ISF-ACTOR-NETWORK-ORCHESTRATION.md` — completed `R14` task tree for static ISF Actor Transfer Level actor-network orchestration.
- `docs/tasks/ISF-CONTRACT-ACTOR-PARAM-WINDOWS.md` — completed `R14` task tree for actor-parameter-backed temporal contract windows.
- `docs/tasks/ISF-CONTRACT-PACKAGE-CONSTANT-WINDOWS.md` — completed `R14` task tree for qualified package scalar constants in temporal contract windows.
- `docs/tasks/ISF-CONTRACT-TRANSACTION-PARAM-WINDOWS.md` — completed `R14` task tree for generated child same-transaction scalar parameter defaults in temporal contract windows.
- `docs/tasks/ISF-CONTRACT-DIRECT-TRANSACTION-PARAM-WINDOWS.md` — completed `R14` task tree for direct transaction same-transaction scalar parameter defaults in temporal contract windows.
- `docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-WINDOWS.md` — completed `R14` task tree for activation-site override diagnostics on generated child temporal contract-window parameters.
- `docs/tasks/ROADMAP-R14-ACTIVATION-OVERRIDE-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for activation override diagnostic coverage synchronization.
- `docs/tasks/ROADMAP-R14-LATEST-SLICE-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for latest R14 slice roadmap truth synchronization.
- `docs/tasks/ROADMAP-R14-PORT-BINDING-HISTORICAL-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for historical transaction-port binding recovery-note truth synchronization.
- `docs/tasks/ISF-RULE-TRIGGER-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md` — completed `R14` task tree for duplicate generated rule-trigger output actor-target diagnostics.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-REPORT-WORDING-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for transaction-port binding report non-claim wording.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-DUPLICATE-OUTPUT-TARGET-DIAGNOSTIC.md` — completed `R14` task tree for duplicate output-binding actor-target diagnostics.
- `docs/tasks/ISF-RULE-TRIGGER-LOCAL-OUTPUT-BINDING-DIAGNOSTIC.md` — completed `R14` task tree for direct/local rule-trigger output-binding diagnostic hardening.
- `docs/tasks/ISF-AUTHORED-TIMING-METADATA-DOC-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for authored binding timing metadata wording.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-REQUEST-METADATA.md` — completed `R14` task tree for authored transaction-port binding timing request report metadata.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-METADATA.md` — completed `R14` task tree for bounded transaction-port binding timing report metadata.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-TIMING-SYNTAX.md` — completed `R14` task tree for explicit transaction input-binding timing syntax.
- `docs/tasks/ISF-CONTRACT-ACTIVATION-OVERRIDE-SAME-VALUE.md` — completed `R14` task tree for same-value activation-site overrides on generated child temporal contract-window parameters.
- `docs/tasks/ISF-LATENCY-ACTOR-CONSTANT-BOUNDS.md` — completed `R14` task tree for positive actor constants in transaction latency bounds.
- `docs/tasks/ISF-LATENCY-ACTOR-PARAM-BOUNDS.md` — completed `R14` task tree for actor-parameter-backed transaction latency bounds.
- `docs/tasks/ISF-LATENCY-PACKAGE-CONSTANT-BOUNDS.md` — completed `R14` task tree for qualified package scalar constants in transaction latency bounds.
- `docs/tasks/ISF-INTERFACE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor interface port widths.
- `docs/tasks/ISF-INTERFACE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor interface port widths.
- `docs/tasks/ISF-INTERFACE-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in actor interface port widths.
- `docs/tasks/ISF-SCALAR-STORAGE-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in actor-owned scalar storage widths.
- `docs/tasks/ISF-SCALAR-STORAGE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned scalar storage widths.
- `docs/tasks/ISF-SCALAR-STORAGE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned scalar storage widths.
- `docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned bank storage widths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-CONSTANT-DEPTHS.md` — completed `R14` task tree for actor-constant-backed actor-owned bank storage depths.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor-constant-backed transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-ACTOR-PARAM-WIDTHS.md` — completed `R14` task tree for actor-parameter-backed transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-TRANSACTION-PARAM-WIDTHS.md` — completed `R14` task tree for same-transaction scalar parameter defaults in transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in transaction-local port widths.
- `docs/tasks/ISF-TRANSACTION-PORT-BINDING-ENDPOINT-KINDS.md` — completed `R14` task tree for transaction-port binding endpoint-kind schedule-report metadata.
- `docs/tasks/ISF-TRANSACTION-PORT-PACKAGE-WIDTH-BOOK-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for stale mdBook transaction-port package-constant width wording.
- `docs/tasks/ISF-DATA-OP-PACKAGE-CONSTANT-WIDTHS.md` — completed `R14` task tree for qualified package scalar constants in explicit data-operation width evidence.
- `docs/tasks/ISF-BANK-STORAGE-PACKAGE-CONSTANT-DEPTHS.md` — completed `R14` task tree for qualified package scalar constants in actor-owned bank storage depths.
- `docs/tasks/ISF-BANK-STORAGE-ACTOR-PARAM-DEPTHS.md` — completed `R14` task tree for actor-parameter-backed actor-owned bank storage depths.
- `docs/tasks/ISF-WATCHDOG-ACTOR-CONSTANT-LIMITS.md` — completed `R14` task tree for positive actor constants in watchdog limits.
- `docs/tasks/ISF-WATCHDOG-ACTOR-PARAM-LIMITS.md` — completed `R14` task tree for actor-parameter-backed watchdog limits.
- `docs/tasks/ISF-WATCHDOG-PACKAGE-CONSTANT-LIMITS.md` — completed `R14` task tree for qualified package scalar constants in watchdog limits.
- `docs/tasks/ISF-REPEAT-ACTOR-CONSTANT-WIDTHS.md` — completed `R14` task tree for actor constants as repeat counter width evidence.
- `docs/tasks/ISF-REPEAT-ACTOR-PARAM-COUNTS.md` — completed `R14` task tree for actor-parameter-backed repeat counts.
- `docs/tasks/ISF-REPEAT-PACKAGE-CONSTANT-COUNTS.md` — completed `R14` task tree for qualified package scalar constants in static transaction repeat counts.
- `docs/tasks/ISF-REPEAT-STATIC-ZERO-COUNT-POLICY.md` — completed `R14` task tree for a bounded static zero-count repeat policy.
- `docs/tasks/ISF-REPEAT-RUNTIME-ZERO-COUNT-POLICY.md` — completed `R14` task tree for runtime scalar repeat zero-count skip policy.
- `docs/tasks/ISF-REPEAT-COUNT-SOURCE-BOUNDARY.md` — completed `R14` task tree for the accepted repeat count source boundary.
- `docs/tasks/ISF-BACKLOG-OWNER-TRUTH-SYNC.md` — completed `R14` task tree for mdBook backlog task-tree owner truth synchronization.
- `docs/tasks/ISF-REPEAT-TRANSACTION-PARAM-COUNT-DIAGNOSTIC.md` — completed `R14` task tree for targeted transaction-parameter repeat count diagnostics.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-DRIVE-COVERAGE.md` — completed `R14` task tree for dynamic-divisor drive-expression coverage hardening.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-CONTROL-BANK-COVERAGE.md` — completed `R14` task tree for dynamic-divisor control and bank expression coverage hardening.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-ACTOR-PARAM-ZERO.md` — completed `R14` task tree for actor-parameter-zero dynamic-divisor safety.
- `docs/tasks/ROADMAP-R14-NEXT-PNT-TEXT-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for synchronizing stale next-PNT roadmap wording.
- `docs/tasks/CI-STRICT-WIRING-DIAGNOSTIC-REPAIR.md` — completed project-operations task tree for repairing the hosted strict wiring and direct LHS diagnostic regression.
- `docs/tasks/CI-FEATURE-BACKLOG-STATUS-AUDIT.md` — completed project-operations task tree for repairing a stale feature-backlog status audit expectation.
- `docs/tasks/ISF-ATL-FRONTIER-TRUTH-SYNC.md` — completed `R14` roadmap-maintenance task tree for synchronizing stale closed ATL frontier wording.
- `docs/tasks/ISF-ATL-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing stale ATL backlog prose.
- `docs/tasks/ISF-ATL-COMPACT-INSTANCE-ALIAS.md` — completed `R14` task tree for the compact ATL static instance alias.
- `docs/tasks/ISF-ATL-COMPACT-GROUP-ALIAS.md` — completed `R14` task tree for the compact ATL concurrent group alias.
- `docs/tasks/ISF-ATL-MULTI-EVENT-WAIT.md` — completed `R14` task tree for bounded ATL transaction-body multi-event waits.
- `docs/tasks/ISF-ATL-PIN-MIXED-ROUTE-SETS.md` — completed `R14` task tree for bounded generated-child ATL top-level pin mixed scalar/vector route sets.
- `docs/tasks/ISF-ATL-PIN-VECTOR-MULTI-ROUTE.md` — completed `R14` task tree for bounded generated-child ATL top-level pin exact-width vector multi-route sets.
- `docs/tasks/ISF-ATL-PIN-ROUTE-VECTOR-WIDTH.md` — completed `R14` task tree for bounded generated-child ATL top-level pin exact-width vector routes.
- `docs/tasks/ISF-ATL-ACTOR-ROUTE-VECTOR-WIDTH.md` — completed `R14` task tree for bounded generated-child ATL actor-to-actor exact-width vector routes.
- `docs/tasks/ISF-ATL-ROUTE-DRIVE-ARGUMENT-BOUNDARY.md` — completed `R14` task tree for shared ATL route-drive formal/actual-argument boundary hardening.
- `docs/tasks/ISF-ATL-PIN-EGRESS-MULTI-ROUTE.md` — completed `R14` task tree for bounded generated-child ATL resolved-child pin-egress multi-route scalar movement.
- `docs/tasks/ISF-ATL-PIN-INGRESS-MULTI-ROUTE.md` — completed `R14` task tree for bounded generated-child ATL top-level pin-ingress multi-route scalar movement.
- `docs/tasks/ISF-ATL-MULTI-ROUTE-DATA-MOVEMENT.md` — completed `R14` task tree for bounded generated-child ATL multi-route scalar data movement.
- `docs/tasks/ROADMAP-R14-FRONTIER-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for removing stale R14 frontier text after ATL multi-route closure.
- `docs/tasks/ISF-ATL-DOC-STATUS-TRUTH-SYNC.md` — completed `R14` task tree for ATL book/proposal/status truth synchronization after tree closure.
- `docs/tasks/ISF-SPECFORGE-REPORTED-STAGE-CONTRACT-BUGS.md` — completed `R14` task tree for SPECFORGE-reported ISF stage/contract conformance bugs.
- `docs/tasks/ISF-ACTIVATION-BIND-EXPRESSIONS.md` — completed `R14` task tree for expression-valued activation input bindings.
- `docs/tasks/ISF-SETTER-SYNTAX.md` — completed `R14` task tree for scalar setter syntax shared by rules and transactions.
- `docs/tasks/ISF-TRANSACTION-ACTIVATION.md` — completed `R14` task tree for task-like transaction activation and parameter overrides.
- `docs/tasks/ISF-ACTIVATION-PARAM-OVERRIDES.md` — completed `R14` task tree for remaining rule-trigger and direct-activation parameter overrides.
- `docs/tasks/ISF-ACTIVATION-PARAM-ACTOR-PARAMS.md` — completed `R14` task tree for actor-local scalar parameter defaults as generated activation parameter override values.
- `docs/tasks/ISF-ACTIVATION-PARAM-VALUE-DOMAIN-DOC-TRUTH-SYNC.md` — completed `R14` documentation truth-sync task tree for activation parameter value-domain prose.
- `docs/tasks/ISF-LIBRARY-USE-ACTOR-STATIC-VALUES.md` — completed `R14` task tree for actor static values in reusable-library use-site parameter overrides.
- `docs/tasks/ISF-LIBRARY-USE-PACKAGE-CONSTANTS.md` — completed `R14` task tree for package scalar constants in reusable-library use-site parameter overrides.
- `docs/tasks/ISF-ACTOR-PARAM-ACTOR-CONSTANT-DEFAULTS.md` — completed `R14` task tree for actor constants in actor parameter defaults.
- `docs/tasks/ISF-ACTOR-PARAM-ACTOR-PARAM-DEFAULTS.md` — completed `R14` task tree for ordered actor-parameter-backed actor parameter defaults.
- `docs/tasks/ISF-TRANSACTION-PARAM-ACTOR-STATIC-DEFAULTS.md` — completed `R14` task tree for actor-static generated-child transaction parameter defaults.
- `docs/tasks/ISF-TRANSACTION-PARAM-DEPENDENCY-DEFAULTS.md` — completed `R14` task tree for earlier-scalar generated-child transaction parameter dependency defaults.
- `docs/tasks/ISF-TRANSACTION-PARAM-PACKAGE-CONSTANT-DEFAULTS.md` — completed `R14` task tree for package scalar constants in generated-child transaction parameter defaults.
- `docs/tasks/ISF-ACTIVATION-PARAM-PACKAGE-CONSTANTS.md` — completed `R14` task tree for package scalar constants in generated activation parameter overrides.
- `docs/tasks/ROADMAP-CURRENT-ACTIVE-LANE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for synchronizing stale current-active-lane roadmap wording.
- `docs/tasks/ISF-ACTOR-PARAM-PACKAGE-CONSTANT-DEFAULTS.md` — completed `R14` task tree for package scalar constants in actor parameter defaults.
- `docs/tasks/ISF-LIBRARY-SYSTEM-BINDINGS.md` — completed `R14` task tree for reusable-library clock/reset name remapping.
- `docs/tasks/ISF-STORAGE-VAR-ALIASES.md` — completed `R14` task tree for actor-owned scalar storage variable aliases.
- `docs/tasks/ISF-STORAGE-VAR-SURFACE.md` — completed `R14` task tree for the narrowed actor-owned scalar storage source vocabulary.
- `docs/tasks/ISF-PUBLIC-CONTRACT-SYNC.md` — completed `R14` task tree for ISF spec, book, manifest, and contract synchronization.
- `docs/tasks/ISF-CLOCK-DOMAINS.md` — completed `R14` task tree for multi-clock and CDC semantics.
- `docs/tasks/ISF-TIMING-CONVENTIONS.md` — completed `R14` task tree for default actor timing conventions.
- `docs/tasks/ISF-DOWNSTREAM-INTEGRATION-SPEC.md` — completed `R14` task tree for the self-contained `.isf` downstream integration handoff.
- `docs/tasks/ISF-LIVE-BOOK-DOCUMENT-PATHS.md` — completed `R14` task tree for advertising complete ISF mdBook live-document paths through the public contract.
- `docs/tasks/ISF-REPEAT-BODY-DOC-TRUTH-SYNC.md` — completed `R14` task tree for repeat-body shipped-subset documentation truth synchronization.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX.md` — completed `R14` task tree for the book-facing ISF shipped feature matrix.
- `docs/tasks/ISF-RULE-GUARD-DOC-TRUTH-SYNC.md` — completed `R14` task tree for standalone enum/aggregate rule-guard backlog truth synchronization.
- `docs/tasks/ISF-LOOP-BODY-DOC-TRUTH-SYNC.md` — completed `R14` task tree for loop-body shipped-clause documentation truth synchronization.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-COVERAGE-SYNC.md` — completed `R14` task tree for shipped stage/contract coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-PORT-BINDING-SYNC.md` — completed `R14` task tree for transaction port/binding coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-REPORT-METADATA-SYNC.md` — completed `R14` task tree for report metadata coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-ISSUE-BUNDLE-SYNC.md` — completed `R14` task tree for downstream issue-bundle coverage in the ISF book feature matrix.
- `docs/tasks/ISF-MDBOOK-FEATURE-MATRIX-CLI-EXAMPLES-SYNC.md` — completed `R14` task tree for `.isf` CLI example coverage in the ISF book feature matrix.
- `docs/tasks/ISF-ASSEMBLE-SINGLE-PART-WIDTH-INFERENCE.md` — completed `R14` task tree for exactly-one-missing-part `assemble` width inference.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-CONSTANTS.md` — completed `R14` task tree for actor-constant zero divisor rejection in shipped ISF runtime expression contexts.
- `docs/tasks/ISF-DYNAMIC-DIVISOR-SAFETY.md` — completed `R14` task tree for literal-zero divisor rejection in shipped ISF runtime expression contexts.
- `docs/tasks/ISF-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing stale ISF feature-backlog status text.
- `docs/tasks/ISF-RESOURCE-BACKLOG-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing resource arbitration and storage-role backlog status text.
- `docs/tasks/ISF-FEATURE-BACKLOG-STATUS-SYNC.md` — completed `R14` task tree for synchronizing stale ISF feature-backlog status labels after closed task trees.
- `docs/tasks/ISF-GENERATED-NAME-POLICY.md` — completed `R14` task tree for generated-name stability policy in schedule reports and generated artifacts.
- `docs/tasks/ISF-SCHEDULE-REPORT-SCHEMA-VERSION.md` — completed `R14` task tree for report-level schedule JSON schema-version metadata.
- `docs/tasks/ISF-SCHEDULE-REPORT-EVOLUTION-POLICY.md` — completed `R14` task tree for schedule-report additive/deprecation evolution policy.
- `docs/tasks/ISF-SCHEDULE-REPORT-SUMMARY-BOUNDARY.md` — completed `R14` task tree for schedule-report assignment provenance and multi-file child summary boundary.
- `docs/tasks/ISF-SCHEDULE-REPORT-GOLDEN-MATRIX.md` — completed `R14` task tree for the executable schedule-report golden fixture matrix.
- `docs/tasks/ISF-SCHEDULE-REPORT-FULL-SCHEMA-FREEZE.md` — completed `R14` task tree for freezing schedule JSON schema version 1.
- `docs/tasks/ISF-PARAM-OVERRIDE-CONSTANTS.md` — completed `R14` task tree for actor constants in activation parameter overrides.
- `docs/tasks/ISF-ASSIGN-DIAGNOSTIC-TRUTH-SYNC.md` — completed `R14` task tree for synchronizing removed `(assign ...)` diagnostic truth.
- `docs/tasks/ISF-SPEC-TEST-INDEX-SYNC.md` — completed `R14` task tree for keeping the ISF spec focused-test index synchronized.
- `docs/tasks/DOWNSTREAM-ISSUE-REPRO-FLOW.md` — completed `R14` task tree for downstream reproducible issue-reporting flow.
- `docs/tasks/ISF-ACTOR-PHASE-STAGE-REPORTS.md` — completed `R14` task tree for actor-level phase/stage schedule-report metadata.
- `docs/tasks/ISF-ACTOR-PARAM-REPORTS.md` — completed `R14` task tree for actor-level parameter default schedule-report metadata.
- `docs/tasks/ISF-EXTRACT-SINGLE-FIELD-WIDTH-INFERENCE.md` — completed `R14` task tree for exactly-one-missing-field `extract` width inference.
- `docs/tasks/ISF-CONTRACT-ACTOR-CONSTANT-WINDOWS.md` — completed `R14` task tree for positive actor constants in bounded eventual temporal-contract windows.
- `docs/tasks/ISF-TEMPORAL-CONTRACT-STORAGE-REPORTS.md` — completed `R14` task tree for temporal-contract monitor storage schedule-report roles.
- `docs/tasks/ISF-TEMPORAL-CONTRACT-ASSERTIONS.md` — completed `R14` task tree for temporal-contract SystemVerilog assertion projection.
- `docs/tasks/ISF-CDC-FIXTURE-MATRIX.md` — completed `R14` task tree for dual acknowledged-event CDC fixture hardening.
- `docs/tasks/ISF-TYPE-AGGREGATE-PARITY.md` — completed `R14` task tree for ISF enum/type/aggregate parity with existing `.fsm` semantic machinery.
- `docs/tasks/ISF-DYNAMIC-WAIT-STORAGE-REPORTS.md` — completed `R14` task tree for runtime dynamic-wait counter storage schedule-report roles.
- `docs/tasks/ISF-ACTIVATION-HANDOFF-STORAGE-REPORTS.md` — completed `R14` task tree for generated activation handoff storage schedule-report roles.
- `docs/tasks/ISF-ACTIVATION-HANDSHAKE-STORAGE-REPORTS.md` — completed `R14` task tree for generated activation start/done handoff storage schedule-report roles.
- `docs/tasks/ISF-TRANSACTION-PORT-STORAGE-REPORTS.md` — completed `R14` task tree for transaction-local port storage schedule-report roles.
- `docs/tasks/ISF-RULE-TRIGGER-STORAGE-REPORTS.md` — completed `R14` task tree for rule-trigger source and payload-source storage schedule-report roles.
- `docs/tasks/FSMGEN-IR-AUDIT.md` — completed architecture task tree for current IR inventory, canonical/private boundary classification, repo-local IR policy, and consolidation follow-up selection.
- `docs/tasks/IR-DIRECT-STRUCTURAL-BACKEND-CONVERGENCE.md` — completed architecture follow-up that guarded the current direct-root `structural_rtl_ir` projection before future convergence work.
- `docs/tasks/IR-EXPRESSION-AST-OWNERSHIP.md` — completed architecture follow-up for expression representation ownership and conversion boundaries.
- `docs/tasks/EXPR-NAMER-TRACKED-COPY-CLEANUP.md` — completed architecture follow-up that removed the tracked `ExpressionNamer.pm.new` duplicate.
- `docs/tasks/EXPR-AST-UTILS-OWNER-CONSOLIDATION.md` — completed architecture follow-up that collapsed duplicate `FSM::AST::Utils` ownership.
- `docs/tasks/EXPR-NAMER-LEGACY-PARSE-BOUNDARY.md` — completed architecture follow-up for guarding `ExpressionNamer` legacy hash/string parse boundaries.
- `docs/tasks/GLOBAL-AST-MANAGER-BOUNDARY.md` — completed architecture follow-up for resolving legacy `GlobalASTManager` ownership.
- `docs/tasks/ISF-LOWERINGIR-BOUNDARY-EXTRACTION.md` — completed architecture follow-up that inventoried private ISF `LoweringIR` subfamilies and deferred helper-owner extraction.
- `docs/tasks/MODULE-INFO-PROJECTION-GUARD.md` — completed architecture follow-up that audited `module_info` mirrors and closed without extra guard work.
- `docs/tasks/ROADMAP-ACTIVE-LANE-TRUTH-SYNC.md` — completed roadmap-maintenance task tree for repairing stale live-roadmap active-lane/frontier claims.
- `docs/tasks/ROADMAP-ACTIVE-LANE-LATEST-SLICE-SYNC.md` — completed roadmap-maintenance task tree for synchronizing the lower live-roadmap latest-slice summary.
- `docs/tasks/R12-COMPOSITION-PARSER-TOKEN-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for composition parser token and top-symbol diagnostics.
- `docs/tasks/R12-COMPOSITION-ENDPOINT-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for composition endpoint-shape diagnostics.
- `docs/tasks/R12-COMPOSITION-C1-PORT-EXPOSURE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for C1 passthrough exposure diagnostics.
- `docs/tasks/R12-COMPOSITION-EXPLICIT-LINK-TOPOLOGY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for missing explicit composition wiring diagnostics.
- `docs/tasks/R12-COMPOSITION-TARGET-SUPPORT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for unsupported composition backend target diagnostics.
- `docs/tasks/R12-COMPOSITION-PORTS-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for composition ports shape-gate diagnostics.
- `docs/tasks/R12-COMPOSITION-DUPLICATE-DECLARATION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for duplicate composition declaration diagnostics.
- `docs/tasks/R12-COMPOSITION-CHILD-KIND-PORTS-MAPPING-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for unsupported composition child-kind and legacy ports-mapping diagnostics.
- `docs/tasks/R12-COMPOSITION-CHILD-STRUCTURE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for malformed composition child-entry structure.
- `docs/tasks/R12-RTL-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for malformed external RTL child source count and payload shape.
- `docs/tasks/R12-GENERATED-CHILD-SOURCE-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for malformed generated-child source count and payload shape.
- `docs/tasks/R12-STANDALONE-DTC-EXPLICIT-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported standalone DTC explicit-system auto-wiring corpus coverage.
- `docs/tasks/R12-WRONG-KIND-CHILD-SOURCE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained expected-failure corpus coverage for wrong-kind generated-child source realization.
- `docs/tasks/R12-STANDALONE-DT-EXPLICIT-SYSTEM-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported standalone DT explicit-system corpus coverage.
- `docs/tasks/R12-IMPLICIT-COMPOSITION-SYSTEM-AUTOWIRE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported implicit composition system-port auto-wiring corpus coverage.
- `docs/tasks/R12-IMPLICIT-SYSTEM-DEFAULTS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported direct implicit system defaults corpus coverage.
- `docs/tasks/R12-CUSTOM-SYSTEM-CLOCK-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported custom system clock corpus coverage.
- `docs/tasks/R12-COMPOUND-UPDATE-VARIANTS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported compound update variant corpus coverage.
- `docs/tasks/R12-NESTED-COMPOUND-GUARD-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported nested and compound guard corpus coverage.
- `docs/tasks/R12-ARITHMETIC-XOR-OPERATOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported arithmetic and XOR operator corpus coverage.
- `docs/tasks/R12-RESET-STATE-ALIAS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported reset-state alias corpus coverage.
- `docs/tasks/R9-STRICT-LEGACY-LTEPLUS-BOUNDARY.md` — completed `R9` task tree for strict-mode rejection of the legacy `<=+` assignment alias.
- `docs/tasks/R12-RHS-EXPRESSION-SUPPORTED-VARIANTS-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported RHS expression variant corpus coverage.
- `docs/tasks/R12-COMPUTED-COMPARISON-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported computed comparison selector corpus coverage.
- `docs/tasks/R12-TEST-SELECTOR-SYMBOLIC-DEFAULT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported symbolic/default test-selector corpus coverage.
- `docs/tasks/R12-PLAIN-TEST-SIGNAL-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported plain test-signal corpus coverage.
- `docs/tasks/R12-STANDALONE-DT-GUARD-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported standalone DT guard corpus coverage.
- `docs/tasks/R12-TEST-BRANCH-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported relational test-branch selector corpus coverage.
- `docs/tasks/R12-COMPUTED-TEST-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported computed test-selector corpus coverage.
- `docs/tasks/R12-RELATIONAL-OPERATOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported relational-operator corpus coverage.
- `docs/tasks/R12-GUARD-SHORTHAND-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported guard-shorthand corpus coverage.
- `docs/tasks/R12-STATE-DTE-GUARD-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported state-DT header guard corpus coverage.
- `docs/tasks/R12-UPDATE-SHORTHAND-VARIANT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained supported update-shorthand variant corpus coverage.
- `docs/tasks/R12-TEST-SELECTOR-DEFAULT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained duplicate default test-selector expected-failure corpus coverage.
- `docs/tasks/R12-TOP-LEVEL-FORM-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained unsupported top-level form expected-failure corpus coverage.
- `docs/tasks/R12-DELAYED-PULSE-TARGET-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained delayed-pulse LHS target expected-failure corpus coverage.
- `docs/tasks/R12-PLUS-FSM-BODY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed legacy `+fsm` root-body expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-TOKEN-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained symbol-definition token expected-failure corpus coverage.
- `docs/tasks/R12-PARAM-AGGREGATE-EXPRESSION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained aggregate parameter-expression expected-failure corpus coverage.
- `docs/tasks/R12-PARAM-DEPENDENCY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained parameter dependency expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-VALUE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained symbol-definition value expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-ENTRY-MALFORMED-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed symbol-definition entry expected-failure corpus coverage.
- `docs/tasks/R12-SYMBOL-SECTION-EMPTY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained empty symbol-definition section expected-failure corpus coverage.
- `docs/tasks/R12-INIT-DIRECTIVE-SHAPE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained `:=` init-directive shape expected-failure corpus coverage.
- `docs/tasks/R12-CONDITION-EXPRESSION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained condition-expression expected-failure corpus coverage.
- `docs/tasks/R12-RHS-EXPRESSION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained RHS expression expected-failure corpus coverage.
- `docs/tasks/R12-FSM-ROOT-BODY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained structured `?fsm` root-body expected-failure corpus coverage.
- `docs/tasks/R12-STATE-BODY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained state/DT body expected-failure corpus coverage.
- `docs/tasks/R12-UPDATE-SHORTHAND-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained update-shorthand expected-failure corpus coverage.
- `docs/tasks/R12-INLINE-MODIFIER-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained inline compound modifier expected-failure corpus coverage.
- `docs/tasks/R12-TEST-SELECTOR-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained test-signal/test-selector expected-failure corpus coverage.
- `docs/tasks/R12-OPERATOR-DIRECTIVE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained authored operator/directive expected-failure corpus coverage.
- `docs/tasks/R12-ASSIGNMENT-BOUNDARY-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained assignment-boundary expected-failure corpus coverage.
- `docs/tasks/R12-NAME-REFERENCE-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained source-name, state/DT-name, and transition-target expected-failure corpus coverage.
- `docs/tasks/R12-LANGUAGE-CONTRACT-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained language-contract expected-failure corpus coverage.
- `docs/tasks/R12-MALFORMED-FORM-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed-form expected-failure corpus coverage.
- `docs/tasks/R12-SYSTEM-SECTION-CORPUS-WIDENING.md` — completed `R12` task tree for widening maintained malformed `+system` expected-failure corpus coverage.
- `docs/tasks/R8-PARTIAL-LHS-PULSE-BOUNDARY.md` — completed `R8` task tree for the delayed-pulse partial-LHS fail-closed boundary.
- `docs/tasks/R8-PARTIAL-LHS-PREFERRED-DUAL-OUTPUT.md` — completed `R8` task tree for preferred `<=-` partial-LHS dual-output coverage and the remaining pulse/vector decision split.
- `docs/BIN_FSMGEN_IMPORT_TREE.md` — live `bin/fsmgen` import-tree and runtime-spine architecture snapshot.
- `docs/IR_POLICY.md` — repo-local policy for adding, extending, exposing, or retiring IR and IR-like compiler surfaces.
- `docs/COMPOSITION_SCOPE.md` — concrete composition scope and acceptance boundary for the active architecture.
- `docs/COMPOSITION_LEGACY_MAPPING.md` — historical legacy-composition behavior mapped onto the active architecture.
- `docs/EXTENSION_MODEL.md` — typed extension boundary for the active `R7` replacement path.
- `docs/SPECFORGE_FEEDBACK_RESPONSE.md` — tracked FSMGen response to SPECFORGE adapter/tool-integration feedback.
- `docs/DOWNSTREAM_ISSUE_REPORTING.md` — strict downstream issue-reporting protocol for locally reproducible FSMGen bug reports.
- `docs/INTENT_SCHEDULING_BRAINSTORM.md` — living brainstorm log for inferring/scheduling cycles from a hardware-native intent layer above explicit `.fsm`.
- `docs/ISF_ATL_DESIGN_PROPOSAL.md` — live design proposal for ISF Actor Transfer Level actor-network orchestration.
- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` — single self-contained downstream `.isf` integration handoff that must stay synchronized with the live spec, book, public contract, manifest metadata, tests, and code.
- `docs/ISF_SPEC.md` — active R14 `.isf` Intent Scheduling Format specification.
- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` — live downstream-consumer API contract for ISF parser/scheduler surfaces.
- `docs/ISF_LIBRARY_CATALOG.md` — live catalog of shipped reusable ISF library definitions.
- `docs/REGRESSION_CORPUS.md` — human-readable companion to the machine-checked support and regression catalog.
- `docs/INTENT_CAPTURE_AXI_CASE_STUDY.md` — AXI intent-capture case-study notes for future high-level synthesis work.
- `docs/IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md` — first non-code IAL2 protocol/platform intent evaluation and go/no-go criteria.
- `docs/AXI_VALID_READY_INTENT_PROBE.md` — first bounded AXI Valid-Ready source-anchor evidence inventory for future IAL2 design/probe work.
- `docs/AXI_MANAGER_USER_API_BRAINSTORM.md` — captured AXI manager user-facing API direction for future IAL2 work.
- `docs/AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md` — first bounded AXI ID/order/concurrency source-anchor evidence inventory for future IAL2 manager rule-engine work.
- `docs/AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md` — first bounded AXI manager source-to-rule responsibility matrix for future IAL2 work.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md` — selected the first post-Valid-Ready AXI manager subset: outstanding-capacity plus acceptance/status feedback.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT.md` — readiness audit for the selected AXI manager capacity/status subset and first in-process generator boundary.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md` — first in-process AXI manager capacity/status generator slice and report surface.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md` — selected public `.ppif` syntax/readiness boundary for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md` — first public `.ppif` parser/CLI slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md` — selected the next AXI manager subset: ID-family declaration and static validation.
- `docs/AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md` — readiness audit for the additive ID-family/static-validation implementation boundary.
- `docs/AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md` — shipped additive `.ppif` ID-family metadata slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md` — selected the next AXI manager subset: logical read/write transaction envelope and static validation.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md` — readiness audit for the additive transaction-envelope/static-validation implementation boundary.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md` — shipped additive `.ppif` transaction-envelope metadata slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md` — selected the next prerequisite: transaction event dispatch and direction fan-in.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md` — readiness audit for additive per-transaction event dispatch and direction fan-in.
- `docs/AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md` — shipped additive `.ppif` transaction event dispatch/fan-in slice for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md` — selected the next AXI manager subset: ID/response rule-engine readiness.
- `docs/AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md` — readiness audit for additive concrete transaction ID request/response assertions.
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md` — shipped additive concrete transaction ID request/response assertions for the public AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_SELECTION.md` — selected AXI manager auto-ID lifecycle/request-ID drive readiness as the next subset.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_READINESS_AUDIT.md` — readiness audit selecting bounded auto-ID pool/request-ID drive contract selection before implementation.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md` — selected explicit optional `auto-id-lifecycle` bounded-pool syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md` — shipped additive `.ppif` auto-ID lifecycle parser/report metadata for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md` — shipped bounded auto-ID request-ID drive behavior for explicit lifecycle families.
- `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md` — selected AXI manager generated response-demux readiness after bounded auto-ID request-ID drive.
- `docs/AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md` — readiness audit selecting bounded write response-demux public contract before implementation.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected explicit write-only `response-demux` public syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md` — shipped write-only `response-demux` parser/report metadata for one AXI manager capacity/status object.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md` — readiness audit selecting the IAL1 rule-pulse prerequisite before generated write `BID` demux behavior.
- `docs/AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md` — shipped generated write `BID` response-demux behavior for explicit `response-demux` contracts.
- `docs/AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md` — selected report-residue alignment after generated write `BID` demux before larger ordering/read-response work.
- `docs/AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md` — shipped auto-ID lifecycle report-residue alignment after generated write `BID` demux.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md` — selected same-ID ordering readiness after generated write `BID` demux and residue alignment.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md` — readiness audit selecting bounded auto-ID same-ID avoidance assertions/report metadata before per-ID queues.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md` — shipped bounded generated auto-ID same-ID avoidance assertions/report metadata.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md` — selected read `RID` response-demux readiness after generated auto-ID same-ID avoidance.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md` — readiness audit selecting a bounded read response-demux public contract before parser/report or behavior changes.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected explicit `response-scope single-beat` read response-demux syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md` — shipped read response-demux parser/report metadata and static validation without generated read behavior.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md` — readiness audit selecting bounded generated single-beat read `RID` response-demux behavior before implementation.
- `docs/AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md` — shipped bounded generated single-beat read `RID` response-demux behavior for explicit read response-demux contracts.
- `docs/AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data payload, burst/`RLAST`, and per-ID ordering/reassembly readiness as the next AXI manager IAL2 audit after generated read demux.
- `docs/AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md` — readiness audit selecting bounded public read-data payload/status contract selection before parser/report or generated behavior changes.
- `docs/AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md` — selected bounded single-beat `read-data` syntax for `RDATA`/`RRESP` capture before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md` — shipped structural `read_data` parser/report metadata and static validation without generated capture behavior.
- `docs/AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md` — readiness audit selecting generated single-beat `RDATA`/`RRESP` capture behavior with no new IAL1/IAL0/SystemVerilog prerequisite.
- `docs/AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md` — shipped generated single-beat `RDATA`/`RRESP` capture behavior for explicit `read-data` contracts.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md` — readiness audit selecting public AXI burst/`RLAST` completion contract selection before parser/report metadata or generated behavior changes.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md` — selected additive read `response-demux` `response-scope burst-last` plus one-bit `last-signal` syntax before parser/report implementation.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for `response-scope burst-last` with generated `RLAST` behavior deferred.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md` — readiness audit selecting direct generated burst-last/`RLAST` completion behavior.
- `docs/AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md` — shipped generated burst-last/`RLAST` completion behavior.
- `docs/AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md` — selected AXI `RLAST` report/static-text alignment before larger read-data reassembly or manager behavior.
- `docs/AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md` — shipped generated AXI `RLAST` schedule-report prose alignment.
- `docs/AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md` — selected public AXI burst read-data contract selection after generated `RLAST` completion/report alignment.
- `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md` — selected explicit last-beat `RDATA`/`RRESP` capture as the first bounded burst read-data contract.
- `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for explicit last-beat `RDATA`/`RRESP` capture with generated behavior deferred.
- `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md` — readiness audit selecting direct generated last-beat `RDATA`/`RRESP` capture behavior.
- `docs/AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md` — shipped generated last-beat `RDATA`/`RRESP` capture behavior.
- `docs/AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected public AXI burst read-data beat-count/depth contract selection after generated last-beat capture.
- `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md` — selected ARLEN-based `burst-length` syntax and report contract before parser/report metadata.
- `docs/AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for ARLEN-based `burst-length` contracts.
- `docs/AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md` — selected generated ARLEN burst-length capture readiness audit after report-only metadata.
- `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md` — audited generated raw-ARLEN capture readiness and selected direct behavior.
- `docs/AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md` — shipped generated raw-ARLEN capture behavior for opt-in last-beat read-data `burst-length` contracts.
- `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md` — audited beat-count/RLAST validation readiness and selected public runtime-validation contract selection before behavior.
- `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md` — selected `(validation runtime-assertion)` / `runtime_assertion` as the public beat-count/RLAST validation contract before behavior.
- `docs/AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md` — shipped generated beat-count/RLAST runtime validation for `(validation runtime-assertion)` burst-length contracts.
- `docs/AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md` — selected public multi-beat read-data reassembly/output contract selection after generated beat-count/RLAST validation.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md` — selected per-beat output-bank public contract for multi-beat read-data reassembly/output.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for the public multi-beat read-data output-bank contract.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md` — audited generated output-bank behavior readiness and selected direct scalar-lane behavior.
- `docs/AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md` — shipped generated multi-beat read-data output-bank behavior for the public multi-beat sample.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md` — selected public scalar `RRESP` aggregation contract selection after generated multi-beat read-data output-bank behavior.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md` — selected additive scalar `RRESP` aggregation syntax and report contract before parser/report metadata.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md` — shipped parser/report metadata and static validation for the selected scalar `RRESP` aggregation contract.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md` — audited generated scalar `RRESP` aggregation readiness and selected direct generated behavior.
- `docs/AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md` — shipped generated scalar `RRESP` aggregation outputs/init/update behavior.
- `docs/AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md` — selected per-ID read-data interleaving and queue readiness after scalar `RRESP` aggregation.
- `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_QUEUE_READINESS_AUDIT.md` — audited read-data interleaving/queue readiness and selected report/static residue alignment for the covered generated auto-ID multi-beat-by-RID subset.
- `docs/AXI_IAL2_MANAGER_READ_DATA_INTERLEAVING_RESIDUE_ALIGNMENT_FIRST_SLICE.md` — aligned read-data interleaving residue for the covered generated auto-ID multi-beat-by-RID subset.
- `docs/AXI_IAL2_MANAGER_POST_INTERLEAVING_ALIGNMENT_NEXT_SLICE_SELECTION.md` — selected AXI burst payload/output readiness audit after read-data interleaving residue alignment.
- `docs/AXI_IAL2_MANAGER_BURST_PAYLOAD_OUTPUT_READINESS_AUDIT.md` — audited bounded burst payload/output readiness and selected report/static `bursts` residue alignment.
- `docs/AXI_IAL2_MANAGER_BURST_RESIDUE_ALIGNMENT_FIRST_SLICE.md` — aligned broad `bursts` residue for the covered generated auto-ID multi-beat output-bank subset.
- `docs/AXI_IAL2_MANAGER_POST_BURST_RESIDUE_NEXT_SLICE_SELECTION.md` — selected AXI concrete-ID same-ID ordering readiness after bounded burst residue alignment.
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_ORDERING_READINESS_AUDIT.md` — audited concrete-ID same-ID ordering readiness and selected fail-closed static validation for unsupported authored same-ID reuse.
- `docs/AXI_IAL2_MANAGER_CONCRETE_ID_SAME_ID_STATIC_VALIDATION_FIRST_SLICE.md` — shipped fail-closed static validation for unsupported same-family concrete-ID reuse.
- `docs/AXI_IAL2_MANAGER_POST_CONCRETE_ID_STATIC_VALIDATION_NEXT_SLICE_SELECTION.md` — selected per-ID issue-order queue readiness after concrete-ID static validation.
- `docs/AXI_IAL2_MANAGER_PER_ID_QUEUE_READINESS_AUDIT.md` — audited per-ID issue-order queue readiness and selected same-ID reuse policy contract selection.
- `docs/AXI_IAL2_MANAGER_SAME_ID_REUSE_POLICY_CONTRACT_SELECTION.md` — selected explicit same-ID reuse reject policy syntax before parser/report metadata.
- `docs/AXI_IAL2_MANAGER_SAME_ID_REJECT_POLICY_FIRST_SLICE.md` — shipped parser/report metadata and static validation for explicit same-ID reuse reject policy.
- `docs/AXI_IAL2_MANAGER_POST_SAME_ID_REJECT_POLICY_NEXT_SLICE_SELECTION.md` — selected same-ID issue-order queue policy contract selection after explicit reject policy.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_CONTRACT_SELECTION.md` — selected the public AXI same-ID `issue-order-queue` policy contract and the follow-up behavior-readiness audit.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_BEHAVIOR_READINESS_AUDIT.md` — audited same-ID `issue-order-queue` behavior readiness and selected metadata-first support.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_METADATA_FIRST_SLICE.md` — shipped metadata-first parser/report support for selected-not-generated `issue-order-queue`.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_ENQUEUE_BOUNDARY_AUDIT.md` — audited admitted enqueue readiness and selected admitted request pulses before queue state.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_ADMITTED_REQUEST_PULSES_FIRST_SLICE.md` — shipped admitted request pulse generation for selected same-ID `issue-order-queue` families while accepted same-ID reuse remains deferred.
- `docs/AXI_IAL2_MANAGER_POST_ADMITTED_REQUEST_PULSES_NEXT_SLICE_SELECTION.md` — selected same-ID issue-order queue state and queue-head demux readiness after admitted request pulses.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_DEMUX_READINESS_AUDIT.md` — audited same-ID queue-state and queue-head response-demux readiness.
- `docs/AXI_IAL2_MANAGER_SAME_ID_ISSUE_ORDER_QUEUE_STATE_REPRESENTATION_SELECTION.md` — selected compact one-hot transaction slots for future same-ID issue-order queues.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_CONTRACT_SELECTION.md` — selected the concrete same-ID queue-head response-demux public/report contract.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md` — shipped selected-not-generated concrete same-ID queue-head response-demux metadata and static validation.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_READINESS_AUDIT.md` — audited generated same-ID queue state plus queue-head behavior readiness and selected the first generated behavior slice selector.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE_SELECTION.md` — selected read burst-last, one duplicate concrete-ID group, two-transaction depth-2 generated queue state plus queue-head demux as the first behavior implementation boundary.
- `docs/AXI_IAL2_MANAGER_SAME_ID_QUEUE_BEHAVIOR_FIRST_SLICE.md` — shipped bounded generated read burst-last depth-2 concrete same-ID queue state plus queue-head response demux for the public same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_WRITE_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped bounded generated write depth-2 concrete same-ID queue state plus queue-head `BID` response demux for the public write same-ID sample.
- `docs/AXI_IAL2_MANAGER_POST_WRITE_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md` — selected bounded read `single-beat` concrete same-ID queue-head response demux as the next behavior slice.
- `docs/AXI_IAL2_MANAGER_READ_SINGLE_BEAT_SAME_ID_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped bounded generated read single-beat depth-2 concrete same-ID queue state plus queue-head `RID` response demux without `RLAST`.
- `docs/AXI_IAL2_MANAGER_POST_READ_SINGLE_BEAT_SAME_ID_QUEUE_BEHAVIOR_NEXT_SLICE_SELECTION.md` — selected queue-head read-data consumption readiness after generated read single-beat same-ID queue-head behavior.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_READINESS_AUDIT.md` — audited queue-head read-data readiness and selected generated single-beat queue-head read-data capture.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_READ_DATA_BEHAVIOR_FIRST_SLICE.md` — shipped generated single-beat queue-head `RDATA`/`RRESP` capture for the bounded read single-beat concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated last-beat queue-head `RDATA`/`RRESP` capture for the bounded read burst-last concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected generated raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data shape.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped report-only raw-`ARLEN` burst-length capture for the bounded queue-head last-beat read-data sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data shape.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_RUNTIME_VALIDATION_BEHAVIOR.md` — shipped generated queue-head beat-count/RLAST runtime validation for the bounded queue-head last-beat read-data sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_RUNTIME_VALIDATION_NEXT_SLICE_SELECTION.md` — selected generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head demux shape.
- `docs/AXI_IAL2_MANAGER_QUEUE_HEAD_MULTI_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated queue-head multi-beat read-data output-bank behavior for the bounded read burst-last concrete same-ID queue-head sample.
- `docs/AXI_IAL2_MANAGER_POST_QUEUE_HEAD_MULTI_BEAT_NEXT_SLICE_SELECTION.md` — selected multiple independent read burst-last depth-2 concrete same-ID queue-head response-demux group readiness after generated queue-head multi-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_READINESS_AUDIT.md` — audited multiple depth-2 read burst-last queue-head response-demux groups and selected the narrow implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_RESPONSE_DEMUX_BEHAVIOR.md` — shipped generated multiple read burst-last depth-2 concrete same-ID queue-head response-demux groups.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_DEMUX_NEXT_SLICE_SELECTION.md` — selected read-data-over-multiple-generated-queue-groups readiness after generated multi-group queue-head demux.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_READ_DATA_BEHAVIOR.md` — shipped generated multi-group queue-head multi-beat read-data output-bank behavior.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_READ_DATA_NEXT_SLICE_SELECTION.md` — selected last-beat-only read-data over multiple generated queue-head groups as the next audit owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_READINESS_AUDIT.md` — audited scalar last-beat read-data over multiple generated queue-head groups and selected the narrow implementation owner.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_BEHAVIOR.md` — shipped generated multi-group queue-head scalar last-beat read-data capture.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md` — selected generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_BEHAVIOR.md` — shipped generated report-only raw-`ARLEN` capture for multi-group queue-head scalar last-beat read-data.
- `docs/AXI_IAL2_MANAGER_POST_MULTI_GROUP_QUEUE_HEAD_BURST_LENGTH_NEXT_SLICE_SELECTION.md` — selected runtime-validation multi-group queue-head scalar last-beat readiness audit.
- `docs/AXI_IAL2_FIRST_IMPLEMENTATION_SUBSET_SELECTION.md` — selected first AXI-derived IAL2 implementation subset and pre-code contract.
- `docs/AXI_IAL2_VALID_READY_READINESS_AUDIT.md` — code/test/docs/report owner map for a future AXI Valid-Ready IAL2 implementation slice.
- `docs/AXI_IAL2_VALID_READY_GENERATOR_FIRST_SLICE.md` — first in-process AXI Valid-Ready IAL2 generator slice and report surface.
- `docs/IAL2_PPIF_PARSER_CLI_FIRST_SLICE.md` — first public `.ppif` parser/CLI slice for one AXI Valid-Ready source object.
- `docs/IAL2_PPIF_MULTI_VALID_READY_READINESS.md` — readiness map for future multi-channel `.ppif` Valid-Ready support.
- `docs/IAL2_PPIF_VALID_READY_BUNDLE_CONTRACT_SELECTION.md` — selected future aggregate bundle contract for multi-channel `.ppif` Valid-Ready support.
- `docs/IAL2_PPIF_VALID_READY_BUNDLE_FIRST_SLICE.md` — shipped bounded multi-channel `.ppif` Valid-Ready bundle report/review-artifact behavior.
- `docs/IAL2_PPIF_BUNDLE_SEMANTIC_JSON_FIRST_SLICE.md` — shipped aggregate semantic JSON for multi-channel `.ppif` bundles.
- `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_SELECTION.md` — selected aggregate wrapper/top HDL entry contract for multi-channel `.ppif` bundles.
- `docs/IAL2_PPIF_BUNDLE_HDL_ENTRY_FIRST_SLICE.md` — shipped aggregate wrapper/top HDL entry for the tracked multi-channel `.ppif` bundle.
- `ppif/axi_aw_valid_ready.ppif` — first checked-in runnable `.ppif` sample for the public IAL2 Valid-Ready CLI surface.
- `ppif/axi_aw_w_valid_ready_bundle.ppif` — checked-in runnable multi-channel `.ppif` bundle sample for aggregate report/review-artifact modes.
- `ppif/axi_manager_capacity_status_id_family.ppif` — checked-in runnable `.ppif` sample for static AXI manager ID-family metadata.
- `ppif/axi_manager_capacity_status_transaction_envelope.ppif` — checked-in runnable `.ppif` sample for AXI manager transaction-envelope metadata and concrete direction-level ID assertions.
- `ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif` — checked-in runnable `.ppif` sample for AXI manager transaction event dispatch/fan-in and concrete per-transaction ID assertions.
- `ppif/axi_manager_capacity_status_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read burst-last depth-2 concrete same-ID queue state plus queue-head response demux.
- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated multiple read burst-last depth-2 concrete same-ID queue-head response-demux groups.
- `ppif/axi_manager_capacity_status_read_multi_group_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated multi-group queue-head multi-beat read-data output-bank behavior.
- `ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated read single-beat depth-2 concrete same-ID queue state plus queue-head `RID` response demux without `RLAST`.
- `ppif/axi_manager_capacity_status_read_single_beat_same_id_queue_head_read_data.ppif` — checked-in runnable `.ppif` sample for generated single-beat `RDATA`/`RRESP` capture from generated read single-beat concrete same-ID queue-head response demux.
- `ppif/axi_manager_capacity_status_write_same_id_queue_head_response_demux.ppif` — checked-in runnable `.ppif` sample for generated write depth-2 concrete same-ID queue state plus queue-head `BID` response demux.
- `ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif` — checked-in runnable `.ppif` sample for AXI manager auto-ID lifecycle bounded-pool request-ID drive behavior.
- `ppif/axi_manager_capacity_status_read_response_demux.ppif` — checked-in runnable `.ppif` sample for AXI manager read response-demux generated single-beat `RID` behavior.
- `ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif` — checked-in runnable `.ppif` sample for generated AXI manager burst-last `RLAST` response-demux completion behavior.
- `ppif/axi_manager_capacity_status_read_data_last_beat.ppif` — checked-in runnable `.ppif` sample for structural AXI manager last-beat `RDATA`/`RRESP` metadata paired with generated burst-last response-demux completion.
- `ppif/axi_manager_capacity_status_read_data_multi_beat.ppif` — checked-in runnable `.ppif` sample for public multi-beat read-data output-bank behavior with generated per-beat data/status lanes, valid mask, length outputs, and generated scalar `RRESP` aggregation behavior.
- `docs/PDF_EXTRACTION_WORKFLOW.md` — portable workflow for task-owned source-anchored PDF text, table, diagram, and image extraction.
- `docs/decisions/0014-protocol-platform-intent-surface-and-layered-lowering.md` — generic IAL2 file-surface candidates and layered lowering decision.
- `docs/decisions/0015-ial2-profile-extensions-are-vocabulary-aliases.md` — IAL2 protocol-profile extension refinement.
- `docs/decisions/0016-ppif-is-first-public-ial2-container.md` — selects `.ppif` as the first public generic IAL2 file surface.
- `docs/decisions/0017-ppif-valid-ready-bundle-contract.md` — future multi-channel `.ppif` bundle contract decision.
- `docs/decisions/0018-ial-contracts-are-backend-language-neutral.md` — IAL contracts and mdBook stay backend-language-neutral for future Rust, Rust/Wasm, browser-capable JavaScript, and Dart/web parity.
- `docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf` — tracked repo-local raw AXI protocol specification reference for future task-tree-owned IAL2 probes.
- `docs/FEATURE_BACKLOG.md` — repo-level pointer to the canonical mdBook backlog for deferred/not-fully-shipped user-visible features.
- `docs/VHDL_SCOPE.md` — scoped VHDL backend plan and shipped direct-root scaffold boundary.
- `CHANGES.md` — persistent technical change history.
- `DEVELOPMENT_NOTES.md` — architecture notes and engineering rationale.
- `MEMORY.md` — live continuity context and recovery notes.
- `LIVE_ACHIEVEMENT_STATUS.md` — latest completed roadmap-aligned slice for fast recovery.
- `COMMIT.md` — canonical commit workflow specification.
- `WARP.md` — project guidance for Warp/agent workflows.
- `.agents/workflows/commit.md` — agent workflow definition for commit operations.
- `.github/workflows/README.md` — active hosted CI and GitHub Pages workflow overview.

## Project file and directory map
### Core entrypoints and pipeline
- `bin/fsmgen` — main CLI entrypoint.
- `bin/fsmgen-issue-bundle` — downstream issue-bundle helper that captures
  reproducible FSMGen command artifacts for local triage.
- `perl/FSM/Adapter/ISF.pm` — `.isf` parser facade for intent-scheduling sources.
- `perl/FSM/Scheduler/ISF.pm` — `.isf` lowering facade that emits scheduled `.fsm` and schedule JSON reports.
- `perl/FSM/Scheduler/ISF/LoweringIR.pm` — typed lowering IR builder for `.isf` actors, transactions, drives, control flow, and spawned children.
- `perl/FSM/Scheduler/ISF/ATLGeneratedTop.pm` — private ATL generated-top helper for schedule-report projection and data-link child-interface marking.
- `perl/FSM/Scheduler/ISF/Emitter/FSM.pm` — scheduled `.fsm` emitter for `.isf` lowering results.
- `perl/FSM/Scheduler/ISF/Emitter/CompositionTop.pm` — generated `?top` emitter for ISF spawned-child parent/child handoff.
- `perl/FSM/Scheduler/ISF/Emitter/JSON.pm` — machine-readable schedule-report emitter for `.isf` lowering results.
- `perl/FSM/Pipeline/HDLGenerator.pm` — thin public generation facade around source/direct/composition orchestrators; accepts supported `.fsm`, `.isf`, and `.ppif` source roots.
- `perl/FSM/Composition/Net.pm` — typed internal net plan for multi-child composition wiring.
- `perl/FSM/Composition/Parser.pm` — first typed composition parser/IR boundary.
- `perl/FSM/Composition/Plan.pm` — typed realized top-planning object for active composition work.
- `perl/FSM/Composition/RTLInterfaceLoader.pm` — sidecar external-RTL interface loader for the shipped `C3` composition lane.
- `perl/FSM/Extension/Loader.pm` — explicit typed extension-module loader for the active `R7` replacement seam.
- `perl/FSM/Extension/Registry.pm` — typed extension registry for the active `R7` replacement seam.
- `perl/FSM/Extension/Context.pm` — typed hook context object passed to active extensions.
- `perl/FSM/Support/CapabilityManifest.pm` — machine-readable capability manifest builder for downstream tool integration.
- `perl/FSM/Support/CapabilityManifestContract.pm` — bounded top-level capability-manifest shell contract advertised through the manifest itself.
- `perl/FSM/Support/DiagnosticsContract.pm` — bounded manifest-facing contract for the `diagnostics` section's public top-level and stable-code entry families.
- `perl/FSM/Support/EmbeddingContract.pm` — bounded manifest-facing contract for the `embedding` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/BackendValidationContract.pm` — bounded manifest-facing contract for the `backend_validation` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/DocumentationContract.pm` — bounded manifest-facing contract for the `documentation` section's public path-list keys.
- `perl/FSM/Support/LanguageSurfaceContract.pm` — bounded manifest-facing contract for the `language_surface` section's public top-level, first nested key lists, file-surface discovery keys, and per-suffix supported CLI-mode metadata.
- `perl/FSM/Support/ProducerContract.pm` — bounded manifest-facing contract for the `producer` section's public identity/build metadata keys.
- `perl/FSM/Support/SemanticExportsContract.pm` — bounded manifest-facing contract for the `semantic_exports` section's public top-level and nested contract-owner map.
- `perl/FSM/Support/CheckDiagnostics.pm` — bounded `--check --json` report builder and stable-code classifier.
- `perl/FSM/Support/CheckDiagnosticsContract.pm` — bounded `--check --json` key-presence contract advertised through the capability manifest.
- `perl/FSM/Support/CheckFailureDiagnosticContract.pm` — shared bounded nested-object contract for failure `diagnostic` payloads in public check JSON and normalized semantic JSON.
- `perl/FSM/Support/CheckResultContract.pm` — bounded nested-object contract for successful public check JSON `result` payloads.
- `perl/FSM/Support/CompositionReportContract.pm` — bounded sanitized composition provenance/report contract for semantic JSON.
- `perl/FSM/Support/NormalizedSemanticCompositionContract.pm` — bounded nested-object contract for the `semantic.composition` summary in successful public normalized semantic JSON composition sources, including bounded `children[]`, `children[].parameter_overrides[]`, `generated_children[]`, `generated_children[].parameter_overrides[]`, `standalone_dt_children[]`, and `shared_datapath_candidates[]` shallow/alias entry key families.
- `perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm` — bounded nested-object contract for the `semantic.explicit_system_contract` summary in successful public normalized semantic JSON when that authored explicit contract is preserved.
- `perl/FSM/Support/NormalizedSemanticForwardIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.lowered_rtl_ir` summary in successful public normalized semantic JSON, including output-drive, selector-conflict, standalone-DT multi-drive, and composition-only extension key families.
- `perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.structural_rtl_ir` summary in successful public normalized semantic JSON, including bounded `assignment_records[]` structured generated-enable entries, bounded `auxiliary_assignments[]` scalar-string compatibility values, bounded `ports[]` core keys, direct input-port `targets[]` extension/entry keys, `nets[]`, generated-enable net `source`/`targets[]` connectivity entry keys, `declared_links[]`, `resolved_links[]`, shallow `instances[]`, nested `instances[].interface_ports[]`, nested `instances[].parameter_overrides[]` core plus optional raw-value/value-metadata extension keys, and nested `instances[].port_bindings[]` core plus typed-extension entry keys.
- `perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm` — bounded nested-object contract for the `semantic.forward_ir.intent_hir` summary in successful public normalized semantic JSON, including its composition-only extension keys and composition-child alias key families.
- `perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm` — bounded nested-object contract for the `semantic.signal_analysis` summary in successful public normalized semantic JSON, including the shared core signal-entry keys.
- `perl/FSM/Support/NormalizedSemanticSystemContract.pm` — bounded nested-object contract for the `semantic.system_contract` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticSymbolContract.pm` — bounded nested-object contract for the optional `semantic.symbol_contract` summary in successful public normalized semantic JSON symbol-rich sources.
- `perl/FSM/Support/NormalizedSemanticModuleContract.pm` — bounded nested-object contract for the `semantic.module` summary in successful public normalized semantic JSON.
- `perl/FSM/Support/NormalizedSemanticPayloadContract.pm` — bounded nested-object contract for successful public normalized semantic JSON `semantic` payloads.
- `perl/FSM/Support/DiagnosticCodes.pm` — stable diagnostic-code registry consumed by support accounting and the capability manifest.
- `perl/FSM/Support/DiagnosticCodeRegistryContract.pm` — bounded stable-code registry contract advertised through the capability manifest.
- `perl/FSM/Support/DebugRuntimeContract.pm` — bounded in-process debug save/restore/scoped runtime contract advertised through `embedding.debug_runtime`.
- `perl/FSM/Support/ExtensionContract.pm` — bounded typed-extension/context contract advertised to embedders through the capability manifest.
- `perl/FSM/Support/HDLGeneratorFacadeContract.pm` — bounded public in-process `HDLGenerator` constructor/generation facade contract advertised through `embedding.hdl_generator_facade`.
- `perl/FSM/Support/ISFPublicInterfaceContract.pm` — bounded public ISF parser/scheduler facade and schedule-report contract advertised through `embedding.isf_public_interface`.
- `perl/FSM/Support/ISFResourceCatalog.pm` — shared ISF resource-kind registry consumed by the parser and public contract, including current arbiters, shareable resource kinds, shipped/backlog status, and meaning text.
- `perl/FSM/Support/HDLGeneratorModuleInfoContract.pm` — bounded nested-object contract for `HDLGenerator` `module_info` identity plus direct/composition scalar summary subsurfaces.
- `perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `composition_plan` branch plus its sanitized composition-summary fallback surfaces.
- `perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `composition_spec` branch plus its sanitized composition-summary fallback surfaces.
- `perl/FSM/Support/HDLGeneratorFSMModuleContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `fsm_module` CoreAST branch plus its semantic-summary fallback surfaces.
- `perl/FSM/Support/HDLGeneratorRawASTContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `raw_ast` parser/debug branch plus its semantic-summary fallback surface.
- `perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm` — bounded shell-only contract for the raw `HDLGenerator` `resolved_package_imports` package-spec map plus its stable package-import summary surface.
- `perl/FSM/Support/HDLGeneratorStatisticsContract.pm` — bounded nested-object contract for `HDLGenerator` `statistics` direct/composition scalar summary subsurfaces.
- `perl/FSM/Support/HDLGeneratorSourceInfoContract.pm` — bounded nested-object contract for `HDLGenerator` `source_info` identity and package-import summary subsurfaces.
- `perl/FSM/Support/HDLGeneratorResultContract.pm` — bounded top-level result contract plus delegated nested `source_info`/`module_info`/`statistics` owners, delegated shell-only `composition_plan`/`composition_spec`/`fsm_module`/`raw_ast`/`resolved_package_imports` owners, advertised stable subsurfaces for `source_info`/`module_info`/`statistics` rather than whole-hash promises, an explicitly raw `composition_report` compatibility branch, and reused semantic-layer shell contracts rather than separate whole-hash promises for in-process `HDLGenerator` embedders.
- `perl/FSM/Support/SerializablePlanReportContract.pm` — bounded `embedding.serializable_plan_reports` contract that advertises JSON-safe plan/report surfaces and raw `HDLGenerator` shell replacement guidance for embedders.
- `perl/FSM/Support/SerializableCompositionPlanSnapshot.pm` — JSON-safe bounded composition-plan snapshot builder/contract for embedders that need plan summaries without traversing raw `FSM::Composition::Plan` objects.
- `perl/FSM/Support/SerializableGenerationResultSnapshot.pm` — JSON-safe bounded `HDLGenerator` result snapshot builder/contract for embedders that need result summaries without exporting raw compatibility-shell objects.
- `perl/FSM/Support/SerializableDiagnosticSummary.pm` — JSON-safe bounded diagnostic summary builder/contract for stable diagnostic code/count inspection across public reports.
- `perl/FSM/Support/HDLExternalValidation.pm` — optional Verilator/Yosys validation lane for generated SystemVerilog.
- `perl/FSM/Support/HDLExternalValidationContract.pm` — bounded external validation contract advertised through the capability manifest.
- `perl/FSM/Support/NormalizedSemanticReport.pm` — bounded normalized semantic JSON report builder for downstream tool integration.
- `perl/FSM/Support/NormalizedSemanticReportContract.pm` — bounded normalized semantic JSON key-presence contract advertised through the capability manifest.
- `perl/FSM/Support/ReportGeneratedOutputContract.pm` — shared bounded nested-object contract for public `generated_output` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/ReportCommandContract.pm` — shared bounded nested-object contract for public `command` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/ReportProducerContract.pm` — shared bounded nested-object contract for public `producer` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/ReportSourceContract.pm` — shared bounded nested-object contract for public `source` payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/SupportAccountingMatchContract.pm` — shared bounded nested-object contract for public support-accounting match payloads in check JSON and normalized semantic JSON.
- `perl/FSM/Support/SupportAccountingContract.pm` — bounded support-accounting section contract advertised through the capability manifest.
- `perl/FSM/Support/RegressionCorpus.pm` — production support-accounting catalog owner consumed by the manifest and regression tests.
- `perl/FSM/SourceClassifier.pm` — top-level source-kind classification for FSM vs composition inputs.
- `perl/FSM/Adapter/FSMGenFull.pm` — FSM adapter/parsing entry.
- `perl/FSM/HDL/FlattenedDT.pm` — Flattened decision-tree facade.
- `perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/PostFlatteningAssemblySupport.pm` — live direct SystemVerilog post-flattening assembly owner.
- `perl/FSM/Package/IntegerLiteralSupport.pm` — shared `.fsm` integer-literal interpreter and target-HDL normalizer for decimal, based, prefixed, and intent-level sized spellings such as `5'23`, `8'-10`, and `20'x1`.
- `perl/FSM/Synthesis/EnableGraph.pm` — enable synthesis/helper ownership.

### Input, tests, and support
- `fsm/` — sample/input `.fsm` files.
- `ppif/` — sample/input `.ppif` files for shipped IAL2 public surfaces.
- `t/` — regression and behavior tests.
- `docs/` — user and technical docs.
- `generated/` — generated parser/output artifacts.
- `grammars/` — grammar definitions.
- `rust/Makefile` — makefile used for rust-side build/management tasks.

## Quick start
```bash
./bin/fsmgen fsm/trial_0.fsm
./bin/fsmgen --output /tmp/trial_0.sv fsm/trial_0.fsm
./bin/fsmgen --debug=3 fsm/lte_dif_pmaster.fsm
./bin/fsmgen --verify-hdl --output /tmp/lte_dif_pmaster.sv fsm/lte_dif_pmaster.fsm
./bin/fsmgen --strict isf/apb_requester.isf
./bin/fsmgen --emit-schedule-json isf/i2c_master.isf
./bin/fsmgen --emit-schedule-json ppif/axi_aw_valid_ready.ppif
./bin/fsmgen --capability-manifest
```

## Documentation quick preview
```bash
mdbook build docs/book
cd docs/book && mdbook serve
```
- The mdBook is the progressive learning surface.
- `docs/USER_GUIDE.md` remains the broad live reference while that split is still in progress.
- GitHub Pages publishes the same mdBook from `docs/book` through the active
  workflow in `.github/workflows/pages.yml` when the repository's Pages source
  is set to GitHub Actions.

## Local CI / pre-push regression
```bash
./bin/ci-regression quick
./bin/ci-regression smoke
./bin/ci-regression isf
./bin/ci-regression
./bin/ci-regression --list
```
- `bin/ci-regression` is the repo-owned local regression entrypoint.
- The script resolves the repository root itself, so you can invoke it without depending on your current working directory.
- It supports explicit turnaround tiers:
  - `quick`: curated smoke set across direct `.fsm`, composition
    classification, one composition child path, ISF parse/schedule, and the
    ISF public contract.
  - `smoke`: alias for `quick`, provided for the fast basic-functionality
    check described by the tier.
  - `isf`: all ISF-focused tests in the current 109x, 11xx, 12xx, and 13xx
    numbered bands.
  - `full`: the complete Perl regression suite with `prove -I perl t`.
- With no mode argument it runs `full`, preserving the historical pre-push
  gate behavior.
- It also builds the mdBook with `mdbook build docs/book` by default, so the
  user-facing book stays under the same local quality gate; use `--no-book`
  only for a deliberately code-only local turnaround check.
- When `verilator` and `yosys` are installed, the external SystemVerilog validation smoke runs too; otherwise that test is skipped.
- GitHub Actions is active again under [.github/workflows/](.github/workflows/).
  The hosted regression workflow calls `./bin/ci-regression`, so the local and
  GitHub quality gates use the same repo-owned entrypoint.
- Hosted CI uses a minimal Perl setup. Ordinary runtime paths should not rely
  on undeclared local CPAN modules, and CLI report modes tested for clean
  stderr must remain compatible with the hosted Perl version.

## CLI quick reference
```bash
./bin/fsmgen [options] <fsm_file_or_isf_file>
```
- `-o, --output <file>`: explicit output path.
- `--outdir <dir>`: write every scheduled `.fsm` file produced from a multi-file `.isf` lowering.
- `-l, --language <systemverilog|sv|verilog|v|vhdl>`: target language.
- `-d, --debug[=N]`: numeric debug compatibility level (`0..4`; bare `--debug` implies `4`).
- `--trace-verbosity <none|low|medium|high|debug>`: named trace verbosity.
- `--trace-log[=FILE]`: trace output file (default `trace.log`).
- `--trace-emojis` / `--notrace-emojis`: emoji marker toggle.
- `--extension-module <Module::Name>`: load an explicit typed extension module from `@INC` (may be repeated).
- `--extension-config <file>`: load typed extension modules from an explicit config file (may be repeated).
- `--capability-manifest`: print the versioned JSON FSMGen capability manifest and exit.
- `--check --json`: run the full pipeline as a check, emit JSON diagnostics, and do not write HDL.
- `--emit-semantic-json`: run the full pipeline, emit bounded normalized semantic JSON, and do not write HDL.
- `--emit-schedule-json`: for `.isf` input, emit the scheduler's JSON report and exit before HDL generation.
- `--verify-hdl`: after writing generated SystemVerilog, run Verilator lint and ABC-free Yosys structural synthesis; optional ABC executable discovery is reported for contract visibility but ABC is not required or run by the CLI. In-process callers can explicitly opt into ABC-backed Yosys mapping validation with `FSM::Support::HDLExternalValidation::validate_systemverilog_file(..., abc_mapping => 1)`.
- `-q, --quiet`: suppress informational output.

Inputs ending in `.isf` are parsed by the intent scheduler, lowered to one or
more explicit `.fsm` sources, and then fed through the normal `.fsm` pipeline
unless `--emit-schedule-json` is requested.
For `.isf` inputs, `--check --json` and `--check-json` emit structured
`success: false` JSON for parser, lowering, report-building, and downstream
semantic check failures instead of leaving stdout empty.
For successful `.isf` and `.ppif` inputs that lower through generated `.fsm`
temporaries, public check JSON and normalized semantic JSON keep
`source.resolved_path` on the original resolved `.isf`/`.ppif` file and can
match support accounting against those public source paths. The normalized
semantic payload still describes the generated `.fsm` semantic root.

The bounded machine-readable surfaces are backed by support accounting:
`--check --json` is corpus-covered across supported, strict-supported, and
expected-failure entries, while `--emit-semantic-json` is corpus-covered across
current supported, strict-supported, and expected-failure entries.
Those two public JSON/report surfaces now also share one bounded nested-object
owner for their `support_accounting` match payloads:
[perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`producer` object owner for FSMGen identity plus the report builder owner:
[perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`source` object owner for the caller-facing input string and resolved source
path:
[perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`command` object owner for invocation metadata such as `mode`, `json`,
`strict_mode`, and `target_language`:
[perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm).
Those same two public JSON/report surfaces now also share one bounded nested
`generated_output` object owner for whether the report invocation emitted HDL
artifacts:
[perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm).
Successful public check JSON reports now also have one bounded nested `result`
object owner for module identity plus basic summary counts:
[perl/FSM/Support/CheckResultContract.pm](perl/FSM/Support/CheckResultContract.pm).
Failed public check JSON reports now also have one bounded nested `diagnostic`
object owner for the core stable diagnostic fields, matched-only corpus keys,
optional extracted artifact paths, and nested support-accounting metadata:
[perl/FSM/Support/CheckFailureDiagnosticContract.pm](perl/FSM/Support/CheckFailureDiagnosticContract.pm).
Failed public normalized semantic JSON reports now explicitly reuse that same
bounded nested `diagnostic` owner too.
Successful public normalized semantic JSON reports now also have one bounded
nested `semantic` object owner for module/system metadata, signal analysis,
and the forward-IR projection:
[perl/FSM/Support/NormalizedSemanticPayloadContract.pm](perl/FSM/Support/NormalizedSemanticPayloadContract.pm).
That payload owner now advertises `optional_child_presence_keys` for
`composition` and `symbol_contract`, and the normalized semantic report
contract republishes the same family as
`success_semantic_optional_child_presence_keys` so embedders can discover those
optional success children without inferring them from prose.
For composition sources, the nested `semantic.composition` owner also
advertises bounded `children[]`, `children[].parameter_overrides[]`,
`generated_children[]`, `generated_children[].parameter_overrides[]`, and
`standalone_dt_children[]` shallow/alias entry key families. Standalone-DT child
entries include the current reusable-DT names, enable-family metadata, module
enable-family metadata, and nested multi-drive target metadata. Each child
entry's `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` summaries, and
the nested standalone-DT multi-drive assertion shape, remain delegated to their
existing bounded contracts:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm).
The composition-side `shared_datapath_candidates[]` collection is also
advertised there as an alias of the already bounded lowered-RTL
`composition_shared_datapath_candidates[]` candidate, contributor,
drive-intent, aggregate-enable, assertion, and bound-connection schemas instead
of duplicating those internals.
The nested `semantic.system_contract` summary inside that payload now also has
its own bounded owner for the explicit clock/reset contract keys emitted today:
[perl/FSM/Support/NormalizedSemanticSystemContract.pm](perl/FSM/Support/NormalizedSemanticSystemContract.pm).
The nested `semantic.explicit_system_contract` summary inside that payload now
also has its own bounded owner when the authored explicit contract is
preserved:
[perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm](perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm).
The nested `semantic.signal_analysis` summary inside that payload now also has
its own bounded owner for the current sanitized signal families plus the shared
core signal-entry keys emitted across direct and composition roots:
[perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm](perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm).
The nested `semantic.forward_ir` summary inside that payload now also has its
own bounded owner for the current sanitized forward semantic projections:
[perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](perl/FSM/Support/NormalizedSemanticForwardIRContract.pm).
The nested `semantic.forward_ir.lowered_rtl_ir` summary inside that branch now
also has its own bounded owner for the current lowered-RTL shell, including
the bounded `output_drive_families[]` entry schema, selector-conflict target
count/list metadata, the bounded `selector_conflict_targets[]` entry schema,
standalone-DT multi-drive target metadata, the bounded
`standalone_dt_multi_drive_targets[]` entry schema and nested
`multi_drive_assertion` metadata keys, and the current composition-only
extension keys. For composition roots, that same contract also advertises the
bounded `composition_shared_datapath_candidates[]` entry schema, optional
declared-type extension keys, contributor entries and `bound_connection_expr`
metadata, contributor `drive_intent` entries plus nested drive-intent
`rhs_enable_families[]` entries, aggregate enable-family entries,
aggregate-family contributors, and multi/same-value assertion metadata.
Contributor child `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir`
summaries remain delegated to their existing bounded contracts:
[perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm).
The nested `semantic.forward_ir.structural_rtl_ir` summary inside that branch
now also has its own bounded owner for the current structural-RTL shell,
including bounded `assignment_records[]` structured generated-enable entry
keys, bounded `auxiliary_assignments[]` scalar-string compatibility values,
bounded `ports[]` core entry keys, composition-top port extension keys,
bounded `nets[]` entry keys, generated-enable net `source`/`targets[]`
connectivity entry keys, and bounded `declared_links[]` plus `resolved_links[]`
entry keys, plus bounded shallow `instances[]` entry keys, nested
`instances[].interface_ports[]` entry keys, and nested
`instances[].parameter_overrides[]` core plus optional raw-value/value-metadata
extension keys, plus nested `instances[].port_bindings[]` core plus
typed-extension entry keys:
[perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm).
Direct roots now populate `structural_rtl_ir.nets[]` with declaration-only
internal storage/helper nets projected from the backend internal declaration
plan plus generated enable wires projected from the already-prepared direct
backend enable registries and assignment analysis. Those direct net entries
preserve width, signedness, state-model, and declared-type metadata where
available. Direct generated enable assignments now live in
`structural_rtl_ir.assignment_records[]` as machine-readable continuous
assignment records with structured `lhs`, `rhs`, rendered text, and
provenance. Generated-enable net entries now also populate structured
`source` objects for assignment-record drivers and structured `targets[]`
entries for direct nets consumed by another generated-enable assignment-record
RHS. `structural_rtl_ir.auxiliary_assignments[]` mirrors those rendered lines
as scalar strings for compatibility. The direct SystemVerilog top
state/standalone-DT generated-enable condition block is now rerouted through
those `StructuralRTLIR` assignment records by an explicit backend marker
handoff that is removed before final HDL is returned. Direct input ports
consumed by generated-enable assignment-record RHS ASTs now also expose
structured `targets[]` entries on `structural_rtl_ir.ports[]` using the same
assignment-record target endpoint shape as generated-enable net targets.
Direct output ports whose names match bounded lowered output-drive families now
also expose a structured `source` summary on `structural_rtl_ir.ports[]` with
`kind`, `signal_name`, `multiplexer_type`, `driver_count`, `driver_blocks`,
`rhs_values`, `driver_enable_signals`, and `family_enable_signals`. Broader
output-drive/always-block body consumer modeling remains outside that compact
summary. Direct instance/link selector
`R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirms direct roots intentionally
keep `instances[]`, `declared_links[]`, and `resolved_links[]` empty; populated
instances and links remain a composition-top structural contract. Selector
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` confirms broader/full direct
SystemVerilog rerouting through `StructuralRTLIR` is still outside that
projection until direct behavior-body, state-update, output, and assertion
regions are structurally owned. Direct VHDL backend/reroute work remains
outside the projection and is deferred by
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` until the SystemVerilog-backed
IAL0/IAL1/IAL2 path is feature complete.
The nested `semantic.forward_ir.intent_hir` summary inside that branch now
also has its own bounded owner for the current intent-hir shell plus the
current composition-only extension keys. For composition roots, that same owner
also advertises bounded alias key families for
`composition_children[]`, `composition_generated_children[]`, and
`composition_standalone_dt_children[]` by delegating to the already bounded
`semantic.composition` child and standalone-DT child schema owners. The
`composition_children[].parameter_overrides[]` and
`composition_generated_children[].parameter_overrides[]` alias key families are
likewise bounded and delegate to the structural instance parameter-override
schema owner. Nested child `intent_hir`, `lowered_rtl_ir`, and
`structural_rtl_ir`
summaries stay delegated to their existing bounded contracts:
[perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm).
The optional `semantic.symbol_contract` summary inside that payload now also
has its own bounded owner for symbol-rich sources:
[perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm).
The nested `semantic.module` summary inside that payload now also has its own
bounded owner for the core module keys plus the current optional metric-key
family:
[perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm).
The nested `semantic.composition` summary inside that payload now also has its
own bounded owner for composition sources, including bounded
`children[].parameter_overrides[]` and
`generated_children[].parameter_overrides[]` alias key families that delegate to
`semantic.forward_ir.structural_rtl_ir.instances[].parameter_overrides[]`:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm).
The generated-child public-export hardening edge now publishes
`parameter_override_count`, `parameter_overrides[]`, and bounded
parameter-override alias key families for
`semantic.composition.generated_children[]` and
`semantic.forward_ir.intent_hir.composition_generated_children[]`.
The symbol-contract constants public-export hardening edge now publishes
bounded scalar/list value key families for
`semantic.symbol_contract.constants` and
`semantic.forward_ir.intent_hir.symbol_contract.constants`. Every advertised
constant value carries `kind`; scalar values add `payload`, and list values add
`items`. That constants edge did not widen enum/type nested schemas,
package-import internals, or full normalized semantic export stabilization.
The symbol-contract enum public-export hardening edge now publishes enum
value-kind families for `semantic.symbol_contract.enums` and
`semantic.forward_ir.intent_hir.symbol_contract.enums`: enum entries are
member-payload maps, and dynamic enum members carry scalar payloads.
The symbol-contract type public-export hardening edge now publishes bounded
recursive type-entry schema metadata for `semantic.symbol_contract.types` and
`semantic.forward_ir.intent_hir.symbol_contract.types`: scalar entries carry
`kind`, `signed`, `width`, and optional `state_model`, while aggregate entries
carry recursive `items` or `members` plus `member_order`.
The symbol-contract package-import public-export hardening edge now publishes
explicit scalar package-name entry metadata for
`semantic.symbol_contract.package_imports` and
`semantic.forward_ir.intent_hir.symbol_contract.package_imports`.
`package_import_entry_value_kinds` is `[scalar_package_name]`, and
`package_import_entry_value_meaning` is `authored package-import package-name
string` on the top-level contract surface. Inside grouped
`presence_key_family_map` discovery maps, the corresponding
`*_package_import_entry_value_meaning` entries are single-element arrays
containing that same meaning string, preserving the invariant that every
grouped family-map value is array-valued. That edge does not expose raw
`FSM::Package::Spec` internals,
package source AST, package symbols, VHDL package declaration/emission, or full
normalized semantic export stabilization.
The direct VHDL scaffold now lowers generated two-state vector `bit [N:0]`
internal declarations to VHDL `std_logic_vector` signals while preserving
scalar `bit` as `std_logic`. Typed read-only direct-root two-state ports that
generate `input bit NAME` or `input bit [N:0] NAME` now lower to VHDL
`std_logic` / `std_logic_vector` input ports. Typed read-only non-signed
four-state ports that generate `input logic NAME` or
`input logic [N:0] NAME` now lower to VHDL `std_logic` /
`std_logic_vector` input ports. It also lowers generated vector `logic signed`
internal declarations to VHDL `signed` signals and generated signed vector
direct-root ports to VHDL `signed` ports. Same-width signed vector
addition/subtraction/multiplication/division/modulo RHS assignments now lower
as native signed VHDL arithmetic when the target and all operands are same-width
signed vectors, with multiplication/division/modulo target-width resized. The
scaffold also lowers signed vector numeric-literal addition/subtraction and
multiplication/division/modulo RHS assignments through target-width
`to_signed` literal conversion, with multiplication/division/modulo resized to
the target width. The direct VHDL scaffold also lowers the bounded generated
AMBA wrap arithmetic family in `fsm/amba_requester.fsm`, including
`beats_total_q * addr_step_q`, `addr_q - addr_q % (beats_total_q * addr_step_q)`,
and the matching wrap-high expression, through explicit unsigned target-width
resizes. Bounded direct aggregate-output packed-vector lowering is also shipped
for `t/corpus/direct_rhs_concat_target_autogrowth.fsm` and
`t/corpus/direct_aggregate_constant_target_autogrowth.fsm`; the maintained
supported direct-root VHDL sweep now runs clean. The first bounded composition
VHDL structural top is also shipped for the C3 external-RTL literal/concat
fixture in `t/corpus/composition_intent_integer_literals.fsm`, emitting VHDL
concurrent literal/concat assignments and an `entity work.uart_tx` port map
without SystemVerilog `module`/`assign` syntax. A second bounded composition
VHDL structural top is shipped for the C1 standalone-DT passthrough fixture in
`t/corpus/standalone_dtc_explicit_system_autowire.fsm`, emitting the VHDL child
entity plus a top-level `entity work.standalone_route_src` port map for the
explicit passthrough ports. The same bounded C1 standalone-DT family also
emits scalar integer generic maps such as `WIDTH => 16`, scalar expression
generic maps such as `EXPR_WIDTH => (8 + 1)`, and one-bit sized bitstring
generic maps such as `ENABLE_DEFAULT => '1'`, and multi-bit sized bitstring
generic maps such as `RESET_VALUE => "10100101"` before the standalone-DT
child port map; packed-list generic maps such as
`LANES => "1010010100111100"` and packed-map generic maps such as
`FRAME => "101"` also emit before that port map. The bounded C2 generated-FSM scalar-autowire top
is also shipped for `t/corpus/implicit_composition_system_autowire.fsm`, emitting
VHDL-safe generated-child shared-datapath export ports/assignments, scalar
structural signals, and both generated child entity port maps. The same
bounded C2 generated-FSM family also emits scalar integer generic maps such as
`WIDTH => 16` and scalar expression generic maps such as
`EXPR_WIDTH => (16 + 1)`, one-bit sized bitstring generic maps such as
`ENABLE_DEFAULT => '1'`, multi-bit sized bitstring generic maps such as
`RESET_VALUE => "10100101"`, and resolved packed aggregate generic maps such
as `LANES => "1010010100111100"` and `FRAME => "101"` before a generated
child port map. The bounded
APB/C4 generated-FSM top is shipped for `fsm/apb_tb.fsm`, emitting
`apb_requester` and `apb_completer` child VHDL entities, vector APB structural
signals, deterministic shared-datapath sink signals, and both child entity port
maps. The same APB/C4 family also emits scalar integer generic maps such as
`TIMEOUT_CYCLES => 8` and `TIMEOUT_CYCLES => 6`, scalar expression generic maps
such as `TIMEOUT_CYCLES => (4 + 1)` and `TIMEOUT_CYCLES => (3 + 3)`, and
one-bit sized bitstring generic maps such as `ENABLE_DEFAULT => '1'`, plus
multi-bit sized bitstring generic maps such as `RESET_VALUE => "10100101"` and
`RESET_VALUE => "00111100"`, and resolved packed aggregate generic maps such
as `LANES => "0011110010100101"` and `FRAME => "101"` before the
requester/completer child port maps. Qualified package constants in the same
APB/C4 subset are resolved before VHDL emission, so `param_pkg.TIMEOUT_8` and
`param_pkg.RESET_A5` emit `TIMEOUT_CYCLES => 8` and
`RESET_VALUE => "10100101"` without leaking package tokens.
Signed scalar division/modulo and mixed signed/unsigned scalar arithmetic
remain explicitly fail-closed; full aggregate
VHDL record/array lowering, broader generated-FSM/C4 composition VHDL beyond
the exact shipped fixtures, internal-net-heavy/bus-heavy tops beyond APB,
generic-map families outside the shipped external-RTL scalar literal/expression,
metadata-backed one-bit sized bitstring, multi-bit sized bitstring
literal/resolved-package-constant, resolved packed aggregate actuals,
standalone-DT scalar integer/expression/one-bit sized bitstring/multi-bit sized bitstring/packed-list/packed-map actuals and generated-FSM scalar
integer/expression, one-bit sized bitstring, multi-bit sized bitstring, and
resolved packed aggregate actuals, plus APB/C4 generated-FSM scalar integer,
scalar expression, one-bit sized bitstring, and multi-bit sized bitstring
actuals, resolved packed aggregate actuals, and resolved package-backed
actuals, external-RTL aggregate actuals that do not lower to one packed
literal, standalone-DT aggregate actuals that do not lower to one packed
literal, APB/C4 aggregate actuals that do not lower to one packed literal,
generated-FSM aggregate actuals that do not lower to one packed literal now
locked fail-closed before VHDL emission,
VHDL package
declaration/emission, GHDL validation, broad expression parity beyond the
shipped AMBA wrap family, package-import internals, unrelated forward-IR
payloads, and full normalized semantic export stabilization remain out of scope
until later exact leaves own them.
Package-root direct HDL generation is locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.100.1`: `?pkg` roots remain import-only
declaration containers, not standalone SystemVerilog or VHDL package output
roots.
Declared aggregate structural VHDL ports/nets/types are locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.101.1`: composition tops with declared
aggregate structural surfaces do not emit VHDL record/array declarations until a
future exact aggregate-lowering leaf owns them.
GHDL validation blocker reconfirmation is locked by
`BACKEND-API-VALIDATION-FRONTIER.102.1`: `ghdl` is unavailable in the current
environment, so external HDL validation remains SystemVerilog-only until a
future exact GHDL lane can run the tool.
Completed backend/API frontier leaf
`BACKEND-API-VALIDATION-FRONTIER.132` exhausted the active backend/API selector:
the supported-smoke `.fsm` corpus passes under `--language vhdl`, `ghdl` remains
unavailable, and remaining broad backend/API directions require future exact
owners before implementation. Completed selector leaf
`ARCHITECTURE-DEBT-FRONTIER.3` deferred ISF
parser/lowerer extraction until a stable family is proven by a future exact
owner. Completed implementation leaf
`R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2` projects top-level direct state
and standalone-DT enable wires into `structural_rtl_ir.nets[]` without
claiming DT-specific/LHS WEN/EN wires, assignment connectivity, instances,
links, auxiliary assignments, or rerouting HDL emission. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1` projects direct
DT-specific and LHS-level WEN/EN wires into `structural_rtl_ir.nets[]` as
declaration-only one-bit nets without claiming assignment connectivity,
instances, links, auxiliary assignments, or rerouting HDL emission. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2` projects
already-rendered direct generated enable assignment lines into
`structural_rtl_ir.auxiliary_assignments[]` as scalar strings without claiming
assignment records, direct net connectivity, instances, links, or rerouting
HDL emission. Completed implementation leaf
`R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2` projects those same generated
enable assignments into machine-readable `structural_rtl_ir.assignment_records[]`
entries while retaining `auxiliary_assignments[]` as the compatibility mirror
and without rerouting HDL emission. Completed implementation leaf
`R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2` populates generated-enable direct
net `source` objects for assignment-record drivers and `targets[]` entries for
direct nets consumed by another generated-enable assignment-record RHS.
Completed implementation leaf `R11-DIRECT-STRUCTURAL-HDL-REROUTING.2`
reroutes the direct SystemVerilog top state/standalone-DT generated-enable
condition block through `StructuralRTLIR` assignment records by using explicit
backend markers that are removed before final HDL is returned. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2`
populates direct input-port generated-enable RHS target connectivity on
`structural_rtl_ir.ports[]` without changing HDL emission. Completed
implementation leaf `R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2` populates
direct output-port `source` summaries from lowered output-drive families
without changing HDL emission. Completed selector leaf
`R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirms direct roots intentionally
keep empty instance/link arrays and no direct implementation leaf is warranted
today. Completed selector leaf
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` defers broader/full direct
SystemVerilog rerouting until direct behavior-body, state-update, output, and
assertion regions have exact structural ownership. Completed selector leaf
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` defers direct VHDL backend/reroute
work until the SystemVerilog-backed IAL0/IAL1/IAL2 path is feature complete.
Completed
implementation leaf `ARCHITECTURE-DEBT-FRONTIER.2.1` projects direct backend
storage/helper declaration-plan entries into `structural_rtl_ir.nets[]`
without rerouting HDL emission. The shipped literal-literal positive modulo
edge lowers
an 8-bit non-signed `REM = (% 2 3)` fixture to
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod to_unsigned(3, 8), 8));`.
The shipped literal-literal positive division edge
lowers an 8-bit non-signed `QUOT = (/ 2 3)` fixture to
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / to_unsigned(3, 8), 8));`.
The shipped literal-literal positive multiplication edge lowers an 8-bit non-signed `PROD = (* 2 3)` fixture to
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * to_unsigned(3, 8), 8));`.
The shipped literal-first positive modulo edge lowers an
8-bit non-signed `REM = (% 2 A)` fixture to
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod unsigned(A), 8));`.
The shipped literal-first positive division edge lowers
an 8-bit non-signed `QUOT = (/ 2 A)` fixture to
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / unsigned(A), 8));`.
The shipped literal-first positive multiplication
edge lowers an 8-bit non-signed `PROD = (* 2 A)` fixture to
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * unsigned(A), 8));`.
The shipped signal-first positive
modulo edge lowers an 8-bit non-signed
`REM = (% A 2)` fixture to
`REM <= std_logic_vector(resize(unsigned(A) mod to_unsigned(2, 8), 8));`.
The shipped signal-first positive division edge lowers an 8-bit
non-signed `QUOT = (/ A 2)` fixture to
`QUOT <= std_logic_vector(resize(unsigned(A) / to_unsigned(2, 8), 8));`.
The shipped signal-first positive multiplication edge lowers an 8-bit non-signed
`PROD = (* A 2)` fixture to
`PROD <= std_logic_vector(resize(unsigned(A) * to_unsigned(2, 8), 8));`.
Broad VHDL expression-literal parity remains deferred beyond this bounded
literal-literal arithmetic subset.
The shipped non-signed negative modulo edge lowers an 8-bit
non-signed `REM = (% A -2)` fixture to
`REM <= std_logic_vector(resize(unsigned(A) mod unsigned(to_signed(-2, 8)), 8));`.
The shipped non-signed division edge
lowers an 8-bit non-signed `QUOT = (/ A -2)` fixture to
`QUOT <= std_logic_vector(resize(unsigned(A) / unsigned(to_signed(-2, 8)), 8));`.
The shipped non-signed multiplication edge
lowers an 8-bit non-signed `PROD = (* A -2)` fixture to
`PROD <= std_logic_vector(resize(unsigned(A) * unsigned(to_signed(-2, 8)), 8));`.
The shipped non-signed subtraction edge lowers an 8-bit non-signed
`DIFF = (- A -1)` fixture to
`DIFF <= std_logic_vector(unsigned(A) - unsigned(to_signed(-1, 8)));`.
Broad VHDL expression parity, aggregate, package, GHDL, composition-parity,
and normalized semantic stabilization work remain deferred until exact leaves
own them.
The manifest is still not a full normalized semantic export stabilization
promise.
The manifest-facing stable diagnostic-code registry now has its own explicit
bounded contract owner in
[perl/FSM/Support/DiagnosticCodeRegistryContract.pm](perl/FSM/Support/DiagnosticCodeRegistryContract.pm),
so downstream tools can discover the public diagnostics sibling keys and stable
entry keys without treating the whole diagnostics tree as frozen.
The capability manifest shell now has that same explicit split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
builds the JSON, while
[perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm)
owns the bounded top-level and first nested section key lists advertised under
`manifest_contract`.
That shell contract now explicitly includes the first nested
`support_accounting` key list too, so machine consumers do not have to
special-case the corpus-backed section while discovering the current bounded
manifest shape.
The manifest's `support_accounting` section now also advertises that same
bounded owner through `support_accounting.section_contract`, while keeping the
existing inline support-accounting payload and catalog metadata in place for
compatibility.
The manifest's `embedding` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current in-process embedding surfaces, while
[perl/FSM/Support/EmbeddingContract.pm](perl/FSM/Support/EmbeddingContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`embedding.section_contract` without flattening the whole embedding tree into
one accidental API.
The current embedding children include
`embedding.debug_runtime`, owned by
[perl/FSM/Support/DebugRuntimeContract.pm](perl/FSM/Support/DebugRuntimeContract.pm),
and `embedding.hdl_generator_facade`, owned by
[perl/FSM/Support/HDLGeneratorFacadeContract.pm](perl/FSM/Support/HDLGeneratorFacadeContract.pm),
and `embedding.isf_public_interface`, owned by
[perl/FSM/Support/ISFPublicInterfaceContract.pm](perl/FSM/Support/ISFPublicInterfaceContract.pm),
and `embedding.serializable_generation_result_snapshot`, owned by
[perl/FSM/Support/SerializableGenerationResultSnapshot.pm](perl/FSM/Support/SerializableGenerationResultSnapshot.pm),
so callers can discover the shipped in-process runtime, facade, and report
boundaries from the manifest instead of inferring them from Perl implementation
files.
The snapshot child advertises the JSON-safe `HDLGenerator` result summary
contract directly, while the existing
`embedding.serializable_plan_reports.generation_result_snapshot_contract`
reference remains available for plan/report compatibility.
The facade child reports `default_generation_mode: flattened_debug_first` and
does not expose a public `generation_mode` constructor option; structured
non-flattened generation remains a separate backend path to implement later.
The manifest's `diagnostics` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current registry/check surfaces, while
[perl/FSM/Support/DiagnosticsContract.pm](perl/FSM/Support/DiagnosticsContract.pm)
owns the bounded top-level, scalar-string, and stable-code entry families
advertised through `diagnostics.section_contract` without flattening the whole
diagnostics tree into one accidental API.
The manifest's `producer` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current FSMGen identity/build metadata, while
[perl/FSM/Support/ProducerContract.pm](perl/FSM/Support/ProducerContract.pm)
owns the bounded top-level, scalar-string, and boolean field families
advertised through `producer.section_contract`. That keeps tool/build identity
discoverable without pretending this is already a package-manager release API.
The manifest's `semantic_exports` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current bounded semantic interchange surfaces, while
[perl/FSM/Support/SemanticExportsContract.pm](perl/FSM/Support/SemanticExportsContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`semantic_exports.section_contract`. That keeps `normalized_semantic_json`
discoverable without pretending every future semantic export format is already
frozen.
The manifest's `backend_validation` section now follows that split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current backend validation surfaces, while
[perl/FSM/Support/BackendValidationContract.pm](perl/FSM/Support/BackendValidationContract.pm)
owns the bounded top-level and nested contract-owner map advertised through
`backend_validation.section_contract`. That keeps
`systemverilog_external` discoverable without pretending every future backend
validation lane is already frozen.
The manifest's `language_surface` section now follows the same pattern:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the authored-surface summary, while
[perl/FSM/Support/LanguageSurfaceContract.pm](perl/FSM/Support/LanguageSurfaceContract.pm)
owns the bounded top-level and first nested section-key lists advertised
through `language_surface.surface_contract` without pretending the whole
authored language is frozen. The bounded `language_surface.file_surfaces`
section advertises the shipped `.fsm`/`.isf`/`.ppif` file suffixes, including
the `.ppif` first-slice rule that IAL2 lowers through generated `.isf` before
generated `.fsm`, and publishes the supported CLI modes for each shipped
suffix.
The manifest's `documentation` section now has the same split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
still publishes the current doc pointers, while
[perl/FSM/Support/DocumentationContract.pm](perl/FSM/Support/DocumentationContract.pm)
owns the bounded top-level and path-list contract advertised through
`documentation.section_contract` without freezing the exact file lists forever.

## Assignment semantics (quick reference)
- `A <- expr`: synchronous/flopped assignment where `A` names the flop output/Q value.
- `A <= expr`: synchronous/flopped variant where `A` names the D-input/next-value side.
- `A = expr`: combinational assignment.
- Safety rule: combinational `=` cannot create direct/indirect RHS feedback to same LHS.
- Safety rule: D-input-named `<=` / `<=-` cannot read the same LHS name from the RHS or guard; use `<-` for ordinary register feedback. In default mode, legacy `<=+` is accepted as an alias for `<=-`; strict mode rejects `<=+` and points to preferred `<=-`.

## README maintenance policy
- Keep `README.md` as the canonical onboarding hub.
- Update it when any of the following changes materially:
  - project objective/scope,
  - document set or purpose,
  - key file paths / architecture entrypoints,
  - onboarding workflow.
- It does **not** need to be updated on every commit—only when meaningful for onboarding accuracy.

## Fresh session shortcut
For a new engineering session, the preferred one-line instruction is:

```text
Read SESSION_BOOTSTRAP.md and start from there.
```

That startup ritual must still honor the session safety invariant above:
`COMMIT.md` is mandatory, and every completed task, slice, or lane must be committed before the next one starts.
