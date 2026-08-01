# Live-Document Utility And Retirement Audit

- Date: `2026-07-31`
- Owner: `LIVE-DOCUMENT-SIZE-CONTAINMENT-ADOPTION.16`
- Evidence revision: clean activation commit `289e946149371000bc824ffc0235bb341b706e5b`
- Status: outcomes selected; migrations and retirements remain separate
- Destructive action in this audit: none

This audit asks whether each governed document family still performs a useful
current job before asking how to contain its size. It is the FSMGen adoption
record for the project-neutral rule in
[`LIVE_DOCUMENT_SIZE_CONTAINMENT.md`](../LIVE_DOCUMENT_SIZE_CONTAINMENT.md):
size pressure triggers containment work, while a change of role, canonical
input, replacement, or consumers triggers utility review.

The independent PGEN and ANVIL reviews are represented by the tracked
[disposition](LIVE_DOCUMENT_SIZE_CONTAINMENT_EXTERNAL_REVIEW_DISPOSITION.md).
The reread ANVIL input is exactly 334 lines / 44,242 bytes at SHA-256
`9dac9f1f442ea4baa9afe1f1a56bd8bda3bb54bf2de0156c563ad0df85f61be2`,
matching that disposition. Machine-local review paths are inputs, never
durable project locators.

## Executive decision

FSMGen must not partition every large Markdown file. The evidence selects
three materially different actions:

- retain live canonical roles such as the GitHub README, mdBook, decisions,
  task evidence, Knowledge Cards, and the actively consumed ISF contracts;
- re-form useful roles whose current representation is the problem, including
  the roadmap, Knowledge Map, Chapter 14, `docs/ISF_SPEC.md`, focused
  slice-evidence collections;
- supersede completed migration waypoints `docs/USER_GUIDE.md` and
  `docs/BOOK_PLAN.md` only after a fresh content/consumer/replacement proof;
- delete `WARP.md` after the director confirmed that warp.dev is no longer
  used and the owned `.25` proof found no surviving discovery role.
- delete `CHANGES.md` after the later director-authorized `.4` audit found no
  current content consumer or distinct question beyond task trees and Git.

Decision `0047` supersedes only the changelog-retention portion of the earlier
four-file review. The conditional rationale ledger remains separately owned by
`.5`. Both status files remain byte-frozen; `.11` must audit each independently
and obtain the director's document-specific lifecycle choice before changing
either path.

No file is deleted, archived, moved, reclassified, or content-migrated here.
Leaves `.24` and `.25` below isolate the two newly discovered migrations;
existing leaves retain all earlier family work.

## Audit method and limitations

The census uses the unconditional live-document checker, direct file/heading
measurement, Git last-change evidence, exact literal-reference scans over all
tracked files, and focused whole-document token probes. Incoming references
are classified by what they require, not merely counted: content consumer,
reader navigation, author-routing hint, executable/test contract, current
planning dependency, or historical mention.

A literal reference does not prove utility. `CHANGES.md`, frozen narratives,
task evidence, and the generated Knowledge Map legitimately preserve old path
names. Conversely, one executable consumer can make a small document
load-bearing. The selected outcome therefore combines audience, canonical
role, unique content, duplication, currency, consumer kind, and retention.

The clean activation census covers `2,784 / 2,784` tracked Markdown paths in
22 declared surfaces. Important current measurements are:

| Surface | Current working-set evidence | State |
| --- | ---: | --- |
| root `*.md` | 21 files; 127,069 lines; 14,835,778 bytes | rollover debt; semantic owners differ |
| focused `docs/*.md` | 1,004 files; 212,051 lines; 9,369,849 bytes | rollover debt; one file of headroom before this audit |
| mdBook | 38 files; 47,427 lines; 2,514,830 bytes | maintained reference; Chapter 14 per-part debt |
| task evidence | 568 files; 99,547 lines; 9,375,175 bytes | migrated and normal |
| decisions | 46 files; 3,022 lines; 170,770 bytes | steady and normal |
| Knowledge Cards | 1,097 files; 42,034 lines; 3,209,104 bytes | canonical collection debt |
| generated Knowledge Map | 15,634 lines; 6,151,941 bytes | structural projection debt |
| change/rationale ledgers | 66,805 lines; 5,189,508 bytes | deferred rollover debt |

