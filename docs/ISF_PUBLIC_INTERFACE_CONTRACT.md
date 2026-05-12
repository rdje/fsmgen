# ISF Public Interface Contract

This is the live downstream-consumer contract for the `.isf` intent-scheduling
surface.

It is intentionally a live document: any implementation slice that changes
supported ISF syntax, CLI behavior, public in-process facade behavior, scheduled
`.fsm` result shape, or schedule-report shape must update this file in the same
commit.

Machine-readable discovery lives in
[perl/FSM/Support/ISFPublicInterfaceContract.pm](../perl/FSM/Support/ISFPublicInterfaceContract.pm)
and is advertised through:

```text
./bin/fsmgen --capability-manifest
  -> embedding.isf_public_interface
```

The advertised contract object is full-surface JSON-round-trip audited by
[t/1113-isf-public-interface-contract-json-roundtrip-audit.t](../t/1113-isf-public-interface-contract-json-roundtrip-audit.t).
Downstream tools can treat that contract metadata as JSON-safe discovery data.
It is also defensive-copy audited by
[t/1114-isf-public-interface-contract-defensive-copy-audit.t](../t/1114-isf-public-interface-contract-defensive-copy-audit.t),
so callers can mutate a received copy without polluting later contract builds.
The identity and stability metadata is checked by
[t/1141-isf-public-identity-flags-metadata-audit.t](../t/1141-isf-public-identity-flags-metadata-audit.t)
to keep schema version, bounded status, owner list, and stability flags exact
across direct and manifest views.
The downstream guidance metadata is checked by
[t/1142-isf-public-guidance-metadata-audit.t](../t/1142-isf-public-guidance-metadata-audit.t)
to keep the advertised consumer advice exact and duplicate-free across direct
and manifest views.
The ISF-specific `tested_by` provenance metadata is checked by
[t/1144-isf-public-tested-by-metadata-audit.t](../t/1144-isf-public-tested-by-metadata-audit.t)
to keep the advertised audit list exact, duplicate-free, repo-relative, and
present on disk across direct and manifest views.
Both capability-manifest CLI spellings are audited by
[t/1115-isf-public-interface-cli-manifest-audit.t](../t/1115-isf-public-interface-cli-manifest-audit.t)
to keep the in-process contract and CLI-advertised contract aligned.
The `public_top_level_presence_keys` discovery list is checked by
[t/1131-isf-public-top-level-discovery-audit.t](../t/1131-isf-public-top-level-discovery-audit.t)
to stay unique and exact across direct, manifest, and CLI manifest views.
The advertised entrypoint metadata is checked by
[t/1135-isf-public-entrypoint-metadata-audit.t](../t/1135-isf-public-entrypoint-metadata-audit.t)
to stay exact and duplicate-free across the same views.
The advertised ISF CLI option list is checked by
[t/1136-isf-public-cli-option-metadata-audit.t](../t/1136-isf-public-cli-option-metadata-audit.t)
to stay exact and duplicate-free across direct and manifest views.
The advertised parser and scheduler method-name lists are checked by
[t/1137-isf-public-method-name-metadata-audit.t](../t/1137-isf-public-method-name-metadata-audit.t)
to stay exact and duplicate-free across those views.
The advertised constructor option list is checked by
[t/1138-isf-public-constructor-option-metadata-audit.t](../t/1138-isf-public-constructor-option-metadata-audit.t)
to stay exact and duplicate-free across those views.
The plain `file.isf` HDL-generation path is checked by
[t/1123-isf-public-cli-hdl-generation-audit.t](../t/1123-isf-public-cli-hdl-generation-audit.t)
to reach generated HDL with clean stderr for the APB fixture.
The advertised `--strict` option on that path is checked by
[t/1124-isf-public-cli-strict-mode-audit.t](../t/1124-isf-public-cli-strict-mode-audit.t).
The current APB schedule report is checked against the advertised key families
by [t/1116-isf-public-schedule-report-key-family-audit.t](../t/1116-isf-public-schedule-report-key-family-audit.t).
The advertised schedule-report metadata itself is checked by
[t/1140-isf-public-schedule-report-metadata-audit.t](../t/1140-isf-public-schedule-report-metadata-audit.t)
to keep key families, grouped family maps, ordering, multi-file scope, and
successful `compile_issues` shape exact across direct and manifest views.
The schedule-report DT assignment-count shape is checked by
[t/1147-isf-public-report-dt-assignment-count-audit.t](../t/1147-isf-public-report-dt-assignment-count-audit.t)
to keep `dt_blocks[*].assignments` documented as a non-negative assignment
count, not an assignment payload list.
The inferred-storage metadata is checked by
[t/1148-isf-public-storage-metadata-audit.t](../t/1148-isf-public-storage-metadata-audit.t)
to keep advertised storage `kind` values and optional `width` shape exact
across direct and manifest views.
The transaction-summary metadata is checked by
[t/1149-isf-public-transaction-metadata-audit.t](../t/1149-isf-public-transaction-metadata-audit.t)
to keep transaction `states` and `count` shapes exact across direct and
manifest views.
The reset-summary metadata is checked by
[t/1150-isf-public-reset-metadata-audit.t](../t/1150-isf-public-reset-metadata-audit.t)
to keep advertised reset `kind` and `polarity` values exact across direct and
manifest views.
The schedule-report count metadata is checked by
[t/1151-isf-public-report-count-metadata-audit.t](../t/1151-isf-public-report-count-metadata-audit.t)
to keep interface and state-count semantics exact across direct and manifest
views.
The schedule-report scalar metadata is checked by
[t/1152-isf-public-report-scalar-metadata-audit.t](../t/1152-isf-public-report-scalar-metadata-audit.t)
to keep `source`, `scheduled_fsm`, `clock`, and `watchdog` shapes exact across
direct and manifest views.
The public `--emit-schedule-json` CLI path is checked by
[t/1121-isf-public-cli-schedule-report-audit.t](../t/1121-isf-public-cli-schedule-report-audit.t)
to emit clean-stderr JSON matching the in-process scheduler report.
The successful `compile_issues` report shape is checked by
[t/1130-isf-public-compile-issues-success-audit.t](../t/1130-isf-public-compile-issues-success-audit.t)
for both in-process and CLI report paths.
The lower-result `files` map is checked for both single-file and multi-file
lowering by [t/1117-isf-public-lower-result-files-audit.t](../t/1117-isf-public-lower-result-files-audit.t).
The lower-result discovery metadata is checked by
[t/1139-isf-public-lower-result-metadata-audit.t](../t/1139-isf-public-lower-result-metadata-audit.t)
to keep `lower_result_presence_keys` and `lower_result_file_map_shape` exact
across direct and manifest views.
The public `--outdir` CLI path is checked by
[t/1122-isf-public-cli-outdir-lowering-audit.t](../t/1122-isf-public-cli-outdir-lowering-audit.t)
to write scheduled `.fsm` artifacts matching the in-process lower-result
`files` map for a multi-file fixture.
The current multi-file schedule-report scope is checked by
[t/1128-isf-public-multifile-schedule-report-audit.t](../t/1128-isf-public-multifile-schedule-report-audit.t).
The `parse_source(...)` facade method is checked by
[t/1118-isf-public-parse-source-facade-audit.t](../t/1118-isf-public-parse-source-facade-audit.t)
to ensure in-memory source text returns a scheduler-consumable actor with the
same public lower/report identities as `parse_file(...)` for a real fixture.
Generated `.fsm` DT block order and schedule-report `dt_blocks` order are
checked by
[t/1119-isf-deterministic-dt-block-order.t](../t/1119-isf-deterministic-dt-block-order.t)
for both `parse_file(...)` and `parse_source(...)` on the APB fixture.
The scheduled `.fsm` artifact metadata is checked by
[t/1145-isf-public-scheduled-fsm-metadata-audit.t](../t/1145-isf-public-scheduled-fsm-metadata-audit.t)
to keep `scheduled_fsm_dt_ordering`, its paired schedule-report ordering
policy, and the review-artifact flag exact across direct and manifest views.
The DT assignment operator metadata is checked by
[t/1146-isf-public-dt-assignment-metadata-audit.t](../t/1146-isf-public-dt-assignment-metadata-audit.t)
to keep the combinational and sequential assignment families exact across
direct and manifest views.
The `live_document_paths` list is checked by
[t/1120-isf-public-live-document-path-audit.t](../t/1120-isf-public-live-document-path-audit.t)
to keep the direct owner, in-process manifest, and both CLI manifest spellings
aligned on repo-relative Markdown paths that exist on disk.
The public constructor option boundary is checked by
[t/1125-isf-public-constructor-boundary-audit.t](../t/1125-isf-public-constructor-boundary-audit.t)
for both adapter and scheduler facades.
The public constructor receiver boundary is checked by
[t/1133-isf-public-constructor-receiver-boundary-audit.t](../t/1133-isf-public-constructor-receiver-boundary-audit.t).
The public parser facade method boundary is checked by
[t/1126-isf-public-parser-method-boundary-audit.t](../t/1126-isf-public-parser-method-boundary-audit.t).
The public `parse_file(...)` path boundary is checked by
[t/1134-isf-public-parse-file-path-boundary-audit.t](../t/1134-isf-public-parse-file-path-boundary-audit.t).
The public scheduler facade method boundary is checked by
[t/1127-isf-public-scheduler-method-boundary-audit.t](../t/1127-isf-public-scheduler-method-boundary-audit.t).
The parser and scheduler method receiver boundary is checked by
[t/1132-isf-public-method-receiver-boundary-audit.t](../t/1132-isf-public-method-receiver-boundary-audit.t).
The scheduler-consumable actor shell returned by the public parser facades is
checked by
[t/1129-isf-public-actor-shell-contract-audit.t](../t/1129-isf-public-actor-shell-contract-audit.t).
The facade shape metadata that advertises those constructor, method, path, and
actor-shell boundaries is checked by
[t/1143-isf-public-facade-shape-metadata-audit.t](../t/1143-isf-public-facade-shape-metadata-audit.t)
to stay exact across direct and manifest views.

