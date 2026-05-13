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
The advertised CLI success-shape metadata is checked by
[t/1153-isf-public-cli-success-metadata-audit.t](../t/1153-isf-public-cli-success-metadata-audit.t)
to keep the schedule JSON, `--outdir`, and plain HDL-generation success
surfaces exact across direct and manifest views.
The advertised `--strict` HDL-generation success metadata is checked by
[t/1155-isf-public-cli-strict-success-metadata-audit.t](../t/1155-isf-public-cli-strict-success-metadata-audit.t)
to keep the accepted strict `file.isf` generation shape exact across direct and
manifest views and aligned with the APB strict CLI path.
The advertised in-process facade return-shape metadata is checked by
[t/1154-isf-public-facade-return-metadata-audit.t](../t/1154-isf-public-facade-return-metadata-audit.t)
to keep the `parse_file(...)`, `parse_source(...)`, `lower(...)`, and
`report(...)` return containers exact across direct and manifest views and
aligned with real APB facade results.
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
The schedule-report DT kind metadata is checked by
[t/1158-isf-public-report-dt-kind-metadata-audit.t](../t/1158-isf-public-report-dt-kind-metadata-audit.t)
to keep advertised `dt_blocks[*].kind` values exact across direct and manifest
views and aligned with APB plus full-featured reports.
The inferred-storage metadata is checked by
[t/1148-isf-public-storage-metadata-audit.t](../t/1148-isf-public-storage-metadata-audit.t)
to keep advertised storage `kind` values and optional `width` shape exact
across direct and manifest views.
The transaction-summary metadata is checked by
[t/1149-isf-public-transaction-metadata-audit.t](../t/1149-isf-public-transaction-metadata-audit.t)
to keep transaction `states` and `count` shapes exact across direct and
manifest views.
The transaction-ordering metadata is checked by
[t/1157-isf-public-report-transaction-ordering-audit.t](../t/1157-isf-public-report-transaction-ordering-audit.t)
to keep transaction summaries lexically sorted by name while each
transaction's `states` array follows scheduled `.fsm` state emission order.
The reset-summary metadata is checked by
[t/1150-isf-public-reset-metadata-audit.t](../t/1150-isf-public-reset-metadata-audit.t)
to keep advertised reset `kind` and `polarity` values exact across direct and
manifest views.
The reset container/null shape is checked by
[t/1159-isf-public-report-reset-shape-metadata-audit.t](../t/1159-isf-public-report-reset-shape-metadata-audit.t)
to keep configured reset summaries as hashes and omitted resets as JSON null.
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
The lower-result file sub-shape metadata is checked by
[t/1156-isf-public-lower-result-file-shape-audit.t](../t/1156-isf-public-lower-result-file-shape-audit.t)
to keep scheduled `.fsm` basename keys and scheduled-text roots exact across
direct and manifest views and aligned with single-file plus multi-file
lowering.
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
The public facade failure diagnostic metadata is checked by
[t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t](../t/1161-isf-public-facade-failure-diagnostic-metadata-audit.t)
to keep constructor, parser, and scheduler facade boundary failures advertised
as bounded scalar diagnostics.
The scheduler-consumable actor shell returned by the public parser facades is
checked by
[t/1129-isf-public-actor-shell-contract-audit.t](../t/1129-isf-public-actor-shell-contract-audit.t).
The actor-shell value-shape metadata is checked by
[t/1160-isf-public-actor-shell-value-shape-audit.t](../t/1160-isf-public-actor-shell-value-shape-audit.t)
to keep the `actor_name`, `transactions`, and `interface` public handoff
shapes exact across direct and manifest views.
The actor-shell interface subshape is checked by
[t/1162-isf-public-actor-shell-interface-shape-audit.t](../t/1162-isf-public-actor-shell-interface-shape-audit.t)
to keep the parser-returned `interface` inputs/outputs arrays and public port
entry `name`/`width` shape exact across direct and manifest views without
freezing the rest of the raw actor hash.
The actor-shell transaction subshape is checked by
[t/1163-isf-public-actor-shell-transaction-shape-audit.t](../t/1163-isf-public-actor-shell-transaction-shape-audit.t)
to keep parser-returned transaction entries discoverable as scalar `name` plus
`clauses` array shells while leaving the clause payload contents private
scheduler input.
The actor-shell actor-name shape is checked by
[t/1164-isf-public-actor-shell-actor-name-shape-audit.t](../t/1164-isf-public-actor-shell-actor-name-shape-audit.t)
to keep parser-returned `actor_name` discoverable as the non-empty scalar
identifier preserved from the ISF actor root.
The actor-shell timing shape is checked by
[t/1165-isf-public-actor-shell-timing-shape-audit.t](../t/1165-isf-public-actor-shell-timing-shape-audit.t)
to keep parser-returned `clock`, `reset`, and `watchdog` timing fields
discoverable as bounded current handoff metadata.
The actor-shell rule shape is checked by
[t/1166-isf-public-actor-shell-rule-shape-audit.t](../t/1166-isf-public-actor-shell-rule-shape-audit.t)
to keep parser-returned rule entries discoverable as scalar `name`, optional
`when`, and `actions` array shells while leaving rule payload contents private
scheduler input.
The rule-action parser boundary is checked by
[t/1181-isf-rule-action-boundary.t](../t/1181-isf-rule-action-boundary.t)
so accepted rule actions have explicit `(port value)`,
`(trigger transaction)`, or `(priority over other_rule)` shapes before a rule
enters the actor shell. Expression-valued rule assignments remain deferred.
The factored rule-guard scheduled `.fsm` shape is checked by
[t/1168-isf-rule-guard-factoring.t](../t/1168-isf-rule-guard-factoring.t)
so rule actions remain grouped under one guard block in review artifacts.
The shorthand rule-guard parser/lowering path is checked by
[t/1169-isf-rule-shorthand-guard.t](../t/1169-isf-rule-shorthand-guard.t)
to keep `(rule name condition actions...)` normalized to the same public
`when` field as `(rule name (when condition) actions...)`.
The rule-trigger fan-in path is checked by
[t/1171-isf-rule-trigger-fanin.t](../t/1171-isf-rule-trigger-fanin.t)
so multiple rule triggers for one transaction preserve distinct trigger
sources before generated combinational fan-in.
The schedule-report projection of that same fan-in path is checked by
[t/1172-isf-rule-trigger-fanin-schedule-report.t](../t/1172-isf-rule-trigger-fanin-schedule-report.t)
so downstream consumers can rely on the advertised DT kind/order and one-bit
inferred-storage summaries for the generated trigger sources.
The explicit-width `shift_right` data-operation path is checked by
[t/1173-isf-shift-right-explicit-width.t](../t/1173-isf-shift-right-explicit-width.t)
so authors can avoid the placeholder width fallback when a shifted register is
not declared elsewhere.
The explicit-width `extract` data-operation path is checked by
[t/1174-isf-extract-explicit-widths.t](../t/1174-isf-extract-explicit-widths.t)
so authors can avoid placeholder slice bounds when extract field widths are
not declared elsewhere.
The temporal-contract lowering boundary is checked by
[t/1175-isf-contract-fail-closed.t](../t/1175-isf-contract-fail-closed.t)
so authored transaction `(contract ...)` clauses fail closed with a targeted
diagnostic until temporal assertion lowering is implemented.
The parser boundary for resource and priority metadata is checked by
[t/1176-isf-resource-priority-boundary.t](../t/1176-isf-resource-priority-boundary.t)
so malformed `(resources ...)`, actor-level `(priority lhs over rhs)`, and
rule-local `(priority over other_rule)` forms are rejected before an actor
shell is returned. Arbitration enforcement remains deferred.
The blocking `do` child-completion handoff is checked by
[t/1177-isf-do-child-done-pulse.t](../t/1177-isf-do-child-done-pulse.t)
so the generated internal `child_done` signal remains a one-cycle delayed pulse
through scheduled `.fsm` parsing and HDL generation.
The deprecated handshake compatibility boundary is checked by
[t/1178-isf-handshake-compatibility-boundary.t](../t/1178-isf-handshake-compatibility-boundary.t)
so `(handshake name (valid signal) (ready signal))` metadata is structurally
validated before being ignored. Old handshake semantics are still not lowered.
The phase/stage boundary is checked by
[t/1179-isf-phase-stage-boundary.t](../t/1179-isf-phase-stage-boundary.t)
so actor-level phase/stage metadata and transaction phase/stage clauses have
scalar names plus list-form body entries before an actor shell is returned.
Transaction `(phase ...)` remains a pass-through state marker; transaction
`(stage ...)` fails closed during lowering until valid/ready pipeline-stage
generation is implemented.
The unsupported transaction-clause boundary is checked by
[t/1180-isf-unsupported-transaction-clause-boundary.t](../t/1180-isf-unsupported-transaction-clause-boundary.t)
so removed or future transaction clause heads, including `(assign ...)`, fail
closed instead of disappearing from scheduled `.fsm` output. The nested
`when`, `switch`, and `repeat` body contexts use the same shipped-lowerer
boundary, while deferred `contract` and `stage` clauses keep their dedicated
diagnostics.
The actor-shell drive shape is checked by
[t/1167-isf-public-actor-shell-drive-shape-audit.t](../t/1167-isf-public-actor-shell-drive-shape-audit.t)
to keep parser-returned drive definitions discoverable as a drive-name-keyed
hash of `params` and `body` arrays while leaving drive body payload contents
private scheduler input.
ISF switch fallback scheduling is checked by
[t/1103-isf-switch-branch-exits.t](../t/1103-isf-switch-branch-exits.t)
and the generated `.fsm` default selector contract is checked by
[t/42-language-contract-test-selector-boundary.t](../t/42-language-contract-test-selector-boundary.t)
and [t/37-language-contract-computed-test-selector.t](../t/37-language-contract-computed-test-selector.t).
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

