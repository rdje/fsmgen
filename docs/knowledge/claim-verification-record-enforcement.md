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
  'for reader in verify_failed verify_corrected_failed verify_snapshot_failed snapshot_postrun_sources epoch_constraints; do python3 -B
  docs/audits/original-join-parent-acceptance-20261018/$reader.py || exit; done'
---

`claim_registries.jsonl` (path above) bounds registry sets; `--registry` keeps
explicit single-file fixtures (`0094`). Exact blocks bind re-derive/falsify/durability
evidence or owned gaps. Reject invalid bounds, unsafe/untracked paths,
missing/duplicate markers and identical evidence/path legs. Truth and conceptual
oracle independence need review (`0074`). `0104` adopts
`CLAIM-VERIFICATION-TEMPLATE-REVIEW.2` rules without checker changes.

Historical defaults read live inputs. `container_common.public` (`064cf9`)
rejects `a0561d9` factory advancement; twelve helpers retain. Factory-only replay
rejects its publication-test update in `repaired_preflight`. Whole `1a40a1d`
rejects consumer `model.inputs`: knowledge/decision baseline `8b9a726` has
later-edited cards. Empty locality dirs break the after observer; a separate
full-source check passes. Failures/gap retain. Its
`epoch_constraints.py` selects `192c9d` from whole source/formal/import/runtime/
canonical constraints; later epochs refuse. Physical/semantic admission
pending; current checks separate; native/private/HIAL open.
