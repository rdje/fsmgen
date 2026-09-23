# CLAIM-VERIFICATION-TEMPLATE-REVIEW: Review the selected template revision

## Metadata

- Tree ID: `CLAIM-VERIFICATION-TEMPLATE-REVIEW`
- Status: `active`
- Roadmap lane: `evidence architecture`
- Created: `2026-09-06`
- Last updated: `2026-09-23`
- Owner: repo-local workflow

## Goal

Review the director-selected claim-verification template changes against the
locally authoritative policy before deliberately selecting any adoption.

## Non-Goals

No automatic upstream synchronization, imported deployment claims, changed
quantitative gates, or interruption of the owned CI startup repairs.

## Acceptance Criteria

Classify every template delta; accept, adapt, or reject each with local
rationale; own any policy/checker/book implementation before changing it.

## Task Tree

- ID: `CLAIM-VERIFICATION-TEMPLATE-REVIEW`
  Status: `active`
  Goal: `Review the changed template without silently replacing local authority.`
  Children: `CLAIM-VERIFICATION-TEMPLATE-REVIEW.1, CLAIM-VERIFICATION-TEMPLATE-REVIEW.2`

- ID: `CLAIM-VERIFICATION-TEMPLATE-REVIEW.1`
  Status: `done`
  Goal: `Select the locally useful template revisions and their enforcement limits.`
  Acceptance: `Disposition the domain-free rule, evidence granularity, reversible attribution, bidirectional set census, history oracle, challenged-claim grading, and revised examples; separate exact contracts from judgment and never require unsupported certainty. Reconcile existing local enforcement references against decision 0094 if this review exposes stale single-file-default guidance; do not change policy or checker semantics in this slice.`
  Verification: `Review at 8542aafd66505ee6e72c318d8d1ae85a166d6b8f: the adopted neutral body remains SHA-256 8f194574ec718749e90a402cf6e4dc6650e44f6185dd194853a54482eef68643; the caller-authorized, read-only, same-volume selected input is 9f99df25209c43afb74d77e348dd2d0cdb68ce96cf17a4f272ede8328f6046bd, unchanged since the September 6 comparison. The retained source/diff verifier independently parses 8 changed hunk headers, requires complete coverage by 12 dispositions, and rejects 6 corrupted controls. Semantic selection remains human/agent review, not a mechanically proven judgment. The stale Knowledge Map single-file default is reconciled with decision 0094. Local policy/checker bytes remain unchanged; focused tests passed (Files=2, Tests=15).`
  Commit: `CLAIM-VERIFICATION-TEMPLATE-REVIEW.1 commit`

- ID: `CLAIM-VERIFICATION-TEMPLATE-REVIEW.2`
  Status: `pending`
  Goal: `Apply the reviewed evidence rules to the local policy and contributor book guidance.`
  Acceptance: `Implement the 12 reviewed dispositions in the local policy, with a durable rationale and a traceable rule mapping. Preserve decision 0074 scope and incidental-numeral exclusions, exact semantic contracts, explicit evidence gaps, stochastic intervals, and the structural checker's limits. Explain safe attribution without replaying forbidden/spent captures. Keep external examples labeled and reject unsupported instant certainty. No checker-schema or HIAL admission changes. Synchronize the mdBook, verify links/rendered guidance and focused claim gates, then commit separately.`
  Verification: `Pending implementation; the retained review is a selection record, not adoption.`
  Commit: `pending`

## Decisions

- Preserve decision `0047` and conditional rationale updates, as reconfirmed by
  the director during startup. Do not restore the retired changelog.
- The selected input is the sibling PGEN `docs/CLAIM_VERIFICATION.md`; derive
  its physical root from the current checkout's sibling directory at review.
  No machine-specific absolute path is persisted.

- The 2026-09-23 review may retain a byte-identified copy of the authorized
  read-only template plus its exact diff/disposition evidence under an audit
  directory. No local policy or checker changes until a separate owned slice.

## Review evidence and next action

The bounded review bundle is `docs/audits/claim-template-review-20260923/`.
Re-derive source identity and diff coverage with:

```sh
python3 -B docs/audits/claim-template-review-20260923/review.py --verify-selected --qualify
```

Omit `--verify-selected` for fully repository-local replay. The tracked source,
manifest, exact diff and verifier are the durability leg; the six corrupted
controls are the falsification leg. Review judgments and later implementation
are not proved by hunk coverage. The initial manifest used a different
SequenceMatcher autojunk mode than unified_diff; parsing the saved diff
caught its two off-by-one context ranges. The manifest now uses the same mode,
and independent header parsing agrees. No policy adoption occurs in .1.
The next leaf is .2; its selected rules and adaptations are in `review.json`.

## Acceptance Checklist (.1)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S` on the original neutral-body
  digest locates `c9d96dc17 CLAIM-VERIFICATION-ADOPTION.2: install authoritative
  standard`; the selected template differs in 8 hunks. The canonical policy
  and decision 0094 already specify the registry set; only the fact-card
  default description had remained single-file.
- [x] **ADDRESSED (verified)** — `review.py --verify-selected --qualify`
  reports `retained review verified: 8 changed hunks, 12 dispositions; no
  policy adoption asserted` and rejects all 6 corruptions. Snapshot bytes
  equal the authorized input. The policy/checker are unchanged; .2 owns
  adoption. The fact card now names the manifest default and fixture override.
- [x] **NO REGRESSION** — RAM-guarded `prove -Iperl
  t/1636-claim-verification-doctrine.t t/1750-claim-verification-registry-set.t`:
  `All tests successful. Files=2, Tests=15`; `scripts/check_claim_verification.pl`
  accepts the 3-shard set with 53 records (52 published and 1 fixture).
  The mdBook already describes this unchanged contract; no product or
  contributor policy change is published by .1.

## Blockers

- No blocker for this review and its selected adoption, begun under
  unlimited PNT after clean Chapter 11 repair `8542aafd6`. Implementation will
  be separately owned; the template is not an upstream and HIAL gates stay closed.