Supported ISF syntax remains a live surface. For `(switch signal ...)`, explicit
case values remain unique branch selectors, and one fallback branch may be
written as `(default body...)` or `(_ body...)`. Those fallback spellings are
aliases and are rejected if both appear in the same switch. When no authored
fallback branch is present, ISF lowering emits an implicit scheduled `.fsm`
`(default (-> next_state))` fallthrough branch. In the downstream `.fsm`
language, that default selector means the logical negation of the OR of every
explicit sibling branch predicate, so the fallback path is true only when no
explicit branch matched.

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
The current public parser handoff also advertises one bounded subshape inside
that shell: `interface` contains `inputs` and `outputs` arrays, and each public
port entry has scalar `name` plus positive integer `width`, with omitted source
widths normalized to `1`. The machine-readable contract advertises this through
`actor_shell_interface_shape`.
This is current live-contract metadata for scheduler-consumable parser output;
it does not make actor fields outside the advertised shell public or freeze
future ISF interface extensions before they are documented and audited.
The current public parser handoff also advertises a bounded transaction-entry
shell: `transactions` is an array of entries with scalar `name` and `clauses`
array fields. The machine-readable contract advertises this through
`actor_shell_transaction_shape`. The `clauses` array is a scheduler-consumable
container; its payload contents are intentionally not frozen as a public API by
this field.
The current public parser handoff also advertises the actor identity shell:
`actor_name` is a non-empty scalar actor identifier preserved from the ISF actor
root. The machine-readable contract advertises this through
`actor_shell_actor_name_shape`.
The current public parser handoff also advertises bounded actor timing fields:
`clock` is a non-empty scalar when configured, `reset` is null when omitted or a
hash with scalar `name`, `kind`, and `polarity`, and `watchdog` is null when
omitted or a positive integer. The machine-readable contract advertises this
through `actor_shell_timing_shape`.
The current public parser handoff also advertises a bounded rule-entry shell:
`rules` is an array of entries with scalar `name`, optional `when`, and
`actions` array fields. The machine-readable contract advertises this through
`actor_shell_rule_shape`. Rule condition/action payload contents remain private
scheduler input.
Authored `(rule name condition actions...)` shorthand and long-form
`(rule name (when condition) actions...)` normalize to the same public `when`
field. The current shorthand guard is scalar because scheduled rule guards are
still single port/signal conditions. Rule-local `(when condition)` is a
guard-only clause; it is not the transaction `(when condition body...)`
control-flow construct.
Current scheduled `.fsm` review artifacts emit a rule's `when` guard as one
factored DT guard block around that rule's lowered actions. This keeps the
generated text aligned with the source rule structure without widening the
actor-shell rule payload contract.
Within that scheduled `.fsm` review artifact, ordinary rule `(port value)`
actions remain guarded flopped assignments, while `(trigger transaction)`
actions use `<1` on a generated `rule_transaction` trigger source. A rule
trigger is therefore a one-cycle delayed pulse, not a sticky flopped request
bit.
Multiple rules may trigger the same transaction. The current scheduled `.fsm`
artifact exposes those triggers as distinct one-bit `rule_transaction` sources
and emits a generated combinational `transaction_trigger_fanin` DT for each
triggered transaction. The fan-in drives `transaction_start` from the OR of the
rule sources without adding latency, so downstream consumers can inspect
per-rule trigger provenance before the transaction start OR.
The current public parser handoff also advertises a bounded drive-definition
shell: `drives` is a hash of entries keyed by drive name, and each entry has
`params` and `body` arrays. The machine-readable contract advertises this
through `actor_shell_drive_shape`. Drive body payload contents remain private
scheduler input.
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
empty stderr, `--outdir DIR` writes scheduled `.fsm` files by basename into
`DIR`, and plain `file.isf` generation lowers through scheduled `.fsm` before
writing the requested HDL output with empty stderr.
The strict CLI success-shape field advertises that accepted `--strict
file.isf` generation follows the public HDL-generation success shape and keeps
stderr empty on success.

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
Each public `files` key is a scheduled `.fsm` basename with no directory
components. Each value is scheduled `.fsm` source text rooted at
`(?fsm:<basename-stem> ...)`.

