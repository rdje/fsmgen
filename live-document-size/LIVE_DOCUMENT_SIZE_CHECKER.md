# Neutral Live-Document Size Checker Contract

This checker is project-neutral, project-agnostic, and harness-neutral. It
interprets local JSON Lines (JSONL) declarations; it contains no
adopting-project paths, thresholds, owners, document names, or tool vendors.
Every non-empty registry line is exactly one JSON object. Blank lines,
comments, malformed JSON, missing required keys, and unknown keys fail closed.

Every common registry begins with exactly one bounded metadata record:

```json
{"record_type":"registry","schema_version":1,"max_records":32,"max_bytes":65536,"max_record_bytes":8192}
```

`max_records` counts data records after the metadata record. `max_bytes`
counts the entire file, including metadata and line terminators.
`max_record_bytes` counts the raw JSON content bytes on each line, excluding
its line terminator. All three values are positive, the record cap cannot
exceed the file cap, and the neutral core also imposes fail-safe portable
ceilings of 10,000 records, 16 MiB per registry, and 64 KiB per record. Local
registries normally declare much tighter limits. This makes the control plane
itself finite rather than using bounded documents with an unbounded registry.

## Inputs

Each surface record has this shape:

```json
{"surface_id":"guide","lifecycle":"partitioned_canonical","locator":"collection","targets":["guide/*.md"],"index":"guide/INDEX.md","index_contract":{"kind":"membership","verifier":"builtin:markdown_links"},"canonical_inputs":[],"routes_to":[],"owner":"guide-maintainers","health_targets":{"files":32,"lines_each":1000,"bytes_each":65536,"line_bytes_each":1024,"lines_total":12000,"bytes_total":1048576},"enforcement_ceilings":{"files":32,"lines_each":1100,"bytes_each":73728,"line_bytes_each":2048,"lines_total":13000,"bytes_total":1179648},"milestones":{"warning_pct":80,"rollover_pct":90},"containment_status":"steady","state":"normal","baseline":null,"verifier":"builtin:budget","currency":{"contract_id":"guide_source_alignment","verifier":"core:tools/check-guide-alignment"}}
```

`lifecycle` is one of `bounded_snapshot`, `partitioned_canonical`,
`maintained_reference`, `generated_projection`, `rolling_ledger`,
`archive_terminal`, `external_terminal`, or `frozen_legacy`. `locator`
independently describes how the target is found: `file`, `collection`,
`generated_file`, `query`, `archive`, `external`, or `frozen`.
`generated_projection` accepts a singular `generated_file`, a bounded generated
`collection`, or a terminal `query`; the generated-collection form is measured
on per-part, file-count, and aggregate axes like every other collection.

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
`ratchet_step` values in the same six dimensions. The checker never rewrites
the baseline: actual measurements may exceed it only within that separately
declared bounded allowance, and baseline plus allowance must not exceed the
ceiling. A debt ceiling also satisfies
`ceiling <= max(actual, health_target) + 2 * ratchet_step`; this band permits
one atomic reduction step before the declaration must ratchet down. Healthy
measured records use
`normal`; query/archive/external rows use `terminal`; frozen rows use `frozen`.

### Maintained product reference

`maintained_reference` is an information lifecycle for unique prose whose
aggregate legitimately follows product or specification scope. It still uses
the `collection` locator and semantic partitions, but it is not merely a
synonym for `partitioned_canonical`: a timeless aggregate size cap would be
decorative or would eventually force deletion of unique material.

Its ordinary pressure objects keep the exact six keys but use JSON `null` for
`files`, `lines_total`, and `bytes_total`. The `lines_each` and `bytes_each`
and `line_bytes_each` values remain positive fixed health targets and inclusive
ceilings. A debt baseline, growth allowance, and ratchet use the same nullable
aggregate shape.
`null` means that the fixed pressure axis is inapplicable; it does not mean the
aggregate is unmeasured or may change without review.

Every maintained reference requires a bounded single-line `classification`
object with `audience`, stable identifier `role`, and `rationale`, plus this
contract:

```json
{"classification":{"audience":"tool users","role":"unique_product_reference","rationale":"These explanations are maintained here and grow only with the product contract."},"reference_contract":{"mandatory_read":{"path":"guide/SUMMARY.md","lines_ceiling":64,"bytes_ceiling":4096},"max_navigation_depth":1,"aggregate_change":{"authority_id":"GUIDE-CHANGE.7","owner":"guide-maintainers","rationale":"Document the newly shipped transaction feature.","baseline":{"files":12,"lines_total":4000,"bytes_total":240000},"delta":{"files":1,"lines_total":180,"bytes_total":10500}}}}
```

