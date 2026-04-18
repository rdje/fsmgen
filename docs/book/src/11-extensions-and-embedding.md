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
explicitly classifies live/raw/unsanitized compatibility payloads such as
`fsm_module`, `raw_ast`, `statistics`, `composition_spec`,
`composition_plan`, and `composition_report`.

Do not treat the raw `HDLGenerator` result hash as a stable JSON document. Some
nested branches still contain live CoreAST/AST objects for compatibility and
in-process tooling. If you need sanitized machine interchange, use
`--emit-semantic-json` or the `FSM::Support::NormalizedSemanticReport` surface
instead.

Composition provenance has one more important split:

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
That lane is currently SystemVerilog-only; VHDL/GHDL validation waits for an
active VHDL backend.

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
