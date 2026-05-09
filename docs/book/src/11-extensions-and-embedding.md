# Extensions and Embedding

This chapter covers the current supported integration seam for tool builders.

## Capability Manifest Discovery

The machine-readable entrypoint for downstream tools is:

```bash
./bin/fsmgen --capability-manifest
```

The top-level `manifest_contract` object owns the bounded shell for that JSON.
It now also publishes a grouped `top_level_contract_source_map` for the public
top-level sections:

- `producer`
- `support_accounting`
- `diagnostics`
- `semantic_exports`
- `backend_validation`
- `embedding`
- `language_surface`
- `documentation`

That grouped map is the intended discovery surface for embedders. It lets a
tool start from one manifest object, then hand each public top-level section to
its dedicated contract owner without reconstructing the owner map from scattered
section payloads, hard-coding owner strings, or remembering that
`language_surface` still advertises its nested owner under `surface_contract`
for compatibility.
The same manifest shell now also publishes a grouped
`top_level_section_presence_key_map` so a downstream tool can discover the
bounded key family for each public top-level section from one place instead of
collecting those section-key lists field by field.
It now also publishes a grouped `presence_key_family_map` so a downstream tool
can discover the manifest-owned legacy `*_presence_keys` field families from
one place instead of collecting those compatibility field lists one by one.

The public machine-JSON CLI boundary is runtime-audited too:
[t/384-public-json-trace-stdout-boundary-audit.t](t/384-public-json-trace-stdout-boundary-audit.t)
runs the capability manifest, check JSON, and normalized semantic JSON paths
with debug/trace options enabled. It proves stdout remains JSON-only, stderr
stays clean, trace output is routed to the requested trace file for report
modes, and check/semantic JSON still do not write HDL artifacts.

## Current Philosophy

The active extension model is typed and explicit.

It is not:

- legacy `.plg` discovery
- implicit hook-name lookup
- stringly plugin callbacks

It is:

- explicit Perl modules
- explicit hook methods
- typed context objects

## Typed Extensions

Current shipped hooks are:

- `after_parse_source($context)`
- `after_generate_result($context)`

These run:

- after parsed-source classification
- after normal generation result assembly

This hook/context boundary is now advertised in the capability manifest under
`embedding.typed_extensions`, owned by
`FSM::Support::ExtensionContract`. That machine-readable contract records:

- explicit object/module/config loading entrypoints
- the shipped hook names
- the stable context accessor names
- the rule that extension modules loaded by name must provide a real `new()`
  method
- the rule that registry extension arrays are copied while extension objects
  remain live hook objects
- and the deliberate absence of legacy `.plg` discovery, automatic directory
  discovery, and `AUTOLOAD` hook dispatch

That registry ownership rule is runtime-audited directly: mutating the caller's
extension array after `FSM::Extension::Registry->new(...)`, or mutating an
`extensions()` accessor array, cannot add hooks to the registry. The extension
objects themselves remain live hook objects by identity.
The same construction-time ownership applies at the facade loader entrypoint:
`HDLGenerator->new(extension_modules => \@modules)` resolves and registers the
listed modules during construction, so later caller mutation of `@modules` does
not add, remove, or replace hooks on that facade object.
`HDLGenerator->new(extension_config_files => \@configs)` follows the same rule
for config-file discovery: the constructor-time config path list is read during
facade construction, and later caller mutation of `@configs` cannot change the
installed hooks.
Direct `HDLGenerator->new(extensions => \@objects)` construction follows the
registry rule as well: the array container is snapped at construction, while the
extension objects themselves remain live hook objects by identity.

That same owner now also publishes a grouped `name_family_map` so embedders
can discover the bounded hook-name, context-accessor, and supported-source-kind
families from one place instead of collecting those name lists separately.
That grouped discovery key is itself now listed in the contract's advertised
top-level key list, and
[t/306-extension-contract.t](t/306-extension-contract.t)
checks that the typed-extension contract's advertised top-level keys cover the
exact emitted contract shell.

The current context accessors are:

- `stage`
- `pipeline`
- `source_path`
- `target_language`
- `source_info`
- `raw_ast`
- `result`

`source_info->{kind}` is the classified root kind, such as `fsm`, `dt`, or
`composition`.
`source_info` and `raw_ast` accessors return fresh snapshots; mutating them does
not alter the stored context. `raw_ast` is available on `after_parse_source`.
`result` is available on `after_generate_result` and remains the live result hash.
Reusable `HDLGenerator` facade objects build new extension context snapshots for
each generation, so mutations to one hook invocation's `source_info` or
`raw_ast` snapshots do not leak into later hook invocations on the same facade.
Result augmentation is a valid in-process extension use, but it is not the same
thing as publishing a new sanitized JSON interchange field.
[t/379-extension-result-json-boundary-audit.t](t/379-extension-result-json-boundary-audit.t)
locks that split: extension-added raw result fields and HDL text remain
available to in-process callers, while `--emit-semantic-json` and
`FSM::Support::NormalizedSemanticReport` keep them out of the public JSON
payload.

## Programmatic Example

```perl
use FSM::Pipeline::HDLGenerator;

{
    package My::ResultMarker;

    sub new { bless {}, shift }

    sub after_generate_result {
        my ($self, $context) = @_;
        $context->result->{extension_marker} = {
            source_kind => $context->source_info->{kind},
            target_language => $context->target_language,
        };
    }
}

my $pipeline = FSM::Pipeline::HDLGenerator->new(
    target_language => 'systemverilog',
    extensions => [ My::ResultMarker->new ],
);

my $result = $pipeline->generate_hdl_from_file('fsm/trial_0.fsm');
```

That public constructor-plus-generate seam is now machine-advertised too under
`embedding.hdl_generator_facade`, owned by
[perl/FSM/Support/HDLGeneratorFacadeContract.pm](perl/FSM/Support/HDLGeneratorFacadeContract.pm).
That bounded facade contract currently covers:

- `new(...)`
- `generate_hdl_from_file(...)`
- the core runtime constructor options `debug_level`, `target_language`,
  `strict_mode`, and `source_search_paths`
- the accepted compatibility/presentation constructor option `quiet`
- direct blessed-object extension injection through `extensions`

