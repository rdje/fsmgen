---
id: claim-verification-record-enforcement
title: Exact claim blocks bind three structural evidence legs
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
  'for reader in verify_failed verify_corrected_failed verify_snapshot_failed snapshot_postrun_sources; do python3 -B
  docs/audits/original-join-parent-acceptance-20261018/$reader.py || exit; done'
---

`claim_registries.jsonl` (path above) bounds registry sets; `--registry` keeps
explicit single-file fixtures (`0094`). Exact blocks bind re-derive/falsify/durability
evidence or owned gaps. Reject invalid bounds, unsafe/untracked paths,
missing/duplicate markers and identical evidence/path legs. Truth and conceptual
oracle independence need review (`0074`). `0104` adopts
`CLAIM-VERIFICATION-TEMPLATE-REVIEW.2` rules without checker changes.

Historical defaults read live inputs. At `container_common.public` (`064cf9`),
`a0561d9` advanced the factory while twelve helpers retain; old/current guards
separate. Factory-only replay next rejects that commit's publication-test update
in `repaired_preflight`. Whole `1a40a1d` rejects consumer `model.inputs`:
complete knowledge/decision baseline is `8b9a726`, with later-edited cards.
The after observer rejects empty locality directories; a later full-source check
passes. Failures and the original gap retain. Whole snapshots cover tracked
inputs; select epochs from all original constraints. Current checks stay
separate; native/private/HIAL assurance stays open.
