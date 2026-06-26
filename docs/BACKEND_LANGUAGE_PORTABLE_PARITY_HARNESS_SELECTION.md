# Backend-Language Portable Parity Harness Selection

## Metadata

- Owner leaf: `BACKEND-LANGUAGE-PORTABILITY-CONTRACT-FRONTIER.2.5`
- Date: `2026-06-26`
- Status: `complete`
- Outcome: selected the Perl-reference parity harness shape and normalization
  rules for future implementation-language variants. This is a contract
  selector only; it does not add a non-Perl implementation and does not change
  current CLI, report, generated artifact, or HDL behavior.

## Evidence Read

- Portability selectors:
  `docs/BACKEND_LANGUAGE_PORTABILITY_READINESS_AUDIT.md`,
  `docs/BACKEND_LANGUAGE_PORTABLE_IN_MEMORY_API_CONTRACT_SELECTION.md`, and
  `docs/BACKEND_LANGUAGE_PORTABLE_HOST_ABSTRACTION_SELECTION.md`.
- Regression corpus and current broad gates:
  `perl/FSM/Support/RegressionCorpus.pm`,
  `t/296-regression-corpus-supported-behavior.t`,
  `t/249-regression-corpus-classified-behavior.t`,
  `t/301-check-json-supported-corpus.t`, and
  `t/303-normalized-semantic-json-supported-corpus.t`.
- Capability and introspection gates:
  `t/297-capability-manifest.t`,
  `t/1438-semantic-introspection-contract.t`, and
  `t/1440-semantic-introspection-manifest-contract-roundtrip-audit.t`.
- Current resource-sensitive replacement coverage:
  `t/1466-ppif-check-json-oversized-summary.t`.
- User-facing portability/backlog surface:
  `docs/book/src/14-feature-backlog.md`.

## Selected Harness Model

The selected model is a differential parity harness with the current Perl 5
implementation as the reference/oracle. Every future implementation-language
variant must run the same logical request family from `.2.3` against the same
logical source graph from `.2.4`, normalize host-specific details, and compare
the normalized public result against the Perl oracle before claiming support for
that feature family.

The harness compares public contracts, not private implementation structures.
Perl package names, blessed objects, raw internal AST/IR objects, temp paths,
process-local handles, and filesystem adapter details are not parity targets.
Observable source behavior, reports, diagnostics, support accounting, semantic
introspection, virtual artifacts, generated HDL, and documented examples are
parity targets.

## Corpus Partitions

The harness must preserve the current regression-corpus taxonomy and make it
available to every variant:

- `supported_smoke`: required positive coverage for any feature the variant
  claims. The existing `t/296`, `t/301`, and `t/303` families are the Perl
  reference shape for this partition.
- `strict_supported`: supported-smoke entries that must also pass under strict
  mode. Variants must preserve the same strict-mode success/failure state and
  support-accounting marker.
- `expected_failure`: negative behavior that must fail closed with public
  diagnostics. The current classified-boundary coverage in `t/249` is the
  reference shape.
- `legacy_out_of_scope`: compatibility-covered behavior for the Perl reference
  that is not automatically a portable feature claim for a new variant. A
  variant either advertises and proves it explicitly, or reports it unsupported
  through a public diagnostic.
- `resource_sensitive`: fixtures that are valid public contract coverage but
  need a bounded direct check or smaller replacement gate in constrained
  environments. The oversized PPIF manager-capacity check-json path proved by
  `t/1466` is the current example.

## Differential Matrix

At minimum, a conforming variant must pass these parity families for every
advertised feature:

- Capability manifest parity: advertised file surfaces, operations, feature
  flags, support-accounting metadata, and semantic-introspection claims match
  the public contract for the claimed variant profile.
- Check JSON parity: `check` operation results match the public
  `check_schema_version`, success state, source classification, diagnostics,
  support accounting, result summary, and `generated_output` no-HDL-emission
  semantics.
- Semantic JSON parity: `semantic` operation results match normalized semantic
  schema version, command/source/support-accounting fields, sanitized semantic
  payloads, composition summaries, forward-IR summaries, and private-field
  exclusion.
- Lowering and schedule parity: `lower` and `schedule` operations preserve
  public generated review artifacts, schedule JSON, source-layer provenance,
  and deterministic artifact identity.
