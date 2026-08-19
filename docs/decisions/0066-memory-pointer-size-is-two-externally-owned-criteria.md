# 0066 — The resume pointer is bounded by two different criteria, not one budget

- Date: 2026-08-19
- Type: infra/continuity governance
- Status: selected by `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.4`
- Supersedes: point 5 of [0065](0065-live-document-line-and-byte-targets-are-derived-as-a-pair.md); refines the numeric cap in [0007](0007-memory-architecture-supersedes-blob-narration.md)
- Implementation owner: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.4`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.4-ACTIVE-RESUME-BYTES-EACH`
- Surface: `active_resume`
- Dimension: `bytes_each`
- Change: `8192 -> 32768`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.4-ACTIVE-RESUME-BYTES-TOTAL`
- Surface: `active_resume`
- Dimension: `bytes_total`
- Change: `8192 -> 32768`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.4-ACTIVE-RESUME-LINES-EACH`
- Surface: `active_resume`
- Dimension: `lines_each`
- Change: `75 -> 150`
- Ceiling authority: `LIVE-DOCUMENT-LINE-TARGET-CALIBRATION.4-ACTIVE-RESUME-LINES-TOTAL`
- Surface: `active_resume`
- Dimension: `lines_total`
- Change: `75 -> 150`

## Context

Decision `0065` established that a surface's line and byte limits are normally
one derivation, and recorded `active_resume` as its stated exemption. `.4`
makes that exemption explicit rather than incidental, because the director set
a criterion for the byte dimension that has nothing to do with the line
dimension's purpose.

The two criteria are genuinely different questions:

- **Lines answer "is this still a pointer?"** `MEMORY_ARCHITECTURE.md` §1 and
  §12 name the ever-growing `MEMORY.md` as the anti-pattern the whole standard
  exists to prevent. The line cap is the mechanism that pushes content down into
  task trees (layer B) and decision records (layer C). It is an architectural
  control, not a display preference.
- **Bytes answer "can a resuming agent ingest it in one call?"** That is a
  reader-capability bound set by the director at 32,768 bytes. It says nothing
  about whether the content belongs in layer A.

Deriving either from the other produces a wrong answer. Deriving lines from
32 KiB at `MEMORY.md`'s measured 75 bytes per line yields roughly 440 lines,
which is the blob the standard forbids. Deriving bytes from a line cap yields a
number unrelated to what one read call can carry.

The live problem was never bytes. At 75 bytes per line a 60-line file is about
4,500 bytes, so the previous 8,192-byte ceiling was unreachable and raising it
alone would have changed nothing. The problem was line headroom: before `.2`
the containment warning fired at 48 lines against a documented 60-line cap, and
after `.2` the file sat at 47 of 60 — workable, but tight enough that each
session's update is compressed rather than stated plainly.

## Decision

1. `active_resume` `bytes_each` and `bytes_total` become `32,768`. This is the
   stated maximum for `MEMORY.md` and its criterion is single-call readability.
   It is an outer safety bound, deliberately not a pressure target: at the line
   cap the file is about 9,000 bytes, so this dimension does not bind and is not
   expected to.
2. `MEMORY_POINTER_LINE_CAP` in `scripts/check_memory_architecture.sh` becomes
   `120`, twice the previous cap and about 2.5x current use. This is the real
   cap and it remains the layer-routing control.
3. `active_resume` `lines_each` and `lines_total` become `150`, so the
   containment warning at 80% lands exactly on the 120-line cap. This preserves
   the alignment `.2` established: containment signals when the owning doctrine's
   cap is reached, and never restates that cap more tightly.
4. The line cap is **not** derived from 32,768 bytes and must not be in future.
   A request to enlarge `MEMORY.md` is a request about layer routing and is
   answered by asking what content is in the wrong layer, not by dividing the
   byte ceiling by bytes per line.
5. `MEMORY_ARCHITECTURE.md` keeps its neutral `~50 lines` guidance and its
   `MEMORY_POINTER_LINE_CAP` knob. FSMGen's local value diverges from the
   default under §9.1, which already designates that cap as the per-project
   knob; the portable standard is not rewritten to carry a local number.
6. This supersedes `0065` point 5 only. Every other part of `0065`, including
   the derivation rule for surfaces with one criterion, stands unchanged.

## Consequences

- `MEMORY.md` moves from 78.3% line pressure before `.2`, to 62.7% after `.2`,
  to **33.3% lines and 11.6% bytes** here (surface peak 37.9%, now carried by
  `line_bytes_each`, which neither criterion governs). The compression pressure on every
  resume update is gone.
- The anti-blob control survives at 120 lines. It is looser, and that is the
  real cost: content that should have been routed to layer B or C can now sit in
  layer A about twice as long before the gate objects. Reviewers should keep
  treating a growing resume pointer as a routing failure, not as normal.
- A future reader of `surfaces.jsonl` alone would infer a 150-line allowance.
  The binding cap is 120 in `scripts/check_memory_architecture.sh`, and this
  record plus `0065` are where that split is written down.
- No milestone percentage, ratchet, verifier, authority requirement, decision
  pairing, or debt baseline changes. Four ceiling increases, four authority
  rows, one paired record.

## Containment

One bounded rationale record under the existing decision collection limits. The
byte criterion is restated where an author meets it — the `MEMORY.md` header,
`COMMIT.md`, and the fact card — rather than only here.
