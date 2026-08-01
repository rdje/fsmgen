# IAL2 Foundations Backlog

### IAL2 Protocol And Platform Intent Exploration

Status: first bounded IAL2 implementations and `.ppif` Valid-Ready parser/CLI
surface shipped; broader IAL2 remains backlog. IAL2 feature completeness on the
SystemVerilog-backed path is the current priority before VHDL backend/reroute
work resumes.

Historical task-tree record:
[IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION](../../tasks/IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.md).
That tree is closed; future IAL2 behavior changes need a new task-tree leaf
before implementation.

Active frontier:
[IAL2-FEATURE-COMPLETENESS-FRONTIER](../../tasks/IAL2-FEATURE-COMPLETENESS-FRONTIER.md)
owns the next IAL2 feature-completeness work. Its first selector audited the
shipped `.ppif` Valid-Ready single/bundle surface and moved the frontier to
the first AXI manager rule-subset selection/pre-code contract. That selector
chose outstanding-capacity plus acceptance/status feedback as the first
post-Valid-Ready manager subset. The completed readiness audit for that subset
found no IAL1 or IAL0/SystemVerilog prerequisite blocker and selected an
in-process generator as the first behavior-bearing capacity/status slice
before public `.ppif` syntax. That in-process generator is now shipped. The
public `.ppif` capacity/status parser/CLI first slice is now shipped for one
manager object with sample, manifest, support-accounting, semantic JSON, check
JSON, generated review artifacts, HDL, `--verify-hdl`, mdBook, and focused
diagnostics. The next AXI manager subset is selected as ID-family declaration
and static validation, and the additive optional `(id-families ...)` `.ppif`
extension is now shipped for the existing capacity/status object with report
metadata and unchanged generated `.isf`, generated `.fsm`, and HDL behavior.
The next AXI manager subset is selected as a machine-readable AST/structural
logical read/write transaction envelope and static-validation contract; the
readiness audit selects an additive optional `(transactions ...)` static/report
metadata extension under the existing `manager-capacity-status` object. That
optional transaction-envelope metadata slice is now shipped with a separate
sample, structural report entries, check JSON and semantic JSON source
identity, and initially unchanged generated `.isf`, generated `.fsm`, and HDL
behavior.
The transaction event dispatch and direction fan-in slice is now shipped for
that same object. Distinct per-transaction request/completion events become
generated IAL1 inputs, multi-event direction groups use OR fan-in guards, the
existing IAL1/IAL0/SystemVerilog path carries the behavior, and schedule JSON
additively reports `transaction_event_dispatch` metadata. The concrete
transaction ID assertion slice is now shipped: transactions with concrete
requested IDs declare used ID-family request/response ID signals as generated
IAL1 inputs, lower assertion-only checks to `.fsm` `+assert` carriers, emit
verification-only SystemVerilog assertions, and report
`id_response_rule_engine` metadata. Auto-ID allocation, ID release, response
demux, ordering, bursts, queued policy, aliases, full-manager behavior, and
VHDL remain residue. The next selector chose AXI manager auto-ID
lifecycle/request-ID drive readiness as the next subset. Completed readiness
audit `.20` concluded that the IAL1/IAL0/SystemVerilog substrate can carry a
bounded scalar request-ID lifecycle, but auto-ID allocation must not be
inferred directly from ID width or existing `(id auto)` syntax. Completed
selector `.21` chose an explicit optional `(auto-id-lifecycle (write (pool
...)) (read (pool ...)))` clause. Completed implementation leaf `.22` shipped
that parser/report metadata and static-validation slice with unchanged
generated `.isf`, `.fsm`, and HDL behavior. Completed implementation leaf
`.23` ships bounded request-ID drive behavior for explicit auto-ID lifecycle
families. Completed selector `.24` chooses AXI generated response-demux
readiness as the next exact subset. Completed readiness audit `.25` selects a
bounded write `BID` response-demux public contract selector first, because
existing transaction `completion` names are authored inputs and must not be
silently reinterpreted as generated demux signals. Completed selector `.26`
chooses explicit write-only `(response-demux ...)` syntax. Completed
implementation leaf `.27` ships parser/report metadata and static validation
for that explicit opt-in while keeping generated `.isf`, `.fsm`, and HDL
behavior unchanged. Completed readiness audit `.28` concludes that generated
write `BID` demux completion names need an IAL1 rule-owned one-cycle pulse
action first. Completed implementation leaf `.29` ships bounded IAL1
`(pulse target)` rule actions that lower as `<1` pulse-domain assignments.
Completed implementation leaf `.30` ships generated write `BID`
response-demux behavior through those pulse completions. Completed selector
`.31` selects `.32` to align `auto_id_lifecycle.residue` with that shipped
behavior before larger ordering/read-response work. Completed implementation
leaf `.32` ships that report-residue alignment. Completed selector `.33`
selects `.34` as the AXI same-ID ordering readiness audit. Completed
readiness audit `.34` selects `.35` as the bounded auto-ID same-ID avoidance
assertion/report slice. Completed implementation leaf `.35` ships that
boundary and advances the active leaf to `.36`, the next selector.
Selected IAL2 slices may include explicit IAL1 or
IAL0/SystemVerilog prerequisites when those prerequisites are needed for
clean, reviewable lowering.

Evaluation note:
[IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION](../../IAL2_PROTOCOL_PLATFORM_INTENT_EVALUATION.md).

Goal: decide whether an intent layer above current ISF has enough independent
semantic value to exist.

Current boundary: FSMGen names `.fsm` as Intent Abstraction Layer 0 (`IAL0`)
and current `.isf` as Intent Abstraction Layer 1 (`IAL1`). `IAL2` now has a
first bounded shipped surface for one AXI Valid-Ready protocol intent object,
the first protocol-neutral Valid-Ready sample, the AXI AW/W multi-channel
Valid-Ready bundle, the protocol-neutral dual-channel Valid-Ready bundle, and
one AXI manager capacity/status shell through public `.ppif`, including
optional static ID-family metadata,
optional structural transaction-envelope metadata with per-transaction event
dispatch/fan-in, concrete transaction ID request/response assertions,
metadata-first dynamic transaction-ID parser/report support, generated
bounded single-active dynamic write transaction-ID capture plus `BID` response
matching plus same-cycle release-and-recapture for one explicit
`response-demux.write` dynamic write transaction, and
generated bounded single-active dynamic read transaction-ID capture plus
single-beat `RID` response matching with same-cycle release-and-recapture plus
burst-last `RID && RLAST` response matching for one explicit
`response-demux.read` dynamic read transaction, and
bounded scalar dynamic read-data capture over that generated dynamic read
response-demux for exactly one dynamic read transaction. `.238` now also ships
report-only dynamic raw-`ARLEN` burst-length capture for that generated
dynamic last-beat read-data boundary, and `.240` ships generated dynamic
runtime beat-count/`RLAST` validation for the same single-active dynamic
last-beat shape. `.236` added the bounded focused validation target for the
shipped dynamic transaction-ID family.
Broader IAL2 still must justify itself with semantics above individual
transactions, not only syntax convenience. Its generic file surface remains
protocol/platform-generic, and an IAL2 file may select a protocol or platform
vocabulary inside the file.

IAL0, IAL1, IAL2, and this book describe backend-language-neutral contracts,
not Perl-only implementation APIs. The current Perl 5 codebase is the
reference implementation/oracle. Future Rust, Rust/Wasm, browser-capable
JavaScript, and Dart/web implementations should preserve the same source
syntax, generated review artifacts, reports, diagnostics, and HDL behavior
through suitable host abstractions rather than creating parallel semantics. Decision
[0018](../../decisions/0018-ial-contracts-are-backend-language-neutral.md)
records this rule.
All future variants and implementations must satisfy FSMGen's public
contracts. The portability goal is identical in-memory behavior on any
suitable platform/environment, with feature, functionality, diagnostic,
semantic-introspection, example, fixture, and test parity against the Perl
reference/oracle. The book must grow into the language-independent blueprint
for building a conforming FSMGen variant in language X.
The active owner for that portability work is
[BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER](../../tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md).
Its `.2.1` leaf captures that doctrine. Its `.2.2` readiness audit separates
backend-neutral public contracts from current Perl implementation details and
selects exact future leaves for the portable API, host abstraction, parity
harness, book blueprint, extension boundary, and first implementation-language
selection. The `.2.3` leaf selected a portable in-memory request/result API
family with JSON-safe envelopes and virtual artifacts. The `.2.4` leaf selected
the host abstraction behind that API: pure in-memory hosts provide a
`source_catalog` plus `artifact_sink`, while the current filesystem CLI remains
an adapter for `--path`, `FSMLIB`, current-directory lookup, `--outdir`,
`--output`, and verification-output directories. The `.2.5` leaf selected the
Perl-reference parity harness and normalization rules: future variants compare
normalized public contracts against the Perl oracle across corpus partitions,
reports, diagnostics, support accounting, artifacts, HDL behavior, and
resource-sensitive fixtures. The `.2.6` leaf selected the mdBook language-X
implementation blueprint structure and added Chapter 15 as the public
implementation-blueprint entry point. The `.2.7` leaf audited typed extension
and plugin portability; its selected boundary keeps current typed
extensions as a Perl-reference surface and leaves extension/plugin support out
of scope for the first non-Perl implementation experiment unless a future exact
task selects a portable extension API first. The `.2.8` leaf selected
the same-repository Rust/Rust-Wasm portable API smoke as the first non-Perl
implementation experiment. The `.3.1` leaf scaffolded the additive
`fsmgen_portable_api` Rust contract crate with an incomplete capability
profile. The `.3.2` leaf added exactly one direct `.fsm` check smoke:
`feature.direct_sreset_active_high` returns a JSON-safe check result with no
HDL emission and matched `supported_smoke` support accounting. Other Rust check
sources fail closed with `E_PORTABLE_RUST_UNSUPPORTED_CHECK_SOURCE`, and
non-check operations fail closed with
`E_PORTABLE_RUST_UNIMPLEMENTED_OPERATION`. The crate is not wired into
`bin/fsmgen`, Perl manifests, generated HDL, package installation, or shipped
runtime behavior. The `.3.3` leaf added the first Perl-oracle parity smoke for
that result through a test-only Rust projection binary and a focused normalized
comparison against the Perl check-JSON oracle.
For SystemVerilog-to-Verilog portability, the default is FSMGen-owned
generation/lowering rather than a mandatory external converter. Tools such as
`sv2v` are future audit candidates only: they may become optional validation
aids, or selected dependencies only if a later owned audit proves exceptional
quality and coverage.
Downstream-visible changes must keep the codebase, downstream
handoff/integration docs, public contracts, capability-manifest metadata,
support-accounting catalog entries, tests, explicit deferrals, and this book
in lockstep for every downstream consumer.

