# ISF Public Interface Contract

This is the live downstream-consumer contract for the `.isf` intent-scheduling
surface.
The single self-contained human integration handoff for downstream producers
and consumers is
[docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md](ISF_DOWNSTREAM_INTEGRATION_SPEC.md).
That document must stay synchronized with this contract, the live `.isf` spec,
the mdBook, manifest metadata, regression tests, and implementation behavior.

It is intentionally a live document: any implementation slice that changes
supported ISF syntax, CLI behavior, public in-process facade behavior, scheduled
`.fsm` result shape, or schedule-report shape must update this file and the
downstream integration spec in the same commit.

This contract is not frozen. Exact audits in this document and in
`embedding.isf_public_interface` mean the current advertised surface is
discoverable and regression-backed; they do not prevent the ISF API from
evolving alongside FSMGen.

Parser acceptance is not sufficient to make an ISF construct public or
supported. A shipped construct must have an explicit accepted source shape,
fail-closed malformed-form diagnostics, a documented lowering path into
scheduled `.fsm` or an intentional diagnostic before emission, a runtime
semantic in terms of cycles/activation/storage/conflicts/completion, and
focused regression coverage. Constructs without that full chain remain deferred,
backlog, or validated compatibility input.

The intent-layer terminology used by the docs is also part of this live
contract: `.fsm` is Intent Abstraction Layer 0 (`IAL0`), the explicit
cycle-authored review artifact, and current `.isf` is Intent Abstraction Layer
1 (`IAL1`), the scheduling-intent layer that lowers to reviewable IAL0 `.fsm`.
No higher layer is currently shipped.

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
The compact SPI-like serial fixture is checked by
[t/1228-isf-spi-fixture-coverage.t](../t/1228-isf-spi-fixture-coverage.t)
to keep file-backed schedule JSON, scheduled `.fsm`, plain HDL generation,
strict HDL generation, explicit MOSI bit selection, and ISF shift handoff
covered without claiming full external SPI protocol compliance.
The compatibility CLI parity path is checked by
[t/1229-isf-compatibility-cli-parity.t](../t/1229-isf-compatibility-cli-parity.t)
so accepted ignored handshake compatibility source reaches CLI schedule JSON
and strict HDL, while removed transaction `(assign ...)` fails through the CLI
with migration guidance.
The first reusable-library import path is checked by
[t/1230-isf-library-import-resolution.t](../t/1230-isf-library-import-resolution.t)
so file-backed `(imports ...)` / `(use ...)` source resolves exported library
actors, validates use-site parameter and binding errors, emits specialized
child scheduled `.fsm` artifacts, and reports bounded `library_uses`
provenance.
Generated top wiring for resolved library actor instances is checked by
[t/1231-isf-library-generated-top.t](../t/1231-isf-library-generated-top.t)
so a library actor wrapper reaches CLI `--outdir`, generated top `.fsm`, and
SystemVerilog output through the normal composition path, including explicit
generated-top links when a library actor uses different clock/reset names than
the importing actor. Those links are name remaps inside the current
single-clock-domain ISF model; they do not advertise CDC or interacting
clock-domain semantics.
The current APB schedule report is checked against the advertised key families
by [t/1116-isf-public-schedule-report-key-family-audit.t](../t/1116-isf-public-schedule-report-key-family-audit.t).
The shipped stage/contract report projection is checked by
[t/1225-isf-stage-contract-schedule-report.t](../t/1225-isf-stage-contract-schedule-report.t).
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
views and aligned with APB, full-featured, and temporal-contract reports.
Stage and contract schedule-report key/value families are audited across
direct and manifest views and checked against generated JSON.
The inferred-storage metadata is checked by
[t/1148-isf-public-storage-metadata-audit.t](../t/1148-isf-public-storage-metadata-audit.t)
to keep advertised storage `kind` values, optional `role` values, and optional
`width` shape exact across direct and manifest views. Data-operation storage
roles and widths are checked by
[t/1226-isf-data-width-storage-report.t](../t/1226-isf-data-width-storage-report.t)
for sampled aliases, extracted fields, assembled targets, explicit-width
shift registers, and completion pulses.
Actor-owned fixed storage declarations are checked by
[t/1232-isf-actor-storage-declarations.t](../t/1232-isf-actor-storage-declarations.t)
for parser shape, authored `(var ...)` / `(variable ...)` scalar storage
forms, scalarized bank lowering, `actor_storage` report metadata, fail-closed
diagnostics, and SystemVerilog generation for used storage.
Rule expression guards are checked by
[t/1233-isf-rule-expression-guards.t](../t/1233-isf-rule-expression-guards.t)
for shorthand and long-form guard normalization, scheduled `.fsm` DT-DTE
emission, HDL generation, and targeted parser diagnostics.
The depth-4 FIFO controller matrix is checked by
[t/1235-isf-fifo-same-cycle-update-matrix.t](../t/1235-isf-fifo-same-cycle-update-matrix.t)
for the real controller interface, actor-maintained full/empty flags,
pointer/occupancy state updates, equality-based disjoint-rule proof, scheduled
`.fsm`, schedule report, and SystemVerilog reachability without inventing a
FIFO data-bank datapath.
Actor-owned bank access is checked by
[t/1236-isf-bank-access-lowering.t](../t/1236-isf-bank-access-lowering.t)
for `(store <bank-name> <index> <value>)` and
`(load <bank-name> <index> as <target>)` parsing,
scalarized guarded lowering, bounded `bank_accesses` report metadata,
fail-closed diagnostics, and depth-4 FIFO data-path HDL reachability.
The fixed-shape reusable FIFO library fixture is checked by
[t/1237-isf-fifo-library-fixture.t](../t/1237-isf-fifo-library-fixture.t)
for file-backed import of [isf/common/fifo.isf](../isf/common/fifo.isf),
specialized child scheduled `.fsm` emission, generated top wiring, fixed
parameter provenance, same-cycle full push/pop case visibility, bank-backed
accepted push/pop artifacts, and `library_uses` report metadata.
Generated-top SystemVerilog for that FIFO fixture is checked by
[t/1238-isf-fifo-library-hdl-generation.t](../t/1238-isf-fifo-library-hdl-generation.t)
for FIFO child parameter bindings, scalarized data entries, pointer-gated
accepted push/pop selectors, and AST factorization preserving distinct
`CoreAST` signal identities.
The reusable-library catalog contract is checked by
[t/1239-isf-library-catalog-contract.t](../t/1239-isf-library-catalog-contract.t)
so the machine-readable public contract advertises
[docs/ISF_LIBRARY_CATALOG.md](ISF_LIBRARY_CATALOG.md), the shipped catalog
entry key family, and the current shipped reusable definition list.
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
The explicit schedule-report freeze boundary is checked by
[t/1227-isf-schedule-report-freeze-boundary.t](../t/1227-isf-schedule-report-freeze-boundary.t)
so the contract stays bounded-public, does not claim whole-schema stability,
and keeps the presence-family map scoped to key families.
The successful `compile_issues` report shape is checked by
[t/1130-isf-public-compile-issues-success-audit.t](../t/1130-isf-public-compile-issues-success-audit.t)
for both in-process and CLI report paths.
The nonfatal `compile_issues` projection is checked by
[t/1212-isf-schedule-report-compile-issues-projection.t](../t/1212-isf-schedule-report-compile-issues-projection.t)
for both in-process and CLI report paths.
The compatible fan-in projection is checked by
[t/1213-isf-schedule-report-compatible-fanin-projection.t](../t/1213-isf-schedule-report-compatible-fanin-projection.t)
for both in-process and CLI report paths.
Rejected conflict diagnostics are checked by
[t/1214-isf-rejected-conflict-diagnostics.t](../t/1214-isf-rejected-conflict-diagnostics.t)
for both in-process scheduler calls and the CLI schedule-report path.
Generated composition-top lowering is checked by
[t/1216-isf-generated-composition-top.t](../t/1216-isf-generated-composition-top.t),
including contextual diagnostics for generated handoff port-name conflicts.
The accepted generated-composition report projection is a top-level
`generated_composition` field and is checked by
[t/1217-isf-generated-composition-schedule-report.t](../t/1217-isf-generated-composition-schedule-report.t).
Non-generated-top reports use JSON null, while generated-child reports use a
bounded object with `kind`, `top_module`, `top_fsm`, `parent`, `children`, and
`instances`. The `kind` value is `spawn_generated_top` for spawn-only generated
tops and `activation_generated_top` when another activation kind such as
blocking `do` or parameterized rule `trigger` participates. Parent entries expose `module` and
`scheduled_fsm`; child entries expose `transaction`, `module`, `scheduled_fsm`,
and `parameters`; instance entries expose `instance`, `child`,
`activation_kind`, `start`, `done`, `parameter_bindings`, and
`drive_handoffs`. Parameter binding entries expose `name`, `source`, and
stringified `value`; drive handoff entries expose `drive`, `request`, and
`payloads`, with each payload naming the drive `parameter`, child/parent ports,
and `width`. This projection must stay a bounded live review/discovery summary,
not a raw LoweringIR or `?wiring` dump.
Reusable library actor uses are reported through a top-level `library_uses`
array. Each entry exposes the bounded identity of the resolved use
(`library`, `alias`, `export`, `kind`, `instance`), generated artifact names
(`module`, `scheduled_fsm`), parameter summaries, and explicit binding
summaries. Parameter entries expose `name`, `source` (`default` or
`override`), and stringified `value`. Binding entries expose `role`,
`library_name`, `parent_name`, and `width`; clock/reset bindings use JSON null
for `library_name`, and width is `1`. Raw library resolver state, raw exported
actor hashes, and generated top planning details remain non-public.
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
The multi-domain clock-domain report projection and event-crossing fixture are
checked by [t/1247-isf-clock-domain-partition.t](../t/1247-isf-clock-domain-partition.t).
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
The interface-port boundary is checked by
[t/1188-isf-interface-port-boundary.t](../t/1188-isf-interface-port-boundary.t)
so port names are unique across both input and output directions before an
actor shell is returned.
The actor-shell transaction subshape is checked by
[t/1163-isf-public-actor-shell-transaction-shape-audit.t](../t/1163-isf-public-actor-shell-transaction-shape-audit.t)
to keep parser-returned transaction entries discoverable as unique non-empty
scalar `name`, a `ports` hash with `inputs`/`outputs` arrays, and a `clauses`
array shell while leaving the clause payload contents private scheduler input.
The transaction-port declaration boundary is checked by
[t/1240-isf-transaction-port-declarations.t](../t/1240-isf-transaction-port-declarations.t)
so parser-accepted `(ports ...)` clauses normalize to directional
`name`/`width` entries and malformed direction, duplicate, width, or option
forms fail before scheduler lowering.
The first activation-binding lowering boundary is checked by
[t/1241-isf-transaction-port-bindings.t](../t/1241-isf-transaction-port-bindings.t)
so `do`, `spawn`, and rule-trigger input bindings accept scalar signals,
numeric/exact-width literals, and non-empty list expressions where shipped,
are direction- and known-width-checked, keep actor inputs read-only, reject
actor output readback, produce hidden generated-top handoffs for spawned
bindings, avoid duplicate same-name child wiring for explicit spawn binding
sources, and use per-rule source signals before trigger fan-in.
The actor-pin binding conflict boundary is checked by
[t/1242-isf-port-binding-conflict-semantics.t](../t/1242-isf-port-binding-conflict-semantics.t)
so spawned output bindings keep parent-transaction ownership in assignment
provenance, conflicting rule writes fail through the existing
rule/transaction conflict path, and accepted spawn or rule-trigger binding
fan-in reaches the backend's verification-only selector instrumentation.
The transaction-port binding schedule-report projection is checked by
[t/1243-isf-port-binding-schedule-report.t](../t/1243-isf-port-binding-schedule-report.t)
so successful in-process and CLI reports expose bounded binding provenance
without exporting raw `LoweringIR` assignment internals.
The transaction wait boundary is checked by
[t/1244-isf-wait-clause-lowering.t](../t/1244-isf-wait-clause-lowering.t)
so `(wait N)` accepts non-negative integer literals and actor constants in
transaction body contexts, lowers positive resolved counts to reviewable fixed
wait-state chains, treats resolved zero as a transparent no-op, accepts the
known-width runtime scalar and runtime expression count subsets including
consecutive top-level runtime waits and waits after shipped `await`, `stage`,
`repeat` exit, `await_all`, `await_any`, and loop-decision predecessors,
reaches HDL generation, exposes `actor_constants[]` and
`transaction_waits[]` provenance, and rejects malformed, unknown,
parameter-backed, unknown-width expression, or unsupported dynamic counts.
Inline `when`, `repeat`, `switch`, `while`, and
`until` body dynamic waits are covered for the no-pending-sample subset. Branch
and loop decision states preserve their alternate exits while splitting the
selected dynamic-wait edge into positive-count load/entry and zero-count
bypass paths. Pending samples before top-level runtime waits are covered: the
positive path materializes samples in the first wait state, counts greater
than one continue through a no-resample wait-loop state, and the zero path uses
a sample-preserving clone of the following state when that state can carry the
sample without changing timing. Top-level zero-count successors that cannot
yet carry pending samples fail closed. Pending samples before `when`-body and
`switch`-branch runtime waits are now covered by the same one-shot positive
sample and zero-clone contract when the selected successor can carry samples.
Pending samples before `repeat`, `while`, and `until` dynamic waits are covered
by the same contract for sample-compatible body successors while preserving
loop-back and loop-exit edges. Dynamic waits whose selected zero-count
successor cannot yet carry samples fail closed with diagnostics that name the
body context.
The transaction loop boundary is checked by
[t/1245-isf-transaction-loop-lowering.t](../t/1245-isf-transaction-loop-lowering.t)
so top-level transaction `(while cond body...)` lowers as a pre-test
zero-or-more loop, `(until cond body...)` lowers as a body-first one-or-more
loop, conditions are sampled in generated decision states, successful reports
expose `transaction_loops[]`, and unsupported loop body combinations fail
closed.
The transaction-name boundary is checked by
[t/1185-isf-transaction-name-boundary.t](../t/1185-isf-transaction-name-boundary.t)
so duplicate transaction names fail before actor-shell return and downstream
target-resolution code sees one unambiguous same-actor transaction namespace.
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
to keep parser-returned rule entries discoverable as unique non-empty scalar
`name`, optional `when`, and `actions` array shells while leaving rule payload
contents private scheduler input.
The rule-name boundary is checked by
[t/1186-isf-rule-name-boundary.t](../t/1186-isf-rule-name-boundary.t)
so duplicate rule names fail before actor-shell return and generated rule DTs
plus rule-trigger source prefixes remain unambiguous.
The rule-action parser boundary is checked by
[t/1181-isf-rule-action-boundary.t](../t/1181-isf-rule-action-boundary.t)
so accepted rule actions have explicit `(set port expr)`, `(port expr)`,
`(trigger transaction)`, or `(priority over other_rule)` shapes before a rule
enters the actor shell. Assignment RHS values may be scalar tokens or
non-empty list expressions with scalar expression heads.
The scalar setter syntax boundary is checked by
[t/1246-isf-setter-syntax.t](../t/1246-isf-setter-syntax.t)
so `(set lhs expr)` is accepted in rule and transaction contexts, malformed
setter forms fail closed with targeted diagnostics, rule setters lower as
guarded flopped rule assignments, and transaction setters lower as ordered
flopped transaction states that reach HDL generation.
The rule-expression assignment lowering path is checked by
[t/1221-isf-rule-expression-assignment.t](../t/1221-isf-rule-expression-assignment.t)
so expression-valued rule assignments preserve through scheduled `.fsm`
emission, assignment provenance, normal `.fsm` frontend parsing, and HDL
generation while keeping the existing flopped `<-` rule assignment family.
The expression-valued rule conflict/report path is checked by
[t/1222-isf-rule-expression-conflict-report.t](../t/1222-isf-rule-expression-conflict-report.t)
so same-expression rule writes appear as compatible fan-in, different
expression writes fail closed through `isf_conflicting_rule_writes`, and
priority-resolved expression conflicts project through `priority_resolutions`.
The disjoint-rule write path is checked by
[t/1234-isf-disjoint-rule-writes.t](../t/1234-isf-disjoint-rule-writes.t)
so same-target FIFO-style rule writes are accepted when direct contradictory
guard literals prove the rules cannot fire in the same cycle, while
overlapping expression guards still fail closed through
`isf_conflicting_rule_writes`.
The rule-trigger target boundary is checked by
[t/1182-isf-rule-trigger-target-boundary.t](../t/1182-isf-rule-trigger-target-boundary.t)
so `(trigger transaction)` must name a declared transaction in the same actor.
Forward references are accepted because validation runs after the full actor
body is collected; missing targets fail before actor-shell return.
The rule-guard scheduled `.fsm` DTE-header shape is checked by
[t/1168-isf-rule-guard-factoring.t](../t/1168-isf-rule-guard-factoring.t)
so rule actions remain grouped under one guarded non-state DT enable in review
artifacts.
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
The static rule-conflict path is checked by
[t/1209-isf-static-conflict-detection.t](../t/1209-isf-static-conflict-detection.t)
so provable incompatible rule/rule data writes fail closed, compatible
same-value rule writes remain accepted, rule/drive overlap is flagged
internally as `proof_status => not_doable`, and ordinary transaction state
mux behavior remains accepted.
The rule-priority conflict-resolution path is checked by
[t/1210-isf-priority-conflict-resolution.t](../t/1210-isf-priority-conflict-resolution.t)
so rule-local and actor-level rule priorities can suppress lower-priority
same-target rule assignments, while priority cycles fail closed.
The verification-only runtime selector instrumentation path is checked by
[t/1211-isf-runtime-selector-conflict-instrumentation.t](../t/1211-isf-runtime-selector-conflict-instrumentation.t)
so same-value source selector checks, whole-mux value selector checks, and the
Verilog no-assertion boundary remain regression-backed after ISF lowers through
scheduled `.fsm` into HDL.
The explicit-width `shift_right` data-operation path is checked by
[t/1173-isf-shift-right-explicit-width.t](../t/1173-isf-shift-right-explicit-width.t)
so explicit `(width N)` fills otherwise missing register-width evidence,
known-width shifts do not need the option, conflicting explicit widths fail
closed, and accepted `shift_right` source no longer emits placeholder `WIDTH`
terms.
The explicit-width `extract` data-operation path is checked by
[t/1174-isf-extract-explicit-widths.t](../t/1174-isf-extract-explicit-widths.t)
so authors can avoid placeholder slice bounds when extract field widths are
not declared elsewhere.
The temporal-contract lowering boundary is checked by
[t/1175-isf-contract-fail-closed.t](../t/1175-isf-contract-fail-closed.t)
and [t/1224-isf-contract-lowering.t](../t/1224-isf-contract-lowering.t).
The shipped subset is the top-level transaction form
`(contract name (eventually signal (within cycles)))`. It lowers to one arm
state plus an always-on monitor DT with pending, age, and sticky-fail storage.
Schedule reports classify that DT as `temporal_contract_monitor` and classify
the generated pending/fail storage as registers and age storage as a counter.
The bounded `temporal_contracts` summary projection reports the public trigger,
observed signal, cycle bound, generated storage names, reset policy, overlap
policy, and assertion projection status for downstream consumers.
Unsupported top-level bodies and nested contracts still fail closed with
targeted diagnostics. Verification-only assertion text is not advertised yet.
The parser boundary for resource and priority metadata is checked by
[t/1176-isf-resource-priority-boundary.t](../t/1176-isf-resource-priority-boundary.t)
so malformed `(resources ...)`, actor-level `(priority lhs over rhs)`, and
rule-local `(priority over other_rule)` forms are rejected before an actor
shell is returned. Current parser metadata carries resource names, arbiter
strings, and optional resource-kind/user metadata. A resource name is the
author-defined instance handle; the resource kind is the public registry entry
that says what type of shareable thing the instance represents. The first
enforced resource kind is `rule_slot`, a one-cycle mutual-exclusion slot for
rule users under the `priority` arbiter. The current shareable resource
registry is:
`rule_slot` (shipped for `priority` arbitration), `output_bundle`,
`interface_bundle`, `named_drive`, `transaction_start`, `child_instance`, and
`storage_port`. The non-`rule_slot` kinds are public catalog/backlog names,
not public runtime behavior, until their lowering paths, runtime semantics,
diagnostics, report surfaces, and regressions ship. The accepted `round_robin`
string remains parser metadata until round-robin lowering ships.
The code owner for that registry is `FSM::Support::ISFResourceCatalog`; the
parser and this public contract both consume it. Downstream consumers can
discover the current values through `resource_arbiter_values`,
`resource_kind_values`, `resource_kind_status_map`,
`resource_kind_meaning_map`, `enforced_resource_kind_values`, and
`backlog_resource_kind_values` on `embedding.isf_public_interface`.
The first resource-arbitration path is checked by
[t/1218-isf-rule-slot-resource-arbitration.t](../t/1218-isf-rule-slot-resource-arbitration.t)
for parser metadata, scheduled `.fsm` DTE gating, HDL handoff, and
fail-closed unsupported arbitration cases.
The first rule/transaction priority path is checked by
[t/1219-isf-rule-transaction-priority.t](../t/1219-isf-rule-transaction-priority.t)
for accepted rule-over-transaction suppression, unordered conflict rejection,
cycle rejection, and transaction-over-rule fail-closed diagnostics.
The arbitration schedule-report projection is checked by
[t/1220-isf-arbitration-schedule-report.t](../t/1220-isf-arbitration-schedule-report.t)
for bounded successful `priority_resolutions` and `resource_arbitration`
entries across the in-process scheduler and CLI JSON path.
The rule-local priority target boundary is checked by
[t/1190-isf-rule-priority-target-boundary.t](../t/1190-isf-rule-priority-target-boundary.t)
so `other_rule` in `(priority over other_rule)` must resolve to a declared
same-actor rule before actor-shell return. Forward references remain accepted.
The actor-level priority target boundary is checked by
[t/1191-isf-actor-priority-target-boundary.t](../t/1191-isf-actor-priority-target-boundary.t)
so both sides of `(priority lhs over rhs)` must resolve to declared same-actor
transactions or rules before actor-shell return. Forward references remain
accepted.
The singleton actor-clause boundary is checked by
[t/1192-isf-singleton-actor-clause-boundary.t](../t/1192-isf-singleton-actor-clause-boundary.t)
so `(clock ...)`, `(reset ...)`, `(watchdog ...)`, `(interface ...)`, and
`(resources ...)`, and `(storage ...)` fail closed when repeated instead of
letting later clauses overwrite earlier public actor-shell fields.
The blocking `do` child-completion handoff is checked by
[t/1177-isf-do-child-done-pulse.t](../t/1177-isf-do-child-done-pulse.t)
so the generated internal `child_done` signal remains a one-cycle delayed pulse
through scheduled `.fsm` parsing and HDL generation.
The child transaction target boundary is checked by
[t/1184-isf-child-transaction-target-boundary.t](../t/1184-isf-child-transaction-target-boundary.t)
so `(do child ...)` and `(spawn child as instance ...)` must resolve `child`
to a declared same-actor transaction before scheduled `.fsm` emission, while
forward references remain accepted. Parameterized/generated `do` uses a
generated child activation instance; local unparameterized `do` keeps the
rewired child-completion pulse path.
The deprecated handshake compatibility boundary is checked by
[t/1178-isf-handshake-compatibility-boundary.t](../t/1178-isf-handshake-compatibility-boundary.t)
so `(handshake name (valid signal) (ready signal))` metadata requires exactly
one scalar `valid` and one scalar `ready`, rejects duplicate handshake names,
and remains ignored after validation. Old handshake semantics are still not
lowered.
The phase/stage boundary is checked by
[t/1179-isf-phase-stage-boundary.t](../t/1179-isf-phase-stage-boundary.t)
so actor-level phase/stage metadata and transaction phase/stage clauses have
scalar names plus list-form body entries before an actor shell is returned.
Transaction `(phase ...)` remains a pass-through state marker; transaction
`(stage name (input ready_signal) (output valid_signal))` has its first
bounded lowering path checked by
[t/1223-isf-stage-lowering.t](../t/1223-isf-stage-lowering.t): it emits one
ready-gated state that drives `valid_signal = 1` while active, parses through
the normal `.fsm` frontend, and reaches SystemVerilog generation. Actor-level
phase/stage metadata is parser-carried only today and is not copied into
`LoweringIR`, schedule JSON, generated `.fsm`, generated composition tops, or
HDL.
The unsupported transaction-clause boundary is checked by
[t/1180-isf-unsupported-transaction-clause-boundary.t](../t/1180-isf-unsupported-transaction-clause-boundary.t)
so removed or future transaction clause heads, including `(assign ...)`, fail
closed instead of disappearing from scheduled `.fsm` output. Removed
`(assign ...)` has targeted migration guidance, while unknown future keywords
keep the generic unsupported-clause diagnostic. The nested `when`, `switch`,
and `repeat` body contexts use the same shipped-lowerer boundary, while
unsupported `contract` clauses and deferred nested/unsupported `stage` forms
keep their dedicated diagnostics. The shipped top-level
bounded-eventual `contract` subset is covered separately by
[t/1224-isf-contract-lowering.t](../t/1224-isf-contract-lowering.t).
The actor-shell drive shape is checked by
[t/1167-isf-public-actor-shell-drive-shape-audit.t](../t/1167-isf-public-actor-shell-drive-shape-audit.t)
to keep parser-returned drive definitions discoverable as a unique
drive-name-keyed hash of `params` and `body` arrays with body entries
validated as scalar `(port value)` pairs while leaving richer drive semantics
private scheduler input.
The drive-name boundary is checked by
[t/1187-isf-drive-name-boundary.t](../t/1187-isf-drive-name-boundary.t)
so duplicate drive definitions fail before actor-shell return instead of
silently overwriting an earlier drive body in the parser handoff.
The drive-body boundary is checked by
[t/1194-isf-drive-body-boundary.t](../t/1194-isf-drive-body-boundary.t)
so malformed body entries fail before actor-shell return instead of being
skipped during drive-DT construction or stringified as unsupported payloads.
The drive-call arity boundary is checked by
[t/1193-isf-drive-call-arity-boundary.t](../t/1193-isf-drive-call-arity-boundary.t)
so known drive calls require exactly one actual value per declared formal
parameter. Missing actuals and extra actuals fail during lowering instead of
emitting unbound parameter signals or ignoring author-provided values.
The sample-clause boundary is checked by
[t/1195-isf-sample-clause-boundary.t](../t/1195-isf-sample-clause-boundary.t)
so standalone samples and `(on ...)` inline samples must use exactly
`(sample port as name)` with scalar names. Unsupported `(on ...)` body forms
fail closed instead of being ignored. Direct `(on ...)` activation is not a
parameter-override site; `(on start (params ...))` stays outside the public
syntax and must fail closed like any other unsupported entry-body form.
The complete-clause boundary is checked by
[t/1196-isf-complete-clause-boundary.t](../t/1196-isf-complete-clause-boundary.t)
so `(complete port)` must name exactly one scalar completion target before
scheduled `.fsm` emission.
The latency-clause boundary is checked by
[t/1197-isf-latency-clause-boundary.t](../t/1197-isf-latency-clause-boundary.t)
so `(latency ...)` accepts only positive-integer `(min N)` and `(max N)`
options, rejects duplicates, requires `min <= max` when both are present, and
uses valid explicit `max` bounds for the generated counter width/max check.
The update-clause boundary is checked by
[t/1198-isf-update-clause-boundary.t](../t/1198-isf-update-clause-boundary.t)
so `(update var expr)` has exactly one scalar target and one scalar or list
expression payload, and nested expression payloads are formatted as `.fsm`
expressions instead of Perl reference strings.
The shift-clause boundary is checked by
[t/1199-isf-shift-clause-boundary.t](../t/1199-isf-shift-clause-boundary.t)
so `(shift_left reg bit)` and `(shift_right reg bit [(width N)])` require
scalar register/bit operands before scheduled `.fsm` emission.
The assemble-clause boundary is checked by
[t/1200-isf-assemble-clause-boundary.t](../t/1200-isf-assemble-clause-boundary.t)
so `(assemble part... as target)` requires one or more scalar parts and one
scalar target before scheduled `.fsm` emission. The same regression covers the
width-evidence boundary: when all part widths are known, the derived sum must
match any already-known target width.
The extract-clause boundary is checked by
[t/1201-isf-extract-clause-boundary.t](../t/1201-isf-extract-clause-boundary.t)
so `(extract word as field... [(widths N...)])` requires one scalar source
word, one or more scalar fields, and at most one ordered positive-integer
`(widths N...)` option before scheduled `.fsm` emission.
The exact-slice extraction behavior is checked by
[t/1101-isf-extract-slices.t](../t/1101-isf-extract-slices.t), so accepted
`extract` source emits concrete descending slices and fails closed for unknown
field widths or known source/field width disagreement instead of emitting
placeholder slice bounds.
The repeat-clause boundary is checked by
[t/1202-isf-repeat-clause-boundary.t](../t/1202-isf-repeat-clause-boundary.t)
so `(repeat count body...)` requires one scalar non-empty count and at least
one list-form body clause before repeat counter emission.
The count is a runtime counter load value, not a hardware-elaboration count:
literal counts provide fixed loop bounds, while named scalar counts may be
dynamic when their width is known. Dynamic counts make latency data-dependent
and require explicit zero-count and verification-bound policy before the
repeat surface is widened further.
The await-sync clause boundary is checked by
[t/1203-isf-await-sync-clause-boundary.t](../t/1203-isf-await-sync-clause-boundary.t)
so `(await_all done_port)` and `(await_any done_port)` require exactly one
scalar done-port operand before sync-state emission.
The child-composition clause boundary is checked by
[t/1204-isf-child-composition-clause-boundary.t](../t/1204-isf-child-composition-clause-boundary.t)
so `(do transaction [(params (NAME value) ...)] [(bind ...)])` and
`(spawn transaction as instance [(params (NAME value) ...)] [(bind ...)])`
require exact scalar child/instance operands before child-target resolution or
generated-child collection.
Spawn and blocking `do` parameter binding are checked by
[t/1215-isf-spawn-parameter-binding.t](../t/1215-isf-spawn-parameter-binding.t).
Rule-trigger parameter binding is checked by
[t/1248-isf-rule-trigger-parameter-binding.t](../t/1248-isf-rule-trigger-parameter-binding.t).
Actor constants as activation parameter override values are checked by
[t/1249-isf-activation-parameter-constants.t](../t/1249-isf-activation-parameter-constants.t).
Generated composition-top wiring for generated child activations is checked by
[t/1216-isf-generated-composition-top.t](../t/1216-isf-generated-composition-top.t).
The shipped surface preserves validated per-instance spawn and generated `do`
overrides plus parameterized rule-trigger overrides in lowerer metadata, emits
child transaction defaults into generated child scheduled `.fsm` `+params`
blocks, resolves actor-local constants in activation parameter override values,
rejects duplicate instances, duplicate parameters, unknown overrides,
unsupported non-constant symbolic or expression values, and aggregate shape
mismatches, and rejects parameter declarations on non-generated transactions.
Generated composition-top links use the canonical Lisp-ish `?wiring` list
spelling, for example `(parent.instance_start instance.start)`, rather than
the older slash-token compatibility spelling.
The switch-clause boundary is checked by
[t/1205-isf-switch-clause-boundary.t](../t/1205-isf-switch-clause-boundary.t)
so `(switch signal (value body...)...)` requires one scalar signal, one or more
list-form branches, and scalar branch values before branch expansion.
The when-clause boundary is checked by
[t/1206-isf-when-clause-boundary.t](../t/1206-isf-when-clause-boundary.t)
so `(when condition body...)` requires one scalar or list-form condition and at
least one list-form body clause before branch expansion.
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
`parse_file(...)` resolves external library files from the importing source
directory, `FSMLIB`, and the current directory, checking both dotted and
path-like file names such as `common.pulse.isf` and `common/pulse.isf`.
`parse_source(...)` can resolve same-source library roots; general external
resolution requires a real source path, so file-backed library use should call
`parse_file(...)`. Resolved library actor instances emit a generated top when
lowered for HDL: bound library inputs/outputs link directly between top ports
and the library child instance. Same-name clock/reset bindings use the existing
composition system-port auto-wiring path. Differently named clock/reset
bindings emit explicit generated-top `?wiring` list links such as
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
artifact satisfies the current scheduled `.fsm` clock/reset HDL contract.
The current shipped reusable library catalog contains `common.fifo.fifo` with
source [isf/common/fifo.isf](../isf/common/fifo.isf), import fixture
[isf/fifo_library_use.isf](../isf/fifo_library_use.isf), fixed parameters
`DATA_WIDTH=8`, `DEPTH=4`, `PTR_WIDTH=2`, and `OCC_WIDTH=3`, the public FIFO
interface, actor-owned storage, runtime semantics, tests, and limitations.
The same information is mirrored in `shipped_library_definitions` for
machine-readable discovery.

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
optional array reference when present. The shipped storage entries are
fixed-width scalar declarations authored with preferred `(var ...)`,
verbose `(variable ...)`, plus fixed-depth `bank` declarations whose
scalarized element names are scheduler input.
Schedule reports still use coarse `kind: register` for generated storage
class; that report value is not the source vocabulary.
Actor roots may also carry parser-validated actor-local constants through a
singleton `(constants ...)` clause. That field is not a required actor shell
key, but the advertised value-shape string records that `constants` is an
optional array reference when present.
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
the read-before-write same-cycle policy.
`store` is bank-entry-only public syntax. Scalar storage updates remain the
ordinary rule assignment and transaction `update` surfaces.
The current public parser handoff also advertises one bounded subshape inside
that shell: `interface` contains `inputs` and `outputs` arrays, and each public
port entry has unique non-empty scalar `name` plus positive integer `width`,
with omitted source widths normalized to `1`. Accepted clock-domain sources may
carry scalar `domain` ownership metadata on those port entries. The
machine-readable contract advertises this through
`actor_shell_interface_shape`.
This is current live-contract metadata for scheduler-consumable parser output;
it does not make actor fields outside the advertised shell public or freeze
future ISF interface extensions before they are documented and audited.
The current public parser handoff also advertises a bounded transaction-entry
shell: `transactions` is an array of entries with unique non-empty scalar
`name`, `clauses` array fields, and optional scalar `domain` ownership
metadata. The machine-readable contract advertises this through
`actor_shell_transaction_shape`. The `clauses` array is a scheduler-consumable
container; its payload contents are intentionally not frozen as a public API by
this field.
The current public parser handoff also advertises the actor identity shell:
`actor_name` is a non-empty scalar actor identifier preserved from the ISF actor
root. The machine-readable contract advertises this through
`actor_shell_actor_name_shape`.
The current public parser handoff also advertises bounded actor timing fields:
`clock` is a non-empty scalar when configured and is the default-domain clock
when `clock_domains` is present, `reset` is null when omitted or a hash with
scalar `name`, `kind`, and `polarity` for the default domain, and `watchdog` is
null when omitted or a positive integer. Public multi-domain `lower(...)`
emits domain-specific scheduled `.fsm` artifacts plus a generated multi-domain
top, and public `report(...)` exposes bounded domain and crossing report
metadata. The machine-readable contract advertises this through
`actor_shell_timing_shape`.
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
FIFO fire predicates and pointer/occupancy matrix cases. Rule/drive
same-target overlap is marked internally because
compile-time proof is not doable in that case. Nonfatal rule/drive overlap is
now projected into successful schedule-report `compile_issues`; reports with
no nonfatal issues still keep that array empty.
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
Unordered rule/transaction conflicts, priority cycles, mixed timing operators,
and transaction-over-rule priority all fail closed.
Transaction-over-rule is not lowered yet because scheduled `.fsm` review text
does not expose a state-active predicate that can safely guard a non-state
rule DT assignment.
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
[t/1189-isf-drive-parameter-boundary.t](../t/1189-isf-drive-parameter-boundary.t)
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
generated multi-domain top and the concrete acknowledged-event CDC child when
each emitted domain artifact satisfies the current scheduled `.fsm`
clock/reset HDL contract.
`--emit-schedule-json` succeeds for accepted multi-domain actors.
The strict CLI success-shape field advertises that accepted `--strict
file.isf` generation follows the public HDL-generation success shape and keeps
stderr empty on success.

