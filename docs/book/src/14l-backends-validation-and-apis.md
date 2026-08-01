# Backends, Validation, and Public APIs Backlog

## Backends And Validation

### Full VHDL Backend

Status: partially shipped; full backend remains backlog.

Goal: implement VHDL as a full HDL backend.

Current boundary: the CLI and `FSM::Pipeline::HDLGenerator` route
`target_language => 'vhdl'` direct single-FSM roots through
`FSM::HDL::FlattenedDT::Backend::VHDL`. The scaffold emits deterministic VHDL
entity/architecture text for scalar/vector ports, state constants,
continuous enable assignments, `process(all)` combinational muxes, sync-reset
clocked processes, async-reset clocked processes, delayed-pulse clock-branch
nested-if lowering, generic-bearing direct-root module headers as VHDL integer
generics or typed scalar/vector generics for sized-literal defaults, basic
concat RHS forms, scalar addition/subtraction/multiplication RHS/chain
lowering, generated scalar `bit` internal declarations as `std_logic`,
generated signed vector internal declarations as VHDL `signed`, generated mux
arithmetic with vector signal plus/minus numeric literal operands through
target-width `to_unsigned` casts, same-width vector addition/subtraction RHS
chain lowering through `numeric_std` unsigned casts, same-width vector
multiplication/division/modulo RHS chain lowering through explicit
target-width `numeric_std` resize, same-width scalar/vector XOR chain lowering
through VHDL `xor`, and generated non-signed four-state `logic` scalar/vector
internal declarations as `std_logic` / `std_logic_vector`, plus generated
vector `logic signed` internal declarations as VHDL `signed` signals and
generated signed vector direct-root port declarations as VHDL `signed` ports,
and same-width signed vector addition/subtraction/multiplication/division/modulo RHS
assignments as signed VHDL arithmetic.
Bounded direct aggregate-output fixtures now lower generated inferred packed
struct outputs as VHDL `std_logic_vector` ports with the generated packed
widths.
It is covered by direct pipeline, CLI, and facade tests.

The direct-VHDL expression adapter now recognizes generated unary reductions
before generic rewrites. Scalars/static bits use identity/complement; declared
vectors use required-only backend-owned `std_logic` OR/AND/XOR fold helpers,
with signed casts and helper-collision rejection. Range slices, invalid
selects, unresolved/compound/malformed/residual shapes fail closed. The real
named-drive, AMBA `HRESP`, and APB `wait_ctr`/`addr_q` outputs contain no
SystemVerilog reduction token. Public source arity remains unchanged. Decision
`0023` still prevents textual generation from being called executable VHDL
qualification because no `ghdl`, `nvc`, or `vcom` is installed.

Composition VHDL now includes the bounded C3 external-RTL literal/concat top
for `t/corpus/composition_intent_integer_literals.fsm` and the bounded C1
standalone-DT passthrough top for
`t/corpus/standalone_dtc_explicit_system_autowire.fsm`, plus the bounded C2
generated-FSM scalar-autowire top for
`t/corpus/implicit_composition_system_autowire.fsm`, plus the bounded APB/C4
generated-FSM top for `fsm/apb_tb.fsm` with scalar integer, scalar expression,
one-bit sized bitstring, multi-bit sized bitstring, and resolved packed
aggregate plus resolved package-backed generic maps in the same APB/C4 shape.
Still backlog beyond those exact owners: broader generated-FSM/C4 composition
VHDL, internal-net-heavy composition tops beyond APB, composition generic maps
beyond shipped external-RTL scalar integer, scalar integer expression,
metadata-backed one-bit sized bitstring, and multi-bit sized bitstring
literal/resolved-package-constant actuals plus
resolved packed aggregate actuals and shipped generated-FSM scalar integer,
scalar expression, one-bit sized bitstring, multi-bit sized bitstring, and
resolved packed aggregate actuals, plus shipped APB/C4 generated-FSM scalar
integer, scalar expression, one-bit sized bitstring, and multi-bit sized
bitstring actuals plus resolved packed aggregate and resolved package-backed
actuals, aggregate VHDL record/array lowering,
C2 generated-FSM aggregate actuals that do not lower to one packed literal
now locked fail-closed before VHDL emission,
VHDL package
declaration/emission, multi-clock domains, GHDL validation, broad expression
parity, signed scalar division/modulo,
mixed signed/unsigned scalar arithmetic, mixed signed/unsigned vector
arithmetic, and full feature parity with the
SystemVerilog backend. Scalar division/modulo,
broader scalar arithmetic beyond scalar addition/subtraction/multiplication
chains, broader arithmetic operators, mismatched-width arithmetic, and
expression contexts beyond the same-width
addition/subtraction/multiplication/division/modulo/XOR RHS chain family remain
fail-closed at the scaffold boundary. Scalar `A / B` and `A % B` are locked as
explicit fail-closed direct VHDL boundaries by focused pipeline and facade
coverage. The maintained
arithmetic/XOR and runtime division/modulo corpora now lower through the direct
VHDL scaffold for that family, and the maintained size-expression width fixture
now lowers generated direct-root parameter blocks to VHDL integer generics.
Generated sized-literal generic defaults such as `1'b1` and `1'b0` now lower
to typed `std_logic` generics in the maintained aggregate-parameter comparison
fixture, and multi-bit sized-literal generic defaults now lower to typed
`std_logic_vector` generics in the maintained aggregate unary complement
fixture. Maintained aggregate-output direct roots now lower as packed-vector
VHDL ports; full VHDL record/array aggregate lowering remains deferred.
External-RTL scalar integer, metadata-backed one-bit sized bitstring, and
multi-bit sized bitstring composition generic maps now lower to VHDL
`generic map` actuals before the port map, including qualified package
constants after they resolve to scalar integer or multi-bit sized bitstring
literals, scalar integer expressions such as `(16 + 1)`, one-bit scalar
actuals such as `ENABLE_DEFAULT => '1'`, and resolved packed aggregate values
such as `16'b1010010100111100`; broader
generic-map families remain deferred except for the bounded C1 standalone-DT
scalar integer actuals now emitted as `WIDTH => 16`, standalone-DT scalar
expression actuals now emitted as `EXPR_WIDTH => (8 + 1)`, standalone-DT
one-bit sized bitstring actuals now emitted as `ENABLE_DEFAULT => '1'`,
standalone-DT multi-bit sized bitstring actuals now emitted as
`RESET_VALUE => "10100101"`, standalone-DT packed-list actuals now emitted as
`LANES => "1010010100111100"`, standalone-DT packed-map actuals now emitted as
`FRAME => "101"`, bounded C2
generated-FSM scalar integer actuals now emitted as `WIDTH => 16`,
generated-FSM scalar expression actuals now emitted as `EXPR_WIDTH => (16 + 1)`,
one-bit sized bitstring actuals now
emitted as `ENABLE_DEFAULT => '1'`, multi-bit sized bitstring actuals now
emitted as `RESET_VALUE => "10100101"`, and resolved packed aggregate actuals
now emitted as VHDL bit strings, plus bounded APB/C4 generated-FSM scalar
integer actuals now emitted as VHDL integers such as `TIMEOUT_CYCLES => 8`
and scalar expression actuals emitted as VHDL expressions such as
`TIMEOUT_CYCLES => (4 + 1)`, and one-bit sized bitstring actuals emitted as
VHDL `std_logic` actuals such as `ENABLE_DEFAULT => '1'`, and multi-bit sized
bitstring actuals emitted as VHDL `std_logic_vector` actuals such as
`RESET_VALUE => "10100101"`, and resolved packed aggregate actuals emitted as
VHDL bit strings such as `LANES => "0011110010100101"` and `FRAME => "101"`.
APB/C4 resolved package-backed actuals now emit resolved VHDL literals such as
`TIMEOUT_CYCLES => 8` and `RESET_VALUE => "10100101"` without leaking
`param_pkg`.
The bounded C3 external-RTL
literal/concat structural top now emits a VHDL entity/architecture with
concurrent literal/concat assignments and an external `entity work.uart_tx`
port map. The bounded C1 standalone-DT passthrough structural top now emits the
standalone-DT child VHDL segment and a top-level
`entity work.standalone_route_src` port map; the same bounded C1 family now
also emits scalar integer generic maps such as `WIDTH => 16`, scalar
expression generic maps such as `EXPR_WIDTH => (8 + 1)`, and one-bit sized
bitstring generic maps such as `ENABLE_DEFAULT => '1'`, and multi-bit sized
bitstring generic maps such as `RESET_VALUE => "10100101"`, packed-list
generic maps such as `LANES => "1010010100111100"`, and packed-map generic
maps such as `FRAME => "101"` before that port map.
The bounded C2
generated-FSM scalar-autowire structural top now emits VHDL-safe generated-child
shared-datapath export ports/assignments, scalar structural signals, and both
generated child entity port maps; the same bounded C2 family now also emits
scalar integer, scalar expression, one-bit sized bitstring, multi-bit sized
bitstring, and resolved packed aggregate generic maps before the generated
child port map. The bounded APB/C4 generated-FSM structural top now emits APB requester/completer child
VHDL entities, vector APB
structural signals, deterministic shared-datapath sink signals, and both child
entity port maps; the same bounded APB/C4 family now also emits scalar integer
generic maps such as `TIMEOUT_CYCLES => 8` and `TIMEOUT_CYCLES => 6`, plus
scalar expression generic maps such as `TIMEOUT_CYCLES => (4 + 1)` and
`TIMEOUT_CYCLES => (3 + 3)`, plus one-bit sized bitstring generic maps such as
`ENABLE_DEFAULT => '1'`, plus multi-bit sized bitstring generic maps such as
`RESET_VALUE => "10100101"` and `RESET_VALUE => "00111100"`, before the
requester/completer port maps; resolved packed aggregate generic maps such as
`LANES => "0011110010100101"` and `FRAME => "101"` also emit before those port
maps. Resolved package-backed generic maps such as `TIMEOUT_CYCLES => 8` and
`RESET_VALUE => "10100101"` also emit before those port maps without leaking
package tokens. Other
composition/top VHDL shapes remain
fail-closed after typed composition IR parsing, with the pipeline and CLI
pointing users to the scoped composition target-support diagnostic.