It intentionally does not freeze the lower-level owner-injection constructor
arguments. It also leaves module/config-file extension loading behind
`embedding.typed_extensions`, so the narrower facade contract stays honest
about what is currently meant to be a stable in-process entry seam.
That boundary is now audited directly:
[t/377-hdl-generator-constructor-boundary-audit.t](t/377-hdl-generator-constructor-boundary-audit.t)
classifies every current `HDLGenerator` constructor argument read from
`%args` and proves the owner-injection arguments stay out of both the facade
contract and the live manifest public constructor-option lists.
[t/385-hdl-generator-facade-strict-mode-boundary-audit.t](t/385-hdl-generator-facade-strict-mode-boundary-audit.t)
also proves the advertised `strict_mode` constructor option is runtime-backed:
the default facade compiles the legacy infix-assignment compatibility fixture,
the strict facade rejects that same source with the canonical pair-form hint,
and the same strict facade object still accepts the canonical pair-form fixture.
[t/386-hdl-generator-facade-target-language-boundary-audit.t](t/386-hdl-generator-facade-target-language-boundary-audit.t)
also proves the advertised `target_language` constructor option routes real
direct backend behavior: the default path emits SystemVerilog forms, explicit
`verilog` emits Verilog forms, and explicit `vhdl` remains a source-contextual
not-implemented boundary rather than a completed backend promise.
[t/387-hdl-generator-facade-debug-level-boundary-audit.t](t/387-hdl-generator-facade-debug-level-boundary-audit.t)
also proves the advertised `debug_level` constructor option is runtime-backed
and scoped: level `0` stays silent, level `2` emits low/medium trace without
high-detail raw-AST dumps, level `4` emits that high-detail path, and the
caller debug state is restored afterward.
[t/388-hdl-generator-facade-source-search-paths-boundary-audit.t](t/388-hdl-generator-facade-source-search-paths-boundary-audit.t)
also proves the advertised `source_search_paths` constructor option is
runtime-backed and facade-local: missing roots fail at external package
resolution, supplied roots generate HDL with the imported package literal, and
separate facade objects with different roots do not leak resolution state.
That facade-local rule includes input ownership: the constructor-time
`source_search_paths` array is copied into the resolver, so later caller
mutation of the original array reference does not change package resolution for
that facade object.
[t/389-hdl-generator-facade-extensions-boundary-audit.t](t/389-hdl-generator-facade-extensions-boundary-audit.t)
also proves the advertised `extensions` constructor option is runtime-backed as
direct blessed-object injection: non-blessed values are rejected, hook-capable
injected objects dispatch in order, result-hook mutation reaches the returned
raw result, and separate facade objects do not share injected extension state.
[t/390-hdl-generator-facade-quiet-boundary-audit.t](t/390-hdl-generator-facade-quiet-boundary-audit.t)
also proves the advertised `quiet` constructor option is accepted compatibility
state rather than core runtime behavior: it is grouped under
`compatibility_constructor_option_names`, stays out of the core runtime family,
and in-process generation captures no stdout/stderr for either quiet value.
[t/419-hdl-generator-facade-legacy-debug-boundary-audit.t](t/419-hdl-generator-facade-legacy-debug-boundary-audit.t)
also proves the older `debug` constructor compatibility key stays non-public:
it is absent from the facade contract and manifest public constructor surfaces,
maps boolean values to `debug_level` `0` / `1` only when public `debug_level`
is omitted, yields to public `debug_level` when both are supplied, and rejects
malformed defined values before debug-runtime setup. New embedder-facing code
should use `debug_level`, not legacy `debug`.
[t/420-hdl-generator-facade-constructor-duplicate-option-boundary-audit.t](t/420-hdl-generator-facade-constructor-duplicate-option-boundary-audit.t)
also proves duplicate raw `new(...)` constructor option names fail at the
facade seam before Perl hash assignment can silently keep only the last value:
the duplicate-option policy is manifest-backed, public and non-public repeated
names receive sorted targeted diagnostics, later value-shape or unsupported
name validation does not run first, and caller debug state is preserved.
[t/421-hdl-generator-facade-extension-hook-method-boundary-audit.t](t/421-hdl-generator-facade-extension-hook-method-boundary-audit.t)
also proves direct extension objects must expose at least one real supported
typed-extension hook method: hookless, unsupported-hook-only, and
`AUTOLOAD`/fake-`can` objects fail at the facade before registry or raw method
fallout can leak, while parse-only and result-only real hook objects remain
accepted.
[t/426-typed-extension-registry-constructor-argument-boundary-audit.t](t/426-typed-extension-registry-constructor-argument-boundary-audit.t)
also proves direct `FSM::Extension::Registry->new(...)` construction accepts
only the exact class receiver and an even-length list of unique supported
scalar option names, so malformed registry constructor calls fail before raw
hash-coercion or `bless` fallout can leak.
[t/429-typed-extension-registry-method-receiver-boundary-audit.t](t/429-typed-extension-registry-method-receiver-boundary-audit.t)
also proves direct registry methods require an exact hash-backed
`FSM::Extension::Registry` object constructed by `new(...)`, so class
receivers, subclass stand-ins, and fake exact-class objects fail before hook or
context diagnostics can leak.
[t/432-typed-extension-registry-method-argument-list-boundary-audit.t](t/432-typed-extension-registry-method-argument-list-boundary-audit.t)
also proves direct registry methods own their payload argument counts:
`extensions(...)` takes no payload arguments, `dispatch_hook(...)` takes a
hook name and context, and hook wrapper methods take one context argument after
the registry invocant.
[t/493-typed-extension-registry-extension-list-defensive-copy-boundary-audit.t](t/493-typed-extension-registry-extension-list-defensive-copy-boundary-audit.t)
also proves direct registry construction and `extensions()` accessor calls copy
the extension array, so caller-side list mutation cannot alter the registry's
configured dispatch list while the extension objects remain the live hook
objects that dispatch invokes.
[t/399-hdl-generator-facade-stateful-reuse-boundary-audit.t](t/399-hdl-generator-facade-stateful-reuse-boundary-audit.t)
also proves the advertised `stateful_reuse_supported` promise is
runtime-backed: one facade object preserves `strict_mode`, `target_language`,
and `source_search_paths` across success, strict-mode failure, and later
success, while restoring caller debug state after each path and still keeping
lower-level owner-injection constructor args outside the public facade surface.
[t/375-hdl-generator-facade-contract.t](t/375-hdl-generator-facade-contract.t)
also now checks that the facade contract's advertised top-level key list
exactly covers the emitted facade contract shell, so new facade metadata cannot
silently miss the machine-readable key list.
[t/380-extension-loading-command-boundary-audit.t](t/380-extension-loading-command-boundary-audit.t)
locks the matching loading-owner split: module/config extension loading remains
advertised by `embedding.typed_extensions`, stays out of
`embedding.hdl_generator_facade`, and does not widen the normalized-semantic
JSON `command` object when semantic export runs with loaded extensions.
[t/391-typed-extension-programmatic-loading-boundary-audit.t](t/391-typed-extension-programmatic-loading-boundary-audit.t)
also proves that same typed-extension-owned programmatic loading seam is
runtime-backed in-process: `extension_modules` and `extension_config_files`
both load a real module from `@INC`, dispatch `after_parse_source` before
`after_generate_result`, and mutate only the returned raw result for the
pipeline that requested loading.
[t/400-typed-extension-config-line-shape-boundary-audit.t](t/400-typed-extension-config-line-shape-boundary-audit.t)
also proves the advertised config-file line shape is runtime-backed:
config files accept only `module Module::Name` lines plus inert blank,
comment, and inline-comment text; malformed lines report extension config
file and line-number context; and repeated config files preserve parsed module
order during in-process hook dispatch.
[t/401-typed-extension-module-name-shape-boundary-audit.t](t/401-typed-extension-module-name-shape-boundary-audit.t)
also proves module-name validation fails closed before loading: every
`::`-separated segment must use the `Module::Name` identifier shape, so names
such as `FSM::BoundaryAudit::9Bad` are rejected at loader, config parser,
pipeline, and CLI boundaries before `require` runs or emits missing-module
fallout.
[t/402-typed-extension-constructor-list-shape-boundary-audit.t](t/402-typed-extension-constructor-list-shape-boundary-audit.t)
also proves the constructor list shape for programmatic extension loading
fails at the facade seam: scalar/hash values for `extension_modules`,
`extension_config_files`, and direct `extensions` are rejected with targeted
array-reference diagnostics before raw Perl dereference or lower-level loader
fallout can leak.
[t/392-typed-extension-autoload-boundary-audit.t](t/392-typed-extension-autoload-boundary-audit.t)
also proves `AUTOLOAD` remains outside the typed-extension hook boundary:
AUTOLOAD-only extensions, including objects that override `can(...)`, fail
closed as hookless direct extension objects, while explicit and inherited real
hook methods still run normally.
[t/393-typed-extension-hook-set-closed-boundary-audit.t](t/393-typed-extension-hook-set-closed-boundary-audit.t)
also proves the hook set is closed for the current schema version: extra
hook-shaped methods such as `before_parse_source` or `after_emit_hdl` remain
inert during direct and composition generation until the contract deliberately
adds a new hook family.
[t/394-typed-extension-context-accessor-boundary-audit.t](t/394-typed-extension-context-accessor-boundary-audit.t)
also proves the context accessor names are stable for the current schema
version by checking manifest discovery, the implemented
`FSM::Extension::Context` methods, and real direct plus composition hook
contexts through every advertised accessor.
[t/395-typed-extension-explicit-discovery-boundary-audit.t](t/395-typed-extension-explicit-discovery-boundary-audit.t)
also proves extension discovery remains explicit: nearby `extensions.fsmext`,
`fsmgen.fsmext`, and legacy `.plg`-shaped files stay inert for in-process and
CLI generation unless the caller supplies explicit module or config loading
entrypoints.
[t/396-typed-extension-constructor-boundary-audit.t](t/396-typed-extension-constructor-boundary-audit.t)
also proves module-name loading requires a real `new()` method: explicit and
inherited constructors still work, while extension-provided `can(...)` methods
and `AUTOLOAD`-only constructor discovery stay outside the typed loading
boundary.
[t/427-typed-extension-loader-constructor-argument-boundary-audit.t](t/427-typed-extension-loader-constructor-argument-boundary-audit.t)
also proves direct `FSM::Extension::Loader->new(...)` construction accepts
only the exact class receiver and no option/value arguments, so malformed
loader constructor calls fail before raw hash-coercion or `bless` fallout can
leak.
[t/428-typed-extension-loader-method-receiver-boundary-audit.t](t/428-typed-extension-loader-method-receiver-boundary-audit.t)
also proves direct loader methods require an exact hash-backed
`FSM::Extension::Loader` object constructed by `new(...)`, so class receivers,
subclass stand-ins, and fake exact-class objects fail before loading payload
diagnostics can leak.
[t/431-typed-extension-loader-method-argument-list-boundary-audit.t](t/431-typed-extension-loader-method-argument-list-boundary-audit.t)
also proves direct loader methods accept exactly one payload argument after the
loader invocant, so missing or extra payload arguments fail before raw Perl
signature fallout or payload value diagnostics can leak.
[t/397-typed-extension-registry-dispatch-boundary-audit.t](t/397-typed-extension-registry-dispatch-boundary-audit.t)
also proves the registry's direct `dispatch_hook(...)` entrypoint enforces the
same closed hook set: `after_parse_source` and `after_generate_result` still
dispatch, while unsupported hook names are rejected before extension methods
can run.
[t/422-typed-extension-registry-dispatch-context-boundary-audit.t](t/422-typed-extension-registry-dispatch-context-boundary-audit.t)
also proves direct registry dispatch requires a real
`FSM::Extension::Context` object whose `stage` matches the dispatched hook
name, so malformed direct contexts fail before extension code can reinterpret
them.
[t/434-typed-extension-registry-dispatch-constructed-context-boundary-audit.t](t/434-typed-extension-registry-dispatch-constructed-context-boundary-audit.t)
also proves direct registry dispatch requires an exact hash-backed context
object constructed by `FSM::Extension::Context->new(...)`, so fake exact-class
context objects fail at the registry boundary before context accessor fallout
can leak.
[t/423-typed-extension-context-constructor-argument-boundary-audit.t](t/423-typed-extension-context-constructor-argument-boundary-audit.t)
also proves direct `FSM::Extension::Context->new(...)` construction accepts
only the exact class receiver and an even-length list of unique supported
scalar option names, so malformed constructor calls fail before raw Perl
argument or `bless` fallout can leak.
[t/430-typed-extension-context-accessor-receiver-boundary-audit.t](t/430-typed-extension-context-accessor-receiver-boundary-audit.t)
also proves direct context accessors require an exact hash-backed
`FSM::Extension::Context` object constructed by `new(...)`, so class receivers,
subclass stand-ins, and fake exact-class objects fail before raw accessor
fallout can leak.
[t/433-typed-extension-context-accessor-argument-list-boundary-audit.t](t/433-typed-extension-context-accessor-argument-list-boundary-audit.t)
also proves direct context accessors take no payload arguments after the
context invocant, so extra accessor arguments fail before raw Perl signature
fallout can leak.
[t/424-typed-extension-context-constructor-payload-boundary-audit.t](t/424-typed-extension-context-constructor-payload-boundary-audit.t)
also proves direct context construction validates the payload values that hooks
rely on: supported hook stages, a blessed pipeline, scalar source path and
target language, scalar `source_info->{kind}`, parse contexts with
`raw_ast` and no `result`, and result contexts with `result` and no `raw_ast`.
[t/425-typed-extension-dt-source-kind-contract-audit.t](t/425-typed-extension-dt-source-kind-contract-audit.t)
also proves standalone `?dt:` roots are part of the bounded typed-extension
source-kind family: manifests advertise `dt`, and live `dt` generation
dispatches parse/result contexts whose `source_info->{kind}` is `dt`.

