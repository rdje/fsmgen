# ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS: Output Bundle Storage Members

## Metadata

- Tree ID: `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-23`
- Last updated: `2026-05-23`
- Owner: repo-local workflow

## Goal

Widen explicit `output_bundle` member lists from declared actor outputs only to
the next bounded LHS domain: declared actor-owned storage signals that bound
rule users may write.

## Non-Goals

- Do not add output-target users, transaction users, named-drive users,
  child-instance users, or storage-port resources.
- Do not add route mux/storage, fan-in/fan-out routing, ready/backpressure,
  fairness, hold/release, multi-capacity resources, or `round_robin`
  arbitration.
- Do not accept actor input ports, transaction-local ports, aggregate storage
  paths, bank roots, actor-network endpoints, inferred undeclared LHS targets,
  or arbitrary expressions as explicit members in this tree.
- Do not change the existing one-cycle static `priority` grant timing for
  `rule_slot` or `output_bundle`.

## Acceptance Criteria

- Resource entries may continue to use `(members name...)` only with
  `(kind output_bundle)`.
- Explicit output-bundle members may name declared actor output ports or
  actor-owned storage signals. Storage members must resolve to concrete
  scalar storage signals, including scalar vars and already scalarized bank
  element signals, not bank roots or aggregate paths.
- For an enforced `output_bundle` with explicit members and declared rule
  users, the lowerer fails closed if a bound rule writes a declared actor
  output or actor-owned storage signal outside the member list, or if a listed
  member in those domains is not written by any bound rule user.
- Successful arbitration preserves the existing one-cycle grant model and
  continues to expose bounded member evidence through
  `resource_arbitration[].members`.
- Parser, lowerer, report, public-contract, spec-index, and book audits pass;
  the broader ISF gate runs when implementation lands.
- ISF spec, downstream integration handoff, public contract, mdBook, roadmap
  status, task index, MEMORY, CHANGES, DEVELOPMENT_NOTES, and
  LIVE_ACHIEVEMENT_STATUS are synchronized.
- Each completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS`
  Status: `done`
  Goal: `Allow output_bundle members to name declared actor-owned storage signals`
  Children: `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.1`,
  `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2`

- ID: `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.1`
  Status: `done`
  Goal: `Select the bounded storage-member widening slice`
  Acceptance: `The roadmap, task index, and live docs identify the active
  slice, document the exact boundary, and confirm no compiler behavior changed`
  Verification: `documentation-only selection review, live-doc audits,
  git diff check`
  Commit: `3c1c656c`

- ID: `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2`
  Status: `done`
  Goal: `Implement actor-owned storage signals in output_bundle member lists`
  Acceptance: `The parser accepts and validates storage-signal members,
  lowering enforces declared-output/storage coverage for rule users, docs are
  synchronized, and focused plus broad checks pass`
  Verification: `syntax, focused resource/public/spec/book checks,
  mdBook build, broad ISF regression, post-closure audits, git diff check`
  Commit: `079ab51d ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2: ship storage members`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `closed` | `done` | `The selected storage-member widening slice is implemented, documented, validated, and ready for commit.` |

## Decisions

- `2026-05-23`: Select actor-owned storage signals as the next explicit
  member domain because the resource catalog already describes unmembered
  `output_bundle` intent as outputs or rule-written LHS targets, while the
  explicit member-list implementation currently covers declared outputs only.
- `2026-05-23`: Keep the first storage-member slice concrete-signal-only.
  Scalar vars and scalarized bank element signals have existing scheduled
  `.fsm` names and assignment targets; bank roots, aggregate paths, inferred
  undeclared LHS targets, and actor-network endpoints require separate
  ownership/report semantics.
- `2026-05-23`: Preserve the existing priority grant timing. Storage members
  are validation and report evidence for the already shipped whole-rule grant;
  they do not add route mux/storage or per-member scheduling.

## Open Questions

- None for this bounded slice. Broader resource kinds, output-target users,
  and route/storage ownership remain explicit backlog.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.1` | `prove -Iperl t/1303-isf-public-live-book-paths-audit.t t/1250-isf-spec-focused-test-index-audit.t` | `passed: Files=2, Tests=25` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.1` | `git diff --check` | `passed` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` | `perl -Iperl -c perl/FSM/Adapter/ISF/Parser.pm`; `perl -Iperl -c perl/FSM/Scheduler/ISF/LoweringIR.pm` | `passed` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` | `prove -Iperl t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t t/1220-isf-arbitration-schedule-report.t` | `passed: Files=3, Tests=14` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` | `prove -Iperl t/1176-isf-resource-priority-boundary.t t/1218-isf-rule-slot-resource-arbitration.t t/1220-isf-arbitration-schedule-report.t t/1140-isf-public-schedule-report-metadata-audit.t t/1255-isf-schedule-report-golden-matrix.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1250-isf-spec-focused-test-index-audit.t t/1305-isf-book-feature-matrix-audit.t` | `passed: Files=10, Tests=342` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` | `mdbook build docs/book` | `passed` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` | `./bin/ci-regression isf --no-book` | `passed: Files=250, Tests=1659` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` | `prove -Iperl t/1250-isf-spec-focused-test-index-audit.t t/1303-isf-public-live-book-paths-audit.t t/1305-isf-book-feature-matrix-audit.t t/1144-isf-public-tested-by-metadata-audit.t t/1112-isf-public-interface-contract.t t/1115-isf-public-interface-cli-manifest-audit.t` | `passed: Files=6, Tests=347` |
| `2026-05-23` | `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` | `git diff --check` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.1` | `3c1c656c ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.1: select storage members` | `selection slice` |
| `ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2` | `079ab51d ISF-OUTPUT-BUNDLE-STORAGE-MEMBERS.2: ship storage members` | `implementation slice` |

## Changelog

- `2026-05-23`: Created and activated the task tree.
- `2026-05-23`: Implemented explicit actor-owned storage signal members for
  `output_bundle` resources and synchronized public docs.
