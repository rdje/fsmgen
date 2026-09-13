"""Join the retained profile inventory, current wrapper qualification and continuity."""
import argparse
import json
import re
import subprocess

from audit import BASE, ROOT, PLAN, digest, save
LOG = ROOT / '.artifacts/logs' / BASE.name

STAGES = ['audit', 'audit-saved', 'book', 'book-inspection', 'claims-write',
          'claims-check', 'claims-review', 'knowledge-generate', 'knowledge-check',
          'knowledge-query', 'pickaxe', 'wrapper-saved']


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
    expected = dict(profiles=7,complete_workspace_profiles=0,hypothetical_missing_profile_witnesses=5,
                    rejected_controls=9,fresh_compiler_admission_required=True,new_execution=False)
    for stage in ['audit','audit-saved']:
        assert json.loads(raw[stage+'.stdout']) == expected
    assert b'knowledge-map: OK' in raw['knowledge-check.stdout'] + raw['knowledge-check.stderr']
    assert b'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in raw['knowledge-query.stdout']
    assert raw['pickaxe.stdout'].startswith(b'e0d74bb051465ba641227acc11975e25e5d879a7 ')
    wrapper = json.loads(raw['wrapper-saved.stdout'])
    assert wrapper['baseline_retirement_rejected_unchanged'] and wrapper['repaired_retirement_removed_nodes']==10
    assert wrapper['native_or_live_execution'] is wrapper['actual_compiler_capacity_qualified'] is False
    for p in read(BASE/'audit-pins.json'):
        assert pin(ROOT/p['path']) == p
    assert report['input_files']==67 and report['input_bytes']==644103
    assert len(report['result']['profiles'])==7 and len(report['rejected_controls'])==9
    assert report['result']['fresh_compiler_admission_required']
    assert not report['result']['authentic_complete_workspace_profile_found']
    book = read(BASE/'book-review.json')
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages'])==6 and len(book['checked_runtime_passages'])==2
    assert not (ROOT/book['output']).exists()
    claims = read(BASE/'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline']==dict(files=64,lines_total=62210,bytes_total=3414867)
    assert claims['book_delta']==dict(files=0,lines_total=15,bytes_total=974)
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
        retained_profiles=7,preserved_questions=121,book=book,
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
    print('Compiler-profile inventory completion: OK; prospective compiler-only census admission is next.')


if __name__=='__main__':
    main()
