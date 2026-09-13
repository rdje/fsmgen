"""Join the installed-toolchain epoch, historical inventory and current continuity."""
import argparse
import json
import re
import subprocess

from epoch import BASE, ROOT, PLAN, digest, save
LOG = ROOT / '.artifacts/logs' / BASE.name

STAGES = ['epoch', 'epoch-saved', 'book', 'book-inspection', 'claims-write',
          'claims-check', 'claims-review', 'knowledge-generate', 'knowledge-check',
          'knowledge-query', 'pickaxe', 'inventory-saved']


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
    report = read(BASE/'epoch-review.json')
    expected = dict(compiler_bytes_changed=True,default_sdk_changed=True,
        old_sdk_directory_identity_changed=True,rejected_controls=8,
        current_revalidation_required_before_execution=True,new_compiler_or_fixture_invocation=False)
    for stage in ['epoch','epoch-saved']:
        assert json.loads(raw[stage+'.stdout']) == expected
    assert b'knowledge-map: OK' in raw['knowledge-check.stdout'] + raw['knowledge-check.stderr']
    assert b'test-subprocess-policy-adapters\tdocs/knowledge/test-subprocess-policy-adapters.md' in raw['knowledge-query.stdout']
    assert raw['pickaxe.stdout'].strip()
    prior=json.loads(raw['inventory-saved.stdout'])
    assert prior['profiles']==7 and prior['complete_workspace_profiles']==0 and prior['new_execution'] is False
    for p in read(BASE/'epoch-pins.json'):
        assert pin(ROOT/p['path']) == p
    assert len(report['rejected_controls'])==8
    assert report['current_revalidation_required_before_execution']
    assert report['result']['compiler_bytes_changed'] and report['result']['default_sdk_changed']
    assert report['result']['new_compiler_or_fixture_invocation'] is False
    book = read(BASE/'book-review.json')
    assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert len(book['checked_passages'])==6 and len(book['checked_runtime_passages'])==2
    assert not (ROOT/book['output']).exists()
    claims = read(BASE/'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline']==dict(files=64,lines_total=62225,bytes_total=3415841)
    assert claims['book_delta']==dict(files=0,lines_total=13,bytes_total=883)
    card = 'docs/knowledge/test-subprocess-policy-adapters.md'
    current = (ROOT/card).read_text()
    questions = lambda text: re.findall(r'^  - ".*"$',text,re.M)
    assert questions(current)==questions(git_bytes(card).decode()) and len(questions(current))==121
    assert PLAN['source_revision']+':'+card in current
    assert str(BASE.relative_to(ROOT))+'/epoch.py --verify-saved' in current
    history = [json.loads(line) for line in (ROOT/'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl').read_bytes().splitlines()]
    assert len(history)==2
    h=history[1]; source=git_bytes(h['source_path']); suffix=source[source.rfind(b'## Acceptance Checklist'):]
    assert h['source_revision']==PLAN['source_revision'] and h['source_sha256']==digest(source)
    assert h['source_bytes']==len(source) and h['source_lines']==source.count(b'\n')
    assert h['history_bytes']==len(suffix) and h['history_lines']==suffix.count(b'\n')==5 and h['history_sha256']==digest(suffix)
    task=(ROOT/h['source_path']).read_text()
    section=lambda owner:task.split('- ID: `'+owner+'`\n')[1].split('- ID: `',1)[0]
    owner=PLAN['owner']; parent=owner.rsplit('.',1)[0]; next_owner=parent
    assert 'Status: `done`' in section(owner) and 'Status: `active`' in section(parent)
    assert 'Status: `active`' in section(next_owner)
    assert 'Status: `proposed`' in section(parent.rsplit('.',1)[0]+'.3')
    assert task.count('\n')<=6370
    return dict(owner=owner,next_owner=next_owner,source_revision=PLAN['source_revision'],
        qualified_installed_epoch=True,preserved_questions=121,book=book,
        claims=pin(BASE/'claim-review.json'),report=pin(BASE/'epoch-review.json'),
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
    print('Compiler/SDK epoch completion: OK; current-epoch census admission remains active.')


if __name__=='__main__':
    main()
