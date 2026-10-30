"""Replay source-only concatenation contracts and complete native conservation."""
import gzip
import hashlib
import io
import json
from pathlib import Path
import re
import subprocess
import tarfile

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
REVISION = '2b9b9af72cc617c775787e92ff44c6d320f41e40'
TEST = 't/2278-concatenation-source-widths.t'
BASE = 'docs/audits/concat-guard-capture-20261030/probe.pl'
PROBE = str((HERE / 'probe.pl').relative_to(ROOT))
WORK = ROOT / '.artifacts/concat-source-widths-predecessor'


def run(arguments, cwd=ROOT):
    result = subprocess.run(arguments, cwd=cwd, capture_output=True, text=True)
    return dict(command=arguments, cwd=str(cwd.relative_to(ROOT)) or '.', status=result.returncode,
                stdout=result.stdout, stderr=result.stderr)


def normalize(value):
    if isinstance(value, str):
        return re.sub(r'^// Date:.*\n', '// Date: <normalized>\n', value, flags=re.M)
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    return value


def main():
    baseline = run(['perl', '-Iperl', BASE])
    observed = run(['perl', '-Iperl', PROBE])
    assert baseline['status'] == observed['status'] == 0, (baseline, observed)
    native = json.loads(baseline['stdout'])
    result = json.loads(observed['stdout'])
    prior = json.loads(gzip.decompress((ROOT / 'docs/audits/concat-source-observations-20261030/evidence.json.gz').read_bytes()))
    assert normalize(native) == normalize(result['native']), 'source adapter changes native products'
    assert normalize(native) == normalize(json.loads(prior['baseline']['stdout'])), 'predecessor native products changed'
    plans = [entry['plan'] for collection in result['observations'] for entry in collection['frames']]
    assert plans, 'actual original candidate source preparation must run'
    for plan in plans:
        record = plan['record']
        assert record['kind'] == 'concatenation_source_widths'
        assert record['source_names'] in [['A', 'B'], ['B', 'A'], ['A', 'B', 'A']]
        assert [operand['name'] for operand in record['operands']] == record['source_names']
        for operand in record['operands']:
            assert operand['width'] == (8 if operand['name'] == 'A' else 3)
    # Exact predecessor production snapshot; no submodule or other repo checkout.
    # The settled identical test demonstrates that the new source API was absent.
    WORK.mkdir(parents=True, exist_ok=True)
    assert WORK.stat().st_dev == ROOT.stat().st_dev
    archive = subprocess.check_output(['git', 'archive', '--format=tar', REVISION, 'bin', 'perl'], cwd=ROOT)
    with tarfile.open(fileobj=io.BytesIO(archive)) as stream:
        stream.extractall(WORK, filter='data')
    assert not (WORK / 'perl/FSM/ConcatenationSourceWidthSupport.pm').exists()
    (WORK / 't').mkdir(exist_ok=True)
    (WORK / TEST).write_bytes((ROOT / TEST).read_bytes())
    predecessor = run(['prove', '-Iperl', TEST], WORK)
    assert predecessor['status'] != 0 and 'separate current independent' in predecessor['stderr'], predecessor
    paths = set(subprocess.check_output(['git', 'ls-files', '--', 'bin', 'perl'], cwd=ROOT, text=True).splitlines())
    paths.update([TEST, BASE, PROBE, 'perl/FSM/ConcatenationSourceWidthSupport.pm',
                  str(Path(__file__).relative_to(ROOT))])
    hashes = {path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest()
              for path in sorted(paths) if (ROOT / path).is_file()}
    changed = {path for path, digest in prior['source_sha256'].items()
               if path.startswith(('bin/', 'perl/')) and hashes[path] != digest}
    assert changed == {'perl/FSM/ConcatenationSourceObservationSupport.pm'}, changed
    logs = {str(path.relative_to(ROOT)): path.read_text() for path in sorted(
        (ROOT / '.artifacts').glob('concat-source-widths-*.log'))}
    preparation = {str(path.relative_to(ROOT)): path.read_text() for path in sorted(
        (ROOT / '.artifacts').glob('concat-source-widths-*')) if path.suffix in {'.pl', '.pm', '.t', '.json'}}
    record = dict(schema_version=1, revision=REVISION, predecessor=predecessor,
                  predecessor_archive_sha256=hashlib.sha256(archive).hexdigest(),
                  settled_test_sha256=hashes[TEST], source_sha256=hashes,
                  baseline=baseline, observed=observed, preparation_logs=logs, preparation_sources=preparation,
                  corrections='First harness used local on a lexical variable. Next fixture declared but did not reference A/B, so parser materialized no source Signals. The next run exposed canonical flattened control-assignment snapshot representation and numeric checks changing detached observation JSON scalar kinds. Preserve the canonical shape and check eligibility on a separate copy. Initial logs/diagnostics retain. Production source observer now also rejects a defined scalar driving_ast rather than conflating it with absence.',
                  rederive='Canonical source preparation from actual current original factorizer/Core sources; complete native HDL/declaration/caller/refusal products and focused source/raw/canonical checks.',
                  falsify='Identical settled test against an exact predecessor production archive; independent W/X and fixed/mutable contrasts; signed/type/state/opaque/combined/computed/stale/foreign controls; early/canonical/late nonoperand getter mutation and mismatching getter values; malformed output, JSON kinds, clean retry and detached owner lifetime.',
                  durability='Tracked source/regression/probe/replay and exact input/source hashes; complete native products, first harness failures and diagnostic sources retained; Git capture boundary.',
                  limits='Private current source contracts only. No completed backend policy, generic sum/range/emission, generic override/runtime, public/corpus, VHDL backend or full .6/publication qualification.')
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('Independent current source contracts qualify; complete current/prior native products preserve; exact predecessor lacks the new API.')


if __name__ == '__main__':
    main()
