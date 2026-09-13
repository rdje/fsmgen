"""Join final source/data admission without running any fixture producer."""
import argparse
import hashlib
import importlib.util
import inspect
import subprocess
from support_final_corrected import BASE, ROOT, H, M, pin, read, reader, write
from admit_execution import absent
import audit_integration_corrected
import qualify_permit
import resources_final

STAGES = {'prepare':1, 'prepare-corrected':0, 'integration':1, 'integration-corrected':0, 'permit':0}


def raw(row):
    body = bytes.fromhex(row['bytes_hex'])
    assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
    return body


def verify():
    plan = read(BASE / 'plan.json'); pins = read(H / 'final-preflight-pins.json')
    for row in plan['inputs'] + pins: assert pin(ROOT / row['path']) == row
    for row in plan['inputs']:
        body = subprocess.check_output(['git','show',plan['source_revision']+':'+row['path']],cwd=ROOT)
        assert body == (ROOT / row['path']).read_bytes()
    assert len({row['path'] for row in pins}) == len(pins)
    assert {row['path'] for row in plan['inputs']} <= {row['path'] for row in pins}
    assert {(BASE/name).relative_to(ROOT).as_posix() for name in ('audit_final.py','audit_integration_corrected.py','support_final_corrected.py','resources_final.py','admit_execution.py','qualify_permit.py')} <= {row['path'] for row in pins}
    spec = importlib.util.spec_from_file_location('qualified_harness_source_audit', H / 'audit.py')
    previous = importlib.util.module_from_spec(spec); spec.loader.exec_module(previous)
    harness = read(H / 'harness-review.json')
    assert previous.verify(harness['raw_captures']) == {key:value for key,value in harness.items() if key != 'raw_captures'}
    integration = audit_integration_corrected.verify()
    assert integration == read(BASE / 'integration-review.json')
    permit = qualify_permit.verify(); assert permit == read(BASE / 'permit-review.json')
    assert reader.opened_identities is resources_final.opened_identities
    assert inspect.getsourcefile(reader.verify) == str(H / 'consume_controls.py')
    assert inspect.getsourcefile(resources_final.resources) == str(H / 'resources.py')
    sources = {
        'NativeProxyLifetimeFiles': (ROOT/'docs/audits/native-proxy-lifetime-files-admission-20260913/LifetimeFiles.pm',
            'sysopen(my $handle, "$ROOT/$relative", O_WRONLY | O_CREAT | O_EXCL | O_NOFOLLOW, 0600)', 0o600),
        'NativeProxyImageCoordination': (ROOT/'docs/audits/native-proxy-image-coordination-20260910/Coordination.pm',
            'sysopen($handle, $path, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW | O_NONBLOCK, 0600)', 0o600),
        'NativeProxyImagePublication': (ROOT/'docs/audits/native-proxy-image-publication-20260910/Publication.pm',
            'sysopen(my $writer, $path, O_RDWR | O_CREAT | O_EXCL | O_NOFOLLOW, 0400)', 0o400),
    }
    assert resources_final.CREATION_MODES == {key:value[2] for key,value in sources.items()}
    for path, marker, mode in sources.values(): assert marker in path.read_text()
    publication = sources['NativeProxyImagePublication'][0].read_text()
    assert publication.index('syswrite(') < publication.index('NativeProxyImageCustody::_source(') < publication.index('_seal_payload($writer, $mode)')
    first = read(BASE / 'first-preparation-failure.json'); failed = read(BASE / 'first-integration-failure.json')
    for receipt in (first, failed):
        for row in receipt['sources'] + receipt['outputs']: raw(row)
        assert raw(receipt['outputs'][-1]) == b'1\n'
    original = next(raw(row) for row in first['sources'] if row['path'].endswith('/prepare_integration.py'))
    assert original == (BASE/'prepare_integration.py').read_bytes()
    assert original.replace(b'name: bytes.fromhex(body)',b"name.removesuffix('_hex'): bytes.fromhex(body)") == (BASE/'prepare_integration_corrected.py').read_bytes()
    assert b"KeyError: 'wrapper'" in raw(first['outputs'][1])
    assert b'opened_identities' in raw(failed['outputs'][1]) and b'0o600' in raw(failed['outputs'][1])
    selection = read(M / 'selection.json')
    roots = [case['roots'][key] for case in selection['cases'] for key in ('store','target','other','evidence')]
    assert roots == plan['prospective_roots'] and len(roots) == len(set(roots)) == 56
    assert all(absent(path) for path in roots)
    outputs = read(BASE / 'qualification-outputs.json')
    by_name = {row['path'].rsplit('/',1)[1]:raw(row) for row in outputs}
    assert len(by_name) == len(outputs) == len(STAGES)*3
    for stage, status in STAGES.items(): assert by_name[stage+'.exit'] == str(status).encode()+b'\n'
    return dict(schema='fsmgen.lifetime_controls_final_admission_review.v1', owner=plan['owner'],
        source_revision=plan['source_revision'], git_inputs=len(plan['inputs']), preflight_inputs=len(pins),
        selected_cases=len(selection['cases']), prospective_roots_absent=roots,
        selected_reader=pin(BASE/'support_final_corrected.py'), identity_reader=pin(BASE/'resources_final.py'),
        harness_source_review=pin(H/'harness-review.json'), integration_review=pin(BASE/'integration-review.json'),
        permit_review=pin(BASE/'permit-review.json'), raw_outputs=outputs,
        creation_modes=resources_final.CREATION_MODES, first_failures_preserved=True,
        actual_fixture_operations=0, actual_permits_written=0, execution_requires_committed_admission=True,
        runtime_qualification=False, native_process_authentication=False)


def main():
    parser=argparse.ArgumentParser();group=parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--retain',action='store_true');group.add_argument('--verify-saved',action='store_true');args=parser.parse_args()
    result=verify()
    if args.retain:write(BASE/'review.json',result)
    else:assert read(BASE/'review.json')==result
    print('Final lifetime control admission: OK; source/data only; commit required before permit and execution.')


if __name__=='__main__':main()
