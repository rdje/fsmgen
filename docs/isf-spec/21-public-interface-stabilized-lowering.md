
## Stabilized Surface

The current bounded public surface is deliberately narrow.
The machine-readable contract's `public_top_level_presence_keys` list is the
exact top-level discovery list for the contract payload. It is not a partial
hint list.
The schema/status/owner identity fields and stability flags are exact discovery
metadata for the contract's current bounded-public stance.
The `guidance` list is exact downstream-consumer advice for interpreting the
current bounded contract: facade pairs are public, raw internals are not, human
contract documents must evolve with public ISF changes, and feature-driven
public changes must move the matching public contract and manifest audit tests
in the same implementation slice.
The `tested_by` list is exact audit-provenance metadata for this ISF contract
owner; every path must stay repo-relative and present on disk.
The `library_catalog_paths`, `library_catalog_entry_keys`, and
`shipped_library_definitions` fields are live discovery metadata for reusable
ISF libraries. They advertise where downstream consumers can find the human
catalog, which fields each catalog entry carries, and which reusable
definitions are shipped in this repository today. They do not expose the raw
library resolver state or freeze future library kinds.

Supported ISF syntax remains a live surface. For `(switch signal ...)`, explicit
case values remain unique branch selectors, and one fallback branch may be
written as `(default body...)` or `(_ body...)`. Those fallback spellings are
aliases and are rejected if both appear in the same switch. When no authored
fallback branch is present, ISF lowering emits an implicit scheduled `.fsm`
`(default (-> next_state))` fallthrough branch. In the downstream `.fsm`
language, that default selector means the logical negation of the OR of every
explicit sibling branch predicate, so the fallback path is true only when no
explicit branch matched.

For the first reusable-library import surface, actor roots may use one
`(imports ...)` clause and one or more `(use ...)` clauses. Library roots use
`(library name ...)` with one `(exports ...)` clause, and the first supported
export kind is `actor`. A use such as
`(use pulse_lib.pulse_actor as rx (params (WIDTH 4)) (bind ...))` resolves a
namespaced exported actor, validates instance-local parameter overrides and
explicit clock/reset/interface bindings, and emits a specialized child
scheduled `.fsm` artifact named `<importing_actor>__<instance>.fsm`.
Use-site parameter override scalar values and compatible aggregate/list leaves
may use numeric/exact-width literals, importing-actor constants,
importing-actor scalar parameter defaults, local/package enum members, and
qualified imported package scalar constants. Those static use-site values
resolve to literal generated-top/generated-composition bindings and
`library_uses[]` report values; unqualified package constants, aggregate
package constants, package member/item paths, and ambiguous
local-enum/package-constant spellings fail closed.
`parse_file(...)` resolves external library files from the importing source
directory, `FSMLIB`, and the current directory, checking both dotted and
path-like file names such as `common.pulse.isf` and `common/pulse.isf`.
`parse_source(...)` can resolve same-source library roots; general external
resolution requires a real source path, so file-backed library use should call
`parse_file(...)`. Resolved library actor instances emit a generated top when
lowered for HDL: bound library inputs/outputs link directly between top ports
and the library child instance. Same-name clock/reset bindings can be inferred
when the parent and child clock names match and the reset name/kind/polarity
matches; they use the existing composition system-port auto-wiring path and
are still reported in `library_uses[].bindings[]`. Differently named
clock/reset bindings emit explicit generated-top `?wiring` list links such as
`(clk rx.lib_clk)` to the library child system ports; the reusable actor still
owns reset kind and polarity. That reusable-library system-binding surface is
still signal-name binding, not CDC behavior by itself.
The clock-domain lowering slices add parser and scheduler handoff metadata for
the selected `(clock-domains ...)` and `(crossings ...)` source model.
Accepted multi-domain actors are partitioned by declared domain inside
`LoweringIR`, and direct unowned cross-domain reads, writes, triggers,
activations, bindings, and drive reuse fail closed before emission. Public
`lower(...)` now emits domain-specific scheduled `.fsm` artifacts named
`<actor>__domain_<domain>.fsm` plus a generated multi-domain top that wires
domain modules and explicit CDC child interfaces. Public `report(...)` and
`--emit-schedule-json` now describe the generated top at the top level and
expose bounded per-domain and event-crossing metadata through
`clock_domains[]` and `crossings[]`. Plain generated HDL for accepted
SystemVerilog/Verilog-family event-crossing actors now emits the generated top
and a concrete generated acknowledged-event CDC child when each emitted domain
artifact satisfies the current scheduled `.fsm` HDL contract, including
clock-only no-reset domain artifacts.
No-reset event-crossing actors are accepted for lowering, in-process
`report(...)`, and `--emit-schedule-json`; their generated CDC interface
metadata publishes `SOURCE_RESET_PRESENT 0d0` and `DEST_RESET_PRESENT 0d0`.
Plain HDL generation for those no-reset domain artifacts emits reset-free
domain modules and a generated CDC child without absent reset ports.
The current shipped reusable library catalog contains `common.fifo.fifo` with
source [isf/common/fifo.isf](../../isf/common/fifo.isf), import fixture
[isf/fifo_library_use.isf](../../isf/fifo_library_use.isf), fixed parameters
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3`, the public FIFO
interface, actor-owned storage, runtime semantics, tests, and limitations.
The same information is mirrored in `shipped_library_definitions` for
machine-readable discovery. The file-backed import fixture is also the
strict reusable-library handoff example: it emits the importing actor,
specialized child, and generated top scheduled `.fsm` artifacts, records
fixed parameter overrides and binding provenance in `library_uses[]`, and
reaches plain plus strict generated-top SystemVerilog.

Supported CLI entrypoints:

```bash
./bin/fsmgen path/to/file.isf
./bin/fsmgen --emit-schedule-json path/to/file.isf
./bin/fsmgen --outdir path/to/outdir path/to/file.isf
```

Supported in-process facade entrypoints:

```perl
my $actor = FSM::Adapter::ISF->new(%args)->parse_file($path);
my $actor = FSM::Adapter::ISF->new(%args)->parse_source($text, $label);