These values prove pressure, not usefulness. The family and candidate tables
below supply the missing semantic judgment.

This tracked audit consumes the focused collection's one-file transition
allowance, producing 1,005 files at the inclusive ceiling. No additional
direct `docs/*.md` file may land before `.24` or another owned migration
reduces the collection; widening the ceiling is not an alternative.

## Outcome vocabulary

Every migration record must select exactly one outcome before choosing a
storage topology:

| Outcome | Meaning | Minimum proof |
| --- | --- | --- |
| `retain` | Current role, audience, and representation remain justified. | Named role, canonical home, current consumer, and boundedness owner. |
| `merge` | Unique material moves into an existing canonical home. | Itemized destination coverage and updated consumers. |
| `supersede` | A replacement already owns the whole role. | Replacement parity plus removal-safe content and consumer proof. |
| `archive` | Current use ends but exact historical content must remain addressable. | Immutable identity, index/descriptor, retrieval, and retention contract. |
| `delete` | No current or historical product remains. | Zero unexplained unique residue and zero content-required consumers. |
| `re-form` | The role survives while its representation changes. | Surviving role, replacement representation, semantic coverage, and no lost unique prose. |

`Supersede` and `delete` are not synonyms. A superseded live file can be
removed only after the replacement and historical-retention proofs pass;
`delete` additionally asserts that no separately valuable historical product
exists.

## Complete governed-family disposition

| Surface | Current audience and canonical role | Utility evidence and pressure | Outcome | Atomic owner |
| --- | --- | --- | --- | --- |
| `readme_entrypoint` | GitHub visitors; direct identity, quick start, architecture, and canonical navigation | 245 lines / 9,917 bytes; first-class rendered landing interface, not an overflow buffer | `retain` | `.12` final calibration only |
| `root_documents` | Mixed users/maintainers/automation; bounded project entry and continuity contracts | 20 heterogeneous files after WARP retirement; group pressure comes from ledgers, frozen records, roadmap, and projection rather than one common role | `re-form` | `.3`-.5, `.9`, `.11`, `.12`, `.24`, `.25` |
| `focused_documents` | Users, downstream integrators, maintainers, and auditors; mixed specifications/contracts/slice evidence | 1,004 files; active specifications coexist with large historical readiness/contract cohorts | `re-form` | `.13` after `.24` |
| `ancillary_documents` | Harnesses and maintainers; compact bootstrap/workflow/audit entry points | 10 files / 1,229 lines; normal and query-indexed | `retain` | `.13` periodic classification |
| `shipped_behavior` | Users/authors; canonical product explanation and examples | Unique maintained prose, bounded SUMMARY and parts; Chapter 14 is the per-part outlier | `retain` family; `re-form` Chapter 14 | `.8` |
| `reported_capabilities` | Tools and users; generated capability query | Executable terminal rather than authored history | `retain` | capability contract tests |
| `high_level_direction` | Director and maintainers; current/future roadmap | 10,451 lines; shipped chronology obscures current direction | `re-form` | `.9` |
| `active_resume` | Next session; bounded current resume pointer | 38 lines / 2,278 bytes, overwrite-only, no required history | `retain` | memory architecture |
| `active_index` | PNT and maintainers; active/proposed task selection | 560 lines; migrated, currency-checked, and normal | `retain` | `.7` |
| `task_evidence` | Maintainers/auditors; canonical work/evidence graph | 568 files; current root plus exact bounded segment/history contracts | `retain` | `.7` and task workflow |
| `rationale` | Implementers; canonical accepted decisions | Small one-decision-per-file units with complete index | `retain` | decision workflow |
| `engineering_rationale` | Implementers; interim non-derivable rationale ledger | 34,506 lines; only conditional new entries are allowed | `retain` provisionally | four-file review, then `.3`/`.5` |
| `knowledge_cards` | Agents/maintainers; canonical question-answer facts | Current and addressable, but one card and long lines exceed part targets | `retain` facts; `re-form` outliers | `.10` |
| `fact_index` | Agents/tools; disposable generated discovery projection | 6,151,941 bytes and 10,275-byte longest line; no unique content | `re-form` | `.10` |
| `change_history` | Formerly maintainers/users; curated per-slice change narration | 32,299 lines; no content consumer or distinct current question beyond task/Git evidence | `delete`, exact version object retained | `.4`, decision `0047` |
| `exact_history` | Auditors; exact Git objects | Query-only terminal with explicit retention contracts where depended upon | `retain` | version-control audit trail |
| `diagnostics` | Engineers; bounded procedure/tool index | 317 lines / 12,761 bytes; active bootstrap consumer, still normal | `retain` | toolbox maintainers |
| `enforced_rules` | All contributors; bounded doctrine index | 223 lines / 12,854 bytes; active mechanical contract | `retain` | doctrine maintainers |
| `frozen_roadmap_status` | Possible historical/project-status readers; role under review | 15,039 lines / 1,638,574 bytes, exact frozen identity, last changed 2026-06-01 | `retain` byte-frozen pending decision | four-file review, then `.11` |
| `frozen_achievement_status` | Possible historical/achievement readers; role under review | 16,618 lines / 955,308 bytes, exact frozen identity, last changed 2026-06-01 | `retain` byte-frozen pending decision | four-file review, then `.11` |
| `live_document_review` | External/internal reviewers; bounded current architecture entry | 78 lines / 4,060 bytes; current front door | `retain` | `.22` |
| `external_review_packet` | Auditors; exact detailed review evidence | 1,311 lines, SHA-256 frozen, no longer appended or mandatory | `archive` | `.22` complete |

