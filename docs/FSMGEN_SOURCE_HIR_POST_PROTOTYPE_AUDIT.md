# FSMGen SourceHIR post-prototype audit

Date: 2026-07-30
Owner: `FSMGEN-HIR-ROADMAP-FRONTIER.5`
Status: selected — remain private through a second lowering route

## Decision

Keep `FSM::IR::SourceHIR` private. Do not promote the current valid-ready
prototype, and do not retire it.

The next bounded direction is a second private SourceHIR route for concrete
FSM/control intent that renders canonical IAL1 and enters the existing
`IAL1 -> IAL0` path. A separate design-only leaf must select its exact schema,
package boundary, renderer handoff, provenance mapping, diagnostics, and one
tracked IAL1 golden before implementation.

Leaf `.6` now selects that second route as semantic SourceHIR version 2 with
canonical byte-identical `isf/phase_test.isf` rendering and existing-adapter/
scheduler re-entry. The exact contract is
`docs/FSMGEN_SOURCE_HIR_CONCRETE_CONTROL_V2_CONTRACT.md`.

Leaf `.7` now implements and proves that route privately. Leaf `.8` remains
the sole owner of the next promotion/continued-private/retirement decision;
clean implementation commit `8876adb0b` activates that audit continuity-only.

Public host-language selection remains owned by proposed
`IAL2-HOST-LANGUAGE-BUILDER-FRONTIER`. No Perl, Python, Julia, C, CLI, raw-HIR,
serialization, report, manifest, or support-accounting contract is promoted by
this audit.

## Evidence

### What the prototype proves

Focused `t/1547-source-hir-valid-ready.t` passes with `Files=1, Tests=9` and
proves all of the version-1 claims:

- closed validation and immutable defensive access;
- deterministic structured diagnostics with repository-relative or logical
  provenance;
- canonical PPIF and a private generated-line source map;
- exact 14-line, 428-byte valid-ready golden output;
- existing PPIF parser/validator re-entry rather than a generator bypass; and
- equal generated IAL1, IAL0, schedule, and protocol reports relative to the
  hand-written fixture.

This is enough evidence that a shared pre-IAL semantic object and provenance
model are useful. Retirement would discard a working boundary without any
public compatibility benefit.

### What the prototype does not prove

Repository source references outside historical documentation are limited to
the three private `FSM::IR::SourceHIR*` packages and focused t1547. There is no
independent frontend producer, public package, CLI entry, language-surface
entry, capability-manifest entry, normalized-report projection, or support-
accounting entry.

At the time of this audit, the only SourceHIR root kind was one
protocol-neutral valid-ready object and the only renderer targeted PPIF/IAL2.
The evidence then proved only this half of the selected architecture:

```text
SourceHIR protocol intent -> canonical IAL2 -> IAL1 -> IAL0
```

It did not yet prove the other promised route:

```text
SourceHIR concrete FSM/control -> canonical IAL1 -> IAL0
```

Publishing the object at that point would have frozen names, versioning, error
contracts, and package ergonomics from one semantic shape before the common
abstraction survived a second lowering target. Leaf `.7` has since supplied
that second private proof; `.8` owns the fresh conclusion.

### Concrete-route readiness

The existing IAL1 corpus already supplies small, checked candidates. As a
non-selecting readiness probe, `isf/phase_test.isf` passes strict check with
five states and five signals, and its schedule has one five-state transaction,
three ports, an asynchronous active-low reset, and explicit phase control.
This demonstrates that a bounded concrete-control golden can be selected
without inventing new IAL1 behavior. Leaf `.6`, not this audit, owns the exact
fixture choice.

## Options considered

| Outcome | Evidence for it | Evidence against it | Result |
| --- | --- | --- | --- |
| Promote now | The valid-ready path is deterministic, diagnosed, and lowering-equivalent. | One test-only producer and one IAL2 semantic shape do not establish a stable public cross-route schema or ergonomic API. Public versioning and language choice have not been selected. | Rejected as premature. |
| Keep private for a second route | Preserves the proved boundary without compatibility cost and directly tests the unproved concrete-control-to-IAL1 half of the architecture. | Requires one more bounded design and implementation cycle before promotion can be reconsidered. | Selected. |
| Retire | The public `.ppif` path remains sufficient for current users. | The private object already adds checked provenance, deterministic construction, and frontend-independent semantics with no public maintenance burden. | Rejected. |

## Selected follow-on leaves

- `.6` selects the exact private concrete-control-to-IAL1 version-2 boundary
  and golden. It is design-only and may reject the route if a genuinely shared
  SourceHIR cannot represent the candidate without IAL1 syntax leakage.
- `.7` implements only the `.6`-selected private route and equivalence proof;
  it is now complete.
- `.8` repeats the promotion/continued-private/retirement audit from evidence
  across both lowering routes.

The next promotion audit may recommend public activation only if both private
routes are coherent and `IAL2-HOST-LANGUAGE-BUILDER-FRONTIER` separately
selects a supported producer, versioning policy, packaging, diagnostics, and
compatibility boundary. A second route is necessary evidence, not by itself a
public API authorization.

## Guardrails and retirement test

The second route must:

- reuse the immutable object and provenance principles rather than create an
  unrelated builder hidden under the same package name;
- emit ordinary canonical IAL1 and pass through its shipped parser,
  validation, and `IAL1 -> IAL0` chain;
- reproduce one tracked IAL1 fixture byte-for-byte and prove equal downstream
  schedule and IAL0 artifacts;
- remain private with no new CLI, public serialization, reports, manifests, or
  support accounting; and
- preserve all current `.fsm`, `.isf`, `.ppif`, composition, embedding, and
  backend behavior.

If `.6` finds that the concrete route requires target-language syntax inside
SourceHIR, duplicates the IAL1 AST wholesale, breaks deterministic provenance,
or cannot share the version-1 object invariants, it must select retirement or
a renamed narrower protocol-intent object instead of forcing false unity.

## Change boundary

This audit changes documentation, task continuity, decision records, and the
Knowledge Map only. It changes no package, test, parser, fixture, generated
artifact, configuration, public API/report/accounting surface, HDL/runtime, or
existing behavior. Both frozen project-status files remain untouched.
