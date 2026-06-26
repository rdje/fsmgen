# Backend-Language Portable Host Source/Artifact Abstraction Selection

## Metadata

- Owner leaf: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.4`
- Date: `2026-06-26`
- Status: `complete`
- Outcome: selected the host source/artifact abstraction required by the
  portable in-memory request/result API. This is a contract selector only; it
  does not change CLI behavior, report schemas, generated artifacts, or
  implementation code.

## Evidence Read

- Portability selectors:
  `docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md` and
  `docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md`.
- Current filesystem adapter mechanics: `bin/fsmgen` and
  `perl/FSM/SourcePathResolver.pm`.
- Current public source/report surfaces:
  `perl/FSM/Support/ReportSourceContract.pm`,
  `perl/FSM/Support/SerializableGenerationResultSnapshot.pm`,
  `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md`, and
  `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md`.
- User-facing portability/backlog surface:
  `docs/book/src/14-feature-backlog.md`.

## Selected Abstraction

The selected host boundary is a two-part abstraction:

- `source_catalog`: resolves source identities to source text plus bounded
  metadata.
- `artifact_sink`: accepts virtual artifacts produced by `lower`,
  `generate_hdl`, and `verification_output` operations.

The pure in-memory API from `.2.3` must speak to these two families. It must not
require a POSIX filesystem, current working directory, environment variables,
temporary files, process spawning, or Perl module loading. The existing
filesystem CLI remains an adapter that maps `--path`, `FSMLIB`, current
directory search, `--outdir`, `--output`, and verification-output directories
onto the same logical catalog/sink model.

## Source Catalog Contract

A host source catalog must accept source references by identity and return a
JSON-safe source envelope:

- `source_id`: caller-facing stable identity used in request/result envelopes.
- `source_kind_hint`: optional `fsm`, `isf`, `ppif`, `package`, or another
  advertised kind; omitted hints are classified by the engine.
- `text`: source text for the resolved identity.
- `encoding`: explicit text encoding when needed; UTF-8 text is the default
  contract assumption.
- `origin`: one of `memory`, `filesystem`, `workspace`, `embedded`, or another
  manifest-advertised bounded origin.
- `display_name`: user-facing identity suitable for diagnostics.
- `canonical_id`: optional stable host-normalized identity for deduplicating
  repeated lookups.
- `relative_path`: optional path-like identity when the host has a workspace or
  filesystem concept.
- `metadata`: optional JSON-safe host metadata; raw filehandles, process
  handles, host exceptions, Perl objects, and private ASTs are forbidden.

The catalog must support dependency lookup for package imports, composition
children, generated child review artifacts, RTL sidecars where current public
contracts require them, and future include-like source families. A failed lookup
must return a public diagnostic envelope rather than leaking host stack detail.

## Artifact Sink Contract

A host artifact sink must accept virtual artifacts with the `.2.3` artifact
fields:

- `relpath`
- `kind`
- `language`
- `role`
- `content`
- `source_layer`
- `generated_from`

The sink may store artifacts in memory, write them to a filesystem, stream them
to an embedding host, or reject writes with a public diagnostic if the requested
operation requires an artifact class that the host has not enabled. The sink
must preserve deterministic artifact identity and write ordering. It must not
infer additional generated artifacts that the engine did not emit.

Binary artifact support is deferred until a shipped operation needs it. Until
then, artifacts are text payloads with explicit encoding metadata.

## Current CLI Adapter Mapping

The current CLI maps into the host abstraction as follows:

- An input path maps to `source_id == input` plus a filesystem-backed source
  envelope.
- `--path DIR` entries, `FSMLIB`, and current-directory fallback map to ordered
  source-catalog roots. `~` expansion and environment-variable lookup are CLI
  adapter mechanics, not portable API requirements.
- `--outdir DIR`, `--output FILE`, and `--verification-outdir DIR` map to a
  filesystem artifact sink.
- Temporary `.isf`/`.ppif` lowering files used internally by the current CLI are
  implementation details; portable hosts receive virtual generated `.fsm` and
  `.isf` artifacts instead.
- Existing public report fields such as `source.resolved_path` remain unchanged
  for the file-backed CLI. Pure in-memory reports may use a host-selected
  canonical source identity once an implementation leaf widens the report
  contract deliberately.

## Host Profiles

- Filesystem CLI: ordered source roots, current public path semantics, and a
  filesystem artifact sink.
- Browser/Wasm: caller-provided in-memory source map, no environment lookup, no
  current working directory, and an in-memory artifact sink.
- Embedded/library host: callback-backed source catalog and caller-owned
  artifact sink with no process-global state requirement.
- Test/parity host: deterministic in-memory catalog and artifact sink suitable
  for comparing future variants against the Perl reference/oracle.

## Validation Requirements

Future implementation work must prove:

- source lookup parity for current `--path`, `FSMLIB`, local source context, and
  embedded-package behavior through the filesystem adapter;
- pure in-memory lookup parity for the same logical source graph without
  filesystem paths;
- artifact-sink parity between virtual artifacts and current `--outdir`,
  `--output`, and verification-output filesystem materialization;
- diagnostic parity for missing sources and unsupported artifact writes;
- no raw host objects or private implementation data in public JSON reports; and
- deterministic artifact ordering and identities across filesystem and
  in-memory hosts.

## Deferrals

- No implementation code changes in this selector leaf.
- No report-schema widening for pure in-memory `source` identity until an exact
  implementation owner changes both reports and manifest advertisement.
- No parity harness implementation until `.2.5`.
- No mdBook language-X blueprint until `.2.6`.
- No typed extension/plugin portability decision until `.2.7`.
- No first non-Perl implementation experiment until `.2.8` or a later exact
  owner.
