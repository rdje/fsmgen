# IAL2 Post-APB Surface Sync Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.557`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.557` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.558`, a no-behavior readiness audit for
APB completer/interconnect generation after the current `.axi`/`.apb`
profile-alias public surfaces were synchronized.

The selected next owner must not implement APB completer or interconnect
generation. It must decide whether the existing lower-layer APB evidence is
enough for a public IAL2 contract selection, whether a smaller lower-layer or
report/static prerequisite is needed, or whether the residue should remain
deferred.

## Evidence Read

The selector read the post-APB public-surface sync, the shipped APB `.apb`
behavior, the APB `.ppif` requester-transfer behavior, the APB source-shape
contract, the earlier APB source-shape readiness audit, the shipped `.axi`
profile-alias behavior, current `.axi`/`.apb` facts, remaining unsupported
alias inventory, support-accounting and manifest surfaces, README,
ROADMAP_V2, mdBook, task tree, Memory, and the Knowledge Map.

The current shipped APB IAL2 behavior is still bounded to one requester
transfer. Its report keeps these APB residues explicit:

```text
apb_multi_peripheral_decode_deferred
apb_protection_and_strobes_deferred
apb_completer_and_interconnect_generation_deferred
apb_alternate_widths_deferred
apb_back_to_back_policy_deferred
```

The immediate residue selected for audit is:

```text
apb_completer_and_interconnect_generation_deferred
```

## Live Evidence

The selector reverified these existing APB surfaces:

```bash
./bin/fsmgen --quiet --strict --check --json fsm/apb_completer.fsm
./bin/fsmgen --quiet --strict --check --json fsm/apb_tb.fsm
./bin/fsmgen --quiet --emit-schedule-json ppif/apb_requester_transfer.apb
./bin/fsmgen --quiet --strict --check --json ppif/apb_requester_transfer.apb
```

The APB completer check succeeded with support-accounting entry
`protocol.apb_completer`. The APB composition top check succeeded with
support-accounting entry `protocol.apb_tb` and two children:
`apb_requester` and `apb_completer`. The `.apb` schedule/check probes
succeeded with support-accounting entry `intent.apb_profile_alias_requester_transfer`
and preserved the APB requester-transfer residue list.

## Why `.558`

APB completer/interconnect readiness is the next narrow prerequisite because
the repository already has lower-layer APB completer and APB requester-to-
completer composition fixtures, while IAL2 still exposes only the requester
generation path. A readiness audit can determine whether the future contract
should be:

- an APB completer object under `.ppif` and bounded `.apb`;
- an APB interconnect/composition object that wires generated requester and
  completer artifacts;
- a report/static alignment prerequisite over the existing residue;
- a lower-layer fixture or documentation prerequisite; or
- explicit deferral.

Direct implementation is not selected because the public contract is still
unsettled: source vocabulary, object cardinality, generated review artifacts,
report schema, support identities, source anchors, diagnostics, and `.ppif`
versus `.apb` exposure all need an owned contract before behavior changes.

## Rejected Next Owners

APB sidebands, alternate widths, and back-to-back transfer policy remain
deferred because they modify the requester-transfer contract itself and should
not be mixed into completer/interconnect ownership.

APB multi-peripheral decode may couple to interconnect generation, but the
next slice is only a readiness audit. It may decide whether decode belongs in
the same future contract or requires a later owner.

Another protocol-profile alias readiness lane is deferred. `.chi`, `.ace`,
`.ahb`, `.atb`, `.smbus`, and `.i2s` still lack their own source-shape,
profile-matching, report, support-accounting, and mdBook evidence.

Generic-container alias cleanup for `.pif` and `.ppi`, AXI manager frontier
return, direct backend work, verification-output generation, backend-language
variants, and VHDL remain valid future candidates but are not selected before
the APB completer/interconnect readiness question is answered.

## Validation Plan For `.558`

The selected owner should read the `.557` selector, APB behavior/contract
chain, APB lower-layer fixtures, support-accounting entries, README,
ROADMAP_V2, mdBook, task tree, Memory, and Knowledge Map. It should reverify
the APB completer/composition and `.apb` requester-transfer probes above, then
record a readiness outcome without changing behavior.

Closeout gates should include:

```bash
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

## Rollback

Because `.557` changes only selector documentation and memory, rollback is a
straight revert of the selector doc, fact card, task-tree frontier, README,
ROADMAP_V2, mdBook, Memory, and regenerated Knowledge Map entries. No runtime
behavior is affected.
