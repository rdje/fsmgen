# NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR: Restore section/subsection numbering alignment

## Metadata

- Tree ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR`
- Status: `active`
- Roadmap lane: `NEXSIM requirements / document integrity`
- Created: `2026-08-09`
- Last updated: `2026-09-23`
- Owner: repo-local workflow

## Origin

The IAL2 mdBook coherence audit found a deterministic numbering defect in
`docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md`: top-level section 36 owns
subsections numbered `35.x`, section 37 owns `36.x`, and the one-section lag
continues through the section-42 subsections. Requirement identities remain
stable; the human-facing hierarchy is inconsistent.

## Goal

Align NEXSIM subsection numbers with their owning top-level sections while
preserving every normative requirement identity and technical statement.

## Non-Goals

- Do not change NEXSIM scope, requirements, priority, APIs, MCP schemas, or
  conformance meaning.
- Do not activate NEXSIM implementation work.

## Task Tree

- ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR`
  Status: `active`
  Goal: `Repair deterministic subsection numbering drift without changing requirements semantics.`
  Children: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.1, NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.2`

- ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.1`
  Status: `done`
  Goal: `Audit and mechanically align subsections under sections 36 through 42.`
  Acceptance: `On clean activation, census all top-level and subsection headings, change only lagging human-facing subsection numbers so each matches its parent, verify heading/link/navigation integrity and zero normative requirement-ID/text changes, then pass path/doctrine gates.`
  Verification: `A complete source census found 25 lagging labels under sections 36, 37, 38, 41 and 42. Only those parent-number tokens changed. Removing parent-number tokens from old/new source yields byte-identical content with SHA-256 364472a0a4f6f5cf0f24bfbb56b7caf70a67275a76a63f3100eb52e6d388d7da. Independent rendered HTML parsing finds all 45 sections and 67 numbered subsections with zero parent mismatches, and every one of its 126 local links/fragments resolves. All definition IDs and their source order remain identical; baseline version, metadata, examples and normative prose remain untouched. The separate historical count error is owned by .2.`
  Commit: `this commit`

- ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.2`
  Status: `pending`
  Goal: `Correct the historical baseline requirement-ID census without changing requirements.`
  Acceptance: `After .1 commits cleanly, compare the exact original published snapshot and current source using independent complete-ID and definition-line enumerations. Explain the nested UVM namespace omission, repair the two false baseline-count statements in the historical task with explicit dated correction and canonical evidence, and retain a reverify command. Preserve all requirement text and director-deferred implementation/amendment work.`
  Verification: `Read-only discovery: original d37b2920e1b5be2df07338d9d77e78174c790048 and current source each contain 393 unique definition IDs, whereas the historical task says 365. Matching only a single alphabetic namespace yields 365; all 28 excluded nested UVM namespace IDs are actual definitions. The original baseline already includes them, so this is historical accounting error, not newly added requirements.`
  Commit: `pending`

## Decisions

- `2026-08-09`: Park the mechanical repair independently; it is unrelated to
  IAL2/AXI semantics and must not widen the active documentation slice.

- `2026-09-23`: Activate only human heading-number correction; preserve the
  version-1 requirement text and IDs byte-for-byte. Verify the included book
  heading hierarchy and existing fragment links. This corrects document
  navigation, without amending requested capabilities or support claims.

## Blockers

- None for this mechanical correction, selected under unlimited PNT after
  clean APB repair `9ccbb3268`. The director-deferred NEXSIM implementation
  and evidence-driven requirements-amendment tree remains deferred.

## Acceptance Checklist (heading correction .1)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '### 35.1 Initialization and negotiation' -- docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md` identifies the original NEXSIM publication `d37b2920e`. Current source headings reveal a one-section lag in 25 subsection labels after section 35; numbered subsections in sections 36, 37, 38, 41 and 42 disagree with their parent. The book directly includes that canonical file, so the defect is user-visible there too.
- [x] **ADDRESSED (verified)** — Only the 25 incorrect heading parent-number tokens change. Exact normalized old/new source equality preserves every requirement identity, order, example, metadata field and technical statement. The book build succeeds, and an independent HTML parser confirms all 45 top-level sections and 67 numbered subsections have correct hierarchy and every local chapter link/fragment resolves.
- [x] **NO REGRESSION** — `knowledge-map: OK` retains the canonical requirements route and the director-deferred amendment/implementation boundary. Re-derive: complete source heading census; falsify: independent rendered hierarchy and link-target inspection plus exact non-heading byte comparison; durability: canonical source, direct book include, original Git snapshot, task evidence and fact card. The newly exposed historical 365-ID count is not endorsed by this correction; .2 owns correcting it against the complete 393-ID definition set. No NEXSIM capability or requirement semantics are changed.
