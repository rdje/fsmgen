# Neutral Live-Document Size Checker Contract

This checker is project-neutral, project-agnostic, and harness-neutral. It
interprets local JSON Lines (JSONL) declarations; it contains no
adopting-project paths, thresholds, owners, document names, or tool vendors.
Every non-empty registry line is exactly one JSON object. Blank lines,
comments, malformed JSON, missing required keys, and unknown keys fail closed.

## Inputs

Each surface record has this shape:

```json
{"surface_id":"guide","lifecycle":"partitioned_canonical","locator":"collection","targets":["guide/*.md"],"index":"guide/INDEX.md","canonical_inputs":[],"routes_to":[],"owner":"guide-maintainers","budgets":{"files":32,"lines_each":1000,"bytes_each":65536,"lines_total":12000,"bytes_total":1048576},"milestones":{"warning_pct":80,"rollover_pct":90,"hard_pct":100},"state":"normal","baseline":null,"verifier":"builtin:budget"}
```

`lifecycle` is one of `bounded_snapshot`, `partitioned_canonical`,
`generated_projection`, `rolling_ledger`, `archive_terminal`,
`external_terminal`, or `frozen_legacy`. `locator` independently describes how
the target is found: `file`, `collection`, `generated_file`, `query`,
`archive`, `external`, or `frozen`.

Measured file and collection records carry positive `budgets` plus ordered
warning, rollover, and hard percentages under `milestones`. Terminal records
use JSON `null` for `budgets`, `milestones`, and `baseline`.
Debt states (`warning_debt`, `rollover_debt`, `structural_debt`) require an
owner and exact adoption-baseline measurements. An optional `transition`
object may name one containment owner and nonnegative `max_growth` values in
the same five dimensions. The checker never rewrites the baseline: actual
measurements may exceed it only within that separately declared bounded
allowance. Healthy measured records use
`normal`; query/archive/external rows use `terminal`; frozen rows use `frozen`.

`targets`, `canonical_inputs`, and `routes_to` are arrays, avoiding delimiter
and escaping conventions inside values. All local paths and patterns are
interpreted from the supplied project root. Generated projections name their
canonical input patterns in `canonical_inputs`; partitioned collections name
their bounded `index`, except an explicitly owned debt may use `null` until its
remediation lands. Other locators use a `null` index and an empty
`canonical_inputs` array.

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
`version_object` and `external` retrievals require an executable or declared
external verifier for the adopting project to run.

## Coverage input

With `--coverage-stdin`, the checker reads a NUL-separated list of project-
relative document paths and requires every path to match at least one declared
surface target. How that list is produced is a local concern; the neutral core
does not assume a version-control system.

## Guarantees and limits

The checker validates schema, lifecycle/locator compatibility, repository-
relative and same-volume local targets, non-symlink files, per-part and
aggregate budgets, debt acknowledgement, generated-verifier presence, frozen
identity, route closure, archive-descriptor shape, and optional inventory
coverage. It never mutates the project.

An executable verifier's presence does not prove its result. The adopting
project must register the verifier itself in the same unconditional commit/CI
driver when freshness or retrieval requires execution.