## Named document and cohort audit

### Completed guide-migration waypoints

| Candidate | Evidence | Consumer classification | Selected outcome |
| --- | --- | --- | --- |
| `docs/USER_GUIDE.md` | 130 lines / 5,468 bytes; every major section declares a named mdBook home; last changed at `ee977fea9` on 2026-05-14 | Fresh `.24` census finds 19 referring files: 2 executable/test, 7 navigation/planning, 4 current governance/evidence, and 6 historical/archive records | `superseded` by `.24`; current consumers now use the mdBook |
| `docs/BOOK_PLAN.md` | 310 lines / 9,968 bytes; top says “in progress,” while the guide is already reduced and every named chapter exists | Fresh `.24` census finds 7 referring files: 1 live planning, 3 current governance/evidence, and 3 historical records | `superseded` by `.24`; one unique focused link and one quality rule migrated first |

A preliminary case-insensitive sweep of all 212 distinct five-or-more-character
word/identifier tokens in `docs/USER_GUIDE.md` against the mdBook found nine
absent compound spellings: `assignment-operator`, `back-end`, `first-run`,
`heading`, `linking`, `old-guide-to-book`, `overview`, `result-surface`, and
`waypoint`. Their source contexts describe migration/navigation rather than an
unmapped product contract. This is strong supersession evidence, but it is not
the deletion proof: `.24` must repeat the sweep on its exact candidate bytes,
enumerate all residue, exercise the negative control, and update the two
executable consumers plus every current navigation consumer atomically.

#### Executed `.24` proof

The clean activation commit `65c646a1239f27e032068674709b6f21c4430ab6`
provides both exact source objects:

- `docs/USER_GUIDE.md`: 130 lines / 5,468 bytes / SHA-256
  `18de5df2ba5247a6037191f5efd2d18b4ede297537c22de6ab77a823c00916c2`;
