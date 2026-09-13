"""Check retained source-matrix completion evidence without replaying producers."""
from __future__ import annotations
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
STAGES=('corrected-selection','first-audit','saved-audit','book','book-inspection','claims-write',
        'claims-check','claims-review','knowledge-generate','knowledge-check','pickaxe')


def document(path): return json.loads(path.read_bytes())
def sha(body): return hashlib.sha256(body).hexdigest()
def pin(path):
    body=path.read_bytes(); return dict(path=path.relative_to(ROOT).as_posix(),size_bytes=len(body),sha256=sha(body))
def old(revision,path): return subprocess.check_output(['git','show',revision+':'+path],cwd=ROOT)
def captured(row):
    body=bytes.fromhex(row['bytes_hex']);assert len(body)==row['size_bytes'] and sha(body)==row['sha256'];return body

def absent(relative):
    path=ROOT
    for part in relative.split('/'):
        assert part not in ('','.','..');path/=part
        try: metadata=path.lstat()
        except FileNotFoundError:return True
        assert stat.S_ISDIR(metadata.st_mode) and metadata.st_dev==ROOT.stat().st_dev and metadata.st_uid==os.getuid()
    return False


def verify(outputs):
    for filename in ('matrix-pins.json','documentation-pins.json','completion-pins.json'):
        for row in document(BASE/filename):assert pin(ROOT/row['path'])==row
    plan=document(BASE/'plan.json');report=document(BASE/'review.json');selection=document(BASE/'selection.json')
    assert report['source_inputs']==len(plan['inputs'])==59
    assert report['source_functions']==len(document(BASE/'source-contracts.json'))==14
    assert len(report['cases'])==len(selection['cases'])==14
    assert len(report['call_witnesses'])==3 and len(report['rejected_countermodels'])==10
    assert report['actual_controls_executed']==0 and report['runtime_qualification'] is report['native_process_authentication'] is False
    assert len(report['missing_legs'])==3
    roots=sorted(path for case in selection['cases'] for path in case['roots'].values())
    assert len(roots)==len(set(roots))==56 and all(absent(path) for path in roots)
    assert absent(selection['journal'])
    values={row['path'].rsplit('/',1)[1]:captured(row) for row in outputs}
    assert len(values)==len(outputs)==3*len(STAGES)
    for stage in STAGES:assert values[stage+'.exit']==b'0\n'
    assert b'knowledge-map: OK' in values['knowledge-check.stdout']+values['knowledge-check.stderr']
    assert values['pickaxe.stdout'].startswith(b'da27b5cbaf01af7cbe294c8f851c8273dd750856 ')
    for stage in ('first-audit','saved-audit'):
        assert json.loads(values[stage+'.stdout'])==dict(actual_controls_executed=0,call_witnesses=3,cases=14,
            rejected_countermodels=10,source_functions=14,success=True)
    for row in report['raw_captures']:captured(row)
    failure=document(BASE/'first-selection-failure.json')
    for row in failure['raw_captures']:captured(row)
    assert captured(failure['raw_captures'][-1])==b'1\n'
    assert (BASE/'author_matrix.py').read_bytes()==(BASE/'first-selection.source').read_bytes()
    book=document(BASE/'book-review.json');assert book['exact_output_absent'] and absent(book['output'])
    claims=document(BASE/'claim-review.json')
    assert claims['candidate_identities_and_semantics_unchanged'] and claims['dispositions_unchanged']
    assert claims['book_baseline']==dict(files=64,lines_total=61998,bytes_total=3401240)
    assert claims['book_delta']==dict(files=0,lines_total=24,bytes_total=1416)
    card='docs/knowledge/test-subprocess-policy-adapters.md'
    prior=old(plan['source_revision'],card).decode();current=(ROOT/card).read_text()
    questions=lambda text:re.findall(r'^  - ".*"$',text,re.M)
    assert questions(prior)==questions(current) and len(questions(current))==117
    assert plan['source_revision']+':'+card in current
    history=[json.loads(line) for line in (ROOT/'docs/tasks/history/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE/acceptance-history.jsonl').read_bytes().splitlines()]
    assert len(history)==2;history=history[1];assert history['source_revision']==plan['source_revision']
    body=old(history['source_revision'],history['source_path']);suffix=body[body.rfind(b'## Acceptance Checklist'):]
    assert sha(body)==history['source_sha256'] and len(body)==history['source_bytes'] and body.count(b'\n')==history['source_lines']
    assert sha(suffix)==history['history_sha256'] and len(suffix)==history['history_bytes'] and suffix.count(b'\n')==history['history_lines']==5
    return dict(schema='fsmgen.inactive_lifetime_control_matrix_completion.v1',owner=plan['owner'],
        source_revision=plan['source_revision'],qualified_matrix=pin(BASE/'review.json'),raw_output_count=len(outputs),
        retained_first_author_failure=True,book=book,claims=pin(BASE/'claim-review.json'),unchanged_questions=117,
        prior_acceptance=history,prospective_roots_absent=roots,actual_interruption_qualification=False)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    if args.retain:
        outputs=[]
        for stage in STAGES:
            for suffix in ('stdout','stderr','exit'):
                path=LOG/(stage+'.'+suffix);outputs.append(dict(**pin(path),bytes_hex=path.read_bytes().hex()))
        value=verify(outputs);value['raw_outputs']=outputs
        with (BASE/'completion.json').open('xb') as stream:stream.write(json.dumps(value,sort_keys=True,indent=2).encode()+b'\n')
    else:
        saved=document(BASE/'completion.json');value=verify(saved['raw_outputs'])
        assert {k:v for k,v in saved.items() if k!='raw_outputs'}==value
    print('control matrix completion: OK; source/data only; actual interruptions unqualified')


if __name__=='__main__':main()
