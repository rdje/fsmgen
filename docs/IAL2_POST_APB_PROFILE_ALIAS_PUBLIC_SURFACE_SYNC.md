# IAL2 Post-APB Profile-Alias Public Surface Sync

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.556`

Date: 2026-06-26

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.556` synchronizes current profile-alias
public surfaces after the APB `.apb` alias shipped in
`IAL2-FEATURE-COMPLETENESS-FRONTIER.554`.

No parser, generator, suffix recognition, sample, support-accounting, test,
schedule JSON, check JSON, semantic JSON, HDL, direct-backend,
verification-output, backend-language, or VHDL behavior changed.

## Current Public State

FSMGen currently accepts two bounded IAL2 profile-alias suffixes:

- `.axi` for the selected AXI AW Valid-Ready source at
  `ppif/axi_aw_valid_ready.axi`;
- `.apb` for the selected APB requester-transfer source at
  `ppif/apb_requester_transfer.apb`.

Both are profile aliases over the same IAL2 `protocol-platform-intent` model,
and both lower through generated `.isf` before generated `.fsm`.

The current remaining unsupported aliases are:

```text
.chi
.ace
.ahb
.atb
.smbus
.i2s
.pif
.ppi
```

`.apb` no longer belongs in the current unsupported-alias set after `.554`.
Historical statements that say `.apb` was unsupported at `.540`, `.548`,
`.550`, `.552`, or `.553` closeout remain accurate only as dated chronology.

## Surfaces Updated

The sync updates:

- `docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md`, so the current `.axi` behavior
  note describes `.apb` as a later shipped APB profile alias rather than as a
  current unsupported suffix;
- `docs/knowledge/ial2-axi-profile-alias-behavior.md`, so current Knowledge
  Map answers route `.axi` plus `.apb` support correctly;
- README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map, so the
  public chronology records this no-behavior synchronization.

Historical pre-`.554` docs and fact cards remain historical. They are not
rewritten into current behavior notes because their dated closeout statements
are still useful archaeology when explicitly framed as historical state.

## Deferred Work

APB completer/interconnect generation, sidebands, alternate widths,
multi-peripheral decode, back-to-back transfer policy, implicit suffix profile
inference, direct backend lowering, verification-output generation,
backend-language variants, and VHDL remain deferred.

`.chi`, `.ace`, `.ahb`, `.atb`, `.smbus`, and `.i2s` still need their own
evidence before any protocol-profile alias contract selection. `.pif` and
`.ppi` remain generic-container alias candidates, not accepted aliases.

## Next Owner

`.556` selects `IAL2-FEATURE-COMPLETENESS-FRONTIER.557`, the next exact IAL2
owner selector after the post-APB public-surface sync. That selector may choose
APB expansion, another protocol-profile alias readiness lane, generic-container
cleanup, report/static alignment, AXI manager frontier return, or a smaller
lower-layer prerequisite, but it must do so in a separate task-tree-owned slice.

## Validation

The sync is validated by focused stale-wording checks against the current
`.axi` behavior document and fact card, plus the usual documentation and
doctrine gates:

```bash
perl -0ne 'if (/\.apb[^\n]*(?:remain unsupported|known unsupported)|(?:remain unsupported|known unsupported)[^\n]*\.apb/) { print "$ARGV\n"; exit 1 }' \
  docs/IAL2_AXI_PROFILE_ALIAS_BEHAVIOR.md \
  docs/knowledge/ial2-axi-profile-alias-behavior.md
knowledge-map/scripts/gen_knowledge_map.sh
knowledge-map/scripts/check_knowledge_map.sh
mdbook build docs/book
scripts/check_docs_relative_paths.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
scripts/check_doctrines.sh
```

The focused stale-wording check is expected to produce no matches. Broader
historical docs may still mention that `.apb` was unsupported before `.554`.
