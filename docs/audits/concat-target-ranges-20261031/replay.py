"""Focused original/current/incorrect-owner target-range checks; no HDL runtime."""
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
BEFORE = '0781b80c9'
OWNER = 'perl/FSM/DirectConcatenationRangeSupport.pm'
FACADE = 'perl/FSM/DirectDeclaredWidthSupport.pm'
TEST = 't/2295-concatenation-target-ranges.t'
PROBE = 'docs/audits/concat-guard-capture-20261030/probe.pl'


def run(command, cwd=ROOT):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    return dict(command=command, cwd=str(cwd.relative_to(ROOT)) or '.', status=result.returncode,
                stdout=result.stdout, stderr=result.stderr)


def save(record):
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())


def normalize(value):
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, str):
        return re.sub(r'^// Date:.*\n', '// Date: <normalized>\n', value, flags=re.M)
    return value


def main():
    revision = subprocess.check_output(['git', 'rev-parse', BEFORE], cwd=ROOT, text=True).strip()
    archive = subprocess.check_output(['git', 'archive', '--format=tar', revision,
                                      'bin', 'perl', 'specs/Lispish.spec'], cwd=ROOT)
    paths = [OWNER, FACADE, TEST, 't/2294-concatenation-source-declarations.t', PROBE,
             str(Path(__file__).relative_to(ROOT)),
             str((HERE / 'initial-draft.json.gz').relative_to(ROOT)),
             str((HERE / 'draft-check.json.gz').relative_to(ROOT))]
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in paths}
    record = dict(schema_version=1, before_revision=revision, source_sha256=hashes,
                  archive_sha256=hashlib.sha256(archive).hexdigest())
    with tempfile.TemporaryDirectory(prefix='concat-target-range-', dir=ROOT / '.artifacts/tmp') as directory:
        work = Path(directory)
        assert work.stat().st_dev == ROOT.stat().st_dev
        with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
            stream.extractall(work, filter='data')
        for path in (OWNER, FACADE):
            original = subprocess.check_output(['git', 'show', f'{revision}:{path}'], cwd=ROOT)
            assert (work / path).read_bytes() == original
        (work / TEST).parent.mkdir(parents=True)
        (work / TEST).write_bytes((ROOT / TEST).read_bytes())
        (work / PROBE).parent.mkdir(parents=True)
        (work / PROBE).write_bytes((ROOT / PROBE).read_bytes())
        record['predecessor'] = red = run(['prove', '-v', '-Iperl', TEST], work)
        save(record)
        assert red['status'] != 0 and "Failed test 'complete physical concatenation target prepares'" in red['stderr'], red
        assert 'ok 2 - original completed source sum exists independently of new API' in red['stdout'], red
        record['focused'] = focused = run(['prove', '-v', '-Iperl', TEST, 't/2294-concatenation-source-declarations.t'])
        save(record)
        assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
        assert f'loaded {OWNER} sha256={hashes[OWNER]}' in focused['stderr']
        (work / FACADE).write_bytes((ROOT / FACADE).read_bytes())
        current = (ROOT / OWNER).read_text()
        controls = {
            'missing_complete_target_fence': (
                current.replace('unless _same($snapshot, _target_snapshot(%args));', 'unless 1;', 1),
                "Failed test 'target_identity final mutation refuses equal target ranges'"),
            'missing_original_source_fence': (
                current.replace('unless _current_raw($checkpoint, %current_args);\n    _fail(\'installed original typed renderer changed during target preparation\')',
                                'unless 1;\n    _fail(\'installed original typed renderer changed during target preparation\')', 1),
                "Failed test 'event_identity final mutation refuses equal target ranges'"),
            'missing_physical_result_width_agreement': (
                current.replace('unless FSM::IntermediateWidthAllocationSupport::_width($result->{width}) eq $width\n            && _same($width, $intent->{width});',
                                'unless 1;', 1),
                "Failed test 'wrong result width cannot use a correct source sum'"),
        }
        record['counterfactuals'] = {}
        for name, (source, needle) in controls.items():
            assert source != current
            (work / OWNER).write_text(source)
            result = run(['prove', '-v', '-Iperl', TEST], work)
            record['counterfactuals'][name] = dict(source=source, sha256=hashlib.sha256(source.encode()).hexdigest(), **result)
            save(record)
            assert result['status'] != 0 and needle in result['stderr'], result
        # Preserve the first draft's actual failure with its complete original
        # sources. The initial interactive output was truncated; this is a
        # distinct same-source replay, not a reconstruction of that raw stream.
        initial = json.loads(gzip.decompress((HERE / 'initial-draft.json.gz').read_bytes()))
        for path, row in initial['sources'].items():
            source = row['source'].encode()
            assert hashlib.sha256(source).hexdigest() == row['sha256']
            (work / path).write_bytes(source)
        record['initial_draft_replay'] = draft = run(['prove', '-v', '-Iperl', TEST], work)
        save(record)
        assert draft['status'] != 0 and 'target result disagrees with the independent ordered operand sum' in draft['stderr']
        # Restore the authenticated predecessor before native conservation.
        with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
            stream.extractall(work, filter='data')
        record['native'] = {}
        for mode in ('fixed', 'mutable', 'rhs', 'mutable_rhs'):
            old = run(['perl', '-Iperl', PROBE, mode], work)
            new = run(['perl', '-Iperl', PROBE, mode])
            record['native'][mode] = dict(before=old, after=new)
            save(record)
            assert old['status'] == new['status'] == 0, (old, new)
            assert normalize(json.loads(old['stdout'])) == normalize(json.loads(new['stdout']))
    tracked = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, 'bin', 'perl'], cwd=ROOT, text=True).splitlines()
    changed = set()
    for path in tracked:
        before = subprocess.check_output(['git', 'show', f'{revision}:{path}'], cwd=ROOT)
        if (ROOT / path).read_bytes() != before:
            changed.add(path)
    assert changed == {FACADE, OWNER}, changed
    actual = set(subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    assert actual == set(tracked)
    record['native_membership'] = dict(predecessor_paths=tracked, changed_existing=sorted(changed))
    for path, digest in hashes.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    record.update(
        rederive='Current original completed sums, independent declarations and ordered explicit literal/signal contracts agree with complete physical target membership and freshly rendered actual-target ranges. An independent source-slot arithmetic oracle checks distinguishing overrides.',
        falsify='Authenticated identical predecessor retains original completed source sums but fails the new target capability. Three isolated incorrect owners genuinely fail final target identity, original source holder and selected physical result-width controls. Hostile declarations/mappings/currentness, detachment, failure/reset/reuse and weak row lifetime checks pass.',
        durability='Tracked owners/test/producer and complete source identities, focused/predecessor/control/native streams, initial draft source and distinct complete draft replay. Git archive and full bin/perl membership are independently joined.',
        limits='Preparation only; native fixed emission records and proposed matching numeric mutable target records are distinguished. No producer-origin attestation, mutable live emission, final ledgers, unknown literal sizing, VHDL, public source/report/API/MCP/corpus capability expansion or full compiler/runtime/publication qualification. Native conservation is bounded to the retained probe population. The original initial interactive output was truncated and is not reconstructed.',
    )
    save(record)
    print('Target plans pass; identical predecessor and all three bad-owner controls fail; bounded native products preserve.')


if __name__ == '__main__':
    main()
