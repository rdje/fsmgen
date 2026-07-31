# Neutral Live-Document Size Checker Contract

This checker is project-neutral, project-agnostic, and harness-neutral. It
interprets local JSON Lines (JSONL) declarations; it contains no
adopting-project paths, thresholds, owners, document names, or tool vendors.
Every non-empty registry line is exactly one JSON object. Blank lines,
comments, malformed JSON, missing required keys, and unknown keys fail closed.

## Inputs

Each surface record has this shape:

```json
{"surface_id":"guide","lifecycle":"partitioned_canonical","locator":"collection","targets":["guide/*.md"],"index":"guide/INDEX.md","canonical_inputs":[],"routes_to":[],"owner":"guide-maintainers","health_targets":{"files":32,"lines_each":1000,"bytes_each":65536,"lines_total":12000,"bytes_total":1048576},"enforcement_ceilings":{"files":32,"lines_each":1100,"bytes_each":73728,"lines_total":13000,"bytes_total":1179648},"milestones":{"warning_pct":80,"rollover_pct":90},"containment_status":"steady","state":"normal","baseline":null,"verifier":"builtin:budget","currency":{"contract_id":"guide_source_alignment","verifier":"core:tools/check-guide-alignment"}}
```

`lifecycle` is one of `bounded_snapshot`, `partitioned_canonical`,
`generated_projection`, `rolling_ledger`, `archive_terminal`,
`external_terminal`, or `frozen_legacy`. `locator` independently describes how
the target is found: `file`, `collection`, `generated_file`, `query`,
`archive`, `external`, or `frozen`.

Measured file and collection records carry independent positive
`health_targets` and `enforcement_ceilings` plus ordered warning and rollover
percentages under `milestones`. Terminal records use JSON `null` for both
pressure objects, `milestones`, and `baseline`. `hard_pct` is not a schema key:
the absolute ceiling itself is inclusive, so equality passes and overflow
fails.

Health pressure is `actual / health target`; ceiling pressure is reported
separately and never determines whether a surface is healthy. File-count
pressure applies to collections, while singular file locators still enforce
their declared file-count ceiling without letting the unavoidable `1 / 1`
dominate health reporting. `containment_status` is `steady`, `migrated`, or
`pinned_deferred` for measured rows and `not_applicable` for terminal rows.
Debt states (`warning_debt`, `rollover_debt`, `structural_debt`) require an
owner and exact adoption-baseline measurements. An optional `transition`
object names one containment owner, nonnegative `max_growth`, and positive
`ratchet_step` values in the same five dimensions. The checker never rewrites
the baseline: actual measurements may exceed it only within that separately
declared bounded allowance, and baseline plus allowance must not exceed the
ceiling. A debt ceiling also satisfies
`ceiling <= max(actual, health_target) + 2 * ratchet_step`; this band permits
one atomic reduction step before the declaration must ratchet down. Healthy
measured records use
`normal`; query/archive/external rows use `terminal`; frozen rows use `frozen`.

`targets`, `canonical_inputs`, and `routes_to` are arrays, avoiding delimiter
and escaping conventions inside values. All local paths and patterns are
interpreted from the supplied project root. Generated projections name their
canonical input patterns in `canonical_inputs`; partitioned collections name
their bounded `index`, except an explicitly owned debt may use `null` until its
remediation lands. Other locators use a `null` index and an empty
`canonical_inputs` array.

`currency` is optional (or JSON `null`). When present, it contains exactly a
stable `contract_id` and a `verifier` using the same `core:`, `adapter:`, or
`external:` execution modes. Its meaning is local to the adopting project: the
neutral core executes the declared oracle but does not infer currency from
dates, file age, or size. Adapter proofs use `currency:ID`, independently from
freshness `surface:ID` proofs. Archive, external-terminal, and frozen
lifecycles cannot declare currency because their historical dates are not
current-state claims.

Each route record has this shape:

```json
{"route_id":"guide","source_surface_id":"entrypoint","marker":"guide/INDEX.md","target_surface_id":"guide"}
```

Each declared graph edge needs a route row. The marker must occur in the
source file when the source is file-backed. Unknown endpoints, undeclared
edges, duplicate route ids, and cycles fail closed.

The archive registry begins with one durable metadata record so a valid empty
registry remains trackable, followed by zero or more descriptor records:

```json
{"record_type":"registry","schema_version":1}
{"record_type":"descriptor","schema_version":1,"descriptor_id":"guide_0001","surface_id":"guide","former_path":"guide/old.md","range_id":"entries-1-20","revision":"0123456789abcdef","lines":500,"bytes":32000,"sha256":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","retrieval_kind":"file","retrieval_locator":"archive/guide-0001.md","current_pointer":"guide/INDEX.md","sealed_on":"2030-01-01","verifier":"builtin:file"}
```

Descriptors are optional until content leaves a live surface. When present,
their schema version, identifiers, relative paths, counts, digest, retrieval
kind, date, and verifier are validated. A `file` retrieval is also
digest-checked immediately;
Generated projections and `version_object` retrievals use one explicit
execution mode: `core:PATH`, `adapter:PATH`, or `external:CONTRACT`. The neutral
core executes a `core:` program from the supplied project root and accepts its
result only on exit zero. For `adapter:`, the adopter executes the program and
passes the exact `surface:ID`, `archive:ID`, or `currency:ID` proof token;
missing, duplicate, or unused tokens fail closed. `external:` is a visible degraded result and
cannot produce a local green result. Ordinary measured rows use
`builtin:budget`; file retrievals continue to use `builtin:file`.

## Coverage input

With `--coverage-stdin`, the checker reads a NUL-separated list of project-
relative document paths and requires every path to match at least one declared
surface target. How that list is produced is a local concern; the neutral core
does not assume a version-control system.

## Guarantees and limits

The checker validates schema, lifecycle/locator compatibility, repository-
relative and same-volume local targets, non-symlink files, per-part and
aggregate targets/ceilings, inclusive equality, debt acknowledgement and
ratchets, generated/version-object verifier execution, opt-in currency-oracle
execution, frozen identity, route closure,
archive-descriptor shape, and optional inventory coverage. It reports actual,
target, ceiling, and migrated/pinned/steady pressure separately. It never
mutates the project.

The neutral core validates one resulting tree. An adopting project that uses
Git may add a separate diff-aware authority registry and checker: every ceiling
increase must match exactly one newly appended authority row and one newly
added reviewed decision in the same change; lowering needs no authority. That
adapter may also enforce cross-revision baseline immutability. The authority
mechanism is intentionally separate because a ceiling declaration must not
authorize its own widening.

An adopting wrapper must discover and execute every `adapter:` verifier on
every run, pass only the proof tokens emitted after successful execution, and
remain reachable through the project's one unconditional commit/CI driver.
The core deliberately rejects a proof token that no current declaration
consumes, preventing stale or fabricated reachability from passing vacuously.
