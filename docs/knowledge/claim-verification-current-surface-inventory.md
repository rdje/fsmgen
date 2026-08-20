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
date: 2026-08-20
status: current
tags: [claim-verification, inventory, current-surfaces, derived-constants]
evidence: >-
  doctrine/claim_verification/inventory_scope.json;
  doctrine/claim_verification/inventory.jsonl;
  scripts/check_claim_verification_inventory.pl;
  t/1637-claim-verification-inventory.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_inventory.pl --report && prove -Iperl
  t/1637-claim-verification-inventory.t
---

The inventory source set expands selected IDs from
`doctrine/live_document_size/surfaces.jsonl`; it is not a handwritten copy of
the paths being audited. A separate Git census must agree with the direct
scanner on every numeric source line. Structural incidental partitions are
explicit, while quantified and otherwise ambiguous numeric prose remains
actionable debt with an exact migration owner. Numeric doctrine leaves are
separately classified as schema identifiers, configured policy inputs, or
derived-and-watched repository constants. The tracked inventory census names
its own re-derive, falsify, and durability legs.
