# FSMGen SourceHIR version-2 concrete-control private contract

Date: 2026-07-30
Owner: `FSMGEN-HIR-ROADMAP-FRONTIER.6`
Status: selected and privately implemented under `.7`

Clean contract commit `f42fb033d` activated `.7` continuity-only. The private
implementation now satisfies this contract without changing the parser,
fixture, public surface, or existing behavior.

## Outcome

SourceHIR version 2 adds one closed private `concrete_control` root that
represents the semantic subset exercised by `isf/phase_test.isf`. It renders
canonical IAL1/ISF text, then enters the shipped
`FSM::Adapter::ISF -> FSM::Scheduler::ISF -> IAL0` path.

Version 2 is a discriminated SourceHIR object, not a copy of the ISF parser AST
and not a raw Lispish syntax tree. It models an actor, ordered scalar ports,
one parameterized named drive, and one trigger/ordered-phase/completion
transaction with typed semantic fields. The renderer alone owns canonical ISF
spelling, parentheses, indentation, scalar-width elision, and final newline.

This contract changes no code, test, parser, fixture, generated artifact,
configuration, CLI/API/report/manifest/accounting surface, HDL/runtime, or
existing behavior. Version 1 remains byte-for-byte and API compatible.

## Why `isf/phase_test.isf`

The selected fixture is 17 lines, 395 bytes, and SHA-256
`6eeab6c6f2e87c4a91f97fd8c0f2535334a163a7ccf263f30dfcefae51b0d2f2`.
It is the smallest mainstream checked IAL1 fixture that combines:

- an explicit actor, clock, and asynchronous active-low reset;
- ordered input/output declarations with scalar and width-32 ports;
- one named drive with a semantic parameter-to-output assignment;
- one scalar trigger;
- three ordered concrete transaction states; and
- one scalar completion pulse.

Existing t1179 and t1312 coverage already proves parser validation,
pass-through phase-state lowering, exact transaction state order, schedule
reporting, strict CLI acceptance, and generated HDL reachability. The fixture
does not require ATL, composition, libraries, rules, resources, arbitrary
expressions, or protocol-specific policy.

`isf/phase_test.isf` remains phase-metadata/pass-through coverage; SourceHIR
does not reinterpret `(outputs ...)` or `(next ...)` as a new actor-level
scheduler. It merely constructs the already shipped transaction-phase subset.

## Rejected fixture alternatives

- `isf/atl_trigger_wait_pipeline.isf` is shorter but selects the separate ATL
  actor-network/composition model rather than a basic concrete actor.
- `isf/verification_observation_metadata.isf` is metadata-oriented and would
  entangle the first concrete route with verification-output policy.
- `isf/when_test.isf` and `isf/switch_test.isf` add expression and branch
  contracts before the actor/port/ordered-state seam is proved.
- protocol-facing ISF samples would duplicate the version-1 protocol-intent
  evidence instead of proving the distinct concrete-control route.

## Private package and method surface

Implementation leaf `.7` changed only this private package family:

- extend `FSM::IR::SourceHIR` for the discriminated version-2 root;
- extend `FSM::IR::SourceHIRBuilder` with concrete-control validation/build;
- add `FSM::IR::SourceHIRISFRenderer` for canonical IAL1 handoff; and
- add focused `t/1548-source-hir-phase-control.t`.

The exact class methods are:

```perl
FSM::IR::SourceHIRBuilder
    ->validate_concrete_control($input);

FSM::IR::SourceHIRBuilder
    ->build_concrete_control($input);

FSM::IR::SourceHIRISFRenderer
    ->render_isf($source_hir);

FSM::IR::SourceHIRISFRenderer
    ->diagnostic_from_isf_error($rendered, $error_text);
```

The builder methods accept exactly one hash reference and must be called on
the exact class invocant. `validate_concrete_control` returns a fresh ordered
array of private diagnostic hashes. `build_concrete_control` returns an
immutable `FSM::IR::SourceHIR` or throws the formatted first diagnostic.

