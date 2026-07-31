# 0042 — Task trees seal completed subtrees with exact provenance

- Date: 2026-07-31
- Type: architecture/convention
- Status: accepted
- Refines: [0019](0019-task-tree-in-file-secondary-views-are-historical.md), [0041](0041-live-documents-use-bounded-views-over-durable-stores.md)
- Evidence owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.6`

## Context

Decision 0019 correctly makes the task node list, cross-tree index, and git the
live sources, but it assumes every node remains in one task Markdown file. The
active IAL2 tree reached more than four megabytes. Keeping every completed node
in the mandatory live read makes the authoritative source itself unbounded;
mechanically splitting it without provenance would merely move that pressure
and weaken confidence that node evidence survived intact.

Decision 0041 therefore assigns task evidence a bounded live-root topology:
current work stays directly readable, while completed subtrees may seal or
become query-first only when identity and retrieval remain provable. The schema
must preserve stable node IDs, parent/child closure, terminal status, leaf
verification, and commit evidence across those storage forms. This contract
leaf must add the capability without migrating an existing tree.

## Decision

1. The live task Markdown file remains the front door and retains task metadata,
   the top-level root, every nonterminal node, every ancestor needed to reach
   the frontier, and any completed nodes not yet sealed. PNT therefore never
   needs an archive lookup to select current work.
2. A task file may name one repository-relative JSONL `Segment manifest`. Its
   registry record declares the tree ID plus finite manifest record/byte,
   per-segment node/line/byte, and aggregate node/line/byte limits. Segment
   records name content-addressed Markdown files, disjoint completed subtree
   roots, node count, SHA-256, and the exact source revision/path from which
   those nodes were copied.
3. A sealed segment is immutable evidence, not a second editable task tree. Its
   filename is its content digest; every node must match the exact source-
   revision node, every declared root includes its full source subtree, and all
   segment nodes are terminal. The checker combines live and sealed nodes before
   validating unique IDs, ancestry, direct-child closure, status, and evidence.
4. A fully completed subtree may instead remain in the live root as one compact
   `version_object` terminal. It records an exact revision, former task path,
   retrieved-file SHA-256, archived-node count, verification, and commit. The
   checker retrieves the file through git, proves its digest and goal identity,
   reconstructs the named subtree, and rejects any nonterminal node, broken
   child closure, or pending leaf evidence.
5. Segment manifests and compact terminals are optional. Existing in-file trees
   retain their syntax and behavior. Leaf `.6` defines and proves the contract;
   migrations remain separately atomic under `.7`.
6. Decision 0019 still governs optional historical tables. The authoritative
   node graph is now the checked union of the live `## Task Tree` list and any
   manifest-addressed sealed segments; git remains the chronological and exact
   version-object store.

## Consequences

- Ordinary resume and PNT reads stay bounded and immediately understandable.
- Moving completed nodes cannot silently lose identity, structure, validation,
  or commit evidence.
- Content-addressed segment paths prevent in-place edits from masquerading as
  the same sealed object; exact source revisions additionally prove provenance.
- Independent manifest, per-segment, and aggregate limits make overflow
  pressure explicit instead of moving it into an unbounded index or shard set.
- Compact terminals reduce mandatory working-set size while keeping full
  reconstruction deterministic and mechanically tested.
- No existing task file, node, status, threshold, or product behavior changes
  merely because the checker understands the new optional forms.

## First Migration

Leaf `.7` applies the contract without renaming or deleting a node. Exact
revision `44b5f159789ba1c31b487c6b047097bb27a9770d` supplies all 844 terminal
IAL2 children to one content-addressed segment; the live file retains its
active root and a short Git retrieval pointer for decision-0019 historical
views. The cross-tree index retains only active/proposed work and seals its 540
unique terminal rows through a separate finite JSONL exact-version manifest.
The checker proves the archived index digest, dimensions, statuses, unique IDs,
revision-local task links, and PNT-view purity. Completed task files remain in
their canonical repository paths.
