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
- the pipeline accepts normal blessed Perl objects with at least one supported
  hook method as extensions,
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
- each extension must be a normal blessed Perl object that provides at least
  one real supported hook method discoverable by `UNIVERSAL::can`,
- the shipped hook set today is:
  - `after_parse_source($context)`
  - `after_generate_result($context)`.

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

## Shipped hooks
### `after_parse_source($context)`
This hook runs after the source file has been parsed and classified, and after composition inputs have been parsed into typed composition IR.

Current intent:
- source inspection,
- parse-frontier validation,
- early telemetry,
- or other explicit source-frontier behavior that does not require the old plugin model.

### `after_generate_result($context)`
This hook runs after the pipeline has built the generation result and before the caller receives it.

Current intent:
- inspection,
- metadata augmentation,
- additional reporting/telemetry,
- or other post-generation behavior that does not require the old plugin model.

## Hook context
`$context` is a [FSM::Extension::Context](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Extension/Context.pm) object with:
- `stage`
  - current hook stage name such as `after_parse_source` or `after_generate_result`
- `pipeline`
  - the active `FSM::Pipeline::HDLGenerator` instance
- `source_path`
  - the input file path used for generation
- `target_language`
  - current target language for generation
- `source_info`
  - classified source metadata such as `fsm`, `dt`, or `composition`
- `raw_ast`
  - parsed source AST when the hook runs at the parse frontier
- `result`
  - the generation result hash returned by the pipeline

The shipped boundary is regression-locked in
[t/26-extension-mechanism.t](/Users/richarddje/Documents/github/fsmgen/t/26-extension-mechanism.t),
[t/27-extension-loading.t](/Users/richarddje/Documents/github/fsmgen/t/27-extension-loading.t),
and [t/28-extension-config-loading.t](/Users/richarddje/Documents/github/fsmgen/t/28-extension-config-loading.t).
The manifest-owned programmatic loading boundary is also audited in
[t/391-typed-extension-programmatic-loading-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/391-typed-extension-programmatic-loading-boundary-audit.t),
which proves `extension_modules` and `extension_config_files` dispatch real
in-process hooks through `FSM::Pipeline::HDLGenerator` while remaining owned by
`embedding.typed_extensions`.
[t/392-typed-extension-autoload-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/392-typed-extension-autoload-boundary-audit.t)
also proves the negative side of the same typed boundary: AUTOLOAD-only
extensions, including objects that override `can(...)`, now fail closed as
hookless direct extension objects, while explicit and inherited real hook
methods still run.
[t/393-typed-extension-hook-set-closed-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/393-typed-extension-hook-set-closed-boundary-audit.t)
also proves the hook set is closed for the current schema version: extra
hook-shaped methods such as `before_parse_source` or `after_emit_hdl` remain
inert during direct and composition generation until the contract deliberately
adds a new hook family.
[t/421-hdl-generator-facade-extension-hook-method-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/421-hdl-generator-facade-extension-hook-method-boundary-audit.t)
also proves the `HDLGenerator` facade and direct registry reject hookless,
unsupported-hook-only, and `AUTOLOAD`/fake-`can` direct extension objects before
they can become silent no-ops or leak registry/lower-level fallout.
[t/426-typed-extension-registry-constructor-argument-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/426-typed-extension-registry-constructor-argument-boundary-audit.t)
also proves direct `FSM::Extension::Registry->new(...)` construction accepts
only the exact class receiver and an even-length list of unique supported
scalar option names, so malformed registry constructor calls fail before raw
hash-coercion or `bless` fallout can leak.
[t/429-typed-extension-registry-method-receiver-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/429-typed-extension-registry-method-receiver-boundary-audit.t)
also proves direct registry methods require an exact hash-backed
`FSM::Extension::Registry` object constructed by `new(...)`, so class
receivers, subclass stand-ins, and fake exact-class objects fail before hook or
context diagnostics can leak.
[t/394-typed-extension-context-accessor-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/394-typed-extension-context-accessor-boundary-audit.t)
also proves the context accessor names are stable for the current schema
version by checking manifest discovery, the implemented
`FSM::Extension::Context` methods, and real direct plus composition hook
contexts through every advertised accessor.
[t/395-typed-extension-explicit-discovery-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/395-typed-extension-explicit-discovery-boundary-audit.t)
also proves extension discovery remains explicit: nearby `extensions.fsmext`,
`fsmgen.fsmext`, and legacy `.plg`-shaped files stay inert for in-process and
CLI generation unless the caller supplies explicit module or config loading
entrypoints.
[t/396-typed-extension-constructor-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/396-typed-extension-constructor-boundary-audit.t)
also proves module-name loading requires a real `new()` method: explicit and
inherited constructors still work, while extension-provided `can(...)` methods
and `AUTOLOAD`-only constructor discovery stay outside the typed loading
boundary.
[t/427-typed-extension-loader-constructor-argument-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/427-typed-extension-loader-constructor-argument-boundary-audit.t)
also proves direct `FSM::Extension::Loader->new(...)` construction accepts
only the exact class receiver and no option/value arguments, so malformed
loader constructor calls fail before raw hash-coercion or `bless` fallout can
leak.
[t/428-typed-extension-loader-method-receiver-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/428-typed-extension-loader-method-receiver-boundary-audit.t)
also proves direct loader methods require an exact hash-backed
`FSM::Extension::Loader` object constructed by `new(...)`, so class receivers,
subclass stand-ins, and fake exact-class objects fail before loading payload
diagnostics can leak.
[t/397-typed-extension-registry-dispatch-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/397-typed-extension-registry-dispatch-boundary-audit.t)
also proves the registry's direct `dispatch_hook(...)` entrypoint enforces the
same closed hook set: `after_parse_source` and `after_generate_result` still
dispatch, while unsupported hook names are rejected before extension methods
can run.
[t/422-typed-extension-registry-dispatch-context-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/422-typed-extension-registry-dispatch-context-boundary-audit.t)
also proves direct registry dispatch requires a real
`FSM::Extension::Context` object whose `stage` matches the dispatched hook
name, so malformed direct contexts fail before extension code can reinterpret
them.
[t/423-typed-extension-context-constructor-argument-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/423-typed-extension-context-constructor-argument-boundary-audit.t)
also proves direct `FSM::Extension::Context->new(...)` construction accepts
only the exact class receiver and an even-length list of unique supported
scalar option names, so malformed constructor calls fail before raw Perl
argument or `bless` fallout can leak.
[t/430-typed-extension-context-accessor-receiver-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/430-typed-extension-context-accessor-receiver-boundary-audit.t)
also proves direct context accessors require an exact hash-backed
`FSM::Extension::Context` object constructed by `new(...)`, so class receivers,
subclass stand-ins, and fake exact-class objects fail before raw accessor
fallout can leak.
[t/424-typed-extension-context-constructor-payload-boundary-audit.t](/Users/richarddje/Documents/github/fsmgen/t/424-typed-extension-context-constructor-payload-boundary-audit.t)
also proves direct context construction validates the payload values that hooks
rely on: supported hook stages, a blessed pipeline, scalar source path and
target language, scalar `source_info->{kind}`, parse contexts with
`raw_ast` and no `result`, and result contexts with `result` and no `raw_ast`.
[t/425-typed-extension-dt-source-kind-contract-audit.t](/Users/richarddje/Documents/github/fsmgen/t/425-typed-extension-dt-source-kind-contract-audit.t)
also proves standalone `?dt:` roots are part of the bounded typed-extension
source-kind family: manifests advertise `dt`, and live `dt` generation
dispatches parse/result contexts whose `source_info->{kind}` is `dt`.