For in-process embedders, `FSM::Pipeline::HDLGenerator` no longer leaves its
requested `debug_level` behind as process-global state after construction or
generation. The pipeline now scopes its debug setting to the constructor or
generation call and restores the caller's prior `FSM::Debug` state afterward.

If an embedder needs to rebind tracing manually, the current shipped
save/restore seam is:

```perl
use FSM::Debug qw(
    capture_fsm_debug_state
    restore_fsm_debug_state
    set_fsm_trace_output_file
    set_fsm_trace_verbosity
);

my $saved = capture_fsm_debug_state();
set_fsm_trace_output_file('embedded-trace.log');
set_fsm_trace_verbosity('debug');

# ... temporary embedded tracing work ...

restore_fsm_debug_state($saved);
```

That restore path preserves the caller-facing trace/debug configuration,
including the original trace sink, instead of forcing embedders to reconstruct
global debug state by hand after a temporary trace-file switch. Restores now
accept exact schema-version-1 snapshots from `capture_fsm_debug_state(...)` and
reject malformed partial snapshots before mutating process-global debug state.
[t/374-debug-runtime-contract.t](t/374-debug-runtime-contract.t)
now also checks that the debug-runtime contract's advertised top-level key list
exactly covers the emitted debug-runtime contract shell, matching the same
self-description guard used by the sibling facade and typed-extension contracts.
The same direct contract test also proves the advertised helper/control names
are implemented and exported by `FSM::Debug`, and that the advertised named
trace-verbosity values plus numeric range match the live debug runtime mapping.
It also captures a trace-bound debug-state snapshot and proves the advertised
`snapshot_state_keys` match the real snapshot keys, including the schema,
debug level, trace path, live filehandle, and emoji state.
That trace-bound snapshot is also checked as not JSON-safe as a whole, matching
the contract's `snapshot_json_safe => false` claim.
[t/494-debug-runtime-restore-state-boundary-audit.t](t/494-debug-runtime-restore-state-boundary-audit.t)
also proves the manifest-backed restore argument shape, valid captured
restores, targeted malformed-snapshot diagnostics, and caller-state
preservation on rejection.
[t/398-debug-runtime-scoped-helper-boundary-audit.t](t/398-debug-runtime-scoped-helper-boundary-audit.t)
also proves `with_fsm_debug_state(...)` restores caller debug state across
scalar, list, void, and error paths, while ordinary debug setters remain
process-global unless callers explicitly scope or restore them.
That current in-process seam is now also advertised through
`embedding.debug_runtime`, owned by
[perl/FSM/Support/DebugRuntimeContract.pm](perl/FSM/Support/DebugRuntimeContract.pm).
That bounded contract publishes the shipped helper families, the bounded
snapshot-state keys, the supported named trace-verbosity values, and the
current limit that `FSM::Debug` is still one process-global singleton rather
than a thread-local debug context.

## CLI Loading

```bash
PERL5LIB=./my_extensions ./bin/fsmgen \
  --extension-module My::ResultMarker \
  --output /tmp/trial_0.sv \
  fsm/trial_0.fsm
```

Or via config file:

```text
module My::ResultMarker
```

```bash
PERL5LIB=./my_extensions ./bin/fsmgen \
  --extension-config extensions.fsmext \
  --output /tmp/trial_0.sv \
  fsm/trial_0.fsm
```

## Result Surfaces

Embedders can already consume structured result data such as:

- `module_info`
- `intent_hir`
- `lowered_rtl_ir`
- `structural_rtl_ir`
- composition reports

The first bounded `HDLGenerator` result contract is now manifest-backed too.
The in-process entrypoint is:

```perl
my $result = FSM::Pipeline::HDLGenerator->new(
    target_language => 'systemverilog',
)->generate_hdl_from_file('path/to/file.fsm');
```

`R13` now treats explicit serializable plan/report APIs as the preferred
direction for new embedder-facing surfaces. The raw `HDLGenerator` result
branches remain useful in-process compatibility shells, but downstream tooling
should not have to traverse raw objects such as `composition_spec`,
`composition_plan`, `fsm_module`, `raw_ast`, or `resolved_package_imports` to
build stable machine-readable integrations.
That direction now has a concrete manifest surface:
[perl/FSM/Support/SerializablePlanReportContract.pm](perl/FSM/Support/SerializablePlanReportContract.pm)
is advertised as `embedding.serializable_plan_reports`, listing the current
JSON-safe report families and mapping raw `HDLGenerator` compatibility shells to
preferred serializable replacements.
The first plan-oriented API behind that surface is
[perl/FSM/Support/SerializableCompositionPlanSnapshot.pm](perl/FSM/Support/SerializableCompositionPlanSnapshot.pm):
`build_serializable_composition_plan_snapshot(...)` emits a JSON-safe
`composition_plan_snapshot` with bounded summaries for the plan lane, top module,
ports, links, resolved-link endpoints, nets, instances, auxiliary assignments,
and shared-datapath candidates without exposing the raw
`FSM::Composition::Plan` object graph. Successful normalized semantic JSON
reports for composition roots now embed that same snapshot at
`semantic.composition.plan_snapshot`.
The manifest surface also advertises
[perl/FSM/Support/SerializableGenerationResultSnapshot.pm](perl/FSM/Support/SerializableGenerationResultSnapshot.pm)
as `generation_result_snapshot`, a JSON-safe summary of raw `HDLGenerator`
results that records stable module/source/HDL-size facts, semantic-layer
presence, and raw-shell presence/class metadata without turning the raw result
hash into a public JSON API. Successful normalized semantic JSON reports now
expose that snapshot as top-level `generation_result_snapshot`. Failed semantic
JSON reports deliberately omit both `generation_result_snapshot` and semantic
composition `plan_snapshot`, preserving the existing success-only boundary for
generated semantics.
The manifest surface also advertises
[perl/FSM/Support/SerializableDiagnosticSummary.pm](perl/FSM/Support/SerializableDiagnosticSummary.pm)
as `diagnostic_summary`, a JSON-safe diagnostic count/code/severity summary for
tools that do not need to copy complete diagnostic payloads. Normalized semantic
JSON now embeds that summary for both success and failure reports, and check JSON
uses the same summary for `--check --json` / `--check-json` outputs.
The diagnostic summary builder and contract return fresh caller-owned
containers, so local annotations of code lists or count maps do not pollute
later report construction.
Tracked documentation and book links use paths relative to the repository root;
machine-local absolute filesystem paths are not part of the public embedding
surface.

