"""Discovery only: byte-preserving named spans, not Perl semantic parsing."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path(__file__).parent
tracked = set(filter(None, subprocess.check_output(
    ['git', 'ls-files', '-z', 't', 'perl', 'scripts', 'bin']).decode().split('\0')))
files = []
for name in sorted(tracked):
    path = Path(name)
    if not path.is_file():
        continue
    raw = path.read_bytes()
    if path.suffix in ('.t', '.pm', '.pl', '.py') or re.match(rb'#![^\n]*perl', raw):
        files.append(name)

records, encodings, producers = [], [], {}
for name in files:
    raw = Path(name).read_bytes()
    producers[name] = {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}
    try:
        raw.decode('utf-8')
    except UnicodeDecodeError as error:
        encodings.append({'path': name, 'offset': error.start,
                          'policy': 'ASCII discovery on original bytes; JSON surrogateescape preserves non-UTF8 bytes'})
    for start in re.finditer(rb'(?m)^sub\s+([A-Za-z_]\w*)\b', raw):
        line_end = raw.find(b'\n', start.start())
        definition = raw[start.start():line_end if line_end != -1 else len(raw)]
        if definition.rstrip().endswith(b'}'):
            end = line_end if line_end != -1 else len(raw)
        else:
            close = re.search(rb'(?m)^}\s*(?:#.*)?$', raw[start.end():])
            if not close:
                continue
            end = start.end() + close.end()
        span = raw[start.start():end]
        if not re.search(rb'\b(?:like|unlike)\s*\(|\$@\s*=~', span):
            continue
        if not re.search(rb'\b(?:eval|diagnostic|error)\b|\$@', span):
            continue
        function = start.group(1).decode('ascii')
        records.append({'path': name, 'function': function,
                        'line': raw[:start.start()].count(b'\n') + 1,
                        'span_sha256': hashlib.sha256(span).hexdigest(),
                        'span': span.decode('utf-8', 'surrogateescape'),
                        'named_refusal_helper': bool(re.match(r'(?:refus|reject|fail|declin)', function)),
                        'classification': 'unreviewed discovery candidate'})

(BASE / 'candidates.json').write_text(json.dumps({
    'baseline': subprocess.check_output(['git', 'rev-parse', 'HEAD']).decode().strip(),
    'files': files, 'producers': producers, 'encoding_observations': encodings,
    'records': records,
    'scope': 'Named lexical spans with exception text and regex assertions. No anonymous/top-level '
    'or cold-consumer completeness, parsed-function boundaries or defect signoff is claimed.'},
    sort_keys=True, indent=2) + '\n')
print(json.dumps({'discovery_files': len(files), 'candidate_spans': len(records),
                  'named_refusal_spans': sum(row['named_refusal_helper'] for row in records),
                  'encoding_observations': encodings}, sort_keys=True))