my $lowered = FSM::Scheduler::ISF->new(%args)->lower($actor);
my $json    = FSM::Scheduler::ISF->new(%args)->report($actor);
```

The advertised entrypoint lists are exact discovery metadata, not examples with
additional unlisted public entrypoints implied.
The `parser_method_names` and `scheduler_method_names` lists are exact
discovery metadata for the public facade method families.
The parser facade return-shape fields advertise that `parse_file(...)` and
`parse_source(...)` return scheduler-consumable actor hash references with the
advertised `actor_shell_required_keys`. The scheduler facade return-shape
fields advertise that `lower(...)` returns a hash reference with
`lower_result_presence_keys`, and that `report(...)` returns a JSON string
encoding `schedule_report_top_level_keys`.
These fields are exact return-shape metadata. They do not freeze the raw actor
hash, the full lower-result hash, or every schedule-report field beyond the
bounded metadata advertised by this contract.

Constructors must be called with the exact public class invocants
`FSM::Adapter::ISF` or `FSM::Scheduler::ISF`. The only public constructor
option currently advertised for the ISF parser and scheduler facades is
`debug`. Constructors reject malformed invocants, odd option lists, and
unsupported option names before object creation. The machine-readable contract
advertises the invocant requirement through `constructor_receiver_shape`.
The `constructor_option_names` list is exact discovery metadata for the public
constructor option family.
The constructor receiver and argument-shape strings are exact discovery
metadata for the public constructor boundary.

Parser methods must be called on an object returned by
`FSM::Adapter::ISF->new(...)`. Scheduler methods must be called on an object
returned by `FSM::Scheduler::ISF->new(...)`. The machine-readable contract
advertises those receiver boundaries through `parser_method_receiver_shape` and
`scheduler_method_receiver_shape`.
Those receiver-shape strings are exact discovery metadata.

`parse_file(...)` requires exactly one defined scalar path argument, and that
path must have a `.isf` suffix and name a readable regular file before private
parsing begins. The machine-readable contract advertises this through
`parse_file_path_requirement`.
`parse_source(...)` requires exactly two defined scalar arguments: source text
and source label.
`lower(...)` and `report(...)` require exactly one scheduler-consumable actor
hash reference from the ISF adapter. The current public actor shell requires
scalar `actor_name`, array `transactions`, and hash `interface` fields.
The machine-readable contract advertises those required shell fields through
`actor_shell_required_keys` and the value shapes through
`actor_shell_value_shape`. That promise is intentionally a shell contract: the
full raw actor hash remains non-public.
Actor roots may also carry parser-validated actor-owned storage declarations
through a singleton `(storage ...)` clause. That field is not a required actor
shell key, but the advertised value-shape string records that `storage` is an
optional array reference when present. The shipped storage entries include
scalar declarations authored with preferred `(var ...)` or verbose
`(variable ...)`, where widths may be positive integer literals or
actor-local scalar parameters, declared actor constants, or qualified imported
package scalar constants that resolve to positive integers, plus fixed-depth
`bank` declarations whose widths and depths may use those same static scalar
sources and whose scalarized element names are scheduler input.
Scalar width-based storage variables may also carry optional declarative
`(fields ...)` metadata. The parser validates field names, literal bit ranges,
non-overlap, optional access tokens, optional field reset metadata against an
explicit parent reset, and inline enum values. The lower/report surface
preserves accepted fields through `inferred_storage[].fields`; generated
`.fsm`, HDL, access-policy behavior, reset derivation, banks, aggregate
carriers, and packet/flit layouts are unchanged by that metadata.
Schedule reports still use coarse `kind: register` for generated storage
class; that report value is not the source vocabulary.
Actor roots may also carry parser-validated actor-local constants through a
singleton `(constants ...)` clause. That field is not a required actor shell
key, but the advertised value-shape string records that `constants` is an
optional array reference when present.
Actor roots may also carry the first bounded ATL static actor-network
metadata through direct actor-level `(instance NAME of ACTOR_TYPE)` clauses or
compact `(NAME : ACTOR_TYPE)` aliases. The enclosing actor is the network
boundary; `(network ...)` wrappers are not part of the shipped source surface.
That field is not a required actor shell key. When present, `actor_network` is
a `static_declaration` hash with direct static instance metadata, optional
report-only group metadata, shipped event, trigger, data movement, exact
temporary trigger-batch metadata, resolved library-qualified child artifact
metadata, and the bounded generated ATL top families. Schedule reports project
it through top-level `actor_network`. Verbose instances report
`declaration: "actor"`; compact instance aliases report
`declaration: "instance_alias"`. Resolved instance entries report actor type
provenance and child artifact names. The generated-top subset wires the
selected one-child trigger/event
forms, the selected one-child scalar pin-ingress route, the selected
one-child exact-width vector pin-ingress route, the same-child scalar
pin-ingress multi-route extension, the same-child vector pin-ingress
multi-route extension, the same-child mixed scalar/vector pin-ingress
route-set extension, the selected one-child pin-egress route, the selected
one-child exact-width vector pin-egress route, the same-child pin-egress
multi-route extension, the same-child vector pin-egress multi-route extension,
the same-child mixed scalar/vector pin-egress route-set extension, the selected
two-child trigger/event
sequence, and the selected two-child scalar or exact-width vector
generated-child actor-to-actor route set. No group endpoints,
route mux/storage, broader HDL event wiring, or
broader generated-top data routing is promised by this field.
The selected broader ATL v0 public direction is direct actor-body syntax plus
existing drive-body movement syntax, but most of those forms remain future
behavior until advertised by capability metadata. Endpoint-aware movement
will keep drive body pair order as `(sink source)` and may later admit
qualified `pins.name`, `actor.port`, `actor.transaction`, `actor.event`, and
`group.name` endpoints. `connect`, `transfer`, and `move` are not public ATL
v0 movement clauses. Unsupported qualified actor endpoint drive-body pairs
naming a declared static actor instance reject with ATL data-movement
diagnostics unless they match the shipped actor-to-actor subset.
The generated actor-to-actor handoff subset is now implemented in the public
API for one-bit scalar and exact-width vector child endpoint routes. That
subset admits exactly two direct static actor instances, one named drive body
with one `(sink_actor.endpoint source_actor.endpoint)` pair, and one top-level
transaction drive call. FSMGen rewrites the pair to generated parent handoff
signals named `source_actor_source_endpoint` and
`sink_actor_sink_endpoint`; their width is the resolved matching child endpoint
width. The schedule-report surface is `actor_network.data_movements[]` with
`kind`, `transaction`, `context`, `drive`, `source_instance`,
`source_endpoint`, `source_signal`, `sink_instance`, `sink_endpoint`,
`sink_signal`, `width`, `width_source`, `route_lifetime`, `storage`,
`source`, and `sink`. Scalar one-bit routes use
`kind: "scalar_actor_handoff"` and `width_source: "scalar_one_bit"`;
same-width vector routes use `kind: "vector_actor_handoff"` and
`width_source: "resolved_child_endpoint_exact_width"`. Storage, muxing,
broader pin movement, inline/expression movement, width adaptation,
fan-in/fan-out, broader group scheduling outside the exact trigger-batch
subset, CDC, and trigger/await coupling beyond the selected generated-child
top sequence remain future public contracts.
The first top-level pin movement public subset is implemented: one
`(actor.endpoint pins.input_pin)` scalar pair in one named drive body, one
direct static actor instance, and one top-level transaction drive call. The
report kind is `scalar_pin_to_actor_handoff`, with
`source => top_level_pin` and `sink => external_handoff`.
The generated-child top-level input-pin movement subset also accepts one
exact-width vector `(actor.endpoint pins.input_pin)` route for a resolved child
when the top-level input pin and child input endpoint widths match exactly.
The public route entry reports `kind: "vector_pin_to_actor_handoff"`,
`width` equal to that endpoint width, and
`width_source: "top_level_input_pin_resolved_child_endpoint_exact_width"`;
the same-child vector pin-ingress multi-route subset accepts multiple such
routes when every route has unique pins/endpoints and exact matching
route-local widths. The same-child mixed scalar/vector pin-ingress route-set
subset accepts scalar one-bit and exact-width vector routes together when all
routes target the same resolved child, share one parent transaction, use unique
top-level input pins and child input endpoints, and keep adjacent pre-trigger
drive calls. Each route keeps its own public `kind`, `width`, and
`width_source`. Width adaptation and mixed pin-egress route sets remain outside
the public contract.
The inverse actor-to-top-level output pin public subset is implemented: one
`(pins.output_pin actor.endpoint)` scalar pair in one named drive body, one
direct static actor instance, and one top-level transaction drive call. The
report kind is `scalar_actor_to_pin_handoff`, with
`source => external_handoff` and `sink => top_level_pin`.
The generated-child top-level output-pin movement subset also accepts one
exact-width vector `(pins.output_pin actor.endpoint)` route for a resolved
child when the child output endpoint and top-level output pin widths match
exactly. The public route entry reports
`kind: "vector_actor_to_pin_handoff"`, `width` equal to that endpoint width,
and
`width_source: "top_level_output_pin_resolved_child_endpoint_exact_width"`;
the same-child vector pin-egress multi-route subset accepts multiple such
routes when every route has unique child outputs/top-level pins and exact
matching route-local widths. The same-child mixed scalar/vector pin-egress
route-set subset accepts scalar one-bit and exact-width vector routes together
when all routes source the same resolved child, share one parent transaction,
use unique child output endpoints and top-level output pins, and keep adjacent
post-event drive calls. Each route keeps its own public `kind`, `width`, and
`width_source`. Width adaptation and broader mixed route fabrics remain outside
the public contract.
Future blocking and nonblocking orchestration spellings are reserved as
`(do actor.transaction)` and `(spawn actor.transaction as NAME)`, with event
payloads deferred. Transaction-body `(trigger actor.transaction)` has a
bounded parent-handoff subset, and one top-level rule action
`(trigger actor.transaction)` may use the same parent-handoff output surface.
Concurrent groups may still be declared with
`(group NAME (members ACTOR...) (mode concurrent))`, but groups are static
review metadata only. They are not required for task-scoped ATL trigger
associations and do not create permanent runtime associations or override
safety checks.
The concurrent-group implementation axis has shipped targeted diagnostics and
report-only metadata:
direct actor-body `(group NAME (members ACTOR...) (mode concurrent))`
declarations now report static `actor_network.groups[]` metadata when every
member names an already declared direct static actor instance. Compact
`(concurrent NAME ACTOR...)` aliases now normalize to the same report-only
metadata surface and report `declaration: "concurrent_alias"` instead of the
verbose form's `declaration: "group"`. Group entries also keep
`source: "actor_body"` and `scheduling: "metadata_only"` in this subset. No
public group endpoint behavior is implemented yet. Source-authored group
endpoints now fail closed before generic dotted enum-member handling when the
qualifier names a declared static group: transaction-body `(trigger
group.name)`, `(await group.name)`, `(await_all group.name)`, `(await_any
group.name)`, and rule-action `(trigger group.name)` report the ATL
group-endpoint diagnostic. The diagnostic names the missing group-level
trigger arbitration/fanout, event aggregation, storage/lifetime, and
generated-child wiring semantics.
The first public multi-actor trigger scheduling contract is a same-cycle
external trigger batch over existing top-level transaction-body
`(trigger actor.transaction)` clauses. The batch is a task-scoped temporary
association: one contiguous trigger run may target distinct static actor
instances, lowers to one trigger-batch state, and advertises scheduling
evidence through canonical `actor_network.association_schedules[]` entries.
The existing `actor_network.group_schedules[]` array remains a
schema-version-1 compatibility view for current downstream consumers. If the
trigger set matches one declared static group, the compatibility `group` field
names that group; otherwise it carries a synthetic transaction-scoped name
such as `run_trigger_batch`. Public reports therefore separate static
membership (`groups[]`) from scheduled temporary associations
(`association_schedules[]`).
The current shipped actor-event wait subset accepts top-level transaction-body
`(await actor.event)` in the bounded selected ATL contexts. The external
parent-handoff subset supports one declared static actor instance and lowers
to a generated one-bit parent event handoff input named `actor_event`; for
example, `reader.done` lowers through `reader_done`. The generated-top subset
also uses these event wait records for the selected one-child and two-child
resolved-library forms, including the selected two-child trigger-batch
generated top. A temporary trigger batch may also be followed by a contiguous
source-ordered chain of multiple top-level waits when each wait targets a
distinct triggered actor instance and no ATL data movement is in that
transaction segment; the waits remain sequential scheduled states, not a
hidden same-cycle join. In the selected resolved-child trigger-batch generated
top, those parent event handoffs are wired internally from the generated child
event outputs. Schedule reports expose waits through
`actor_network.event_waits[]` entries with `transaction`, `context`,
`instance`, `event`, `signal`, and `source` keys, where `source` is currently
`external_handoff`. Nested event waits, repeated actor waits, hidden fan-in or
fan-out event joins, event payloads, cross-clock actor events, concurrent
group events, and waits outside the selected generated-top/source-order
shapes remain fail-closed/deferred. When a temporary trigger batch is followed
by multiple waits to the same triggered actor instance, the diagnostic names
the missing event re-arm or per-event generation/lifetime contract instead of
advertising a hidden repeated-wait behavior. Sync-clause spellings such as
`(await_all reader.done writer.done)` or
`(await_any reader.done writer.done)` also fail closed with an ATL event-join
diagnostic; `await_all`/`await_any` remain generated-child completion sync
forms, not qualified actor-event all-of/any-of joins.
Existing unqualified local `(await signal)` and rule-level
`(trigger transaction)` behavior remains unchanged, and dotted enum-looking
names outside actor-network instances and static groups keep their prior
diagnostics.
Regression coverage includes the accepted temporary trigger-batch multi-event
wait fixture and negative repeated-wait boundaries; repeated waits fail before
scheduled `.fsm` emission, with trigger-batch repeated waits receiving the
targeted event re-arm/lifetime diagnostic.
The current qualified actor-trigger subset is one top-level transaction-body
`(trigger actor.transaction)` for a static actor instance, plus the exact
same-cycle temporary trigger batch described above. It also includes one
top-level rule action `(trigger actor.transaction)` for a static actor
instance. Each trigger lowers to a generated one-cycle parent output handoff
named `actor_transaction_start`. For example, `reader.capture` lowers through
`reader_capture_start`, and rule action `worker.process` lowers through
`worker_process_start`; the scheduled parent `.fsm` pulses that output at the
transaction trigger point or in the guarded rule DT. The trigger sink is
external for parent-handoff-only sources; in selected generated-top sources
the generated top wires that handoff into the resolved child transaction start
input. Nested qualified triggers, repeated triggers to the same instance, repeated
rule-action qualified triggers, generated handoff signal conflicts,
fan-in/fan-out, cross-clock actor triggers, rule-action trigger payloads or
bindings, and broader concurrent group behavior remain deferred. Schedule
reports expose this through `actor_network.transaction_triggers[]` entries
with `owner_transaction`, `context`, `instance`, `target_transaction`,
`signal`, and `sink` keys, where `sink` is currently `external_handoff`; rule
actions use `context: "rule_action"` and have no owning transaction.
Rule-action `group.name` triggers remain unsupported and use the same ATL
group-endpoint diagnostic as transaction-body group triggers.
Actor roots may also carry parser-validated clock-domain declarations through
a singleton `(clock-domains ...)` clause. That field is not a required actor
shell key, but the advertised value-shape string records that `clock_domains`
is null for legacy one-clock actors or optional live metadata for accepted
domain declarations. When `clock_domains` is present, the compatibility
`clock` and `reset` fields expose the selected default domain only.
The bank access forms `(store <bank-name> <index> <value>)` and
`(load <bank-name> <index> as <target>)` are now public parser support for
declared actor-owned banks in rules and supported transaction contexts. The
second item is the authored bank name; actors may declare multiple banks. They
lower to scalarized guarded `.fsm` assignments and successful reports expose
bounded `bank_accesses` metadata with the access kind, owner, container, bank
name, index token, width/depth, scalarized entries, value or target, and
the read-before-write same-cycle policy. The file-backed
`isf/fifo_data_path.isf` fixture is the public bank datapath example and is
covered by `t/1319-isf-fifo-datapath-fixture-coverage.t` for strict schedule
JSON parity plus plain and strict HDL generation.
The sibling `isf/fifo_controller.isf` fixture is the public controller-only
example for occupancy, full/empty, and pointer updates; it is covered by
`t/1320-isf-fifo-controller-fixture-coverage.t`.
The `isf/fifo_library_use.isf` fixture is the public fixed reusable-library
example for the combined controller/datapath FIFO actor; it is covered by
`t/1321-isf-fifo-library-fixture-coverage.t` for strict schedule JSON parity,
multi-file scheduled `.fsm` emission, fixed parameter/binding provenance, and
plain plus strict generated-top HDL generation.
`store` is bank-entry-only public syntax. Scalar storage updates remain the
ordinary rule assignment and transaction `update` surfaces.
The current public parser handoff also advertises one bounded subshape inside
that shell: `interface` contains `inputs` and `outputs` arrays, and each public
port entry has unique non-empty scalar `name` plus positive integer `width`,
with omitted source widths normalized to `1`. Source `(width PARAM)` and
`(width CONST)` are accepted only when they name an actor-local scalar
parameter default or declared actor constant that resolves to a positive
integer; the public port entry still carries the resolved integer width, not
the authored token. Accepted clock-domain sources may carry scalar `domain`
ownership metadata on those port entries. The machine-readable contract
advertises this through
`actor_shell_interface_shape`.
This is current live-contract metadata for scheduler-consumable parser output;
it does not make actor fields outside the advertised shell public or freeze
future ISF interface extensions before they are documented and audited.
The current public parser handoff also advertises a bounded transaction-entry
shell: `transactions` is an array of entries with unique non-empty scalar
`name`, `ports.inputs[]` / `ports.outputs[]` entries that carry resolved
positive integer `width` values, `clauses` array fields, and optional scalar
`domain` ownership metadata. Transaction-local `(width PARAM)`,
`(width CONST)`, and `(width PACKAGE.CONSTANT)` entries are accepted only when
the source names an actor-local scalar parameter default, declared actor
constant, or qualified imported package scalar constant that resolves to a
positive integer; the public port entry carries the resolved integer width,
not the authored token. The machine-readable contract advertises this through
`actor_shell_transaction_shape`. The `clauses` array is a scheduler-consumable
container; its payload contents are intentionally not frozen as a public API by
this field.
The current public parser handoff also advertises the actor identity shell:
`actor_name` is a non-empty scalar actor identifier preserved from the ISF actor
root. The machine-readable contract advertises this through
`actor_shell_actor_name_shape`.
The current public parser handoff also advertises bounded actor timing fields:
`clock` is a non-empty scalar, with omitted legacy single-clock actor clocks
defaulting to `clk`; `reset` is a default-domain hash with scalar `name`,
`kind`, and `polarity`, with omitted legacy single-clock actor resets
defaulting to async active-low `rst_n`; and `watchdog` is a positive resolved
integer, with omitted watchdog clauses defaulting to `65535` exactly
`(2^16 - 1)`. Actor-level watchdog constants, actor-local scalar parameter
defaults, and qualified imported package scalar constants are accepted when
they resolve to positive integers; the parser returns the resolved integer in
`watchdog` and keeps the authored declaration visible through
`actor_constants[]`, `actor_params[]`, or package/import metadata and embedded
package `+constants` entries. Await-local watchdog constants, actor scalar
parameters, qualified imported package scalar constants, and same-transaction
scalar parameter defaults resolve during lowering. Transaction parameters are
accepted only on top-level await-local watchdog overrides, where they shadow
actor-level static names and remain local lowering inputs. One transaction
still has one watchdog counter, so distinct per-await watchdog limits in the
same transaction fail closed.
Generated child activation overrides for top-level await-local watchdog
transaction parameters are accepted only when they resolve to the same
positive integer as the child default; mismatches fail closed until
per-activation watchdog counter specialization is shipped.
When `clock_domains` is present, `clock` and `reset` expose the selected
default-domain timing, and `reset` is null only when that domain omits reset.
Public multi-domain `lower(...)` emits domain-specific scheduled `.fsm`
artifacts plus a generated multi-domain top, and public `report(...)` exposes
bounded domain and crossing report metadata. The machine-readable contract
advertises this through `actor_shell_timing_shape`.
Those timing fields, along with `interface`, parser-carried `resources`,
parser-carried `storage`, and parser-carried `crossings`, are source-level
singleton actor clauses. The `clock-domains` clause is also singleton and is
mutually exclusive with
actor-level `clock` and `reset`. Repeating one is a parser boundary error; the
parser does not merge duplicate interface/resources/storage/clock-domain
blocks or let later clock/reset/watchdog clauses overwrite earlier ones.
The current public parser handoff also advertises a bounded rule-entry shell:
`rules` is an array of entries with unique non-empty scalar `name`, optional
`when`, `actions` array fields, and optional scalar `domain` ownership
metadata. The machine-readable contract advertises this through
`actor_shell_rule_shape`. Rule condition/action payload contents remain private
scheduler input.
Authored `(rule name condition actions...)` shorthand and long-form
`(rule name (when condition) actions...)` normalize to the same public `when`
field. The guard may be a scalar condition or a list expression using the
normal `.fsm` expression spelling. Rule-local `(when condition)` is a
guard-only clause; it is not the transaction `(when condition body...)`
control-flow construct.
Current scheduled `.fsm` review artifacts emit a rule's `when` guard as the
non-state DT header DTE for that rule's lowered actions. This keeps the
generated text aligned with the source rule structure without widening the
actor-shell rule payload contract.
Within that scheduled `.fsm` review artifact, ordinary rule `(port expr)`
actions remain flopped assignments inside the guarded DT, while
`(trigger transaction)` actions use `<1` on a generated `rule_transaction`
trigger source inside that same guarded DT. A rule trigger is therefore a
one-cycle delayed pulse, not a sticky flopped request bit.
Multiple rules may trigger the same transaction. The current scheduled `.fsm`
artifact exposes those triggers as distinct one-bit `rule_transaction` sources
and emits a generated combinational `transaction_trigger_fanin` DT for each
triggered transaction. The fan-in drives `transaction_start` from the OR of the
rule sources without adding latency, so downstream consumers can inspect
per-rule trigger provenance before the transaction start OR.
Parser handoff now requires each rule trigger target to resolve to a declared
transaction in the same actor. This prevents a misspelled rule trigger from
inventing an otherwise unowned `transaction_start` fan-in path.
Lowering also performs best-effort static conflict checks for rule data writes:
provable incompatible rule/rule writes to the same target fail closed, while
same-target rule writes with direct contradictory guard facts are accepted as
disjoint. This proof is conservative and currently recognizes simple signal
and negated-signal terms plus equality facts, including conjunctions used by
FIFO fire predicates and pointer/occupancy matrix cases. A named drive with
exactly one distinct local transaction caller and no generated caller uses
that transaction as its logical conflict/priority actor while keeping raw
drive provenance. Different-value overlap without priority then fails closed
as `isf_conflicting_rule_transaction_writes`. Shared, generated, mixed-source,
or unused-drive overlap without an applicable priority remains nonfatal and is
projected into successful schedule-report `compile_issues` as
`isf_unproven_rule_drive_overlap/not_doable`; reports with no nonfatal issues
still keep that array empty.
For same-target rule/rule data conflicts, rule-local and actor-level priority
edges can now select a target-local winner by guarding the lower-priority
assignment with the inverse higher-priority rule condition. This changes the
scheduled `.fsm` review artifact and does not itself add a compile issue.
Actor-level rule-over-transaction priority is also enforced for the covered
same-target data case when both assignments use the same timing operator: the
transaction-state assignment is guarded with the inverse active rule
condition. Spawned transaction output bindings are also treated as
transaction-owned data for this conflict pass, so a spawned child output bound
to an actor output cannot silently coexist with a conflicting rule writer.
Actor-level transaction-over-rule priority is enforced for the covered
same-target data case too: the transaction-state assignment stays unchanged,
and the lower-priority rule assignment is guarded with the inverse scheduled
`.fsm` `(state_active STATE)` predicate for the winning transaction state.
That predicate lowers to an internal `current_state == STATE` comparison
without creating fake module inputs for `current_state`, state constants, or
generated state-enable names. Unordered rule/transaction conflicts, priority
cycles, and mixed timing operators still fail closed.
The same actor-level priority declarations cover a uniquely owned named-drive
assignment. Rule-over-transaction adds the inverse rule condition only to the
conflicting drive-body assignment; transaction-over-rule guards only the
conflicting rule assignment with the inverse full drive activation. Drive
request fan-in, transaction progress, completion, parameters, and unrelated
drive outputs are not masked. A priority involving shared, generated, or mixed
drive ownership fails before HDL as
`isf_ambiguous_rule_transaction_drive_priority` because no unique logical
transaction owner can be proved. Private drive caller/source metadata and
invoking-transaction provenance do not widen the public schedule-report or
normalized-semantic schemas.
After scheduled `.fsm` reaches the HDL backend, generated SystemVerilog now
adds verification-only selector assertions derived from backend assignment
analysis. Same-value source selectors for one `LHS`/`VAL` selector and
different-value selectors for one `LHS` mux are checked with `$onehot0` under
`` `ifndef SYNTHESIS``. Verilog emission remains free of those assertions.
This does not widen the successful public ISF schedule-report schema; the
selector metadata lives in the downstream HDL-generation/lowered-RTL result
surface, whose full hash remains outside the ISF public contract.
The current public parser handoff also advertises a bounded drive-definition
shell: `drives` is a hash of entries keyed by unique non-empty drive name, and
each entry has unique scalar `params` and `body` arrays. Body entries are
parser-validated as scalar `(port value)` pairs. The machine-readable contract
advertises this through `actor_shell_drive_shape`. Richer drive semantics
remain private scheduler input.
Drive parameter names are also parser-validated before actor-shell return:
[t/1189-isf-drive-parameter-boundary.t](../../t/1189-isf-drive-parameter-boundary.t)
keeps parameterized drive declarations from reusing one parameter name for
multiple positional arguments.
Known drive calls are exact-arity calls: the number of actual values must match
the drive's declared parameter count. Extra actuals are rejected during
lowering rather than silently discarded, and missing actuals keep the existing
targeted missing-parameter diagnostic.
The parser/scheduler argument-shape fields and actor-shell key list are exact
facade-shape discovery metadata.
Public facade boundary failures produce bounded scalar diagnostics before
object creation, private parsing, or private lowering/reporting begins. The
machine-readable contract advertises this through
`facade_failure_diagnostic_shape`.

