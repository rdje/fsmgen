"""Verify the exact staged-gate metadata correction and its retained first epoch."""
from __future__ import annotations
import argparse
import hashlib
import json
from pathlib import Path
import re
import review_completion as completion

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
LOG=ROOT/'.artifacts/logs'/BASE.name


def document(path):return json.loads(path.read_bytes())
def sha(body):return hashlib.sha256(body).hexdigest()
def pin(path):
    body=path.read_bytes();return dict(path=path.relative_to(ROOT).as_posix(),size_bytes=len(body),sha256=sha(body))


def verify():
    evidence=document(BASE/'first-staged-gate.json')
    for row in evidence['raw_captures']:
        body=bytes.fromhex(row['bytes_hex']);assert sha(body)==row['sha256'] and len(body)==row['size_bytes']
    assert bytes.fromhex(evidence['raw_captures'][-1]['bytes_hex'])==b'1\n'
    replacements={}
    for key in ('surface','inventory'):
        row=evidence[key];current=(ROOT/row['path']).read_bytes();lines=current.splitlines(keepends=True)
        before=bytes.fromhex(row['before_line_hex']);after=lines[row['line']]
        if key=='inventory':assert before==after
        else:
            assert after==bytes.fromhex(row['after_line_hex'])
            a,b=json.loads(before),json.loads(after)
            previous=a['reference_contract']['aggregate_change']['authority_id']
            a['reference_contract']['aggregate_change']['authority_id']=previous.upper()
            assert a==b and re.fullmatch(r'[A-Z][A-Z0-9_.-]{0,127}',previous.upper())
        lines[row['line']]=before;original=b''.join(lines);assert sha(original)==row['before_sha256']
        replacements[row['path']]=original
    for old_manifest in evidence['original_manifests']:
        body=(ROOT/old_manifest['retained_path']).read_bytes()
        assert sha(body)==old_manifest['sha256'] and len(body)==old_manifest['size_bytes']
        prior=json.loads(body);current=document(ROOT/old_manifest['path']);assert len(prior)==len(current)
        for old,new in zip(prior,current):
            assert old['path']==new['path'] and new==pin(ROOT/new['path'])
            if old==new:continue
            assert old['path'] in replacements
            oldbody=replacements[old['path']]
            assert old['sha256']==sha(oldbody) and old['size_bytes']==len(oldbody)
        replacements[old_manifest['path']]=body
    saved=document(BASE/'completion.json')
    # Re-read the current pins and all unchanged source/doc evidence; the
    # completion result's fields remain exactly equal after this metadata fix.
    assert completion.verify(saved['raw_outputs'])=={k:v for k,v in saved.items() if k!='raw_outputs'}
    outputs=[]
    for suffix in ('stdout','stderr','exit'):
        path=LOG/('corrected-claims-write.'+suffix);outputs.append(dict(**pin(path),bytes_hex=path.read_bytes().hex()))
    assert bytes.fromhex(outputs[-1]['bytes_hex'])==b'0\n'
    return dict(schema='fsmgen.control_matrix_metadata_correction.v1',owner=evidence['owner'],
        first_staged_rejection_retained=True,authority_identifier_only_changed=True,inventory_unchanged=True,
        completion_result_unchanged=True,current_manifests=[pin(ROOT/r['path']) for r in evidence['original_manifests']],
        first_gate=pin(BASE/'first-staged-gate.json'),verifier=pin(Path(__file__).resolve()),raw_captures=outputs)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    result=verify()
    if args.retain:
        with (BASE/'metadata-correction.json').open('xb') as stream:stream.write(json.dumps(result,sort_keys=True,indent=2).encode()+b'\n')
    else:assert document(BASE/'metadata-correction.json')==result
    print('control matrix metadata: OK; exact first epoch retained; current completion still holds')


if __name__=='__main__':main()
