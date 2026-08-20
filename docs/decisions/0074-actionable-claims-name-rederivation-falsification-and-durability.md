# 0074 — Actionable claims name re-derivation, falsification, and durability

- Date: 2026-08-20
- Type: evidence architecture/governance
- Status: accepted
- Source: director-requested adoption of the portable PGEN claim-verification standard
- Implementation owner: `CLAIM-VERIFICATION-ADOPTION`

## Context

FSMGen already enforces task ownership, durable memory, knowledge retrieval,
doctrine execution, current-document containment, and evidence-backed staged
implementation acceptance. Those systems answer where work and facts live and
whether declared repository rules execute. They do not define what makes a
published quantitative claim earned.

Repeating one measurement does not expose a shared classifier, wrong bucket,
misread specification, untracked producer, or unwatched derived constant. A
conservation check can pass while every bucket is wrong; a test and
implementation derived from the same prose can agree on the same
misinterpretation; a correct value can become stale immediately after it is
copied into an unguarded document.

The portable source at the director-specified sibling-project path names three
different questions: can the claim be re-derived from its source, can a
separating oracle falsify the competing hypothesis, and can a later reader
rerun the tracked producer while a watcher detects staleness? FSMGen has not
yet adopted that standard or registered a corresponding doctrine check.

## Decision

1. FSMGen adopts **re-derive**, **falsify**, and **durability** as the three
   required evidence legs for an actionable quantitative claim that a user,
   maintainer, reviewer, or automated policy will act on.
2. Each published claim record names the claim and all three legs. A genuinely
   unavailable leg is written as an explicit gap with its owner; absence is
   never allowed to look like success.
3. The falsification leg must name evidence capable of separating the claim
   from a concrete competing hypothesis. Repeating the producer, checking only
   a conserved total, hashing only inputs, or building both sides from the same
   interpretation does not become independent merely because it runs twice.
4. The durability leg names tracked producers and an executable watcher or an
   explicit gap. A repository-derived constant is derived at use or bound to
   every input that can change the complete artifact, including the instrument
   that produced it.
5. Incidental numerals are outside the claim-record obligation: dates,
   versions, work-unit IDs, schema identifiers, HDL literals, example payloads,
   and transient command output do not become policy claims merely because
   they contain numbers. Their existing semantic contracts still apply.
6. FSMGen's authoritative standard will live at repository-root
   `CLAIM_VERIFICATION.md` with a fenced local adoption note. The source copy is
   an adoption template, not an upstream or runtime dependency.
7. Mechanical enforcement begins with what a checker can decide honestly:
   bounded record syntax, unique IDs, local/tracked source and producer paths,
   named non-aliased legs or explicit gaps, registered watchers, and execution
   through the doctrine driver. Positive fixtures and deliberately corrupted
   RED controls must prove the checker can fail.
8. The checker does **not** claim that formatting proves semantic truth,
   oracle independence, sufficient statistical sampling, or human intent.
   Those judgments stay reviewable in the record and its evidence.
9. Existing current surfaces and repository-derived constants receive a
   producer-derived inventory before migration. The inventory must itself name
   its re-derivation, falsification control, and durability evidence; it is not
   allowed to bootstrap its own completeness from the same handwritten list it
   checks.
10. Adoption lands as separate commits for selection, authoritative policy and
    discovery, mechanical enforcement, inventory, migrations, and closure.
    Product-language and HIAL/VIAL implementation remain unchanged during this
    governance task.

## Consequences

- A claim can be useful with a named evidence gap; it cannot silently present
  that gap as verification.
- Reviewers can distinguish three independent dimensions instead of counting
  repeated passes.
- Tracked derivations and watchers prevent a freshly corrected number from
  becoming the next unwatched constant.
- Structural gates remain honest about their limit: they enforce declared
  evidence plumbing and visibility, not semantic understanding.
- The requested adoption temporarily precedes the clean HIAL backend-emission
  frontier, which resumes after this bounded adoption tree closes or reaches a
  task-owned safe handoff.