The renderer methods are exact-class calls. `render_isf` accepts exactly one
version-2 `concrete_control` SourceHIR object. The diagnostic remapper accepts
exactly one closed renderer-result hash and one defined scalar error.

No public constructor is added. `SourceHIR->_new_validated` remains the only
object constructor and stays builder-owned.

## Object access

The existing root-independent methods continue to work for both versions:

```perl
$hir->schema_version;
$hir->root_kind;
$hir->provenance;
$hir->source_location_for($semantic_path);
$hir->as_hashref;
```

Version 2 adds exactly:

```perl
$hir->control_actor;
```

`control_actor` returns a defensive clone and rejects a version-1 object.
The version-1 protocol accessors retain their current results for version 1
and deterministically reject a version-2 root rather than returning partial
or misleading protocol data. No mutator or raw internal-reference accessor is
added.

## Closed object shape

The top-level version-2 object has exactly:

```text
schema_version: integer 2
root_kind: "concrete_control"
actor: closed actor hash
provenance: closed provenance hash
```

### Actor

```text
actor:
  name: ISF identifier
  clock: ISF identifier
  reset:
    signal: ISF identifier
    active_level: integer 0 or 1
    kind: "async" or "sync"
  ports: non-empty ordered array of port hashes
  drive_blocks: ordered array containing exactly one drive-block hash
  transactions: ordered array containing exactly one transaction hash
```

### Ports

Each port has exactly:

```text
direction: "input" or "output"
name: ISF identifier
width: positive integer
```

Names are unique across all ports. At least one input and one output are
required. The actor name, clock, and reset signal are distinct identifiers.
The clock and reset signal must not collide with any port name.
The selected fixture uses, in order:

```text
input  start width 1
output done  width 1
output rdata width 32
```

### Named drive blocks

Each drive block has exactly:

```text
name: ISF identifier
parameters: non-empty ordered array of unique ISF identifiers
assignments: non-empty ordered array of assignment hashes
```

Each assignment has exactly:

```text
target: declared output port name
value: declared drive parameter name
```

Targets are unique within a block and every declared parameter is used. This
first subset permits no literal, operator, selector, call, or raw expression
string. A drive-block name may equal its output target, matching the selected
fixture. Drive-block names are unique across blocks.

The selected block is semantically:

```text
name rdata; parameter val; assign output rdata from parameter val
```

### Transactions and phases

Each transaction has exactly:

```text
name: ISF identifier
trigger:
  signal: declared width-1 input port
phases: non-empty ordered array of phase hashes
completion:
  signal: declared width-1 output port
```

Each phase has exactly:

```text
name: ISF identifier
outputs: non-empty ordered array of declared output port names
next: next phase name, omitted only on the final phase
```

Transaction names are unique. Phase names are unique within the transaction.
Each non-final phase's `next` must name the immediately following phase; the
final phase must omit `next`. Output names are unique inside a phase. This
closed linear-chain rule is deliberately narrower than arbitrary control-flow
graphs and prevents syntax-shaped clause storage.

The selected transaction is:

```text
t: trigger start
  first_phase  outputs rdata -> second_phase
  second_phase outputs done  -> last_phase
  last_phase   outputs done
  complete done
```

## Provenance and semantic paths

The version-2 provenance shape is identical in principle and key shape to
version 1:

```text
provenance:
  source_name: repository-relative path or stable logical name
  spans:
    <recognized semantic path>:
      start_line, start_column, end_line, end_column: positive integers
```

`/` is required. Machine-absolute paths, parent traversal, backslashes,
unknown paths, malformed spans, and end-before-start ranges fail closed.
Exact-path, nearest-ancestor, then root fallback remains unchanged.

Recognized version-2 paths are exactly the structural paths implied by the
closed object, including:

