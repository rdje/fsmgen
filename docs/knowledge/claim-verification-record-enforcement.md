---
id: claim-verification-record-enforcement
title: Claim evidence and original reader recovery
answers:
  - "where is the claim template review?"
  - "how is claim verification mechanically enforced?"
  - "where is the claim verification registry?"
  - "how are claim re-derive falsify and durability legs checked?"
  - "can the claim checker prove semantic truth or oracle independence?"
  - "what checker rejects aliased claim verification legs?"
  - "how are missing claim evidence legs owned?"
  - "why did the original prerequisite replay reject the canonical factory?"
  - "can a default saved reader still depend on live source?"
  - "why did the factory-only corrected prerequisite replay still fail?"
  - "why did the whole historical checkout reject canonical source bytes?"
  - "why did native0 prerequisites fail after custody?"
  - "are cache types enforced?"
  - "where are compile exec operands inventoried?"
  - "what binds compile-only inputs?"
  - "where are AST model inputs reconstructed?"
  - "why is the retained preparation correction a no-op?"
  - "where are dated reader-recovery facts retained?"
  - "where are payload namespace selectors qualified?"
date: 2026-10-19
status: current
tags: [claim-verification, doctrine, evidence, registry]
evidence: >-
  CLAIM_VERIFICATION.md;
  doctrine/claim_verification/claim_registries.jsonl; scripts/check_claim_verification.pl;
  docs/tasks/CLAIM-VERIFICATION-TEMPLATE-REVIEW.md;
  docs/audits/original-join-parent-acceptance-20261018/payload_closure.py; scripts/check_source_recovery_card.sh
reverify: >-
  scripts/run_with_ram_guard.sh -- bash
  docs/audits/original-join-parent-acceptance-20261018/verify_claim_readers.sh
---

`CLAIM_VERIFICATION.md` owns live policy and registry contracts: distinct
re-derivation, falsification and durability legs, or owned gaps. Structural
checks do not prove semantic truth or oracle independence.

Dated original reader-recovery facts retain in the complete pre-rollover card:

```bash
cat docs/audits/original-join-parent-acceptance-20261018/source-recovery-card-7748b2db479ffdf559f49ede08335b7418ebecfe979a9a9da973d9e582e2594a.txt
```

The archive preserves every factory/source/intake/cache/compiler fact and its
original scope. Current frontier: read `MEMORY.md`, then its owning leaf in
`docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md`.

List current source-model replay commands with:

```bash
bash docs/audits/original-join-parent-acceptance-20261018/verify_claim_readers.sh --list
```

Those readers retain their pinned epochs, first failures and native/private gaps.

Saved cache replay pins Git epochs.
