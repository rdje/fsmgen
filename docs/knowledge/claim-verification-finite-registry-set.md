---
id: claim-verification-finite-registry-set
title: Claim records use one finite manifest-addressed registry set
answers:
  - "where are claim verification records stored?"
  - "how does the claim registry roll over when one shard is full?"
  - "what bounds the claim verification registry set?"
  - "does claim registry sharding create separate claim namespaces?"
  - "how is single-file claim registry compatibility retained?"
date: 2026-09-01
status: current
tags: [claim-verification, registry, partition, bounded-discovery]
evidence: >-
  doctrine/claim_verification/claim_registries.jsonl;
  doctrine/claim_verification/claims.jsonl;
  doctrine/claim_verification/claims-0002.jsonl;
  scripts/check_claim_verification.pl;
  t/1750-claim-verification-registry-set.t;
  docs/decisions/0094-claim-records-use-a-finite-registry-set-with-global-identity.md;
  docs/tasks/CLAIM-VERIFICATION-REGISTRY-PARTITION.md
reverify: >-
  scripts/check_claim_verification.pl && prove -Iperl
  t/1750-claim-verification-registry-set.t
---

The no-argument claim doctrine reads the closed shard list in
`doctrine/claim_verification/claim_registries.jsonl`. The manifest, aggregate
shard bytes and records, each shard, each record, and the complete tracked
sibling census all have hard bounds. Shards retain local lexical ordering, but
the checker merges their claims before enforcing one global ID and exact
source-marker namespace.

The initial rollover preserves `claims.jsonl` byte-for-byte and adds
`claims-0002.jsonl` with metadata but no claim records. Explicit `--registry`
remains available for bounded portable fixtures; it does not alter production
discovery or create an independent accepted claim namespace.