Decision `0016` selects `.ppif` (Protocol/Platform Intent Format) as the first
public generic IAL2 file suffix. Earlier candidates `.pif` and `.ppi` are not
first implementation suffixes.

Protocol-specific extensions such as `.axi`, `.chi`, `.ace`, `.ahb`, `.apb`,
`.atb`, `.smbus`, or `.i2s` may also be accepted later as vocabulary/profile
aliases over the same IAL2 model. They are not separate layers and do not get
direct-lowering privileges.

The mandatory lowering chain is `IAL2 -> IAL1/.isf -> IAL0/.fsm -> HDL`.
Direct `IAL2 -> IAL0` lowering is forbidden.

The first worthwhile areas to investigate are
reusable protocol-level intent objects, such as APB/AXI transaction templates,
and platform/resource mapping decisions that choose among legal ISF schedules
or resource allocations. Aliases, macros, wrappers, and sugar without a
distinct runtime model should stay inside IAL1 or remain out of the language.

Current evaluation: IAL2 now has a first in-process behavior-bearing slice for
an AXI Valid-Ready contract object, a first public `.ppif` parser/CLI slice for
that same object shape, protocol-neutral Valid-Ready one-channel and
dual-channel bundle samples, AXI AW/W multi-channel Valid-Ready bundle
behavior, and a public `.ppif` AXI manager capacity/status shell with
reviewable generated `.isf` and `.fsm` artifacts plus optional ID-family
metadata, transaction-envelope
metadata, per-transaction event dispatch/fan-in, and concrete transaction ID
request/response assertions. It also ships optional auto-ID lifecycle
bounded-pool parser/report metadata plus bounded request-ID drive behavior
for explicit lifecycle families.
Future implementation leaves must choose exact owners for the next protocol
rule subset, additional `.ppif` syntax, or aliases; a hand-written reusable
`.fsm` or `.isf` library alone is useful but not enough to justify IAL2.

The repo-local tracked raw AXI reference for future bounded probes is
`docs/vendor/arm/amba/axi/IHI0022_L_2025-08_AMBA_AXI_Protocol_Specification.pdf`.
It is evidence for future task-tree-owned protocol-intent work, not a shipped
PDF/spec extraction capability.

Additional tracked raw standards references are available for future
task-tree-owned probes:

- `docs/vendor/accellera/systemrdl/SystemRDL_2.0_Jan2018.pdf`
- `docs/vendor/accellera/pss/Portable_Test_Stimulus_Standard_v3.0.pdf`
- `docs/vendor/accellera/uvm/UVM_Class_Reference_Manual_1.2.pdf`
- `docs/vendor/accellera/uvm/uvm_users_guide_1.2.pdf`

They are local reference artifacts only. They do not ship SystemRDL, PSS, UVM,
PDF extraction, parser, lowering, scheduler, or HDL behavior.

Completed evidence probe:
[AXI-VALID-READY-INTENT-PROBE](../../tasks/AXI-VALID-READY-INTENT-PROBE.md)
extracted the first valid/ready source-anchor evidence inventory without
selecting parser, lowering, `.fsm`, or HDL implementation behavior.

Evidence note:
[AXI_VALID_READY_INTENT_PROBE](../../AXI_VALID_READY_INTENT_PROBE.md)
records the AXI Valid-Ready anchors, source facts, inferred candidate model,
explicit abstractions, unsupported residue, and no-implementation status. It
is evidence for a future task-tree-owned IAL2 design/probe leaf, not a shipped
PDF/spec extraction capability and not an IAL2 implementation.

ID/order evidence note:
[AXI_ID_ORDERING_RULE_EVIDENCE_PROBE](../../AXI_ID_ORDERING_RULE_EVIDENCE_PROBE.md)
records the first AXI ID/order/concurrency source anchors for future manager
rule-engine work. The note covers ID families, outstanding transactions,
same-ID response ordering, response matching through `BID`/`RID`,
read-data interleaving, write-data sequencing, interconnect ID remapping, and
explicit residue. It confirms that Easy mode should not be reduced to
one-transaction-at-a-time behavior; concurrency belongs in the manager, backed
by source-anchored ID allocation, ordering, matching, interleaving, and
capacity-feedback rules.

Rule-matrix design/probe:
[AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE](../../AXI_MANAGER_RULE_MATRIX_DESIGN_PROBE.md)
maps the captured Valid-Ready and ID/order evidence into a first future AXI
manager rule responsibility matrix. It classifies candidate responsibilities
as static authoring checks, generated scheduler/scoreboard behavior, runtime
assertions, environment assumptions, or unsupported residue. It still selects
no source syntax, parser, lowering, `.isf`, `.fsm`, HDL, assertion text, queue
default, or ID allocation algorithm.

First post-Valid-Ready manager subset:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_SUBSET_SELECTION.md)
selects outstanding transaction capacity plus acceptance/status feedback as
the next AXI manager rule family. The selected source anchors are `A1.1`,
`A1.2`, and `A5.1`. The subset is expected to expose explicit read/write
`max-pending` depths, `try`-style acceptance feedback, full/pending/slots
status, and a capacity-only blocked-reason vocabulary while preserving
generated `.isf` and `.fsm` review artifacts before SystemVerilog HDL. It is
now shipped as a bounded capacity/status shell through an in-process generator
and public `.ppif` parser/CLI sample. It does not claim ID allocation,
ordering, interleaving, response matching, burst assembly, channel expansion,
`blocking`/`queued` policy behavior, profile aliases, or VHDL backend work.
The next manager behavior remains behind a selector.

Capacity/status readiness audit:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_READINESS_AUDIT.md)
finds that existing IAL1 actor storage, status-output, rule/update, scheduled
`.fsm`, and SystemVerilog generation surfaces can carry the first
capacity/status shell. The selected first implementation boundary is an
in-process IAL2 generator, tentatively
`FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus`, not public `.ppif`
syntax. The generator should accept a structured contract hash with explicit
read/write `max-pending` depths, `submit_policy => try`, abstract submit and
completion events, namespaced status outputs, and source anchors for `A1.1`,
`A1.2`, and `A5.1`. It must emit reviewable generated `.isf` before generated
`.fsm`, then use the existing SystemVerilog path. Public `.ppif`
capacity/status syntax, profile aliases, IDs, ordering, response matching,
bursts, queued/blocking policies, and VHDL remain future exact-owner work.

Capacity/status in-process generator slice:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_GENERATOR_FIRST_SLICE.md)
ships `FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus` as the first AXI
manager capacity/status IAL2 generator. It is an in-process API, not public
`.ppif` syntax:

```perl
use FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus;

my $result = FSM::IAL2::ProtocolIntent::AxiManagerCapacityStatus->new()->generate({
    name              => 'axi0',
    intent_name       => 'axi_manager_capacity_status',
    protocol          => 'axi4',
    submit_policy     => 'try',
    clock             => 'clk',
    reset             => { signal => 'rst_n', active_low => 1, async => 1 },
    read_max_pending  => 4,
    write_max_pending => 2,
    read_submit       => 'axi0_read_submit',
    read_complete     => 'axi0_read_complete',
    write_submit      => 'axi0_write_submit',
    write_complete    => 'axi0_write_complete',
    status            => {
        read_can_accept       => 'axi0_read_can_accept',
        write_can_accept      => 'axi0_write_can_accept',
        read_full             => 'axi0_read_full',
        write_full            => 'axi0_write_full',
        pending_reads         => 'axi0_pending_reads',
        pending_writes        => 'axi0_pending_writes',
        read_slots_available  => 'axi0_read_slots_available',
        write_slots_available => 'axi0_write_slots_available',
    },
    source => {
        object_id => 'axi-manager-capacity-status',
        anchors => [
            { document => 'IHI0022_L_2025-08', section => 'A1.1' },
            { document => 'IHI0022_L_2025-08', section => 'A1.2' },
            { document => 'IHI0022_L_2025-08', section => 'A5.1' },
        ],
    },
});
```

The result exposes `generated_ial1.text` before `generated_ial0.files`. The
generated `.isf` parses through `FSM::Adapter::ISF`, lowers through
`FSM::Scheduler::ISF`, and reaches SystemVerilog through the scheduled `.fsm`
review artifact. The generated actor owns read/write pending counters, exposes
namespaced read/write `can_accept`, full, pending, and slots-available status
outputs, and emits explicit idle, submit-only, complete-only, and
submit+complete rule matrices per direction. Same-cycle submit+complete at a
full depth is accepted because the completion frees capacity in the same
cycle.

The IAL2 report schema is
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`. It includes
source anchors, generated artifact names, read/write capacity metadata,
status-output bindings, abstract-event bindings, generated rule summaries,
assumptions, enforced static rules, and explicit residue. Public `.ppif`
parser/CLI behavior, profile aliases, IDs, ordering, response matching, bursts,
queued/blocking policy, HDL blocked-reason outputs, and VHDL remain future
exact-owner work.

Public capacity/status `.ppif` syntax selection:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_SYNTAX_SELECTION.md)
selects the next public source shape. The selected syntax is one
`manager-capacity-status` object under the generic PPIF root:

```text
(protocol-platform-intent axi0_capacity_status
  (profile axi4)
  (source
    (object axi-manager-capacity-status)
    (anchor (document IHI0022_L_2025-08) (section A1.1) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A1.2) (page A1-1))
    (anchor (document IHI0022_L_2025-08) (section A5.1) (page A5-1)))
  (manager-capacity-status axi0
    (clock clk)
    (reset (rst_n active_low async))
    (read-max-pending 4)
    (write-max-pending 2)
    (submit-policy try)
    (read-submit axi0_read_submit)
    (read-complete axi0_read_complete)
    (write-submit axi0_write_submit)
    (write-complete axi0_write_complete)
    (status
      (read-can-accept axi0_read_can_accept)
      (write-can-accept axi0_write_can_accept)
      (read-full axi0_read_full)
      (write-full axi0_write_full)
      (pending-reads axi0_pending_reads)
      (pending-writes axi0_pending_writes)
      (read-slots-available axi0_read_slots_available)
      (write-slots-available axi0_write_slots_available))))