- `/`, `/schema_version`, `/root_kind`, `/actor`, `/provenance`;
- scalar actor/reset fields;
- `/actor/ports/<index>` and each port field;
- `/actor/drive_blocks/<index>`, its fields,
  `/parameters/<index>`, `/assignments/<index>`, and assignment fields;
- `/actor/transactions/<index>`, trigger, phases, completion, and their
  indexed/scalar fields; and
- provenance source-name/spans fields.

Array order is semantic and preserved. Hash insertion order is not semantic
and may not affect validation, normalized objects, or rendering.

## Validation order and diagnostics

Validation is deterministic depth-first in this order:

1. input reference kind and unknown top-level keys;
2. schema version and root kind;
3. actor name, clock, reset, ports, drive blocks, transactions;
4. cross-reference/uniqueness/width constraints;
5. provenance shape, recognized paths, and span coordinates.

Within a closed hash, unknown keys are diagnosed in lexical order. Arrays are
validated in authored order. Validation returns every discovered diagnostic
without relying on Perl hash insertion order.

Validation diagnostics keep the existing private closed shape and code:

```text
schema_version: 2
severity: "error"
code: "FSMGEN_SOURCE_HIR_INVALID"
phase: "source_hir_validation"
message: one-line scalar
semantic_path: recognized path or nearest valid container
source_location: resolved original location
```

The formatted `build_concrete_control` failure remains:

```text
Error [<code>] <source_name>[:<line>:<column>] <semantic_path>: <message>\n
```

## Canonical IAL1 renderer

`render_isf` returns a fresh closed hash with exactly:

```text
schema_version: 2
format: "isf"
source_label: "source-hir-generated/phase_test.isf"
text: canonical ISF ending in exactly one newline
source_map: ordered array of closed entries
```

The source label is derived from the validated actor name and accepts no path
input. A scalar width of 1 renders without `(width 1)`; widths greater than 1
render as `(width N)`. Reset renders as
`(<signal> async|sync active_low|active_high)`, matching canonical ISF order.

For the selected input the renderer reproduces
`isf/phase_test.isf` byte-for-byte:

- 17 lines;
- 395 bytes;
- SHA-256
  `6eeab6c6f2e87c4a91f97fd8c0f2535334a163a7ccf263f30dfcefae51b0d2f2`;
- LF line endings; and
- exactly one final newline.

The emitted clause order is actor, clock, reset, blank line, interface/ports,
blank line, drive blocks, blank line, transactions with trigger/phases/
completion. Input order is preserved for every list. The implementation reads
the tracked fixture as its byte oracle and must not rewrite it.

## Source map and downstream remapping

Each source-map entry has the version-1 closed shape:

```text
semantic_path
generated_span: start_line, start_column, end_line, end_column
source_location: source_name plus resolved coordinates
```

There is one entry for each of the 14 non-empty generated lines plus one root
entry covering the complete 17-line generated document. Blank separator lines
have no invented character span and therefore resolve only through the root
entry. Generated coordinates are one-based, inclusive, and exclude newline
bytes.

`diagnostic_from_isf_error` uses code
`FSMGEN_SOURCE_HIR_ISF_REJECTED`, phase `isf_handoff`, and the same closed
handoff-diagnostic additions as version 1:

```text
downstream_message: first non-empty error line with Perl stack suffix removed
generated_location: source label plus extracted line/column when present
```

It searches the sanitized first line for
`<source_label>:<line>[:<column>]`, then `line <line>` with optional column,
selects the smallest containing source-map span, and otherwise uses `/` plus
root provenance. The current ISF parser commonly reports the source label but
not a generated position, so root fallback is required and truthful; the
remapper must not invent a semantic field from message text.

## Existing-pipeline equivalence oracle

Focused t1548 does:

1. build and render the selected version-2 object;
2. compare rendered bytes to `isf/phase_test.isf`;
3. parse both texts through `FSM::Adapter::ISF->parse_source`;
4. prove equal typed actor structures;
5. lower both through independent `FSM::Scheduler::ISF` instances;
6. prove equal `phase_test.fsm` text and equal schedule reports; and
7. preserve the existing one-file IAL0 result.