- `docs/BOOK_PLAN.md`: 310 lines / 9,968 bytes / SHA-256
  `dd82c5987efad596ce40575a26d182b99d46a7c834cde5b99baf84d768ff9b06`.

The fresh USER_GUIDE sweep again finds 212 distinct case-folded tokens of at
least five characters. Eight are absent from the mdBook:
`assignment-operator`, `back-end`, `first-run`, `heading`, `linking`,
`old-guide-to-book`, `overview`, and `result-surface`. Each is a hyphenation,
heading, or migration-navigation spelling whose concept is already in the
named owning chapter; none is unique product behavior. Appending the in-memory
token `fsmgen_orphan_probe_user_guide` changes residue from 8 to 9 and reports
that exact planted token.

The BOOK_PLAN sweep finds 392 tokens against the mdBook plus decisions `0006`
and `0045`. Its 39 residues are: `basic-usage`, `book-like`, `breadcrumbs`,
`buried`, `chapter-level`, `chaptered`, `essential`, `extension-specific`,
`first-run`, `focused-reference`, `giant`, `harder`,
`intent_capture_axi_case_study`, `interrupted`, `moderately`, `namespacing`,
`non-obvious`, `normalized-export`, `old-guide`, `on-ramp`, `orientation`,
`orients`, `plentiful`, `problems`, `progressively`, `quickstart`, `recurring`,
`reduce`, `rollout`, `roughly`, `sessions`, `solves`, `study`, `styles`,
`support-boundary`, `tool-facing`, `topics`, `tutorials`, and `world`.
The exact case-study identifier is now linked from the book reference map; the
non-obvious-failure/rejected-form quality rule is now in the introduction.
The remaining items are compound spellings or completed migration/process
prose rather than unique product contracts. The in-memory
`fsmgen_orphan_probe_book_plan` raises this residue from 39 to 40 exactly.

All executable and current reader consumers now name `SUMMARY.md`, the book
introduction, the reference map, or the owning diagnostic chapter. README's
GitHub landing table routes directly to the book; the capability manifest
replaces the obsolete guide path with the introduction and its focused test
asserts both the replacement and absence. Current book and roadmap planning
language no longer treats either waypoint as live. Historical ledgers, frozen
status, completed-task, and frozen review evidence keep factual path mentions;
the current task, fact, audit, and disposition keep proof references only.
The post-edit classifier reports zero unresolved consumers for each name; an
in-memory `probe/current_user_guide_consumer.pl` or
`probe/current_book_plan_consumer.md` changes its respective result to one.

Both Git objects are reachable with `git show 65c646a1239f27e032068674709b6f21c4430ab6:<path>`
and reproduce the line, byte, and digest identities above. Contract
`fsmgen_required_history` names the repository maintainers, authoritative/full-
history guarantee, and shallow/rewrite recovery. The resulting-tree and
planted-consumer gates below must still pass after removal.

### Retired harness bootstrap

Clean activation revision `f02da976fad6aa0a6f42daa8265fc211f9d78f20`
identifies `WARP.md` at 183 lines / 6,878 bytes and SHA-256
`3b2b47e977ea616fb8a17f5c726bcd82e235df5abb8be1a570b66269e3dc7847`.
It was last substantively changed at `2cfe9cda3` on 2026-06-22. The director
then confirmed that warp.dev is no longer used, so the discovery role assumed
by the preliminary audit no longer exists.

