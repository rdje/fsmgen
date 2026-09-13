"""Verify the source/data slice's completed evidence and documentation boundary."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
LOG=ROOT/'.artifacts/logs'/BASE.name
STAGES=('harness-review','harness-saved','book','book-inspection','claims-write','claims-check',
        'claims-review','knowledge-generate','knowledge-check','pickaxe')


def document(path):return json.loads(path.read_bytes())
def sha(body):return hashlib.sha256(body).hexdigest()
def pin(path):
    body=path.read_bytes();return dict(path=path.relative_to(ROOT).as_posix(),size_bytes=len(body),sha256=sha(body))
def raw(row):
    body=bytes.fromhex(row['bytes_hex']);assert len(body)==row['size_bytes'] and sha(body)==row['sha256'];return body

def absent(relative):
    path=ROOT
    for part in relative.split('/'):
        assert part not in ('','.','..');path/=part
        try:metadata=path.lstat()
        except FileNotFoundError:return True
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev==ROOT.stat().st_dev and metadata.st_uid==os.getuid()
    return False


def verify(outputs):
    for filename in ('harness-pins.json','documentation-pins.json','completion-pins.json'):
        for row in document(BASE/filename):assert pin(ROOT/row['path'])==row
    plan=document(BASE/'harness-plan.json');report=document(BASE/'harness-review.json');data=document(BASE/'data-review.json')
    assert report['owner']==plan['owner'] and report['source_inputs']==len(plan['inputs'])==89
    assert report['selected_cases']==len(data['cases'])==14 and report['reader_countermodels']==len(data['rejected_countermodels'])==41
    assert report['corrected_perl_checks']==data['corrected_perl_checks']==96
    assert report['healthy_resource_traces']==len(data['retained_healthy_resource_traces'])==2
    assert report['actual_fixture_operations']==0 and report['runtime_qualification'] is report['native_process_authentication'] is False
    assert data['full_actual_journal_not_executed'] is True
    for row in report['raw_captures']:raw(row)
    change=document(BASE/'source-finalization.json')
    for key in ('before_source','after_source','before_manifest','execution_harness_unchanged'):
        assert pin(ROOT/change[key]['path'])==change[key]
    before=(ROOT/change['before_source']['path']).read_bytes();after=(ROOT/change['after_source']['path']).read_bytes()
    removed=bytes.fromhex(change['removed_line_hex']);assert before.count(removed)==1 and before.replace(removed,b'')==after
    oldpins=document(ROOT/change['before_manifest']['path']);current=document(BASE/'harness-pins.json')
    assert len(current)==len(oldpins)+3
    for a,b in zip(oldpins,current):
        if a==b:continue
        assert a['path']==b['path']==str((BASE/'audit.py').relative_to(ROOT))
        assert a['sha256']==sha(before) and a['size_bytes']==len(before)
        assert b['sha256']==sha(after) and b['size_bytes']==len(after)
    assert {row['path'] for row in current[len(oldpins):]}=={str((BASE/name).relative_to(ROOT)) for name in (
        'first-review-audit.py.source','first-review-harness-pins.json.source','source-finalization.json')}
    roots=report['prospective_roots_absent'];assert len(roots)==len(set(roots))==56 and all(absent(path) for path in roots)
    values={row['path'].rsplit('/',1)[1]:raw(row) for row in outputs};assert len(values)==len(outputs)==3*len(STAGES)
    for stage in STAGES:assert values[stage+'.exit']==b'0\n'
    for stage in ('harness-review','harness-saved'):
        assert json.loads(values[stage+'.stdout'])==dict(actual_fixture_operations=0,cases=14,perl_checks=96,reader_countermodels=41,success=True)
    assert b'knowledge-map: OK' in values['knowledge-check.stdout']+values['knowledge-check.stderr']
    assert values['pickaxe.stdout'].startswith(b'33b1c0b4cb41227034f3a8b369c9cacefdc27c32 ')
    book=document(BASE/'book-review.json');assert book['exact_output_absent'] and absent(book['output'])
    claims=document(BASE/'claim-review.json');assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline']==dict(files=64,lines_total=62022,bytes_total=3402656)
    assert claims['book_delta']==dict(files=0,lines_total=23,bytes_total=1257)
    revision=plan['source_revision'];card='docs/knowledge/test-subprocess-policy-adapters.md'
    prior=subprocess.check_output(['git','show',revision+':'+card],cwd=ROOT).decode();current=(ROOT/card).read_text()
    questions=lambda text:re.findall(r'^  - ".*"$',text,re.M)
    assert questions(prior)==questions(current) and len(questions(current))==117 and revision+':'+card in current
    history=[json.loads(line) for line in (ROOT/'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl').read_bytes().splitlines()]
    assert len(history)==2;history=history[1];assert history['source_revision']==revision
    body=subprocess.check_output(['git','show',revision+':'+history['source_path']],cwd=ROOT);suffix=body[body.rfind(b'## Acceptance Checklist'):]
    assert sha(body)==history['source_sha256'] and len(body)==history['source_bytes'] and body.count(b'\n')==history['source_lines']
    assert sha(suffix)==history['history_sha256'] and len(suffix)==history['history_bytes'] and suffix.count(b'\n')==history['history_lines']==5
    return dict(schema='fsmgen.inactive_lifetime_control_harness_completion.v1',owner=plan['owner'],source_revision=revision,
        qualified_report=pin(BASE/'harness-review.json'),raw_output_count=len(outputs),book=book,claims=pin(BASE/'claim-review.json'),
        prior_acceptance=history,unchanged_questions=117,prospective_roots_absent=roots,first_inert_failure_retained=True,
        final_admission_pending=True,actual_interruption_qualification=False)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    if args.retain:
        outputs=[]
        for stage in STAGES:
            for suffix in ('stdout','stderr','exit'):
                path=LOG/(stage+'.'+suffix);outputs.append(dict(**pin(path),bytes_hex=path.read_bytes().hex()))
        result=verify(outputs);result['raw_outputs']=outputs
        with (BASE/'completion.json').open('xb') as stream:stream.write(json.dumps(result,sort_keys=True,indent=2).encode()+b'\n')
    else:
        saved=document(BASE/'completion.json');result=verify(saved['raw_outputs']);assert {k:v for k,v in saved.items() if k!='raw_outputs'}==result
    print('control harness completion: OK; source/data qualified; final admission and actual controls pending')


if __name__=='__main__':main()
