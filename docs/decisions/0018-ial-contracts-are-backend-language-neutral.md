# 0018 — IAL contracts and mdBook are backend-language-neutral

- Date: 2026-06-12
- Type: architecture
- Status: accepted

## Context

FSMGen is currently implemented as a Perl 5 project. The intended long-term
direction includes additional backend implementations, including Rust,
JavaScript, and Dart. A Rust implementation should also keep WebAssembly as a
plausible future deployment target. The JavaScript and Dart directions
specifically include being able to run FSMGen in a web browser, not only in
server-side runtimes.

The mdBook is the user-facing surface for the project, and IAL0/IAL1/IAL2 are
semantic layers, not Perl-specific APIs. Current Perl module names are useful
implementation references, but they must not become the definition of the
layers.

## Decision

IAL0, IAL1, IAL2, their public file formats, reports, diagnostics, examples,
and mdBook explanations must stay backend-language-neutral.

The canonical user-facing contract is the authored source syntax, generated
review artifacts, machine-readable reports, diagnostics, and HDL behavior. The
current Perl implementation remains the reference implementation/oracle while
other implementations grow, but public documentation should describe semantics
and observable contracts first.

When documentation mentions Perl module names, it must label them as current
implementation entrypoints, not as the portable IAL definition.

Portable IAL contracts must avoid assuming POSIX filesystem access,
process-spawning, Perl module loading, or other host-only runtime features as
part of the semantic contract. Those capabilities may exist in the current CLI
or reference implementation, but browser-hosted JavaScript, Dart/web, and
Rust/Wasm targets must be able to implement the same source/report/diagnostic
semantics through appropriate host abstractions.

## Consequences

- Future Rust, Rust/Wasm, browser-capable JavaScript, and Dart/web backend
  work should implement the same IAL contracts instead of inventing parallel
  semantics.
- mdBook examples should prefer public CLI/file-format/report behavior when
  explaining user-visible features.
- In-process Perl examples may remain where they document the current
  reference implementation, but they should not imply that IAL0/IAL1/IAL2 are
  Perl-only abstractions.
- Task-tree selectors for IAL0/IAL1/IAL2 must preserve backend-neutral
  wording and identify implementation-language-specific work as such.
