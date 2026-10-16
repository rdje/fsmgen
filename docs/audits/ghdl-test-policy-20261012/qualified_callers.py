"""Run original HDL callers against pinned GHDL with complete stage observation."""
from pathlib import Path
import argparse
import base64
import gzip
import hashlib
import json
import os
import shutil
import subprocess
from observe_owner import BASE, save

TESTS = [
    't/1892-explicit-reset-hdl-behavior.t',
    't/1901-reset-only-output-behavior.t',
    't/1902-explicit-internal-signal-roles.t',
    't/1903-isf-internal-storage-ownership.t',
    't/1904-isf-generated-child-storage-reads.t',
    't/1909-isf-dynamic-wait-count-predicates.t',
    't/1910-vhdl-unsigned-comparison-literals.t',
    't/1932-isf-extract-runtime.t',
    't/1952-isf-storage-keyword-identifiers.t',
]

def identity(path):
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for chunk in iter(lambda: stream.read(1_048_576), b''):
            digest.update(chunk)
    return dict(bytes=path.stat().st_size, sha256=digest.hexdigest(),
                mode=path.stat().st_mode & 0o777)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reset-only', action='store_true')
    args = parser.parse_args()
    label = 'qualified-reset-only-20261016' if args.reset_only else 'qualified-callers-20261016-v3'
    tests = ['t/1901-reset-only-output-behavior.t'] if args.reset_only else TESTS
    authority = Path('vial/qualification/vhdl_portable_ghdl/ghdl-6.0.0-qualification.json')
    source = authority.read_bytes()
    qualification = json.loads(source)
    provider = qualification['provider']
    binary = Path(provider['binary'])
    assert not binary.is_absolute() and '..' not in binary.parts
    assert binary.resolve().is_relative_to(Path.cwd()) and not binary.is_symlink()
    before = identity(binary)
    assert before['sha256'] == provider['binary_sha256']
    environment = dict(os.environ)
    environment['FSMGEN_RESET_GHDL'] = binary.as_posix()
    environment['PATH'] = str(binary.resolve().parent) + os.pathsep + environment.get('PATH', '')
    observer = BASE / 'observer-lib'
    assert 'HARNESS_PERL_SWITCHES' not in environment, 'preserve unknown caller harness configuration'
    environment['HARNESS_PERL_SWITCHES'] = '-Iperl -It/lib -I' + str(observer) + ' -MFSM::Test::HDLPolicyObservation'
    folder = Path('.artifacts/ghdl-test-policy-20261012/native') / label
    folder.mkdir(parents=True, exist_ok=False)
    environment['FSMGEN_HDL_POLICY_OBSERVATION'] = folder.as_posix()
    verilator = shutil.which('verilator', path=environment['PATH'])
    assert verilator is not None, 'original lint qualification requires Verilator'
    verilator_path = Path(verilator).resolve()
    lint_before = identity(verilator_path)
    command = ['prove', '-v', '-Iperl', '-It/lib', '-I' + str(observer), *tests]
    start = dict(owner='TASK-ACCEPTANCE-AUDIT-SOURCE-COVERAGE.1.1.2', command=command,
        expected_status=0, authority_path=authority.as_posix(), authority_body=source.decode(),
        provider_before=before, lint_provider_before=lint_before,
        selected_provider=binary.as_posix(), native_observation=folder.as_posix(),
        harness_observer=environment['HARNESS_PERL_SWITCHES'],
        darwin_verilator_runtime_opt_in=environment.get('FSMGEN_DARWIN_VERILATOR_TEST_RUNTIME'),
        condition='Explicit qualification provider override; public defaults and Darwin '
                  'runtime guard retain. Observer forwards the admitted call and identical '
                  'native return; it does not create, retry or promote a stage.')
    save(label + '-provider-started.json', start)
    result = subprocess.run(command, env=environment)
    records = {}
    for path in sorted(folder.glob('*.json')):
        assert not path.is_symlink()
        body = path.read_bytes()
        records[path.name] = dict(body_base64=base64.b64encode(body).decode(),
                                  sha256=hashlib.sha256(body).hexdigest(), record=json.loads(body))
    after, lint_after = identity(binary), identity(verilator_path)
    actual = dict(**start, status=result.returncode, provider_after=after,
                  lint_provider_after=lint_after, native_records=records)
    with (BASE / (label + '-native.json.gz')).open('xb') as stream:
        stream.write(gzip.compress(json.dumps(actual, sort_keys=True).encode(), mtime=0))
    assert before == after and lint_before == lint_after, 'selected tool identities must conserve'
    if result.returncode:
        raise SystemExit(result.returncode)
    assert {row['record']['test'] for row in records.values()} == {Path(name).name for name in tests}
    expected_stages = {'ghdl'} if args.reset_only else {'ghdl', 'verilator_lint'}
    assert {row['record']['stage'] for row in records.values()} == expected_stages
    for row in records.values():
        record = row['record']
        native = record['native']
        assert native['ok'] and native['cleanup']['leader_reaped'] and native['cleanup']['group_gone']
        expected = binary.resolve() if record['stage'] == 'ghdl' else verilator_path
        assert Path(record['argv'][0]) == expected
    print('Original caller collection and every observed HDL stage passed.', flush=True)

if __name__ == '__main__':
    main()
