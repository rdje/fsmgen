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
  - "why did native0 prerequisites fail after custody?"
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
  'for r in verify_failed verify_corrected_failed verify_snapshot_failed selected_intake epoch_constraints verify_selected_failed; do python3 -B
  docs/audits/original-join-parent-acceptance-20261018/$r.py || exit; done'
---

`0094`: bounded `claim_registries.jsonl` sets; `--registry`: single-file fixtures.
Blocks bind re-derive/falsify/durability legs/owned gaps; reject bad bounds,
unsafe/untracked paths, missing/duplicate markers, aliased legs. Truth/independence
need review (`0074`); `0104` adopts `CLAIM-VERIFICATION-TEMPLATE-REVIEW.2`; checker unchanged.

Historical live reads: `container_common.public` (`064cf9`) rejects `a0561d9`
factory drift; twelve helpers intact. Factory-only fails publication-test drift
(`repaired_preflight`). `1a40a1d` fails `model.inputs` on edited `8b9a726`
knowledge/decision cards. Empty locality dirs break after custody; later full-source
passes. Failures/gaps kept. `epoch_constraints.py` picks `192c9d` across whole
source/formal/import/runtime/canonical constraints; later epochs fail.
Physical/intake passed; semantics pending; current checks separate;
native/private/HIAL open. Native0 custody gap: undeclared KM query cache.
`verify_selected_failed.py`: later source/cache/query; runtime fix pending.