```

This syntax is now shipped by the public parser/CLI first slice below.

Public capacity/status `.ppif` first slice:
[AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE](../../AXI_IAL2_MANAGER_CAPACITY_STATUS_PPIF_FIRST_SLICE.md)
ships the selected source shape as a runnable sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status.ppif
```

The public sample is support-accounted as
`intent.ppif_axi_manager_capacity_status`. Schedule JSON emits
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1`; `--outdir`
writes `axi0_capacity_status.isf` before `axi0_capacity_status.fsm`; default
HDL and `--verify-hdl` reach the generated `axi0_capacity_status`
SystemVerilog module; check JSON and normalized semantic JSON preserve the
public `.ppif` source path. The first public slice rejects mixed
`valid-ready-channel` plus `manager-capacity-status` files, multiple manager
objects, IDs, ordering, response matching, bursts, queued/blocking policy,
profile aliases, and VHDL behavior.

Next AXI manager subset: ID-family/static-validation:
[AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION](../../AXI_IAL2_MANAGER_ID_FAMILY_SUBSET_SELECTION.md)
selects the next bounded subset after capacity/status. The subset owns
separate read/write ID-family declarations, zero-width absence semantics,
static signal-pair validation, source anchors, and report metadata. The
selected semantic shape is:

```text
(id-families
  (write (width 4) (request-id AWID) (response-id BID))
  (read  (width 4) (request-id ARID) (response-id RID)))
```

Readiness audit:
[AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT](../../AXI_IAL2_MANAGER_ID_FAMILY_READINESS_AUDIT.md)
selects the implementation boundary. The first implementation should add an
optional `(id-families ...)` clause under the existing
`manager-capacity-status` object, emit additive report metadata, and leave
generated `.isf`, generated `.fsm`, and HDL behavior unchanged.

First ID-family `.ppif` slice:
[AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE](../../AXI_IAL2_MANAGER_ID_FAMILY_FIRST_SLICE.md)
ships that boundary as the optional `(id-families ...)` clause under the
existing capacity/status object:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))
```

The zero-width absence form is explicit:

```text
(id-families
  (write (width 0))
  (read (width 0)))
```

Runnable sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_id_family.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_id_family.ppif
```

The support-accounting entry is
`intent.ppif_axi_manager_capacity_status_id_family`. Schedule JSON keeps
schema `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and
additively emits `id_families.write` and `id_families.read` with `width`,
`present`, request/response signal names for positive widths, and source
anchors. The same `axi0_capacity_status.isf`, `axi0_capacity_status.fsm`, and
SystemVerilog module are produced with or without `id_families`. ID
allocation, per-transaction ID validation, same-ID ordering, different-ID
interleaving, `BID`/`RID` response matching, bursts, queued/blocking policies,
profile aliases, and VHDL remain future task-tree-owned residue.

Next AXI manager subset: transaction envelope/static-validation:
[AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION](../../AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_SELECTION.md)
selects the next bridge between static manager metadata and dynamic manager
behavior. The selected subset is a machine-readable AST/structural logical
read/write transaction envelope with stable transaction names, read/write kind,
user-visible tags, request/completion event bindings, optional requested-ID
policy or value, source anchors, report metadata, and explicit residue. The
illustrative semantic shape is:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id auto)))
```

Readiness audit:
[AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_READINESS_AUDIT.md)
selects the implementation boundary. The first implementation should add an
optional `(transactions ...)` clause under the existing
`manager-capacity-status` object, emit additive report metadata, and leave
generated `.isf`, generated `.fsm`, and HDL behavior unchanged. Transaction
request/completion bindings in this first slice must reference the existing
direction-level abstract events:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id (value 3))))
```

First transaction-envelope `.ppif` slice:
[AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE](../../AXI_IAL2_MANAGER_TRANSACTION_ENVELOPE_FIRST_SLICE.md)
ships that boundary as the optional `(transactions ...)` clause under the
existing capacity/status object:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_write_submit)
    (completion axi0_write_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_read_submit)
    (completion axi0_read_complete)
    (id (value 3))))
```

Runnable sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_envelope.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_transaction_envelope.ppif
```

The support-accounting entry is
`intent.ppif_axi_manager_capacity_status_transaction_envelope`. Schedule JSON
keeps schema `fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and
additively emits `transactions[]` entries with `name`, `kind`, `tag`,
`request_event`, `completion_event`, `id`, and `source_anchors`. Concrete IDs
report `policy: concrete`, `value`, `family`, `family_width`, and `fits`.
At the time the transaction-envelope slice shipped, generated artifacts were
unchanged. The later concrete-ID assertion slice now makes concrete
`(id (value N))` transactions behavior-bearing: generated `.isf` declares the
used ID-family request/response ID signals, generated `.fsm` carries `+assert`
entries, and SystemVerilog emits verification-only assertions. Auto-ID
transactions remain report-only until an allocator slice ships. The manager
still does not implement ID allocation algorithms, dynamic user-ID validation
while issuing, same-ID ordering queues, different-ID interleaving, generated
`BID`/`RID` response demux, bursts, queued/blocking policy, profile aliases,
full AXI manager behavior, or VHDL.

First transaction-event dispatch `.ppif` slice:
[AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION](../../AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_SELECTION.md)
selected the prerequisite before ID allocation or response matching. The
readiness audit:
[AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT](../../AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_READINESS_AUDIT.md)
selected an additive implementation boundary. The first implementation slice:
[AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE](../../AXI_IAL2_MANAGER_TRANSACTION_EVENT_DISPATCH_FIRST_SLICE.md)
ships that behavior under the existing optional `(transactions ...)` clause.
Distinct per-transaction request and completion events now fan into the
read/write capacity/status rule matrices through the current
IAL1/IAL0/SystemVerilog path:

```text
(transactions
  (write w0
    (tag wr0)
    (request axi0_w0_request)
    (completion axi0_w0_complete)
    (id auto))
  (read r0
    (tag rd0)
    (request axi0_r0_request)
    (completion axi0_r0_complete)
    (id (value 3))))
```

Runnable sample:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
./bin/fsmgen --outdir generated --verify-hdl ppif/axi_manager_capacity_status_transaction_event_dispatch.ppif
```

The support-accounting entry is
`intent.ppif_axi_manager_capacity_status_transaction_event_dispatch`.
Schedule JSON keeps schema
`fsmgen.ial2.protocol_intent.axi_manager_capacity_status.v1` and additively
emits:

```text
transaction_event_dispatch:
  mode: per_transaction_event_fanin
  directions:
    - direction: write
      request_events:
        - axi0_w0_request
        - axi0_w1_request
      completion_events:
        - axi0_w0_complete
        - axi0_w1_complete
      request_fanin: "(| axi0_w0_request axi0_w1_request)"
      completion_fanin: "(| axi0_w0_complete axi0_w1_complete)"
    - direction: read
      request_events:
        - axi0_r0_request
      completion_events:
        - axi0_r0_complete
      request_fanin: axi0_r0_request
      completion_fanin: axi0_r0_complete
```

Generated `.isf` declares the transaction events as inputs and keeps scalar
one-event compatibility for directions with one transaction event. Multi-event
groups lower as OR fan-in guards, the generated `.fsm` preserves those guard
expressions, and SystemVerilog emits the equivalent OR expressions through the
existing backend. Concrete-ID transactions now also use this event provenance:
request/response ID assertions bind to per-transaction events such as
`axi0_r0_request` and `axi0_r0_complete`, while the capacity/status rule
matrix keeps the same fan-in behavior. The IAL1 rule-conflict proof now
understands the bounded OR/negated-OR guard shape used by this generated rule
matrix. This slice does
not implement or claim ID allocation, generated `BID`/`RID` response demux,
same-ID ordering, interleaving, bursts, payload binding, queued/blocking
policy, profile aliases, full AXI manager behavior, or VHDL.

Next AXI manager subset: ID/response rule-engine readiness:
[AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION](../../AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_SELECTION.md)
selects the next frontier after shipped transaction event provenance. The next
leaf is not an implementation permission slip; it is a readiness audit that
must decide whether the first ID/response behavior can extend the existing
`manager-capacity-status` object through current IAL1/IAL0/SystemVerilog
substrate or whether a narrower prerequisite is needed first.
The readiness audit:
[AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_ID_RESPONSE_RULE_ENGINE_READINESS_AUDIT.md)
selects additive concrete transaction ID request/response assertions as the
first implementation boundary.

Concrete transaction ID assertion first slice:
[AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE](../../AXI_IAL2_MANAGER_CONCRETE_ID_ASSERTIONS_FIRST_SLICE.md)
ships that boundary without adding new public syntax. Existing machine-readable
ID-family and transaction metadata now become behavior-bearing when a
transaction uses concrete `(id (value N))`:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read  (width 4) (request-id axi0_arid) (response-id axi0_rid)))

(transactions
  (write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto))
  (read  r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id (value 3))))
```

Generated `.isf` declares the used ID-family request/response signals and emits
assertion-only checks:

```text
(input axi0_arid (width 4))
(input axi0_rid (width 4))

(transaction axi0_id_response_checks
  (assert (=> axi0_r0_request (== axi0_arid 3))
          "axi0 r0 request ID matches concrete ID")
  (assert (=> axi0_r0_complete (== axi0_rid 3))
          "axi0 r0 response ID matches concrete ID"))
```

The generated `.fsm` carries `+size` entries for the used ID signals and
`+assert` carriers. SystemVerilog emits verification-only concurrent
properties through the existing assertion backend. Schedule JSON additively
emits:

```text
id_response_rule_engine:
  mode: concrete_id_assertions
  id_signal_inputs:
    - axi0_arid
    - axi0_rid
  checks:
    - transaction: r0
      phase: request
      event: axi0_r0_request
      id_signal: axi0_arid
      id_value: 3
      enforcement: runtime_assertion
    - transaction: r0
      phase: response
      event: axi0_r0_complete
      id_signal: axi0_rid
      id_value: 3
      enforcement: runtime_assertion
  residue:
    - auto_id_allocation
    - id_release
    - same_id_ordering
    - response_demux