For embedders, the same boundary is now machine-readable through
[perl/FSM/Support/ExtensionContract.pm](/Users/richarddje/Documents/github/fsmgen/perl/FSM/Support/ExtensionContract.pm)
and advertised by `bin/fsmgen --capability-manifest` under
`embedding.typed_extensions`. That manifest entry is intentionally bounded: it
names the current loading entrypoints, hook names, context accessor names, and
the direct context constructor boundaries, and non-goals, but it does not
claim the entire future extension API is frozen.

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

### Example 3: inspect the parsed source frontier
```perl
package My::SourceInspector;

sub new { bless { seen => [] }, shift }

sub after_parse_source {
    my ($self, $context) = @_;
    push @{$self->{seen}}, {
        stage => $context->stage,
        source_kind => $context->source_info->{kind},
    };
}
```

This kind of extension is a good fit for:
- early validation,
- source-kind telemetry,
- or inspection of raw parsed input before semantic lowering.

### Example 4: explicit CLI loading
```bash
PERL5LIB=./my_extensions ./bin/fsmgen \
  --extension-module My::Telemetry \
  --output /tmp/example.sv \
  fsm/trial_0.fsm
```

This is still explicit and typed:
- there is no directory scan,
- the module name is provided directly,
- and the loader instantiates a normal Perl object through a real `new()`
  method.

### Example 5: explicit config-file loading
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
- broad mid-pipeline mutation hooks,
- backend text-rewrite hooks,
- or composition/plugin-era architecture phases such as `declarch`, `beginarch`, or `endarch`.

Those are future `R7` design decisions, not part of the first shipped boundary.

## Future extension growth
- Extend the typed hook set only if a future active-architecture seam is stable enough to deserve standardization.
- Decide later whether explicit loading should remain at object/module/config scope or gain richer constructor/config parameter support.
- Continue reusing this typed boundary instead of reopening `.plg` / `PPlugin` as the architectural extension story.
