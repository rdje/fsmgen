"""Retain one actual task command and its complete output, without overwrites."""
import json
import subprocess
import sys
from pathlib import Path


def main():
    output, *command = sys.argv[1:]
    path = Path(output)
    root = Path.cwd().resolve()
    assert command and not path.is_absolute() and '..' not in path.parts
    assert path.parent.resolve().is_relative_to(root) and not path.exists()
    result = subprocess.run(command, capture_output=True)
    path.write_text(json.dumps(dict(command=command, status=result.returncode,
        stdout=result.stdout.decode(), stderr=result.stderr.decode()), sort_keys=True, indent=2) + '\n')
    print(result.stdout.decode(), end='')
    print(result.stderr.decode(), end='', file=sys.stderr)
    raise SystemExit(result.returncode)


if __name__ == '__main__':
    main()