The bounded contract stabilizes top-level key presence for fields such as
`hdl_code`, `module_info`, `intent_hir`, `lowered_rtl_ir`,
`structural_rtl_ir`, `source_info`, and `resolved_package_imports`. It also
stabilizes the small nested identity slices `source_info.header`,
`source_info.kind`, `module_info.module_name`, and
`module_info.source_root_kind`, plus the bounded summary keys inside
`source_info`, `module_info`, and `statistics`. That includes source-level
facts such as `package_import_count` and `package_import_names`, reusable
module/stats counts such as `signal_count`, `state_count`,
`parameter_count`, `output_drive_family_count`, `intermediate_signals`,
`global_expressions`, `factoring_enabled`, and the composition-only
count/lane fields when the input root is a composition. The same contract now
also advertises that the top-level `intent_hir`, `lowered_rtl_ir`, and
`structural_rtl_ir` hashes reuse the bounded shell owners from normalized
semantic JSON, while explicitly
classifying live/raw/unsanitized compatibility payloads such as `fsm_module`,
`raw_ast`, `resolved_package_imports`,
`statistics`, `composition_spec`, `composition_plan`, and
`composition_report`.
Reusable `HDLGenerator` facade objects return fresh top-level direct result
containers per generation, so caller additions, replacements, or deletions on
one result do not leak into a later direct result from the same facade.
Composition generation follows the same top-level result-container reuse rule,
including composition-only branches such as `composition_report`.
Standalone `?dt` generation follows that result-container reuse rule too.
The top-level `resolved_package_imports` branch is therefore shell-only: it is
still a hash of raw `FSM::Package::Spec` objects, so stable package-import
inspection should use `source_info.package_import_count` and
`source_info.package_import_names` instead of traversing those typed values.
The `package_import_names` list is a fresh caller-owned array on each returned
`source_info` object, so local caller mutation of one returned summary does not
affect a later result.
That same owner now also publishes a grouped `fallback_surface_map` so
embedders can discover the bounded source-info package-import fallback family
from one place instead of collecting those fallback paths separately.
That shell-only branch now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm](perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm),
which is the contract to follow for the raw package-spec-map rule plus that
bounded package-import summary surface.
Reusable `HDLGenerator` facade objects also return a fresh
`resolved_package_imports` map for each generation: caller mutation of one
result's raw map does not leak into a later result produced by the same facade
object.
The raw `FSM::Package::Spec` values inside that map are also per-generation
objects for facade reuse: mutating one result's package name, symbols, or raw
package AST does not leak into a later generation.
The same per-generation package-spec rule applies whether the package source is
embedded in the root file or loaded from a configured package search path.
Composition results keep the top-level `resolved_package_imports` map and
`source_info.resolved_package_imports` as independent mirrors down to the raw
package-spec object graph, so annotating either mirror does not rewrite the
other one.
Reusable `HDLGenerator` facade objects also rebuild both composition
package-spec mirrors for each generation, so caller mutation of one composition
result's resolved package specs does not leak into the next composition result.
The enclosing composition resolved-import maps are also fresh per generation for
both the top-level branch and the `source_info` mirror.
The top-level `fsm_module` branch is shell-only too when it is defined: it is a
raw `FSM::CoreAST::FSMModule` object kept for in-process compatibility, so
structured downstream consumers should prefer `intent_hir`, `lowered_rtl_ir`,
`structural_rtl_ir`, or normalized semantic JSON. That shell-only branch now
also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorFSMModuleContract.pm](perl/FSM/Support/HDLGeneratorFSMModuleContract.pm),
which is the contract to follow for the raw CoreAST-object rule plus the
semantic-summary fallback surfaces.
Reusable `HDLGenerator` facade objects return fresh direct-generation
`fsm_module` object graphs per generation, so caller mutation of one result's
raw module object, nested signals, or state array does not leak into a later
result produced by the same facade object.
Standalone `?dt` roots follow the same reuse rule for their distinct
decision-tree-shaped `fsm_module` graphs.
The top-level `raw_ast`
branch is likewise shell-only and intentionally treated as a frontend/debug
artifact rather than a public interchange tree, so structured consumers should
prefer `intent_hir` instead of binding themselves to parser-level arrays. That
shell-only branch now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorRawASTContract.pm](perl/FSM/Support/HDLGeneratorRawASTContract.pm),
which is the contract to follow for the parser/debug-array rule plus the
`intent_hir` fallback surface.
Reusable `HDLGenerator` facade objects return a fresh `raw_ast` snapshot per
generation, so caller mutation of one result's parser/debug array does not leak
into a later result produced by the same facade object.
The same result contract now machine-advertises the narrower “stable
subsurface” boundary for the nested hashes too: the whole `source_info`,
`module_info`, and `statistics` hashes are still not stable APIs, but the
advertised `source_info.*`, `module_info.*`, and `statistics.*` identity/summary
paths are the bounded public slices embedders should target.
That same contract now also publishes a grouped `stable_subsurface_map` so
embedders can discover those bounded nested stable slices from one place
instead of reconstructing the map from the separate `source_info`,
`module_info`, and `statistics` arrays.
It now also publishes a grouped `optional_composition_key_family_map` so
embedders can discover the bounded composition-only key families from one
place instead of collecting the separate `module_info`,
`statistics`, `intent_hir`, and `lowered_rtl_ir` optional-composition lists
individually.
It now also publishes a grouped `semantic_layer_presence_key_family_map` so
embedders can discover the bounded top-level semantic-layer key families for
`intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` from one place
instead of collecting those semantic-layer key lists separately.
It now also publishes a grouped `shell_only_fallback_surface_map` so embedders
can discover, from one place, where to go instead of binding themselves to the
raw shell-only compatibility branches such as `fsm_module`, `raw_ast`,
`resolved_package_imports`, `composition_spec`, `composition_plan`, and
`composition_report`.
It now also publishes a grouped `shell_only_fallback_surface_family_map` so
embedders can discover the narrower fallback-surface families those shell-only
branches publish for themselves without reconstructing the per-branch grouping
by hand.
The nested `source_info` object now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorSourceInfoContract.pm](perl/FSM/Support/HDLGeneratorSourceInfoContract.pm),
which is the contract to follow for `header`, `kind`,
`package_import_count`, and `package_import_names`.
Reusable `HDLGenerator` facade objects return fresh `source_info` containers per
generation, so caller mutation of one result's classification or package summary
does not leak into a later result produced by the same facade object.
That includes direct roots with non-empty package-import summaries.
Standalone `?dt` roots follow the same source-info reuse rule when their
packages are resolved through `source_search_paths`.
That reuse rule covers composition `source_info` too, including the top-root
header and package-import summary list.
For direct package imports, `source_info.package_import_names` is also audited
against the raw `fsm_module.attributes.package_imports` compatibility branch:
the two arrays preserve the same authored import order without sharing mutable
containers.
Standalone `?dt` roots use the same package-import summary ownership rule,
including external packages resolved through `source_search_paths`.
Composition roots also use that rule: `source_info.package_import_names` matches
the raw `composition_spec->top->package_imports` branch without sharing its
mutable array.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded identity and summary source-info key
families from one place instead of collecting those key lists separately.
The nested `module_info` object now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorModuleInfoContract.pm](perl/FSM/Support/HDLGeneratorModuleInfoContract.pm),
which is the contract to follow for `module_name`,
`source_root_kind`, the direct-root scalar summary keys, and the
composition-only scalar summary keys.
Reusable `HDLGenerator` facade objects return fresh `module_info` containers per
generation, so caller mutation of one result's module summary does not leak into
a later result produced by the same facade object.
That reuse rule covers composition `module_info` too, including top-level module
summaries, signal analysis, and child summary containers.
Standalone `?dt` `module_info` follows the same facade-reuse ownership rule for
module and signal summaries.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded identity, summary, and composition-only
module-info key families from one place instead of collecting those key lists
separately.
Composition `module_info` summary projections such as `signal_analysis`,
`composition_children`, and `composition_generated_children` are also audited
as owned result containers. They start equivalent to their embedded
`intent_hir` mirrors, but annotating either location does not mutate the other.
Direct-generation `module_info` forward summary projections such as
`signal_analysis` and `signal_names` follow the same rule: they start equivalent
to their embedded `intent_hir` mirrors without sharing mutable containers.
The same rule applies to lowered summary projections such as
`internal_net_names` and `instance_names`: they start equivalent to the embedded
`lowered_rtl_ir` mirrors without sharing mutable containers.
Direct-generation lowered summaries such as `output_drive_families` and
`standalone_dt_multi_drive_targets` are audited the same way: initially
equivalent to their embedded `lowered_rtl_ir` mirrors, independently mutable
after return.
The nested `statistics` object now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorStatisticsContract.pm](perl/FSM/Support/HDLGeneratorStatisticsContract.pm),
which is the contract to follow for the direct-root scalar summary keys and
the composition-only scalar summary keys.
Reusable `HDLGenerator` facade objects return fresh `statistics` containers per
generation, so caller mutation of one result's scalar statistics or nested raw
backend maps does not leak into a later result produced by the same facade
object.
Composition statistics follow the same reuse rule, including the nested
`statistics.composition_provenance` mirror.
Standalone `?dt` statistics follow the same reuse rule for common scalar
statistics and raw nested backend maps.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded summary and composition-only statistics
key families from one place instead of collecting those key lists
separately.
Composition statistics returned from a caller-supplied `statistics_seed` are
also audited as owned snapshots: nested seed arrays and hashes remain
caller-owned, while the returned `statistics` branch can be annotated without
rewriting the original seed.
The top-level `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` hashes
follow the same honesty rule: they reuse the dedicated normalized-semantic
shell owners and their advertised shell keys, but the `HDLGenerator` result
contract does not treat those top-level hashes as separately stabilized full
trees beyond those shell boundaries.
Direct and composition generation both expose those semantic IR payloads twice:
as convenient top-level result branches and as compatibility mirrors under
`module_info`. Those locations should compare equal at return time, but callers
must treat them as separate mutable projections. Mutating
`result->{intent_hir}`, `result->{lowered_rtl_ir}`, or
`result->{structural_rtl_ir}` must not rewrite the same-result `module_info`
mirror, and mutating the mirror must not rewrite the top-level projection.
Reusable `HDLGenerator` facade objects also return fresh top-level semantic IR
maps per generation, so caller mutation of one result's `intent_hir`,
`lowered_rtl_ir`, or `structural_rtl_ir` does not leak into a later result
produced by the same facade object.
The direct-generation `intent_hir` shell is explicitly audited under that
stateful facade-reuse rule.
The direct-generation `lowered_rtl_ir` shell is audited under the same rule,
including caller-created optional branches.
The direct-generation `structural_rtl_ir` shell is audited under that rule as
well, including structural ports and net lists.
Composition `intent_hir` shells are also audited under the same facade-reuse
rule, including realized child summaries.
Composition `lowered_rtl_ir` shells follow that rule for lowered instance and
net summaries.
Composition `structural_rtl_ir` shells follow it for top ports, child
instances, and resolved links.
Standalone `?dt` `intent_hir` shells follow the same facade-reuse rule for
data-transform intent summaries.
The whole raw result hash is now runtime-audited as non-JSON-safe too:
[t/378-hdl-generator-result-json-boundary-audit.t](t/378-hdl-generator-result-json-boundary-audit.t)
checks real direct and composition `HDLGenerator` results against strict JSON
encoding and verifies that normalized semantic JSON remains the public
JSON-safe interchange path.
The composition-only `composition_spec` and `composition_plan` branches are
shell-only too: they are raw `FSM::Composition::Spec` and
`FSM::Composition::Plan` objects kept for in-process compatibility. The
`composition_spec` branch now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm](perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm),
which is the contract to follow for the raw composition-spec rule plus the
sanitized composition-summary fallback surfaces. That same owner now also
publishes a grouped `fallback_surface_map` so embedders can discover the
bounded semantic-composition fallback families from one place. Reusable
`HDLGenerator` facade objects return fresh `composition_spec` objects per
composition generation, so caller mutation of one result's raw composition
object graph does not leak into a later result produced by the same facade
object. The `source_info.composition_spec` compatibility mirror follows the
same per-generation ownership rule when a facade object is reused. The
`composition_plan` branch
now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm](perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm),
which is the contract to follow for the raw composition-plan rule plus the
same sanitized composition-summary fallback surfaces. That same owner now also
publishes a grouped `fallback_surface_map` so embedders can discover the
bounded semantic-composition fallback families from one place. Reusable
`HDLGenerator` facade objects return fresh `composition_plan` objects per
composition generation, so caller mutation of one result's raw plan object graph
does not leak into a later result produced by the same facade object. Raw
`composition_report` is likewise an in-process compatibility hash rather than
a serializable public JSON surface, so embedders should follow
[perl/FSM/Support/CompositionReportContract.pm](perl/FSM/Support/CompositionReportContract.pm)
and the sanitized
`semantic.composition.provenance_report` fragment for downstream interchange.
Reusable `HDLGenerator` facade objects return fresh `composition_report`
containers per composition generation, so caller mutation of one result's raw
provenance report does not leak into a later result produced by the same facade
object.
Composition generation also mirrors provenance into
`module_info.composition_provenance` and `statistics.composition_provenance`.
Those three branches should compare equal at return time, but they are separate
result containers: caller-side annotation of raw `composition_report` must not
rewrite `module_info` or `statistics`, and annotation of either mirror must not
rewrite the raw report or the other mirror.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded composition-report summary, collection,
count-map, example-map, and ordered-list families from one place instead of
collecting those key-family lists separately.
The public `support_accounting` match objects emitted beside those reports also
share one bounded nested-object contract:
[perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm)
owns the common `matched` key plus the matched success/failure identity keys
used by check JSON and normalized semantic JSON.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded support-accounting key families from one
place instead of collecting the individual field-family lists separately.
Those same public check JSON and normalized semantic JSON reports now also
share one bounded nested-object contract for producer identity:
[perl/FSM/Support/ReportProducerContract.pm](perl/FSM/Support/ReportProducerContract.pm)
owns the shared `name` plus `report_source` keys, while normalized semantic
JSON adds the bounded `semantic_layers` extension documented by that same
owner.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded producer key families from one place
instead of collecting the individual field-family lists separately.
Those same public check JSON and normalized semantic JSON reports now also
share one bounded nested-object contract for the caller-facing source identity:
[perl/FSM/Support/ReportSourceContract.pm](perl/FSM/Support/ReportSourceContract.pm)
owns the shared `input` plus `resolved_path` keys emitted under the nested
`source` object.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded source input and resolution key families
from one place instead of collecting the individual key-family lists
separately.
Those same public check JSON and normalized semantic JSON reports now also
share one bounded nested-object contract for invocation metadata:
[perl/FSM/Support/ReportCommandContract.pm](perl/FSM/Support/ReportCommandContract.pm)
owns the shared `mode`, `json`, `strict_mode`, and `target_language` keys
emitted under the nested `command` object.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded command mode, flag, and target-language
key families from one place instead of collecting the individual
key-family lists separately.
Those same public check JSON and normalized semantic JSON reports now also
share one bounded nested-object contract for HDL-emission side effects:
[perl/FSM/Support/ReportGeneratedOutputContract.pm](perl/FSM/Support/ReportGeneratedOutputContract.pm)
owns the shared `emitted` key emitted under the nested `generated_output`
object.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded generated-output emission key family from
one place instead of collecting that key-family list separately.
Successful public check JSON reports now also have one bounded nested-object
contract for the compact success summary:
[perl/FSM/Support/CheckResultContract.pm](perl/FSM/Support/CheckResultContract.pm)
owns the `module_name`, `state_count`, `signal_count`, and
`composition_child_count` keys emitted under the nested `result` object.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded result identity and summary key families
from one place instead of collecting the individual key-family lists
separately.
The public check JSON contract now also publishes a grouped
`nested_presence_key_map` so embedders can discover the primary nested object
key families for `command`, `result`, `failure_diagnostic`,
`generated_output`, `producer`, `source`, and report-level
`support_accounting` from one place, while the matched overlays and optional
failure-diagnostic artifacts remain explicitly advertised as separate bounded
key families.
That same shell now also publishes a grouped `presence_key_family_map` so
embedders can discover the shell-owned success, failure, and shared report key
families from one place instead of collecting those check-JSON field-family
lists separately.
At the manifest-facing diagnostics-section level, FSMGen now also publishes a
grouped `nested_presence_key_map` so downstream tools can discover the bounded
key family for `stable_code_registry` and `check_json` from one place before
descending into those child contracts.
Failed public check JSON reports now also have one bounded nested-object
contract for the failure payload itself:
[perl/FSM/Support/CheckFailureDiagnosticContract.pm](perl/FSM/Support/CheckFailureDiagnosticContract.pm)
owns the core stable diagnostic keys plus the matched-only, optional-artifact,
and nested support-accounting key lists emitted under each `diagnostic`
object.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded failure-diagnostic key families from one
place instead of collecting the individual field-family lists separately.
Failed public normalized semantic JSON reports now explicitly reuse that same
bounded nested failure-diagnostic contract too.
Successful public normalized semantic JSON reports now also have one bounded
nested-object contract for the success payload itself:
[perl/FSM/Support/NormalizedSemanticPayloadContract.pm](perl/FSM/Support/NormalizedSemanticPayloadContract.pm)
owns the `module`, `system_contract`, `explicit_system_contract`,
`signal_analysis`, and `forward_ir` keys, and the same owner also publishes
the nested `explicit_system_contract`, `signal_analysis`, `system_contract`,
`forward_ir`, and optional `symbol_contract` plus `composition` key lists.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the shell-owned semantic payload and child extension
key families from one place instead of collecting those field-family lists
separately.
That same payload contract now also publishes a grouped
`nested_presence_key_map`, and the public normalized semantic report contract
that advertises it now also publishes the same grouped child families as
`semantic_nested_presence_key_map`, so embedders can discover the deeper
semantic child key families from one place instead of reconstructing them
from separate `success_*` lists.
The public normalized semantic report now also republishes the payload
owner's grouped shell-family view as `semantic_presence_key_family_map`, so
embedders can discover the shell-owned semantic payload and child-extension
families from one place instead of reconstructing them from separate
`success_*` fields.
The bounded `semantic.forward_ir` shell now also publishes its own grouped
`nested_presence_key_map`, and both the nested payload contract and the
public normalized semantic report now republish that grouped view as
`forward_ir_nested_presence_key_map`, so embedders can discover the deeper
`intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` key families without
reconstructing them from separate `success_forward_ir_*` lists.
That same payload contract, and the public normalized semantic report contract
that advertises it, now also publish a grouped
`forward_ir_nested_contract_source_map` so embedders can discover the deeper
`intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` shell owners without
reconstructing them from parallel scalar owner fields.
The public normalized semantic report contract now also publishes a grouped
`nested_presence_key_map` so embedders can discover the primary nested object
key families for `command`, `failure_diagnostic`, `generated_output`,
`producer`, `source`, report-level `support_accounting`, and the success-side
semantic branches from one place, while the matched overlays and optional
failure-diagnostic artifacts remain explicitly advertised as separate bounded
key families.
That same shell now also publishes a grouped `presence_key_family_map` so
embedders can discover the shell-owned shared-report, success, and failure
key families from one place instead of collecting those normalized semantic
field-family lists separately.
At the manifest-facing semantic-exports-section level, FSMGen now also
publishes a grouped `nested_presence_key_map` so downstream tools can
discover the bounded key family for `normalized_semantic_json` from one place
before descending into that child contract.
The nested `semantic.signal_analysis` summary inside that payload now also has
its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm](perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm)
owns the current sanitized signal-family projection keys plus the shared core
signal-entry keys emitted across direct and composition roots.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded signal-analysis bucket and entry key
families from one place instead of collecting the individual field-family
lists separately.
The nested `semantic.explicit_system_contract` summary inside that payload now
also has its own bounded nested-object contract when the authored explicit
contract is preserved:
[perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm](perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm)
owns the current authored explicit clock/reset projection keys through one
real built nested-object contract, not just parallel helper lists.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded explicit clock, reset-identity, and
reset-metadata key families from one place instead of collecting the
individual key-family lists separately.
The nested `semantic.system_contract` summary inside that payload now also has
its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticSystemContract.pm](perl/FSM/Support/NormalizedSemanticSystemContract.pm)
owns the current clock/reset/system-contract projection keys through one real
built nested-object contract, not just parallel helper lists.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded clock, reset-identity, reset-metadata,
and system-behavior key families from one place instead of collecting the
individual key-family lists separately.
The nested `semantic.forward_ir` summary inside that payload now also has its
own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](perl/FSM/Support/NormalizedSemanticForwardIRContract.pm)
owns the current sanitized forward semantic projection keys.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the shell-owned `forward_ir` and child
composition-only extension key families from one place instead of collecting
those field-family lists separately.
The nested `semantic.forward_ir.lowered_rtl_ir` summary inside that branch now
also has its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm)
owns the current lowered-RTL shell keys plus the composition-only extension
keys emitted today for top roots.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded `lowered_rtl_ir` key families from one
place instead of collecting the individual field-family lists separately.
The nested `semantic.forward_ir.structural_rtl_ir` summary inside that branch
now also has its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm)
owns the current structural-RTL shell keys shared by direct and composition
roots.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded structural-RTL shell summary and
collection key families from one place instead of collecting the individual
key-family lists separately.
The nested `semantic.forward_ir.intent_hir` summary inside that branch now
also has its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm)
owns the current intent-hir shell keys plus the composition-only extension
keys emitted today for top roots.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded `intent_hir` key families from one place
instead of collecting the individual field-family lists separately.
The optional `semantic.symbol_contract` summary inside that payload now also
has its own bounded nested-object contract for symbol-rich sources:
[perl/FSM/Support/NormalizedSemanticSymbolContract.pm](perl/FSM/Support/NormalizedSemanticSymbolContract.pm)
owns the published symbol-contract key family.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded symbol-contract summary, name-list,
nested-map, constant-detail, and package-import key families from one place
instead of collecting the individual key-family lists separately.
The nested `semantic.module` summary inside that payload now also has its own
bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticModuleContract.pm](perl/FSM/Support/NormalizedSemanticModuleContract.pm)
owns the core module-summary keys plus the current optional metric-key family.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded semantic.module key families from one
place instead of collecting the individual field-family lists separately.
The nested `semantic.composition` summary inside that payload now also has its
own bounded nested-object contract for composition sources:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](perl/FSM/Support/NormalizedSemanticCompositionContract.pm)
owns the composition key family while keeping nested provenance-report
ownership delegated to
[perl/FSM/Support/CompositionReportContract.pm](perl/FSM/Support/CompositionReportContract.pm).
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded composition summary, collection, and
nested provenance key families from one place instead of collecting the
individual key-family lists separately.

