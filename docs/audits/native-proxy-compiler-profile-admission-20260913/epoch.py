"""Read-only installed-toolchain epoch capture and independently checked disposition."""
import argparse
import copy
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import plistlib
import stat
import subprocess

BASE=Path(__file__).resolve().parent
ROOT=BASE.parents[2]
PLAN=json.loads((BASE/'epoch-plan.json').read_bytes())


def digest(raw):
    return hashlib.sha256(raw).hexdigest()


def save(path,value):
    with path.open('x') as stream:
        json.dump(value,stream,sort_keys=True,indent=2)
        stream.write('\n')


def identity(s):
    return dict(device=s.st_dev,inode=s.st_ino,mode=stat.S_IMODE(s.st_mode),uid=s.st_uid,
                size_bytes=s.st_size,mtime_ns=s.st_mtime_ns,ctime_ns=s.st_ctime_ns)


def external_pin(name):
    path=Path(name)
    assert path.is_absolute() and not path.is_relative_to(ROOT)
    assert path.resolve(strict=True)==path
    before=path.lstat()
    assert stat.S_ISREG(before.st_mode) and before.st_uid==0
    assert before.st_size<=PLAN['limits']['file_bytes']
    fd=os.open(path,os.O_RDONLY|os.O_NOFOLLOW|os.O_NONBLOCK)
    hasher=hashlib.sha256();count=0;small=[]
    try:
        assert identity(os.fstat(fd))==identity(before)
        while True:
            raw=os.read(fd,PLAN['limits']['read_chunk_bytes'])
            if not raw:break
            count+=len(raw)
            assert count<=PLAN['limits']['file_bytes']
            hasher.update(raw)
            if before.st_size<=65536:small.append(raw)
        assert identity(os.fstat(fd))==identity(before)==identity(path.lstat())
        assert count==before.st_size
    finally:
        os.close(fd)
    row=dict(path=name,identity=identity(before),sha256=hasher.hexdigest(),access='read_only')
    if small:row['bytes_hex']=b''.join(small).hex()
    return row


def sdk_entry(name):
    path=Path(name);before=path.lstat()
    assert before.st_uid==0
    target=str(path.readlink()) if stat.S_ISLNK(before.st_mode) else None
    assert target is not None or stat.S_ISDIR(before.st_mode)
    resolved=path.resolve(strict=True)
    current=resolved.lstat()
    assert stat.S_ISDIR(current.st_mode) and current.st_uid==0
    assert identity(path.lstat())==identity(before)
    return dict(path=name,identity=identity(before),target=target,resolved=str(resolved),
                resolved_identity=identity(current),access='read_only')


def source_inputs():
    values={}
    for pin in PLAN['inputs']:
        raw=subprocess.check_output(['git','show',PLAN['source_revision']+':'+pin['path']],cwd=ROOT)
        assert len(raw)==pin['size_bytes'] and digest(raw)==pin['sha256']
        assert (ROOT/pin['path']).read_bytes()==raw
        values[pin['path']]=raw
    return values


def verify(observed,values):
    assert observed['schema']=='fsmgen.compiler_profile_toolchain_epoch.v1'
    assert observed['new_compiler_or_fixture_invocation'] is False
    assert observed['project_device']>0 and observed['host']['sysname']=='Darwin' and observed['host']['machine']=='arm64'
    assert [r['path'] for r in observed['files']]==PLAN['external_read_only_files']
    assert [r['path'] for r in observed['sdk_entries']]==PLAN['sdk_entries']
    files={r['path']:r for r in observed['files']}
    for row in observed['files']:
        assert row['access']=='read_only' and row['identity']['uid']==0
        assert row['identity']['device']!=observed['project_device']
        assert row['identity']['size_bytes']<=PLAN['limits']['file_bytes']
        assert len(row['sha256'])==64
        if 'bytes_hex' in row:
            raw=bytes.fromhex(row['bytes_hex'])
            assert len(raw)==row['identity']['size_bytes'] and digest(raw)==row['sha256']
    assert sum(r['identity']['size_bytes'] for r in observed['files'])<=PLAN['limits']['total_bytes']
    old_a=json.loads(values['docs/audits/native-proxy-hardlink-20260910/admission.json'])['selection_context']
    old_b=json.loads(values['docs/audits/native-proxy-daemon-original-20260910/admission.json'])['host_selection_inputs']
    assert old_a==old_b
    old_compiler=old_a['compiler'];old_sdk=old_a['sdk']
    clang=files['/Library/Developer/CommandLineTools/usr/bin/clang']
    assert clang['path']==old_compiler['path']
    assert clang['identity']['size_bytes']!=old_compiler['bytes'] and clang['sha256']!=old_compiler['sha256']
    current_entry,old_entry,new_entry=observed['sdk_entries']
    assert current_entry['target']=='MacOSX27.0.sdk'
    assert current_entry['resolved']==new_entry['path']==new_entry['resolved']
    assert current_entry['resolved_identity']==new_entry['resolved_identity']
    assert old_entry['path']==old_sdk['path']==old_entry['resolved']
    assert old_entry['target'] is new_entry['target'] is None
    assert old_entry['identity']['inode']!=old_sdk['inode']
    assert current_entry['resolved']!=old_sdk['path']
    versions={}
    for entry in [old_entry,new_entry]:
        settings=files[entry['resolved']+'/SDKSettings.json']
        value=json.loads(bytes.fromhex(settings['bytes_hex']))
        versions[entry['resolved']]=dict(version=value['Version'],canonical_name=value['CanonicalName'],
                                       display_name=value['DisplayName'],settings_sha256=settings['sha256'])
    assert versions[old_entry['path']]['version']=='26.5'
    assert versions[new_entry['path']]['version']=='27.0'
    system=files['/System/Library/CoreServices/SystemVersion.plist']
    system_value=plistlib.loads(bytes.fromhex(system['bytes_hex']))
    producer=values['t/lib/FSM/Test/RustProxyFixture.pm'].decode()
    assert "abs_path('/Library/Developer/CommandLineTools/usr/bin/clang')" in producer
    assert "abs_path('/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk')" in producer
    assert "'-mmacosx-version-min=11.0'" in producer
    prior_inventory=json.loads(values['docs/audits/native-proxy-compiler-profile-inventory-20260913/review.json'])
    assert prior_inventory['result']['fresh_compiler_admission_required']
    return dict(original_context=old_a,current_compiler=clang,current_sdk=current_entry,
        retained_sdk_label=old_entry,sdk_versions=versions,
        current_os={k:system_value[k] for k in ['ProductName','ProductVersion','ProductBuildVersion']},
        compiler_bytes_changed=True,default_sdk_changed=True,old_sdk_directory_identity_changed=True,
        old_version_label_proves_old_sdk_bytes=False,
        historical_startup_or_image_change_cause='not_established',
        selected_policy='Use the current fixed builder selection only after a fresh committed compiler-only admission and exact epoch revalidation. No rollback or earlier-image byte expectation.',
        dependency_limits='SDK header closure, compiler libraries and OS loaded-image state are not exhaustively attested; these identity/version pins are not historical environment equivalence.',
        new_compiler_or_fixture_invocation=False)


