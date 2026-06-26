# Implementation Blueprint

This chapter is the selected blueprint entry point for conforming FSMGen
implementation-language variants. It is not a claim that a Rust, Rust/Wasm,
browser JavaScript, Dart/web, Julia, or other non-Perl implementation exists
yet. The current Perl implementation remains the reference/oracle.

The blueprint status is selected by
[BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.6](../../tasks/BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.md).
The canonical selector is
[BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md](../../BACKEND_LANGUAGE_MDBOOK_BLUEPRINT_SELECTION.md).

## Blueprint Structure

The implementation blueprint is organized around public contracts, not Perl
module internals. A conforming variant must be able to implement and validate
these surfaces from the book, focused public contracts, capability manifest,
selector records, and regression corpus.

| Section family | Current home |
| --- | --- |
| Source-layer contract map | Chapters 02-08 for `.fsm`, Chapters 13-13m for `.isf`, Chapter 14 for bounded `.ppif` status |
| Layering and lowering order | Chapter 13h plus the `.isf` and `.ppif` public contract docs |
| Portable request/result API | [BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md](../../BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md) |
| Host source/artifact model | [BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md](../../BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md) |
| Report and manifest contracts | Chapter 11, Chapter 13i, public contract docs, and `./bin/fsmgen --capability-manifest` |
| Artifact semantics | Chapter 09, Chapter 13h, Chapter 13i, and the portability selectors |
| Diagnostics and support accounting | Chapter 10, Chapter 11, Chapter 13i, and the capability manifest |
| Backend output boundaries | Chapter 09, Chapter 14, and backend-validation manifest sections |
| Semantic introspection and MCP | Chapter 11 and the semantic-introspection contract tests |
| Parity harness | [BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md](../../BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md) |
| Extension/plugin portability | [BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md](../../BACKEND_LANGUAGE_TYPED_EXTENSION_PORTABILITY_AUDIT.md) |
| First implementation experiment | Pending `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.8` |

## Source Layers

`.fsm` is IAL0: explicit cycle-authored hardware intent. `.isf` is IAL1:
scheduling intent that lowers into reviewable scheduled `.fsm` artifacts.
`.ppif` is the first IAL2 public file surface: protocol/platform intent that
currently lowers through generated `.isf` before generated `.fsm`.

A variant must not invent parallel semantics for these layers. It may use any
host-native internal representation, but the observable source syntax, lowering
order, diagnostics, reports, generated review artifacts, HDL behavior, and
support-accounting results must match the public contracts it claims.

## Portable API And Host Model

The portable API shape is a request/result family with conceptual
`capabilities(request?)` and `execute(request)` entry points. Operations are
`check`, `lower`, `schedule`, `semantic`, `generate_hdl`, and
`verification_output`.

The selected host boundary is a `source_catalog` plus `artifact_sink`. Pure
in-memory hosts provide source text and receive virtual artifacts without
mandatory POSIX paths, current working directory, environment variables,
temporary files, process spawning, or Perl module loading. The current
filesystem CLI remains an adapter over that logical model.

## Reports And Artifacts

A conforming variant must preserve the public report and artifact families it
claims:

- check JSON
- schedule JSON
- normalized semantic JSON
- capability manifest
- diagnostics and support accounting
- generated `.isf` and `.fsm` review artifacts
- HDL artifacts
- verification-output artifacts and manifests where shipped
- semantic-introspection and MCP surfaces when claimed

Raw private ASTs, internal IR objects, process-local handles, stack traces, and
host-specific exception objects are not portable public outputs.

## Parity Gate

Future variants prove support through the Perl-reference differential parity
harness. The selected corpus partitions are `supported_smoke`,
`strict_supported`, `expected_failure`, `legacy_out_of_scope`, and
`resource_sensitive`.

Before a variant claims a feature, it must pass the selected positive,
negative, report, artifact, diagnostic, support-accounting, documentation, and
resource-sensitive gates for that feature. Broad resource-sensitive runs must
use the selected RAM-guarded or exact bounded replacement policy.

## Implementation Checklist

A future implementation slice must be able to answer these questions from
public contracts before code claims parity:

- Which source forms are public and supported?
- How does each source layer lower?
- Which reports and artifacts are emitted?
- How does the host supply sources and receive artifacts?
- Which diagnostics and support-accounting fields are required?
- How are generated HDL and verification outputs validated?
- How is parity proven against the Perl oracle?
- Which extension surfaces are portable, unsupported, or out of scope?

Typed extension and plugin portability is selected as out of scope for the
first non-Perl implementation experiment unless a future exact task first
selects a portable extension API. A future variant must not claim portable
extension support from the current Perl `Module::Name`/`@INC`/blessed-object
surface.