Do not treat the raw `HDLGenerator` result hash as a stable JSON document. Some
nested branches still contain live CoreAST/AST objects for compatibility and
in-process tooling. If you need sanitized machine interchange, use
`--emit-semantic-json` or the `FSM::Support::NormalizedSemanticReport` surface
instead.

Composition provenance has one more important split:

- raw `fsm_module` is a live CoreAST object and is not a public JSON API
- raw `raw_ast` is a parser/debug artifact and is not a public interchange API
- raw `composition_spec` is a live parsed composition object and is not a
  public JSON API
- raw `composition_report` is useful for in-process Perl tooling, but it can
  still contain private live objects in nested endpoint contexts
- raw `composition_plan` is a live planning object and is not a public JSON API
- normalized semantic JSON exposes the sanitized
  `semantic.composition.provenance_report` fragment for downstream tools

That fragment preserves bounded public report facts such as the composition
lane, top-port and resolved-link counts, provenance origin counts, ordered
origin/kind lists, ports, resolved links, override events, and block events,
while stripping private Perl objects before JSON emission.

On the current live path, `structural_rtl_ir` instance bindings are not just
flat signal names anymore. They can preserve:

- `connection_expr` for the structural source shape
- `connection_type_name` when a binding reuses a declared named type alias
- `connection_type_spec` when the planner already knows the typed signal,
  expression, or whole-aggregate actual contract

