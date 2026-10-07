"""Conserve the whole index, retain detailed task states and verify refreshed copies."""
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0,'scripts')
import book_source_references as plane

BASE = Path('docs/audits/coordinate-public-origin-hypotheses-checks-20261007')
OUTPUT = '.artifacts/coordinate-public-origin-hypotheses-book'
SUMMARY = ('Push deferred .69.2; HIAL/full CI/push .69.3 open. '
    'Parser/public/class-frame publication and .77 continuity/capacity repairs complete. '
    'Raw coordinates active: source/custody and finite public caller/boundary qualification committed; '
    'pure-source origin hypotheses done, origin intake next, then native controls, '
    'full qualification/publication and original join. Address/consumer/alias/cold and visual QA remain owned.')


def pin(raw):
    return dict(bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def main():
    before=(BASE/'index-before.md.txt').read_text()
    after=(BASE/'index-after.md.txt').read_text()
    marker='| `SEMANTIC-INTROSPECTION-MCP-FRONTIER` |'
    old=[line for line in before.splitlines(keepends=True) if line.startswith(marker)]
    plane.require(len(old)==1,'unique complete original active index row')
    parts=old[0].split(' | ')
    plane.require(len(parts)==5,'complete original index identity/status/lane/summary/route fields')
    parts[3]=SUMMARY
    expected=before.replace(old[0],' | '.join(parts))
    plane.require(after==expected and Path('docs/TASK_TREE.md').read_text()==after,
                  'whole index exact summary-only compaction and canonical equality')
    plane.require(len(old[0].rstrip('\n').encode())==874
                  and len(' | '.join(parts).rstrip('\n').encode())==562,
                  'independent complete before/after index line measurements')
    failure=json.loads((BASE/'doctrines.json').read_bytes())
    plane.require(type(failure['status']) is int and failure['status']==1
                  and 'max line bytes is 874 (> baseline 790 + growth 72)' in failure['stderr'],
                  'complete actual unchanged allowance failure retained')
    owner=(Path('docs/audits/record-value-coordinate-public-origin-hypotheses-20261007/scope.txt')
           .read_text().splitlines()[0].removeprefix('Owner: '))
    suffix='.2.2.2.2.2.2.1'
    plane.require(owner.endswith(suffix),'exact source-only hypothesis repair owner')
    raw_owner=owner[:-len(suffix)]
    task=Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md').read_text()
    completed=['SEMANTIC-INTROSPECTION-MCP-FRONTIER.69.2','SEMANTIC-INTROSPECTION-MCP-FRONTIER.77',
        *[raw_owner+suffix for suffix in ('.1','.2.1.1','.2.1.2','.2.2.1','.2.2.2.1',
                                         '.2.2.2.2.1','.2.2.2.2.2.1')],owner]
    retained={}
    for node in completed:
        start=task.index('- ID: `'+node+'`');end=task.index('\n- ID:',start+1)
        block=task[start:end]
        plane.require('\n  Status: `done`\n' in block,'complete canonical detailed completed state retained')
        retained[node]=block
    next_node=owner[:-1]+'2'
    start=task.index('- ID: `'+next_node+'`');end=task.index('\n- ID:',start+1)
    plane.require('\n  Status: `pending`\n' in task[start:end],'exact canonical origin intake frontier remains pending')
    build=json.loads((BASE/'book-index-refresh.json').read_bytes())
    plane.require(build['command']==['scripts/run_with_ram_guard.sh','--','mdbook','build','docs/book','--dest-dir',OUTPUT]
                  and type(build['status']) is int and build['status']==0,
                  'complete actual final index-refresh book command and integer success')
    rows=plane.expected_rows();plane.check(rows,OUTPUT);plane.check_index(rows)
    copies=[]
    for row in rows:
        current=plane.source_bytes(row['source'])
        copied=plane.local_read(plane.ROOT/OUTPUT/row['asset'],plane.SOURCE_BYTES)
        plane.require(current==copied,'complete final native copied-source currency')
        copies.append(dict(route=row,canonical=pin(current),copied=pin(copied)))
    native=Path(OUTPUT)/'13k-isf-feature-support-matrix.html'
    plane.require(native.read_bytes()==(BASE/'book-input.html').read_bytes(),
                  'complete qualified origin/caller native guide conserved after index refresh')
    product=dict(before=pin(before.encode()),after=pin(after.encode()),completed_nodes=retained,
                 next_node=next_node,copies=copies,actual=build,
                 scope='Exact index-byte conservation and canonical state routing plus final copied-source currency; summary phrasing equivalence remains engineer review, and old native-copy proof retains its original dated source epoch.')
    path=BASE/'index-repair-proof.json';encoded=json.dumps(product,sort_keys=True,indent=2)+'\n'
    if path.exists():plane.require(path.read_text()==encoded,'whole retained exact index repair proof')
    else:path.write_text(encoded)
    print('PASS exact whole index compaction, detailed canonical task-state retention and fresh final native source copies.')


if __name__=='__main__':
    main()
