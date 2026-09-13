"""Close only the preserved rejection disposition, with repair still proposed."""
import argparse
import hashlib
import json
import re

from audit import BASE, ROOT, REVISION, read, old, verify

LOG=ROOT/'.artifacts/logs/native-proxy-compiler-census-execution-20260913'
STAGES=['rejection-audit-final','rejection-saved','knowledge-generate-final','knowledge-check-final','knowledge-query',
        'pickaxe','book','book-inspection-final','claims-write','claims-check','claims-review','claims-after-containment']


def pin(path):
    raw=path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)),size_bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest())


def check(outputs):
    for p in read('completion-pins.json'):assert pin(ROOT/p['path'])==p
    assert set(outputs)==set(STAGES)
    assert all(v['exit']=='0\n' for v in outputs.values())
    result=verify();assert read('review.json')==result
    expected=dict(**result['result'],rejected_controls=len(result['rejected_controls']))
    assert json.loads(outputs['rejection-saved']['stdout'])==expected
    assert json.loads(outputs['rejection-audit-final']['stdout'])==expected
    assert 'knowledge-map: OK' in outputs['knowledge-check-final']['stdout']+outputs['knowledge-check-final']['stderr']
    assert 'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in outputs['knowledge-query']['stdout']
    assert REVISION in outputs['pickaxe']['stdout']
    book=read('book-review.json');claims=read('claim-review.json')
    assert len(book['checked_passages'])==6 and len(book['checked_runtime_passages'])==2
    assert book['same_volume_direct_objects'] and book['exact_output_absent'] and not (ROOT/book['output']).exists()
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline']==dict(files=64,lines_total=62252,bytes_total=3417722)
    assert claims['book_delta']==dict(files=0,lines_total=8,bytes_total=534)
    card='docs/knowledge/test-subprocess-policy-adapters.md';current=(ROOT/card).read_text()
    questions=lambda text:re.findall(r'^  - ".*"$',text,re.M)
    previous=questions(old(card).decode());now=questions(current)
    assert [q for q in now if q in previous]==previous and len(previous)==121 and len(now)==122
    assert set(now)-set(previous)=={'  - "why does the closed compiler census Git preflight see local Claude settings?"'}
    assert REVISION+':'+card in current and str(BASE.relative_to(ROOT))+'/audit.py --verify-saved' in current
    containment=read('card-line-containment.json')
    assert containment['decoded_evidence_unchanged'] and containment['questions_unchanged'] and containment['ceilings_unchanged']
    assert containment['after_lines']==containment['before_lines']-1
    assert read('staged-gate.first.json')['outputs']['exit']=='1\n'
    manifest=[json.loads(line) for line in (ROOT/'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl').read_bytes().splitlines()]
    assert len(manifest)==2
    h=manifest[1];source=old(h['source_path']);suffix=source[source.rfind(b'## Acceptance Checklist'):]
    assert h['source_revision']==REVISION and h['source_sha256']==hashlib.sha256(source).hexdigest()
    assert h['source_bytes']==len(source) and h['source_lines']==source.count(b'\n')
    assert h['history_bytes']==len(suffix) and h['history_lines']==suffix.count(b'\n')==5
    assert h['history_sha256']==hashlib.sha256(suffix).hexdigest()
    parent=read('execution-context.json')['owner'];owner=parent+'.1'
    task=(ROOT/h['source_path']).read_text();section=lambda ident:task.split('- ID: `'+ident+'`\n')[1].split('- ID: `',1)[0]
    assert 'Status: `done`' in section(owner) and 'Status: `active`' in section(parent)
    assert 'Status: `proposed`' in section(parent+'.2') and 'Status: `proposed`' in section(parent+'.3')
    assert task.count('\n')<=6370
    for name in ['audit-first.json','book-inspection-first.json']:
        first=read(name);raw=bytes.fromhex(first['source']['bytes_hex'])
        assert hashlib.sha256(raw).hexdigest()==first['source']['sha256'] and first['outputs']['exit']=='1\n'
    return dict(owner=owner,next_owner=parent+'.2',source_revision=REVISION,result=result,
        previous_acceptance=h,book=book,claims=pin(BASE/'claim-review.json'),
        original_compiler_invocations=0,local_policy_repair_and_fresh_admission_pending=True,raw_outputs=outputs)


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__);group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    if args.retain:
        outputs={s:{e:(LOG/(s+'.'+e)).read_text() for e in ['stdout','stderr','exit']} for s in STAGES}
        with (BASE/'completion.json').open('x') as stream:json.dump(check(outputs),stream,sort_keys=True,indent=2);stream.write('\n')
    else:
        saved=read('completion.json');assert check(saved['raw_outputs'])==saved
    print('First compiler preflight rejection disposition: OK; local policy repair and fresh admission remain proposed.')