That means embedding tools can inspect whether a binding came from a plain
typed signal, an inferred list-like concat/repeat expression, or a whole
aggregate actual root without reconstructing that meaning from packed width
alone.

Composition provenance endpoint contexts also preserve typed aggregate source
expression facts. For example, `in_frame.tag` and
`producer.OUT_FRAME.payload[1]` report the resolved aggregate leaf width/type
when their base endpoint carries a declared aggregate type, rather than forcing
embedders to infer that path from string spelling or whole-base widths.

On the composition side, `module_info.composition_shared_datapath_candidates`
also now preserves declared type contracts conservatively:

- width-equal typed child-output families do not collapse into one candidate
  when their declared type contracts disagree
- uniform typed shared-datapath families preserve one candidate-level declared
  type contract
- and the raw contributor nets synthesized during shared-datapath lifting keep
  contributor-side declared type identity in the structural export
- lifted shared runtime carriers such as `*_shared_q`, `*_shared_next`, and
  `*_shared_comb` now also live in that structural net surface with an explicit
  declaration kind instead of existing only as declaration text in auxiliary
  HDL sections

That is already useful for downstream tooling while the long-term public
embedding/API stabilization lane (`R13`) is active but not fully frozen yet.

## Important Boundary

Today, programmatic embedding exists, but it is not yet declared a fully frozen
public API.

That means:

- useful now for internal tooling and serious integration work
- not yet promised as a permanently stable contract forever

The active `R13` lane is where that public stabilization work is being
graduated from useful internal seams into deliberate public contracts.

The capability manifest's `semantic_exports` section now has that same
bounded split too:

- `FSM::Support::CapabilityManifest` still publishes the current semantic
  export surfaces
- `FSM::Support::SemanticExportsContract` owns the bounded top-level plus
  nested contract-owner map advertised through `semantic_exports.section_contract`
- deeper semantic payload meaning stays with narrower dedicated contracts such
  as `FSM::Support::NormalizedSemanticReportContract`

The emitted `semantic_exports` section itself is now built through
[perl/FSM/Support/SemanticExportsSection.pm](perl/FSM/Support/SemanticExportsSection.pm)
and runtime-locked as an exact dedicated-builder projection across both
in-process and CLI manifest surfaces. That keeps the current bounded
`normalized_semantic_json` export plus its manifest-context support-accounting
coverage promises in one place instead of leaving that public section as
duplicated inline manifest assembly logic.

## Downstream Tool Alignment

FSMGen now keeps a tracked response to SPECFORGE's `.fsm` adapter feedback:

- [SPECFORGE_FEEDBACK_RESPONSE.md](../../SPECFORGE_FEEDBACK_RESPONSE.md)

That response accepts the broad direction that FSMGen should become a precise
`.fsm` contract authority for downstream tools:

- strict mode as the preferred generated-`.fsm` target,
- a capability manifest generated from support-accounting truth,
- stable diagnostic codes plus bounded check-only JSON diagnostics,
- bounded normalized semantic JSON export,
- stronger clock/reset contract metadata,
- and later checked metadata for actor roles, channel grouping, semantic signal
  roles, temporal/stability contracts, and provenance/residuals.

Those surfaces are not all implemented yet. They are intentionally staged
behind support accounting, diagnostics, and the active `R13` public embedding
lane so adapter-facing contracts can be regression-backed instead of merely
documented.

The first bounded machine-readable surface is now:

```bash
./bin/fsmgen --capability-manifest
```

