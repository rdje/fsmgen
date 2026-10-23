---
id: claim-verification-current-surface-inventory
title: Claim inventory scope derives from governed current-document surfaces
answers:
  - "where is the current-surface quantitative claim inventory?"
  - "how is the claim inventory source set derived?"
  - "how are incidental numerals separated from actionable claim debt?"
  - "what independently checks claim inventory completeness?"
  - "where are unwatched claims and untracked producers inventoried?"
  - "how do repository-derived numeric constants enter claim review?"
  - "how is the original doctrine constant cohort preserved?"
date: 2026-08-20
status: current
tags: [claim-verification, inventory, current-surfaces, derived-constants]
evidence: >-
  doctrine/claim_verification/inventory_scope.json;
  doctrine/claim_verification/original_constant_baseline.jsonl;
  doctrine/claim_verification/inventory.jsonl;
  scripts/check_claim_verification_inventory.pl;
  t/1637-claim-verification-inventory.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md; docs/tasks/PERL-POD-API-REFERENCE.md
reverify: >-
  scripts/check_claim_verification_inventory.pl --report && prove -Iperl
  t/1637-claim-verification-inventory.t
---

Scope expands governed surface IDs, not copied paths. An independent Git census
checks each numeric line. Structural partitions are explicit; ambiguous prose
is intended to remain owned debt. Disposition IDs close owners; unmatched
candidates keep theirs. Reciprocal gates reject stale joins. Numeric leaves are
derived or configured, including schema identity.

The original-cohort manifest binds adoption commit and per-source boundaries, counts
and ID digests. The checker reconstructs membership from that version, retains
every original ID in the census and allows later IDs anywhere in the JSONL tree. Each
leaf keeps its producer, oracle and watcher.

2026-10-23: continued `10.` can be mistaken for a list marker.
P2 repair: `PERL-POD-API-REFERENCE.6.6.1`.