- HDL artifact parity: `generate_hdl` produces the same public HDL module/top
  behavior and required structural shapes for selected supported-smoke entries.
  Byte-for-byte HDL text is required for the Perl reference against itself and
  for variants that claim exact Perl text emission; otherwise, future variants
  must pass a selected normalized HDL comparison plus any available syntax or
  simulation validation selected by an owned backend-validation leaf.
- Verification-output parity: `verification_output` is compared only for
  currently shipped `.isf` targets unless a later exact owner widens direct
  `.ppif` verification-output behavior.
- Diagnostic and support-accounting parity: supported entries remain
  diagnostic-clean; unsupported or expected-failure entries fail closed with
  stable support-accounting classification and public diagnostic family/text
  after host-path normalization.
- Semantic-introspection and MCP parity: variants claiming introspection or MCP
  exposure must round-trip the same public semantic section and manifest
  contract used by `t/1438` and `t/1440`.

## Normalization Rules

The harness must normalize host-specific data before comparison:

- Source identity: compare stable `source_id`, corpus entry id, source kind,
  support-accounting entry id, and canonical relative identity. File-backed
  `source.resolved_path` remains a CLI adapter detail and must be path-normalized
  before cross-host comparison.
- Path-like values: normalize absolute paths, temporary directories, output
  directories, generated review-artifact roots, path separators, and home/CWD
  expansions to deterministic logical identities.
- JSON shape: compare decoded JSON values with deterministic key ordering for
  snapshots, normalized booleans, numeric values, arrays in public order, and no
  dependence on producer-specific whitespace.
- Generated-output metadata: compare logical emission state, requested output
  role, artifact identities, and no-HDL-emission semantics for `check` and
  `semantic` operations.
- Virtual artifacts: compare `relpath`, `kind`, `language`, `role`, `content`,
  `source_layer`, and `generated_from` after line-ending and path normalization.
  Artifact order must remain deterministic.
- HDL text: normalize line endings and selected non-semantic formatting only
  under an explicitly owned HDL normalization rule. Public module/top names,
  ports, declarations, assignments, state encodings, assertions, and structural
  behavior remain semantic comparison targets.
- Diagnostics: normalize file paths and line-ending differences, but preserve
  public diagnostic family, source context, support tier, migration hint, and
  fail-closed state.
- Resource measurements: runtime, RSS, temp path names, process ids, and host
  load are not parity targets. Resource-sensitive public behavior must instead
  be covered by bounded replacement tests.

## Resource Policy

Broad Perl/`prove`/`fsmgen` parity gates must run under
`scripts/run_with_ram_guard.sh` or an equivalent monitored wrapper before they
are used as signoff evidence in this environment. The default local policy is
host RAM 88 percent and descendant RSS 4096 MiB unless an owning task records a
safer exception.

The known full `t/301-check-json-supported-corpus.t` retry is host-memory-policy
blocked here after `.2.3.1`: one guarded retry stopped on host-memory cutoff and
a higher host cutoff retry was rejected by the approval layer. A future harness
implementation must keep the full public corpus as the logical parity target,
but it may split or replace resource-sensitive fixtures with bounded direct
tests when an owning leaf records the exact replacement and the public contract
coverage is equivalent. Do not bypass the rejected high-cutoff run without
explicit user approval.

## Pass/Fail Gates

A future variant may claim a feature only when all selected positive, negative,
report, artifact, and documentation gates for that feature pass against the
Perl oracle. Unsupported features must be advertised as unsupported or fail
closed through public diagnostics; silent drift, reduced reports, or omitted
support-accounting fields are failures.

The filesystem CLI adapter, pure in-memory host, browser/Wasm host, and
embedded/library host may expose different transport mechanics, but they must
produce the same normalized public result for the same logical request and
source graph.

## Deferrals

- No harness implementation code changes in this selector leaf.
- No new non-Perl implementation-language experiment until `.2.8` or a later
  exact owner.
- No mdBook language-X implementation blueprint structure until `.2.6`.
- No typed extension/plugin portability boundary until `.2.7`.
- No broad unguarded corpus reruns; resource-sensitive broad gates need the
  selected guarded or bounded replacement policy above.
