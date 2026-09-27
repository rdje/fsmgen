# 0108 — Decision records seal originals with stable retrieval

Date: 2026-09-27
Type: architecture / continuity
Owner: SEMANTIC-INTROSPECTION-MCP-FRONTIER.51.2

## Context

The declared rationale collection reached rollover debt while a controller
architecture decision was pending. Increasing its ordinary allowance would
violate containment. The independently committed source census in
`docs/audits/decision-record-rollover-census-20260927.json` fixes record
identities and consumers before storage changes.

## Decision

Seal the complete `0001–0050` cohort in `history/0001-0050.json`. Original
UTF-8 record text is immutable and digest-checked against the prior census.
Storage does not change authority: existing supersession markers and active
policies remain exactly as written. Later semantic changes still require a
new decision and an explicit supersession reference.

Every original path remains a bounded forwarding page. The existing index
continues to discover those identities. `scripts/decision_records.py read ID`
returns original text; ordinary retrieval needs neither historical Git objects
nor network access. The generated `history/0001-0050.md` view relocates relative
links and provides stable per-record anchors. It contains no unique facts.
Its executed freshness verifier checks the entire view and all forwarding
pages against the originals, and checks affected Knowledge Map commands.

The archive is file-backed terminal storage with an exact descriptor. The
optional human view is a bounded generated projection, excluded from mandatory
bootstrap reads. Its fixed ceiling admits this sealed cohort and rendering
headers; the freshness gate prohibits appending content to either form. The
archive reader bounds every input and ID request and rejects unsafe paths,
symlinks, duplicate keys, missing/reordered records and altered original bytes.

Keep the live rationale collection's existing ceilings. Retire recovered line
and byte growth allowance; retain file-count warning pressure honestly because
stable aliases preserve cardinality. Another index/identity containment task
must precede file-count rollover. This migration grants no authority to raise
that ceiling, retire a policy, or activate the director-deferred reassessment
of other agent-era documents.

## Consequences

Direct text searches of sealed root pages now search pointers. Use the exact
reader for body searches; the affected Knowledge Map reverify commands do so.
Evidence and generated provenance retain their original decision paths.

Source identity, complete-record preservation, navigation/consumer closure,
live dimensions and residue are separate checks. Tests compare every public
reader result with the independent Git source and plant corrupt originals,
missing/duplicate/reordered members, stale views, broken aliases/index links,
missing destinations and obsolete body-search commands. Git retrieval is a
qualification oracle, not a production reader dependency.
