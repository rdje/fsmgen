# Backend-Language mdBook Blueprint Structure Selection

## Metadata

- Owner leaf: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.6`
- Date: `2026-06-26`
- Status: `complete`
- Outcome: selected a dedicated mdBook implementation-blueprint structure for
  conforming language-X variants. This selector adds the book entry point and
  structure only; it does not start a non-Perl implementation and does not
  change source syntax, report schemas, generated artifacts, diagnostics, HDL,
  or runtime behavior.

## Evidence Read

- Portability selectors:
  `docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md`,
  `docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md`,
  `docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md`, and
  `docs/BACKEND_LANGUAGE_PORTABLE_PARITY_HARNESS_SELECTION.md`.
- Current mdBook structure:
  `docs/book/src/SUMMARY.md`, `docs/book/src/11-extensions-and-embedding.md`,
  `docs/book/src/13h-lowering-reference.md`,
  `docs/book/src/14-feature-backlog.md`, and
  `docs/book/src/90-reference-map.md`.
- Existing public contract homes:
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`,
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`, and capability-manifest discovery
  through `./bin/fsmgen --capability-manifest`.

## Selected Placement

The selected mdBook home is a dedicated chapter:

```text
docs/book/src/15-implementation-blueprint.md
```

It is wired into `docs/book/src/SUMMARY.md` after the feature backlog and
before the reference map. The chapter is not a full independent specification
yet; it is the user-facing blueprint index and status surface that names the
exact sections a language-X implementer must be able to follow without reading
Perl internals as the source of truth.

Focused external docs such as public interface contracts, downstream
integration specs, and selector records remain canonical for their narrow
machine or maintainer details. The book chapter points to those homes and
states the required implementation blueprint structure so future slices can
fill each section without duplicating volatile detail.

## Selected Section Structure

The selected implementation-blueprint chapter must contain these section
families:

- Status and non-goals: state that Perl remains the reference/oracle and that
  no non-Perl implementation is selected by the blueprint itself.
- Source-layer contract map: identify `.fsm` as IAL0, `.isf` as IAL1, `.ppif`
  as the first IAL2 public file surface, and point to the chapter/reference
  homes for each source grammar and semantic boundary.
- Layering and lowering order: document the public lowering order from source
  classification through generated review artifacts, schedule/lowering data,
  HDL artifacts, verification artifacts, and reports.
- Portable request/result API: summarize the `.2.3` `capabilities(request?)`
  and `execute(request)` family and link to the selector as the canonical
  current shape.
- Host source/artifact model: summarize the `.2.4` `source_catalog` plus
  `artifact_sink` boundary and identify the filesystem CLI as an adapter.
- Report and manifest contracts: enumerate check JSON, schedule JSON,
  normalized semantic JSON, capability manifest, support accounting,
  diagnostics, semantic introspection, and verification-output manifest
  responsibilities.
- Artifact semantics: describe generated `.isf` and `.fsm` review artifacts,
  virtual artifacts, HDL artifacts, verification-output artifacts, manifests,
  deterministic identity, and artifact ordering.
- Diagnostics and support accounting: require fail-closed public diagnostics,
  support tier visibility, strict-mode parity, and matched support-accounting
  fields for supported entries.
- Backend output boundaries: identify current SystemVerilog/Verilog-family and
  VHDL/verification-output status, backend-validation boundaries, and the
  default no-mandatory-external-converter stance.
- Semantic introspection and MCP: require variants that claim these surfaces to
  preserve the public semantic-introspection and MCP contract rather than raw
  implementation objects.
- Parity harness: summarize the `.2.5` differential harness, corpus
  partitions, normalization rules, resource-sensitive policy, and pass/fail
  gates.
- Extension/plugin portability status: mark typed extensions and plugin
  portability as pending `.2.7`, not a portable contract yet.
- Implementation checklist: list the ordered gates a conforming variant must
  pass before claiming support for a source surface or operation.

## Canonical Homes And Drift Rule

The blueprint chapter is an index and implementation guide. It must not become
a stale copy of every narrow contract. The selected drift rule is:

- stable user-facing semantics belong in the owning book chapter;
- narrow machine-readable or downstream contracts stay in their focused docs
  and manifest sections;
- selector records under `docs/` preserve the current portability decisions;
- task-tree leaves own future changes before any code, test, generated
  artifact, config, or public contract behavior changes;
- every future implementation slice must update the blueprint chapter when it
  changes a language-X implementer requirement or public parity gate.

## Pass/Fail Gate For Future Blueprint Completion

A future implementation-blueprint completion slice must make the chapter
sufficient for a competent implementer to build a conforming variant from
public contracts, selectors, and linked focused docs. The implementer should not
need to inspect Perl package internals to answer these questions:

- which source forms are public and supported;
- how each source layer lowers;
- which reports and artifacts are emitted;
- how a host supplies sources and receives artifacts;
- which diagnostics and support-accounting fields are required;
- how generated HDL and verification outputs are validated;
- how parity is proven against the Perl oracle;
- which extension surfaces are portable or explicitly out of scope.

## Deferrals

- No non-Perl implementation is selected in this leaf.
- No typed extension/plugin portability answer is selected until `.2.7`.
- No first implementation-language experiment is selected until `.2.8`.
- No report-schema or source-language widening is selected by adding the
  blueprint chapter.