The current lowering oracle is:

- one file named `phase_test.fsm`;
- 45 lines;
- 484 bytes; and
- SHA-256
  `8b82ddb329a6b625d0ec271d9611b35140414a2c84e775c1615e442cdfa65047`.

Schedule invariants include actor `phase_test`, clock `clk`, async active-low
`rst_n`, three ports, five states, one transaction `t`, ordered states
`t_idle_0`, `t_phase_1`, `t_phase_2`, `t_phase_3`, `t_done_4`, one `rdata`
drive block, and current completion/drive inferred storage.

The ISF renderer must depend only on `FSM::IR::SourceHIR`. It may not call the
ISF adapter, scheduler, IAL0 emitter, or backend. The test owns parser and
scheduler re-entry.

## Focused implementation coverage

Leaf `.7` adds only `t/1548-source-hir-phase-control.t` for the new boundary.
It covers:

- exact class/argument boundaries and version/root dispatch;
- version-1 behavior preservation through t1547;
- deep input cloning, immutable object access, and renderer non-mutation;
- every closed-schema and cross-reference rejection class;
- deterministic diagnostic ordering and exact/ancestor/root provenance;
- deliberately reordered input hashes with identical normalized/rendered
  results;
- alternate ordered identifiers, reset kind/polarity, scalar/width rendering,
  list ordering, and linear phase references within the selected subset;
- exact 17-line/395-byte/source-hash golden output;
- source-map shape and generated-line/root-fallback remapping with stack-path
  sanitization;
- equal existing-parser actor, schedule report, and exact 45-line/484-byte
  IAL0 output; and
- absence of CLI, public report, capability, language-surface, and support-
  accounting exposure.

Focused regression includes t1547, t1179, and t1312 plus syntax checks for the
four changed/new Perl/test files. No new runtime simulation is required because
the fixture's unchanged bytes and t1312 already own strict HDL reachability;
the implementation changes only a private producer of those exact bytes.

## Deferrals

Version 2 does not select:

- multiple actors, transactions, drive blocks, clocks, or reset domains;
- guards, branches, loops, rules, priorities, resources, storage, procedures,
  calls, stages, awaits, spawns, ATL, composition, libraries, imports, types,
  enums, constants, crossings, properties, or verification observations;
- arbitrary expressions, literals, selectors, operators, quoted/raw ISF
  fragments, or user-controlled formatting;
- direct typed-AST construction, direct scheduler calls, direct IAL0/backend
  lowering, a persisted source-map sidecar, or fixture rewriting; or
- a public HIR schema, builder language, package, CLI mode, report projection,
  capability, support-accounting promise, or compatibility version.

## Migration and failure rule

Version 1 remains accepted by its existing methods and renderer without byte,
diagnostic, accessor, or downstream changes. Version 2 is additive and private;
no existing source migrates.

Implementation preserves the semantic closed subset, deterministic provenance,
exact canonical fixture, existing parser/scheduler re-entry, and version-1
behavior without embedding raw ISF syntax or duplicating the parser AST. The
failure rule remains the guardrail for later changes. Only `.8` may reconsider
promotion.

## Implementation evidence

`FSM::IR::SourceHIR` now dispatches immutable access by root kind;
`FSM::IR::SourceHIRBuilder` validates/builds the complete closed version-2
shape; and `FSM::IR::SourceHIRISFRenderer` emits canonical ISF plus a private
source map and diagnostic remapper. T1548 proves exact fixture and IAL0 hashes,
equal typed actors/schedules, ordered variants, malformed-input rejection,
provenance, deterministic rendering, truthful no-position root fallback, and
absence from public surfaces. T1547, t1179, and t1312 preserve version 1 and the
existing phase path. Repository-local test scratch is removed after use.
