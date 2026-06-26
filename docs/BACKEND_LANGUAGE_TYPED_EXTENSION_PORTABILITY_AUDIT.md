# Backend-Language Typed Extension Portability Audit

## Metadata

- Owner leaf: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.7`
- Date: `2026-06-26`
- Status: `complete`
- Outcome: selected the backend-language portability boundary for typed
  extensions. The current typed extension system remains a bounded Perl
  reference implementation surface, but it is not a backend-neutral portable
  extension/plugin contract. Extension/plugin support is out of scope for the
  first non-Perl implementation experiment unless a later exact task selects a
  portable extension API first.

## Evidence Read

- Current extension model:
  `docs/EXTENSION_MODEL.md` and
  `docs/book/src/11-extensions-and-embedding.md`.
- Current extension implementation:
  `perl/FSM/Support/ExtensionContract.pm`,
  `perl/FSM/Extension/Loader.pm`, `perl/FSM/Extension/Registry.pm`,
  `perl/FSM/Extension/Context.pm`, `perl/FSM/Pipeline/HDLGenerator.pm`, and
  `bin/fsmgen`.
- Current proof surfaces:
  `t/391-typed-extension-programmatic-loading-boundary-audit.t`,
  `t/395-typed-extension-explicit-discovery-boundary-audit.t`, and
  `t/401-typed-extension-module-name-shape-boundary-audit.t`, plus the broader
  `t/39x`, `t/42x`, `t/43x`, `t/49x`, and capability-manifest typed-extension
  JSON/defensive-copy audit families.
- Portability selectors:
  `docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md`,
  `docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md`,
  `docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md`, and
  `docs/BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md`.

## Current Perl Reference Boundary

The current typed extension model is explicit and bounded:

- Extension instances are blessed Perl objects.
- Extension objects must provide at least one real supported hook method
  discoverable by `UNIVERSAL::can`.
- The shipped hook set is closed for schema version 1:
  `after_parse_source($context)` and `after_generate_result($context)`.
- Hook context is a `FSM::Extension::Context` object with accessor methods for
  `stage`, `pipeline`, `source_path`, `target_language`, `source_info`,
  `raw_ast`, and `result`.
- Programmatic loading accepts direct extension objects, module names through
  `extension_modules`, and config files through `extension_config_files`.
- CLI loading accepts explicit `--extension-module Module::Name` and
  `--extension-config FILE` arguments.
- Module/config loading depends on Perl `@INC`, `require`, a real `new()`
  constructor, and scalar `Module::Name` or `module Module::Name` shapes.
- Legacy `.plg` discovery, automatic directory discovery, implicit CLI plugin
  discovery, `AUTOLOAD` hook dispatch, and extra hook-shaped methods remain
  disabled or inert.

This is a public bounded contract for the current Perl reference
implementation and Perl in-process embedders. It is advertised through
`embedding.typed_extensions` and is regression-backed.

## Non-Portable Mechanics

The following mechanics are explicitly Perl/reference-implementation details,
not backend-language-neutral requirements:

- blessed Perl objects as extension instances;
- Perl package names and `Module::Name` validation;
- `@INC`, `PERL5LIB`, `require`, and Perl constructor discovery;
- `UNIVERSAL::can`, Perl inheritance semantics, and `AUTOLOAD` exclusion;
- raw `FSM::Extension::*` receiver shapes and hash-backed object markers;
- live `pipeline` and live `result` Perl objects in hook context;
- direct mutation of raw in-process result hashes;
- filesystem config-file loading as a portable extension discovery mechanism;
- Perl exception text and stack behavior below the public diagnostic context.

Future variants may expose host-native extension mechanisms, but they must not
claim that the current Perl module-loading surface is the shared portable API.

## Selected Portability Boundary

The selected boundary is:

- Keep the current Perl typed extension model as a bounded Perl reference
  surface.
- Treat typed extension/plugin support as out of scope for the first non-Perl
  implementation experiment.
- A future non-Perl variant that does not implement a portable extension API
  must advertise extension support as unsupported and fail closed if a caller
  requests extension loading.
- No first non-Perl implementation may depend on `@INC`, Perl module loading,
  blessed object identity, raw Perl pipeline objects, or raw result-hash
  mutation for core FSMGen parity.
- Before any variant claims portable extension support, a later exact task must
  select a backend-neutral extension API with JSON-safe context snapshots,
  explicit hook names, host-provided callback/registration mechanics, result
  augmentation rules, diagnostics, manifest advertisement, and parity gates.

## Future Portable Extension API Requirements

If a future task selects portable extension support, it must define:

- hook names and timing against the `.2.3` operation model;
- JSON-safe context payloads for source identity, source kind, target language,
  diagnostics, reports, and virtual artifacts;
- whether hooks may mutate results, return additive metadata, emit virtual
  artifacts, or only observe;
- host registration for callbacks/modules/packages without mandatory POSIX
  paths or Perl package loading;
- deterministic error handling and fail-closed diagnostics;
- manifest advertisement for supported hooks, payload shapes, and unsupported
  host profiles;
- parity tests against the Perl oracle for any claimed extension behavior;
- explicit exclusion of private AST/IR/pipeline objects from the portable
  surface unless a future selector deliberately promotes a sanitized form.

## Deferrals

- No implementation code changes in this audit leaf.
- No current Perl typed extension behavior is weakened or removed.
- No portable extension ABI/API is selected here.
- No first implementation-language experiment is selected here; `.2.8` owns
  that choice after this boundary is committed.
