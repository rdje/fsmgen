---
id: claim-verification-record-enforcement
title: Claim evidence and reader recovery
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
  - "why did published optional reader omission or reordering pass?"
date: 2026-10-21
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

`CLAIM_VERIFICATION.md`: policy/registries, distinct rederive/falsify/durability
legs or owned gaps. Structure proves no semantic truth or oracle independence.

Dated factory/source/intake/cache/compiler facts, original scope:

```bash
cat docs/audits/original-join-parent-acceptance-20261018/source-recovery-card-7748b2db479ffdf559f49ede08335b7418ebecfe979a9a9da973d9e582e2594a.txt
```

Frontier: `MEMORY.md` →
`docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md`.

List: `bash docs/audits/original-join-parent-acceptance-20261018/verify_claim_readers.sh --list`.

Epoch/failure/native/private gaps stay.
Git pins cache/dispatch/fixed-gap/caller/operand/AST/preparation/compile-only/allocation metadata.
Uniqueness missed membership/order. Git snapshots bind published order/membership; qualified additions retain.
