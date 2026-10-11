"""Reexecute the whole old display reader in its exact dated instrument context."""
import argparse
import hashlib
import json
import os
import shutil
import stat
import subprocess
import sys
from pathlib import Path
from common import BASE, REVISION, canonical, load, need, pin, save
from intake import git

ROOT=Path('.artifacts/raw-stack-prerequisites-20261011/display-checkpoint')
DISPLAY=Path('docs/audits/observer-display-contract-20261010')
ORIGINAL='a9fa6d6955797577c6be8fd54c1c6a507e48a526'
INSTRUMENT='scripts/check_record_value_publication.py'
SUCCESS='PASS complete fresh dated display-reader execution and whole fixed source/instrument conservation; maintained current/native verification remains separate.\n'


def preflight():
    root=Path.cwd().resolve();full=root/ROOT
    need(not ROOT.is_absolute() and not {'..','.git'}.intersection(ROOT.parts) and full.resolve()==full,
         'plain own dated checkpoint path before any write')
    for parent in (full,*full.parents):
        if parent==root:break
        need(not (parent/'.git').exists(),'own dated checkpoint repository boundary before any write')
    nearest=full
    while not nearest.exists():nearest=nearest.parent
    need(nearest.is_dir() and nearest.stat().st_dev==root.stat().st_dev,
         'ordinary same-volume dated checkpoint parent before any write')


def identity(path):
    digest=hashlib.sha256();size=0
    with path.open('rb') as stream:
        while chunk:=stream.read(1048576):digest.update(chunk);size+=len(chunk)
    return dict(bytes=size,sha256=digest.hexdigest())


def expected():
    fixed=load('intake-qualified.json')['members']
    prerequisite=json.loads((DISPLAY/'prerequisites.json').read_bytes())
    checks=json.loads((DISPLAY/'checks.json').read_bytes())
    roots=set(prerequisite['custody']['roots'])|{str(DISPLAY)}
    roots.update(path for record in checks.values() for path in record['instruments'])
    members={path:dict(bytes=row['bytes'],sha256=row['sha256'],executable=row['mode']=='100755')
             for path,row in fixed.items() if any(path==root or path.startswith(root+'/') for root in roots)}
    need(all(any(path==root or path.startswith(root+'/') for path in members) for root in roots),
         'complete dated display prerequisite/direct instrument roots')
    original=git('show',ORIGINAL+':'+INSTRUMENT)
    need(pin(original)==checks['current-publication']['instruments'][INSTRUMENT],
         'exact old display publication instrument from immutable Git and original actual receipt')
    need(members[INSTRUMENT]['sha256']!=pin(original)['sha256'],
         'genuine legitimate old and current publication programme epochs differ')
    members[INSTRUMENT]=dict(**pin(original),executable=members[INSTRUMENT]['executable'])
    return members,original


def census(expected_members):
    result={};root=Path.cwd().resolve();directories=set()
    for path in sorted(ROOT.rglob('*')):
        mode=path.lstat().st_mode
        need(path.resolve()==root/path and path.stat().st_dev==root.stat().st_dev
             and not (path/'.git').exists(),'own same-volume dated display checkpoint graph')
        if stat.S_ISDIR(mode):directories.add(str(path.relative_to(ROOT)));continue
        need(stat.S_ISREG(mode),'ordinary complete dated display checkpoint member')
        result[str(path.relative_to(ROOT))]=dict(**identity(path),executable=bool(mode&0o111))
    wanted={str(parent) for name in expected_members for parent in Path(name).parents if str(parent)!='.'}
    need(directories==wanted,'whole dated display checkpoint directory graph')
    return result


def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('--replay',action='store_true');args=parser.parse_args()
    members,original=expected()
    preflight()
    fresh=not ROOT.exists()
    need(args.replay or fresh,'retain complete first dated display checkpoint')
    ROOT.mkdir(parents=True,exist_ok=args.replay)
    for name,record in members.items():
        target=ROOT/name
        if target.exists():continue
        need(fresh,'replay does not repair missing checkpoint evidence')
        target.parent.mkdir(parents=True,exist_ok=True)
        if name==INSTRUMENT:target.write_bytes(original)
        else:shutil.copyfile(name,target)
        target.chmod(0o755 if record['executable'] else 0o644)
    before=census(members);need(before==members,'whole copied fixed source/native/direct instrument byte epoch')
    command=['python3','-B',str(DISPLAY/'verify.py')]
    actual=subprocess.run(command,cwd=ROOT,capture_output=True,text=True)
    after=census(members)
    record=dict(command=command,cwd=str(ROOT),status=actual.returncode,stdout=actual.stdout,stderr=actual.stderr,
                fixed_revision=REVISION,original_instrument_revision=ORIGINAL,members=members,
                before=before,after=after,meaning='Complete freshly executed historical display reader under its original direct instrument context. No live file is replaced, original execution recaptured or current programme relabeled historical.')
    if not args.replay:
        number=len(list(BASE.glob('display-checkpoint-actual-*.json')))+1
        save('display-checkpoint-actual-'+str(number)+'.json',record)
    print(actual.stdout,end='');print(actual.stderr,end='',file=sys.stderr)
    need(type(actual.returncode) is int and actual.returncode==0 and actual.stderr==''
         and actual.stdout=='PASS entire finite public source/display/body/loss/lifetime contracts, genuine controls, all first failures and whole fixed/current source custody; original observer/settings identity remains unmeasured.\n',
         'actual complete dated display reader success')
    need(before==after,'dated display reader conserves every whole input and creates no artifact')
    if (BASE/'display-checkpoint.json').exists():need(load('display-checkpoint.json')==record,'whole fixed dated display actual result')
    else:
        need(not args.replay,'dated replay requires its committed original result')
        save('display-checkpoint.json',record)
    print(SUCCESS,end='')


if __name__=='__main__':main()