The compound update and update-shorthand fixtures now lower generated
direct-root vector arithmetic with numeric literal operands, such as `SRC + 2`,
`SRC - 1`, `byte_count + 4`, and `remaining - 3`, through target-width
`to_unsigned` casts. Typed read-only direct-root two-state signals now lower
generated `input bit FLAG_IN` and `input bit [7:0] BYTE_IN` ports to VHDL
`std_logic` and `std_logic_vector` input ports. Typed read-only direct-root
non-signed four-state signals now lower generated `input logic FLAG_IN` and
`input logic [7:0] BYTE_IN` ports to the same VHDL input-port shapes. The declarative bits
symbolic-width fixture now lowers
generated scalar and vector two-state `bit` internal declarations, such as
`bit FLAG;` and `bit [7:0] OUT;`, to VHDL `std_logic` and
`std_logic_vector` signals; signed vector declarations such as
`reg signed [3:0] NIB;` lower to VHDL `signed` signals. Package-backed
declarative `+types` fixtures now lower generated
non-signed four-state `logic` internal declarations, such as
`logic [7:0] ISYM;` and `logic LFLAG;`, to `std_logic_vector` and `std_logic`.
Generated internal `logic signed [MSB:LSB] NAME;` declarations now lower to
VHDL `signed` signals. Generated signed vector direct-root port declarations,
starting with `input logic signed [7:0] IN`, now lower to VHDL `signed` ports.
Generated signed scalar direct-root declarations from one-bit signed type
aliases, such as `input logic signed IN` and `logic signed OUT;`, now lower to
VHDL `std_logic` ports/signals. Signed scalar
addition/subtraction/multiplication RHS assignments and chains now lower as
one-bit `std_logic` bit-pattern logic: `+` and `-` become `xor` chains, and `*`
becomes an `and` chain. Signed scalar division/modulo and mixed signed/unsigned
scalar arithmetic remain fail-closed.
Same-width signed vector addition/subtraction/multiplication/division/modulo
RHS assignments now lower as signed VHDL arithmetic when the target and all operands are
same-width signed vectors, so a signed direct-root `SUM = (+ A B)` assignment
emits `SUM <= A + B;`, a signed `DIFF = (- A B)` assignment emits
`DIFF <= A - B;`, and a signed `PROD = (* A B)` assignment emits
`PROD <= resize(A * B, 8);`. Signed `QUOT = (/ A B)` emits
`QUOT <= resize(A / B, 8);`, and signed `REM = (% A B)` emits
`REM <= resize(A mod B, 8);`, rather than unsigned casts. Scalar signed
division/modulo, mixed signed/unsigned arithmetic, broader generated-FSM/C4
composition VHDL beyond the exact shipped fixtures, internal-net-heavy
composition tops beyond APB, composition generic maps beyond external-RTL
scalar integer, scalar integer expression, metadata-backed one-bit sized
bitstring, and multi-bit sized bitstring literal/resolved-package-constant
actuals plus resolved packed aggregate and standalone-DT scalar integer
actuals and generated-FSM scalar integer/scalar expression/one-bit sized
bitstring/multi-bit sized bitstring/resolved packed aggregate actuals plus
APB/C4 generated-FSM scalar integer/scalar expression/one-bit sized bitstring/
multi-bit sized bitstring/resolved packed aggregate/resolved package-backed
actuals, generated-FSM aggregate actuals that do not lower to one packed
literal now locked fail-closed before VHDL emission, aggregate
VHDL, VHDL package declaration/emission, GHDL validation, and full backend
parity remain outside the shipped
scaffold. Signed vector numeric-literal
addition/subtraction/multiplication/division/modulo also lower through
target-width `to_signed`, so `SUM = (+ A 1)` emits
`SUM <= A + to_signed(1, 8);`, `DIFF = (- A 1)` emits
`DIFF <= A - to_signed(1, 8);`, `PROD = (* A 2)` emits
`PROD <= resize(A * to_signed(2, 8), 8);`, `QUOT = (/ A 2)` emits
`QUOT <= resize(A / to_signed(2, 8), 8);`, and `REM = (% A 2)` emits
`REM <= resize(A mod to_signed(2, 8), 8);`. Mixed signed/unsigned vector
numeric arithmetic is locked fail-closed rather than lowering signed operands
through unsigned casts.
The AMBA requester direct fixture now lowers its bounded generated wrap
arithmetic through explicit unsigned target-width resizes: `wrap_span_q_next`
uses the mixed-width product `beats_total_q * addr_step_q`, `wrap_base_q_next`
uses `addr_q - addr_q % (beats_total_q * addr_step_q)`, and
`wrap_high_q_next` adds the same wrap-span product to the computed base. This
does not claim broad expression-parser parity; unrelated nested or
mismatched-width arithmetic still needs exact future owners.
The maintained direct aggregate-output fixtures now lower through the direct
VHDL scaffold as packed vectors: `NESTED` is
`std_logic_vector(6 downto 0)`, `OUT` is `std_logic_vector(2 downto 0)`, and
`OUT_FRAME` / `OUT_LANES` are 5-bit `std_logic_vector` ports. Full VHDL
record/array aggregate lowering remains a future exact owner.
Direct vector output-port next-signal assignments from unsized decimal
literals now lower through target-width `to_unsigned`; for example an 8-bit
interface output emits `OUT_next <= std_logic_vector(to_unsigned(165, 8));`
instead of a raw integer-to-vector assignment.
Signed vector output-port next-signal assignments from unsized decimal
literals now lower through target-width `to_signed`; for example an 8-bit
signed interface output emits `OUT_next <= to_signed(5, 8);` instead of a raw
integer-to-signed-vector assignment.

