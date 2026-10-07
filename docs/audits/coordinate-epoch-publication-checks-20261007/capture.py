"""Capture the complete current source/query/native epoch without recapture."""
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, 'scripts')
import check_record_value_publication as current

BASE = Path('docs/audits/record-value-coordinate-epoch-publication-20261007')
BUILD = '.artifacts/coordinate-epoch-publication-book'
CONTROLLER = 'docs/audits/coordinate-epoch-publication-checks-20261007/capture.py'


def main():
    names = ('current-input.json', 'current-actual.json', 'native-input.html')
    current.require(not any((BASE / name).exists() for name in names), 'fresh epoch publication cannot overwrite actual products')
    prior = current.historical()
    canonical = current.sources()
    record = current.current_input(prior, canonical)
    instruments = {p:current.identity(Path(p).read_bytes()) for p in
        ('scripts/check_record_value_publication.py', 'scripts/record_value_epoch_fact.py',
         'scripts/book_source_references.py', CONTROLLER)}
    command = ['python3', '-B', 'scripts/check_record_value_publication.py', '--build', BUILD]
    result = subprocess.run(command, capture_output=True, text=True)
    (BASE / names[0]).write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    (BASE / names[1]).write_text(json.dumps(dict(command=command, status=result.returncode,
        stdout=result.stdout, stderr=result.stderr, instruments=instruments,
        input=current.identity((BASE / names[0]).read_bytes()),
        role='Fresh complete current tooling/source/query/census/native and committed historical epoch qualification; original evidence retained.'), sort_keys=True, indent=2) + '\n')
    current.require(type(result.returncode) is int and result.returncode == 0
        and result.stdout == current.SUCCESS and result.stderr == '', 'complete actual current epoch/native success')
    current.require(canonical == current.sources() and current.same(record, current.current_input(prior, canonical)),
        'complete current source/query epoch conserved across execution')
    current.require(all(current.same(pin, current.identity(Path(path).read_bytes()))
        for path, pin in instruments.items()), 'whole invocation instruments conserved across execution')
    html = Path(BUILD) / (prior['CHAPTER'].stem + '.html')
    current.check_native(html.read_text(), prior)
    (BASE / names[2]).write_bytes(html.read_bytes())
    print('PASS retained complete current epoch/native actual execution and stable input/instrument/source/query products; original captures untouched.')


if __name__ == '__main__':
    main()