```

The shipped scope now includes bounded automatic request-ID allocation and
completion-event ID release only when the explicit `auto-id-lifecycle` clause
is present. Same-ID ordering queues, different-ID read-data
interleaving/reassembly, burst and last-beat tracking, payload binding,
queued/blocking policy, generated response demux, full AXI manager syntax,
profile aliases, and VHDL remain unshipped.

Shipped AXI manager subset: auto-id-lifecycle request-ID drive:
[AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE](../../AXI_IAL2_MANAGER_AUTO_ID_REQUEST_ID_DRIVE_FIRST_SLICE.md)
ships bounded request-ID drive behavior for the explicit lifecycle contract.
The earlier
[AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_AUTO_ID_LIFECYCLE_METADATA_FIRST_SLICE.md)
implements the parser/report metadata boundary for the same syntax selected by
[AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_AUTO_ID_POOL_CONTRACT_SELECTION.md).
Auto-ID transactions are still report-only unless the opt-in clause is
present. With the clause present, request ID signals such as `axi0_awid`
become generated outputs, per-auto-transaction selected-ID/busy state is
generated, first-free allocation and completion release rules lower through
`.fsm`, and SystemVerilog declares the request ID and state registers.

The selected audit starts from the existing syntax:

```text
(id-families
  (write (width 4) (request-id axi0_awid) (response-id axi0_bid))
  (read (width 4) (request-id axi0_arid) (response-id axi0_rid)))

(transactions
  (write w0 (tag wr0) (request axi0_w0_request) (completion axi0_w0_complete) (id auto))
  (read  r0 (tag rd0) (request axi0_r0_request) (completion axi0_r0_complete) (id auto)))
```

The selected opt-in syntax is:

```text
(auto-id-lifecycle
  (write (pool 0 1))
  (read  (pool 0 1 2 3)))
```

Without that clause, existing `(id auto)` transactions remain
structural/report-only metadata. With that clause, the shipped implementation
validates positive-width ID families, one to four unique pool values per
family, values inside the declared width, and at least one auto-ID transaction
in each listed family. The structural report adds `auto_id_lifecycle` metadata
with `generated_behavior: true`, `request_id_direction: generated_output`,
`response_id_direction: generated_input`, `allocator: first_free_pool_order`,
`transaction_lifetime: single_active`, and `transaction_state[]` entries that
name generated selected-ID storage, busy storage, allocation rules, release
rules, and assertion carriers. Its residue is now `response_demux`; the later
same-ID avoidance slice below removed the covered generated auto-ID same-ID
residue.

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_auto_id_lifecycle.ppif
```

Its support-accounting entry is:

```text
intent.ppif_axi_manager_capacity_status_auto_id_lifecycle
```

The generated behavior uses request ID outputs for `AWID`/`ARID`, keeps
response ID inputs such as `BID`/`RID` absent unless concrete checks require
them, allocates first-free IDs in author pool order, enforces single-active
logical auto transactions, and releases IDs on completion events. Same-ID
ordering queues, generated response demux, read-data interleaving/reassembly,
bursts, queued/blocking policy, full AXI manager syntax, aliases, and VHDL
remain unshipped.

Selected next AXI manager subset:
[AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION](../../AXI_IAL2_MANAGER_RESPONSE_DEMUX_SELECTION.md)
selects generated response-demux readiness as the next exact slice after
bounded auto-ID request-ID drive. The audit must resolve response-channel
`BID`/`RID` ownership, response handshake/completion-event direction, generated
demux completion signals, report shape, and IAL1/IAL0/SystemVerilog substrate
before any response matching, same-ID ordering, read-data interleaving, burst,
queued-policy, alias, full-manager, or VHDL behavior changes.

Response-demux readiness audit:
[AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects a bounded write `BID` response-demux public-contract step before
parser/report or generated behavior changes. The audit finds no obvious
IAL1/IAL0/SystemVerilog blocker for a narrow write demux once the contract is
explicit, but the source must first define response accepted event naming,
transaction completion ownership, generated demux signal naming, diagnostics,
and report shape.

Write response-demux contract selection:
[AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects the first public response-demux syntax:

```text
(response-demux
  (write
    (response-event axi0_write_complete)
    (transaction-completion generated)))
```

This first contract is write-only. `response-event` names the raw write
response accepted event and must equal top-level `write-complete` in the first
bounded slice. `transaction-completion generated` means write transaction
`completion` names become generated demux signals only under this explicit
opt-in clause. Without `response-demux`, completion names remain authored
inputs as they do today.

Shipped write response-demux first slices:
[AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md)
ships parser/report metadata and static validation for the selected explicit
opt-in. The behavior follow-up:
[AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md)
now generates bounded write `BID` response-demux behavior for the same source
shape. The checked-in sample is:

```text
ppif/axi_manager_capacity_status_response_demux.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --outdir generated ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_response_demux.ppif
```

Generated IAL1 declares the raw write response event and `BID` as inputs,
declares each transaction completion as a generated pulse output, and emits
one demux rule per auto-ID write transaction:

```text
(input axi0_write_complete)
(input axi0_bid (width 4))
(output axi0_w0_complete)

(rule axi0_w0_response_demux
  (& axi0_write_complete axi0_w0_auto_id_busy_q
     (== axi0_bid axi0_w0_auto_id_q))
  (pulse axi0_w0_complete))
```

The generated `.fsm` lowers each demux completion through `<1` pulse-domain
assignments. The existing write capacity matrix and auto-ID release rules use
the generated completion pulse fan-in, so capacity and selected-ID release are
driven by the demuxed completion names rather than authored completion inputs.

The report additively emits:

```text
response_demux:
  mode: bounded_write_bid_demux_contract
  generated_behavior: true
  write:
    response_event: axi0_write_complete
    response_id_signal: axi0_bid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    auto_transactions: [w0, w1]
    generated_rules: [axi0_w0_response_demux, axi0_w1_response_demux]
    generated_completion_signals: [axi0_w0_complete, axi0_w1_complete]
    generated_assertions:
      - axi0_write_response_demux_active_match
      - axi0_w0_w1_write_response_demux_unique_match
  residue:
    - read_response_demux
    - read_data_interleaving
    - bursts
```

The generated assertion transaction checks that every accepted write response
matches an active auto-ID write transaction and that no accepted write response
matches more than one active auto-ID write transaction. The
`id_response_rule_engine` residue removes `response_demux` for this explicit
write demux behavior; concrete/per-ID same-ID ordering remains residue there.

Post-demux selector:
[AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION](../../AXI_IAL2_MANAGER_POST_RESPONSE_DEMUX_RESIDUE_ALIGNMENT_SELECTION.md)
selects the next narrow slice, `.32`, to align `auto_id_lifecycle.residue`
with this shipped behavior. That implementation is now shipped:
[AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE](../../AXI_IAL2_MANAGER_AUTO_ID_RESIDUE_ALIGNMENT_FIRST_SLICE.md)
documents the report-contract cleanup. Explicit generated write demux now
removes `response_demux` from `auto_id_lifecycle.residue`; the later same-ID
avoidance slice below removes the covered same-ID residue for generated
auto-ID write demux.

Same-ID ordering readiness selector:
[AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION](../../AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_SELECTION.md)
selects `.34` as a readiness audit before same-ID ordering implementation or
prerequisite changes. At selector time, `same_id_ordering` was the common
remaining ID/auto-ID/write-demux residue after generated write `BID` demux and
auto-ID residue alignment. The audit decided whether the first same-ID ordering
step should be static/report classification, generated assertions, allocator
constraints, per-ID issue-order queues/scoreboards, or a smaller
IAL1/IAL0/SystemVerilog prerequisite.

Same-ID ordering readiness audit:
[AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT](../../AXI_IAL2_MANAGER_SAME_ID_ORDERING_READINESS_AUDIT.md)
selects `.35` as the first implementation boundary. The first same-ID slice
is not a per-ID ordering queue; it formalizes generated auto-ID same-ID
avoidance by adding pairwise active selected-ID assertions and
machine-readable `same_id_ordering` report metadata. This preserves the
current conservative behavior where generated auto-ID families avoid two
active transactions sharing an ID. Authored concrete-ID same-ID ordering,
per-ID response queues, read `RID` demux, read-data interleaving/reassembly,
bursts, queued/blocking policy, aliases, full-manager behavior, and VHDL
remain future exact-owner work.

Same-ID ordering first slice:
[AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE](../../AXI_IAL2_MANAGER_SAME_ID_ORDERING_FIRST_SLICE.md)
ships that bounded generated auto-ID same-ID avoidance boundary. Generated
auto-ID families now get pairwise active selected-ID assertions, and reports
add:

```text
same_id_ordering:
  mode: auto_id_same_id_avoidance
  generated_behavior: true
  strategy: avoid_same_id_concurrency
  families:
    - family: write
      enforcement: allocator_free_id_guard
      assertion_enforcement: runtime_assertion
      response_demux_covered: true
      generated_assertions:
        - axi0_w0_w1_auto_id_unique_active_id
  residue:
    - concrete_id_same_id_ordering
    - per_id_issue_order_queues
    - read_response_demux
    - read_data_interleaving
    - bursts
```

For the response-demux sample, `auto_id_lifecycle.residue` is now empty and
`response_demux.residue` is `[read_response_demux, read_data_interleaving,
bursts]`. `id_response_rule_engine.residue` still keeps `same_id_ordering`
for authored concrete-ID same-ID cases and future per-ID queues.

Read response-demux selector:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_SELECTION.md)
selects `.37` as a readiness audit for bounded read `RID` response demux after
generated auto-ID same-ID avoidance. The likely public shape to audit is an
additive read arm under the existing `response-demux` clause:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The audit must decide whether `response-event` can honestly mean a bounded
accepted single-beat read response event, whether explicit read
`auto-id-lifecycle` metadata is required, and how to report the remaining
out-of-scope read-data interleaving/reassembly, burst/last-beat, per-ID queue,
full-manager, and VHDL work.

Read response-demux readiness audit:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_READINESS_AUDIT.md)
selects `.38`, a public contract-selection slice. The audit found that the
current parser and generator are intentionally write-shaped for
`response-demux`, while the substrate already has read ID-family metadata,
read transaction metadata, read-capable auto-ID lifecycle state, concrete
`ARID`/`RID` assertion reachability, and IAL1 rule-owned pulse actions. The
contract still has to decide whether the first read demux scope is
single-beat/non-burst, what `response-event` means, whether it must equal
top-level `read-complete`, and whether read `auto-id-lifecycle` metadata is
mandatory before any parser/report or generated behavior changes.

