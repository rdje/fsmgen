---
id: claim-verification-record-enforcement
title: Claim evidence legs
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
date: 2026-10-19
status: current
tags: [claim-verification, doctrine, evidence, registry]
evidence: >-
  CLAIM_VERIFICATION.md; docs/decisions/0074-actionable-claims-name-rederivation-falsification-and-durability.md;
  doctrine/claim_verification/claim_registries.jsonl; scripts/check_claim_verification.pl;
  t/1636-claim-verification-doctrine.t; docs/tasks/CLAIM-VERIFICATION-TEMPLATE-REVIEW.md
reverify: >-
  scripts/check_claim_verification.pl && prove -Iperl
  t/1636-claim-verification-doctrine.t && scripts/run_with_ram_guard.sh -- bash -c
  'for r in verify_failed verify_corrected_failed verify_snapshot_failed selected_intake epoch_constraints verify_selected_failed verify_runtime_cache; do python3 -B
  docs/audits/original-join-parent-acceptance-20261018/$r.py || exit; done'
---

`0094`: bounded `claim_registries.jsonl` sets; `--registry` single-file fixtures.
Legs: re-derive/falsify/durability or owned gaps. Reject bounds,
unsafe/untracked paths, missing/duplicate markers, aliases. Truth/independence:
review (`0074`); `0104` adopts `CLAIM-VERIFICATION-TEMPLATE-REVIEW.2`, checker unchanged.

`container_common.public`/`064cf9` rejects `a0561d9` live factory drift
(twelve helpers intact). Factory-only: publication-test drift (`repaired_preflight`).
`1a40a1d`/`model.inputs`: edited `8b9a726` knowledge/decision cards refuse.
Empty locality dirs fail custody; later full-source passes. Failures/gaps retain.
`epoch_constraints.py`: all `192c9d` source/formal/import/runtime/canonical
constraints pass; later epochs fail. Physical/intake pass; semantics/native/private/HIAL
pending; current checks separate. Native0 after-gap: undeclared KM query cache.
`verify_selected_failed.py`: later source/cache/query; `verify_runtime_cache.py`:
permissive cache/strict output; roles pending.
