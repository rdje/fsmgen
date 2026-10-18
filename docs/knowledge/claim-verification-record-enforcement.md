---
id: claim-verification-record-enforcement
title: Claim records bind exact blocks to three structurally distinct legs
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
date: 2026-10-18
status: current
tags: [claim-verification, doctrine, evidence, registry]
evidence: >-
  CLAIM_VERIFICATION.md; docs/decisions/0074-actionable-claims-name-rederivation-falsification-and-durability.md;
  doctrine/claim_verification/claim_registries.jsonl; scripts/check_claim_verification.pl;
  t/1636-claim-verification-doctrine.t; docs/tasks/CLAIM-VERIFICATION-TEMPLATE-REVIEW.md
reverify: >-
  scripts/check_claim_verification.pl && prove -Iperl
  t/1636-claim-verification-doctrine.t && scripts/run_with_ram_guard.sh -- python3 -B
  docs/audits/original-join-parent-acceptance-20261018/verify_failed.py
---

`doctrine/claim_verification/claim_registries.jsonl` selects the bounded registry set. Explicit `--registry` retains
single-file fixtures (decision `0094`). Each record binds an exact source block to re-derive/falsify/durability evidence
or an owned gap. The checker rejects invalid bounds, unsafe/untracked paths, missing/duplicate markers and identical
evidence/path legs. Semantic truth and conceptual oracle independence remain review judgments (`0074`).

Decision `0104` adopts the template rules under `CLAIM-VERIFICATION-TEMPLATE-REVIEW.2`; checker semantics
are unchanged.

Historical/current roles differ. The original prerequisite default replay on
2026-10-18 still checks the live factory at `064cf9`; legitimate publication
`a0561d9` changed it. All twelve helpers match. Exact-source historical/current
guards separate at `container_common.public`.
`docs/audits/original-join-parent-acceptance-20261018/verify_failed.py` authenticates
failed custody/diagnosis. The cohort stays failed; source-epoch repair is owned
before later execution. Native/private and HIAL assurance remain unreleased.
