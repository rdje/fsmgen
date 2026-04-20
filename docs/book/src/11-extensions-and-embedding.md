# Extensions and Embedding

This chapter covers the current supported integration seam for tool builders.

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
The top-level `fsm_module` branch is shell-only too when it is defined: it is a
raw `FSM::CoreAST::FSMModule` object kept for in-process compatibility, so
structured downstream consumers should prefer `intent_hir`, `lowered_rtl_ir`,
`structural_rtl_ir`, or normalized semantic JSON. The top-level `raw_ast`
branch is likewise shell-only and intentionally treated as a frontend/debug
artifact rather than a public interchange tree, so structured consumers should
prefer `intent_hir` instead of binding themselves to parser-level arrays.
The same result contract now machine-advertises the narrower “stable
subsurface” boundary for the nested hashes too: the whole `source_info`,
`module_info`, and `statistics` hashes are still not stable APIs, but the
advertised `source_info.*`, `module_info.*`, and `statistics.*` identity/summary
paths are the bounded public slices embedders should target.
The composition-only `composition_spec` and `composition_plan` branches are
shell-only too: they are raw `FSM::Composition::Spec` and
`FSM::Composition::Plan` objects kept for in-process compatibility. Raw
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
Those same public check JSON and normalized semantic JSON reports now also
share one bounded nested-object contract for producer identity:
[perl/FSM/Support/ReportProducerContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ReportProducerContract.pm)
owns the shared `name` plus `report_source` keys, while normalized semantic
JSON adds the bounded `semantic_layers` extension documented by that same
owner.
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
Failed public check JSON reports now also have one bounded nested-object
contract for the failure payload itself:
[perl/FSM/Support/CheckFailureDiagnosticContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CheckFailureDiagnosticContract.pm)
owns the core stable diagnostic keys plus the matched-only, optional-artifact,
and nested support-accounting key lists emitted under each `diagnostic`
object.
Failed public normalized semantic JSON reports now explicitly reuse that same
bounded nested failure-diagnostic contract too.
Successful public normalized semantic JSON reports now also have one bounded
nested-object contract for the success payload itself:
[perl/FSM/Support/NormalizedSemanticPayloadContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticPayloadContract.pm)
owns the `module`, `system_contract`, `explicit_system_contract`,
`signal_analysis`, and `forward_ir` keys, and the same owner also publishes
the nested `explicit_system_contract`, `signal_analysis`, `system_contract`,
`forward_ir`, and optional `symbol_contract` plus `composition` key lists.
The nested `semantic.signal_analysis` summary inside that payload now also has
its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticSignalAnalysisContract.pm)
owns the current sanitized signal-family projection keys plus the shared core
signal-entry keys emitted across direct and composition roots.
The nested `semantic.explicit_system_contract` summary inside that payload now
also has its own bounded nested-object contract when the authored explicit
contract is preserved:
[perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticExplicitSystemContract.pm)
owns the current authored explicit clock/reset projection keys.
The nested `semantic.system_contract` summary inside that payload now also has
its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticSystemContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticSystemContract.pm)
owns the current clock/reset/system-contract projection keys.
The nested `semantic.forward_ir` summary inside that payload now also has its
own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticForwardIRContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticForwardIRContract.pm)
owns the current sanitized forward semantic projection keys.
The nested `semantic.forward_ir.lowered_rtl_ir` summary inside that branch now
also has its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticLoweredRTLIRContract.pm)
owns the current lowered-RTL shell keys plus the composition-only extension
keys emitted today for top roots.
The nested `semantic.forward_ir.structural_rtl_ir` summary inside that branch
now also has its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticStructuralRTLIRContract.pm)
owns the current structural-RTL shell keys shared by direct and composition
roots.
The nested `semantic.forward_ir.intent_hir` summary inside that branch now
also has its own bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticIntentHIRContract.pm)
owns the current intent-hir shell keys plus the composition-only extension
keys emitted today for top roots.
The optional `semantic.symbol_contract` summary inside that payload now also
has its own bounded nested-object contract for symbol-rich sources:
[perl/FSM/Support/NormalizedSemanticSymbolContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticSymbolContract.pm)
owns the published symbol-contract key family.
The nested `semantic.module` summary inside that payload now also has its own
bounded nested-object contract:
[perl/FSM/Support/NormalizedSemanticModuleContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticModuleContract.pm)
owns the core module-summary keys plus the current optional metric-key family.
The nested `semantic.composition` summary inside that payload now also has its
own bounded nested-object contract for composition sources:
[perl/FSM/Support/NormalizedSemanticCompositionContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/NormalizedSemanticCompositionContract.pm)
owns the composition key family while keeping nested provenance-report
ownership delegated to
[perl/FSM/Support/CompositionReportContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/CompositionReportContract.pm).

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
The `embedding` section now follows the same split too:
[perl/FSM/Support/EmbeddingContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/EmbeddingContract.pm)
owns the published top-level and nested contract-owner map advertised through
`embedding.section_contract`, while the narrower result, composition-report,
and typed-extension contracts still own their deeper public promises.
The `diagnostics` section now follows the same split too:
[perl/FSM/Support/DiagnosticsContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DiagnosticsContract.pm)
owns the published top-level, scalar-string, and stable-code entry families
advertised through `diagnostics.section_contract`, while the narrower stable
registry and check-JSON contracts still own their deeper public promises.
The `producer` section now follows the same split too:
[perl/FSM/Support/ProducerContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ProducerContract.pm)
owns the published top-level, scalar-string, and boolean field families
advertised through `producer.section_contract`, while the broader producer
story stays limited to current tool/build identity rather than becoming an
accidental release-management API.
The `backend_validation` section now follows the same split too:
[perl/FSM/Support/BackendValidationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/BackendValidationContract.pm)
owns the published top-level and nested contract-owner map advertised through
`backend_validation.section_contract`, while the narrower
`HDLExternalValidationContract` still owns the deeper validation-lane promise.
The `language_surface` section now has its own bounded owner as well:
[perl/FSM/Support/LanguageSurfaceContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/LanguageSurfaceContract.pm)
advertises the public top-level and first nested section-key lists through
`language_surface.surface_contract`, while the broader authored-language
surface still widens only when new claims are regression-backed deliberately.
The `documentation` section now has its own bounded owner too:
[perl/FSM/Support/DocumentationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/DocumentationContract.pm)
advertises the public top-level and path-list keys through
`documentation.section_contract`, while the exact documentation file lists stay
deliberately widenable.
That lane is currently SystemVerilog-only; VHDL/GHDL validation waits for an
active VHDL backend.
The bounded contract for that lane now has its own owner too:
[perl/FSM/Support/HDLExternalValidationContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/HDLExternalValidationContract.pm).
The capability manifest advertises the command shape, tool identities, stage
names, and bounded success result/step keys for embedders that want the same
post-emission gate without reverse-engineering sample output.

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
