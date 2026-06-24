# AXI IAL2 Manager Post Mixed Dynamic Static Read RLAST Recapture Next Slice Selection

Task-tree owner: `IAL2-FEATURE-COMPLETENESS-FRONTIER.397`

Date: 2026-06-24

## Decision

`IAL2-FEATURE-COMPLETENESS-FRONTIER.397` selects
`IAL2-FEATURE-COMPLETENESS-FRONTIER.398`, readiness audit for broader mixed
dynamic/static same-cycle release-and-recapture after the one-dynamic plus
one-static mixed write, read single-beat, and read burst-last recapture
contracts shipped.

The selector changes no parser, generator, PPIF sample, support-accounting
catalog, validation behavior, generated artifact, test, schedule/check or
semantic JSON, HDL, or runtime behavior.

## Evidence Read

The selector read or used:

- `.396` mixed dynamic/static read burst-last `RID && RLAST` recapture
  behavior.
- `.395` mixed read burst-last recapture contract selection.
- `.394` mixed read burst-last recapture readiness audit.
- `.393` post mixed read single-beat recapture selector.
- `.392` mixed dynamic/static read single-beat `RID` recapture behavior.
- `.389` mixed dynamic/static write `BID` recapture behavior.
- Existing multiple mixed dynamic/static write, read single-beat, and read
  burst-last behavior records.
- Existing one-dynamic plus three-static and two-dynamic-plus-one-static mixed
  dynamic/static write/read/read-`RLAST` behavior records.
- Mixed read-data, raw-`ARLEN`, runtime-validation, and multi-beat
  preservation records over generated mixed dynamic/static response-demux
  variants.
- Current focused t/1436/t1437/t1438 expectation surfaces, support accounting,
  README, ROADMAP_V2, mdBook, Memory, task tree, and Knowledge Map.

The `.396` guarded runtime caveat is recorded: schedule JSON attempts for the
selected one-dynamic plus one-static mixed read burst-last public sample were
stopped by the RAM guard at 96.5% and 97.0% host memory, and the focused
t/1438 probe stopped at 89.6% against the 88% cutoff. No cutoff was raised.

## Rationale

The smallest mixed dynamic/static recapture family is now covered:

- mixed write `BID` recapture;
- mixed read single-beat `RID` recapture; and
- mixed read burst-last `RID && RLAST` recapture.

The next closest residue is broader mixed dynamic/static recapture. It is
closer than queues, scoreboards, request-arbitration widening, backend
variants, or VHDL because it reuses the same dynamic selected-ID lifecycle and
static concrete busy lifecycle, but it is materially broader than `.389`,
`.392`, and `.396`:

- one dynamic plus multiple concrete static slots adds sibling static busy
  recapture and pairwise concrete-ID exclusions;
- one dynamic plus three concrete static slots increases the same static-busy
  and report-surface cardinality;
- two-dynamic-plus-one-static shapes combine mixed static-ID reservation with
  active dynamic selected-ID uniqueness and no-active-same-ID checks; and
- read burst-last siblings must preserve raw non-final `RID` beats while
  release and recapture remain final `RID && RLAST` events.

That breadth should not jump straight to implementation. A readiness audit
must decide whether the first broader mixed recapture contract should start
with one-dynamic plus two-static write `BID`, one-dynamic plus three-static
write `BID`, two-dynamic-plus-one-static write `BID`, or a read-side contract,
and whether any helper/report cleanup is needed before behavior changes.

Validation retry after the `.396` host-memory cutoff is not selected as the
next exact owner. The cutoff is environmental, the slice failed closed, and
future audit or implementation leaves can run guarded probes again when host
memory permits. Static-busy-only recapture outside public mixed samples,
request arbitration beyond onehot0, dynamic same-ID queues, scoreboards,
backend variants, VHDL, and full-manager behavior remain later owners.

## Selected .398 Scope

`.398` should audit broader mixed dynamic/static same-cycle
release-and-recapture readiness. It should read:

- `.397`, `.396`, `.395`, `.394`, `.393`, `.392`, `.389`, and `.387`;
- multiple mixed dynamic/static write/read/read-`RLAST` behavior docs;
- one-dynamic plus three-static and two-dynamic-plus-one-static mixed
  dynamic/static behavior docs;
- current response-demux write/read normalization, mixed dynamic/static state
  builders, static busy state helpers, dynamic/static release-only and
  release-recapture rule helpers, assertion/report helpers, and focused
  expectation surfaces;
- support accounting, README, ROADMAP_V2, mdBook, Memory, task tree, and
  Knowledge Map.

The audit should decide:

- which public sample and cardinality should be the first broader mixed
  recapture contract owner;
- whether mode strings and support identities remain unchanged;
- how dynamic recapture fields are reported when multiple dynamic
  transactions are present;
- how static concrete busy recapture fields are reported when multiple static
  transactions are present;
- whether existing onehot0 request policy remains the boundary for the first
  broader mixed recapture behavior;
- how release-only guards exclude same-transaction same-cycle requests across
  dynamic and static states;
- how release-recapture guards block opposite-class and same-class sibling
  requests where selected;
- how static-ID exclusions, active dynamic-ID uniqueness, request
  no-active-same-ID checks, raw response active/unique-match assertions, and
  completion-active assertions are preserved;
- how read burst-last raw non-final beats and final `RLAST` completion
  interact with recapture;
- which read-data, raw-`ARLEN`, runtime-validation, and multi-beat consumers
  are preservation-only for the first behavior owner;
- focused validation and preservation gates, including RAM-guard constraints;
  and
- rollback, docs, Knowledge Map, direct-backend deferral, and VHDL deferral.

Useful guarded baseline schedule probes, if host memory permits, include:

```bash
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_static.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_static_burst_last.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_write_mixed_dynamic_static_response_demux_multi_dynamic.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic.ppif
scripts/run_with_ram_guard.sh -- env -u PERL5LIB ./bin/fsmgen --quiet --emit-schedule-json ppif/axi_manager_capacity_status_read_mixed_dynamic_static_response_demux_multi_dynamic_burst_last.ppif
```

`.398` should not force heavyweight probes outside the RAM guard because it is
a readiness audit.

## Validation

`.397` is docs-only. Closeout validation is:

```bash
bash knowledge-map/scripts/gen_knowledge_map.sh
bash knowledge-map/scripts/check_knowledge_map.sh
scripts/check_memory_architecture.sh
git --no-pager diff --check
mdbook build docs/book
scripts/check_doctrines.sh
```

## Deferred Boundaries

This selector does not implement behavior. Static-busy-only recapture outside
selected public mixed samples, request arbitration beyond onehot0, dynamic
same-ID queues, scoreboards, queued/blocking policy, profile aliases, direct
backend behavior, backend-language variants, VHDL, and full AXI manager
behavior remain later exact owners.

## Rollback

Rollback is the `.397` selector commit. Reverting it restores `.397` as the
active post mixed read burst-last recapture selector and removes `.398` as the
selected readiness-audit owner.