Read response-demux contract selection:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_CONTRACT_SELECTION.md)
selects `.39`, parser/report metadata and static validation for the read arm.
The selected public syntax requires `(response-scope single-beat)`, so the
first read response-demux contract is explicitly non-burst/single-beat.
`response-event` must equal top-level `read-complete` and means the raw
accepted read response transfer under the opt-in. Read demux also requires
positive-width read ID-family metadata, read transaction metadata, and explicit
read `auto-id-lifecycle` metadata. Generated read `RID` demux rules and read
completion pulses remain future behavior.

Read response-demux metadata first slice:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_METADATA_FIRST_SLICE.md)
ships the historical `.39` parser/report implementation. Public `.ppif`
sources may use one `read` arm, one `write` arm, or both under
`response-demux`:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope single-beat)
    (transaction-completion generated)))
```

The checked-in sample is:

```text
ppif/axi_manager_capacity_status_read_response_demux.ppif
```

Useful commands:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_response_demux.ppif
```

At `.39`, the schedule report included:

```text
response_demux:
  mode: bounded_response_demux_contract
  generated_behavior: false
  read:
    mode: bounded_read_rid_demux_contract
    generated_behavior: false
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    auto_transactions: [r0, r1]
  residue:
    - generated_read_rid_demux
    - read_data_interleaving
    - bursts
```

At `.39`, generated read demux behavior was unchanged: the read transaction
completion events remained authored inputs, `RID` was not added to generated
IAL1 by response demux, no read completion outputs were emitted, and no read
response-demux rules or HDL logic were generated. The support-accounting entry is
`intent.ppif_axi_manager_capacity_status_read_response_demux`.

That paragraph describes the `.39` boundary. The generated behavior shipped
later in `.41` without changing the public source syntax.

Read response-demux behavior readiness audit:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md)
selected `.41`, bounded generated single-beat read `RID` response-demux
behavior. The audit found no new IAL1, IAL0, or SystemVerilog prerequisite:
the existing IAL1 `(pulse TARGET)` action and the shipped write demux path can
carry the read demux.

Read response-demux behavior first slice:
[AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_RESPONSE_DEMUX_BEHAVIOR_FIRST_SLICE.md)
ships the `.41` generated behavior. For the checked-in sample:

```text
(input axi0_read_complete)
(input axi0_rid (width 4))
(output axi0_r0_complete)
(output axi0_r1_complete)

(rule axi0_r0_response_demux
  (& axi0_read_complete axi0_r0_auto_id_busy_q
     (== axi0_rid axi0_r0_auto_id_q))
  (pulse axi0_r0_complete))
```

The raw `read-complete` event remains the accepted single-beat read response
input. `RID` is a generated response-ID input. The selected logical read
transaction completion names are generated one-cycle pulse outputs, not
authored event inputs, and read capacity release plus read auto-ID release
consume those pulses.

The schedule report now includes:

```text
response_demux:
  mode: bounded_response_demux_contract
  generated_behavior: true
  read:
    mode: bounded_read_rid_demux_contract
    generated_behavior: true
    response_event: axi0_read_complete
    response_event_role: raw_accepted_read_response
    response_scope: single_beat
    response_id_signal: axi0_rid
    response_id_direction: generated_input
    transaction_completion_source: generated_demux
    generated_rules: [axi0_r0_response_demux, axi0_r1_response_demux]
    generated_completion_signals: [axi0_r0_complete, axi0_r1_complete]
    generated_assertions:
      - axi0_read_response_demux_active_match
      - axi0_r0_r1_read_response_demux_unique_match
  residue:
    - read_data_interleaving
    - bursts
```

Useful behavior checks:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_response_demux.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_response_demux.ppif
```

Read-data interleaving/reassembly, bursts/`RLAST`, per-ID queues,
queued/blocking policy, full-manager behavior, direct backend lowering, and
VHDL remain future exact-owner work.

Post-read-demux next-slice selection:
[AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_READ_DEMUX_NEXT_SLICE_SELECTION.md)
selects `.43` as a readiness audit for AXI read-data payload,
burst/`RLAST`, and per-ID ordering/reassembly ownership. The selector chooses
an audit rather than a direct implementation because the remaining read-side
residue is interdependent: read-data payload capture needs a public structural
shape, burst ownership changes what `read-complete` means, different-ID
interleaving needs per-ID collection or an explicit issue constraint, and
authored concrete-ID same-ID ordering needs queues or a fail-closed rule. Full
manager behavior, profile aliases, queued/blocking policy, direct backend
lowering, and VHDL remain deferred.

Read-data/burst readiness audit:
[AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_DATA_BURST_READINESS_AUDIT.md)
selects `.44` as the bounded public read-data payload/status contract
selector. The audit concluded that a likely single-beat payload/status subset
can be layered on the shipped generated read `RID` demux with the existing
IAL1/IAL0/SystemVerilog data-path substrate, but FSMGen must first select the
public source syntax, report artifacts, target binding semantics, and
interleaving/burst residue policy. Parser/report metadata and generated
behavior changes stay out of `.43`.

Read-data payload/status contract selection:
[AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_READ_DATA_CONTRACT_SELECTION.md)
selects `.45`, parser/report metadata and static validation for the first
bounded `read-data` source contract:

```text
(read-data
  (read
    (capture-scope single-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (interleaving single-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_rdata)
      (status-output axi0_r0_rresp))))
```

The generated read response-demux completion pulse is the validity strobe for
the selected transaction's data/status outputs. The first contract does not
observe `RLAST`, does not assemble bursts, and does not perform multi-beat
read-data reassembly.

Read-data payload/status metadata first slice:
[AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_DATA_METADATA_FIRST_SLICE.md)
now ships the parser/report boundary for that contract. The checked-in
sample is:

```text
ppif/axi_manager_capacity_status_read_data.ppif
```

The sample keeps the generated read `RID` response-demux behavior and adds the
structural read-data AST. At the metadata boundary, schedule JSON reported:

```text
read_data:
  mode: bounded_single_beat_read_data_contract
  generated_behavior: false
  read:
    capture_scope: single_beat
    completion_source: response_demux
    completion_validity: generated_read_response_demux_completion_pulse
    data_signal: axi0_rdata
    data_signal_width: 32
    status_signal: axi0_rresp
    status_signal_width: 2
    interleaving_policy: single_beat_by_rid
```

The report also listed transaction-bound data/status outputs for `r0` and
`r1`, each tied to the generated read-demux completion pulse. The follow-up
behavior slice below now claims generated `RDATA`/`RRESP` capture behavior for
that same public contract.

Response-demux behavior readiness audit:
[AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_WRITE_RESPONSE_DEMUX_BEHAVIOR_READINESS_AUDIT.md)
concluded that generated write `BID` demux should not be implemented directly
on top of ordinary IAL1 rule assignments. Transaction completion names are
one-cycle completion pulses, while existing IAL1 `(set ...)` and shorthand
rule actions lower as sticky flopped assignments. That prerequisite is now
shipped as a bounded rule-owned `(pulse target)` action that lowers through the
existing delayed-pulse path. The generated write `BID` demux behavior is now
shipped through that pulse-completion path.

At the time of the write-demux readiness audit, generated data-capture
behavior still needed a later exact owner. That owner is now shipped for the
bounded single-beat `read-data` contract below. Same-ID response ordering
queues, read-data interleaving/reassembly, bursts, queued/blocking policy,
profile aliases, full AXI manager behavior, and VHDL remain future exact-owner
work.

Read-data capture readiness audit:
[AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_READ_DATA_CAPTURE_READINESS_AUDIT.md)
selects `.47`, generated single-beat `RDATA`/`RRESP` capture behavior. The
audit concluded no smaller IAL1/IAL0/SystemVerilog prerequisite is needed:
the shipped public `read_data` report names the source `RDATA`/`RRESP`
signals, widths, transaction-bound output names, and generated read-demux
completion pulses; existing IAL1 already supports width-bearing inputs,
width-bearing outputs, and normal guarded rule assignments. The behavior owner
must use normal data/status assignments rather than `(pulse ...)`, because the
payload/status outputs are held captured values, not one-cycle completion
pulses. `RLAST`, bursts, multi-beat read-data reassembly, per-ID queues,
full-manager behavior, direct backend lowering, and VHDL remain future
exact-owner work.

Read-data capture behavior first slice:
[AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
now ships generated single-beat `RDATA`/`RRESP` capture for explicit
`read-data` contracts. The generated IAL1 review artifact declares
width-bearing source inputs:

```text
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

and transaction-bound capture outputs:

```text
(output axi0_r0_rdata (width 32))
(output axi0_r0_rresp (width 2))
```

Each covered read transaction gets one normal guarded capture rule:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_rdata axi0_rdata)
  (axi0_r0_rresp axi0_rresp))
```

The guard is the generated read response-demux completion pulse, while the
payload/status assignments are ordinary held assignments. The generated `.fsm`
contains the corresponding capture assignments:

```text
(-axi0_r0_read_data_capture <axi0_r0_complete
  (<- (axi0_r0_rdata> axi0_rdata))
  (<- (axi0_r0_rresp> axi0_rresp)))
```

SystemVerilog exposes `axi0_rdata` and `axi0_rresp` as inputs, exposes each
transaction-bound captured payload/status as flopped outputs, and passes
`--verify-hdl` for:

```bash
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_data.ppif
```

Schedule JSON now reports `read_data.generated_behavior: true` with
`generated_inputs`, `generated_outputs`, and `generated_rules`. The
`read_data.residue` list removes `generated_read_data_capture` and retains
`rlast_completion`, `bursts`, and `multi_beat_read_data_reassembly`.

Burst/`RLAST` completion readiness audit:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_READINESS_AUDIT.md)
selects public contract selection before parser/report metadata or generated
behavior changes. The audit found no evident new IAL1/IAL0/SystemVerilog
prerequisite for a later bounded implementation: width-bearing ports, scalar
storage, guarded assignments, and one-cycle pulses already exist. What is
missing is the public AXI contract. The next selector must define `RLAST`
signal ownership, burst length or beat-count metadata, beat-valid versus
transaction-complete semantics, data/status capture granularity, diagnostics,
generated artifact boundaries, and report/residue movement before behavior can
ship.

`RLAST` completion contract selection:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_CONTRACT_SELECTION.md)
selects an additive read `response-demux` scope:

```text
(response-demux
  (read
    (response-event axi0_read_complete)
    (response-scope burst-last)
    (last-signal axi0_rlast (width 1))
    (transaction-completion generated)))
