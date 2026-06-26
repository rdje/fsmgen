# IAL2 Post-APB Profile-Alias Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.555`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.555` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.556`, a no-behavior public-surface sync
after the bounded APB `.apb` profile-alias behavior shipped.

The next slice must not change parser, generator, suffix, support-accounting,
sample, test, check JSON, semantic JSON, HDL, direct-backend,
verification-output, backend-language, or VHDL behavior. It exists to ensure
the current public surfaces no longer imply that `.apb` remains unsupported
after `.554`.

## Evidence Read

The selector read the shipped APB `.apb` behavior, its contract and readiness
chain, the earlier `.axi` profile-alias behavior, the unsupported-alias
inventory, the profile-alias decisions, support-accounting and manifest
surfaces, README, ROADMAP_V2, mdBook, the active task tree, Memory, and the
Knowledge Map.

The shipped current behavior is:

- `.axi` accepts the selected AXI AW Valid-Ready profile-alias source at
  `ppif/axi_aw_valid_ready.axi`;
- `.apb` accepts the selected APB requester-transfer profile-alias source at
  `ppif/apb_requester_transfer.apb`;
- both aliases remain IAL2 sources that lower through generated `.isf` before
  generated `.fsm`;
- `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi` remain
  unsupported aliases;
- APB completer/interconnect generation, sidebands, alternate widths,
  multi-peripheral decode, back-to-back transfer policy, implicit suffix
  profile inference, direct backend lowering, verification-output generation,
  backend-language variants, and VHDL remain deferred.

## Selected Next Owner

`.556` is a public-surface sync, not a behavior owner.

The immediate risk is current documentation and Knowledge Map routing drift:
the `.554` behavior card is current, but the current `.axi` behavior document
and fact card still list `.apb` in the set of unsupported aliases after the
`.axi` slice. That wording was true at `.540` closeout and remains useful as
historical chronology, but it is no longer a correct answer to current
questions after `.554`.

`.556` must:

- update current `.axi` behavior/fact wording so `.apb` is described as a
  later shipped APB profile-alias, not as currently unsupported;
- preserve pre-`.554` historical statements where they are explicitly framed
  as historical `.540`/`.548`/`.550`/`.552`/`.553` closeout facts;
- keep current remaining unsupported aliases limited to `.chi`, `.ace`,
  `.ahb`, `.atb`, `.smbus`, `.i2s`, `.pif`, and `.ppi`;
- update README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map as
  needed so the current public answer is consistent;
- prove the sync with focused text checks plus Knowledge Map, mdBook,
  docs-path, memory, diff, and doctrine gates.

## Rejected Next Owners For This Slice

APB behavior expansion is real work, but it is not the next safe owner while
current public surfaces still contain stale `.apb`-unsupported wording.
Candidates such as APB completer/interconnect generation, multi-peripheral
decode, sidebands, alternate widths, and back-to-back transfer policy remain
deferred behind a later exact owner.

Another protocol-profile alias readiness lane is also deferred until the
post-APB public surface is clean. `.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`,
and `.i2s` still need their own evidence before any contract selection.

Generic-container alias cleanup for `.pif` and `.ppi` remains explicitly
unsupported by the existing policy. It is not selected here because the
current drift is in profile-alias public wording, not generic-container
behavior.

AXI manager frontier return and smaller IAL1/IAL0/SystemVerilog prerequisites
remain valid future candidates, but neither should preempt the current
profile-alias surface sync.

## Validation Plan For `.556`

The selected owner should run:

```bash
rg -n '\.apb.*remain unsupported|remain unsupported.*\.apb|known unsupported.*\.apb' \
  docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md \
  docs/knowledge/ial2-axi-profile-alias-behavior.md \
  README.md ROADMAP_V2.md docs/book/src/14-feature-backlog.md
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

Focused `.axi` and `.apb` CLI probes may be rerun if the text sync touches
examples or current behavior prose. The slice must not update behavior-bearing
tests or implementation files.

## Rollback

Because `.555` changes only selector documentation and memory, rollback is a
straight revert of the selector doc, fact card, task-tree frontier, README,
ROADMAP_V2, mdBook, Memory, and regenerated Knowledge Map entries. No runtime
behavior is affected.