## Stabilized Surface

The current bounded public surface is deliberately narrow.
The machine-readable contract's `public_top_level_presence_keys` list is the
exact top-level discovery list for the contract payload. It is not a partial
hint list.
The schema/status/owner identity fields and stability flags are exact discovery
metadata for the contract's current bounded-public stance.
The `guidance` list is exact downstream-consumer advice for interpreting the
current bounded contract: facade pairs are public, raw internals are not, and
human contract documents must evolve with public ISF changes.
The `tested_by` list is exact audit-provenance metadata for this ISF contract
owner; every path must stay repo-relative and present on disk.

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
`actor_shell_required_keys`. That promise is intentionally a shell contract:
the full raw actor hash remains non-public.
The parser/scheduler argument-shape fields and actor-shell key list are exact
facade-shape discovery metadata.

The advertised ISF-specific CLI option family is `--emit-schedule-json`,
`--outdir`, and `--strict`.
The `cli_option_names` list is exact discovery metadata for that option family.

## Lower Result

`FSM::Scheduler::ISF->lower($actor)` returns a hash with the advertised top-level
key:

```text
files
```

`files` is a hash reference mapping scheduled `.fsm` basenames to scheduled
`.fsm` source text. The generated `.fsm` text is a reviewable compiler artifact
and then flows through the existing `.fsm` pipeline.
The plain `file.isf` CLI path lowers through that pipeline into generated HDL.

