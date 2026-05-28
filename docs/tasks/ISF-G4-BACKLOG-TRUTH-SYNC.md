# ISF-G4-BACKLOG-TRUTH-SYNC: Backlog Status Truth-Sync

## Metadata

- Tree ID: `ISF-G4-BACKLOG-TRUTH-SYNC`
- Status: `pending`
- Roadmap lane: `R14`

## Goal

Address audit gap G4: 14-feature-backlog.md has 43 `Status:`
markers and the recent diagnostic-precision/coverage slices added
sub-axis, loop-contained, deeper-nested, and book-lowering surfaces
that aren't summarized in a single section. Append a dated
"2026-05-29 status snapshot" near the chapter top so a reader can
see the recent surface additions without scanning the whole
chapter.

## Acceptance Criteria

- A new dated subsection near the top of
  `docs/book/src/14-feature-backlog.md` summarizing the recent
  shipped surface (sub-axis diagnostics, loop-contained,
  deeper-nested, cookbook recipes, book-example lowering build
  gate, contract/SPECFORGE handoff sync).
- Audits clean; mdBook clean.

## Commit Log

| Leaf | Subject |
| --- | --- |
| `.1` | `ISF-G4-BACKLOG-TRUTH-SYNC.1: select` |
| `.2` | `ISF-G4-BACKLOG-TRUTH-SYNC.2: ship` |
