# MDBOOK-LEGACY-SOURCE-LINKS: Repair unresolved native source references

## Metadata

- Tree ID: `MDBOOK-LEGACY-SOURCE-LINKS`
- Status: `active`
- Roadmap lane: `R13 / documentation quality`
- Created: `2026-10-23`
- Last updated: `2026-10-23`
- Owner: repo-local workflow

## Goal

Repair existing manual hyperlinks that point at repository source/test paths
which are absent from the served book. This is P2 defect ownership discovered
during `PERL-POD-API-REFERENCE.4`, not an implementation pivot. Finish the POD
task cleanly first; required SPECFORGE delivery retains its existing priority.

## Reproduction and impact

Build/serve the native book and open Extensions and Embedding. Its
`t/375-hdl-generator-facade-contract.t` link requests that path below the served
root and returns HTTP 404. Browser QA also exposes other relative `t/` and
`perl/` evidence links; their complete affected population is not yet measured.
The repository file exists, but a native book reader cannot follow its link.
Saved observation: `docs/audits/pod-api-20261023/legacy-link-observation.json`.
The newly generated POD/guide links have their own complete passing join and
must remain intact during this repair.

## Non-Goals

- No runtime, HDL, language, API-stability or submodule change.
- Do not replace accurate evidence with an unqualified moving hosted URL.
- Do not claim every old book link is fixed from one repaired example.

## Acceptance Criteria

- Inventory actual native hrefs and distinguish source references, intended
  literal evidence paths, admitted source views and product navigation.
- Preserve each original label, evidence identity and useful reader meaning.
- Publish source views only through the existing documented ownership/ignore
  contracts, or render an intentionally non-clickable repository evidence path
  when that is the correct reader role.
- Verify actual built target bytes/anchors or the deliberate literal role,
  relevant book/source indexes and doctrines; commit every bounded slice.

## Task Tree

- ID: `MDBOOK-LEGACY-SOURCE-LINKS`
  Status: `active`
  Goal: `Make existing native manual source references usable and truthful.`
  Children: `MDBOOK-LEGACY-SOURCE-LINKS.1, MDBOOK-LEGACY-SOURCE-LINKS.2, MDBOOK-LEGACY-SOURCE-LINKS.3`

- ID: `MDBOOK-LEGACY-SOURCE-LINKS.1`
  Status: `pending`
  Goal: `Census unresolved native links and select the first bounded repair.`
  Acceptance: `Reproduce the saved HTTP refusal, independently enumerate actual built local hrefs/anchors and repository target identities, and classify reader roles before changing links. Preserve all original observations and split the repair if its population exceeds one safe slice.`
  Verification: `Known 404 reproduced during API reference browser QA; whole population pending.`
  Commit: `pending`

- ID: `MDBOOK-LEGACY-SOURCE-LINKS.2`
  Status: `pending`
  Goal: `Repair the selected native source-reference cohort.`
  Acceptance: `Follow .1's exact classified population, preserve evidence meaning, use admitted source views or honest literal paths, and verify original/refreshed byte/link contracts. Commit before expanding the cohort.`
  Verification: `pending census`
  Commit: `pending`

- ID: `MDBOOK-LEGACY-SOURCE-LINKS.3`
  Status: `pending`
  Goal: `Qualify repaired delivery and retain ownership of every residual defect.`
  Acceptance: `Check actual built links and relevant source/index/doctrine gates, include genuine broken-target controls, schedule all residual affected cohorts, and close only the measured repaired scope.`
  Verification: `pending repair`
  Commit: `pending`

## Decisions

- The API task owns discovery; this tree schedules the broader legacy repair.
  Browser availability is now established, but no earlier pending visual audit
  is implicitly requalified by the focused API-page observations.

## Open Questions

- Whole-manual affected link population and intended reader roles await .1.

## Blockers

- None requiring a director decision; scheduled behind higher-priority work.