The advertised ISF-specific CLI option family is `--emit-schedule-json`,
`--outdir`, and `--strict`.
The `cli_option_names` list is exact discovery metadata for that option family.
The CLI success-shape fields are exact discovery metadata for successful public
CLI runs: `--emit-schedule-json` writes schedule-report JSON to stdout with
empty stderr, `--outdir DIR` writes lower-result `.fsm` files by basename into
`DIR`, and plain single-clock `file.isf` generation lowers through scheduled
`.fsm` and any generated composition top before writing the requested HDL
output with empty stderr. Plain multi-domain `file.isf` HDL generation for
accepted event-crossing actors writes the generated domain/top `.fsm`
artifacts, then emits SystemVerilog/Verilog-family HDL containing the
generated multi-domain top and concrete acknowledged-event CDC child modules
for accepted crossings when each emitted domain artifact satisfies the current
scheduled `.fsm` HDL contract. No-reset event-crossing actors are public
lower/report/schedule-JSON and HDL fixtures: their generated CDC metadata
marks source and destination resets absent, their domain modules omit reset
ports, and their generated CDC child omits absent reset ports.
`--emit-schedule-json` succeeds for accepted multi-domain actors.
The strict CLI success-shape field advertises that accepted `--strict
file.isf` generation follows the public HDL-generation success shape and keeps
stderr empty on success.
For `.isf` inputs, `--check --json` and `--check-json` now preserve the public
check JSON failure surface for parser, lowering, schedule-report, and
downstream semantic check failures. These failures exit nonzero, write
`success: false` JSON to stdout, keep stderr clean for the machine-readable
mode, and preserve the normalized diagnostic text in `diagnostics[0].message`.
Successful `.isf` check JSON and normalized semantic JSON keep
`source.resolved_path` on the resolved `.isf` input path, not on the temporary
scheduled `.fsm` artifact, and the public `isf/apb_requester.isf` fixture is
support-accounting matched. The normalized semantic payload still describes the
generated `.fsm` semantic root.

