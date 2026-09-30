---
id: live-document-decision-identity-capacity
title: Decision identity rollover preserves finite compatibility paths and current canonical partitions
answers:
  - "why does sealing more decision bodies not solve decision file-count rollover?"
  - "how is the decision identity and consumer census reverified?"
  - "what contract is selected for decision identity and index cardinality rollover?"
  - "which decision consumers must change before canonical records move?"
date: 2026-09-30
status: current
tags: [continuity, decisions, doctrine, knowledge-map]
evidence: scripts/audit_decision_identity_capacity.py; docs/audits/decision-identity-capacity-20260930.json; scripts/decision_records.py; t/1999-decision-identity-capacity-audit.t; t/1923-decision-record-archive.t; docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md
reverify: scripts/run_with_ram_guard.sh -- python3 -B scripts/audit_decision_identity_capacity.py --revision 25c01f0127144922ade78951b91439e1d9221c08 > .artifacts/decision-identity-capacity-reverify.json
---

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

## Identity/cardinality rollover selection — 2026-09-30

Owner `.51.3.1` audits the fixed admission revision
`25c01f0127144922ade78951b91439e1d9221c08`; the tracked census is historical,
not a copied current total. Its complete root population has 114 decision IDs
plus INDEX: 50 sealed forwarders and 64 canonical bodies. Adding one record
enters the unchanged 128-file target's rollover band. Another body seal leaves
those root identities present, so it cannot solve this dimension. Dropping
paths would break known provenance and cannot establish unseen external safety.

Select a finite pre-transition compatibility cohort and separate current
canonical semantic partitions. Preserve every existing root path and its
original heading destinations; freeze the compatibility population and its
rendering inputs so future records never create new root aliases. Keep the
existing sealed originals and exact reader. Place the unsealed canonical bodies
in continuity, language/API and verification partitions, with bounded indexes
and one complete root discovery page. New decisions belong only to those
partitions. Preserve identities, authority/supersession status, all question
keys, relative destination meaning and recoverable original text. The atomic
migration must prove source identity, semantic/navigation closure, current
working-set pressure and residue separately; ceilings do not increase.

This is an actual storage/navigation change, not permission to reclassify the
old growing collection. Its compatibility projection must be closed by exact
membership/byte/heading proofs, and current parts remain under declared finite
bounds. `.51.3.2` must split prerequisites before moving files; `.51.3.3` proves
fresh-record capacity and complete continuity before frontend work resumes.

The scoped full-basename census includes literal fragments and provenance.
Interface review also finds generic path consumers: Knowledge Map already scans
recursively, and memory bootstrap requires the root index. The ceiling-authority
validator currently admits only flat decision paths, so nested canonical
addition needs a precise authority-path integration and negative controls.
T1809 reads decision 0100's body/status directly; decisions 0062/0091 have
self-referential body searches. Their readers must follow canonical bodies.
Existing exported policy/provenance path strings remain stable. The published
sealed-reader index/navigation checks need complete partition-aware closure.
Do not alter immutable audit, calibration or historical source records.

Re-derive the fixed census with the front-matter command. The producer invokes
the pinned public reader in a same-volume temporary fixture and compares every
sealed original with its independent Git source, so future working changes do
not substitute reader inputs. Falsification uses exact index identity and
per-ID destination checks: T1999 observes equal-count duplicates, substituted
IDs, wrong destinations, missing and escaping routes refuse. T1923 preserves
original-byte and corrupt/stale navigation controls. Tracked producer, input
revision, census, tests and existing history-retention contract supply durability.
The consumer search covers tracked nonbinary full basenames; the separate
code search covers literal docs/decisions candidates in scripts/knowledge-map/
perl/t. Neither claims every dynamic or external consumer is enumerated.
No migration, external integration signoff or native HDL result is established.
