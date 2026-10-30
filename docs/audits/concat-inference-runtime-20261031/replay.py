"""Replay returned-AST identity attribution and complete native conservation."""
import argparse
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
HERE = Path(__file__).resolve().parent
TEST = 't/2280-concatenation-inference-events.t'
CHANGED = {'perl/FSM/ConcatenationInferenceSupport.pm',
           'perl/FSM/HDL/FlattenedDT/Backend/SystemVerilog/IntermediateSignalWidthSupport.pm'}


def run(command):
    result = subprocess.run(command, cwd=ROOT, capture_output=True, text=True)
    return dict(command=command, status=result.returncode, stdout=result.stdout, stderr=result.stderr)


def normalize(value):
    if isinstance(value, str):
        return re.sub(r'^// Date:.*\n', '// Date: <normalized>\n', value, flags=re.M)
    if isinstance(value, list):
        return [normalize(item) for item in value]
    if isinstance(value, dict):
        return {key: normalize(item) for key, item in value.items()}
    return value


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--green-log', help='Consume the just-run check at a repository-relative path.')
    args = parser.parse_args()
    before = json.loads(gzip.decompress((HERE / 'before.json.gz').read_bytes()))
    assert before['test'].encode() == (ROOT / TEST).read_bytes(), 'identical settled regression'
    assert 'Failed test \'foreign_runtime cannot mint\'' in before['red_log'] and 'Result: FAIL' in before['red_log']
    assert not before['changed_production_paths']
    for path, digest in before['source_sha256'].items():
        source = subprocess.check_output(['git', 'show', f"{before['revision']}:{path}"], cwd=ROOT) if path in CHANGED else (ROOT / path).read_bytes()
        assert hashlib.sha256(source).hexdigest() == digest, path
    if args.green_log:
        log = ROOT / args.green_log
        assert not Path(args.green_log).is_absolute() and '..' not in Path(args.green_log).parts
        assert log.resolve().is_relative_to(ROOT) and log.stat().st_dev == ROOT.stat().st_dev
        green = dict(log=args.green_log, stdout=log.read_text())
    else:
        green = run(['prove', '-Iperl', TEST])
        assert green['status'] == 0, green
    assert 'All tests successful' in green['stdout'] and 'Result: PASS' in green['stdout']
    native = run(['perl', '-Iperl', 'docs/audits/concat-guard-capture-20261030/probe.pl'])
    assert native['status'] == 0, native
    prior_path = ROOT / 'docs/audits/concat-inference-events-20261031/evidence.json.gz'
    prior = json.loads(gzip.decompress(prior_path.read_bytes()))
    assert normalize(json.loads(native['stdout'])) == normalize(json.loads(prior['native']['stdout']))
    paths = sorted(CHANGED | {TEST, str(Path(__file__).relative_to(ROOT)),
        str((HERE / 'before.json.gz').relative_to(ROOT)), str(prior_path.relative_to(ROOT)),
        'docs/audits/concat-guard-capture-20261030/probe.pl'})
    record = dict(schema_version=1, before_revision=before['revision'], native=native, green=green,
                  source_sha256={path: hashlib.sha256((ROOT / path).read_bytes()).hexdigest() for path in paths},
                  rederive='Actual equal-sum foreign recovery return leaves the original stored runtime AST unchanged. The controlled pre-fix run wrongly installs intrinsic authority; the identical corrected regression withholds it while positive original/repeat controls pass.',
                  falsify='Same settled source fails before and passes after the direct actual-return identity check. Native loaded-module path/hash and unchanged production census authenticate the pre-fix boundary. Complete current/prior native caller/HDL/declaration/contextual-refusal products agree with Date-only normalization.',
                  durability='Tracked immutable before source/test/log/hash and loaded witness; current source/test/replay/complete native products and exact dependency identities; Git task and API/book contracts.',
                  limits='Trusted built-in point-in-time private event observations. Owned collection publication/completion, symbolic sum/range/emission and full compiler/runtime/publication qualification remain open.')
    with gzip.GzipFile(filename=str(HERE / 'evidence.json.gz'), mode='wb', mtime=0) as stream:
        stream.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('Identical foreign-return control fails before and passes after; complete native products preserve.')


if __name__ == '__main__':
    main()
