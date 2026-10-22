#!/usr/bin/env python3
"""Verify timeout-stream glue against its exact retained predecessor, without launching a source workload."""
import gzip
import hashlib
import json
from pathlib import Path
import subprocess
from unittest.mock import patch

RECIPE = 'docs/audits/library-source-retention-20261022.py'
BASELINE = 'docs/audits/library-source-retention-before-20261022.json.gz'
OUTPUT = Path('docs/audits/library-source-timeout-control-20261022.json.gz')
ROOT = Path(__file__).resolve().parents[2]


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def load(text, label):
    namespace = {'__name__': 'retained_capture_unit', '__file__': str(ROOT / RECIPE)}
    exec(compile(text, label, 'exec'), namespace)
    return namespace


def main():
    before = json.loads(gzip.decompress(Path(BASELINE).read_bytes()))['inputs'][RECIPE]['text']
    after = Path(RECIPE).read_text()
    stdout, stderr = b'partial-json\n', b'original-timeout-diagnostic\n'
    record = {'owner': 'ISF-REDUCTION-DELIVERY.2.3.2.1.2.3.1', 'schema_version': 1,
              'recipe': Path(__file__).read_text(), 'before': {'text': before, 'sha256': sha(before.encode())},
              'after': {'text': after, 'sha256': sha(after.encode())}, 'results': {},
              'scope': 'Deterministic own capture-helper unit comparison. subprocess.run is replaced by a known TimeoutExpired carrying exact partial stdout/stderr, and a completed nonzero result. No process/source/HDL workload is launched. The actual prior one-second startup control remains failed and unqualified; the current traced native observation is retained separately. Historical partial streams and timeout cause cannot be reconstructed.'}
    try:
        for label, text in (('before', before), ('after', after)):
            namespace = load(text, 'retained-' + label + '-capture-producer')
            error = subprocess.TimeoutExpired(['fixture'], 60, output=stdout, stderr=stderr)
            with patch.object(subprocess, 'run', side_effect=error) as fake:
                try:
                    value = namespace['run'](['fixture'])
                    record['results'][label] = {'returned': value}
                except subprocess.TimeoutExpired:
                    record['results'][label] = {'raised': 'TimeoutExpired'}
                if fake.call_count != 1:
                    raise ValueError('unexpected launch count')
            if label == 'before':
                if record['results'][label] != {'raised': 'TimeoutExpired'}:
                    raise ValueError('original stream-loss mechanism not reproduced')
                continue
            value = record['results'][label]['returned']
            expected = {'argv': ['fixture'], 'exit': 'timeout', **{
                name: {'text': raw.decode(), 'raw_sha256': sha(raw), 'raw_bytes': len(raw)}
                for name, raw in (('stdout', stdout), ('stderr', stderr))}}
            if value != expected:
                raise ValueError('partial streams/status changed')
            completed = subprocess.CompletedProcess(['fixture'], 7, stdout=b'ordinary-out', stderr=b'ordinary-error')
            with patch.object(subprocess, 'run', return_value=completed):
                normal = namespace['run'](['fixture'])
            if normal['exit'] != 7 or normal['stdout']['text'] != 'ordinary-out' or normal['stderr']['text'] != 'ordinary-error':
                raise ValueError('ordinary capture regression')
            record['ordinary'] = normal
        record['qualified'] = True
    except BaseException as error:
        record['error'] = str(error).replace(str(ROOT), '<repo>')
        raise
    finally:
        with OUTPUT.open('xb') as stream:
            with gzip.GzipFile(fileobj=stream, mode='wb', mtime=0) as compressed:
                compressed.write((json.dumps(record, sort_keys=True, indent=2) + '\n').encode())
    print('capture timeout glue: PASS; exact predecessor raises, repair retains both streams and ordinary status')


if __name__ == '__main__':
    main()