### GHDL Validation

Status: backlog, behind a VHDL validation leaf.

Goal: add GHDL validation once the VHDL backend subset is hardened enough for
tool validation.

Current boundary: validation focuses on SystemVerilog using Verilator and
Yosys. The direct VHDL scaffold is regression-tested through deterministic
text and CLI routing, but not externally validated by GHDL yet. The current
environment blocker is reconfirmed by
`BACKEND-API-VALIDATION-FRONTIER.102.1`.

### Warning-Clean External Validation For Every Historical Sample

Status: backlog.

Goal: make every intended sample under `fsm/` externally warning-clean under
the supported Verilog-family validation tools.

Current boundary: the regression gate uses a focused SystemVerilog smoke set
covering the direct protocol/MIPI/trial samples named in
[Generated HDL Debugging And Inspection](09-generated-hdl-debugging-and-inspection.md)
plus the APB composition top `fsm/apb_tb.fsm`.

It does not claim every historical sample in `fsm/` is externally
warning-clean.

### ABC Mapping Hardening

Status: backlog.

Goal: decide whether and how to add ABC-backed Yosys optimization/mapping
validation without timeout-sensitive noise.

Current boundary: the Yosys lane intentionally uses `synth -noabc`.

Current shipped boundary: the external validation support and manifest surfaces
report optional ABC executable discovery candidates while keeping ABC disabled,
non-required, and outside the shipped CLI validation command sequence. The
in-process support API now has an explicit opt-in mapping probe:
`FSM::Support::HDLExternalValidation::validate_systemverilog_file(...,
abc_mapping => 1)`. That mode requires optional ABC discovery and runs Yosys
`synth -top`, while default `--verify-hdl` remains ABC-free with
`synth -noabc`.

Remaining hardening direction: any ABC-backed Yosys optimization/mapping gate
still needs broader timeout/error policy and regression coverage before it can
become a validation requirement or CLI default.

### Structured Non-Flattened Generation

Status: backlog.

Goal: support a structured/non-flattened generation path where useful without
weakening the debug-first flattened contract.

Current boundary: flattened decision-tree generation is the shipped default
path.

Current shipped boundary: the programmatic facade contract and capability
manifest publish `default_generation_mode: flattened_debug_first`,
`generation_mode_names: ["flattened_debug_first"]`, and
`structured_nonflattened_generation_enabled: false`. `generation_mode` remains
absent from public constructor options until a real backend path is implemented
and regression-backed.

## Embedding And Public APIs

### Semantic Introspection And MCP Adapter

Status: active first-class feature under
[`SEMANTIC-INTROSPECTION-MCP-FRONTIER`](../../tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md).

Goal: make deep semantic introspection a first-class FSMGen capability. Every
meaningful FSMGen semantic domain should become queryable through a clean,
bounded API, and MCP is a required adapter over that API rather than the source
of truth for the semantic contract.

Current shipped boundary: `./bin/fsmgen --capability-manifest` now exposes a
top-level `semantic_introspection` section. That section names query domains,
query families, schema/version fields, contract sources, provenance and
support-accounting expectations, read-only defaults, workspace restrictions,
and MCP resource/tool mappings over the existing capability manifest, check
JSON, normalized semantic JSON, schedule JSON, support accounting, stable
diagnostics, generated artifact inventories, backend-validation status,
embedding contract metadata, and mdBook/corpus examples. `bin/fsmgen-mcp` now
ships the first read-only local JSON-RPC stdio adapter over that contract; the
manifest reports `mcp_adapter_implemented: true` and
`write_generation_tools_enabled: false`. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.5`
hardens the adapter with protocol-level JSON-RPC error codes, notification
handling, malformed percent-encoding rejection, source-query
`adapter_provenance`, and source-bound path sanitization.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.6` adds `fsmgen_support_summary`,
bounded support-accounting aggregates, support-aware example discovery, and
diagnostic explanations linked to support-accounting examples.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.7` documents generic read-only MCP client
configuration and bounded one-shot workflows for capabilities, support
summaries, diagnostics, examples, check JSON, semantic JSON, and schedule
previews.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.8` adds bounded read-only MCP schema
snapshot fixtures and a client compatibility matrix. The shipped profile is
one-shot or MCP 2025-06-18 newline-delimited JSON-RPC stdio; Streamable HTTP,
prompts, sampling, completions, client roots consumption, service mode, and write
tools are not claimed yet. `SEMANTIC-INTROSPECTION-MCP-FRONTIER.9` locks the
stdio framing conclusion with a focused newline/no-embedded-newline guard.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.10` selects explicit `--workspace-root`
as the only shipped source authority; MCP client roots are not consumed yet.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.11` keeps prompt templates unadvertised
until a separate prompt contract can be selected and snapshot-tested.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.12` keeps resource subscriptions and
list-change notifications unadvertised; static resources continue to report
`listChanged: false`.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.13` keeps `completion/complete`
unsupported until a bounded candidate-provider contract is selected.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.14` keeps MCP logging unsupported; adapter
diagnostics remain JSON-RPC errors and structured payloads.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.15` keeps list responses bounded and
unpaginated: resource/template/tool listings emit no `nextCursor`, and
client-supplied cursors are invalid params until a paginated profile is
selected.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.16` keeps MCP sampling and elicitation
unsupported; the adapter does not initiate model calls or user-input requests.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.17` keeps transport bounded to one-shot
`--request-json` and newline-delimited stdio; Streamable HTTP and service mode
remain unshipped.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.18` ships MCP `structuredContent` for
read-only tool results alongside serialized JSON text.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.19` ships per-tool `outputSchema`
metadata for stable public envelope fields. Volatile nested reports and catalog
internals remain schema-light.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.20` ships MCP tool annotations for the
read-only profile: current tools advertise `readOnlyHint: true` and
`openWorldHint: false`; write-only destructive/idempotent hints remain absent.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.21` keeps common MCP annotations absent
from resources, templates, resource-read content, and tool-result text blocks;
tools do not return resource links yet.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.22` keeps progress/cancellation session
behavior unshipped: progress tokens do not emit progress notifications, and
id-less `notifications/cancelled` messages remain silent notifications.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.23` keeps JSON-RPC batch arrays and
non-object request envelopes unsupported with explicit `-32600 Invalid
Request` errors.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.24` locks initialize negotiation to
server protocol version `2025-06-18` and keeps client capabilities from
widening the advertised resources/tools capability set.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.25` keeps JSON-RPC errors message-only
and sanitized; `error.data` remains absent until a bounded schema is selected.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.26` adds stable `serverInfo.title`
metadata and keeps instructions compact/read-only.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.27` exhausts the immediate MCP
protocol-hardening pass for the current read-only profile.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.28` selects catalog-backed source
discovery as the next implementation boundary.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.29` ships that boundary as
`fsmgen://sources` and `fsmgen_discover_sources`, backed by existing manifest
support catalog entries instead of recursive workspace traversal.
`SEMANTIC-INTROSPECTION-MCP-FRONTIER.30` closes the immediate read-only
semantic-introspection/MCP pass after source discovery. The IAL2
feature-completeness tree has shipped
`IAL2-FEATURE-COMPLETENESS-FRONTIER.223`, bounded dynamic write
transaction-ID capture and `BID` response matching.
`DOCTRINE-ENFORCEMENT-ADOPTION.1` now adopts root
`DOCTRINE_ENFORCEMENT.md`, root `TOOLBOX.md`,
`scripts/check_doctrines.sh`, and FSMGEN-native issue-pinpointing commands.
`IAL2-FEATURE-COMPLETENESS-FRONTIER.224` now selects `.225`, generated
dynamic read transaction-ID capture and `RID` response matching readiness
audit, and `.225` selects `.226`, public contract selection for bounded
single-beat dynamic read ID capture and `RID` response matching. `.226`
selects `.227`, direct generated bounded single-beat dynamic read ID capture
and `RID` matching behavior. `.231` now ships bounded dynamic read
burst-last/`RLAST` transaction-ID capture and response matching, and `.232`
selects `.233`, readiness audit for dynamic read-data routing over generated
single-active dynamic read response-demux. `.233` selects `.234`, direct
bounded scalar dynamic read-data capture over the generated dynamic read
single-beat and burst-last/`RLAST` demux shapes. `.234` now ships that scalar
dynamic read-data behavior, `.235` selects `.236`, AXI manager focused-suite
cost cleanup before further dynamic behavior expansion, and `.236` ships the
bounded dynamic-family focused target before selecting `.237`, dynamic
burst-length readiness audit. `.237` selects `.238`, direct bounded
report-only dynamic raw-`ARLEN` burst-length capture over generated dynamic
last-beat read-data.

