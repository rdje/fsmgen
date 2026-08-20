---
id: claim-verification-candidate-dispositions
title: Candidate dispositions join current inventory identities to bounded outcomes
answers:
  - "where are inventoried claim candidates dispositioned?"
  - "how does a completed claim migration group fail on open candidates?"
  - "which outcomes may close a claim inventory candidate?"
  - "how are stale claim candidate dispositions rejected?"
  - "how are reviewed incidental numerals recorded?"
  - "where are missing claim-evidence legs assigned to repair tasks?"
date: 2026-08-20
status: current
tags: [claim-verification, dispositions, inventory, evidence]
evidence: >-
  doctrine/claim_verification/disposition_groups.jsonl;
  doctrine/claim_verification/dispositions.jsonl;
  scripts/check_claim_verification_dispositions.pl;
  t/1638-claim-verification-dispositions.t;
  docs/tasks/CLAIM-VERIFICATION-ADOPTION.md
reverify: >-
  scripts/check_claim_verification_dispositions.pl --report && prove -Iperl
  t/1638-claim-verification-dispositions.t
---

Every current inventory candidate path belongs to exactly one bounded migration
group. Each recorded outcome joins a stable current candidate ID to one of four
forms: a published claim record on the same source path, a non-aliased
three-leg derived gate, a reviewed-incidental reason, or a task-owned evidence
gap. A group becomes required-complete only when its migration slice closes;
the checker then rejects any remaining open candidate. The join detects stale
or duplicate candidate IDs, but it does not turn the reviewer's classification
or declared evidence into semantic truth.
