"""Execute every retained canonical probe, with complete actual results."""
import hashlib
import json
import shlex
import subprocess
from pathlib import Path

PATHS = ('docs/knowledge/mdbook-build-destination-locality.md',)


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    results = []
    for path in PATHS:
        lines = Path(path).read_text().split('---\n')[1].splitlines()
        index = next(i for i, line in enumerate(lines) if line.startswith('reverify: '))
        value = lines[index][len('reverify: '):]
        if value == '>-':
            parts = []
            for line in lines[index + 1:]:
                if not line.startswith('  '):
                    break
                parts.append(line.strip())
            value = ' '.join(parts)
        programme_paths = {path} | {s for s in shlex.split(value) if Path(s).is_file()}
        identities = {p:pin(Path(p).read_bytes()) for p in sorted(programme_paths)}
        command = ['bash', '-c', value]
        run = subprocess.run(command, capture_output=True, text=True)
        row = {'source': path, 'command': command, 'status': run.returncode,
               'stdout': run.stdout, 'stderr': run.stderr, 'instruments': identities}
        print(json.dumps(row, sort_keys=True), flush=True)
        if run.returncode or identities != {p:pin(Path(p).read_bytes()) for p in sorted(programme_paths)}:
            raise ValueError('complete retained canonical reverify route and stable instruments')
        results.append(path)
    print(json.dumps({'result': 'PASS every original executable probe and new expression route',
                      'sources': results}, sort_keys=True))


if __name__ == '__main__':
    main()