The `--outdir` CLI path materializes the same scheduled `.fsm` basename/text
map on disk for multi-file lowerings.

The full lower-result hash is not yet a broad public API beyond the advertised
keys.
The `lower_result_presence_keys` and `lower_result_file_map_shape` fields are
exact lower-result discovery metadata for the currently public `files` map.

## DT Assignment Operators

Scheduled `.fsm` text can contain assignment operators in state DT blocks and
non-state DT blocks. The timing semantics are assignment-family driven, not
block-spelling driven:

- `=` is combinational.
- `<-` and `<=` are sequential/flopped.

A DT may therefore be combinational-only, sequential-only, or mixed depending on
the operators it contains. The machine-readable contract advertises these
families through `dt_assignment_operator_family_map`.

## Schedule Report

`FSM::Scheduler::ISF->report($actor)` and `--emit-schedule-json` produce a
machine-readable schedule report. On success, the CLI report path is expected
to keep stderr clean and emit the JSON payload on stdout.

The bounded public top-level key family is:

```text
source
scheduled_fsm
clock
reset
watchdog
port_count
inputs
outputs
state_count
inferred_storage
transactions
dt_blocks
compile_issues
```

Current bounded nested and array summary families:

```text
reset: name, kind, polarity
inferred_storage entries: name, kind, optional width
transactions entries: name, states, count
dt_blocks entries: name, kind, assignments
compile_issues on success: empty array
```