```

The shipped `single-beat` scope stays unchanged. In the selected
`burst-last` contract, `response-event` remains the raw accepted read response
beat, `last-signal` is a generated one-bit `RLAST` input, and the existing
transaction `(completion NAME)` output is the generated last-beat completion
pulse. The contract publishes no per-transaction beat-valid output, selects no
burst length or `ARLEN` ownership, and does not extend `read-data`; the current
single-beat `read-data` contract must be rejected when paired with
`response-scope burst-last`. The next implementation owner is parser/report
metadata and static validation only.

`RLAST` completion metadata first slice:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_METADATA_FIRST_SLICE.md)
ships that parser/report boundary. Public `.ppif` now accepts
`response-scope burst-last` with exactly one width-1 `last-signal`, keeps
`single-beat` syntax and behavior unchanged, and rejects malformed
`last-signal` clauses, `last-signal` on `single-beat`, and the current
single-beat `read-data` contract when paired with burst-last response demux.

The checked-in runnable sample is:

```text
ppif/axi_manager_capacity_status_read_response_demux_burst_last.ppif
```

The schedule report marks the burst-last read demux as report-only:

```text
response_demux.generated_behavior: false
response_demux.read.generated_behavior: false
response_demux.read.response_scope: burst_last
response_demux.read.last_signal: axi0_rlast
response_demux.read.last_signal_width: 1
response_demux.read.transaction_completion_source: generated_demux_last_beat
response_demux.read.transaction_completion_semantics: matched_rid_and_last_signal
response_demux.read.burst_length_source: rlast_only
response_demux.read.burst_length_validation: not_generated
response_demux.residue:
  - generated_burst_last_read_demux
  - read_data_interleaving
  - bursts
```

Generated `.isf`, `.fsm`, and HDL behavior remain unchanged for this sample:
no `RLAST` input, `RID` input, transaction completion outputs/rules, or
burst-last assertions are generated yet. The follow-on readiness audit selected
the generated burst-last/`RLAST` completion behavior boundary.

`RLAST` completion behavior readiness audit:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_READINESS_AUDIT.md)
selects direct generated behavior next. No new IAL1, IAL0, or SystemVerilog
prerequisite is needed: scalar inputs, generated pulse outputs, guarded rules,
assertion carriers, report artifacts, capacity release, and auto-ID release
already exist on the SystemVerilog-backed path.

The next behavior slice should add the generated `RLAST` input, reuse
generated `RID` matching, and pulse each generated transaction completion only
when the accepted response beat matches the transaction ID and `RLAST` is
asserted. It should move the burst-last sample to
`response_demux.generated_behavior: true`, remove
`generated_burst_last_read_demux` residue, mark read same-ID response-demux
coverage, and keep read-data reassembly, beat-count/`ARLEN` validation,
per-beat outputs, per-ID queues, direct backend lowering, and VHDL deferred.

`RLAST` completion behavior first slice:
[AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_RLAST_COMPLETION_BEHAVIOR_FIRST_SLICE.md)
ships generated burst-last completion behavior for explicit read
`response-demux` contracts. The checked-in burst-last sample now emits
generated `RID` and `RLAST` inputs, generated per-transaction completion pulse
outputs, one `RLAST`-gated response-demux rule per read auto-ID transaction,
active-match and unique-match assertions, auto-ID lifecycle residue movement,
same-ID response-demux coverage movement, and HDL reachability.

Generated IAL1 now includes:

```text
(input axi0_read_complete)
(input axi0_rid (width 4))
(input axi0_rlast)
(output axi0_r0_complete)
(output axi0_r1_complete)
```

The first generated last-beat rule is:

```text
(rule axi0_r0_response_demux
  (& axi0_read_complete axi0_r0_auto_id_busy_q
     (== axi0_rid axi0_r0_auto_id_q)
     axi0_rlast)
  (pulse axi0_r0_complete))
```

The schedule report marks `response_demux.generated_behavior: true`, removes
`generated_burst_last_read_demux` residue, removes `response_demux` from
`auto_id_lifecycle.residue`, and marks the read same-ID family
`response_demux_covered: true`. Read-data reassembly, beat-count/`ARLEN`
validation, per-beat outputs, per-ID queues, direct backend lowering, and VHDL
remain deferred. The active frontier is the post-`RLAST` selector for the next
exact AXI manager feature-completeness owner.

Post-`RLAST` next-slice selection:
[AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_RLAST_NEXT_SLICE_SELECTION.md)
selects the next exact owner after generated burst-last completion behavior.
The selector found that the structured burst-last report fields and generated
artifacts are correct, but generated schedule-report prose still says
burst-last `RLAST` metadata is report-only and generated burst/last-beat
tracking remains outside the capacity/status shell. The active frontier is
`IAL2-FEATURE-COMPLETENESS-FRONTIER.55`, a narrow report/static-text
alignment slice. Multi-beat read-data reassembly, per-ID queues, full-manager
behavior, direct backend lowering, and VHDL remain deferred until that
user-facing report drift is resolved.

`RLAST` report alignment first slice:
[AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE](../../AXI_IAL2_MANAGER_RLAST_REPORT_ALIGNMENT_FIRST_SLICE.md)
ships that user-facing report repair. The schedule report now says
`response_scope burst_last` generates matched-`RID`-and-`RLAST` last-beat
completion behavior for explicit opt-in contracts, and the unsupported-residue
prose now lists generated burst-last `RLAST` response-demux completion as
supported. Public syntax, generated `.isf`, generated `.fsm`, HDL, support
accounting, check JSON, and semantic JSON behavior are unchanged.

Post-`RLAST` report next-slice selection:
[AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_RLAST_REPORT_NEXT_SLICE_SELECTION.md)
selects public AXI burst read-data contract selection as the next owner. The
selector keeps direct multi-beat read-data behavior deferred because the
current `read-data` contract is single-beat-only, the burst-last sample has no
`read_data` contract, and the public shape for capture scope, output binding,
beat-count/depth, `RRESP` aggregation, interleaving, diagnostics, and report
residue movement is not selected yet.

Burst read-data contract selection:
[AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_BURST_READ_DATA_CONTRACT_SELECTION.md)
selects explicit last-beat read-data capture as the first bounded burst-side
contract. The selected source shape is `capture-scope last-beat`,
`status-policy last-beat`, and `interleaving last-beat-by-rid` under
`read-data`, paired only with generated `response_scope burst_last` response
demux. It captures only the last-beat `RDATA`/`RRESP` values and keeps full
multi-beat reassembly, per-beat outputs, `RRESP` aggregation,
`ARLEN`/beat-count validation, per-ID queues, and VHDL deferred.

Last-beat read-data metadata first slice:
[AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_METADATA_FIRST_SLICE.md)
ships parser/report metadata and static validation for that selected contract.
The public `.ppif` sample is
`ppif/axi_manager_capacity_status_read_data_last_beat.ppif`:

```text
(read-data
  (read
    (capture-scope last-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy last-beat)
    (interleaving last-beat-by-rid)
    (transaction r0
      (data-output axi0_r0_last_rdata)
      (status-output axi0_r0_last_rresp))
    (transaction r1
      (data-output axi0_r1_last_rdata)
      (status-output axi0_r1_last_rresp))))
```

The report marks this as structural metadata, not generated capture behavior:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: false
  read:
    capture_scope: last_beat
    completion_validity: generated_read_response_demux_last_beat_completion_pulse
    status_policy: last_beat
    status_aggregation: none
    interleaving_policy: last_beat_by_rid
    burst_length_source: rlast_only
    beat_storage: none
    valid_output: none
    length_output: none
```

The slice requires generated read response-demux metadata with
`response_scope burst_last`, support-accounts the new sample for strict check
JSON and normalized semantic JSON, and keeps generated `.isf`, `.fsm`, HDL
behavior, check JSON semantics, and existing single-beat read-data behavior
unchanged.

Last-beat read-data capture readiness audit:
[AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_CAPTURE_READINESS_AUDIT.md)
selects direct generated last-beat `RDATA`/`RRESP` capture behavior. The audit
found no new IAL1/IAL0/SystemVerilog prerequisite: the existing read-data
source-input, transaction-output, capture-rule, and generated-artifact helpers
are already generic over the normalized read-data transaction list, and the
`.58` metadata binds each transaction to its generated burst-last completion
pulse.

Last-beat read-data behavior first slice:
[AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_LAST_BEAT_READ_DATA_BEHAVIOR_FIRST_SLICE.md)
ships generated last-beat `RDATA`/`RRESP` capture behavior. The last-beat
sample now emits generated data/status inputs, per-transaction last-beat
data/status outputs, and normal guarded capture rules driven by generated
burst-last completion pulses:

```text
(rule axi0_r0_read_data_capture axi0_r0_complete
  (axi0_r0_last_rdata axi0_rdata)
  (axi0_r0_last_rresp axi0_rresp))
```

The schedule report marks the behavior as generated and lists the generated
artifacts:

```text
read_data:
  mode: bounded_last_beat_read_data_contract
  generated_behavior: true
  read:
    generated_inputs:
      - axi0_rdata
      - axi0_rresp
    generated_outputs:
      - axi0_r0_last_rdata
      - axi0_r0_last_rresp
      - axi0_r1_last_rdata
      - axi0_r1_last_rresp
    generated_rules:
      - axi0_r0_read_data_capture
      - axi0_r1_read_data_capture
```

Post last-beat read-data next-slice selection:
[AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_LAST_BEAT_READ_DATA_NEXT_SLICE_SELECTION.md)
selects public AXI burst read-data beat-count/depth contract selection as the
next exact owner. Full multi-beat reassembly, per-beat outputs, `RRESP`
aggregation, missing/extra beat validation, and per-ID reassembly all need an
explicit expected-count/depth contract before behavior can be implemented
honestly.

Burst read-data beat-count contract selection:
[AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_CONTRACT_SELECTION.md)
selects an additive ARLEN-based `burst-length` clause under last-beat
`read-data`:

```text
(burst-length
  (source arlen)
  (signal axi0_arlen (width 8))
  (encoding axlen-plus-one)
  (capture request)
  (max-beats 16)
  (validation report-only))
```

The selected contract is metadata first: generated counters, storage,
missing/extra beat validation, full reassembly, per-beat outputs, `RRESP`
aggregation, and per-ID queues remain future exact-owner work.

