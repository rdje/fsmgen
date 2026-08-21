# 0076 — Original-constant cohorts derive from versioned sources

- Date: 2026-08-21
- Type: evidence architecture/governance
- Status: selected by `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.30`
- Refines: [0074](0074-actionable-claims-name-rederivation-falsification-and-durability.md)

## Context

The claim inventory identifies a numeric repository constant by source path,
JSONL record line, and structured pointer; its value is deliberately excluded.
The original-cohort manifest stored each source's last adoption-time line,
constant count, and identity digest. The checker then reconstructed all numeric
leaves through that boundary from the current file.

That reconstruction confused location with membership. A valid post-adoption
field can be nested beneath a pre-existing record. During OSVVM documentation
synchronization, adding a live-document `warning_debt` object beneath an
existing surface record caused every numeric leaf in that new object to join
the supposedly frozen cohort. The checker correctly went RED against its own
algorithm, but the algorithm made normal schema evolution impossible.

## Decision

The compact manifest now names the full commit identity that created the
original claim inventory. For each declared source and line boundary, the
checker retrieves that exact versioned file and derives the historical
path/line/pointer identities. The recorded per-source count and digest must
match that independently retrieved set.

The current repository is scanned separately. Every historical identity must
still be present, and every current numeric leaf must retain its current
producer, falsification oracle, and doctrine watcher. A new current identity is
allowed on any record line, including a line that existed at adoption. The
manifest has no refresh or rebaseline operation.

The exact adoption commit is retained through the repository's
`fsmgen_required_history` contract. If that object cannot be retrieved,
verification fails rather than silently substituting the current file.

## Consequences

- Frozen membership no longer expands when an existing JSONL record gains a
  legitimate nested numeric field.
- Removing or moving an adoption-time path/line/pointer identity still fails
  closed even when another new constant keeps the aggregate count unchanged.
- The current constant census remains complete and independently regenerated;
  the repair does not exempt new constants or their evidence legs.
- Values remain live derived or configured inputs, not copied historical
  authorities.
- Verification now requires complete access to the named Git commit, matching
  the full-history checkout already used by doctrine and Perl CI jobs.
