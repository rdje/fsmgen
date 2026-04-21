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
- the rule that extension modules loaded by name must provide `new()`
- and the deliberate absence of legacy `.plg` discovery, automatic directory
  discovery, and `AUTOLOAD` hook dispatch

The current context accessors are:

- `stage`
- `pipeline`
- `source_path`
- `target_language`
- `source_info`
- `raw_ast`
- `result`

`raw_ast` is available on `after_parse_source`. `result` is available on
`after_generate_result`. Result augmentation is a valid in-process extension
use, but it is not the same thing as publishing a new sanitized JSON
interchange field.

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
The top-level `resolved_package_imports` branch is therefore shell-only: it is
still a hash of raw `FSM::Package::Spec` objects, so stable package-import
inspection should use `source_info.package_import_count` and
`source_info.package_import_names` instead of traversing those typed values.
That shell-only branch now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLGeneratorResolvedPackageImportsContract.pm),
which is the contract to follow for the raw package-spec-map rule plus that
bounded package-import summary surface.
The top-level `fsm_module` branch is shell-only too when it is defined: it is a
raw `FSM::CoreAST::FSMModule` object kept for in-process compatibility, so
structured downstream consumers should prefer `intent_hir`, `lowered_rtl_ir`,
`structural_rtl_ir`, or normalized semantic JSON. That shell-only branch now
also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorFSMModuleContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLGeneratorFSMModuleContract.pm),
which is the contract to follow for the raw CoreAST-object rule plus the
semantic-summary fallback surfaces. The top-level `raw_ast`
branch is likewise shell-only and intentionally treated as a frontend/debug
artifact rather than a public interchange tree, so structured consumers should
prefer `intent_hir` instead of binding themselves to parser-level arrays. That
shell-only branch now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorRawASTContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLGeneratorRawASTContract.pm),
which is the contract to follow for the parser/debug-array rule plus the
`intent_hir` fallback surface.
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
The nested `source_info` object now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorSourceInfoContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLGeneratorSourceInfoContract.pm),
which is the contract to follow for `header`, `kind`,
`package_import_count`, and `package_import_names`.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded identity and summary source-info key
families from one place instead of collecting those key lists separately.
The nested `module_info` object now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorModuleInfoContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLGeneratorModuleInfoContract.pm),
which is the contract to follow for `module_name`,
`source_root_kind`, the direct-root scalar summary keys, and the
composition-only scalar summary keys.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded identity, summary, and composition-only
module-info key families from one place instead of collecting those key lists
separately.
The nested `statistics` object now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorStatisticsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLGeneratorStatisticsContract.pm),
which is the contract to follow for the direct-root scalar summary keys and
the composition-only scalar summary keys.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded summary and composition-only statistics
key families from one place instead of collecting those key lists
separately.
The top-level `intent_hir`, `lowered_rtl_ir`, and `structural_rtl_ir` hashes
follow the same honesty rule: they reuse the dedicated normalized-semantic
shell owners and their advertised shell keys, but the `HDLGenerator` result
contract does not treat those top-level hashes as separately stabilized full
trees beyond those shell boundaries.
The composition-only `composition_spec` and `composition_plan` branches are
shell-only too: they are raw `FSM::Composition::Spec` and
`FSM::Composition::Plan` objects kept for in-process compatibility. The
`composition_spec` branch now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLGeneratorCompositionSpecContract.pm),
which is the contract to follow for the raw composition-spec rule plus the
sanitized composition-summary fallback surfaces. The `composition_plan` branch
now also has its own explicit owner through
[perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLGeneratorCompositionPlanContract.pm),
which is the contract to follow for the raw composition-plan rule plus the
same sanitized composition-summary fallback surfaces. Raw
`composition_report` is likewise an in-process compatibility hash rather than
a serializable public JSON surface, so embedders should follow
[perl/FSM/Support/CompositionReportContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CompositionReportContract.pm)
and the sanitized
`semantic.composition.provenance_report` fragment for downstream interchange.
The public `support_accounting` match objects emitted beside those reports also
share one bounded nested-object contract:
[perl/FSM/Support/SupportAccountingMatchContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/SupportAccountingMatchContract.pm)
owns the common `matched` key plus the matched success/failure identity keys
used by check JSON and normalized semantic JSON.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded support-accounting key families from one
place instead of collecting the individual field-family lists separately.
Those same public check JSON and normalized semantic JSON reports now also
share one bounded nested-object contract for producer identity:
[perl/FSM/Support/ReportProducerContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportProducerContract.pm)
owns the shared `name` plus `report_source` keys, while normalized semantic
JSON adds the bounded `semantic_layers` extension documented by that same
owner.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded producer key families from one place
instead of collecting the individual field-family lists separately.
Those same public check JSON and normalized semantic JSON reports now also
share one bounded nested-object contract for the caller-facing source identity:
[perl/FSM/Support/ReportSourceContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportSourceContract.pm)
owns the shared `input` plus `resolved_path` keys emitted under the nested
`source` object.
Those same public check JSON and normalized semantic JSON reports now also
share one bounded nested-object contract for invocation metadata:
[perl/FSM/Support/ReportCommandContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportCommandContract.pm)
owns the shared `mode`, `json`, `strict_mode`, and `target_language` keys
emitted under the nested `command` object.
Those same public check JSON and normalized semantic JSON reports now also
share one bounded nested-object contract for HDL-emission side effects:
[perl/FSM/Support/ReportGeneratedOutputContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportGeneratedOutputContract.pm)
owns the shared `emitted` key emitted under the nested `generated_output`
object.
Successful public check JSON reports now also have one bounded nested-object
contract for the compact success summary:
[perl/FSM/Support/CheckResultContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CheckResultContract.pm)
owns the `module_name`, `state_count`, `signal_count`, and
`composition_child_count` keys emitted under the nested `result` object.
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
[perl/FSM/Support/CheckFailureDiagnosticContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CheckFailureDiagnosticContract.pm)
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
[perl/FSM/Support/NormalizedSemanticPayloadContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticPayloadContract.pm)
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
[perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm)
owns the current sanitized signal-family projection keys plus the shared core
signal-entry keys emitted across direct and composition roots.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded signal-analysis bucket and entry key
families from one place instead of collecting the individual field-family
lists separately.
The nested `semantic.explicit_system_contract` summary inside that payload now
also has its own bounded nested-object contract when the authored explicit
contract is preserved:
[perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm)
owns the current authored explicit clock/reset projection keys.
The nested `semantic.system_contract` summary inside that payload now also has
its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticSystemContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticSystemContract.pm)
owns the current clock/reset/system-contract projection keys.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded clock, reset-identity, reset-metadata,
and system-behavior key families from one place instead of collecting the
individual key-family lists separately.
The nested `semantic.forward_ir` summary inside that payload now also has its
own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticForwardIRContract.pm)
owns the current sanitized forward semantic projection keys.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the shell-owned `forward_ir` and child
composition-only extension key families from one place instead of collecting
those field-family lists separately.
The nested `semantic.forward_ir.lowered_rtl_ir` summary inside that branch now
also has its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm)
owns the current lowered-RTL shell keys plus the composition-only extension
keys emitted today for top roots.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded `lowered_rtl_ir` key families from one
place instead of collecting the individual field-family lists separately.
The nested `semantic.forward_ir.structural_rtl_ir` summary inside that branch
now also has its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm)
owns the current structural-RTL shell keys shared by direct and composition
roots.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded structural-RTL shell summary and
collection key families from one place instead of collecting the individual
key-family lists separately.
The nested `semantic.forward_ir.intent_hir` summary inside that branch now
also has its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm)
owns the current intent-hir shell keys plus the composition-only extension
keys emitted today for top roots.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded `intent_hir` key families from one place
instead of collecting the individual field-family lists separately.
The optional `semantic.symbol_contract` summary inside that payload now also
has its own bounded nested-object contract for symbol-rich sources:
[perl/FSM/Support/NormalizedSemanticSymbolContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticSymbolContract.pm)
owns the published symbol-contract key family.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover the bounded symbol-contract summary, name-list,
nested-map, constant-detail, and package-import key families from one place
instead of collecting the individual key-family lists separately.
The nested `semantic.module` summary inside that payload now also has its own
bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticModuleContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticModuleContract.pm)
owns the core module-summary keys plus the current optional metric-key family.
That same owner now also publishes a grouped `presence_key_family_map` so
embedders can discover those bounded semantic.module key families from one
place instead of collecting the individual field-family lists separately.
The nested `semantic.composition` summary inside that payload now also has its
own bounded nested-object contract for composition sources:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticCompositionContract.pm)
owns the composition key family while keeping nested provenance-report
ownership delegated to
[perl/FSM/Support/CompositionReportContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CompositionReportContract.pm).
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
[perl/FSM/Support/SupportAccountingMatchContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/SupportAccountingMatchContract.pm).
The manifest's `support_accounting` section now has its own bounded contract
owner too:
[perl/FSM/Support/SupportAccountingContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/SupportAccountingContract.pm).
That keeps the top-level support counts, id lists, and sanitized catalog-entry
key set discoverable as an explicit contract instead of only as sample output.
The stable diagnostic-code registry now follows the same pattern:
[perl/FSM/Support/DiagnosticCodes.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodes.pm)
owns the production registry, while
[perl/FSM/Support/DiagnosticCodeRegistryContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticCodeRegistryContract.pm)
owns the bounded manifest-facing sibling-key and stable-entry-key promise.
The manifest shell now follows the same split too:
[perl/FSM/Support/CapabilityManifest.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifest.pm)
builds the JSON, while
[perl/FSM/Support/CapabilityManifestContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CapabilityManifestContract.pm)
owns the bounded top-level and first nested section key lists advertised under
top-level `manifest_contract`.
That shell contract now also explicitly lists the first nested
`support_accounting` keys, so embedders can discover the corpus-backed section
shape without a manifest-specific exception.
The `support_accounting` section now also exposes that same bounded owner
through `support_accounting.section_contract`, while deliberately keeping the
existing inline support-accounting contract fields and corpus metadata for
compatibility.
That section shell now also publishes a grouped `presence_key_family_map` so
downstream tools can discover the bounded bucket, id-list, and catalog-entry
key families from one place instead of collecting those support-accounting key
families field by field.
The `embedding` section now follows the same split too:
[perl/FSM/Support/EmbeddingContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/EmbeddingContract.pm)
owns the published top-level and nested contract-owner map advertised through
`embedding.section_contract`, while the narrower result, composition-report,
and typed-extension contracts still own their deeper public promises.
That section shell now also publishes a grouped `nested_presence_key_map` so
downstream tools can discover the bounded child key families for
`composition_report`, `hdl_generator_result`, and `typed_extensions` from one
place before descending into those narrower contracts.
The `diagnostics` section now follows the same split too:
[perl/FSM/Support/DiagnosticsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticsContract.pm)
owns the published top-level, scalar-string, and stable-code entry families
advertised through `diagnostics.section_contract`, while the narrower stable
registry and check-JSON contracts still own their deeper public promises.
That section shell now also publishes a grouped `presence_key_family_map` so
downstream tools can discover the bounded diagnostics-owned scalar-string,
list, and stable-code entry key families from one place instead of collecting
those diagnostics key families separately.
The `producer` section now follows the same split too:
[perl/FSM/Support/ProducerContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ProducerContract.pm)
owns the published top-level, scalar-string, and boolean field families
advertised through `producer.section_contract`, while the broader producer
story stays limited to current tool/build identity rather than becoming an
accidental release-management API.
That section shell now also publishes a grouped `presence_key_family_map` so
downstream tools can discover the bounded scalar-string and boolean key
families from one place instead of collecting those producer key families
field by field.
The `backend_validation` section now follows the same split too:
[perl/FSM/Support/BackendValidationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/BackendValidationContract.pm)
owns the published top-level and nested contract-owner map advertised through
`backend_validation.section_contract`, while the narrower
`HDLExternalValidationContract` still owns the deeper validation-lane promise.
That section shell now also publishes a grouped `nested_presence_key_map` so
downstream tools can discover the bounded child key family for
`systemverilog_external` from one place before descending into the narrower
validation contract.
The `language_surface` section now has its own bounded owner as well:
[perl/FSM/Support/LanguageSurfaceContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/LanguageSurfaceContract.pm)
advertises the public top-level and first nested section-key lists through
`language_surface.surface_contract`, while the broader authored-language
surface still widens only when new claims are regression-backed deliberately.
That section shell now also publishes a grouped `nested_presence_key_map` so
downstream tools can discover the bounded first nested key families for
`strict_mode`, `default_mode_compatibility`, `assignments`,
`system_contracts`, `expressions`, `declarations`, and `composition` from one
place before descending into those nested language-surface sections.
The `documentation` section now has its own bounded owner too:
[perl/FSM/Support/DocumentationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DocumentationContract.pm)
advertises the public top-level and path-list keys through
`documentation.section_contract`, while the exact documentation file lists stay
deliberately widenable.
That section shell now also publishes a grouped `path_list_contract_map` so
downstream tools can discover the bounded path-list families for
`human_contract` and `downstream_alignment` from one place before consuming
those documentation path lists.
That lane is currently SystemVerilog-only; VHDL/GHDL validation waits for an
active VHDL backend.
The bounded contract for that lane now has its own owner too:
[perl/FSM/Support/HDLExternalValidationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLExternalValidationContract.pm).
The capability manifest advertises the command shape, tool identities, stage
names, and bounded success result/step keys for embedders that want the same
post-emission gate without reverse-engineering sample output.
That same contract now also publishes a grouped
`success_presence_key_family_map` so embedders can discover the bounded
success top-level and step key families from one place instead of collecting
those success key lists separately.

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
The bounded key-presence contract for this surface now has its own owner:
[perl/FSM/Support/CheckDiagnosticsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CheckDiagnosticsContract.pm).
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
[perl/FSM/Support/NormalizedSemanticReportContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticReportContract.pm).
The capability manifest advertises that contract so downstream tools can
discover the current top-level and bounded nested success/composition keys
without relying only on narrative docs or reverse-engineering sample payloads.

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