A fresh case-folded whole-file sweep compares 287 normalized tokens of at
least five characters against `AGENTS.md`, `README.md`, `TOOLBOX.md`, the
mdBook, decisions, and Knowledge Cards. Its 53 residues are:
`astfactorization`, `awareness`, `benefits`, `combinatorial`, `complex`,
`converts`, `cross-dt`, `dependency-aware`, `descriptive`, `dt_name`,
`ensures`, `factorizer`, `four-registry`, `fsm-to-hdl`, `fsm/mipicsi2`,
`fsm/mipicsi2_tester_ctrl.fsm`, `fsm:my_fsm`, `fsmgen-specific`, `hffff`,
`insights`, `intelligently`, `iterative`, `known-good`, `management`,
`multi-pass`, `multi-stage`, `multi-target`, `multiplexer`, `my_fsm.fsm`,
`my_fsm.log`, `my_fsm.sv`, `output.v`, `overview`,
`perl/fsm/adapter/fsmgenfull.pm`, `perl/fsm/hdl/astfactorization.pm`,
`perl/fsm/hdl/flatteneddt.pm`, `practices`, `pre-scan`, `prevention`,
`production-quality`, `real-world`, `rescues`, `s_rst_n_and_pready`,
`self-reference`, `sophisticated`, `subsystems`, `systemverilog/verilog/vhdl`,
`test_signal`, `underscores`, `visualizations`, `warp.dev`, `warp.md`, and
`x/11xx/12xx`. They are local source/sample/output names, covered composite
spellings, obsolete architecture shorthand, or non-contractual adjectives;
none is unique accurate guidance. The concrete commands and current workflow
are already canonical in the retained homes, while WARP's debug-level range
and four-registry summary are stale. Planting
`fsmgen_orphan_probe_warp_bootstrap` raises residue to 54 and detects that
token exactly.

The exact activation tree has five referring files: `CHANGES.md` and
`DEVELOPMENT_NOTES.md` are factual history; this audit and its task are proof
records; `scripts/check_doctrine_bootstrap.sh` was the only executable
consumer. No current product, author, harness, or content consumer requires
the file. After removing that one obsolete requirement, the resulting-tree
classifier reports zero unresolved consumers; an in-memory
`probe/warp_bootstrap_consumer.sh` raises it to one exactly. Leaf `.25`
therefore deletes `WARP.md`, makes the local doctrine checker require its
absence, and retains every other bootstrap marker check unchanged. Exact
recovery remains available with `git show f02da976f:WARP.md` under the existing
`fsmgen_required_history` contract.

### Active maintained specifications

Size is not evidence for retirement:

| Candidate | Current evidence | Outcome |
| --- | --- | --- |
| `docs/ISF_SPEC.md` | 6,254 lines / 392,322 bytes; changed 2026-07-30; 69 referring files including implementation, six tests/gates, tasks, cards, book, and peer contracts | `re-form` into indexed semantic parts under `.13`; retain all unique contract prose |
| `docs/ISF_PUBLIC_INTERFACE_CONTRACT.md` | 3,759 lines / 253,774 bytes; changed 2026-07-30; 55 referring files including implementation/tests | `retain` as a maintained contract part; index under `.13` |
| `docs/ISF_DOWNSTREAM_INTEGRATION_SPEC.md` | 4,485 lines / 227,933 bytes; changed 2026-07-30; 64 referring files including implementation/tests | `retain` as a maintained integration part; index under `.13` |

These files demonstrate why “large therefore obsolete” would be destructive.
`docs/ISF_SPEC.md` needs a better representation, while the two already
bounded companion contracts still provide current unique machine- and
maintainer-consumed value.

### Focused readiness, contract, and behavior evidence

The direct `docs/*.md` collection contains these filename-shaped cohorts:

| Cohort | Files | Lines | Bytes | Files with at least one literal incoming reference |
| --- | ---: | ---: | ---: | ---: |
| readiness audits | 220 | 44,590 | 1,936,446 | 218 |
| contract selections | 176 | 46,620 | 1,853,358 | 176 |
| behavior records | 220 | 36,800 | 1,411,161 | 220 |
| first-slice records | 43 | 6,394 | 217,022 | 43 |
| other audits | 20 | 3,896 | 197,738 | 20 |