It emits schema-versioned JSON from `FSM::Support::CapabilityManifest`, backed
by `FSM::Support::RegressionCorpus` and `FSM::Support::DiagnosticCodes`. Treat
this as a conservative support manifest, not yet as a full normalized semantic
export. It can already tell downstream tools which expected-failure corpus
entries carry stable diagnostic codes, which stable codes exist, and which
bounded check-JSON command shape is public. It also advertises that check JSON
emits support-accounting objects and that supported-smoke, strict-supported,
and expected-failure coverage are locked across the current corpus. The same
manifest now advertises supported-smoke, strict-supported, and expected-failure
coverage for the bounded normalized semantic JSON surface. It also advertises
the bounded typed-extension/context contract, the bounded sanitized composition
report contract, and the bounded `HDLGenerator` result contract for in-process
embedders, while making clear that the raw result hash is not JSON-safe as a
whole. It also advertises the optional external SystemVerilog validation lane:
`--verify-hdl` / `--validate-hdl` writes generated `.sv` and then runs
Verilator lint plus ABC-free Yosys structural synthesis when those tools are
installed.
The public `support_accounting` match objects emitted by both `--check --json`
and `--emit-semantic-json` now share one bounded nested-object owner too:
[perl/FSM/Support/SupportAccountingMatchContract.pm](perl/FSM/Support/SupportAccountingMatchContract.pm).
The manifest's `support_accounting` section now has its own bounded contract
owner too:
[perl/FSM/Support/SupportAccountingContract.pm](perl/FSM/Support/SupportAccountingContract.pm).
That keeps the top-level support counts, id lists, and sanitized catalog-entry
key set discoverable as an explicit contract instead of only as sample output.
The stable diagnostic-code registry now follows the same pattern:
[perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm)
owns the production registry, while
[perl/FSM/Support/DiagnosticCodeRegistryContract.pm](perl/FSM/Support/DiagnosticCodeRegistryContract.pm)
owns the bounded manifest-facing sibling-key and stable-entry-key promise.
That same owner now also publishes grouped `key_family_map` and
`bounded_value_family_map` views so downstream tools can discover the bounded
registry key families and allowed value families from one place instead of
collecting those lists separately.
The in-process registry helpers also deliberately return defensive copies:
downstream code may inspect and transform those returned hashes locally, but it
must not expect mutations to feed back into FSMGen’s canonical stable-code
registry.
The manifest shell now follows the same split too:
[perl/FSM/Support/CapabilityManifest.pm](perl/FSM/Support/CapabilityManifest.pm)
builds the JSON, while
[perl/FSM/Support/CapabilityManifestContract.pm](perl/FSM/Support/CapabilityManifestContract.pm)
owns the bounded top-level and first nested section key lists advertised under
top-level `manifest_contract`.
The whole top-level public section fleet is now regression-locked as dedicated
`*Section.pm` builders too: [t/369-manifest-section-builder-audit.t](t/369-manifest-section-builder-audit.t)
discovers the section-builder modules, proves that the discovered set exactly
matches the manifest’s public top-level sections, and then checks that each
section stays an exact dedicated-builder projection across the in-process
manifest and both CLI spellings.
The grouped top-level discovery tables published by `manifest_contract` are now
runtime-locked too: [t/370-capability-manifest-section-discovery-audit.t](t/370-capability-manifest-section-discovery-audit.t)
proves that `top_level_contract_source_map` and
`top_level_section_presence_key_map` stay aligned with the real section
builders and with the live manifest payloads exposed through the in-process
builder plus both CLI spellings.
That runtime boundary is now locked directly too: the emitted
`--capability-manifest` and `--emit-capability-manifest` JSON must match the
in-process `build_capability_manifest()` output exactly. The embedded
`manifest_contract`, every `*.section_contract`, `language_surface.surface_contract`,
`diagnostics.stable_code_registry`, and the exact embedding children
`composition_report`, `hdl_generator_facade`, `hdl_generator_result`,
`typed_extensions`, and `debug_runtime` are now treated as literal
dedicated-builder pass-throughs.
Only three advertised
manifest children are intentionally enriched beyond their dedicated builders:
`diagnostics.check_json`, `semantic_exports.normalized_semantic_json`, and
`backend_validation.systemverilog_external`, and those enrichments are
runtime-locked to a small documented set of manifest-context fields rather than
left as open-ended widening.
Those three enrichments now also have explicit section-owned builders in
[perl/FSM/Support/DiagnosticsSection.pm](perl/FSM/Support/DiagnosticsSection.pm),
[perl/FSM/Support/SemanticExportsSection.pm](perl/FSM/Support/SemanticExportsSection.pm),
and
[perl/FSM/Support/BackendValidationSection.pm](perl/FSM/Support/BackendValidationSection.pm),
so the runtime parity audit reuses the same named manifest-surface builders
instead of reconstructing those bounded enrichments inline.
Published `tested_by` provenance is now repo-checked too:
[t/381-contract-tested-by-provenance-audit.t](t/381-contract-tested-by-provenance-audit.t)
walks the direct support contracts plus the in-process and CLI manifest
surfaces, finds every public `tested_by` list, and requires each entry to stay
a relative existing `t/*.t` file under this repository.
Published module provenance is repo-checked as well:
[t/382-contract-module-provenance-audit.t](t/382-contract-module-provenance-audit.t)
walks the direct support contracts plus the in-process and CLI manifest
surfaces, finds public module-reference fields such as `contract_source`,
`*_contract_source_map`, `implementation_owners`, `report_sources`,
`report_builder`, and `registry_source`, and requires each value to be a
loadable `FSM::...` module present under `perl/`.
Grouped discovery maps now have the same generic guard:
[t/383-contract-family-map-integrity-audit.t](t/383-contract-family-map-integrity-audit.t)
walks direct contracts plus manifest outputs and requires maps such as
`presence_key_family_map`, `nested_presence_key_map`,
`constructor_option_family_map`, `name_family_map`, and `family_map` to stay
hashes of non-empty unique scalar lists, aligned with same-named sibling lists
when the sibling exists.
That shell contract now also explicitly lists the first nested
`support_accounting` keys, so embedders can discover the corpus-backed section
shape without a manifest-specific exception.
The `support_accounting` section now also exposes that same bounded owner
through `support_accounting.section_contract`.
That section shell now also publishes a grouped `presence_key_family_map` so
downstream tools can discover the bounded bucket, id-list, and catalog-entry
key families from one place instead of collecting those support-accounting key
families field by field.
The emitted `support_accounting` section is now also built through
[perl/FSM/Support/SupportAccountingSection.pm](perl/FSM/Support/SupportAccountingSection.pm)
and runtime-locked as an exact dedicated-builder projection across both
in-process and CLI manifest surfaces.
That projection is also runtime-locked against corpus truth: the emitted
`support_accounting` section must stay an exact bounded projection of
[perl/FSM/Support/RegressionCorpus.pm](perl/FSM/Support/RegressionCorpus.pm),
including the derived bucket counts, ordered id lists, sanitized catalog
entries, and the embedded exact `section_contract` copy. In other words, this
section is not just “shape compatible”; it is deliberately tied to maintained
regression-corpus truth.
Those published catalog paths are now checked against the real repository too:
[t/372-support-accounting-catalog-path-audit.t](t/372-support-accounting-catalog-path-audit.t)
proves that every public `catalog_entries[*].relpath` stays relative and
present on disk as a file, every published `search_path_relpaths` entry stays
relative and present as a directory, and the public derived id lists stay
unique and catalog-backed across the in-process manifest plus both CLI
spellings.
The `embedding` section now follows the same split too:
[perl/FSM/Support/EmbeddingContract.pm](perl/FSM/Support/EmbeddingContract.pm)
owns the published top-level and nested contract-owner map advertised through
`embedding.section_contract`, while the narrower result, composition-report,
serializable plan/report, facade, typed-extension, and debug-runtime contracts
still own their deeper public promises.
The emitted `embedding` section itself is now built through
[perl/FSM/Support/EmbeddingSection.pm](perl/FSM/Support/EmbeddingSection.pm)
and runtime-locked as an exact dedicated-builder projection across both
in-process and CLI manifest surfaces. That keeps the grouped
`composition_report`, `hdl_generator_facade`, `hdl_generator_result`,
`serializable_plan_reports`, `typed_extensions`, and `debug_runtime` child
contracts in one place instead of leaving that public section as duplicated
inline manifest assembly logic.
The `hdl_generator_facade` child also has a constructor-boundary audit in
[t/377-hdl-generator-constructor-boundary-audit.t](t/377-hdl-generator-constructor-boundary-audit.t),
so new constructor arguments cannot quietly appear without being classified as
bounded public facade options, internal owner-injection options, or
non-public extension-loading options.
That section shell now also publishes a grouped `nested_presence_key_map` so
downstream tools can discover the bounded child key families for
`composition_report`, `hdl_generator_facade`, `hdl_generator_result`,
`serializable_plan_reports`, `typed_extensions`, and `debug_runtime` from one
place before descending into those narrower contracts.
The `diagnostics` section now follows the same split too:
[perl/FSM/Support/DiagnosticsContract.pm](perl/FSM/Support/DiagnosticsContract.pm)
owns the published top-level, scalar-string, and stable-code entry families
advertised through `diagnostics.section_contract`, while the narrower stable
registry and check-JSON contracts still own their deeper public promises.
The emitted `diagnostics` section itself is now built through
[perl/FSM/Support/DiagnosticsSection.pm](perl/FSM/Support/DiagnosticsSection.pm)
and runtime-locked as an exact dedicated-builder projection across both
in-process and CLI manifest surfaces. That keeps the grouped stable registry,
bounded manifest-context `check_json`, and section contract in one place
instead of leaving that public section as duplicated inline manifest assembly
logic.
That section shell now also publishes a grouped `presence_key_family_map` so
downstream tools can discover the bounded diagnostics-owned scalar-string,
list, and stable-code entry key families from one place instead of collecting
those diagnostics key families separately.
That section is now runtime-locked against diagnostic-registry truth too: the
emitted `stable_codes` list must stay an exact ordered projection of
[perl/FSM/Support/DiagnosticCodes.pm](perl/FSM/Support/DiagnosticCodes.pm),
while `diagnostics.stable_code_registry` stays the exact dedicated registry
contract and `diagnostics.check_json` stays the exact dedicated check-report
contract plus only its documented bounded manifest-context fields. This keeps
the diagnostics section machine-trustworthy without pretending the whole
downstream check-report payload is frozen inside the manifest.
The `producer` section now follows the same split too:
[perl/FSM/Support/ProducerContract.pm](perl/FSM/Support/ProducerContract.pm)
owns the published top-level, scalar-string, and boolean field families
advertised through `producer.section_contract`, while the broader producer
story stays limited to current tool/build identity rather than becoming an
accidental release-management API.
The emitted `producer` section itself is now built through
[perl/FSM/Support/ProducerSection.pm](perl/FSM/Support/ProducerSection.pm)
and runtime-locked as an exact dedicated-builder projection across both
in-process and CLI manifest surfaces. That keeps the current tool identity,
best-effort git hash, and bounded `source`/`section_contract` payload in one
place instead of leaving that public section as duplicated inline manifest
assembly logic.
That section shell now also publishes a grouped `presence_key_family_map` so
downstream tools can discover the bounded scalar-string and boolean key
families from one place instead of collecting those producer key families
field by field.
The `backend_validation` section now follows the same split too:
[perl/FSM/Support/BackendValidationContract.pm](perl/FSM/Support/BackendValidationContract.pm)
owns the published top-level and nested contract-owner map advertised through
`backend_validation.section_contract`, while the narrower
`HDLExternalValidationContract` still owns the deeper validation-lane promise.
The emitted `backend_validation` section itself is now built through
[perl/FSM/Support/BackendValidationSection.pm](perl/FSM/Support/BackendValidationSection.pm)
and runtime-locked as an exact dedicated-builder projection across both
in-process and CLI manifest surfaces. That keeps the current bounded
`systemverilog_external` lane plus its manifest-context regression-smoke claim
in one place instead of leaving that public section as duplicated inline
manifest assembly logic.
That section shell now also publishes a grouped `nested_presence_key_map` so
downstream tools can discover the bounded child key family for
`systemverilog_external` from one place before descending into the narrower
validation contract.
The `language_surface` section now has its own bounded owner as well:
[perl/FSM/Support/LanguageSurfaceContract.pm](perl/FSM/Support/LanguageSurfaceContract.pm)
advertises the public top-level and first nested section-key lists through
`language_surface.surface_contract`, while the broader authored-language
surface still widens only when new claims are regression-backed deliberately.
The emitted `language_surface` section itself is now built through
[perl/FSM/Support/LanguageSurfaceSection.pm](perl/FSM/Support/LanguageSurfaceSection.pm)
and runtime-locked as an exact dedicated-builder projection across both
in-process and CLI manifest surfaces. That keeps the current authored strict
mode, compatibility, expression, declaration, and composition guidance in one
place while preserving the contract rule that the broader language surface is
still widened only by deliberate regression-backed changes.
That section shell now also publishes a grouped `nested_presence_key_map` so
downstream tools can discover the bounded first nested key families for
`strict_mode`, `default_mode_compatibility`, `assignments`,
`system_contracts`, `expressions`, `declarations`, and `composition` from one
place before descending into those nested language-surface sections.
The `documentation` section now has its own bounded owner too:
[perl/FSM/Support/DocumentationContract.pm](perl/FSM/Support/DocumentationContract.pm)
advertises the public top-level and path-list keys through
`documentation.section_contract`, while the exact documentation file lists stay
deliberately widenable.
The emitted `documentation` section itself is now built through
[perl/FSM/Support/DocumentationSection.pm](perl/FSM/Support/DocumentationSection.pm)
and runtime-locked as an exact dedicated-builder projection across both
in-process and CLI manifest surfaces. That keeps the current grouped path
lists in one place while preserving the documented rule that those exact lists
may still widen deliberately over time.
Those published path lists are now runtime-checked against the real repository
too: [t/371-documentation-path-existence-audit.t](t/371-documentation-path-existence-audit.t)
proves that every published documentation path remains relative, unique, and
present on disk under the repo root across the in-process manifest and both
CLI spellings.
That section shell now also publishes a grouped `path_list_contract_map` so
downstream tools can discover the bounded path-list families for
`human_contract` and `downstream_alignment` from one place before consuming
those documentation path lists.
That lane is currently SystemVerilog-only; VHDL/GHDL validation waits for an
active VHDL backend.
The bounded contract for that lane now has its own owner too:
[perl/FSM/Support/HDLExternalValidationContract.pm](perl/FSM/Support/HDLExternalValidationContract.pm).
The capability manifest advertises the command shape, tool identities, stage
names, and bounded success result/step keys for embedders that want the same
post-emission gate without reverse-engineering sample output.
That same contract now also publishes a grouped
`success_presence_key_family_map` so embedders can discover the bounded
success top-level and step key families from one place instead of collecting
those success key lists separately.
It now also publishes bounded `failure_mode_names`,
`failure_mode_family_map`, and `failure_text_prefix_map` values so embedders
can distinguish input-side failures such as missing tools or missing source
paths from tool-step failures without pretending the full thrown stdout/stderr
payload is itself a frozen schema.