The mandatory-read path must equal the collection index. Its line and byte
ceilings are checked independently. A membership index must link every matched
part directly; this proves navigation depth one for a multi-part collection.
The ordinary membership check remains responsible for completeness.

The neutral core measures aggregate files, lines, and bytes and requires each
to equal `baseline + delta`. A local revision-aware adapter must additionally
prove that `baseline` is the prior tree measurement and `delta` is the exact
current-minus-prior change whenever the aggregate moves. A nonzero change
requires a fresh authority id. The resulting last-change record remains
immutable across unrelated commits; unchanged content cannot modify or bank an
authority, and an established maintained-reference lifecycle cannot disappear
silently. This makes aggregate change attributable without inventing a fixed
product-size ceiling.

`targets`, `canonical_inputs`, and `routes_to` are arrays, avoiding delimiter
and escaping conventions inside values. Each array has a finite cardinality
and each element has a byte limit; identifiers, paths, owners, rationales,
markers, guarantees, and recovery text likewise have field-specific byte and
syntax bounds. Newlines are forbidden inside scalar strings. All local paths and patterns are
interpreted from the supplied project root. Generated files and generated
collections name their canonical input patterns in `canonical_inputs`;
partitioned collections name their bounded `index`, except an explicitly owned
debt may use `null` until its remediation lands. A generated collection also
names its bounded root index and exact index contract. Other locators use a
`null` index and an empty `canonical_inputs` array.