For each `dt_blocks` entry, `assignments` is a non-negative integer count of
assignment forms in the matching scheduled `.fsm` DT block. It is not an
assignment payload list. The machine-readable contract advertises this through
`schedule_report_dt_assignments_shape`.

For each `inferred_storage` entry, `kind` is currently one of `counter` or
`register`. Optional `width` values are positive integer bit widths when
present, and are currently present for inferred scheduler counters. The
machine-readable contract advertises these through
`schedule_report_storage_kind_values` and `schedule_report_storage_width_shape`.

For each `transactions` entry, `states` is an array of scheduled state names
belonging to that transaction in emitted order, and `count` is a non-negative
integer equal to the `states` array length. The machine-readable contract
advertises this through `schedule_report_transaction_states_shape` and
`schedule_report_transaction_count_shape`.

For the `reset` summary, `kind` is currently `async` or `sync`, and `polarity`
is currently `active_high` or `active_low`. The machine-readable contract
advertises those value families through `schedule_report_reset_kind_values` and
`schedule_report_reset_polarity_values`.

The top-level `inputs` and `outputs` values are non-negative integer counts of
interface ports by direction, and `port_count` equals their sum. The top-level
`state_count` value is a non-negative integer count of scheduled `.fsm` state
blocks in the current parent report scope. The machine-readable contract
advertises this through `schedule_report_interface_count_shape` and
`schedule_report_state_count_shape`.

The top-level `source` value is an actor-derived `.isf` basename, and
`scheduled_fsm` is the scheduled `.fsm` basename for the current parent actor
report scope. `clock` is the scalar clock signal name from the actor
declaration. `watchdog` is a scalar limit when configured and null when omitted.
The machine-readable contract advertises these through
`schedule_report_source_shape`, `schedule_report_scheduled_fsm_shape`,
`schedule_report_clock_shape`, and `schedule_report_watchdog_shape`.

The current lowerer emits DT summaries in deterministic lowering order:
transaction/rule-created DTs retain their construction order, and hash-backed
drive DTs are emitted lexically by drive name. This is a bounded review-artifact
and schedule-report stability promise, not a promise that raw `LoweringIR`
hashes are public. The machine-readable contract advertises the same policy in
`scheduled_fsm_dt_ordering` and `schedule_report_dt_ordering`.
Those ordering fields are exact shared-policy metadata for the current
scheduled `.fsm` review artifact and schedule report.

For multi-file lowerings, the current schedule report describes the parent
scheduled module only. Child scheduled `.fsm` text remains available through the
lower-result `files` map. The machine-readable contract advertises this current
scope in `schedule_report_multi_file_scope`.
For successful schedule reports, `compile_issues` is present as an empty array.
The machine-readable contract advertises this current success shape in
`schedule_report_compile_issues_success_shape`.

The schedule report is not yet a frozen full schema. Downstream consumers should
use the advertised contract metadata instead of assuming every current field,
generated state name, or private lowering decision is permanent.
The advertised schedule-report metadata fields are exact for the bounded public
key families and policy strings they name.

## Non-Public Internals

These are not stable public interfaces yet:

- The raw actor hash returned by the parser as a whole.
- Actor fields beyond the advertised `actor_shell_required_keys`.
- `FSM::Scheduler::ISF::LoweringIR` internals.
- Emitter-private state objects.
- Any unadvertised keys in the lower-result hash or schedule report.

## Evolution Rule

This contract evolves with R14 implementation work.

When an ISF slice changes a downstream-visible behavior, update together:

- [docs/ISF_PUBLIC_INTERFACE_CONTRACT.md](ISF_PUBLIC_INTERFACE_CONTRACT.md)
- [docs/ISF_SPEC.md](ISF_SPEC.md)
- [docs/book/src/13-intent-scheduling.md](book/src/13-intent-scheduling.md)
- [perl/FSM/Support/ISFPublicInterfaceContract.pm](../perl/FSM/Support/ISFPublicInterfaceContract.pm)
- focused regression tests for the changed public surface

The goal is not to freeze ISF prematurely. The goal is to make every public
promise explicit, discoverable, and regression-backed as the ISF compiler grows.
