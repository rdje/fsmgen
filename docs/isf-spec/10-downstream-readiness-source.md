# ISF Downstream Integration Specification

Status: `bounded_public`
Document version: `2026-06-26`
ISF source specification: `.isf` specification v0.6
Primary audience: downstream tools that emit, validate, inspect, or consume
FSMGen Intent Scheduling Format sources and reports.

This is the single downstream-facing integration contract for the current
`.isf` / IAL1 surface, and it anchors how IAL2 sources that lower through
`.isf` interact with downstream tools. A consumer should be able to implement
against this document for IAL1 behavior without reading the mdBook, Perl
modules, task trees, or tests first. Those artifacts remain the implementation
evidence and evolution history; this file packages the current public IAL1
contract and the downstream file-surface stack in one place.

Synchronization invariant: this document must stay truthful with respect to
the live `.isf` spec, the mdBook, the public contract, the manifest metadata,
the support-accounting catalog, the regression tests, explicit deferrals, and
the codebase itself. A mismatch between this file and implementation behavior
is a project bug. Do not update this file as an aspirational design note;
update it only with the same slice that changes the source language,
diagnostics, lowering behavior, public facade, schedule JSON, generated
artifacts, fixtures, support status, or documented deferrals.

## 1. Readiness And Stability

`.isf` is defined and implemented, but it is not a frozen external standard.
The current integration status is `bounded_public`:

- Source files ending in `.isf` are accepted by `bin/fsmgen`.
- The parser and scheduler have public in-process facades.
- Accepted sources lower to explicit scheduled `.fsm` review artifacts.
- Schedule reports are emitted as JSON through `--emit-schedule-json` or the
  in-process scheduler facade.
- Single-clock accepted sources reach SystemVerilog/Verilog-family HDL through
  the normal `.fsm` backend.
- Accepted multi-domain event-crossing sources lower to generated domain/top
  artifacts and can reach SystemVerilog/Verilog-family HDL with concrete CDC
  child modules when the emitted domain artifacts satisfy the scheduled `.fsm`
  HDL contract, including clock-only no-reset domains.
- Public syntax, public lower-result shape, and public schedule-report key
  families are regression-backed.

The source/lowering contract remains bounded even though schedule JSON
`schema_version: 1` is now stable:

- Parser acceptance alone is not support.
- A construct is public only when this document gives its source shape,
  lowering behavior, runtime meaning, diagnostics boundary, report visibility,
  and regression evidence.
- Full raw parser hashes and full `LoweringIR` objects are not frozen. The
  schedule JSON schema is stable for `schema_version: 1`; use the key/value
  families described here and the machine-readable manifest for exact
  discovery.
- Future downstream-visible `.isf` or `.ppif` changes must update this
  document, the public contract, manifest metadata, support accounting, tests,
  and book content in the same implementation slice.

## 2. Integration Pipeline

The current semantic pipeline is:

```text
Downstream intent source
  -> .isf source
  -> FSM::Adapter::ISF parser
  -> FSM::Scheduler::ISF lowering
  -> scheduled .fsm review artifacts
  -> SystemVerilog / Verilog-family HDL
```

Intent abstraction levels:

- `.fsm` is Intent Abstraction Layer 0 (`IAL0`). It is explicit cycle-authored
  hardware intent and owns DT structure, assignment operators, state and
  non-state activation regions, mux-selection semantics, and exact runtime
  behavior.
- Current `.isf` is Intent Abstraction Layer 1 (`IAL1`). It is scheduling
  intent above `.fsm`: actors, transactions, drives, samples, waits, control
  flow, generated child activations, rules, storage, libraries, constraints,
  and selected clock-domain metadata lower into reviewable `.fsm`.
- `.ppif` is the first shipped Intent Abstraction Layer 2 (`IAL2`) public file
  surface. It is Protocol/Platform Intent Format source and always lowers
  through generated `.isf` before generated `.fsm`; direct IAL2-to-IAL0
  lowering is not a public contract.