Selected first MCP resource families are `fsmgen://capabilities`,
`fsmgen://contracts`, `fsmgen://diagnostics`,
`fsmgen://support-accounting`, `fsmgen://examples`, `fsmgen://sources`,
`fsmgen://source/{source_id}/check`,
`fsmgen://source/{source_id}/semantic`, and
`fsmgen://source/{source_id}/schedule`. Selected first MCP tool families are
`fsmgen_capability_query`, `fsmgen_check`, `fsmgen_semantic_introspect`,
`fsmgen_schedule_preview`, `fsmgen_discover_sources`,
`fsmgen_find_examples`, and `fsmgen_explain_diagnostic`; the shipped
support-accounting query tool is `fsmgen_support_summary`.

Raw private parser ASTs, scheduler objects, lowering objects, `HDLGenerator`
compatibility hashes, and internal Perl references remain outside the public
automation contract. Source-bound adapter responses normalize workspace/repo
absolute paths to relative source identities, redact other absolute paths, and
carry a non-leaking `adapter_provenance` envelope.
Source discovery responses return only catalog-backed repo/workspace-relative
source identities, file kind, source kind, available read-only query kinds, and
support metadata under `query`, `limit`, `file_kind`, `source_kind`, and
`classification` controls.
Write generation tools, HDL writing, service mode, network access, arbitrary
filesystem traversal, mutation workflows, and commit/push actions remain
deferred until separately task-tree-owned.

### Fully Frozen Programmatic Embedding API

Status: backlog under `R13`.

Goal: graduate useful in-process seams into a fully frozen public embedding
API.

Current boundary: programmatic embedding exists and many bounded contracts are
advertised, but the whole API is not promised as permanently stable.

Current shipped boundary: the capability manifest advertises the JSON-safe
generation-result snapshot contract directly as
`embedding.serializable_generation_result_snapshot`, preserves the existing
`embedding.serializable_plan_reports.generation_result_snapshot_contract`
reference, and keeps raw `HDLGenerator` result objects out of the public JSON
API.

### Full Normalized Semantic Export

Status: backlog under `R13`.

Goal: provide a full normalized semantic export format for downstream tools.

Current boundary: the capability manifest and normalized semantic JSON expose
bounded, audited public surfaces. The manifest is not yet a full normalized
semantic export.

Current shipped boundary: the normalized semantic payload contract publishes
`optional_child_presence_keys` for `semantic.composition` and
`semantic.symbol_contract`, and the report contract republishes that list as
`success_semantic_optional_child_presence_keys`. The
`semantic.composition` contract also advertises bounded
`children[]`, `children[].parameter_overrides[]`, `generated_children[]`,
`generated_children[].parameter_overrides[]`, and `standalone_dt_children[]`
shallow/alias entry key families while delegating child `intent_hir`,
`lowered_rtl_ir`, and `structural_rtl_ir` summaries to their existing bounded
owners. The standalone-DT
child family also advertises bounded reusable-DT enable-family metadata,
module-enable-family metadata, and nested multi-drive target metadata while
delegating the assertion shape to the existing lowered-RTL standalone-DT
multi-drive assertion owner. The same contract also advertises the
composition-side `shared_datapath_candidates[]` alias family by delegating to
the already bounded lowered-RTL shared-datapath candidate, contributor,
drive-intent, aggregate-enable, assertion, and bound-connection schemas. The
`semantic.forward_ir.lowered_rtl_ir` contract also advertises the emitted
`output_drive_family_count` and `output_drive_families` metadata with bounded
entry keys for `output_drive_families[]` and its nested
`rhs_enable_families[]` entries. It also advertises
`selector_conflict_target_count` and `selector_conflict_targets` metadata,
including bounded entry keys for `selector_conflict_targets[]`, nested
`rhs_enable_families[]`, and selector assertion metadata. It also advertises
`standalone_dt_multi_drive_target_count` and
`standalone_dt_multi_drive_targets` metadata, including bounded entry keys for
`semantic.forward_ir.lowered_rtl_ir.standalone_dt_multi_drive_targets[]` and
its nested `multi_drive_assertion` metadata. It also advertises bounded entry
keys for
`semantic.forward_ir.lowered_rtl_ir.composition_shared_datapath_candidates[]`,
including optional declared-type extensions, contributor entries, contributor
`bound_connection_expr` metadata, contributor `drive_intent` entries plus
nested drive-intent `rhs_enable_families[]` entries, aggregate enable-family
entries, aggregate family contributors, and multi/same-value assertion
metadata. It also advertises bounded alias key families for
`semantic.forward_ir.intent_hir.composition_children[]`,
`semantic.forward_ir.intent_hir.composition_generated_children[]`, and
`semantic.forward_ir.intent_hir.composition_standalone_dt_children[]` by
delegating to the existing `semantic.composition` child and standalone-DT child
schema owners. It also advertises
`semantic.forward_ir.intent_hir.composition_children[].parameter_overrides[]`
and
`semantic.forward_ir.intent_hir.composition_generated_children[].parameter_overrides[]`
by delegating through the composition aliases to the structural instance
parameter-override schema owner. Contributor and child `intent_hir`,
`lowered_rtl_ir`, and `structural_rtl_ir` summaries stay delegated to their
existing bounded contracts. The
`semantic.forward_ir.structural_rtl_ir` contract also advertises bounded
`ports[]` core entry keys, direct-root input-port target extension/entry keys,
composition-top port extension keys, and bounded
`nets[]`, `declared_links[]`, `resolved_links[]`, shallow `instances[]`, and
nested `instances[].interface_ports[]` plus `instances[].port_bindings[]`
core and typed-extension entry keys. It now also advertises
`instances[].parameter_overrides[]` core, raw-value-extension, and
value-metadata-extension entry keys, advertises `assignment_records[]`
generated-enable structural entries, advertises bounded generated-enable net
source/target entry key families, and advertises `auxiliary_assignments[]` as
scalar-string compatibility entries. The `semantic.composition` contract
now also advertises `children[].parameter_overrides[]` and
`generated_children[].parameter_overrides[]` as aliases of those same
structural instance parameter-override core, raw-value-extension, and
value-metadata-extension schemas. The manifest is still not a full normalized
semantic export.