## Lower Result

`FSM::Scheduler::ISF->lower($actor)` returns a hash with the advertised top-level
key:

```text
files
```

`files` is a hash reference mapping `.fsm` basenames to scheduled module,
resolved ATL child module, generated ATL top, multi-domain domain scheduled
module, specialized library-child module, generated multi-domain top, or
generated composition-top `.fsm` source text.
The generated `.fsm` text is a reviewable compiler artifact and then flows
through the existing `.fsm` pipeline where that path is implemented.
The plain single-clock `file.isf` CLI path lowers through that pipeline into
generated HDL.
Each public `files` key is a `.fsm` basename with no directory components.
Scheduled module values, including emitted multi-domain domain artifacts, are
`.fsm` source text rooted at `(?fsm:<basename-stem> ...)`; generated top
values are `.fsm` source text rooted at `(?top:<basename-stem> ...)` and may
append embedded `(?rtlif:...)` declarations for explicit CDC child interfaces.

The `--outdir` CLI path materializes the same lower-result `.fsm`
basename/text map on disk for HDL-ready multi-file lowerings. Accepted
multi-domain event-crossing actors now use that materialized generated top as
the HDL entry and emit the concrete generated CDC child beside the domain
modules.

The full lower-result hash is not yet a broad public API beyond the advertised
keys.
The `lower_result_presence_keys`, `lower_result_file_map_shape`,
`lower_result_file_name_shape`, and `lower_result_file_text_shape` fields are
exact lower-result discovery metadata for the currently public `files` map.