The `--outdir` CLI path materializes the same scheduled `.fsm` basename/text
map on disk for multi-file lowerings.

The full lower-result hash is not yet a broad public API beyond the advertised
keys.
The `lower_result_presence_keys`, `lower_result_file_map_shape`,
`lower_result_file_name_shape`, and `lower_result_file_text_shape` fields are
exact lower-result discovery metadata for the currently public `files` map.

## DT Assignment Operators

Scheduled `.fsm` text can contain assignment operators in state DT blocks and
non-state DT blocks. The timing semantics are assignment-family driven, not
block-spelling driven:

- `=` is combinational.
- `<-` and `<=` are sequential/flopped.
- `<1` is a one-cycle delayed pulse.

A DT may therefore be combinational-only, sequential-only, or mixed depending on
the operators it contains. The machine-readable contract advertises these
families through `dt_assignment_operator_family_map`.

ISF `(complete port)` lowering uses `<1`, not `<-`, so completion outputs are
one-cycle delayed pulses rather than sticky flopped status bits. Drive phases
that precede completion should not also assign the same completion signal with
`<-`; the `.fsm` backend rejects mixed pulse-delayed and non-pulse sequential
operators on one LHS.
Blocking `(do child)` lowering also uses `<1` for the internal
`child_transaction_done` handoff generated in the rewired child terminal state.
That keeps each parent-visible child completion as a pulse, so repeated `do`
calls wait for fresh child completions instead of observing a sticky
already-done bit.
ISF rule `(trigger transaction)` lowering also uses `<1`, not `<-`, for the
generated `rule_transaction` trigger source. Generated combinational fan-in
then drives `transaction_start` from every source for that transaction. This
keeps rule-driven transaction starts pulse-shaped instead of leaving a sticky
start request active after the rule fires, while preserving per-rule trigger
provenance in the scheduled `.fsm` artifact.