- The public `.ppif` surface is the generic protocol/platform IAL2 container:
  AXI is the first shipped IAL2 profile/example, not the definition of IAL2.
  Future protocol-specific suffixes such as `.axi`, `.chi`, `.ace`, `.ahb`,
  `.apb`, `.atb`, `.smbus`, or `.i2s` are profile aliases over IAL2 rather
  than separate layers. Common IAL2 constructs stay small until compatible
  reuse is proven across multiple profiles.
- Current bounded `.ppif` coverage includes one-channel Valid-Ready sources,
  including the AXI AW first-profile sample and the protocol-neutral
  valid-ready handshake sample, the AXI AW/W multi-channel Valid-Ready bundle,
  the protocol-neutral dual-channel Valid-Ready bundle, and one-object AXI
  manager capacity/status sources. Support-accounted AXI
  manager coverage includes
  capacity/status, ID-family metadata, transaction envelopes and fan-in,
  concrete-ID assertions, bounded auto-ID lifecycle, same-ID reject and
  issue-order-queue policy, generated auto-ID write/read response-demux,
  generated single/last/multi-beat read-data capture, burst-length/runtime
  validation, scalar `RRESP` aggregation, one-or-more read burst-last
  queue-head groups, one-or-more write queue-head groups, read single-beat and
  read burst-last queue-head response-demux including multiple/mixed depth-3
  scalar, raw-`ARLEN`, runtime-validation, and multi-beat output-bank read-data
  groups, same-family mixed auto-ID plus concrete queue-head response-demux
  with scalar, raw-`ARLEN`, runtime-validation, and multi-beat output-bank
  read-data over the selected read burst-last shape, generated single-active
  and multiple all-dynamic write/read response-demux, generated all-dynamic
  same-ID issue-order queues for selected write `BID`, read single-beat `RID`,
  and read burst-last `RID && RLAST` depth-2/depth-3 shapes, selected
  read-data, raw-`ARLEN`, runtime-validation, and multi-beat output-bank
  behavior over generated all-dynamic read burst-last issue-order queues,
  generated mixed dynamic/static response-demux families, generated
  one-dynamic plus one-concrete-static mixed dynamic/static same-ID
  issue-order queue behavior for write `BID`, read single-beat `RID`, and read
  burst-last `RID && RLAST`, generated one-dynamic plus two-concrete-static
  mixed dynamic/static write `BID` same-ID issue-order queue behavior, paired
  scalar read-data over the generated mixed read single-beat and burst-last
  queue completions, report-only raw-`ARLEN` burst-length capture, runtime
  beat-count/`RLAST` validation, and runtime-validation multi-beat output
  banks over the generated mixed read burst-last queue completion.
- Broader mixed issue-order queue cardinality beyond that selected write
  `BID` multi-static shape, scoreboards, group-local simultaneous enqueue
  widening, packed burst-vector outputs, alternate full
  burst payload assembly, aliases, platform clauses, full AXI manager behavior,
  direct backend lowering, verification-output generation, backend-language
  variants, and VHDL remain deferred.
- The machine-readable source of truth for shipped suffixes, layers, lowering
  order, CLI modes, and current per-suffix boundary text is
  `./bin/fsmgen --capability-manifest` under
  `language_surface.file_surfaces`. That manifest boundary, this handoff, the
  public contracts, the mdBook, the support-accounting catalog, and the
  codebase must remain lockstep for every downstream consumer.

## 3. CLI Entry Points

Supported `.isf` CLI surfaces:

```bash
./bin/fsmgen source.isf
./bin/fsmgen --strict source.isf
./bin/fsmgen --emit-schedule-json source.isf
./bin/fsmgen --outdir /tmp/isf-build source.isf
./bin/fsmgen --output /tmp/out.sv source.isf
```

CLI behavior:

- Plain `file.isf` generation lowers through scheduled `.fsm`, then runs the
  normal `.fsm` HDL path.
- `--strict file.isf` follows the same accepted-success shape and keeps stderr
  empty on success.
- `--emit-schedule-json file.isf` prints the scheduler report JSON to stdout
  and exits before HDL generation.
- `--outdir DIR file.isf` writes every lowered `.fsm` artifact by basename into
  `DIR`; for multi-file lowers, the parent/generated-top artifact is the entry
  artifact used by later generation.
- `--capability-manifest` exposes the machine-readable contract at
  `embedding.isf_public_interface`.

CLI options advertised as part of the ISF public surface:

```text
--emit-schedule-json
--outdir
--strict
```

## 4. In-Process API Entry Points

The public Perl facades are:

```perl
use FSM::Adapter::ISF;
use FSM::Scheduler::ISF;

my $parser = FSM::Adapter::ISF->new(debug => 0);
my $actor  = $parser->parse_file('source.isf');
my $actor2 = $parser->parse_source($source_text, 'source-label.isf');

my $scheduler = FSM::Scheduler::ISF->new(debug => 0);
my $lowered   = $scheduler->lower($actor);
my $json      = $scheduler->report($actor);
```

Constructor and receiver rules:

- Constructors require the exact `FSM::Adapter::ISF` or
  `FSM::Scheduler::ISF` class invocant.
- The only public constructor option is `debug`.
- Public methods require objects returned by their matching constructors.
- `parse_file(path)` requires one defined scalar path naming a readable `.isf`
  file.
- `parse_source(text, label)` requires defined scalar source text and label.
- `lower(actor)` and `report(actor)` require one scheduler-consumable actor
  hash returned by the parser.
- Public facade boundary failures die with scalar diagnostics before private
  parser/lowering internals are used.

Lower result shape:

```text
{
  files => {
    "basename.fsm" => "scheduled .fsm source text",
    ...
  }
}
```

The `files` map is the bounded lower-result surface. File keys are `.fsm`
basenames with no directory components. File text is scheduled `.fsm` or
generated-top `.fsm` text rooted at `(?fsm:<basename-stem> ...)` or
`(?top:<basename-stem> ...)`, optionally followed by generated interface
metadata such as `?rtlif` for explicit CDC children.

## 5. Source File Model

`.isf` is Lisp-ish S-expression source. Forms use parenthesized lists, scalar
tokens, and nested list expressions. The public compile/report root is one
actor:

```lisp
(actor actor_name
  actor_clause...)
```

FSMGen rejects sources with multiple top-level `(actor ...)` roots. A sibling
actor root is not an ATL child type definition; downstream producers must keep
one compile/report entry actor until FSMGen publishes an explicit actor
type-resolution contract. Additional `(library ...)` roots remain the
accepted same-source reusable actor packaging surface.

The shipped ATL actor type-resolution source is library-qualified: `(instance
NAME of ALIAS.EXPORT)`, where `ALIAS` comes from the enclosing actor's
`(imports (library ... as ALIAS))` clause and `EXPORT` is an actor export
from that library.

Resolved qualified instances report library/export provenance on
`actor_network.instances[]` and now emit child scheduled `.fsm` artifacts
named by their `scheduled_fsm` fields.

The first generated ATL top is shipped for exactly one resolved child with
one parent trigger handoff and one parent event wait in the same clock/reset
policy.

That top is reported through `actor_network.generated_tops[]`, instantiates
the parent and child, wires public pins to the parent, wires the parent
trigger handoff to the child transaction start input discovered from the
child transaction's scalar `(on START_SIGNAL)`, and wires the child scalar
event output back to the parent event handoff input.

Downstream producers must still treat broader ATL top emission, multi-child
scheduling, data-route coupling, route mux/storage,
payload/ready/backpressure bindings, CDC, recursive actor networks, and
permanent actor grouping as unavailable until later leaves explicitly ship
them.

