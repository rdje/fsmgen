"""Close actual-control evidence, book synchronization and recoverable continuity."""
import argparse
import hashlib
import json
from pathlib import Path
import re
import subprocess

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
STAGES=('capture','independent','independent-saved','book','book-inspection','claims-write',
        'claims-check','claims-review','knowledge-generate','knowledge-check','pickaxe')


def read(path):return json.loads(path.read_bytes())
def pin(path):
    body=path.read_bytes()
    return dict(path=path.relative_to(ROOT).as_posix(),size_bytes=len(body),sha256=hashlib.sha256(body).hexdigest())
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
    expected=dict(success=True,cases=14,records=351,countermodels=11,native_process_authentication=False)
    for stage in ('independent','independent-saved'):assert json.loads(values[stage+'.stdout'])==expected
    assert b'knowledge-map: OK' in values['knowledge-check.stdout']+values['knowledge-check.stderr']
    assert re.match(rb'[0-9a-f]{40} ',values['pickaxe.stdout'])
    plan=read(BASE/'capture-plan.json');report=read(BASE/'review.json');capture=read(BASE/'capture.json')
    assert report['owner']==plan['owner'] and report['admission_commit']==plan['admission_commit']
    assert report['first_journal_records']==capture['record_count']==351
    assert report['first_journal_bytes']==capture['record_bytes']==43693680
    assert report['primary_handles']==report['file_handles']+report['directory_handles']==26621
    assert report['directory_handles']==report['metadata_observers']==11319
    assert report['separate_recoveries']==0 and len(report['roots_absent'])==56
    assert len(report['after_effect_witnesses'])==3 and len(report['rejected_countermodels'])==11
    assert report['first_results_unchanged'] and not report['original_execution_replayed']
    assert report['runtime_qualification'] is report['native_process_authentication'] is False
    book=read(BASE/'book-review.json');assert book['same_volume_direct_objects'] and book['exact_output_absent']
    assert not (ROOT/book['output']).exists()
    claims=read(BASE/'claim-review.json');assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline']==dict(files=64,lines_total=62071,bytes_total=3405453)
    assert claims['book_delta']==dict(files=0,lines_total=26,bytes_total=1879)
    revision=plan['admission_commit'];card='docs/knowledge/test-subprocess-policy-adapters.md'
    old=subprocess.check_output(['git','show',revision+':'+card],cwd=ROOT).decode();current=(ROOT/card).read_text()
    questions=lambda text:re.findall(r'^  - ".*"$',text,re.M)
    assert questions(old)==questions(current) and len(questions(current))==117 and revision+':'+card in current
    history=[json.loads(line) for line in (ROOT/'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl').read_bytes().splitlines()]
    assert len(history)==2;history=history[1];assert history['source_revision']==revision
    source=subprocess.check_output(['git','show',revision+':'+history['source_path']],cwd=ROOT)
    suffix=source[source.rfind(b'## Acceptance Checklist'):]
    assert hashlib.sha256(source).hexdigest()==history['source_sha256'] and len(source)==history['source_bytes']
    assert source.count(b'\n')==history['source_lines'] and suffix.count(b'\n')==history['history_lines']==5
    assert hashlib.sha256(suffix).hexdigest()==history['history_sha256'] and len(suffix)==history['history_bytes']
    task=(ROOT/history['source_path']).read_text()
    for owner in (plan['owner'],plan['owner'].rsplit('.',1)[0]):
        section=task.split('- ID: `'+owner+'`\n')[1].split('- ID: `',1)[0]
        assert 'Status: `done`' in section
    return dict(schema='fsmgen.inactive_lifetime_controls_completion.v1',owner=plan['owner'],
        admission_commit=revision,qualified_report=pin(BASE/'review.json'),retained_objects=len(capture['records'])+len(capture['first_outputs'])+2,
        book=book,claims=pin(BASE/'claim-review.json'),previous_acceptance=history,unchanged_questions=117,
        raw_output_count=len(outputs),raw_outputs=outputs,combined_closure_pending=True,native_live_integration_pending=True)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    if args.retain:
        outputs=[]
        for stage in STAGES:
            for suffix in ('stdout','stderr','exit'):
                path=ROOT/'.artifacts/logs'/BASE.name/(stage+'.'+suffix)
                outputs.append(dict(**pin(path),bytes_hex=path.read_bytes().hex()))
        result=verify(outputs)
        with (BASE/'completion.json').open('x') as stream:json.dump(result,stream,sort_keys=True,indent=2);stream.write('\n')
    else:
        saved=read(BASE/'completion.json');assert verify(saved['raw_outputs'])==saved
    print('Actual lifetime control completion: OK; first execution retained; combined closure follows.')


if __name__=='__main__':main()
