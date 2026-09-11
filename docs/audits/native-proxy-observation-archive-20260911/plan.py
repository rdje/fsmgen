"""Prospective actual inert archive cases; no fixture allocation here."""
from pathlib import Path
import hashlib
import json
import subprocess

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'dd29e3bffdcdbcf737236e20086acb89bcc31771'


def build():
    cases = []
    def case(name, *, retired=True, wrapper='ordinary', prepare='absent', change=None,
             returned=True, diagnostic=''):
        cases.append(dict(name=name,retired=retired,wrapper=wrapper,prepare=prepare,
                          change=change,returned=returned,diagnostic=diagnostic))
    case('fresh archive before retirement',retired=False)
    case('fresh archive after retirement')
    case('stable archive reuse after retirement',prepare='complete')
    case('binary wrapper after retirement',wrapper='binary')
    case('empty wrapper after retirement',wrapper='empty')
    case('exact wrapper ceiling after retirement',wrapper='maximum')
    case('equal wrapper and reference bytes after retirement',wrapper='equal_reference')
    for prepare in ('empty','partial','unknown','symlink','file'):
        case('existing archive '+prepare,prepare=prepare,returned=False,
             diagnostic='archive has incomplete or unknown members' if prepare in ('empty','partial','unknown')
                        else 'symlink ancestry is forbidden' if prepare=='symlink'
                        else 'expected direct owned private same-volume directory')
    for change,diagnostic in [
        ('changed_bytes','archive bytes differ from retained snapshot'),
        ('changed_mode','invalid image source mode, links or size'),
        ('hardlink','invalid image source mode, links or size'),
        ('missing_file','archive has incomplete or unknown members'),
        ('extra_file','archive has incomplete or unknown members'),
        ('wrong_directory_mode','expected direct owned private same-volume directory'),
    ]:
        case('complete archive '+change,prepare='complete',change=change,returned=False,diagnostic=diagnostic)
    case('foreign evidence identity',change='foreign_evidence_identity',returned=False,
         diagnostic='observation record differs from requested ownership')
    case('wrong evidence permissions',change='wrong_evidence_permissions',returned=False,
         diagnostic='expected direct owned private same-volume directory')
    case('missing argument',change='missing_argument',returned=False,
         diagnostic='expected store, request and original retained acquisition')
    case('extra argument',change='extra_argument',returned=False,
         diagnostic='expected store, request and original retained acquisition')
    previous=json.loads((BASE.parent/'native-proxy-observation-archive-records-20260911/plan.json').read_bytes())
    paths=[r['path'] for r in previous['inputs'] if r['path'].endswith('.pm')]
    paths += ['docs/audits/native-proxy-observation-archive-records-20260911/ArchiveRecord.pm',
              'docs/audits/native-proxy-observation-archive-records-20260911/audit.py',
              'docs/audits/native-proxy-image-custody-20260910/vectors.json',
              'docs/audits/native-proxy-observation-release-contract-20260911/contract.json']
    inputs=[]
    for path in sorted(paths):
        raw=(ROOT/path).read_bytes()
        assert raw==subprocess.check_output(['git','show',REVISION+':'+path],cwd=ROOT)
        inputs.append(dict(path=path,size_bytes=len(raw),sha256=hashlib.sha256(raw).hexdigest()))
    assert len({x['name'] for x in cases})==len(cases)
    return dict(schema='fsmgen.inactive_observation_archive_plan.v1',source_revision=REVISION,
        owner='HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.2.2',
        inputs=inputs,cases=cases,
        limits='Actual isolated files and original qualified inert acquisition/retirement; synthetic birth/cleanup records, no executed fixture, compiler, native capture or release. Preserve own/other holds, images and unrelated workspace. Check bytes/metadata and returned source handles, never treat this as every syscall, asynchronous crash, arbitrary-writer atomicity or native ownership. Interruption/close/limit/applicability join is the next leaf.')


if __name__=='__main__':
    value=build();(BASE/'plan.json').write_text(json.dumps(value,indent=2,sort_keys=True)+'\n')
    print(json.dumps(dict(cases=len(value['cases']),inputs=len(value['inputs']))))