Every non-null collection index has an exact `index_contract`. `membership`
with `builtin:markdown_links` resolves the index's relative Markdown links and
requires every matched collection member except the index itself. `generated`
with `surface:ID` requires that ID to be an executed generated projection: a
generated file whose sole target is the index, or a generated collection whose
bounded index is that path. `query` with `builtin:registry_targets`
declares that the exact target-pattern expansion is the complete query rather
than claiming the Markdown front door lists every member. Omitting a member
from a membership index or mislabeling the alternate contract fails closed.

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
{"route_id":"guide","route_kind":"reader_navigation","source_path":"README.md","source_surface_id":"entrypoint","marker":"guide/INDEX.md","target_surface_id":"guide"}
```

`route_kind` is exactly `reader_navigation` or `author_overflow`; the two are
not interchangeable because readers may legitimately visit append-only
history while authors must not append new prose there. `source_path` names the
actual navigation or emitted-hint source, and its literal marker must occur
there. Each declared graph edge needs at least one route row. Unknown
endpoints, undeclared edges, duplicate route ids, wrong kinds, missing source
markers, and cycles fail closed. An adopter-side source scanner must also
derive author candidates from enforcer output so deleting a registry row
cannot hide an emitted overflow destination.

Evidence-map records have this shape:

```json
{"map_id":"review_packet","source_path":"docs/REVIEW.md","begin_marker":"<!-- EVIDENCE:BEGIN -->","end_marker":"<!-- EVIDENCE:END -->"}
```

The marker pair must occur exactly once and in order. Inside it, each Markdown
table evidence cell has one backticked repository-relative file path. A map
with no path rows, an unsafe path, or a missing/non-regular/off-volume file
fails closed.

The archive registry uses the same bounded metadata contract so a valid empty
registry remains trackable, followed by zero or more descriptor records:

```json
{"record_type":"registry","schema_version":1,"max_records":32,"max_bytes":65536,"max_record_bytes":4096}
{"record_type":"descriptor","schema_version":1,"descriptor_id":"guide_0001","surface_id":"guide","former_path":"guide/old.md","range_id":"entries-1-20","revision":"0123456789abcdef","lines":500,"bytes":32000,"sha256":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","retrieval_kind":"file","retrieval_locator":"archive/guide-0001.md","current_pointer":"guide/INDEX.md","sealed_on":"2030-01-01","verifier":"builtin:file"}
```

Descriptors are optional until content leaves a live surface. When present,
their schema version, identifiers, relative paths, counts, digest, retrieval
kind, date, and verifier are validated. A `file` retrieval is also
digest-checked immediately.

The separately bounded ledger-manifest registry is likewise valid while empty.
An opted-in `rolling_ledger` has exactly one ledger record followed by ordered
range records:

```json
{"record_type":"ledger","schema_version":1,"ledger_id":"changes","surface_id":"change_history","current_path":"CHANGES.md","index_path":"changes/INDEX.md","entry_start_prefix":"### ","ordering":"append_only","source_descriptor_id":"changes_source","total_entries":120,"entries_lines":2400,"entries_bytes":160000,"entries_sha256":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","current_entry_limit":20,"index_lines_ceiling":128,"index_bytes_ceiling":8192,"reconstruction_verifier":"builtin:concatenate","archive_transition":{"archive_surface_id":"exact_history","max_live_ranges":8,"max_live_lines":12000,"max_live_bytes":786432}}
{"record_type":"range","schema_version":1,"range_id":"changes_0001","ledger_id":"changes","sequence":1,"first_ordinal":1,"last_ordinal":100,"entry_count":100,"revision":"0123456789abcdef","lines":2000,"bytes":130000,"sha256":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","first_entry_sha256":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","last_entry_sha256":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef","storage_kind":"sealed_file","storage_locator":"changes/0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef.md","verifier":"builtin:file"}
```

The ledger record binds a singular rolling-ledger surface to a separately
bounded index, a literal start-of-line entry prefix, append-only physical
ordering, one exact complete-source archive descriptor, aggregate entry
identity, a bounded current window, and finite live sealed-history limits.
Each range records contiguous sequence and ordinal spans, entry count,
revision, dimensions, whole-range digest, and first/last entry identities.
Exactly one `current` range is last. Earlier ranges use content-addressed
`sealed_file` storage or an `archive_descriptor` whose range, revision,
dimensions, digest, surface, and current pointer agree exactly.

The built-in verifier extracts only complete prefix-delimited entries,
concatenates every readable range in sequence, matches aggregate dimensions
and digest, and compares the result byte for byte with the entries in the
complete-source descriptor. If any range or source is a version object, a
declared `core:` or proved `adapter:` reconstruction verifier must perform that
same comparison; `external:` remains degraded and cannot pass. The index must
name every range. Live sealed files cannot exceed the declared range, line, or
byte transition limits; older ranges must cross the already verified archive
descriptor boundary instead. This bounds the current view, navigation view,
and repository-live history independently without splitting an entry.

Every `version_object` descriptor adds a `retention_contract` identifier. The
separate bounded registry named by `--retention-contracts` begins with one
metadata row and then declares its owner, guarantee, and recovery action:

```json
{"record_type":"registry","schema_version":1,"max_records":16,"max_bytes":8192,"max_record_bytes":4096}
{"record_type":"contract","schema_version":1,"contract_id":"required_history","owner":"repository-maintainers","guarantee":"Referenced objects remain reachable from the authoritative repository or its controlled backup.","recovery":"Fetch complete history; if rewriting removed the object, restore it from the controlled backup or materialize a content-addressed repository file, then rerun the gate."}
```

Missing, unknown, duplicate, unbounded, or malformed contracts fail closed.
The contract makes conditional history retention explicit; evidence that must
survive independently of repository history should instead use a
content-addressed `file` retrieval. A failed local version-object verifier
reports the contract identifier, owner, and recovery action.

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
relative and same-volume local targets, non-symlink files, bounded control
registries and scalar/array shapes, per-part and
applicable aggregate targets/ceilings, maintained-reference classification and
exact aggregate authority, inclusive equality, debt acknowledgement and
ratchets, maximum content-line bytes, generated/version-object verifier execution, opt-in currency-oracle
execution, frozen identity, typed route closure, collection-index contracts,
evidence-map paths, retention-contract and archive-descriptor shape, bounded
whole-entry ledger order/reconstruction/archive transition, and
optional inventory coverage. It reports actual, target, ceiling, and
migrated/pinned/steady pressure separately. It never mutates the project.

The neutral core validates one resulting tree. An adopting project that uses
Git may add a separate diff-aware authority registry and checker: every ceiling
increase must match exactly one newly appended authority row and one newly
added reviewed decision in the same change; lowering needs no authority. That
adapter may also enforce cross-revision baseline immutability. The authority
mechanism is intentionally separate because a ceiling declaration must not
authorize its own widening.

That Git adapter must likewise compare each `maintained_reference` aggregate
contract with the prior revision. Its per-change authority is separate from a
ceiling-increase authority: the former accounts for legitimate product-scope
change on deliberately uncapped aggregate axes, while the latter expands an
otherwise fixed contract boundary.

An adopting wrapper must discover and execute every `adapter:` verifier on
every run, pass only the proof tokens emitted after successful execution, and
remain reachable through the project's one unconditional commit/CI driver.
The core deliberately rejects a proof token that no current declaration
consumes, preventing stale or fabricated reachability from passing vacuously.
When Git supplies the commit tree, the wrapper must also reject controlled
structural inputs that differ between the staged result and the worktree read
by the neutral core. This keeps route, index, and evidence checks about the
tree being committed rather than a convenient neighboring snapshot.