The first bounded check/diagnostic surface is now:

```bash
./bin/fsmgen --strict --check --json path/to/file.fsm
```

It emits schema-versioned JSON to stdout and writes no HDL. Matched
expected-failure diagnostics include the stable `FSMGEN_*` code and the matched
support-accounting entry. The nested `support_accounting` object is the
preferred machine-readable bridge back to corpus truth. Unclassified failures
keep a `null` code until their family is deliberately promoted into the stable
registry. Accepted corpus entries are covered too: supported-smoke entries must
succeed through `--check-json`, and strict-supported entries must succeed
through `--strict --check-json`. When a successful check matches a non-failure
corpus entry by resolved source path, the report-level `support_accounting`
object gives embedders the matched entry id, family, coverage, classification,
source kind, and `strict_supported` marker. Successful user sources outside the
corpus report `matched: false` instead of claiming catalog support they do not
yet have.
Unclassified failures follow the same honesty rule: they still keep the
bounded failure-diagnostic and nested `support_accounting` object shape, but
they omit matched-only fields and keep `matched: false` until that failure
family is deliberately promoted into the stable corpus-backed registry.
The bounded key-presence contract for this surface now has its own owner:
[perl/FSM/Support/CheckDiagnosticsContract.pm](perl/FSM/Support/CheckDiagnosticsContract.pm).
The capability manifest advertises that contract so downstream tools can
discover the common top-level keys plus the current bounded success-result and
failure-diagnostic keys without relying only on narrative docs or reverse-
engineering sample payloads.

The first bounded normalized semantic surface is now:

```bash
./bin/fsmgen --strict --emit-semantic-json path/to/file.fsm
```

`--semantic-json` is the short alias. The command runs the full generation
pipeline, emits schema-versioned JSON to stdout, and writes no HDL file even
when `-o` is present. Successful reports expose:

- `normalized_semantic_schema_version: 1`
- `command.mode: semantic_export`
- a report-level `support_accounting` object
- a `semantic.module` summary
- `semantic.system_contract`
- sanitized `semantic.signal_analysis`
- optional `semantic.symbol_contract` for symbol-rich sources
- `semantic.forward_ir.intent_hir`
- `semantic.forward_ir.lowered_rtl_ir`
- `semantic.forward_ir.structural_rtl_ir`
- `semantic.composition.provenance_report` for composition sources

The important word is "sanitized". This surface does not dump private Perl
objects such as live AST nodes or `FSM::CoreAST::Signal` instances, and it does
not include generated HDL text. It projects scalar/list/hash metadata that
downstream tools can consume without depending on private runtime object
identity. Failed semantic exports reuse the same stable diagnostic-code and
support-accounting bridge as `--check-json`, return non-zero, and do not expose
partial semantics.
When a semantic failure does not match a promoted corpus-backed diagnostic
family, the report still keeps its bounded top-level `support_accounting`
object with `matched: false`, while the failure diagnostic keeps `code: null`
and omits matched-only fields.
Successful composition semantic exports now also recover a bounded effective
`system_contract` when the realized child roots agree on one clock/reset
contract and the top actually exposes those system-port names, even if the top
itself did not author `+system`. In that case `semantic.system_contract`
preserves the shared child clock/reset/reset-policy fields with
`implicit: true`, while `semantic.explicit_system_contract` stays `null`
unless the composition top explicitly authored a system contract.

Accepted corpus entries are covered too. Every current supported-smoke entry
must succeed through `--emit-semantic-json`, and every current strict-supported
entry must succeed through `--strict --emit-semantic-json`, while preserving
matched support-accounting identity, expected module/top identity, sanitized
forward-IR projections, and no HDL emission.

Rejected corpus entries are covered too. Every current expected-failure entry
must reject through `--emit-semantic-json`, using the same strict/default
routing as check JSON, while preserving the stable diagnostic code and matched
support-accounting identity, omitting partial semantic payloads, and writing no
HDL.

The bounded key-presence contract for this public surface now has its own owner:
[perl/FSM/Support/NormalizedSemanticReportContract.pm](perl/FSM/Support/NormalizedSemanticReportContract.pm).
The capability manifest advertises that contract so downstream tools can
discover the current top-level and bounded nested success/composition keys
without relying only on narrative docs or reverse-engineering sample payloads.
Those same normalized-semantic child-owner contracts are now also checked
against real successful runtime payloads on both sides of the surface:
symbol-rich direct roots and composition roots. That keeps the shipped child
contracts honest against the actual emitted `semantic.module`,
`semantic.system_contract`, `semantic.explicit_system_contract`,
`semantic.signal_analysis`, `semantic.forward_ir`, optional
`semantic.symbol_contract`, and optional `semantic.composition` branches,
instead of relying only on static helper-family consistency.
The same runtime-audit stance now also covers the bounded in-process
`HDLGenerator` leaf owners for `source_info`, `module_info`, and `statistics`.
Real direct and composition generation results are checked against the shipped
leaf-owner key families, and the `source_info` audit also locks authored
package-import summaries on both direct and composition roots. That keeps the
leaf contracts tied to what embedders actually receive in-process instead of
only to static helper lists.
The same hardening now also covers the shell-only `HDLGenerator`
compatibility branches. Real direct and composition generation results are now
checked so `fsm_module`, `raw_ast`, `resolved_package_imports`,
`composition_spec`, `composition_plan`, and raw `composition_report` keep the
published runtime shape they still advertise for in-process compatibility, and
their documented fallback surfaces are checked too. In particular, the raw
composition provenance report is now locked against the normalized semantic
JSON `semantic.composition.provenance_report` fragment, so the branch/fallback
story is regression-backed instead of only narrated.
The public report shells themselves are now runtime-checked too. Real
`--check-json` success and matched-failure payloads are checked against the
bounded check-report shell families, and real `--emit-semantic-json` success
and matched-failure payloads are checked against the bounded normalized
semantic shell families. That keeps the top-level public report contract
honest at runtime, not only the nested leaves and child-owner surfaces.

This is still a bounded public slice, not the final full semantic export. Wider
expression, state/DT control-shape, assignment/guard, package/type, and
provenance fields should graduate only when they are backed by regression
coverage and support-accounting truth.

## Legacy External Flow

Some environments may still use the external compatibility script flow:

```bash
perl generate_fsm_hdl.pl --debug /path/to/input.fsm -o output.sv
```

Treat that as environment-specific compatibility, not the main forward surface.

## Where To Go Deeper

For the exact extension boundary and design notes, see:

- [EXTENSION_MODEL.md](../../EXTENSION_MODEL.md)
- [ROADMAP_STATUS.md](../../ROADMAP_STATUS.md)
