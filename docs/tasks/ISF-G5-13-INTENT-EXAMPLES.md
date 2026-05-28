# ISF-G5-13-INTENT-EXAMPLES: Add Happy-Path Examples To 13-Intent-Scheduling

## Metadata

- Tree ID: `ISF-G5-13-INTENT-EXAMPLES`
- Status: `pending`
- Roadmap lane: `R14`

## Goal

Address audit gap G5: 13-intent-scheduling.md is 1055 lines with
only 4 examples. Add 2 happy-path actor fixtures showing a basic
blinker and a request/ack handshake. Each comes with a Walkthrough.

## Acceptance Criteria

- New `lisp` blocks `blinker` and `handshake_intent` in
  `13-intent-scheduling.md`.
- Each lowers cleanly (locked by t/1376).
- Each carries a Walkthrough.
- Audits clean.

## Commit Log

| Leaf | Subject |
| --- | --- |
| `.1` | `ISF-G5-13-INTENT-EXAMPLES.1: select` |
| `.2` | `ISF-G5-13-INTENT-EXAMPLES.2: ship` |
