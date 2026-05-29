# ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING: Enable Deeper-Nested Repeat-Body Local `(do)` Lowering

## Metadata

- Tree ID: `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING`
- Status: `active`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Allow a plain local `(do child)` inside a `(repeat N ...)` reached through more
than one branch ancestor — `when`-inside-`when` (`when⁺ → repeat`) or
`when`-inside-a-`switch`-branch (`switch → when⁺ → repeat`) — to lower cleanly,
instead of failing closed with `deeper-nested repeat-body do remains deferred`.
Third scheduler-frontier slice (after loop-contained local-do and generated-do).

## Ground truth (probed at `bin/fsmgen` HEAD)

1. The deeper-nested fail-closed is validator-only
   (`_validate_repeat_body_spawn_subset`, `_repeat_body_context_is_deeper_nested`,
   LoweringIR.pm). The lowering recursion already supports the reachable shapes:
   `_expand_when` recurses into nested `when` (LoweringIR.pm ~L8095) and
   `_expand_switch` recurses into nested `when` (~L8138), each reaching
   `_ir_repeat`.
2. The validator's `SUPPORTED_TRANSACTION_CLAUSES` does **not** allow a nested
   `switch` inside a `when` body or a `switch` branch (probed: `unsupported
   '(switch ...)' clause in when body` / `... in switch branch`). So the only
   deeper-nested shapes that can reach the repeat gate are `when⁺ → repeat`
   (`when` depth ≥ 2) and `switch → when⁺ → repeat` (`switch` depth 1, `when`
   depth ≥ 1) — exactly the shapes the lowering recursion handles. There is no
   silent-drop shape to guard against.
3. For a **plain local do**, the four trailing `_ir_repeat` params are not
   consumed (as established by the local-do slice), so the nested `_expand_when`/
   `_expand_switch` recursions dropping them (8095/8138) is harmless here. A
   deeper-nested **generated** do would need those threaded through the nested
   recursions plus deeper collector discovery — out of scope, stays deferred.

## Scope (this tree)

- Enable a plain local `(do child)` (no `(params ...)`/`(bind ...)`/`(domain ...)`,
  target not a generated child) at deeper branch nesting reaching the repeat:
  `when⁺ → repeat` and `switch → when⁺ → repeat`.
- Keep deferred: deeper-nested generated `do` (new targeted `deeper-nested
  repeat-body generated do remains deferred` message), deeper-nested `spawn`
  (unchanged `deeper-nested repeat-body spawn remains deferred`), and any
  loop-contained context (handled by its own lane).

## Non-Goals

- No deeper-nested generated do or spawn (would require threading params through
  the nested branch recursions + deeper collector discovery).
- No new nesting combinations beyond what the validator already permits.

## Acceptance Criteria

- `when⁺ → repeat (do worker)` and `switch → when⁺ → repeat (do worker)` lower
  cleanly and round-trip (`--check-json` / HDL emit).
- Deeper-nested generated do and spawn still fail closed with targeted
  diagnostics.
- New `t/1381-isf-deeper-nested-repeat-body-local-do.t` golden-verifies the
  accept path and the still-deferred cases. `t/1375` updated where it asserted
  the now-lifted local-do deferral.
- Book/spec docs synced (13d, 13k, 14, 13h, 13b, ISF_SPEC + focused-test index,
  downstream/contract/SPECFORGE response).
- `prove -Iperl t/1381 t/1375 t/1374 t/1379 t/1380 t/1304 t/1307 t/1305 t/1376
  t/1332 t/1250` passes; repeat/loop + do/spawn/activation/lowering regression
  passes; mdBook clean; `git diff --check` clean.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING`
  Status: `active`
  Goal: `Lower deeper-nested (branch) repeat-body plain local (do); keep generated-do/spawn deferred.`
  Children:
    `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.1`,
    `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.2`

- ID: `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.1`
  Status: `pending`
  Goal: `Select the slice; record probed ground truth and scope.`
  Acceptance: `Task tree committed before any code/test/doc change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `pending`

- ID: `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.2`
  Status: `pending`
  Goal: `Relax the validator deeper-nested do gate for plain local do; add t/1381; update t/1375; sync docs; validate.`
  Acceptance: `Accept-path lowers + round-trips; deferred cases still fail closed; audits green.`
  Verification: `prove -Iperl t/1381 t/1375 t/1374 t/1379 t/1380 t/1304 t/1307 t/1305 t/1376 t/1332 t/1250; mdbook build docs/book; git diff --check`
  Commit: `pending`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.1` | `pending` | Selection commit before any code/test/doc change. |
| 2 | `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.2` | `pending` | Ship the validator relaxation + golden + doc sync. |

## Decisions

- `2026-05-29`: Scope to plain local `(do)` only, mirroring the loop-contained
  local-do slice. The reachable deeper-nested shapes and the lowering recursion
  support are already aligned (the validator blocks nested `switch`), so this is
  a clean validator relaxation with no lowering change.
- `2026-05-29`: Deeper-nested generated do stays deferred (the nested branch
  recursions drop the `_ir_repeat` params; enabling it is a later slice).

## Open Questions

- None blocking.

## Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.1` | `mdbook build docs/book`; `git diff --check` | `pending` |
| `2026-05-29` | `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.2` | `prove -Iperl t/1381 t/1375 t/1374 t/1379 t/1380 t/1304 t/1307 t/1305 t/1376 t/1332 t/1250`; `mdbook build docs/book`; `git diff --check` | `pending` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.1` | `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.1: select deeper-nested repeat-body local-do lowering` | `pending commit hash` |
| `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.2` | `ISF-DEEPER-NESTED-REPEAT-BODY-LOCAL-DO-LOWERING.2: ship deeper-nested repeat-body local-do lowering` | `pending commit hash` |

## Changelog

- `2026-05-29`: Created. Third scheduler-frontier slice. Plain local `(do)` at
  deeper branch nesting (`when⁺ → repeat`, `switch → when⁺ → repeat`); generated
  do and spawn stay deferred.