## Lower Result

`FSM::Scheduler::ISF->lower($actor)` returns a hash with the advertised top-level
key:

```text
files
```

`files` is a hash reference mapping `.fsm` basenames to scheduled module,
multi-domain domain scheduled module, specialized library-child module,
generated multi-domain top, or generated composition-top `.fsm` source text.
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
completion returns that instance to start-gated idle. Future spawn-in-repeat
support must reuse the same lexical instance on each iteration and must reject
or sequence starts that could hit a still-busy child.
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
actor_constants
port_count
inputs
outputs
state_count
inferred_storage
transactions
transaction_waits
transaction_loops
transaction_stages
temporal_contracts
bank_accesses
transaction_port_bindings
dt_blocks
generated_composition
library_uses
compatible_fanin_groups
priority_resolutions
resource_arbitration
compile_issues
clock_domains
crossings
```

Current bounded nested and array summary families:

```text
reset: name, kind, polarity
actor_constants entries: name, value
inferred_storage entries: name, kind, optional role, optional width
transactions entries: name, states, count
transaction_waits entries: transaction, cycles, count_kind, count_source, entry_state, exit_state, counter_signal, counter_width
transaction_waits count_kind values: static, runtime_scalar, runtime_expression
transaction_loops entries: transaction, kind, condition, entry_state, decision_states, body_start, body_states, exit_state, body_clause_count
transaction_stages entries: transaction, name, kind, state, ready, valid
temporal_contracts entries: transaction, name, kind, trigger, signal, within_cycles, pending_signal, counter_signal, fail_signal, overlap_policy, reset_policy, assertion_projection
dt_blocks entries: name, kind, assignments
compile_issues entries: code, severity, target, domain, proof_status, reason, sources
compile_issues source entries: owner, owner_kind, source_kind, target, operator, rhs, domain
compile_issues with no nonfatal issues: empty array
compatible_fanin_groups entries: kind, domain, sources, optional target/value keys
compatible_fanin_groups source entries: same bounded source keys as compile_issues
priority_resolutions entries: target, winner, winner_kind, loser, loser_kind
resource_arbitration entries: resource, kind, arbiter, user, user_kind, suppressed_by
library_uses entries: library, alias, export, kind, instance, module, scheduled_fsm, parameters, bindings
library_uses parameter entries: name, source, value
library_uses binding entries: role, library_name, parent_name, width
bank_accesses entries: kind, owner, owner_kind, container_kind, container_name, bank, index, width, depth, scalar_entries, same_cycle_policy, value, target
transaction_port_bindings entries: site_kind, owner, owner_kind, target_transaction, role, port, actor_signal, actor_expression, width, instance, parent_port, child_port, start_signal, done_signal, trigger_source, payload_source
clock_domains entries: name, default, clock, reset, scheduled_fsm, ports, storage, transactions, rules, library_uses, child_instances, crossings, state_count, dt_block_count
clock_domains child_instances entries: kind, owner, child, instance
clock_domains crossings entries: event, role, signal, ready
crossings entries: name, kind, source_domain, source_signal, destination_domain, destination_signal, ready_signal, instance, module, outstanding_policy, payload, top_fsm
```

For each `dt_blocks` entry, `assignments` is a non-negative integer count of
assignment forms in the matching scheduled `.fsm` DT block. It is not an
assignment payload list. The machine-readable contract advertises this through
`schedule_report_dt_assignments_shape`.
For each `dt_blocks` entry, `kind` is currently one of `drive`,
`do_port_binding`, `latency_counter`, `rule`, `rule_trigger_fanin`,
`spawn_port_binding`, `temporal_contract_monitor`, or
`trigger_generated_activation`. The machine-readable contract advertises this
through `schedule_report_dt_kind_values`.

For each `inferred_storage` entry, `kind` is currently one of `counter` or
`register`. Optional `role` values describe the stable scheduler purpose when
the lowerer has direct evidence. The current role family is
`actor_storage`, `completion_pulse`, `data_register`, `drive_payload`,
`drive_request`, `extract_field`, `latency_counter`, `repeat_counter`,
`sample_alias`, and `watchdog_counter`. Optional `width` values are positive
integer bit widths when present, and are currently present for declared
actor-owned storage, inferred scheduler counters, and register storage with
known ISF width evidence. The machine-readable contract advertises these
through `schedule_report_storage_kind_values`,
`schedule_report_storage_role_values`, and
`schedule_report_storage_width_shape`.

For each `bank_accesses` entry, `kind` is `store` or `load`;
`same_cycle_policy` is currently `read_before_write`; `scalar_entries` lists
the deterministic scalarized storage entries used in the scheduled `.fsm`;
`value` is populated for stores and JSON null for loads; `target` is populated
for loads and JSON null for stores. The machine-readable contract advertises
the exact key set and value families through
`schedule_report_bank_access_keys`,
`schedule_report_bank_access_kind_values`, and
`schedule_report_bank_access_policy_values`.

For each `transactions` entry, `states` is an array of scheduled state names
belonging to that transaction in emitted order, and `count` is a non-negative
integer equal to the `states` array length. The machine-readable contract
advertises this through `schedule_report_transaction_states_shape` and
`schedule_report_transaction_count_shape`.
The `transactions` array itself is sorted lexically by transaction name. Each
entry's `states` array keeps scheduled `.fsm` state emission order for that
transaction. The machine-readable contract advertises this through
`schedule_report_transaction_ordering`.

For each `actor_constants` entry, `name` is the actor-local constant name and
`value` is the stringified compile-time value emitted into scheduled `.fsm`
`+constants`. These constants are compile-time scheduler/source symbols, not
runtime ports, not overrideable params, and not inferred storage.

For each `transaction_waits` entry, `transaction` is the authored transaction
name, `cycles` is the exact positive resolved static wait count or JSON null
for runtime waits, `count_kind` is `static`, `runtime_scalar`, or
`runtime_expression`, `count_source` is the literal, actor constant name,
runtime scalar source signal, or normalized runtime expression text,
`entry_state` is the generated wait state, and `exit_state` is the following
scheduled state after the wait. For consecutive runtime waits, that following
scheduled state can be the next generated wait entry; the generated edge split
may still bypass farther when the next runtime count is zero. Static waits
report `counter_signal` and `counter_width` as JSON null. Runtime waits report
the generated sampled counter name and width through those fields. `(wait 0)`
and symbolic waits that resolve to zero are no-ops and do not create report
entries. Actor-local constants used by symbolic waits are reported separately
through `actor_constants[]`. The machine-readable contract advertises these
through `schedule_report_transaction_wait_keys` and the count-kind value list
through `schedule_report_transaction_wait_count_kind_values`.

For each `transaction_loops` entry, `transaction` is the authored transaction
name, `kind` is `while` or `until`, `condition` is the normalized guard text
used in the scheduled `.fsm`, `entry_state` names the first state associated
with the loop, `decision_states` lists generated condition-sampling states,
`body_start` names the first body state, `body_states` lists generated body
states, `exit_state` names the state reached after the loop, and
`body_clause_count` is the authored body clause count. The machine-readable
contract advertises these through `schedule_report_transaction_loop_keys`.

For each `transaction_stages` entry, `kind` is currently
`ready_valid_barrier`. The entry preserves the authored transaction/stage
names and reports the generated stage state plus the ready input and valid
output. The machine-readable contract advertises these through
`schedule_report_transaction_stage_keys` and
`schedule_report_transaction_stage_kind_values`.

For each `temporal_contracts` entry, `kind` is currently
`bounded_eventually`, `overlap_policy` is currently `fail`, and
`assertion_projection` is currently `none`. The entry reports the generated
trigger state, observed signal, positive cycle bound, generated pending,
counter, and fail signal names, and reset policy. `reset_policy` uses the same
bounded shape as the top-level reset summary when reset is configured and is
null when the actor omits reset. The machine-readable contract advertises
these through `schedule_report_temporal_contract_keys`,
`schedule_report_temporal_contract_kind_values`,
`schedule_report_temporal_contract_overlap_policy_values`,
`schedule_report_temporal_contract_assertion_projection_values`, and
`schedule_report_temporal_contract_reset_policy_shape`.
Raw monitor equations, internal arm request names, and backend assertion text
are not part of the public temporal-contract report entry.

For the `reset` summary, `kind` is currently `async` or `sync`, and `polarity`
is currently `active_high` or `active_low`. The machine-readable contract
advertises those value families through `schedule_report_reset_kind_values` and
`schedule_report_reset_polarity_values`.
When reset is configured, `reset` is a hash reference with
`schedule_report_reset_keys`. When reset is omitted, `reset` is null. The
machine-readable contract advertises this through `schedule_report_reset_shape`.

The top-level `inputs` and `outputs` values are non-negative integer counts.
Single-clock reports count interface ports by direction. Multi-domain reports
count generated-top public ports, including domain clocks/resets and actor
interface ports. `port_count` equals their sum. The top-level `state_count`
value is a non-negative integer count of scheduled `.fsm` state blocks in the
current report scope; multi-domain generated-top reports use zero and expose
domain-local counts in `clock_domains[]`. The machine-readable contract
advertises this through `schedule_report_interface_count_shape` and
`schedule_report_state_count_shape`.

The top-level `source` value is an actor-derived `.isf` basename, and
`scheduled_fsm` is the scheduled `.fsm` basename for the current report scope.
Multi-domain reports use the generated `<actor>_top.fsm` artifact. `clock` is
the scalar clock signal name from the actor declaration, or the selected
default-domain clock when `clock_domains` is present. `watchdog` is a scalar
limit when configured and null when omitted. The machine-readable contract
advertises these through
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

For single-clock multi-file lowerings, the current schedule report describes
the parent scheduled module only. Child scheduled `.fsm` text remains
available through the lower-result `files` map. For multi-domain lowerings,
the current schedule report describes the generated top at the top level and
projects domain-local artifact metadata through `clock_domains[]` plus
crossing metadata through `crossings[]`. The machine-readable contract
advertises this current scope in `schedule_report_multi_file_scope`.
For successful schedule reports, `compile_issues` is present as an array. It is
empty when the successful report has no nonfatal compile issues. The
machine-readable contract advertises that no-issue success shape in
`schedule_report_compile_issues_success_shape`.
Nonfatal conflict issue entries in `compile_issues` are bounded to stable
`code`, `severity`, `target`, `domain`, `proof_status`, diagnostic `reason`,
and capped `sources` summaries. The machine-readable contract advertises the
bounded issue keys in `schedule_report_compile_issue_keys`, source-summary keys
in `schedule_report_compile_issue_source_keys`, current severity values in
`schedule_report_compile_issue_severity_values`, and current proof-status
values in `schedule_report_compile_issue_proof_status_values`.
The current proof-status value that matters for nonfatal conflict reporting is
`not_doable`: it means the lowerer is explicitly flagging that compile-time
proof is NOT doable for that case, instead of silently treating the design as
conflict-free. Fail-closed conflict cases remain targeted diagnostics, not
successful schedule-report entries.
Those rejected diagnostics name the stable code, target, reason, conflicting
owners, source kinds, operators, and values. The CLI `--emit-schedule-json`
path does not emit successful JSON for those rejected conflicts.
Accepted fan-in metadata uses a top-level
`compatible_fanin_groups` array with bounded `kind`, `domain`, target/value
facts, and the same capped source summaries. The machine-readable contract
advertises required group keys in `schedule_report_fanin_group_required_keys`,
optional group keys in `schedule_report_fanin_group_optional_keys`, and current
group kinds in `schedule_report_fanin_group_kind_values`.
The public fan-in projection is narrower than internal classification: request
and pulse fan-in are reported through `request` and `pulse` groups rather than
duplicated as generic `same_target_value` groups.
Transaction port binding provenance uses a top-level
`transaction_port_bindings` array. Each entry is bounded to the advertised key
set and records the binding site kind (`do`, `spawn`, or `rule_trigger`),
owner, target transaction, port role/name, actor signal when the actor side is
a scalar endpoint, formatted actor expression, width, and generated handoff
signal names where applicable. Parameterized rule-trigger entries use the
generated trigger instance handoff names and preserve the per-rule trigger and
payload source names. For expression-valued input bindings,
`actor_signal` is JSON null and `actor_expression` carries the formatted
source expression. JSON null is used for non-applicable handoff fields. The
machine-readable contract advertises the entry key set in
`schedule_report_transaction_port_binding_keys` and the current site-kind
values in `schedule_report_transaction_port_binding_site_kind_values`.
Successful arbitration metadata uses top-level `priority_resolutions` and
`resource_arbitration` arrays. `priority_resolutions` records static
target-local suppressions with bounded winner/loser owner names and owner
kinds. `resource_arbitration` records static resource grant-shaping decisions
for enforced resources, including the resource name, resource kind, arbiter,
rule user, and higher-priority users that can suppress that user's grant. These
entries describe the lowering decision, not per-cycle runtime grant values.
Raw `assignment_provenance`, activation context, assignment indexes, and
priority/resource suppression bookkeeping remain non-public `LoweringIR`
internals unless a later slice deliberately advertises a narrower field.

Multi-domain schedule reports add two bounded top-level arrays.
`clock_domains[]` is empty for legacy one-clock actors. For accepted
`(clock-domains ...)` actors, each entry records the declared domain name,
default marker, clock/reset summary, scheduled domain artifact basename, local
port/storage/transaction/rule/library/child-instance names, local crossing
endpoints, and bounded domain report counts. Multi-domain reports describe the
generated top as the top-level report scope, so top-level `state_count` is
zero and domain-local scheduled state counts live in `clock_domains[]`.
`crossings[]` is empty when no crossing primitive is declared. For accepted
event crossings, each entry records the source domain/signal, destination
domain/pulse signal, ready signal, generated CDC instance/module names,
single-outstanding acknowledgement policy, no-payload policy, and generated
top basename. Concrete synchronizer RTL is still not generated by the ISF CLI
path.

The schedule report is not yet a frozen full schema. Downstream consumers should
use the advertised contract metadata instead of assuming every current field,
generated state name, or private lowering decision is permanent.
The advertised schedule-report metadata fields are exact for the bounded public
key families and policy strings they name.

### Schedule-Report Freeze Readiness

`schedule_report_full_schema_stable` is currently false. The contractual
surface is the advertised metadata in `embedding.isf_public_interface`, not the
raw JSON tree as a whole.

Contractual now:

- The in-process `report(...)` path and `--emit-schedule-json` CLI path emit
  the same successful schedule report for accepted sources.
- `schedule_report_top_level_keys` and the advertised nested key/value
  families define the current bounded public shape.
- Scalar count, reset/nullability, transaction ordering, DT ordering, storage
  kind/role/width, and feature-owned summary arrays are public only to the
  extent described by their advertised metadata fields.

Bounded but not fully frozen:

- New optional keys or value-family members may be added when the same slice
  updates this contract, the mdBook/spec, and focused regressions.
- `inferred_storage[].role`, `compile_issues[]`,
  `compatible_fanin_groups[]`, `priority_resolutions[]`,
  `resource_arbitration[]`, `actor_constants[]`, `transaction_waits[]`,
  `transaction_stages[]`, `transaction_loops[]`, `temporal_contracts[]`,
  `transaction_port_bindings[]`, `library_uses[]`, and `generated_composition`
  are bounded summaries, not raw IR exports.

Blockers before flipping `schedule_report_full_schema_stable` to true:

- Decide whether the report gets its own schema/version field or continues to
  rely on `embedding.isf_public_interface` as the schema discovery surface.
- Close or explicitly defer remaining storage-role families and generated-name
  stability policy.
- Decide whether assignment provenance and multi-file child summaries stay
  private or gain bounded public summaries.
- Define additive/deprecation policy for future top-level keys, nested optional
  keys, and value-family growth.
- Keep a golden fixture matrix covering every advertised branch through both
  in-process and CLI report paths.

## Non-Public Internals

These are not stable public interfaces yet:

- The raw actor hash returned by the parser as a whole.
- Actor fields beyond the advertised `actor_shell_required_keys`.
- Raw library resolver state and raw exported library actor hashes.
- Transaction port behavior beyond parser-shell `ports.inputs[]` /
  `ports.outputs[]` `name`/`width` metadata, scalar/literal/list-expression
  input-binding lowering for `do`, `spawn`, and rule-trigger activation sites,
  plus the first conflict/runtime coverage for binding-generated assignments.
  Rule-trigger output bindings, explicit snapshot-vs-live timing selection,
  broader static conflict diagnostics, richer report fields, and full
  expression width inference remain deferred follow-on port-binding work.
- Transaction control-flow behavior beyond shipped static/symbolic/runtime
  scalar/runtime expression `(wait N)`, sample-compatible runtime wait pending
  samples, and top-level transaction `(while cond body...)` /
  `(until cond body...)` remains non-public. Parameter-backed wait counts,
  sample-incompatible runtime wait successors, nested loops, and loop bodies
  containing child activation, stages, or contracts need parser, lowering,
  report, and regression-backed contracts before downstream users can rely on
  them.
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
