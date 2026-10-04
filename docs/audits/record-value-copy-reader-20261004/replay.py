"""Replay exact sealed probe sources into a newly created same-volume fixture."""
import argparse
import json
import subprocess
import tempfile
from pathlib import Path

# Load the tracked reader without creating bytecode inside either sealed archive.
reader = {'__name__': 'qualified_reader'}
exec(compile(Path('docs/audits/record-value-copy-reader-20261004/verify.py').read_bytes(),
             'docs/audits/record-value-copy-reader-20261004/verify.py', 'exec'), reader)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--out')
    args = parser.parse_args()
    output = Path(args.out) if args.out else None
    root = Path.cwd().resolve()
    require = reader['require']
    if output is not None:
        require(not output.is_absolute() and '..' not in output.parts,
                'output must be repository-relative')
        require(output.parent in (reader['BASE'], Path('.artifacts/record-value-copy-reader-20261004'))
                and output.resolve().is_relative_to(root), 'output containment')
        require(not output.exists(), 'replay receipts are never overwritten')
    reader['authenticate']()
    original = reader['check_population'](reader['CAPTURE'], '.')
    scratch = Path('.artifacts/record-value-copy-reader-20261004')
    scratch.mkdir(parents=True, exist_ok=True)
    require(scratch.resolve().is_relative_to(root)
            and scratch.stat().st_dev == root.stat().st_dev, 'same-volume fixture root')
    fixture = Path(tempfile.mkdtemp(prefix='replay-', dir=scratch)).resolve().relative_to(root)
    if output is None:
        output = fixture / 'replay-receipt.json'
    base = fixture / reader['CAPTURE']
    base.mkdir(parents=True)
    for name, body in reader['load'](reader['BASE'] / 'source-contract.json')['programs'].items():
        (base / name).write_bytes(body.encode())
    receipts, streams = [], []
    observation = {'fixture': str(fixture), 'same_volume': True, 'receipts': receipts,
                   'streams': streams, 'records': {}, 'controls': [],
                   'source_controls': [], 'qualification': 'pending'}

    def save():
        output.write_text(json.dumps(observation, sort_keys=True, indent=2) + '\n')

    save()  # A failed native execution retains its real fixture and first receipt.
    for mode in reader['MODES']:
        command = ['perl', str(reader['CAPTURE'] / 'probe.pl'), mode,
                   str(reader['CAPTURE'] / (mode + '.json'))]
        run = subprocess.run(command, cwd=fixture, text=True, capture_output=True, timeout=60)
        receipt = {'command': command, 'working_directory': str(fixture),
                   'status': run.returncode, 'output': run.stdout + run.stderr,
                   'programs': {n: reader['identity']((base / n).read_bytes())
                                for n in ('probe.pl', 'candidate.pl')}}
        receipts.append(receipt)
        streams.append({'mode': mode, 'stdout': run.stdout, 'stderr': run.stderr})
        if (base / (mode + '.json')).exists():
            observation['records'][mode] = reader['load'](base / (mode + '.json'))
        save()
        require(mode in observation['records'], 'native producer failed before capture')
        reader['check_record'](observation['records'][mode], mode)
        reader['check_receipt'](receipt, observation['records'][mode], str(fixture))
    (base / 'native-receipts.json').write_text(json.dumps(receipts, sort_keys=True, indent=2) + '\n')
    fresh = reader['check_population'](base, str(fixture))
    observation['controls'] = reader['reader_controls'](fresh)
    observation['source_controls'] = reader['source_controls']()
    reader['check_replay'](observation, original)
    for name in ('probe.pl', 'candidate.pl'):
        require((base / name).read_bytes() == (reader['CAPTURE'] / name).read_bytes(),
                'fresh source afterimage drift')
    reader['authenticate']()
    observation['qualification'] = 'PASS'
    save()
    print('PASS fresh exact-source seven-mode native replay and independent complete graph/cause/TAP controls: ' + str(output))


if __name__ == '__main__':
    main()
