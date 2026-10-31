"""Replay current source-intent preparation, native conservation and bad-owner controls."""
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
TEST = 't/2294-concatenation-source-declarations.t'
OWNER = 'perl/FSM/DirectConcatenationRangeSupport.pm'
FACADE = 'perl/FSM/DirectDeclaredWidthSupport.pm'
PROBE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
BEFORE = '3b27bcbd0'


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
    original = subprocess.check_output(['git', 'show', f'{revision}:{FACADE}'], cwd=ROOT)
    paths = [OWNER, FACADE, TEST, 't/2292-concatenation-completed-sums.t', PROBE,
             str(Path(__file__).relative_to(ROOT)),
             str((HERE / 'initial-check.json.gz').relative_to(ROOT)),
             str((HERE / 'cache-counterexample.json.gz').relative_to(ROOT))]
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in paths}
    record = dict(schema_version=1, before_revision=revision, source_sha256=hashes,
                  archive_sha256=hashlib.sha256(archive).hexdigest(),
                  predecessor_facade_sha256=hashlib.sha256(original).hexdigest())
    with tempfile.TemporaryDirectory(prefix='concat-source-intent-', dir=ROOT / '.artifacts/tmp') as directory:
        work = Path(directory)
        assert work.stat().st_dev == ROOT.stat().st_dev
        with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
            stream.extractall(work, filter='data')
        assert (work / FACADE).read_bytes() == original
        assert not (work / OWNER).exists()
        (work / 't').mkdir()
        (work / TEST).write_bytes((ROOT / TEST).read_bytes())
        (work / PROBE).parent.mkdir(parents=True)
        (work / PROBE).write_bytes((ROOT / PROBE).read_bytes())
        record['predecessor'] = red = run(['prove', '-v', '-Iperl', TEST], work)
        save(record)
        assert red['status'] != 0 and 'actual original completed row has source declaration intent' in red['stderr'], red
        assert f'loaded {FACADE} sha256={record["predecessor_facade_sha256"]}' in red['stderr']
        record['focused'] = focused = run(['prove', '-v', '-Iperl', TEST, 't/2292-concatenation-completed-sums.t'])
        save(record)
        assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
        assert f'loaded {OWNER} sha256={hashes[OWNER]}' in focused['stderr']
        (work / FACADE).write_bytes((ROOT / FACADE).read_bytes())
        current = (ROOT / OWNER).read_text()
        controls = {
            'missing_final_original_holder_fence': (
                current.replace('unless _current_raw($checkpoint, %current_args);', 'unless 1;', 1),
                'event late mutation cannot refresh source intent'),
            'cached_text_without_fresh_typed_render': (
                current.replace('unless _same($expression, $rendered);', 'unless 1;', 1),
                'preexisting same-tag wrong expression cannot supply source intent'),
            'missing_original_renderer_fence': (
                current.replace('unless ($ctx->{enable_graph_ast_support} // 0) == $renderer\n            && ($renderer->{flattened_dt} // 0) == $ctx;', 'unless 1;', 1),
                'early_renderer late mutation cannot refresh source intent'),
        }
        record['counterfactuals'] = {}
        for name, (source, needle) in controls.items():
            assert source != current
            (work / OWNER).write_text(source)
            result = run(['prove', '-v', '-Iperl', TEST], work)
            record['counterfactuals'][name] = dict(source=source, sha256=hashlib.sha256(source.encode()).hexdigest(), result=result)
            save(record)
            assert result['status'] != 0 and needle in result['stderr'], result
        (work / FACADE).write_bytes(original)
        (work / OWNER).unlink()
        record['native_predecessor'] = old = run(['perl', '-Iperl', PROBE], work)
        record['native_current'] = new = run(['perl', '-Iperl', PROBE])
        save(record)
        assert old['status'] == new['status'] == 0, (old, new)
        assert normalize(json.loads(old['stdout'])) == normalize(json.loads(new['stdout']))
    tracked = subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision, 'bin', 'perl'], cwd=ROOT, text=True).splitlines()
    changed = set()
    for path in tracked:
        before = subprocess.check_output(['git', 'show', f'{revision}:{path}'], cwd=ROOT)
        if (ROOT / path).read_bytes() != before:
            changed.add(path)
    assert changed == {FACADE}, changed
    record['native_membership'] = dict(predecessor_paths=tracked, changed_existing=sorted(changed), added=[OWNER])
    actual = set(subprocess.check_output(['git', 'ls-files', '--cached', '--others', '--exclude-standard', '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    assert actual == set(tracked) | {OWNER}
    for path, digest in hashes.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    record.update(
        rederive='Actual original completed rows in both Verilog-family backends supply detached source-only intent. Original independent ordered terms, literal fields, selected numeric sums and packed rank preserve; source and actual target language remain separate.',
        falsify='Identical predecessor lacks the new private capability while actual original candidates and sums still exist. Isolated controls omitting the final original-holder fence or fresh typed-render comparison genuinely fail equal-holder and original-cache counterexamples. Missing/foreign/failed proof, hostile source/row/epoch/owner changes, detachment and clean reuse pass. Complete native caller/HDL/declaration/refusal products preserve under Date-only normalization.',
        durability='Tracked sources, focused tests, producer and complete original/predecessor/current/control/native streams and hashes. Initial passing test blindspot and the actual failing same-tag preexisting-cache counterexample retain with complete source snapshots.',
        limits='Private source intent only. No complete physical target namespace/declaration agreement, live range emission, final ledger, public source/API/MCP/corpus capability, VHDL or external compiler/override/runtime/full publication qualification. Native conservation is bounded to the retained probe population.',
    )
    save(record)
    print('Source declaration intent passes; predecessor and missing-fence/fresh-render controls fail; bounded native products preserve.')


if __name__ == '__main__':
    main()