Literal references include historical ledgers and peer artifacts, so the table
does not prove that every file remains a live canonical input. It does prove
that bulk deletion or extension-based archiving would break traceability.
Outcome `re-form` under `.13` keeps unique contract/evidence directly
addressable, adds a bounded complete semantic index, classifies current versus
historical consumers, and retires only individually proved duplicates. A
filename suffix is not sufficient retirement evidence.

## Mandatory deletion and retirement proof

Any future leaf that removes a tracked live document must record all of these
against the exact staged candidate:

1. **Identity:** path, source revision, SHA-256, lines, bytes, longest line, and
   selected utility outcome.
2. **Whole-document token/ID sweep:** extract headings, code spans, stable IDs,
   paths, and normalized words of at least five characters; map every residue
   to a replacement or classify it as an enumerated composite/non-semantic
   artifact. A hand-picked phrase list is insufficient.
3. **Classified consumer census:** scan all tracked documentation, code, tests,
   scripts, registries, comments, and generated-input declarations; classify
   every hit as content, navigation, author hint, executable contract,
   current planning, or history.
4. **Replacement pointers:** give a resolvable canonical destination for every
   surviving role and unique fact; prove required readers/tools reach it.
5. **Negative controls:** inject a unique orphan token into a repository-local
   fixture copy and prove the sweep reports it; inject or retain one unresolved
   content-consumer reference and prove the census/removal gate rejects it.
6. **Retention:** when historical identity still matters, prove a
   content-addressed repository object or an explicit version-retention
   contract with retrieval and actionable recovery.
7. **Resulting-tree proof:** stage the complete migration/removal, rerun the
   probes against that resulting tree, and pass links, book, task, Knowledge
   Map, acceptance, locality, and all doctrine gates.

Zero search hits alone cannot authorize deletion: the search itself must pass
its planted-orphan and planted-consumer negative controls in the same leaf.

## Utility-review triggers

A family or document is re-audited when any of these facts changes:

- its declared role or audience changes, or its observed content no longer
  matches them;
- a canonical input is added, removed, or moved;
- a replacement representation or product is introduced or becomes complete;
- consumer classes change materially, especially when content/executable
  consumers become navigation/history-only or reach zero;
- a current surface becomes generated/derivable, or a generated view acquires
  unique hand-authored content.

Size warning/rollover still triggers containment, but never selects `retain`
or a storage topology by itself. A roughly periodic control-plane census may
find missed trigger events; elapsed time alone does not make a document stale.

## Projection-amplification risk

The `.15` signoff exposed a non-obvious generated-view cost: adding one
`reverify` command to a canonical fact card expanded `KNOWLEDGE_MAP.md` by
1,482 bytes because the same value is projected under many question keys. The
card edit was reverted rather than consuming projection headroom. Leaf `.10`
must therefore measure source-to-projection amplification as well as raw map
size when it designs shards; a small canonical edit is not necessarily a small
generated aggregate change.

## Atomic execution map

| Owner | Outcome to execute after this audit |
| --- | --- |
| `.3`-.5 | Consume the separately selected ledger roles; migrate only retained ledgers. |
| `.8` | Re-form Chapter 14 into stable user-facing topics. |
| `.9` | Re-form live roadmap direction and separately retain proved chronology. |
| `.10` | Re-form oversized cards and the generated map while keeping facts canonical. |
| `.11` | Execute only the separately selected frozen-status decision. |
| `.13` | Re-form/index focused evidence and `docs/ISF_SPEC.md`; retire only per-file proved duplicates. |
| `.24` | Complete; both guide waypoints independently proved, superseded, and retained exactly in Git history. |
| `.25` | Retire unused WARP bootstrap after exact claim/consumer/negative-control proof; enforce absence while preserving Git recovery. |
| `.12` | Re-audit and lower steady-state ceilings only after all selected migrations. |

This audit is the decision boundary, not an authorization to combine those
operations. Each owner starts from a clean repository and commits its own
content movement, consumer updates, evidence, and cleanup atomically.
