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

That is already useful for downstream tooling even though the long-term public
embedding/API stabilization lane (`R13`) is still not started.

## Important Boundary

Today, programmatic embedding exists, but it is not yet declared a fully frozen
public API.

That means:

- useful now for internal tooling and serious integration work
- not yet promised as a permanently stable contract forever

The future `R13` lane is where that public stabilization work belongs.

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
