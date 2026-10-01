"""Authenticate the dated fixed-render cleanup; never perform deletion."""
import copy
import hashlib
import json
import os
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TARGET = '.artifacts/record-output-profiles/book'


def validate(report, protected):
    assert report['owner'] == 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.5'
    assert report['cleanup_revision'] == 'c8c1e5ee45f8594f2f298876d95ab20e0127eccc'
    assert report['residue'] == {TARGET: False}
    assert [row['path'] for row in report['removed']] == [TARGET]
    row = report['removed'][0]
    paths = [item['path'] for item in row['files']]
    assert paths == sorted(set(paths)) and len(paths) == 99
    assert all(path.startswith(TARGET + '/') and '..' not in Path(path).parts for path in paths)
    assert sum(item['bytes'] for item in row['files']) == row['bytes_total'] == 26389300
    assert all(len(item['sha256']) == 64 and type(item['bytes']) is int for item in row['files'])
    assert not os.path.lexists(ROOT / TARGET)
    assert protected['before'] == protected['after'] and protected['after_equal'] is True
    assert len(protected['before']) == 347
    assert 'before maintained book rebuild' in protected['capture_boundary']
    for name in ('record-output-hdl-profiles-20261001', 'record-output-public-sources-20261001',
                 'record-output-target-profiles-20261001', 'record-output-source-admission-20261001',
                 'record-input-direct-observation-20261001', 'record-input-generated-observation-complete-20261001'):
        prefix = 'docs/audits/' + name + '/'
        actual = {str(p.relative_to(ROOT)) for p in (ROOT / 'docs/audits' / name).rglob('*') if p.is_file()}
        assert {path for path in protected['before'] if path.startswith(prefix)} == actual
    for path, item in protected['before'].items():
        assert not Path(path).is_absolute() and '..' not in Path(path).parts
        assert not path.startswith(TARGET + '/')
        # Mutable book/workspace identities are dated before/after captures.
        # Only immutable committed parents are compared with today's bytes.
        if path.startswith('docs/audits/'):
            raw = (ROOT / path).read_bytes()
            assert len(raw) == item['bytes'] and hashlib.sha256(raw).hexdigest() == item['sha256']
    assert report['retained'] == ['all logs', 'native/receipt evidence', 'spent compiler workspaces', 'docs/book/book']
    assert [(row['path'], row['status'], row['retained']) for row in report['rust']] == [
        ('target/release', 'absent', []), ('target/debug/incremental', 'absent', []),
        ('target/debug/deps', 'absent', []), ('rust/target/release', 'absent', []),
        ('rust/target/debug/incremental', 'censused', []), ('rust/target/debug/deps', 'censused', [])]
    assert (ROOT / 'docs/book/book/index.html').is_file()


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert set(manifest['sha256']) == {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    for name, digest in manifest['sha256'].items():
        assert hashlib.sha256((HERE / name).read_bytes()).hexdigest() == digest
    assert manifest['terminal_exit_codes'] == dict(inspect=0, apply=0, verify_saved=0, docs=0, book=0)
    report = json.loads((HERE / 'result.json').read_bytes())
    protected = json.loads((HERE / 'protected.json').read_bytes())
    validate(report, protected)
    assert 'All tests successful' in (HERE / 'docs.txt').read_text()
    assert 'Files=3, Tests=310' in (HERE / 'docs.txt').read_text()
    assert 'HTML book written to' in (HERE / 'book.txt').read_text()
    for mutate in (
        lambda r: r['removed'][0].update(path='.artifacts'),
        lambda r: r['removed'][0].update(bytes_total=0),
        lambda r: r['removed'][0]['files'].pop(),
        lambda r: r.update(retained=[]),
        lambda r: r['removed'][0]['files'][0].update(path=TARGET + '/../outside'),
    ):
        bad = copy.deepcopy(report); mutate(bad)
        try:
            validate(bad, protected)
        except (AssertionError, KeyError, TypeError):
            continue
        raise AssertionError('hostile cleanup allocation or scope accepted')
    bad = copy.deepcopy(protected)
    first = next(iter(bad['after']))
    bad['after'][first]['sha256'] = '0' * 64
    try:
        validate(report, bad)
    except AssertionError:
        pass
    else:
        raise AssertionError('changed protected identity accepted')
    print('Dated fixed-render membership/allocation/residue, protected before/after identities and immutable parents authenticate; hostile scope/loss/retention changes reject. Mutable captures are historical, obsolete bytes are not reproduced, and no HDL runs.')


if __name__ == '__main__':
    main()
