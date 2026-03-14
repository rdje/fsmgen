# Extension Model

This document defines the first modern `R7` replacement seam for legacy `.plg` / `PPlugin`.

It is intentionally narrow.

## Goal
Provide a typed extension mechanism for the active architecture without reviving:
- `.plg` file scanning,
- `AUTOLOAD` dispatch,
- eval-style plugin lookup,
- or environment-dependent late mutation phases.

## Current shipped boundary
The current active toolchain now supports programmatic typed extensions through:
- [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm)
- [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm)
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm)

Current contract:
- callers may pass `extensions => [ $extension_object, ... ]` to `FSM::Pipeline::HDLGenerator->new(...)`,
- each extension must be a normal blessed Perl object,
- the only shipped hook today is `after_generate_result($context)`.

## Why this is the first slice
The legacy plugin path was broad, implicit, and hard to reason about:
- `PPlugin.pm` scanned `.plg` files,
- dispatch happened through `AUTOLOAD`,
- extension points were discovered by string name,
- and late mutation phases were not typed or centrally validated.

The first modern replacement seam does not try to recreate that.

Instead it proves three narrower things:
- the live pipeline has a typed extension registry,
- extensions are explicit programmatic objects,
- and one real hook runs in the active toolchain.

## Shipped hook
### `after_generate_result($context)`
This hook runs after the pipeline has built the generation result and before the caller receives it.

Current intent:
- inspection,
- metadata augmentation,
- additional reporting/telemetry,
- or other post-generation behavior that does not require the old plugin model.

## Hook context
`$context` is a [FSM::Extension::Context](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) object with:
- `pipeline`
  - the active `FSM::Pipeline::HDLGenerator` instance
- `source_path`
  - the input file path used for generation
- `target_language`
  - current target language for generation
- `source_info`
  - classified source metadata (`fsm` or `composition`, etc.)
- `result`
  - the generation result hash returned by the pipeline

The current hook is intentionally post-generation only.

The shipped boundary is regression-locked in
[t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t).

## Example
```perl
package My::Extension;

sub new { bless {}, shift }

sub after_generate_result {
    my ($self, $context) = @_;
    $context->result->{extension_marker} = {
        source_kind => $context->source_info->{kind},
        target_language => $context->target_language,
    };
}
```

Used as:
```perl
my $pipeline = FSM::Pipeline::HDLGenerator->new(
    target_language => 'systemverilog',
    extensions => [ My::Extension->new ],
);
```

## Deliberate non-goals of the current slice
The current shipped mechanism does not yet provide:
- `.plg` compatibility,
- auto-discovery of extension files,
- CLI flags for loading extensions,
- pre-parse or mid-pipeline mutation hooks,
- backend text-rewrite hooks,
- or composition/plugin-era architecture phases such as `declarch`, `beginarch`, or `endarch`.

Those are future `R7` design decisions, not part of the first shipped boundary.

## Next likely R7 slices
- Define the next typed hook set deliberately instead of reopening string-based hook names.
- Decide whether extension loading should remain programmatic or gain an explicit config/CLI path.
- Migrate active architecture users away from `.plg` / `PPlugin` as the extension story.
