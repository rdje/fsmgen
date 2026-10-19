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
  'for r in verify_{failed,corrected_failed,snapshot_failed} selected_intake epoch_constraints verify_{selected_failed,runtime_cache} default_dispatch qualify_fixed_module_gap; do python3 -B
  docs/audits/original-join-parent-acceptance-20261018/$r.py || exit; done'
---

0094: bounded sets; --registry single-file fixtures.
Re-derive/falsify/durability or owned gaps; reject bounds/paths,
untracked paths, absent/duplicate markers, aliases. Truth/independence:
0074 review. 0104: CLAIM-VERIFICATION-TEMPLATE-REVIEW.2; checker same.
container_common.public/064cf9 rejects a0561d9 factory drift; 12 helpers intact.
Factory-only: repaired_preflight publication-test drift.
1a40a1d/model.inputs: edited 8b9a726 knowledge/decision cards refuse.
Empty locality dirs fail custody; later full-source passes. Failures/gaps retain.
epoch_constraints: 192c9d source/formal/import/runtime/canonical passes;
later epochs fail. Physical/intake pass; semantics/native/private/HIAL
pending; current separate. Native0 after-gap: undeclared KM query cache.
verify_selected_failed.py: later source/cache/query; verify_runtime_cache.py:
permissive cache/strict output; default_dispatch: entry edges.
qualify_fixed_module_gap.py: caller namespace stop; closure/effects open.
