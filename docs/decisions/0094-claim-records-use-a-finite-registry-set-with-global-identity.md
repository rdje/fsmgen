# 0094 — Claim records use a finite registry set with global identity

- Date: 2026-09-01
- Type: evidence architecture/governance
- Status: accepted
- Refines: [0074](0074-actionable-claims-name-rederivation-falsification-and-durability.md)
- Implementation owner: `CLAIM-VERIFICATION-REGISTRY-PARTITION`

## Context

The original bounded claim checker stores registry metadata and every claim in
one canonical JSONL file. That file now contains 25 claims plus metadata: 26
lines, 65,381 bytes, and SHA-256
`38b77b69f5fdad6350e665e0aa4abbf19c89ed94097e7b3ad424a0d3179170bc`
against its unchanged 65,536-byte ceiling. Only 155 bytes remain.

This is real admission exhaustion, not merely an average-size forecast. A
canonical schema-shaped record using one-character scalar/path values is
still 477 bytes when every evidence leg is explicitly missing and 498 bytes
when every leg is available. Those deliberately optimistic shapes are lower
bounds: actual valid tracked paths, owner IDs, claims, and evidence can only be
longer. The current checker confirms the real registry has 24 published claims
and one conformance fixture; its smallest actual claim line is 1,082 bytes.

The pressure was exposed while extending an existing record. Raising the file
ceiling would discard the bounded-admission property without addressing the
single-file growth topology. Moving or rewriting the current records would
also create needless source-of-truth churn: global claim identity and exact
source markers do not require all records to share one physical file.

Evidence for the saturation measurement is dimensionally separated:

- Re-derive with `wc -l -c doctrine/claim_verification/claims.jsonl`,
  `shasum -a 256 doctrine/claim_verification/claims.jsonl`, and
  `scripts/check_claim_verification.pl`.
- Falsify the remaining-capacity hypothesis by canonically encoding the
  required schema twice with one-character values: once with three explicit
  missing legs and once with three available legs. Their 477/498-byte lower
  bounds both exceed the 155-byte residue.
- Make the result durable through the owning task, this decision, the existing
  claim doctrine, and the partition watcher selected below. The inability to
  add an independent registry record is the exact gap this task repairs.

## Decision

1. The default FSMGen claim doctrine consumes one bounded canonical JSONL
   **registry set** whose entries enumerate every claim shard. An explicit
   `--registry` option remains available for portable single-file fixtures and
   compatibility probes; default repository validation uses the set.
2. The registry set is itself finite: at most 65,536 bytes, 64 shard entries,
   and 512 bytes per entry. It declares aggregate ceilings of 4,194,304 shard
   bytes and 8,192 claim records. The checker retains hard upper bounds for all
   five values rather than trusting larger data-supplied limits.
3. Shard ordinals are contiguous from one. Ordinal one is
   `doctrine/claim_verification/claims.jsonl`; later ordinals use the exact
   sibling form `claims-NNNN.jsonl`. The checker compares the manifest with
   the complete tracked sibling-name census, rejecting missing, extra,
   duplicate, reordered, nonlocal, untracked, symlinked, or nonregular state.
4. Every shard retains the existing canonical JSONL metadata and hard limits:
   65,536 bytes, 4,096 bytes per record, and 256 claim records. Partitioning
   therefore adds bounded aggregate capacity without weakening a local file
   boundary.
5. Shards are storage partitions, not separate semantic namespaces. The
   checker merges them before enforcing global claim-ID uniqueness,
   classification totals, owner/path/leg constraints, and exact marker
   closure. Records stay lexically ordered inside each shard; the global
   semantic projection is lexical claim ID independent of shard placement.
6. Initial migration keeps the current 65,381-byte shard byte-for-byte intact,
   adds an empty second shard, and introduces the registry set. Existing claim
   text, evidence legs, producer paths, source markers, dispositions, and
   historical identities do not change merely because capacity rolls over.
7. A focused watcher must first fail against the single-registry checker, then
   prove the positive two-shard set plus manifest/shard/aggregate bounds,
   cross-shard duplicates, ordering, tracked-name closure, path locality, and
   exact production migration.
8. This repair raises no existing claim-shard or live-document containment
   ceiling. Any future need beyond the finite registry-set aggregate is a new
   task-owned architecture decision, not an automatic expansion.

## Consequences

- New independent claims regain a full bounded shard without rewriting the
  saturated historical shard.
- Physical rollover cannot create duplicate IDs, orphan markers, or a second
  unchecked claim namespace.
- Default doctrine cost remains bounded by explicit manifest, aggregate,
  per-shard, per-record, and tracked-name limits.
- Portable single-registry conformance tests remain small and directly usable.
- The HIAL quantitative frontier resumes only after checker implementation,
  production migration, documentation, inventory, containment, and doctrine
  closure are committed cleanly.
