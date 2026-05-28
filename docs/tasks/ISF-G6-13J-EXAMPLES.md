# ISF-G6-13J-EXAMPLES: Add Accept-Path Examples To 13j Type/Enum/Aggregate

## Metadata

- Tree ID: `ISF-G6-13J-EXAMPLES`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Address audit gap G6: 13j-type-enum-aggregate.md has only 6
examples for a feature surface that includes type aliases, enum
members, aggregate storage, and parameter defaults. Add 3 complete
accept-path actor fixtures (type alias, enum declaration, aggregate
storage) with Walkthroughs.

## Acceptance Criteria

- Three new `lisp` blocks in
  `docs/book/src/13j-type-enum-aggregate.md`:
    * `type_alias_demo` — local `(type byte (bits 8))` used by an
      input port.
    * `enum_demo` — local `(enums (mode (IDLE 0) (BUSY 1) (DONE
      2)))` with a constant that references an enum member.
    * `aggregate_storage_demo` — local `(type frame_t (record
      ...))` used as actor-owned storage.
- Each parses + lowers (locked by `t/1376`).
- Each carries a Walkthrough paragraph.
- Audits clean.

## Task Tree

- `ISF-G6-13J-EXAMPLES`, `ISF-G6-13J-EXAMPLES.1`, `ISF-G6-13J-EXAMPLES.2`.

## Commit Log

| Leaf | Subject |
| --- | --- |
| `.1` | `ISF-G6-13J-EXAMPLES.1: select 13j type/enum/aggregate examples` |
| `.2` | `ISF-G6-13J-EXAMPLES.2: ship 13j type/enum/aggregate examples` |
