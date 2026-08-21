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
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_inventory.pl --report && prove -Iperl
  t/1637-claim-verification-inventory.t
---

The source set expands governed surface IDs rather than copying paths. An
independent Git census must agree on every numeric line. Structural partitions
are explicit; ambiguous prose remains owned debt. Regeneration consumes
disposition IDs: closed candidates lose owners, unmatched candidates retain
them, and the reciprocal gate rejects stale state. Numeric leaves are derived
values or configured inputs, including schema identity. The original-cohort
manifest keeps source boundaries, counts, and ID digests; the checker
re-derives them and requires every current leaf's producer, oracle, and watcher.
