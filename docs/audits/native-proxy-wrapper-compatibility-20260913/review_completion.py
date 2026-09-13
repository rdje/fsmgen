"""Join original allocations, focused checks and bounded slice continuity."""
import argparse
import json
import re
import subprocess

from files import BASE, ROOT, PLAN, LOG, digest, save

STAGES = ['audit', 'audit-saved', 'book', 'book-inspection', 'claims-write',
          'claims-check', 'claims-review', 'knowledge-generate', 'knowledge-check',
          'knowledge-query', 'pickaxe']


def read(path):
    return json.loads(path.read_bytes())


def pin(path):
    body = path.read_bytes()
    return dict(path=str(path.relative_to(ROOT)), size_bytes=len(body), sha256=digest(body))


def git_bytes(path):
    return subprocess.check_output(['git', 'show', PLAN['source_revision'] + ':' + path], cwd=ROOT)


def verify(outputs):
    for p in read(BASE / 'completion-pins.json'):
        assert pin(ROOT / p['path']) == p
    raw = {}
    for name, record in outputs.items():
        body = bytes.fromhex(record['bytes_hex'])
        assert len(body) == record['size_bytes'] and digest(body) == record['sha256']
        raw[name] = body
    assert set(raw) == {stage + '.' + suffix for stage in STAGES for suffix in ['stdout','stderr','exit']}
    for stage in STAGES:
        assert raw[stage + '.exit'] == b'0\n'
    report = read(BASE/'review.json')
    for stage in ['audit','audit-saved']:
        assert json.loads(raw[stage+'.stdout']) == report['result']
    assert b'knowledge-map: OK' in raw['knowledge-check.stdout'] + raw['knowledge-check.stderr']
    assert b'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in raw['knowledge-query.stdout']
    assert raw['pickaxe.stdout'].startswith(b'4bc8f5ebc48173a26fbec6a30a248b86df7eda71 ')
    original = read(BASE/'first-run.json')
    decode = lambda name: bytes.fromhex(original[name]['bytes_hex'])
    prepared = json.loads(decode('prepared.json'))
    allocations = [json.loads(line) for line in decode('allocation.jsonl').splitlines()]
    assert len(allocations) == len(prepared['nodes'])*2
    created = set()
    alias_case = next(c for c in PLAN['cases'] if c['hardlink'])
    for intent, receipt in zip(allocations[::2], allocations[1::2]):
        assert intent['event']=='intent' and receipt['event']=='created'
        p = intent['path']
        assert p == receipt['path'] and p not in created
        created.add(p)
        expected = dict(prepared['nodes'][p])
        if p == alias_case['path']:
            expected['links'] = 1
        assert receipt['node'] == expected and intent['mode'] == expected['mode']
        if intent['link']:
            assert p == alias_case['root']+'/alias' and intent['link'] == alias_case['path']
            assert intent['link'] in created
        elif expected['kind'] == 'file':
            assert intent['size_bytes'] == expected['size_bytes'] and intent['sha256'] == expected['sha256']
        else:
            assert intent['size_bytes'] is intent['sha256'] is None
    assert created == set(prepared['nodes'])
    book = read(BASE/'book-review.json')
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages'])==6 and len(book['checked_runtime_passages'])==2
    assert not (ROOT/book['output']).exists()
    claims = read(BASE/'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline']==dict(files=64,lines_total=62200,bytes_total=3414215)
    assert claims['book_delta']==dict(files=0,lines_total=10,bytes_total=652)
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    current = (ROOT/card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$',text,re.M)
    assert questions(current)==questions(git_bytes(card).decode()) and len(questions(current))==121
    assert PLAN['source_revision']+':'+card in current
    assert str(BASE.relative_to(ROOT))+'/audit.py --verify-saved' in current
    history = [json.loads(line) for line in (ROOT/'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl').read_bytes().splitlines()]
    assert len(history)==2
    h=history[1]; source=git_bytes(h['source_path']); suffix=source[source.rfind(b'## Acceptance Checklist'):]
    assert h['source_revision']==PLAN['source_revision'] and h['source_sha256']==digest(source)
    assert h['source_bytes']==len(source) and h['source_lines']==source.count(b'\n')
    assert h['history_bytes']==len(suffix) and h['history_lines']==suffix.count(b'\n')==5 and h['history_sha256']==digest(suffix)
    task=(ROOT/h['source_path']).read_text()
    section=lambda owner:task.split('- ID: `'+owner+'`\n')[1].split('- ID: `',1)[0]
    owner=PLAN['owner']; parent=owner.rsplit('.',1)[0]; next_owner=parent+'.2'
    assert 'Status: `done`' in section(owner) and 'Status: `active`' in section(parent)
    assert 'Status: `proposed`' in section(next_owner) and 'Status: `proposed`' in section(parent+'.3')
    assert task.count('\n')<=6370
    return dict(owner=owner,next_owner=next_owner,source_revision=PLAN['source_revision'],
        original_allocations_joined=len(created),preserved_questions=121,book=book,
        claims=pin(BASE/'claim-review.json'),report=pin(BASE/'review.json'),
        previous_acceptance=h,raw_outputs=outputs,
        narrow_wrapper_repair_qualified=True,authentic_compiler_profile_pending=True,
        native_live_integration_pending=True)


def main():
    parser=argparse.ArgumentParser()
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true')
    group.add_argument('--verify-saved',action='store_true')
    args=parser.parse_args()
    if args.retain:
        outputs={}
        for stage in STAGES:
            for suffix in ['stdout','stderr','exit']:
                name=stage+'.'+suffix; path=LOG/name
                outputs[name]=dict(**pin(path),bytes_hex=path.read_bytes().hex())
        save(BASE/'completion.json',verify(outputs))
    else:
        saved=read(BASE/'completion.json')
        assert verify(saved['raw_outputs'])==saved
    print('Wrapper compatibility completion: OK; authentic compiler profiles remain pending.')


if __name__=='__main__':
    main()
