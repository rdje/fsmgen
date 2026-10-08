"""Run only declared saved-data readers, retaining every fresh actual receipt."""
import subprocess
import sys
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-qualification-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-public-qualification-20261008/verify.py')


def main():
    namespace = {'__name__': 'public_saved_reader_schedule'}
    exec(compile(MODEL.read_bytes(), str(MODEL), 'exec'), namespace)
    before = namespace['binding']()
    namespace['save']('binding.json', before)
    for model_name, reader_name, date in namespace['DOMAINS']:
        model, reader = namespace['domain'](model_name, reader_name, date)
        for label, script in (('model', model / 'verify.py'), ('reader', reader / 'verify_saved.py')):
            name = model_name + '-' + label + '.json'
            if (BASE / name).exists():
                raise ValueError('fresh actual receipt already exists; consume it before any explicit retry: ' + name)
            actual = subprocess.run(['python3', '-B', str(BASE / 'run.py'), name,
                                     'python3', '-B', str(script)], capture_output=True, text=True)
            print(name, 'status=' + str(actual.returncode), flush=True)
            if actual.returncode:
                print(actual.stdout, end='')
                print(actual.stderr, end='', file=sys.stderr)
                raise SystemExit(actual.returncode)
    namespace['need'](namespace['same'](namespace['binding'](), before),
                      'all historical source/programme/product/result bytes conserve after fresh readers')


if __name__ == '__main__':
    main()
