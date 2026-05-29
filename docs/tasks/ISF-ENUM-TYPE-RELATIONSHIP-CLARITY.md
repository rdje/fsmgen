# ISF-ENUM-TYPE-RELATIONSHIP-CLARITY: Document Actor-Local `(types)`↔`(enums)` Relationship (SPECFORGE Ask)

## Metadata

- Tree ID: `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY`
- Status: `done`
- Roadmap lane: `R14`
- Created: `2026-05-29`
- Last updated: `2026-05-29`
- Owner: repo-local workflow

## Goal

Answer the SPECFORGE clarity request dated `2026-05-29` in
`specforge/docs/FSMGEN_FEEDBACK.md` (read at the SPECFORGE repo;
FSMGen responds in its own `docs/SPECFORGE_FEEDBACK_RESPONSE.md`).
SPECFORGE asks three questions about the actor-local ISF declaration
surface and wants a precise, machine-checkable rule so a downstream
emitter can lower a recovered enum-like symbol deterministically.

This is a **documentation-clarity + downstream-handoff slice**, not a
bug fix. The behavior already exists; it was not stated explicitly.

## Ground truth (probed at `bin/fsmgen` HEAD, not asserted from docs)

1. **Does `(enums (NAME …))` alone establish a usable `(type NAME)`?**
   **No.** Using `(type mode)` on a width-bearing port when only
   `(enums (mode …))` is declared fails closed:
   `interface port '<p>' references unknown type 'mode'`. An enum name
   is **not** automatically a scalar type alias.
2. **Co-declaring `(type NAME (bits k))` AND `(enums (NAME …))` for the
   same NAME?** **Accepted — not a conflict.** The two occupy distinct
   declaration roles: `(type NAME (bits k))` is the scalar width alias;
   `(enums (NAME …))` is the member-value family. Co-declaration is the
   **required** way to make an enum name usable as a width-bearing
   port/storage/var type.
3. **Are unreferenced `(types)`/`(enums)`/`(constants)` valid?**
   **Yes.** Unreferenced actor-local declarations lower cleanly.
4. (Probed corollary, relevant to deterministic lowering) The
   co-declared `(bits k)` is **not** cross-validated against enum
   member magnitudes: `(type mode (bits 1))` with a member value `3`
   is accepted. The author/emitter chooses the width; for dense
   `0..N-1` enums SPECFORGE's `ceil(log2(member_count))` is an
   appropriate choice.

### Correction to SPECFORGE's pending reading

SPECFORGE's "enums-standalone" reading is correct **only when the enum
name is never used as a width-bearing type**. If a recovered symbol
must be used as `(type NAME)` on a port/storage var, the emitter
**must also** emit the backing `(type NAME (bits k))`; the enum alone
will fail closed as an unknown type. Co-declaration is safe and is the
intended mechanism.

## Non-Goals

- No parser/lowerer/runtime behavior change. The behavior is already
  shipped; this slice documents and locks it.
- Do not change SPECFORGE's repository. FSMGen replies only in its own
  `docs/SPECFORGE_FEEDBACK_RESPONSE.md`, the established channel.
- Duplicate same-namespace `(type NAME)`+`(type NAME)` entry behavior
  is out of scope for this ask (SPECFORGE asked about `(type)`↔`(enums)`
  cross-namespace co-declaration). Any duplicate-entry hardening is a
  separate future tree.

## Acceptance Criteria

- `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` actor-local-declarations
  section states: (a) enum names are not auto type aliases; (b)
  co-declaring `(type NAME)`+`(enums NAME)` is accepted and is the way
  to make an enum a width-bearing type; (c) the co-declared width is
  not cross-validated against members; (d) unreferenced decls are
  contract-valid.
- `docs/book/src/13j-type-enum-aggregate.md` states the same, with a
  runnable `lisp` `(actor …)` example showing enum + co-declared type
  used as a port type (gated by `t/1376`).
- `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` carries the rule in the
  SPECFORGE-facing handoff.
- `docs/SPECFORGE_FEEDBACK_RESPONSE.md` adds a dated response to the
  2026-05-29 clarity request, confirming the rule and correcting the
  pending reading.
- New `t/1378-isf-enum-type-relationship.t` locks: (A) enum-name-as-type
  without backing `(type)` is rejected; (B) co-declaration accepted;
  (C) unreferenced decls accepted.
- `prove -Iperl t/1378 t/1376 t/1305 t/1307 t/1332` passes; mdBook
  clean; `git diff --check` clean; live docs synced.
- Each leaf committed via `COMMIT.md`.

## Task Tree

- ID: `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY`
  Status: `done`
  Goal: `Document + lock the actor-local enum↔type relationship for SPECFORGE.`
  Children:
    `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.1`,
    `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.2`

- ID: `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.1`
  Status: `done`
  Goal: `Select the slice; record probed ground truth and doc-sync targets.`
  Acceptance: `Task tree committed before any doc/test change.`
  Verification: `mdbook build docs/book; git diff --check`
  Commit: `18791272`

- ID: `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.2`
  Status: `done`
  Goal: `Document the rule across contract/book/downstream/response docs + add t/1378; validate.`
  Acceptance: `t/1378 passes; book audits green; response recorded.`
  Verification: `prove -Iperl t/1378 t/1376 t/1305 t/1307 t/1332; mdbook build docs/book; git diff --check`
  Commit: `ship commit (this slice)`

## Current Frontier

| Order | Leaf | Status | Why next |
| --- | --- | --- | --- |
| 1 | `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.1` | `done` | Selection commit `18791272`. |
| 2 | `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.2` | `done` | Documentation + `t/1378` regression shipped; tree closed. |

## Decisions

- `2026-05-29`: Establish the answer by probing the live binary, not by
  reading docs (SPECFORGE explicitly wants the real rule confirmed).
  Lock it with a regression test so the contract is executable, which
  is the form SPECFORGE values most.

## Open Questions / Blockers

- None.

## Verification Log

| Date | Leaf | Checks | Result |
| --- | --- | --- | --- |
| `2026-05-29` | `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.1` | `mdbook build docs/book`; `git diff --check` | `PASS` |
| `2026-05-29` | `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.2` | `prove -Iperl t/1378 t/1376 t/1305 t/1307 t/1332` (Files=5, Tests=714, PASS); `mdbook build docs/book` (clean); `git diff --check` (clean) | `PASS` |

## Commit Log

| Leaf | Commit subject or reference | Notes |
| --- | --- | --- |
| `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.1` | `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.1: select ISF enum-type relationship clarity` | `18791272` |
| `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.2` | `ISF-ENUM-TYPE-RELATIONSHIP-CLARITY.2: ship ISF enum-type relationship clarity` | `ship commit (this slice)` |

## Changelog

- `2026-05-29`: Created in response to the SPECFORGE 2026-05-29 clarity
  request on the actor-local `(types)`↔`(enums)` relationship.
- `2026-05-29`: `.1` selection committed (`18791272`).
- `2026-05-29`: `.2` shipped. Documented the rule in
  `ISF_PUBLIC_INTERFACE_CONTRACT.md`, `13j-type-enum-aggregate.md` (new
  "Enum names are not type aliases" subsection + runnable accept-path
  `enum_with_type` example), `ISF_DOWNSTREAM_INTEGRATION_SPEC.md`
  §11.6.1, and a dated reply in `SPECFORGE_FEEDBACK_RESPONSE.md` answering
  all three questions and correcting the pending "enums-standalone"
  reading. Added `t/1378-isf-enum-type-relationship.t` (3 subtests, PASS).
  Validation green; tree closed.
