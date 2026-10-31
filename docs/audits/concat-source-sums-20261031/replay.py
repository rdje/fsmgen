"""Qualify original current source sums without target emission admission."""
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
TEST = 't/2291-concatenation-source-sums.t'
OWNER = 'perl/FSM/ConcatenationSourceWidthSupport.pm'
KERNEL = 'perl/FSM/Backend/VerilogFamily/WidthExpressionEmitter.pm'
BEFORE = 'd3cad2812'


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
    work = Path(tempfile.mkdtemp(prefix='concat-sum-source-predecessor-', dir=ROOT / '.artifacts'))
    assert work.stat().st_dev == ROOT.stat().st_dev
    with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
        stream.extractall(work, filter='data')
    original = subprocess.check_output(['git', 'show', f'{revision}:{OWNER}'], cwd=ROOT)
    assert (work / OWNER).read_bytes() == original
    (work / 't').mkdir()
    (work / TEST).write_bytes((ROOT / TEST).read_bytes())
    paths = [OWNER, TEST, KERNEL, 't/2278-concatenation-source-widths.t', str(Path(__file__).relative_to(ROOT))]
    paths += [str((HERE / name).relative_to(ROOT)) for name in ('first-check.json.gz', 'second-check.json.gz', 'diagnostic.json.gz')]
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in paths}
    record = dict(schema_version=1, before_revision=revision, source_sha256=hashes,
                  predecessor_owner_sha256=hashlib.sha256(original).hexdigest(),
                  archive_sha256=hashlib.sha256(archive).hexdigest())
    red = run(['prove', '-v', '-Iperl', TEST], work)
    record['predecessor'] = red
    save(record)
    assert red['status'] != 0 and 'separate original current source sum operations exist' in red['stderr'], red
    assert f'loaded {OWNER} sha256={record["predecessor_owner_sha256"]}' in red['stderr']
    focused = run(['prove', '-v', '-Iperl', TEST, 't/2278-concatenation-source-widths.t'])
    record['focused'] = focused
    save(record)
    assert focused['status'] == 0 and 'All tests successful' in focused['stdout'], focused
    assert f'loaded {OWNER} sha256={hashes[OWNER]}' in focused['stderr']
    current = (ROOT / OWNER).read_text()
    controls = {
        'missing_final_raw_barrier': current.replace('    _barrier(@source_args); # getter-free closure after every source/environment read\n', '', 1),
        'borrow_first_source_contract': current.replace('push @$terms, {kind => \'signal\', %$operand};', 'push @$terms, {kind => \'signal\', %{$operands->[0]}};', 1),
    }
    record['counterfactuals'] = {}
    for name, source in controls.items():
        assert source != current
        (work / OWNER).write_text(source)
        result = run(['prove', '-v', '-Iperl', TEST], work)
        record['counterfactuals'][name] = dict(source=source, sha256=hashlib.sha256(source.encode()).hexdigest(), result=result)
        save(record)
        assert result['status'] != 0, result
        needle = 'final raw barrier rejects a late render callback mutation' if name == 'missing_final_raw_barrier' else 'actual syntax follows independent source-slot oracle'
        assert needle in result['stderr'], result
    changed = set(subprocess.check_output(['git', 'diff', '--name-only', revision, '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    assert changed == {OWNER}, changed
    for path, digest in hashes.items():
        assert hashlib.sha256((ROOT / path).read_bytes()).hexdigest() == digest, path
    record.update(
        rederive='Actual original factorizer/Core source holders produce fixed/mixed/independent/equal-default/nested-arithmetic sums, retaining ordered repeated slots, exact literal fields/radices and width-one operand rank. Independent emitted-syntax interpretation checks explicit source-slot golden widths under distinguishing overrides. Actual guard collection in both Verilog-family backends observes source sums without gaining mutable target emission.',
        falsify='Identical regression rejects the authenticated native predecessor missing API. Isolated original-scope controls remove only the final raw barrier or replace each signal slot with the first source contract; the actual late-render mutation and independent override oracle genuinely fail. Stale/foreign/raw map/revision/type/constraint/changed-holder/JSON-kind, unknown literal, arity, late environment/getter and weak lifetime controls qualify the boundary. Directly affected existing source-contract/native inline-RHS refusal tests pass.',
        durability='Tracked owner/test/replay and complete authenticated predecessor/current/counterfactual sources and streams; first two check sources/failures and exact JSON-kind/nonoperand diagnostic remain retained. Complete source hashes and native Git/archive boundary detect changed inputs.',
        limits='Private source-only sum; no original completed backend event, canonical generation row/registry/epoch, actual target declaration/namespace or emitted ledger proof. Fixed sums return an exact decimal string without symbolic range. Unknown literal width remains refused, with target sizing owned by emission integration. VHDL, external compiler/override/runtime, source/report/API/MCP/corpus capability changes and full6/publication are not claimed.',
    )
    save(record)
    print('Current source sums pass; native predecessor, borrowed-contract and missing-raw-barrier controls fail.')


if __name__ == '__main__':
    main()
