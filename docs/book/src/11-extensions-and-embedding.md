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
