"""Specify a source-preserving rollover without editing production cards."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/knowledge-card-rollover-selection-20261005')
STORE = Path('docs/audits/knowledge-card-rollover-source-20261005')
REVISION = '436a207c5a80f2324dbcd2e4f8ac8aea1efea527'
NAMES = ['live-document-size-containment', 'live-document-surface-growth-procedure',
         'knowledge-card-sizing-and-partition', 'live-document-transition-allowance-headroom']


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def main():
    STORE.mkdir(parents=True, exist_ok=True)
    sources = {}
    for name in NAMES:
        path = 'docs/knowledge/' + name + '.md'
        raw = subprocess.check_output(['git', 'show', REVISION + ':' + path])
        assert Path(path).read_bytes() == raw, 'stable production source before selection'
        locator = STORE / (digest(raw) + '.txt')
        locator.write_bytes(raw)
        sources[name] = {'path': path, 'locator': str(locator), 'bytes': len(raw),
                         'lines': raw.count(b'\n'), 'sha256': digest(raw)}
    source = {'revision': REVISION, 'sources': sources}
    (BASE / 'source.json').write_text(json.dumps(source, sort_keys=True, indent=2) + '\n')

    prefix = Path(sources[NAMES[0]]['locator']).read_text().split('---\n', 2)[2]
    prefix = prefix[:prefix.index("T1554's recovery run")]
    main_body = prefix + '''## Current enforcement and reader contracts

Health targets measure warning and rollover pressure; inclusive ceilings reject
only excess and do not establish health. Transition debt also has a separate
baseline-plus-allowance bound. Decision 0064 supersedes the adoption-era claim
that the knowledge-card file ceiling is occupied; decision 0070 requires the
declared rollover at rollover debt. Read current measurements with
`scripts/check_live_document_size.sh`, and use
[[live-document-surface-growth-procedure]],
[[live-document-transition-allowance-headroom]] and
[[knowledge-card-sizing-and-partition]] for the current write procedure.

The bounded JSONL control plane uses typed records, finite registries, scalar
and array bounds, unknown-key refusal, and an independent content-line-byte
axis. Source inventory includes the README landing page. Coverage proves
classification, not health. The root doctrine's Registry and mechanical
enforcement section and the public checker contract own these rules.

Declared `core:` verifiers execute and must succeed. Local `adapter:` verifiers
earn exact registry-derived proofs; missing, duplicate and unused proofs fail.
`external:` contracts expose degradation and cannot produce green. Currency is
lifecycle-specific and opt-in; size compliance does not prove currency or
semantic truth. There is no global age, newest-date or distinct-date heuristic.
The root doctrine's Boundedness, currency, and truth section and the declared
registry contracts own the current behavior.

Author-overflow and reader-navigation routes have different destinations.
Overflow may not append to immutable history. A complete collection front door
uses literal membership, a reproducible generated index, or an explicit target
query. Fenced evidence-map paths and staged/worktree identity are checked.
The root doctrine's Core invariant section and
`scripts/check_live_document_resulting_tree.pl` own these contracts.

Migration evidence separately proves complete-source identity, semantic
closure, live working-set dimensions and unretained residue. These products
may overlap; do not add them as disjoint line counts. Version objects require
a named retention owner, reachability or backup guarantee, and shallow-history
or rewrite recovery. File archives are digest checked. Read the root doctrine's
Atomic partition, rollover, and archive protocol and Archive descriptor contract.

`maintained_reference` governs unique maintained product prose with semantic
parts, bounded complete mandatory navigation, per-part limits and exact fresh
aggregate-change authority; aggregate pressure caps are explicitly inapplicable.
Decision 0045 owns that distinction. Rolling ledgers instead preserve whole
entries, ordered sealed ranges and exact source reconstruction under declared
live-window and archive-transition bounds. Repeated task acceptance narration
uses finite authenticated history pointers while preserving the full node graph.
The root doctrine, ledger manifests and task-history manifests own these rules.

## Canonical views and historical evidence

The Knowledge Map keeps fact cards canonical, generates deterministic topic
shards, catalogues each fact once and assigns each question to one shard.
Shared questions link every matching fact. Its fixed-substring query wrapper
caches only disposable rows under `.artifacts/knowledge-map/query/` and checks
direct/cache parity. Query with
`knowledge-map/scripts/query_knowledge_map.sh 'question words'`; generated
shards and caches never own unique facts. The architecture and public checker
own the complete contract.

`docs/index/FOCUSED_DOCUMENTS.md` is the generated complete focused/ancillary
index. `doctrine/live_document_size/isf_reference_partitions.jsonl` and
`scripts/check_isf_reference_partitions.pl` own exact historical ISF sources
and current topic/navigation contracts. T1569 checks current structure;
activation reconstruction is a separate historical property. Current task
owners and family lifecycle state are read from `docs/TASK_TREE.md` and the
adoption tree, rather than copied completion counts.

Utility review precedes containment. Retention, merge, supersession, archive,
deletion or re-form needs source identity, classified consumers, named current
homes and genuine orphan controls. Decisions 0046-0049 and COMMIT.md own the
retired journals and live authority; no replacement status board is created.
The bounded review front door is `docs/LIVE_DOCUMENT_SIZE_CONTAINMENT_AUDIT.md`.
Detailed adoption outcomes, external-review dispositions and exact historical
measurements remain in the adoption task tree, decision records and the complete
retained predecessor below.

The predecessor's T1554 `_dyld_start` observations are historical evidence,
not a current OS diagnosis or probe authorization. Current native/startup
qualification and full CI remain owned and gated by the HIAL/VIAL task tree.
Use that tree's live frontier before executing a historical recipe.

Every original question and the complete predecessor, including the adoption
chronology and superseded file-ceiling claim, remain retrievable without Git
history. From the repository root, run:

```sh
python3 -B docs/audits/knowledge-card-rollover-selection-20261005/read_source.py live-document-size-containment
```

The bounded source catalog names the exact captured revision and digest.
The archive-descriptor registry verifies each retained file; the rollover
reader verifies source, question, current-rule, collection and retrieval closure.
Historical statements retain their capture boundary and do not authorize writes.
'''
    old_growth = Path(sources[NAMES[1]]['locator']).read_text().split('---\n', 2)[2]
    old_sizing = Path(sources[NAMES[2]]['locator']).read_text().split('---\n', 2)[2]
    old_headroom = Path(sources[NAMES[3]]['locator']).read_text().split('---\n', 2)[2]
    growth = old_growth.replace(
        "Two mechanisms are separate. Raising a surface's `transition.max_growth` to the\nnew measured actual, inside an unchanged ceiling, is a **declared measurement**\nand needs no authority record. Raising an `enforcement_ceilings` value is a\n",
        "Two mechanisms are separate. For eligible transition debt, decision `0070`\nre-declares `transition.max_growth` to cover measured actual plus one declared\n`ratchet_step`, clamped at the unchanged ceiling, with a live remediation owner.\nThat is a **declared measurement**, needing no ceiling authority. A\n`rollover_debt` surface is never widened: perform its declared rollover.\nRaising an `enforcement_ceilings` value is a\n")
    growth = growth.replace("warning milestone, so one added line trips `must declare warning_debt` — rewrite\na line in place or route the content to the surface whose role owns it.",
                            "warning milestone, so one added line can require owned warning remediation.\nClassify the information and its proper home; an arbitrary wording trim does\nnot establish containment or authorize growth.")
    sizing = old_sizing[:old_sizing.index('Each card is bounded')] + '''Each card has independent line, original encoded-byte and content-line-byte
limits. The default Knowledge Map profile is 512 logical lines, 32,768 bytes
and 819 content-line bytes. The containment surface separately declares
per-file limits and file-count/aggregate bounds. Its line measurement counts
completed LF bytes; a final unterminated line still counts in the card checker.
Read configuration and both public checkers before assigning a failure cause.

The default card-width limit is below containment's 80% line-width warning
boundary. That says nothing about the other pressure axes or the surface's
health. Maximum-file bytes, aggregate bytes, lines, file count and the owned
transition allowance can bind independently. Splitting a large card can reduce
per-file pressure while increasing aggregate overhead and file count. Do not
infer aggregate growth permission from one card's remaining bytes.

Partition by semantic topic while preserving the original ID/path, all unique
facts, questions and cross-links. Compare complete question-to-ID/path rows,
not only totals: totals alone cannot expose swapped ownership or replaced
questions. A redistribution-only split preserves unique questions and answer
occurrences, and adds only the declared new fact members. New question routes
need their own explicit expected delta. Inspect current authority before
demoting a duplicate; dated history remains exactly retrievable. Live topic
partitioning needs no archive descriptor, but moving bytes out of the live
collection does require one. Aggregate rollover and retrieval must land atomically.

Related: [[live-document-surface-growth-procedure]],
[[live-document-size-containment]].
'''
    headroom = old_headroom.replace(
        "  declared rollover. `ancillary_documents` sits at 100% of its `files` target\n  and is left alone for that reason.",
        "  declared rollover. Decision `0070`'s ancillary occupancy is a dated\n  adoption observation; derive current pressure from the registry and checker.")
    headroom = headroom.replace('If `baseline + step` would exceed the', 'If `measured actual + step` would exceed the')
    headroom = headroom[:headroom.index('A related bound lives')] + '''A related bound lives outside containment: the default fact-card content-line
width is 819 bytes. Containment's line-width target and the card checker's bound
are distinct authorities; a compliant line does not establish whole-surface
health. The predecessor's line-width census is historical, not a current count.
A long `reverify:` line fails the card checker, and increasing a containment
target cannot admit it. Query [[knowledge-card-sizing-and-partition]] and derive
current collection pressure with the public checkers.
'''
    bodies = dict(zip(NAMES, [main_body, growth, sizing, headroom]))
    for name in NAMES:
        original = Path(sources[name]['locator']).read_text()
        front = original.split('---\n', 2)[1]
        front = re.sub(r'^date:.*$', 'date: 2026-10-05', front, flags=re.M)
        front = re.sub(r'^reverify:.*?(?=^[^ \n])',
                       'reverify: >-\n  python3 -B docs/audits/knowledge-card-rollover-20261005/verify.py --current\n',
                       front, flags=re.M | re.S)
        # The final front-matter field has no following field.
        if 'docs/audits/knowledge-card-rollover-20261005' not in front:
            front = re.sub(r'^reverify:.*$', 'reverify: >-\n  python3 -B docs/audits/knowledge-card-rollover-20261005/verify.py --current\n', front, flags=re.M | re.S)
        if name != NAMES[0]:
            bodies[name] += '\nRetrieve the complete dated predecessor from the repository root:\n\n```sh\npython3 -B docs/audits/knowledge-card-rollover-selection-20261005/read_source.py ' + name + '\n```\n'
        (BASE / (name + '.proposed.txt')).write_text('---\n' + front + '---\n' + bodies[name])
    # Every byte belongs to the retained complete source, including separators.
    units = {}
    for name, row in sources.items():
        raw = Path(row['locator']).read_bytes()
        position = 0; members = []
        for match in re.finditer(rb'.*?(?:\n\n|\Z)', raw, flags=re.S):
            unit = match.group()
            if not unit:
                continue
            assert match.start() == position
            members.append({'start': position, 'end': match.end(), 'sha256': digest(unit),
                            'role': 'exact dated predecessor; current authority remains in doctrine/registries and the proposed card'})
            position = match.end()
        assert position == len(raw)
        units[name] = members
    (BASE / 'coverage.json').write_text(json.dumps(units, indent=2, sort_keys=True) + '\n')


if __name__ == '__main__':
    main()
