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
  - "why was the experimental UVM resource peak removed from the rationale ledger?"
  - "how are bridge source-map calibration claims independently reconstructed?"
  - "why do total fibers live fibers and execution types use separate evidence?"
  - "how are checking-scale model scoreboard coverage and fault claims separated?"
  - "how does random replay distinguish semantic bridge and plan boundaries?"
  - "how are core language and tooling book claims separated from syntax and navigation numerals?"
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

The foundational root review also demonstrates the repair rule. An exact
experimental UVM peak had no tracked measurement producer, while the selected
guarded-envelope outcome and lower-memory compilation control were preserved by
the checked probe. The unsupported point estimate was removed instead of being
reclassified as evidence. Immutable book-partition and roadmap-occupancy
measurements remain historical dispositions whose reasons name their Git
producer, preserved independent audit, and durability path; live ledger,
complete-roadmap-archive, and provider-source-order claims use derived gates.

The bridge/execution review keeps each selected scale axis attached to its own
producer and separating oracle. Source-map calibration is differentially
rebuilt from baseline and one-record semantic shapes before the exact boundary
suite runs. Scenario-map collision is retained as pre-repair history with a
current uniqueness watcher. Total and live fibers use different generated tree
shapes, while execution types require real bound endpoints; rejected wide-tree
and unbound-alias examples are reviewed context rather than claim evidence.

The final root review keeps the checking families separate as well. The
foundation oracle derives owned and rejected catalog shapes. The model oracle
counts authored definitions, instances, declarations, and exercised cells;
scoreboard, coverage, and fault oracles independently reconstruct storage,
order, and lifecycle identities with targeted mutations. The random-replay
oracle distinguishes semantic preflight, bridge materialization, plan
rejection, and the adjacent semantic diagnostic. Exact guarded runs close the
root group, whose registry is now required-complete.

The first general-book review keeps compact language examples from becoming
accidental measurements. Grammar rejections, inferred widths, literal
normalization, declarative state models, composition inference, expression
factorization, hosted-test partitioning, target-language emission, and repeat
lowering use their ordinary tracked producers and focused behavior oracles.
Syntax operands, boolean option values, protocol-version tokens, test bands,
and linked test filenames are reviewed as non-claims. The LTE expected-failure
count has an additional source-derived control that counts the active child
entries independently of the catalog's diagnostic pattern.
