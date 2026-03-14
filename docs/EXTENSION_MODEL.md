# Extension Model

This document defines the first modern `R7` replacement seam for legacy `.plg` / `PPlugin`.

It is intentionally narrow.

## Goal
Provide a typed extension mechanism for the active architecture without reviving:
- `.plg` file scanning,
- `AUTOLOAD` dispatch,
- eval-style plugin lookup,
- or environment-dependent late mutation phases.

## What "typed" means here
In this document, "typed" does not mean a static Perl type system.
It means the extension boundary is explicit and structured instead of string-driven.

Concretely:
- the pipeline accepts normal blessed Perl objects as extensions,
- hook entrypoints are explicit methods on those objects,
- hook arguments are passed through a named context object with stable accessors,
- and the registry validates the basic object shape before dispatch.

So the modern boundary is:
- object + method + context

not:
- filename scan + string hook name + `AUTOLOAD` / eval dispatch

## Current shipped boundary
The current active toolchain now supports programmatic typed extensions through:
- [perl/FSM/Extension/Registry.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Registry.pm)
- [perl/FSM/Extension/Context.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm)
- [perl/FSM/Extension/Loader.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Loader.pm)
- [perl/FSM/Pipeline/HDLGenerator.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Pipeline/HDLGenerator.pm)
- [bin/fsmgen](/Users/richarddje/Documents/github/fsmgen/bin/fsmgen)

Current contract:
- callers may pass `extensions => [ $extension_object, ... ]` to `FSM::Pipeline::HDLGenerator->new(...)`,
- callers may also pass `extension_modules => [ 'My::Extension', ... ]` to `FSM::Pipeline::HDLGenerator->new(...)`,
- callers may also pass `extension_config_files => [ 'extensions.fsmext', ... ]` to `FSM::Pipeline::HDLGenerator->new(...)`,
- the CLI may load repeated `--extension-module Module::Name` entries explicitly from `@INC`,
- the CLI may also load repeated `--extension-config <file>` entries explicitly,
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

## Examples
### Example 1: annotate the returned result
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

### Example 2: collect post-generation telemetry across calls
```perl
package My::Telemetry;

sub new { bless { modules => [] }, shift }

sub after_generate_result {
    my ($self, $context) = @_;
    push @{$self->{modules}}, {
        module_name => $context->result->{module_info}{module_name},
        source_kind => $context->source_info->{kind},
    };
}

sub modules { return shift->{modules} }
```

This kind of extension is a good fit for:
- embedding FSMGen inside a larger Perl tool,
- collecting generation metadata,
- or attaching downstream reporting state

without reopening the legacy plugin-discovery model.

### Example 3: explicit CLI loading
```bash
PERL5LIB=./my_extensions ./bin/fsmgen \
  --extension-module My::Telemetry \
  --output /tmp/example.sv \
  fsm/trial_0.fsm
```

This is still explicit and typed:
- there is no directory scan,
- the module name is provided directly,
- and the loader instantiates a normal Perl object through `new()`.

### Example 4: explicit config-file loading
Extension config file:
```text
# one explicit module declaration per line
module My::Telemetry
module My::ResultMarker
```

CLI usage:
```bash
PERL5LIB=./my_extensions ./bin/fsmgen \
  --extension-config extensions.fsmext \
  --output /tmp/example.sv \
  fsm/trial_0.fsm
```

Current config-file rules:
- blank lines are allowed,
- `# ...` comment lines are allowed,
- each active line must be exactly `module Module::Name`.

## Deliberate non-goals of the current slice
The current shipped mechanism does not yet provide:
- `.plg` compatibility,
- auto-discovery of extension files,
- pre-parse or mid-pipeline mutation hooks,
- backend text-rewrite hooks,
- or composition/plugin-era architecture phases such as `declarch`, `beginarch`, or `endarch`.

Those are future `R7` design decisions, not part of the first shipped boundary.

## Next likely R7 slices
- Define the next typed hook set deliberately instead of reopening string-based hook names.
- Decide whether explicit loading should remain at object/module/config scope or gain richer constructor/config parameter support later.
- Migrate active architecture users away from `.plg` / `PPlugin` as the extension story.