Burst read-data beat-count metadata first slice:
[AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_BURST_READ_DATA_BEAT_COUNT_METADATA_FIRST_SLICE.md)
ships the parser/report boundary for that contract. The public sample is:

```text
ppif/axi_manager_capacity_status_read_data_burst_length.ppif
```

The metadata slice introduced the public report fields for ARLEN beat-count
metadata. The current generated behavior, shipped by
`IAL2-FEATURE-COMPLETENESS-FRONTIER.66`, keeps last-beat `RDATA`/`RRESP`
capture behavior and also captures raw ARLEN at each transaction request:

```text
read_data:
  generated_behavior: true
  read:
    burst_length_source: arlen_signal
    burst_length_signal: axi0_arlen
    burst_length_signal_width: 8
    burst_length_encoding: axlen_plus_one
    burst_length_capture: transaction_request
    max_beats: 16
    burst_length_generated_behavior: true
    burst_length_validation: report_only
    beat_storage: none
    valid_output: none
    length_output: none
    generated_burst_length_inputs:
      - axi0_arlen
    generated_burst_length_storage:
      - axi0_r0_arlen_q
      - axi0_r1_arlen_q
    generated_burst_length_rules:
      - axi0_r0_burst_length_capture
      - axi0_r1_burst_length_capture
```

The generated IAL1 includes the ARLEN input, one raw-ARLEN storage variable
per covered read transaction, and one request-event guarded capture rule per
covered read transaction:

```text
(input axi0_arlen (width 8))

(var axi0_r0_arlen_q (width 8))
(var axi0_r1_arlen_q (width 8))

(rule axi0_r0_burst_length_capture axi0_r0_request
  (axi0_r0_arlen_q axi0_arlen))
(rule axi0_r1_burst_length_capture axi0_r1_request
  (axi0_r1_arlen_q axi0_arlen))
```

The `.fsm` and SystemVerilog outputs lower the same raw-ARLEN capture
behavior. The captured value is raw `ARLEN`; later beat-count validation will
own the `ARLEN + 1` arithmetic implied by `axlen_plus_one`.

Useful checks:

```bash
./bin/fsmgen --emit-schedule-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif
./bin/fsmgen --quiet --verify-hdl ppif/axi_manager_capacity_status_read_data_burst_length.ppif
./bin/fsmgen --strict --check --json ppif/axi_manager_capacity_status_read_data_burst_length.ppif
./bin/fsmgen --strict --emit-semantic-json ppif/axi_manager_capacity_status_read_data_burst_length.ppif
```

Post burst-length metadata selector:
[AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_BURST_LENGTH_METADATA_NEXT_SLICE_SELECTION.md)
selects a readiness audit before generated ARLEN capture. Generated ARLEN
capture is the next prerequisite before beat-count/RLAST validation or
multi-beat reassembly, but it adds a new HDL input, generated storage, and
request-event binding that must be audited before behavior changes.

ARLEN capture readiness audit:
[AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT](../../AXI_IAL2_MANAGER_ARLEN_CAPTURE_READINESS_AUDIT.md)
finds that existing generated inputs, generated vars, guarded rule
assignments, request-event guards, report artifact lists, and HDL lowering are
enough for a bounded raw-ARLEN capture slice. The selected behavior stores raw
8-bit `ARLEN` per read transaction and leaves `ARLEN + 1` arithmetic,
beat-count/RLAST validation, payload storage, and reassembly deferred.

ARLEN capture behavior first slice:
[AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_ARLEN_CAPTURE_BEHAVIOR_FIRST_SLICE.md)
ships generated raw-ARLEN capture for opt-in last-beat read-data
`burst-length` contracts. It removes `generated_burst_length_capture` from
read-data residue and leaves `generated_beat_count_validation`,
`multi_beat_read_data_reassembly`, `per_beat_outputs`, and
`rresp_aggregation` as explicit future owners.

Beat-count/RLAST validation readiness audit:
[AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT](../../AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_VALIDATION_READINESS_AUDIT.md)
finds the IAL1/IAL0/SystemVerilog substrate ready for future generated
validation after a public validation contract exists. Generated storage can
carry `max-beats`-width expected-count and beat-count state, generated rules
can assign arithmetic expressions, response-demux match expressions can
identify every accepted matched read beat, and generated assertions already
lower through clocked reset-disabled SystemVerilog properties. The audit does
not select direct behavior because the existing public syntax says
`validation report-only`, and that mode must remain no-runtime-check behavior.

Beat-count/RLAST runtime-validation contract selection:
[AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_CONTRACT_SELECTION.md)
selects an explicit generated-validation mode while preserving
`validation report-only` as report-only metadata:

```text
(validation runtime-assertion)
```

The normalized report values are `report_only` and `runtime_assertion`.
`runtime-assertion` is behavior-bearing: implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.69`
([AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE](../../AXI_IAL2_MANAGER_BEAT_COUNT_RLAST_RUNTIME_VALIDATION_FIRST_SLICE.md))
ships parser support and generated validation behavior together. The shipped
report shape includes `burst_length_validation: runtime_assertion`,
`beat_count_validation_generated_behavior: true`,
`expected_beat_count_encoding: arlen_plus_one`,
`beat_count_match_source: response_demux_matched_read_beat`, generated
expected-count storage, generated beat-count storage/rules, and generated
assertion names such as `axi0_r0_arlen_within_max`,
`axi0_r0_read_beat_before_expected_count`,
`axi0_r0_rlast_on_expected_beat`, and
`axi0_r0_expected_final_beat_has_rlast`. Generated IAL1/.fsm/SystemVerilog
now include expected-beat storage, matched-read-beat counters, initialization
and increment rules, ARLEN-bound, extra-beat, early-`RLAST`, and
missing-final-`RLAST` assertions for `(validation runtime-assertion)` while
`validation report-only` remains no-runtime-check behavior.

Post beat-count/RLAST validation next-slice selection:
[AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_BEAT_COUNT_RLAST_VALIDATION_NEXT_SLICE_SELECTION.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.71`, public AXI multi-beat
read-data reassembly/output contract selection, as the active frontier. The
selector keeps direct reassembly behavior deferred because the public
source/report surface still needs beat storage, per-beat or packed outputs,
length/valid outputs, all-beat `RRESP` aggregation, and different-ID/per-ID
queue semantics selected first.

Multi-beat read-data reassembly contract selection:
[AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_CONTRACT_SELECTION.md)
selects `capture-scope multi-beat` with mandatory ARLEN `burst-length`
runtime assertions, `status-policy per-beat`, `interleaving
multi-beat-by-rid`, and per-transaction data/status output prefixes,
valid-mask outputs, and length outputs. The first selected output shape is a
per-beat output bank, not a packed burst vector. Scalar `RRESP` aggregation
and generated reassembly behavior remain deferred. The selector advanced the
frontier to
`IAL2-FEATURE-COMPLETENESS-FRONTIER.72`, parser/report metadata and static
validation for this public syntax.

Multi-beat read-data metadata first slice:
[AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_METADATA_FIRST_SLICE.md)
ships parser/report metadata and static validation for the selected
multi-beat output-bank syntax. The support-accounted sample is:

```text
ppif/axi_manager_capacity_status_read_data_multi_beat.ppif
```

The public source shape binds per-transaction output names by prefix and
explicit valid/length outputs:

```text
(read-data
  (read
    (capture-scope multi-beat)
    (completion-source response-demux)
    (data-signal axi0_rdata (width 32))
    (status-signal axi0_rresp (width 2))
    (status-policy per-beat)
    (status-aggregation
      (policy worst-observed))
    (interleaving multi-beat-by-rid)
    (burst-length
      (source arlen)
      (signal axi0_arlen (width 8))
      (encoding axlen-plus-one)
      (capture request)
      (max-beats 16)
      (validation runtime-assertion))
    (transaction r0
      (data-output-prefix axi0_r0_beat_rdata)
      (status-output-prefix axi0_r0_beat_rresp)
      (status-aggregate-output axi0_r0_rresp)
      (valid-mask-output axi0_r0_beat_valid)
      (length-output axi0_r0_read_beats))))
```

Schedule JSON reports `bounded_multi_beat_read_data_contract`, per-transaction
generated lane names, valid-mask widths, length-output widths,
`beat_match_source: response_demux_matched_read_beat`,
`output_shape: per_beat_output_bank`, and
the public transaction output-bank shape. `.72` is the parser/report metadata
boundary; generated output-bank behavior ships in `.74`.

Multi-beat read-data output readiness audit:
[AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT](../../AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_REASSEMBLY_OUTPUT_READINESS_AUDIT.md)
finds no new IAL1, IAL0, or SystemVerilog prerequisite for the first
generated output-bank behavior. The selected implementation boundary uses
scalar generated lane outputs, treats the public output registers as the
generated per-transaction beat storage, clears valid/length/lane outputs on
request, captures each accepted beat under a matched-read-beat,
`!request_event`, and current `beat_count_storage == lane_index` guard, and
sets valid masks with constant prefix values. It selected
`IAL2-FEATURE-COMPLETENESS-FRONTIER.74`, generated multi-beat read-data
output-bank behavior.

Multi-beat read-data output-bank behavior first slice:
[AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_MULTI_BEAT_READ_DATA_OUTPUT_BANK_BEHAVIOR_FIRST_SLICE.md)
ships generated output-bank behavior for the public multi-beat sample. The
generated IAL1 review artifact now declares payload inputs such as:

```text
(input axi0_rdata (width 32))
(input axi0_rresp (width 2))
```

It also declares per-transaction lane outputs, valid masks, and length
outputs:

```text
(output axi0_r0_beat_rdata_0 (width 32))
(output axi0_r0_beat_rresp_0 (width 2))
(output axi0_r0_beat_valid (width 16))
(output axi0_r0_read_beats (width 5))
```

