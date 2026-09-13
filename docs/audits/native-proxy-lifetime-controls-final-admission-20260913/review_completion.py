"""Close documentation and continuity evidence for final source/data admission."""
import argparse
import hashlib
import json
import re
import subprocess
from support_final_corrected import BASE, ROOT, H, pin, read, write

STAGES = ('admission','admission-saved','book','book-inspection','claims-write','claims-check',
          'claims-review','knowledge-generate','knowledge-check','pickaxe')


def raw(row):
    body=bytes.fromhex(row['bytes_hex'])
    assert len(body)==row['size_bytes'] and hashlib.sha256(body).hexdigest()==row['sha256']
    return body


def verify(outputs):
    for name in ('documentation-pins.json','completion-pins.json'):
        for row in read(BASE/name):assert pin(ROOT/row['path'])==row
    values={row['path'].rsplit('/',1)[1]:raw(row) for row in outputs}
    assert len(values)==len(outputs)==len(STAGES)*3
    for stage in STAGES:assert values[stage+'.exit']==b'0\n'
    assert b'knowledge-map: OK' in values['knowledge-check.stdout']+values['knowledge-check.stderr']
    assert re.match(rb'[0-9a-f]{40} ', values['pickaxe.stdout'])
    plan=read(BASE/'plan.json');report=read(BASE/'review.json');integration=read(BASE/'integration-review.json')
    assert report['owner']==plan['owner'] and report['source_revision']==plan['source_revision']
    assert report['selected_cases']==14 and report['actual_fixture_operations']==report['actual_permits_written']==0
    assert report['first_failures_preserved'] and report['execution_requires_committed_admission']
    assert integration['retained_healthy_stages']==152 and len(integration['rejected_countermodels'])==18
    assert len(integration['synthetic_complete_reader']['cases'])==2 and integration['synthetic_control_and_cleanup']
    permit=read(BASE/'permit-review.json');assert len(permit['rejected_states'])==14 and permit['actual_permits_written']==0
    book=read(BASE/'book-review.json');assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert not (ROOT/book['output']).exists()
    claims=read(BASE/'claim-review.json');assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline']==dict(files=64,lines_total=62045,bytes_total=3403913)
    assert claims['book_delta']==dict(files=0,lines_total=26,bytes_total=1540)
    card='docs/knowledge/test-subprocess-policy-adapters.md';revision=plan['source_revision']
    old=subprocess.check_output(['git','show',revision+':'+card],cwd=ROOT).decode();current=(ROOT/card).read_text()
    questions=lambda text:re.findall(r'^  - ".*"$',text,re.M)
    assert questions(old)==questions(current) and len(questions(current))==117 and revision+':'+card in current
    rows=[json.loads(line) for line in (ROOT/'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl').read_bytes().splitlines()]
    assert len(rows)==2;history=rows[1];assert history['source_revision']==revision
    source=subprocess.check_output(['git','show',revision+':'+history['source_path']],cwd=ROOT)
    suffix=source[source.rfind(b'## Acceptance Checklist'):]
    assert hashlib.sha256(source).hexdigest()==history['source_sha256'] and len(source)==history['source_bytes']
    assert source.count(b'\n')==history['source_lines'] and suffix.count(b'\n')==history['history_lines']==5
    assert hashlib.sha256(suffix).hexdigest()==history['history_sha256'] and len(suffix)==history['history_bytes']
    from admit_execution import section
    task=(ROOT/history['source_path']).read_text()
    for owner in plan['completed_owners']:assert 'Status: `done`' in section(task,owner)
    assert 'Status: `proposed`' in section(task,plan['execution_owner'])
    return dict(schema='fsmgen.lifetime_controls_final_admission_completion.v1',owner=plan['owner'],
        source_review=pin(BASE/'review.json'),integration_review=pin(BASE/'integration-review.json'),
        book=book,claims=pin(BASE/'claim-review.json'),previous_acceptance=history,
        unchanged_questions=117,raw_output_count=len(outputs),actual_execution_pending=True,
        actual_permits_written=0,raw_outputs=outputs)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    if args.retain:
        outputs=[]
        for stage in STAGES:
            for suffix in ('stdout','stderr','exit'):
                path=ROOT/'.artifacts/logs'/BASE.name/(stage+'.'+suffix)
                outputs.append(dict(**pin(path),bytes_hex=path.read_bytes().hex()))
        result=verify(outputs);write(BASE/'completion.json',result)
    else:
        saved=read(BASE/'completion.json');assert verify(saved['raw_outputs'])==saved
    print('Final admission completion: OK; commit precedes the separately owned actual execution.')


if __name__=='__main__':main()