def controls(observed,values,result):
    rejected=[]
    original=result['original_context']
    for name,mutate in [
        ('old_compiler_bytes',lambda v:v['files'][0].update(sha256=original['compiler']['sha256'])),
        ('old_sdk_selection',lambda v:v['sdk_entries'][0].update(resolved=original['sdk']['path'])),
        ('old_sdk_identity',lambda v:v['sdk_entries'][1]['identity'].update(inode=original['sdk']['inode'])),
        ('modified_sdk_version_bytes',lambda v:v['files'][1].update(bytes_hex='7b7d')),
        ('off_volume_write',lambda v:v['files'][0].update(access='write')),
        ('compiler_invocation_promoted',lambda v:v.update(new_compiler_or_fixture_invocation=True))]:
        changed=copy.deepcopy(observed);mutate(changed)
        try:verify(changed,values)
        except (AssertionError,KeyError,ValueError):rejected.append(name)
        else:raise AssertionError('accepted altered epoch: '+name)
    changed=dict(values);p='t/lib/FSM/Test/RustProxyFixture.pm'
    changed[p]=changed[p].replace(b'MacOSX.sdk',b'MacOSX26.5.sdk')
    try:verify(observed,changed)
    except AssertionError:rejected.append('producer_sdk_rollback')
    else:raise AssertionError('accepted producer rollback')
    altered=copy.deepcopy(result);altered['old_version_label_proves_old_sdk_bytes']=True
    assert altered!=verify(observed,values)
    rejected.append('promoted_historical_equivalence')
    return rejected


def main():
    parser=argparse.ArgumentParser()
    group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--capture',action='store_true');group.add_argument('--verify-saved',action='store_true')
    args=parser.parse_args();values=source_inputs()
    if args.capture:
        observed=dict(schema='fsmgen.compiler_profile_toolchain_epoch.v1',
            captured_utc=datetime.now(timezone.utc).isoformat(),project_device=ROOT.stat().st_dev,
            host=dict(sysname=os.uname().sysname,machine=os.uname().machine,release=os.uname().release),
            files=[external_pin(p) for p in PLAN['external_read_only_files']],
            sdk_entries=[sdk_entry(p) for p in PLAN['sdk_entries']],new_compiler_or_fixture_invocation=False)
        # Preserve the first actual read before deriving its disposition.
        save(BASE/'epoch-first.json',observed)
    else:observed=json.loads((BASE/'epoch-first.json').read_bytes())
    result=verify(observed,values);rejected=controls(observed,values,result)
    report=dict(owner=PLAN['owner'],source_revision=PLAN['source_revision'],result=result,
        rejected_controls=rejected,first_capture_sha256=digest((BASE/'epoch-first.json').read_bytes()),
        current_revalidation_required_before_execution=True)
    if args.capture:save(BASE/'epoch-review.json',report)
    else:assert report==json.loads((BASE/'epoch-review.json').read_bytes())
    print(json.dumps(dict(compiler_bytes_changed=True,default_sdk_changed=True,
        old_sdk_directory_identity_changed=True,rejected_controls=len(rejected),
        current_revalidation_required_before_execution=True,new_compiler_or_fixture_invocation=False),sort_keys=True))


if __name__=='__main__':main()
