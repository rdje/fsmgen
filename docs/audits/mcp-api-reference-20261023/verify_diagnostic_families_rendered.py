#!/usr/bin/env python3
"""Join the selected native HTML tables and generated POD to saved subjects."""
import argparse
import gzip
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent


class Tables(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.tables = []
        self.row = None
        self.cell = None
        self.text = []

    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'diagnostic-report-and-registry-families'
        if self.active and tag == 'table':
            self.tables.append([])
        if self.active and tag == 'tr':
            self.row = []
        if self.active and tag in ('th', 'td'):
            self.cell = []

    def handle_data(self, value):
        if self.active:
            self.text.append(value)
            if self.cell is not None:
                self.cell.append(value)

    def handle_endtag(self, tag):
        if self.active and tag in ('th', 'td'):
            self.row.append(' '.join(''.join(self.cell).split()))
            self.cell = None
        if self.active and tag == 'tr':
            self.tables[-1].append(self.row)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('build', type=Path)
    args = parser.parse_args()
    html = (args.build / '11-extensions-and-embedding.html').read_bytes()
    pod = (args.build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    packet = json.loads(gzip.decompress((BASE / 'diagnostic-families-qualified.json.gz').read_bytes()))
    records = {r['pointer'].rsplit('/', 1)[1]: r for r in packet['records']}
    view = Tables()
    view.feed(html.decode())
    assert len(view.tables) == 3 and all(len(row) == 2 for table in view.tables for row in table)
    excluded = {'owner_namespaces', 'base_keys_by_subject', 'same_named_mirrors', 'same_named_owner_mirror'}
    check = records['check_json']['fields']
    assert {row[0] for row in view.tables[0][1:]} == {name for name, field in check.items() if field['rule'] not in excluded}
    assert dict(view.tables[1][1:]) == {name: value.removeprefix('FSM::Support::') for name, value in check['nested_contract_source_map']['value'].items()}
    assert {row[0] for row in view.tables[2][1:]} == set(records['stable_code_registry']['fields'])
    text = ' '.join(''.join(view.text).split())
    for phrase in ('name-to-contract object', 'not an array', 'not a closed schema',
                   'conditional additions', 'null code', 'not field names'):
        assert phrase in text, phrase
    assert b'Diagnostic report and registry families' in pod and b'source_optional_fields' in pod
    print(json.dumps({'tables': view.tables, 'book_sha256': hashlib.sha256(html).hexdigest(),
        'pod_sha256': hashlib.sha256(pod).hexdigest(), 'reader_source': Path(__file__).read_text(),
        'scope': 'Selected actual native HTML table/content and POD rendering; browser/whole-manual visual review remains pending.'}, sort_keys=True))


if __name__ == '__main__':
    main()
