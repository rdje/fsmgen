# MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC: AHB Alias Book Surface Sync

## Metadata

- Tree ID: `MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC`
- Status: `done`
- Roadmap lane: `roadmap/documentation alignment`
- Created: `2026-06-29`
- Last updated: `2026-06-29`
- Owner: repo-local workflow

## Goal

Bring stale mdBook language-surface prose back into alignment with the shipped
bounded `.ahb` AHB requester profile-alias surface.

## Non-Goals

- No parser, generator, HDL, runtime, support-accounting, manifest, sample, or
  test behavior changes.
- No AHB completer/subordinate, interconnect/decode, scoreboard, or full-manager
  implementation.
- No AHB source-reference import or source-fact extraction.

## Acceptance Criteria

- The language-surface mdBook prose lists `.ahb` with the shipped bounded
  profile aliases instead of historical unsupported suffixes.
- The backlog status prose keeps pre-`.700` `.ahb`-unsupported wording only as a
  dated historical note and points to the later `.700` shipped alias state.
- `IAL2-FEATURE-COMPLETENESS-FRONTIER.705` remains blocked on an approved local
  AHB/AHB-Lite source artifact.
- Focused documentation scans and doctrine checks pass.
- The completed leaf is committed through `COMMIT.md`.

## Task Tree

- ID: `MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC`
  Status: `done`
  Goal: `Synchronize stale mdBook AHB profile-alias public-surface prose.`
  Children: `MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC.1`

- ID: `MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC.1`
  Status: `done`
  Goal: `Repair stale mdBook AHB alias public-surface wording without behavior changes.`
  Acceptance: `The stale mdBook passages no longer claim shipped .ahb is outside the bounded public surface; historical backlog text remains dated; AHB source-reference blocker is unchanged; focused scans and doctrine checks pass.`
  Verification: `Focused scans confirmed the current language-surface chapter no longer lists .ahb among unsupported suffixes and that the backlog note marks pre-.700 unsupported wording as historical; mdbook build docs/book passed; git diff --check passed; scripts/check_doctrines.sh passed.`
  Commit: `MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC.1: sync AHB alias book surface`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC.1` | `done` | Completed; stale mdBook wording now matches shipped `.ahb` support and the AHB chapter. |

## Decisions

- `2026-06-29`: Scope is documentation-only sync. The live code, tests, support
  metadata, AHB samples, AHB chapter, and active IAL2 task tree already agree
  that `.ahb` is shipped for the bounded requester while `.705` is blocked on
  source material for subordinate/completer work.

## Open Questions

- None.

## Blockers

- None for this documentation sync. The separate AHB feature frontier remains
  blocked at `IAL2-FEATURE-COMPLETENESS-FRONTIER.705`.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-06-29` | `MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC.1` | `rg` focused mdBook scans; `git diff --check`; `mdbook build docs/book`; `scripts/check_doctrines.sh` | `passed` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC.1` | `MDBOOK-AHB-ALIAS-PUBLIC-SURFACE-SYNC.1: sync AHB alias book surface` | Documentation-only public-surface sync; no behavior changed. |

## Changelog

- `2026-06-29`: Created task tree.
- `2026-06-29`: Completed `.1`; synchronized stale AHB alias public-surface prose with shipped `.ahb` requester alias support.