Shipped generated-child export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.51.1` publishes
`parameter_override_count`, `parameter_overrides[]`, and bounded
parameter-override alias key families for
`semantic.composition.generated_children[]` and
`semantic.forward_ir.intent_hir.composition_generated_children[]`. Full
normalized semantic export stabilization remains out of scope.

Shipped symbol-contract constants export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.52.1` publishes bounded scalar/list value key
families for `semantic.symbol_contract.constants` and
`semantic.forward_ir.intent_hir.symbol_contract.constants`. Every advertised
constant value carries `kind`; scalar values add `payload`, and list values add
`items`. That constants edge did not widen enum/type nested schemas,
package-import internals, or full normalized semantic export stabilization.

Shipped symbol-contract enum export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.53.1` publishes enum value-kind families for
`semantic.symbol_contract.enums` and
`semantic.forward_ir.intent_hir.symbol_contract.enums`. Enum entries are
member-payload maps, and dynamic enum members carry scalar payloads. Type
nested schemas, package-import internals, already bounded constant internals,
and full normalized semantic export stabilization remain out of scope.

Shipped symbol-contract type export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.54.1` publishes bounded recursive type-entry
schema metadata for `semantic.symbol_contract.types` and
`semantic.forward_ir.intent_hir.symbol_contract.types`. Scalar entries carry
`kind`, `signed`, `width`, and optional `state_model`; aggregate entries carry
recursive `items` or `members` plus `member_order`.

Shipped symbol-contract package-import export edge: task-tree leaf
`BACKEND-API-VALIDATION-FRONTIER.103.1` publishes bounded package-import
name-list entry metadata for `semantic.symbol_contract.package_imports` and
`semantic.forward_ir.intent_hir.symbol_contract.package_imports`.
`package_import_entry_value_kinds` is `[scalar_package_name]`, and
`package_import_entry_value_meaning` is `authored package-import package-name
string` on the top-level contract surface. The same meaning entries appear as
single-element arrays inside grouped `presence_key_family_map` discovery maps
so every grouped family-map value remains array-valued. Raw package-spec
internals, package source AST, package symbols, VHDL package
declaration/emission, and full normalized semantic export stabilization remain
deferred.