## DT Assignment Operators

Scheduled `.fsm` text can contain assignment operators in state DT blocks and
non-state DT blocks. DT selector logic is combinational; the assignment
family decides what kind of target the selected value drives, not whether the
DT itself is combinational or sequential:

- `=` drives a combinational target mux output.
- `<-` and `<=` drive sequential/flopped targets.
- `<1` requests a one-cycle delayed pulse.

When scheduled `.fsm` text assigns a declared actor output port, the emitted
LHS carries the normal `.fsm` output marker for every assignment family, such
as `done>`, `last_error>`, or `rdata>`.

The machine-readable contract advertises these target-behavior families through
`dt_assignment_operator_family_map`.

ISF `(complete port)` lowering uses `<1`, not `<-`, so completion outputs are
one-cycle delayed pulses rather than sticky flopped status bits. The source
form is exact and requires one scalar `port` target. Drive phases that precede
completion should not also assign the same completion signal with `<-`; the
`.fsm` backend rejects mixed pulse-delayed and non-pulse sequential operators
on one LHS.
Blocking `(do child)` lowering also uses `<1` for the internal
`child_transaction_done` handoff generated in the rewired child terminal state.
That keeps each parent-visible child completion as a pulse, so repeated `do`
calls wait for fresh child completions instead of observing a sticky
already-done bit.
Blocking `(do child ...)` and parallel `(spawn child as instance ...)`
lowering also require the child target to resolve to a declared transaction in
the same actor before scheduled `.fsm` text is emitted. Forward references are
accepted, but missing child targets fail closed so they cannot synthesize dead
`child_start`/`child_done` or `instance_start`/`instance_done` paths.
Parameterized/generated `do` activations use generated instance handoffs such
as `{parent}_{child}_do_{ordinal}_start` and `_done`.
Spawned child instances are static generated HDL. Runtime spawn states only
activate the persistent child instance through its start path, and child
completion returns that instance to start-gated idle. Repeat-body spawn reuses
the same lexical instance on each iteration, including optional static
parameter overrides and optional input/output binding handoff ports, and the
shipped repeat-body subset requires same-body `await_all` sequencing, or
single-pending same-body `await_any`, before the repeat check can re-enter the
spawn. Repeat-body local `(do child)` reuses the local child start/done pulse
contract and reaches the repeat check only after the child done pulse is seen.
ISF rule `(trigger transaction)` lowering also uses `<1`, not `<-`, for the
generated `rule_transaction` trigger source. Generated combinational fan-in
then drives `transaction_start` from every source for that transaction. This
keeps rule-driven transaction starts pulse-shaped instead of leaving a sticky
start request active after the rule fires, while preserving per-rule trigger
provenance in the scheduled `.fsm` artifact.

ISF `(sample port as name)` lowering is a D-input contract. The source form is
structurally exact: `port` and `name` are scalar names, `as` is required, and
extra operands are rejected. Scheduled `.fsm` artifacts use `<=`, not `<-`, so
the authored sampled name denotes the D-input/next-value side in the state
where the sample appears. This preserves same-state visibility for sample
piggybacking, especially when a drive follows the samples and its parameter
wiring consumes a sampled alias in the same scheduled state. Lowering samples
with `<-` would instead make the alias denote the previous Q/output value in
that state and could require an extra state to avoid stale data.
