---
id: claim-verification-record-enforcement
title: Claim records are bounded exact blocks with three structurally distinct legs
answers:
  - "how is claim verification mechanically enforced?"
  - "where is the claim verification registry?"
  - "how are claim re-derive falsify and durability legs checked?"
  - "can the claim checker prove semantic truth or oracle independence?"
  - "what checker rejects aliased claim verification legs?"
  - "how are missing claim evidence legs owned?"
date: 2026-08-20
status: current
tags: [claim-verification, doctrine, evidence, registry]
evidence: >-
  CLAIM_VERIFICATION.md; docs/decisions/0074-actionable-claims-name-rederivation-falsification-and-durability.md;
  doctrine/claim_verification/claims.jsonl; scripts/check_claim_verification.pl;
  t/1636-claim-verification-doctrine.t
reverify: >-
  scripts/check_claim_verification.pl && prove -Iperl
  t/1636-claim-verification-doctrine.t
---

`doctrine/claim_verification/claims.jsonl` is the bounded data-only registry.
Each record points to one exact source block and names re-derivation,
falsification, and durability evidence or an explicit task-owned gap. The
registered checker rejects malformed bounds, unsafe or untracked paths,
missing/duplicate markers, and exact evidence/path aliases. It proves this
plumbing only; semantic truth and conceptual oracle independence remain review
judgments under decision `0074`.
