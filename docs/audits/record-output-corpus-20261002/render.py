import hashlib
import json
from html.parser import HTMLParser
from pathlib import Path

class View(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids, self.text, self.blocks, self.rows = set(), [], [], []
        self.pre, self.row, self.cell = None, None, None
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs:
            self.ids.add(attrs['id'])
        if tag == 'pre':
            self.pre = []
        if tag == 'tr':
            self.row = []
        if tag in ['td', 'th']:
            self.cell = []
    def handle_endtag(self, tag):
        if tag == 'pre' and self.pre is not None:
            self.blocks.append(''.join(self.pre)); self.pre = None
        if tag in ['td', 'th'] and self.cell is not None:
            self.row.append(''.join(self.cell).strip()); self.cell = None
        if tag == 'tr' and self.row is not None:
            self.rows.append(self.row); self.row = None
    def handle_data(self, data):
        self.text.append(data)
        if self.pre is not None:
            self.pre.append(data)
        if self.cell is not None:
            self.cell.append(data)

work = Path('.artifacts/record-output-corpus')
parts = ['10-downstream-readiness-source.md', '11-downstream-actor-transactions.md',
         '12-downstream-rules-artifacts-reports.md', '13-downstream-diagnostics-conformance.md']
chapter = Path('docs/book/src/13i-downstream-integration.md').read_text()
assert [s for s in chapter.splitlines() if s.startswith('{{#include')] == [
    '{{#include ../../isf-spec/' + p + '}}' for p in parts]
page = Path('docs/book/book/13i-downstream-integration.html').read_bytes()
view = View(); view.feed(page.decode())
source = Path('docs/audits/record-output-predecessors-20261002/downstream-record-ports.isf').read_text()
assert source.rstrip() in [s.rstrip() for s in view.blocks], 'complete canonical record-port example'
assert 'packed-record-actor-ports' in view.ids
expected = [
    ['kind', '2', '9:8', '0', 'absent'],
    ['payload.data', '5', '7:3', '1', 'four_state'],
    ['payload.flags[0]', '1', '2:2', '0', 'absent'],
    ['payload.flags[1]', '2', '1:0', '0', 'two_state']]
assert all(row in view.rows for row in expected), 'complete literal maintained output packing table'
text = ''.join(view.text)
for old in ['Record source admission remains refused.', 'record output and root-list interface ports;']:
    assert old not in text, 'old whole-record refusal remains'
assert any('--emit-schedule-json isf/record_output.isf' in block and '--language systemverilog' in block
           for block in view.blocks), 'maintained commands rendered together'
assert 'Output simulation, generated output mappings' in text
paths = ['docs/isf-spec/' + p for p in parts] + [
    'docs/isf-spec/01-purpose-source-timing.md', 'docs/isf-spec/02-interface-transactions.md',
    'docs/isf-spec/22-public-interface-reports-evolution.md',
    'docs/book/src/13j-type-enum-aggregate.md', 'docs/book/src/13k-isf-feature-support-matrix.md']
records = {p: {'text': Path(p).read_text(), 'sha256': hashlib.sha256(Path(p).read_bytes()).hexdigest()} for p in paths}
(work / 'render.html').write_bytes(page)
(work / 'render.json').write_text(json.dumps(dict(chapter=chapter, parts=records, leaf_rows=expected,
    complete_canonical_example=True, maintained_commands=True, residual_refusals_absent=True,
    render_sha256=hashlib.sha256(page).hexdigest()), indent=2, sort_keys=True) + '\n')
print('Canonical downstream includes, full example, literal output packing and maintained commands render; residual old whole-output refusals are absent.')
