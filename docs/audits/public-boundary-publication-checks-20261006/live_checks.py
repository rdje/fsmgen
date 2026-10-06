"""Exercise real superseded/current readers and restored unrelated book progress."""
import json
import subprocess
from pathlib import Path

BASE=Path('docs/audits/record-value-public-boundary-publication-20261006')
CHECKS=Path('docs/audits/public-boundary-publication-checks-20261006')
ns={'__name__':'publication_live_checks'}
exec(compile((BASE/'verify.py').read_bytes(),str(BASE/'verify.py'),'exec'),ns)
require,same,identity,load=(ns[k] for k in ('require','same','identity','load'))


def execute(command):
    result=subprocess.run(command,capture_output=True,text=True)
    return dict(command=command,status=result.returncode,stdout=result.stdout,stderr=result.stderr)


def main():
    path=CHECKS/'live-roles.json'; require(not path.exists(),'fresh actual live-role capture')
    retained=execute(['python3','-B',str(ns['RETENTION']/'verify.py'),'--live-unchanged'])
    require(type(retained['status']) is int and retained['status']==1
            and 'live card remains unchanged before publication' in retained['stderr'],
            'actual superseded retention live-unchanged refusal')
    old='docs/audits/record-value-own-boundary-publication-20261005/verify.py'
    snapshot=execute(['python3','-B',old])
    require(type(snapshot['status']) is int and snapshot['status']==0
            and snapshot['stdout'].startswith('PASS immutable own-boundary source publication'),
            'actual immutable superseded publication default snapshot')
    current=execute(['python3','-B',old,'--current'])
    require(type(current['status']) is int and current['status']==1
            and 'whole current source/role/question/reader epoch' in current['stderr'],
            'actual superseded whole-card current refusal')
    chapter=Path(ns['CHAPTER']); registry=Path(ns['REGISTRY'])
    before={str(chapter):chapter.read_bytes(),str(registry):registry.read_bytes()}
    candidate=before[str(chapter)]+b'\n<!-- Owned unrelated-progress qualification; restored before commit. -->\n'
    lines=registry.read_text().splitlines(); i=next(i for i,s in enumerate(lines) if json.loads(s).get('surface_id')=='shipped_behavior')
    surface=json.loads(lines[i]); change=surface['reference_contract']['aggregate_change']
    change['delta']['bytes_total']+=len(candidate)-len(before[str(chapter)])
    change['delta']['lines_total']+=candidate.count(b'\n')-before[str(chapter)].count(b'\n')
    lines[i]=json.dumps(surface,sort_keys=True,separators=(',',':'))
    candidate_registry=('\n'.join(lines)+'\n').encode()
    intake=CHECKS/'progress-restoration-intake.json'; require(not intake.exists(),'fresh durable restoration intake')
    intake.write_text(json.dumps(dict(source_before={p:raw.decode() for p,raw in before.items()},
        candidate_chapter=candidate.decode(),candidate_registry=candidate_registry.decode()),sort_keys=True,indent=2)+'\n')
    try:
        chapter.write_bytes(candidate); registry.write_bytes(candidate_registry)
        progress=execute(['python3','-B',str(BASE/'verify.py'),'--current'])
    finally:
        for p,raw in before.items(): Path(p).write_bytes(raw)
    restored=all(Path(p).read_bytes()==raw for p,raw in before.items())
    record=dict(retention=retained,superseded_snapshot=snapshot,superseded_current=current,progress=progress,
        programme_identity=identity((CHECKS/'live_checks.py').read_bytes()),
        source_before={p:raw.decode() for p,raw in before.items()},
        candidate_chapter=candidate.decode(),candidate_registry=candidate_registry.decode(),restored=restored)
    path.write_text(json.dumps(record,sort_keys=True,indent=2)+'\n')
    require(progress['status']==0 and progress['stdout']==ns['CURRENT_SUCCESS'], 'actual unrelated book progress current acceptance')
    require(restored, 'whole unrelated progress source restoration')
    print('PASS actual retained snapshot, both superseded current refusals and restored unrelated current progress.')


if __name__=='__main__': main()
