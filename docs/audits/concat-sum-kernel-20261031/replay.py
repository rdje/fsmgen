"""Qualify a prepared sum without source, backend-event or HDL-tool admission."""
import gzip
import hashlib
import io
import json
from pathlib import Path
import subprocess
import tarfile
import tempfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
TEST = 't/2290-verilog-prepared-sum-range.t'
OWNER = 'perl/FSM/Backend/VerilogFamily/WidthExpressionEmitter.pm'
BEFORE = '0d94e3e17'


def run(command, cwd=ROOT):
    result = subprocess.run(command, cwd=cwd, capture_output=True, text=True)
    return dict(command=command, cwd=str(cwd.relative_to(ROOT)) or '.',
                status=result.returncode, stdout=result.stdout, stderr=result.stderr)


def save(record):
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())


def main():
    revision = subprocess.check_output(['git', 'rev-parse', BEFORE], cwd=ROOT, text=True).strip()
    archive = subprocess.check_output(['git', 'archive', '--format=tar', revision,
                                      'bin', 'perl', 'specs/Lispish.spec'], cwd=ROOT)
    work = Path(tempfile.mkdtemp(prefix='concat-sum-predecessor-', dir=ROOT / '.artifacts'))
    assert work.stat().st_dev == ROOT.stat().st_dev
    with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
        stream.extractall(work, filter='data')
    original = subprocess.check_output(['git', 'show', f'{revision}:{OWNER}'], cwd=ROOT)
    assert (work / OWNER).read_bytes() == original
    (work / 't').mkdir()
    (work / TEST).write_bytes((ROOT / TEST).read_bytes())
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
              for path in (OWNER, TEST, 't/2263-verilog-prepared-maximum-range.t',
                           str(Path(__file__).relative_to(ROOT)))}
    record = dict(schema_version=1, before_revision=revision, source_sha256=hashes,
                  predecessor_owner_sha256=hashlib.sha256(original).hexdigest(),
                  archive_sha256=hashlib.sha256(archive).hexdigest())
    red = run(['prove', '-v', '-Iperl', TEST], work)
    record['predecessor'] = red
    save(record)
    assert red['status'] != 0 and 'separate prepared sum kernel exists' in red['stderr'], red
    assert f'loaded {OWNER} sha256={record["predecessor_owner_sha256"]}' in red['stderr']
    focused = run(['prove', '-v', '-Iperl', TEST, 't/2263-verilog-prepared-maximum-range.t'])
    record['focused'] = focused
    save(record)
    assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
    assert f'loaded {OWNER} sha256={hashes[OWNER]}' in focused['stderr']
    current = (ROOT / OWNER).read_text()
    start = current.index('sub lower_sum_range ')
    end = current.index('sub lower_maximum_range ', start)
    method = current[start:end]
    controls = {
        'maximum_instead_of_sum': current[:start] + '''sub lower_sum_range ($class, %args) {
    return $class->lower_maximum_range(%args);
}

''' + current[end:],
        'missing_last_slot': current[:start] + method.replace(
            '    my $value = FSM::WidthExpressionSupport',
            '    pop @terms if @terms > 1;\n    my $value = FSM::WidthExpressionSupport', 1) + current[end:],
        'merge_equal_defaults': current[:start] + method.replace(
            '    my $value = FSM::WidthExpressionSupport',
            '    my %seen; @terms = grep {!$seen{$_->{value}->bstr}++} @terms;\n    my $value = FSM::WidthExpressionSupport', 1) + current[end:],
    }
    record['counterfactuals'] = {}
    for name, source in controls.items():
        assert source != current
        (work / OWNER).write_text(source)
        result = run(['prove', '-v', '-Iperl', TEST], work)
        record['counterfactuals'][name] = dict(source=source, sha256=hashlib.sha256(source.encode()).hexdigest(), result=result)
        save(record)
        assert result['status'] != 0 and 'independent slot-weight oracle' in result['stderr'], result
    changed = set(subprocess.check_output(['git', 'diff', '--name-only', revision, '--', 'bin', 'perl'],
                                         cwd=ROOT, text=True).splitlines())
    assert changed == {OWNER}, changed
    for path, digest in hashes.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    record.update(
        rederive='Actual prepared kernel renders ordered independent contracts, exact fixed summands, repeated slots and nested arithmetic; an independent emitted-syntax interpreter checks explicit slot-weight golden widths under distinguishing overrides. Canonical integer arithmetic folds fixed-only sums without native precision loss.',
        falsify='The identical test rejects the authenticated original missing API. Three isolated native controls replace addition with maximum, drop the last slot or merge equal selected defaults; each genuinely fails the independent override oracle. Real lookup/scope/arithmetic/input/output refusal, complete caller conservation and weak lifetime controls qualify the boundary. Existing prepared-maximum regression preserves shared operand validation.',
        durability='Tracked owner/test/replay and complete authenticated predecessor/current/counterfactual sources and streams in this deterministic receipt. Exact source hashes and native Git/archive boundary make later changes detectable.',
        limits='Private prepared rendering only; supplied contracts do not attest source membership, literal sizing, current allocation/row/epoch, target namespace, live declarations or ledgers. No source grammar/report/API/MCP/corpus capability change. Source sum, completed event and target integration remain owned; VHDL, external compiler/override/runtime and full6/publication are not qualified.',
    )
    save(record)
    print('Prepared sum and maximum checks pass; original and three arithmetic/allocation controls fail.')


if __name__ == '__main__':
    main()
