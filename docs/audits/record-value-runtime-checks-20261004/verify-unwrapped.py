"""Join exact raw unwrapped TAP to every original observed native leaf."""
import json
import re
from pathlib import Path

BASE = Path(__file__).parent
raw = json.loads((BASE / 'focused-raw.json').read_text())
assert raw['command'] == ('scripts/run_with_ram_guard.sh -- prove -v -Iperl -It/lib '
    't/1986-isf-record-port-value-gates.t t/1303-isf-public-live-book-paths-audit.t '
    't/1305-isf-book-feature-matrix-audit.t')
text = raw['output']
projection = ''.join(line.rstrip(' \t\r\n') + '\n' for line in text.splitlines(keepends=True))
assert projection == (BASE / 'focused.txt').read_text(), 'readable margins must preserve exact raw evidence'
block = text.split('t/1986-isf-record-port-value-gates.t')[1].split('t/1303-isf-public-live-book-paths-audit.t')[0]
leaf = re.findall(r'^    (not )?ok \d+ - (.*)$', block, re.M)
observed = json.loads(Path('docs/audits/record-value-runtime-20261004/ordinary.json').read_text())
assert len(leaf) == 125 and all(not status for status, _ in leaf)
assert [label for _, label in leaf] == [row['label'] for row in observed['consumers']]
assert (BASE / 'focused.status').read_text() == '0\n'
assert 'All tests successful.' in text and 'Files=3, Tests=318,' in text
print('PASS all125 original observed leaf labels/pass outcomes exactly match complete '
    'unwrapped T1986 native TAP. Exact raw log retained; readable projection removes only '
    'line margins. Original top-level10 subtests are separate units.')