Completed backend/API frontier leaf
`BACKEND-API-VALIDATION-FRONTIER.132` exhausted the active backend/API selector
after `.131.1` shipped direct VHDL non-signed vector positive numeric-literal
literal-literal modulo, the supported-smoke `.fsm` corpus passed under
`--language vhdl`, and `ghdl` remained unavailable. Completed selector leaf
`ARCHITECTURE-DEBT-FRONTIER.3` deferred broad ISF parser/lowerer extraction
until a stable family is proven by a future exact owner. The first exact
private lowerer extraction is now shipped by
`ISF-ATL-GENERATED-TOP-PLANNER-EXTRACTION.2`: `FSM::Scheduler::ISF::ATLGeneratedTop`
owns ATL generated-top schedule-report projection and data-link
child-interface marking without changing public reports, generated artifacts,
or HDL behavior. Broader parser/lowerer extraction remains deferred behind
future exact owners. Completed selection/evaluation leaves
`IAL2-PROTOCOL-PLATFORM-INTENT-EXPLORATION.1` and `.2` found IAL2
design/probe ready. Completed implementation leaf
`AXI-IAL2-VALID-READY-GENERATOR-FIRST-SLICE.1` ships the first in-process IAL2
generator. Completed implementation leaf
`IAL2-PPIF-PARSER-CLI-FIRST-SLICE.1` ships the first public `.ppif` parser/CLI
path for one AXI Valid-Ready source object.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.4` ships the
first in-process AXI manager capacity/status generator. Completed selector
leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.5` selects the public
`manager-capacity-status` `.ppif` syntax. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.6` ships that public parser/CLI first
slice. Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.7`
selects AXI ID-family declaration/static validation. Completed readiness audit
leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.8` selects the additive
capacity/status implementation boundary. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.9` ships optional `(id-families ...)`
metadata for that object. Completed selector leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.10` selects the logical read/write
transaction-envelope/static-validation subset. Completed readiness audit leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.11` selects the additive implementation
boundary. Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.12`
ships optional `(transactions ...)` metadata for that object and advances the
frontier to `.13`, the next IAL2 feature-completeness selector. Completed
selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.13` selects transaction
event dispatch and direction fan-in and advances the sequence to `.14`
readiness audit. Completed readiness audit leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.14` selects the additive implementation
boundary and advances the sequence to `.15`. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.15` ships transaction event dispatch and
direction fan-in and advances the sequence to `.16`. Completed selector leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.16` selects AXI manager ID/response
rule-engine readiness and advances the sequence to `.17`. Completed readiness
audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.17` selects additive concrete
transaction ID assertions and advances the sequence to `.18`. Completed
implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.18` ships concrete
transaction ID request/response assertions and advances the active frontier to
`.19`. Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.19`
selects auto-ID lifecycle/request-ID drive readiness and advances the active
frontier to `.20`. Completed readiness audit leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.20` selects bounded auto-ID
pool/request-ID drive contract selection and advances the active frontier to
`.21`. Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.21`
selects explicit optional `auto-id-lifecycle` bounded-pool syntax and advances
the active frontier to `.22`, parser/report metadata and static validation.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.22` ships
public `auto-id-lifecycle` parser/report metadata and static validation
without generated `.isf`, `.fsm`, or HDL behavior changes, and selected `.23`
as bounded request-ID drive behavior.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.23` ships
bounded request-ID drive behavior for explicit auto-ID lifecycle families and
selected `.24` as the next exact IAL2 feature-completeness selector.
Completed selector leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.24` selects AXI generated response-demux
readiness and selected `.25` as the readiness audit. Completed readiness audit
leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.25` selects bounded write
response-demux public contract selection and selected `.26` as the contract
selector. Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.26`
selects explicit write-only response-demux syntax and advances the active
frontier to `.27`. Completed implementation leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.27` ships parser/report metadata and
static validation for that syntax, adds the response-demux sample and support
accounting entry, and selected completed `.28` for generated write
response-demux behavior readiness. Completed readiness audit leaf
`IAL2-FEATURE-COMPLETENESS-FRONTIER.28` selects `.29` as the minimal IAL1
rule-pulse prerequisite before generated response-demux completion rules ship.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.29` ships
that bounded `(pulse target)` rule action and selects `.30` for generated
write `BID` response-demux behavior.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.30` ships
generated write `BID` response-demux behavior and selects `.31` as the next
exact IAL2 feature-completeness selector.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.31` selects `.32`
to align `auto_id_lifecycle.residue` after generated write `BID` response
demux before larger ordering/read-response work.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.32` ships
that report-residue alignment and selects `.33` as the next exact IAL2
feature-completeness selector.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.33` selects AXI
same-ID ordering readiness and advanced the frontier to `.34`.
Completed readiness audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.34`
selects bounded auto-ID same-ID avoidance assertions/report metadata and
advances the active frontier to `.35`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.35` ships
bounded auto-ID same-ID avoidance assertions/report metadata and advances the
active frontier to `.36`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.36` selects read
`RID` response-demux readiness and advances the active frontier to `.37`.
Completed readiness audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.37`
selects bounded read response-demux public contract selection and advances
the active frontier to `.38`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.38` selects
explicit `(response-scope single-beat)` read response-demux syntax and advances
the active frontier to `.39`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.39` ships
read response-demux parser/report metadata and static validation while keeping
generated read behavior unchanged, and advances the active frontier to `.40`.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.40` selects
bounded generated single-beat read `RID` response-demux behavior and advances
the active frontier to `.41`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.41` ships
bounded generated single-beat read `RID` response-demux behavior and advances
the active frontier to `.42`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.42` selects
read-data payload, burst/`RLAST`, and per-ID readiness as the next audit and
advances the active frontier to `.43`.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.43` selects the
bounded public read-data payload/status contract selector and advances the
active frontier to `.44`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.44` selects
explicit bounded `(read-data (read ...))` syntax and advances the active
frontier to `.45`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.45` ships
read-data parser/report metadata and static validation while keeping generated
read-data capture behavior unchanged, and advances the active frontier to
`.46`.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.46` selects
generated single-beat `RDATA`/`RRESP` capture behavior and advances the active
frontier to `.47`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.47` ships
generated single-beat `RDATA`/`RRESP` capture behavior and advances the active
frontier to `.48`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.48` selects AXI
burst/`RLAST` completion readiness as the next exact prerequisite after
generated single-beat read-data capture and advances the active frontier to
`.49`.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.49` selects
public AXI burst/`RLAST` completion contract selection before parser/report
metadata or generated behavior changes and advances the active frontier to
`.50`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.50` selects
additive read `response-demux` syntax for `response-scope burst-last` with
one-bit `last-signal` and selected `.51`, parser/report metadata and static
validation.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.51` ships
report-only burst-last `RLAST` response-demux metadata and static validation
and advances the active frontier to `.52`, generated burst-last/`RLAST`
completion behavior readiness.
Completed readiness audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.52` selects
direct generated burst-last/`RLAST` completion behavior and advances the
active frontier to `.53`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.53` ships
generated burst-last/`RLAST` completion behavior and advances the active
frontier to `.54`, the next AXI manager feature-completeness selector.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.54` selects
narrow AXI `RLAST` report/static-text alignment and advances the active
frontier to `.55`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.55`
aligns generated AXI `RLAST` report prose with shipped behavior and hands
off to selector `.56`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.56` selects
public AXI burst read-data contract selection and hands off to selector
`.57`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.57` selects
explicit last-beat read-data parser/report metadata and advances the active
frontier to `.58`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.58` ships
parser/report metadata and static validation for explicit last-beat read-data
capture and hands off to readiness audit `.59`.
Completed readiness-audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.59`
selects direct generated last-beat read-data capture behavior and hands off to
`.60`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.60` ships
generated last-beat `RDATA`/`RRESP` capture behavior and hands off to selector
`.61`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.61` selects
public AXI burst read-data beat-count/depth contract selection and hands off to
`.62`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.62` selects
ARLEN-based `burst-length` parser/report metadata and static validation and
advances the frontier to `.63`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.63` ships
parser/report metadata and static validation for ARLEN-based `burst-length`
contracts and advances the frontier to `.64`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.64` selects
generated AXI ARLEN burst-length capture readiness and advances the active
frontier to `.65`.
Completed audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.65` selects direct
generated raw-ARLEN capture behavior and advances the active frontier to
`.66`.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.66` ships
generated raw-ARLEN capture behavior and advances the active frontier to
`.67`, beat-count/RLAST validation readiness.
Completed audit leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.67` preserves
`validation report-only` as no-runtime-check behavior, selects public
beat-count/RLAST runtime-validation contract selection, and advances the
active frontier to `.68`.
Completed selector leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.68` selects
`(validation runtime-assertion)` / `runtime_assertion`, preserves
`validation report-only` as report-only metadata, and advances the active
frontier to `.69`, the first generated beat-count/RLAST runtime-validation
implementation slice.
Completed implementation leaf `IAL2-FEATURE-COMPLETENESS-FRONTIER.69` ships
generated beat-count/RLAST runtime validation for `(validation
runtime-assertion)` burst-length contracts and advances the active frontier
to `.70`, the next exact-owner selector. Completed selector
`IAL2-FEATURE-COMPLETENESS-FRONTIER.70` advances the active frontier to
`.71`, public AXI multi-beat read-data reassembly/output contract selection,
before parser, generator, HDL, sample, support-accounting, check JSON,
semantic JSON, or validation behavior changes.
Completed selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.71` advances the
active frontier to `.72`, parser/report metadata and static validation for
the selected public multi-beat read-data contract.
Completed implementation `IAL2-FEATURE-COMPLETENESS-FRONTIER.72` ships
parser/report metadata and static validation for the selected public
multi-beat read-data output-bank contract, adds
`ppif/axi_manager_capacity_status_read_data_multi_beat.ppif`, reports
generated lane names, valid-mask widths, length-output widths, and output-bank
shape, and advances the active frontier to `.73`, generated multi-beat
read-data reassembly/output readiness.
Completed audit `IAL2-FEATURE-COMPLETENESS-FRONTIER.73` finds no lower-layer
prerequisite for first generated output-bank behavior and advances the active
frontier to `.74`, generated multi-beat read-data output-bank behavior.
Completed implementation `IAL2-FEATURE-COMPLETENESS-FRONTIER.74` ships
generated multi-beat read-data output-bank behavior and advances the active
frontier to `.75`, the next AXI manager feature-completeness selector.
Completed selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.75` selects public
scalar `RRESP` aggregation contract selection and advances the active
frontier to `.76`.
Completed selector `IAL2-FEATURE-COMPLETENESS-FRONTIER.76` selects additive
`(status-aggregation (policy worst-observed))` syntax, per-transaction
`(status-aggregate-output NAME)` bindings, and advances the active frontier
to `.77`, parser/report metadata and static validation for scalar `RRESP`
aggregation.
Completed implementation leaf
`ARCHITECTURE-DEBT-FRONTIER.2.1`
projects direct backend storage/helper declaration-plan entries into
`structural_rtl_ir.nets[]` without rerouting HDL emission. Completed
implementation leaf
`R11-DIRECT-BACKEND-COORDINATION-FRONTIER.2`
projects top-level direct state and standalone-DT enable wires into
`structural_rtl_ir.nets[]` without claiming DT-specific/LHS WEN/EN wires,
assignment connectivity, instances, links, auxiliary assignments, or rerouting
HDL emission. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-WEN-EN-NETS.1`
projects direct DT-specific and LHS-level WEN/EN wires into
`structural_rtl_ir.nets[]` as declaration-only one-bit nets without claiming
assignment connectivity, instances, links, auxiliary assignments, or rerouting
HDL emission. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-AUX-ASSIGNMENTS.2`
projects already-rendered direct generated enable assignment lines into
`structural_rtl_ir.auxiliary_assignments[]` as scalar strings without claiming
assignment records, direct net connectivity, instances, links, or rerouting
HDL emission. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-ASSIGNMENT-RECORDS.2`
projects those generated enable assignments into
`structural_rtl_ir.assignment_records[]` as machine-readable records while
retaining `auxiliary_assignments[]` as the compatibility mirror and without
rerouting HDL emission. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-NET-CONNECTIVITY.2`
populates generated-enable direct net `source` objects for assignment-record
drivers and `targets[]` entries for direct nets consumed by another
generated-enable assignment-record RHS. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-PORT-DEPENDENCY-CONNECTIVITY.2`
populates direct input-port generated-enable RHS target connectivity on
`structural_rtl_ir.ports[]`, while leaving HDL emission unchanged. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-OUTPUT-CONSUMERS.2`
populates direct output-port `source` summaries from lowered output-drive
families, while leaving broader always-block body consumer modeling and HDL
emission unchanged. Completed
implementation leaf
`R11-DIRECT-STRUCTURAL-HDL-REROUTING.2`
reroutes the direct SystemVerilog top state/standalone-DT generated-enable
condition block through `StructuralRTLIR` assignment records by using explicit
backend markers that are removed before final HDL is returned. Full direct
module rerouting is deferred by selector
`R11-DIRECT-STRUCTURAL-FULL-HDL-REROUTING.1` until direct behavior-body,
state-update, output, and assertion regions have exact structural ownership.
VHDL backend/reroute work is deferred by selector
`R11-DIRECT-STRUCTURAL-VHDL-REROUTING.1` until the SystemVerilog-backed
IAL0/IAL1/IAL2 path is feature complete. Completed selector leaf
`R11-DIRECT-STRUCTURAL-INSTANCES-LINKS.1` confirms direct roots intentionally
keep empty instance/link arrays, with populated instances and links remaining
composition-top structural facts. Completed
implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.131.1` lowers an 8-bit non-signed
`REM = (% 2 3)` fixture into
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod to_unsigned(3, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.130.1` lowers an 8-bit non-signed
`QUOT = (/ 2 3)` fixture into
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / to_unsigned(3, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.129.1` lowers an 8-bit non-signed
`PROD = (* 2 3)` fixture into
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * to_unsigned(3, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.128.1` lowers an 8-bit non-signed
`REM = (% 2 A)` fixture into
`REM <= std_logic_vector(resize(to_unsigned(2, 8) mod unsigned(A), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.127.1` lowers an 8-bit non-signed
`QUOT = (/ 2 A)` fixture into
`QUOT <= std_logic_vector(resize(to_unsigned(2, 8) / unsigned(A), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.126.1` lowers an 8-bit non-signed
`PROD = (* 2 A)` fixture into
`PROD <= std_logic_vector(resize(to_unsigned(2, 8) * unsigned(A), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.125.1` lowers an 8-bit non-signed
`REM = (% A 2)` fixture into
`REM <= std_logic_vector(resize(unsigned(A) mod to_unsigned(2, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.124.1` lowers an 8-bit non-signed
`QUOT = (/ A 2)` fixture into
`QUOT <= std_logic_vector(resize(unsigned(A) / to_unsigned(2, 8), 8));`.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.123.1` lowers an 8-bit non-signed
`PROD = (* A 2)` signal-first fixture into
`PROD <= std_logic_vector(resize(unsigned(A) * to_unsigned(2, 8), 8));`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.122.1` lowers
direct VHDL non-signed vector modulo with a negative decimal numeric literal
into target-width resized unsigned arithmetic over a two-complement literal,
so the selected 8-bit fixture emits
`REM <= std_logic_vector(resize(unsigned(A) mod unsigned(to_signed(-2, 8)), 8));`
instead of failing at arithmetic expression `'A % -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.121.1` lowers
direct VHDL non-signed vector division with a negative decimal numeric literal
into target-width resized unsigned arithmetic over a two-complement literal,
so the selected 8-bit fixture emits
`QUOT <= std_logic_vector(resize(unsigned(A) / unsigned(to_signed(-2, 8)), 8));`
instead of failing at arithmetic expression `'A / -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.120.1` lowers
direct VHDL non-signed vector multiplication with a negative decimal numeric
literal into target-width resized unsigned arithmetic over a two-complement
literal, so the selected 8-bit fixture emits
`PROD <= std_logic_vector(resize(unsigned(A) * unsigned(to_signed(-2, 8)), 8));`
instead of failing at arithmetic expression `'A * -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.119.1` lowers
direct VHDL non-signed vector subtraction with a negative decimal numeric
literal into unsigned arithmetic over a target-width two-complement literal,
so the selected 8-bit fixture emits
`DIFF <= std_logic_vector(unsigned(A) - unsigned(to_signed(-1, 8)));`
instead of failing at arithmetic expression `'A - -1'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.118.1` lowers
direct VHDL non-signed vector addition with a negative decimal numeric literal
into unsigned arithmetic over a target-width two-complement literal, so the
selected 8-bit fixture emits
`SUM <= std_logic_vector(unsigned(A) + unsigned(to_signed(-1, 8)));` instead
of failing at arithmetic expression `'A + -1'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.117.1` lowers
direct VHDL signed vector modulo with a negative decimal numeric literal into
target-width resized signed VHDL arithmetic, so the selected 8-bit signed
fixture emits `REM <= resize(A mod to_signed(-2, 8), 8);` instead of failing
at arithmetic expression `'A % -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.116.1` lowers
direct VHDL signed vector division by a negative decimal numeric literal into
target-width resized signed VHDL arithmetic, so the selected 8-bit signed
fixture emits `QUOT <= resize(A / to_signed(-2, 8), 8);` instead of failing
at arithmetic expression `'A / -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.115.1` lowers
direct VHDL signed vector multiplication with a negative decimal numeric
literal into target-width resized signed VHDL arithmetic, so the selected
8-bit signed fixture emits `PROD <= resize(A * to_signed(-2, 8), 8);`
instead of failing at arithmetic expression `'A * -2'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.114.1` lowers
direct VHDL signed vector subtraction with a negative decimal numeric literal
into signed VHDL arithmetic, so the selected 8-bit signed fixture emits
`DIFF <= A - to_signed(-1, 8);` instead of failing at arithmetic expression
`'A - -1'`.
Completed implementation leaf `BACKEND-API-VALIDATION-FRONTIER.113.1` lowers
direct VHDL signed vector addition with a negative decimal numeric literal into
signed VHDL arithmetic, so the selected 8-bit signed fixture emits
`SUM <= A + to_signed(-1, 8);` instead of failing at arithmetic expression
`'A + -1'`. Non-signed vector negative modulo remains deferred.
Completed implementation
leaf `BACKEND-API-VALIDATION-FRONTIER.112.1` lowers direct VHDL scalar
output-port next-signal assignments from negative decimal literals into
`std_logic` low-bit assignments, so the selected plain scalar fixture emits
`FLAG_next <= '1';` for `-1` and the signed one-bit alias fixture emits
`FLAG_next <= '0';` for `-2` instead of failing at arithmetic expression
`'-1'` or `'-2'`. Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.111.1` lowers direct VHDL non-signed vector
output-port next-signal assignments from negative decimal literals into
VHDL-typed `std_logic_vector` assignments, so the selected 8-bit
interface-output fixture emits `OUT_next <= std_logic_vector(to_signed(-1,
8));` instead of failing at arithmetic expression `'-1'`. Selector leaf
`BACKEND-API-VALIDATION-FRONTIER.111` chose that edge after the probe generated
`std_logic_vector` output/next-signal declarations but failed before VHDL
emission. Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.110.1` lowers direct VHDL signed vector
output-port next-signal assignments from negative decimal literals into
VHDL-typed signed assignments, so the selected 8-bit signed interface-output
fixture emits `OUT_next <= to_signed(-1, 8);` instead of failing at arithmetic
expression `'-1'`. Later leaves now cover non-signed vector and scalar
negative output literals too. Selector leaf
`BACKEND-API-VALIDATION-FRONTIER.110` chose that edge after the probe generated
`signed` output/next-signal declarations but failed before VHDL emission.
Completed
implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.109.1` lowers direct VHDL scalar output-port
next-signal assignments from unsized decimal literals into `std_logic` low-bit
literal assignments, so the selected plain scalar fixture emits
`FLAG_next <= '0';` for `2` and the signed one-bit alias fixture emits
`FLAG_next <= '1';` for `3` instead of raw integer assignments. Selector leaf
`BACKEND-API-VALIDATION-FRONTIER.109` chose that edge after the probes
generated `std_logic` output/next-signal declarations but still wrote raw
`FLAG_next <= 2;` in the VHDL combinational assignment. Completed
implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.108.1` lowers direct VHDL signed vector
output-port next-signal assignments from unsized decimal literals into
VHDL-typed signed assignments, so the selected 8-bit signed interface-output
fixture emits `OUT_next <= to_signed(5, 8);` instead of raw
`OUT_next <= 5;`. Selector leaf `BACKEND-API-VALIDATION-FRONTIER.108` chose
that edge after the probe emitted `signed` output/next-signal declarations but
still wrote the raw integer assignment. Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.107.1` lowers direct VHDL vector output-port
next-signal assignments from unsized decimal literals into VHDL-typed vector
assignments, so the selected 8-bit interface-output fixture emits
`OUT_next <= std_logic_vector(to_unsigned(165, 8));` instead of raw
`OUT_next <= 165;`. Selector leaf `BACKEND-API-VALIDATION-FRONTIER.107` chose
that edge after the probe emitted `std_logic_vector` output/next-signal
declarations but still wrote the raw integer assignment.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.106.1` lowers `input logic IN` and
`input logic [7:0] IN` to VHDL `std_logic` / `std_logic_vector` ports.
Completed selector leaf
`BACKEND-API-VALIDATION-FRONTIER.106` chose that exact logic-input edge after
typed read-only direct-root probes stopped at the direct VHDL port parser.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.105.1` lowers `input bit IN` and
`input bit [7:0] IN` to VHDL `std_logic` / `std_logic_vector` ports.
Completed selector leaf
`BACKEND-API-VALIDATION-FRONTIER.105` chose that exact input-port edge after
typed read-only direct-root probes stopped at the direct VHDL port parser.
Completed implementation leaf
`BACKEND-API-VALIDATION-FRONTIER.104.1` lowers those generated declarations to
`std_logic_vector` signals through pipeline, CLI, and facade coverage.
Completed selector leaf
`BACKEND-API-VALIDATION-FRONTIER.104` chose that exact vector-bit declaration
edge after representative normalized semantic probes found no unadvertised
bounded top-level contract keys and a direct VHDL probe stopped at
`bit [7:0] OUT;`. Completed leaf
`BACKEND-API-VALIDATION-FRONTIER.102.1` reconfirms that VHDL external validation
remains blocked because `ghdl` is unavailable. Completed leaf
`BACKEND-API-VALIDATION-FRONTIER.101.1` locks declared aggregate structural VHDL
ports/nets/types as fail-closed before record/array emission. Completed leaf
`BACKEND-API-VALIDATION-FRONTIER.100.1` locks package roots as import-only
declaration containers that do not generate standalone SystemVerilog or VHDL
package HDL directly.
Package declaration and VHDL package emission, already bounded
constant/enum/type internals, unrelated forward-IR payloads, signed scalar
division/modulo, mixed signed/unsigned arithmetic, standalone-DT generic maps
beyond scalar integer, scalar expression, one-bit sized bitstring, multi-bit
sized bitstring, packed-list, and packed-map actuals,
APB/C4 generic maps beyond scalar integer, scalar expression, one-bit sized
bitstring, multi-bit sized bitstring, resolved packed aggregate, resolved
package-backed actuals, and non-packed aggregate actuals now locked fail-closed
before VHDL emission, external-RTL aggregate actuals that do not lower to one
packed literal now locked fail-closed before VHDL emission, standalone-DT
aggregate actuals that do not lower to one packed literal now locked
fail-closed before VHDL emission, generated-FSM aggregate actuals that do not
lower to one packed literal now locked fail-closed before VHDL emission,
full aggregate VHDL record/array lowering, broader generated-FSM/C4
composition VHDL beyond the exact shipped fixtures, internal nets/generic maps
beyond APB, broader expression parity beyond the shipped AMBA wrap family, and
full normalized semantic export stabilization remain out of scope until later
exact leaves own them.
Package-root direct HDL generation is locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.100.1`; this keeps `?pkg` roots import-only
and still does not implement VHDL package declaration/emission.
Declared aggregate structural VHDL ports/nets/types are locked fail-closed by
`BACKEND-API-VALIDATION-FRONTIER.101.1`; this keeps composition tops from
emitting VHDL record/array declarations until a future exact aggregate-lowering
leaf owns them.
GHDL validation blocker reconfirmation is locked by
`BACKEND-API-VALIDATION-FRONTIER.102.1`: `ghdl` is unavailable in the current
environment, so external HDL validation remains SystemVerilog-only until a
future exact GHDL lane can run the tool.