ISF `(sample port as name)` lowering is a D-input contract: scheduled `.fsm`
artifacts use `<=`, not `<-`, so the authored sampled name denotes the
D-input/next-value side in the state where the sample appears. This preserves
same-state visibility for sample piggybacking, especially when a drive follows
the samples and its parameter wiring consumes a sampled alias in the same
scheduled state. Lowering samples with `<-` would instead make the alias denote
the previous Q/output value in that state and could require an extra state to
avoid stale data.

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
For each `dt_blocks` entry, `kind` is currently one of `drive`,
`latency_counter`, `rule`, or `rule_trigger_fanin`. The machine-readable
contract advertises this through `schedule_report_dt_kind_values`.

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
The `transactions` array itself is sorted lexically by transaction name. Each
entry's `states` array keeps scheduled `.fsm` state emission order for that
transaction. The machine-readable contract advertises this through
`schedule_report_transaction_ordering`.

For the `reset` summary, `kind` is currently `async` or `sync`, and `polarity`
is currently `active_high` or `active_low`. The machine-readable contract
advertises those value families through `schedule_report_reset_kind_values` and
`schedule_report_reset_polarity_values`.
When reset is configured, `reset` is a hash reference with
`schedule_report_reset_keys`. When reset is omitted, `reset` is null. The
machine-readable contract advertises this through `schedule_report_reset_shape`.

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
transaction/rule-created DTs retain their construction order, generated
rule-trigger fan-in DTs follow rule DTs by transaction name, and hash-backed
drive DTs are emitted lexically by drive name. This is a bounded
review-artifact and schedule-report stability promise, not a promise that raw
`LoweringIR` hashes are public. The machine-readable contract advertises the
same policy in `scheduled_fsm_dt_ordering` and `schedule_report_dt_ordering`.
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
