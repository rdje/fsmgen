# NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR: Restore section/subsection numbering alignment

## Metadata

- Tree ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR`
- Status: `done`
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
  Status: `done`
  Goal: `Repair subsection numbering and historical requirement accounting without changing requirement semantics.`
  Children: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.1, NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.2`

- ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.1`
  Status: `done`
  Goal: `Audit and mechanically align subsections under sections 36 through 42.`
  Acceptance: `On clean activation, census all top-level and subsection headings, change only lagging human-facing subsection numbers so each matches its parent, verify heading/link/navigation integrity and zero normative requirement-ID/text changes, then pass path/doctrine gates.`
  Verification: `A complete source census found 25 lagging labels under sections 36, 37, 38, 41 and 42. Only those parent-number tokens changed. Removing parent-number tokens from old/new source yields byte-identical content with SHA-256 364472a0a4f6f5cf0f24bfbb56b7caf70a67275a76a63f3100eb52e6d388d7da. Independent rendered HTML parsing finds all 45 sections and 67 numbered subsections with zero parent mismatches, and every one of its 126 local links/fragments resolves. All definition IDs and their source order remain identical; baseline version, metadata, examples and normative prose remain untouched. The separate historical count error is owned by .2.`
  Commit: `this commit`

- ID: `NEXSIM-REQUIREMENTS-HEADING-NUMBERING-REPAIR.2`
  Status: `done`
  Goal: `Correct the historical baseline requirement-ID census without changing requirements.`
  Acceptance: `After .1 commits cleanly, compare the exact original published snapshot and current source using independent complete-ID and definition-line enumerations. Explain the nested UVM namespace omission, repair the two false baseline-count statements in the historical task with explicit dated correction and canonical evidence, and retain a reverify command. Preserve all requirement text and director-deferred implementation/amendment work.`
  Verification: `The retained Python census agrees on 393 unique complete IDs and the same ordered definition list in original d37b2920e1b5be2df07338d9d77e78174c790048 and current source. Independent backtick-token and definition-line parsers agree; the restrictive single-namespace counter yields 365 and omits exactly 28 nested UVM IDs. Both corrected historical statements now say 393 with a dated explanation; the canonical fact card routes the complete census. Sorted ID-set SHA-256 is 5f53639446dc22720faa781140244cf2513e3e43bf4efcd0f967214308b70d17 in both versions. The baseline source and its book include are unchanged by .2; the original implementation/amendment tree stays deferred.`
  Commit: `this commit`

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

## Historical requirement census reverify (.2)

Run this Python block from the repository root with `python3 -B`. It reads the
original published object and current file; it does not run NEXSIM or alter data.

```python
from pathlib import Path
import hashlib
import re
import subprocess

path = "docs/NEXSIM_API_MCP_AGENT_CONSUMER_REQUIREMENTS.md"
revision = "d37b2920e1b5be2df07338d9d77e78174c790048"
original = subprocess.check_output(["git", "show", f"{revision}:{path}"])
current = Path(path).read_bytes()
sets = []
for label, raw in (("original", original), ("current", current)):
    tokens = set(re.findall(rb"`((?:NXAPI|NXMCP)-(?:[A-Z]+-)+[0-9]{3})`", raw))
    # Independent line/token parser includes nested namespaces without regex.
    definitions = []
    for line in raw.splitlines():
        if line.startswith((b"`NXAPI-", b"`NXMCP-")):
            identity, remainder = line[1:].split(b"`", 1)
            assert remainder.startswith(b" ")
            assert identity.rsplit(b"-", 1)[1].isdigit()
            definitions.append(identity)
    assert len(definitions) == len(set(definitions)), "duplicate definition"
    assert tokens == set(definitions), "token/definition census mismatch"
    narrow = set(re.findall(rb"`((?:NXAPI|NXMCP)-[A-Z]+-[0-9]{3})`", raw))
    omitted = tokens - narrow
    assert omitted and all(x.startswith(b"NXAPI-UVM-") for x in omitted)
    digest = hashlib.sha256(b"\n".join(sorted(tokens)) + b"\n").hexdigest()
    print(label, len(tokens), "IDs; narrow:", len(narrow),
          "nested UVM omitted:", len(omitted), "ID-set SHA256:", digest)
    sets.append(definitions)
assert sets[0] == sets[1], "definition identities or order changed"
print("original and current complete ordered definition lists agree")
```

## Acceptance Checklist (historical census correction .2)

- [x] **ROOT CAUSE (WHY + WHERE)** — `git log -S '365 unique requirement IDs' -- docs/tasks/NEXSIM-SEMANTIC-API-MCP-CONSUMER-REQUIREMENTS.md` identifies baseline publication `d37b2920e`. Reading that exact source object proves it already has 393 unique definitions. A single-namespace-only regex reproduces 365, excluding all 28 nested UVM namespace IDs. This establishes the incomplete counting boundary; no unavailable historical counter implementation is claimed.
- [x] **ADDRESSED (verified)** — The two historical task statements now report 393 with an explicit dated correction and a link to the runnable census above. Complete backtick-ID enumeration agrees with an independent non-regex definition-line parser, rejects duplicates and preserves exact original/current definition order. Both sorted complete-ID sets have SHA-256 `5f53639446dc22720faa781140244cf2513e3e43bf4efcd0f967214308b70d17`; the canonical fact card names the corrected count and original/current agreement.
- [x] **NO REGRESSION** — `knowledge-map: OK` retains all canonical routes. The requirements source and direct mdBook include are unchanged from .1, whose rendered hierarchy and links were verified; no support, priority, schema or normative text changes. Re-derive: current complete-ID set; falsify: independent definition-line enumeration, explicit restrictive-counter omission set and original snapshot; durability: exact original Git object, corrected task statements, executable census block and fact card. Director-deferred NEXSIM amendment/implementation work remains deferred.
