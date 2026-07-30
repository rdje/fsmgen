# IAL2 Post TASK-ACCEPTANCE Next-Owner Selection

## Selection

`IAL2-FEATURE-COMPLETENESS-FRONTIER.836` selects proposed
`PUBLIC-SYNC-TEST-DRIFT-REPAIR.1` as the next exact owner.

The selected leaf must add the verification-observation discovery-key family
already present in the public ISF payload to its authoritative top-level
presence list and restore t1131. This selector does not activate or modify the
selected child before its own commit is clean.

## Current-HEAD Evidence

The public payload/list difference is exact and one-way:

- `schedule_report_verification_observation_keys`;
- `schedule_report_verification_observation_role_values`;
- `schedule_report_verification_observation_signal_keys`.

No authoritative-list entry is absent from the payload. A guarded focused run
confirms that t1131 fails on this family in both the direct contract and all
capability-manifest views. The same run reconfirms the separately owned t1250
focused-test-index drift and t1474 aggregate-diagnostic expectation drift.

A repository-local-TMPDIR `mdbook test docs/book` also reconfirms the competing
`MDBOOK-RUSTDOC-NON-RUST-FENCE-REPAIR.1`: rustdoc rejects exactly four known
untyped plain-text diagrams in Chapters 13, 13b, 13f, and 13h. Its exact
temporary outputs were removed after the probe.

## Candidate Comparison

| Candidate | Result | Evidence |
| --- | --- | --- |
| Public-sync `.1` | **selected** | Three adjacent entries in one authoritative list restore a failing public-contract discovery gate without changing payload or behavior. |
| mdBook rustdoc fence repair | remains proposed | Still real and bounded, but needs four separate book-fence edits rather than one authoritative-list correction. |
| Public-sync `.2` and `.3` | remain sequentially owned | Both failures are current, but the tree already requires `.1` to commit before `.2`, then `.2` before `.3`. |
| Protocol-composition identifier audit | remains proposed | Cross-protocol policy audit is broader than the exact public-list mismatch. |
| HIAL/VIAL, HIR, host builder, scale, and MCP-write horizons | remain proposed | Valuable architecture/product directions, but larger than the reproduced public gate repair. |
| Four-document lifecycle review | remains proposed | Director direction leaves it scheduled but inactive and keeps both status files untouched. |
| RAM guard, t1436, transaction layering, and AXI book-coherence items | ineligible | Their task trees retain explicit director gates. |

## Selected Contract And Rollback

The child may change only
`isf_public_interface_public_top_level_keys()` in
`perl/FSM/Support/ISFPublicInterfaceContract.pm`, adding the three existing
payload-family names in their logical schedule-report position. It must prove
the exact payload/list set difference is empty, run t1131 and adjacent public-
contract/capability-manifest checks, synchronize task/Memory/changelog state,
and satisfy `TASK_ACCEPTANCE.md` plus all doctrine gates.

It must not change the payload, schema version, parser, scheduler, manifest
shape, generated artifact, source language, HDL/runtime behavior, or the later
public-sync leaves. Rollback removes the three list entries and restores this
selector to active; every other candidate remains independently owned.

## Closeout Evidence

- The exact set-difference probe reports the three missing payload keys above
  and no presence-list key absent from the payload.
- The guarded current-HEAD public-sync probe reports the expected failures in
  t1131, t1250, and t1474; this is defect evidence, not a passing regression
  claim.
- The repository-local rustdoc probe reports exactly the four task-owned fence
  failures, and its exact temporary output directory was removed.
- Feature-backlog status plus relative-path audits pass with `Files=2,
  Tests=17`; Knowledge Map generation/check passes at 1,068 facts / 5,499
  question keys; mdBook HTML build and diff hygiene pass.
- `MEMORY.md` is 60 lines, `README.md` remains 246 lines, neither legacy status
  file changed, and no background job remains.

Clean selector commit `06c03e6bf` activates only public-sync `.1` through
continuity changes. The authoritative list, payload, tests, later public-sync
leaves, and every product behavior remain unchanged during activation.

The selected child now adds the exact three list entries and restores an empty
payload/list difference plus t1131. Public-sync `.2` and `.3` remain sequential
owners; the mdBook fence repair and every other candidate remain independent.

Clean `.1` implementation commit `012660f90` activates only public-sync `.2`
continuity-only. Its measured boundary is five missing ISF focused-test links
and zero extras; `.3` remains pending.

Public-sync `.2` now adds exactly those five links, restores the exact 332/332
index, and passes focused t1250 plus the guarded 295-file ISF regression. `.3`
remains pending until the clean `.2` commit.

Clean `.2` implementation commit `4ba108b3d` activates only public-sync `.3`
continuity-only. Its exact boundary is one stale t1474 aggregate-cardinality
regex; the canonical public `.ahb` source remains strict-check clean.

Public-sync `.3` updates exactly that regex and restores the six-file alias
gate without product changes. Adjacent proof discovers four stale generated-
IAL0 ERROR-drive expectations in t1475/t1482; pending `.4` owns them after the
clean `.3` commit.
