# AXI IAL2 Manager Post Two-Dynamic/One-Static Mixed Dynamic/Static Read RLAST Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.432`

Date: 2026-06-24

## Outcome

`IAL2-FEATURE-COMPLETENESS-FRONTIER.432` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.433`, readiness audit for dynamic
same-ID issue-order policy, queue, and scoreboard ownership after the bounded
dynamic/mixed response-demux, read-data, multi-beat, and same-cycle
release-and-recapture chain reached the two-dynamic-plus-one-static read
burst-last boundary.

No parser, generator, PPIF sample, support-accounting catalog, validation
behavior, generated artifact, test, schedule/check or semantic JSON, HDL, or
runtime behavior changes in this selector.

## Inputs Read

The selector is based on:

- `.431` two-dynamic-plus-one-static mixed read burst-last `RID && RLAST`
  release-and-recapture behavior;
- `.430` public contract selection and `.429` readiness audit for that
  burst-last recapture boundary;
- `.427` two-dynamic-plus-one-static mixed read single-beat recapture
  behavior;
- `.423`, `.419`, `.415`, `.411`, `.407`, `.403`, `.400`, `.396`, `.392`,
  `.389`, `.385`, `.381`, `.378`, `.372`, `.368`, and `.365` shipped
  recapture records across dynamic and mixed dynamic/static write/read
  boundaries;
- `.357` two-dynamic-plus-one-static mixed read burst-last multi-beat
  output-bank behavior, which left only `same_id_ordering` in
  `response_demux.residue` for the covered public sample;
- `.362` and `.363`, which deliberately placed same-cycle
  release-and-recapture ahead of dynamic same-ID queues and scoreboards;
- `.216` through `.219`, where dynamic same-ID issue-order readiness selected
  dynamic transaction-ID contract/report support before generalized per-ID
  queues or scoreboards;
- the dynamic transaction-ID generated behavior chain that followed `.219`,
  including dynamic write/read response-demux, read-data, burst-length,
  runtime-validation, multi-beat, multiple dynamic, mixed dynamic/static, and
  same-cycle recapture records;
- current README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map
  entries for dynamic ID behavior, response-demux residue, and same-ID
  ordering residue.

## Decision

The next exact owner is an audit:

```text
IAL2-FEATURE-COMPLETENESS-FRONTIER.433
```

The audit should reopen the dynamic same-ID issue-order surface, not a direct
behavior implementation. Earlier dynamic same-ID readiness selected dynamic
transaction-ID contract/report work first because there was not yet a
generated dynamic ID capture and response-matching substrate. That prerequisite
is now substantially covered for the bounded public dynamic and mixed
dynamic/static response-demux/read-data/multi-beat/recapture shapes.

The local residue is now policy-heavy rather than a single helper widening:
response-demux reports can still leave `same_id_ordering` after generated
dynamic/mixed read-data chains, but accepting multiple outstanding requests
with the same dynamic ID needs an explicit issue-order guarantee and a
reviewable queue or scoreboard policy. Direct implementation would be
premature until the contract distinguishes:

- dynamic same-ID request admission versus the current no-active-same-ID
  assertion stance;
- per-ID issue-order queues versus scoreboard-style completion tracking;
- read and write family symmetry and any burst-last/raw non-final-beat
  special cases;
- request arbitration beyond the current onehot0 sibling policy;
- overflow, ambiguity, and response-active/unique-match assertions;
- report/residue movement when a selected subset becomes generated behavior;
- interactions with existing concrete-ID queue-head policy and generated
  auto-ID same-ID avoidance.

## Questions For `.433`

`.433` should decide the first exact dynamic same-ID owner after the generated
dynamic ID chain:

- public policy contract selection;
- report/static cleanup before behavior;
- generalized per-ID issue-order queue readiness;
- scoreboard policy/readiness;
- a narrower write-only or read-only audit;
- a smaller parser/report/lowerer prerequisite;
- or a recorded reason to defer dynamic same-ID ordering behind another
  roadmap-aligned IAL2 residue.

The audit must preserve `.431` behavior and the existing public syntax/support
identities unless it explicitly selects a later owner. It should not change
code or generated behavior.

## Deferred Boundaries

Direct dynamic same-ID queue behavior, scoreboard behavior, request arbitration
beyond onehot0, queued/blocking policy, profile aliases, full-manager
behavior, direct backend behavior, backend-language variants, and VHDL remain
future exact owners until `.433` selects a bounded next contract.

## Validation For This Selector

Selector closeout requires:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

No behavior-bearing command is required for `.432`.

## Rollback

Rollback is this docs-only selector commit. Reverting it removes only the
`.433` selection record, fact card, task-tree advancement, live-doc updates,
and resume pointer update; generated behavior remains at `.431`.