Each read transaction gets a request-time output-bank clear rule and one lane
capture rule per beat. Lane capture guards combine the response-demux
matched-read-beat expression, `!request_event`, and
`beat_count_storage == lane_index`; actions capture current `RDATA`/`RRESP`,
write a constant prefix valid mask, and write `lane_index + 1` into the
length output. Schedule JSON reports
`multi_beat_reassembly_generated_behavior: true`, generated payload inputs,
generated output lanes, valid/length outputs, output-init rules, and lane
capture rules. `read_data.residue` is now only `rresp_aggregation`; scalar
`RRESP` aggregation, per-ID queues, direct backend lowering, and VHDL remain
deferred. Selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.75` selects public
scalar `RRESP` aggregation contract selection as the next exact owner. That
selection advanced the frontier to `IAL2-FEATURE-COMPLETENESS-FRONTIER.76`.

Post multi-beat output next-slice selection:
[AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_MULTI_BEAT_OUTPUT_NEXT_SLICE_SELECTION.md)
records the `.75` selector. It chooses public scalar `RRESP` aggregation
contract selection before any parser/report metadata or generated behavior
changes.

RRESP aggregation contract selection:
[AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION](../../AXI_IAL2_MANAGER_RRESP_AGGREGATION_CONTRACT_SELECTION.md)
records the `.76` selector. It chooses an additive read-level
`(status-aggregation (policy worst-observed))` clause plus one
transaction-local `(status-aggregate-output NAME)` binding per transaction:

```text
(read-data
  (read
    (capture-scope multi-beat)
    (status-policy per-beat)
    (status-aggregation
      (policy worst-observed))
    (transaction r0
      (status-output-prefix axi0_r0_beat_rresp)
      (status-aggregate-output axi0_r0_rresp))))
```

The normalized report spelling is `status_aggregation: worst_observed`.
For the width-2 contract, the selected ordering is
`OKAY < EXOKAY < SLVERR < DECERR` across every accepted matched read-data
beat. Per-beat `RRESP` lanes stay mandatory, valid/length outputs stay
unchanged, width-3 AXI responses remain deferred, and generated scalar
aggregation behavior remains deferred to a later exact owner. The active
frontier moved through `IAL2-FEATURE-COMPLETENESS-FRONTIER.77`, parser/report
metadata and static validation for this selected contract.

RRESP aggregation metadata first slice:
[AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE](../../AXI_IAL2_MANAGER_RRESP_AGGREGATION_METADATA_FIRST_SLICE.md)
ships the parser/report metadata and static validation for the selected
contract. The public multi-beat sample now accepts `status-aggregation` and
per-transaction `status-aggregate-output` bindings, while generated `.isf`,
`.fsm`, and SystemVerilog output-bank behavior remains unchanged. Schedule JSON
reports the scalar aggregate contract as metadata:

```text
read_data:
  mode: bounded_multi_beat_read_data_contract
  residue:
    - generated_rresp_aggregation
  read:
    status_policy: per_beat
    status_aggregation: worst_observed
    status_aggregation_generated_behavior: false
    status_aggregate_output: per_transaction_scalar
    status_aggregate_output_width: 2
    transactions:
      - transaction: r0
        status_output_prefix: axi0_r0_beat_rresp
        status_aggregate_output: axi0_r0_rresp
        status_aggregate_output_width: 2
```

Generated scalar aggregate outputs are intentionally absent in this slice. The
existing generated output-bank still exposes per-beat status lanes, valid
masks, and length outputs; there is no generated scalar output such as:

```text
(output axi0_r0_rresp (width 2))
```

The next frontier after `.77` was
`IAL2-FEATURE-COMPLETENESS-FRONTIER.78`, generated scalar `RRESP`
aggregation readiness before behavior changes.

RRESP aggregation behavior readiness:
[AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT](../../AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_READINESS_AUDIT.md)
records the `.78` readiness audit. It found no new IAL1, IAL0, or
SystemVerilog prerequisite for first generated width-2 `worst_observed`
behavior.

RRESP aggregation behavior first slice:
[AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE](../../AXI_IAL2_MANAGER_RRESP_AGGREGATION_BEHAVIOR_FIRST_SLICE.md)
ships generated scalar aggregation behavior for the selected width-2
`worst_observed` contract. The public multi-beat sample now emits one scalar
aggregate output per read transaction:

```text
(output axi0_r0_rresp (width 2))
```

The existing output-bank initialization rule initializes the aggregate to
`OKAY` on the transaction request:

```text
(rule axi0_r0_read_data_output_init axi0_r0_request
  ...
  (axi0_r0_rresp 2'd0)
  ...)
```

Each transaction also gets a matched-beat update rule. The rule keeps the
worst width-2 value observed so far:

```text
(rule axi0_r0_rresp_aggregate
  (& MATCHED_READ_BEAT
     (! axi0_r0_request)
     (< axi0_r0_rresp axi0_rresp))
  (axi0_r0_rresp axi0_rresp))
```

The `! REQUEST_EVENT` boundary is mandatory. It keeps scalar aggregation
aligned with the generated output-bank same-cycle request/response behavior.

Schedule JSON now reports generated aggregate artifacts and no scalar
aggregation residue for the selected contract:

```text
read_data:
  residue: []
  read:
    status_aggregation: worst_observed
    status_aggregation_generated_behavior: true
    generated_status_aggregate_outputs:
      - axi0_r0_rresp
      - axi0_r1_rresp
    generated_status_aggregate_init_rules:
      - axi0_r0_read_data_output_init
      - axi0_r1_read_data_output_init
    generated_status_aggregate_update_rules:
      - axi0_r0_rresp_aggregate
      - axi0_r1_rresp_aggregate
```

No-aggregation multi-beat contracts remain valid and continue to report
`status_aggregation: none` with `read_data.residue: [rresp_aggregation]`.

Post-RRESP aggregation selector:
[AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION](../../AXI_IAL2_MANAGER_POST_RRESP_AGGREGATION_NEXT_SLICE_SELECTION.md)
selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.81`, AXI per-ID read-data
interleaving and queue readiness. The live public multi-beat sample now has
empty `read_data` and `auto_id_lifecycle` residue. Remaining AXI manager
residue clusters around `response_demux` read-data interleaving/bursts and
`same_id_ordering` concrete-ID same-ID ordering, per-ID issue queues,
read-data interleaving, and bursts.

Verification-code generation is a valid future FSMGEN target lane. It should
be separate from the current synthesizable RTL path, so SV/UVM agents,
monitors, scoreboards, protocol checkers, coverage, and reusable verification
IP can use the full non-synthesizable target-language surface without
weakening RTL lowering. Width-3 responses, alternate policies, aggregate-only
shapes, packed outputs, per-ID queues, direct backend lowering, and VHDL
remain deferred in the current RTL lane.

That verification lane is now task-tree owned by
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER`. Its default source stance is
IAL1 (`.isf`) to verification code, not direct IAL2 to verification. The
source-readiness audit
[IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT](../../IAL1_VERIFICATION_CODE_GENERATION_SOURCE_READINESS_AUDIT.md)
found the existing IAL1 assert/assume/cover/property/monitor surface sufficient
for inline SystemVerilog assertion projection, but insufficient for
first-class generated SV/UVM or VHDL-oriented verification artifacts. The
observation selector
[IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION](../../IAL1_VERIFICATION_OBSERVATION_CONTRACT_SELECTION.md)
then selected actor-level passive observation metadata,
`(observe NAME (role passive_monitor) (signals SIG...))`, as the first IAL1
verification-specific source feature. `ISF-VERIFICATION-OBSERVATION-METADATA.1`
shipped the parser, additive `verification_observations[]` schedule-report
projection, public contract metadata, supported-smoke fixture, and mdBook
example for that report-only metadata. The SV/UVM selector
[IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION](../../IAL1_SV_UVM_PASSIVE_MONITOR_SKELETON_CONTRACT_SELECTION.md)
then selected a passive UVM monitor skeleton package as the first SV/UVM
output target. It may declare inert UVM 1.2 snapshot item and monitor classes
from `verification_observations[]`, but it must not sample a DUT interface,
publish transactions, infer events, build an agent, generate a scoreboard,
generate coverage, or emit reusable VIP behavior. Public CLI, artifact layout,
report/manifest shape, support-accounting identity, and validation gates now
have their own selector:
[IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION](../../IAL1_VERIFICATION_OUTPUT_PUBLIC_SURFACE_CONTRACT_SELECTION.md).
It chose the command `--emit-verification-output
uvm-passive-monitor --verification-outdir DIR source.isf`, with artifacts at
`DIR/uvm/<actor>_observation_uvm_pkg.sv` and
`DIR/verification-output-manifest.json`. Implementation
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.8` now ships that bounded inert
UVM passive-monitor skeleton output for `.isf` sources with passive
`verification_observations[]`. The output is reviewable source plus a manifest;
FSMGen still does not claim UVM compile support. The VHDL selector
[IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION](../../IAL1_VHDL_VERIFICATION_OUTPUT_CONTRACT_SELECTION.md)
selected no VHDL verification artifact yet: the current VHDL path is a
synthesizable scaffold, VHDL/GHDL validation is not active, and
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.9` selected shape-only
inert-artifact validation with explicit no-compile/no-PSL manifest claims. The
validation-substrate selector
[IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION](../../IAL1_VHDL_VERIFICATION_VALIDATION_SUBSTRATE_SELECTION.md)
enabled the VHDL artifact selector
[IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION](../../IAL1_VHDL_OBSERVATION_PACKAGE_CONTRACT_SELECTION.md),
which chose `vhdl-observation-package`: an inert VHDL observation metadata
package with canonical id `vhdl_observation_package_skeleton`.
`IAL1-VERIFICATION-CODE-GENERATION-FRONTIER.11` now implements that bounded
target:

```bash
./bin/fsmgen --emit-verification-output vhdl-observation-package \
  --verification-outdir generated-verification \
  isf/verification_observation_metadata.isf
```

The command writes `generated-verification/vhdl/<actor>_observation_vhdl_pkg.vhd`
plus `generated-verification/verification-output-manifest.json`. The VHDL
package is metadata-only: it records observation name/role/clock/reset and
signal name/direction/width constants, and it does not contain an entity,
architecture, process, assert, PSL, testbench, scoreboard, coverage, simulator
binding, analyzer claim, reusable VIP behavior, or direct IAL2 protocol
behavior. The direct IAL2 route audit
[IAL1_DIRECT_IAL2_VERIFICATION_ROUTE_AUDIT](../../IAL1_DIRECT_IAL2_VERIFICATION_ROUTE_AUDIT.md)
selects no direct `.ppif` verification-output route for the current lane:
future protocol-specific verification facts should first lower or annotate
generated IAL1 `.isf` review artifacts, then reuse the IAL1
verification-output path unless a later exact owner proves a direct route is
required. Scoreboard behavior, coverage behavior, and reusable VIP behavior
remain deferred behind later selector leaves.