Imported files may also contain library roots:

```lisp
(library library.name
  library_clause...)
```

General source rules:

- Names that identify actors, ports, storage, transactions, rules, drives,
  parameters, domains, and instances are scalar HDL identifiers. Current
  accepted identifier spelling is compatible with `[A-Za-z_][A-Za-z0-9_]*`.
  Child instance labels authored by `spawn ... as`, reusable-library
  `use ... as`, or ATL static instance declarations must additionally be
  non-reserved across the shipped HDL targets. SystemVerilog keyword matching
  is case-sensitive; VHDL-2008 matching is case-insensitive. Reserved labels
  fail at their source boundary and are not silently renamed.
- Widths and depths are positive integer literals unless a specific clause says
  otherwise. Actor top-level interface port widths, actor-owned scalar storage
  widths, actor-owned bank storage widths, actor-owned bank storage depths,
  and transaction-local port widths also accept declared actor constants and
  actor-local scalar parameter defaults that resolve to positive integers.
  Actor top-level interface port widths, actor-owned scalar storage widths,
  actor-owned bank storage widths, actor-owned bank storage depths, and
  transaction-local port widths additionally accept qualified imported package
  scalar constants that resolve to positive integers; the parser handoff,
  scheduled `.fsm`, activation handoff storage where applicable, schedule
  report, and generated HDL publish the resolved integer width or depth.
  Generated child and direct/non-generated transaction-local port widths
  additionally accept same-transaction scalar parameter defaults that resolve
  to positive integers.
- Actor constants use non-negative integer literals or enum member references
  that resolve to non-negative integers. Actor parameter scalar defaults may
  also use earlier actor-local scalar parameter defaults by name, preserving
  authored tokens while resolving those names internally. Generated child
  transaction parameter defaults may use numeric/exact-width literals,
  declared actor constants, actor-local scalar parameter defaults, earlier
  scalar transaction parameter defaults, enum members, qualified imported
  package scalar constants, or compatible aggregate/list literals with those
  scalar leaf sources; actor constants and actor scalar parameter defaults are
  published as literal child/report defaults while earlier transaction
  parameter names, enum tokens, and qualified package-constant tokens stay
  authored in child review artifacts. Package-constant-backed transaction
  defaults require imported `PACKAGE.CONSTANT` scalar package `+constants`
  entries; unqualified package constants, aggregate package constants, and
  package member/item paths fail closed.
  Static wait counts use non-negative integer literals, same-transaction
  scalar parameter defaults, actor constants, actor-local scalar parameter
  defaults, or qualified imported package scalar constants. Static latency
  bounds use positive integer literals, same-transaction scalar parameter
  defaults, actor constants, actor-local scalar parameter defaults, or
  qualified imported package scalar constants. Top-level await-local watchdog
  limits use positive integer literals, same-transaction scalar parameter
  defaults, actor constants, actor-local scalar parameter defaults, or
  qualified imported package scalar constants; actor-level watchdog limits use
  the same set except transaction parameters.
- Numeric and exact-width integer literals are accepted where this document
  says scalar numeric literals are accepted.
- Runtime expression positions may use scalar tokens, numeric/exact-width
  literals, or non-empty list expressions. List expressions use the same
  Lisp-like operator-first shape consumed by the scheduled `.fsm` expression
  formatter.
- Runtime division and modulo expressions fail closed before scheduled `.fsm`
  emission when any divisor operand is a numeric/exact-width literal zero, an
  actor-level constant that resolves to zero, or an actor-local scalar
  parameter default that resolves to zero, including nested expression
  operands. Nonzero literal divisors, nonzero actor-constant divisors, nonzero
  actor-parameter divisors, and dynamic scalar divisors remain accepted;
  FSMGen does not yet prove arbitrary dynamic divisors nonzero.
- Singleton actor clauses are not mergeable. Repeating one fails closed rather
  than letting later clauses overwrite earlier fields.
