---
id: claim-verification-record-enforcement
title: Exact claim blocks bind three distinct structural evidence legs
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
date: 2026-10-18
status: current
tags: [claim-verification, doctrine, evidence, registry]
evidence: >-
  CLAIM_VERIFICATION.md; docs/decisions/0074-actionable-claims-name-rederivation-falsification-and-durability.md;
  doctrine/claim_verification/claim_registries.jsonl; scripts/check_claim_verification.pl;
  t/1636-claim-verification-doctrine.t; docs/tasks/CLAIM-VERIFICATION-TEMPLATE-REVIEW.md
reverify: >-
  scripts/check_claim_verification.pl && prove -Iperl
  t/1636-claim-verification-doctrine.t && scripts/run_with_ram_guard.sh -- bash -c
  'for reader in verify_failed verify_corrected_failed; do python3 -B
  docs/audits/original-join-parent-acceptance-20261018/$reader.py || exit; done'
---

`doctrine/claim_verification/claim_registries.jsonl` selects bounded registries;
explicit `--registry` retains single-file fixtures (`0094`). Exact blocks bind
re-derive/falsify/durability evidence or owned gaps. Invalid bounds, unsafe or
untracked paths, missing/duplicate markers and identical evidence/path legs
reject. Truth and conceptual oracle independence need review (`0074`). `0104`
adopts `CLAIM-VERIFICATION-TEMPLATE-REVIEW.2` rules without checker changes.

On 2026-10-18 the original prerequisite default rejects the live factory at
`container_common.public` (`064cf9`); legitimate publication `a0561d9` advanced it.
All twelve helpers match; exact old/current guards separate. The factory-only
corrected view then rejects `repaired_preflight`: that commit also advanced the
publication test. Both failures retain; complete runtime source-role repair is
owned before later execution. Native/private/HIAL assurance stays open.
