#!/usr/bin/env python3
"""Join the selected native envelope tables to qualified metadata subjects."""
import argparse
import gzip
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent


class Envelope(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.tables = []
        self.row = None
        self.cell = None
        self.text = []

    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'normalized-report-envelope-families'
        if self.active and tag == 'table':
            self.tables.append([])
        if self.active and tag == 'tr':
            self.row = []
        if self.active and tag in ('td', 'th'):
            self.cell = []

    def handle_data(self, value):
        if self.active:
            self.text.append(value)
            if self.cell is not None:
                self.cell.append(value)

    def handle_endtag(self, tag):
        if self.active and tag in ('td', 'th'):
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
    packet = json.loads(gzip.decompress((BASE / 'normalized-envelope-qualified.json.gz').read_bytes()))
    view = Envelope()
    view.feed(html.decode())
    assert len(view.tables) == 2 and all(len(row) == 2 for table in view.tables for row in table)
    fields = packet['fields']
    assert {row[0] for row in view.tables[0][1:]} == {key for key in fields if not key.endswith('_contract_source')}
    owners = {key.removesuffix('_contract_source'): row['value'].removeprefix('FSM::Support::')
              for key, row in fields.items() if key.endswith('_contract_source')}
    assert dict(view.tables[1][1:]) == owners
    text = ' '.join(''.join(view.text).split()).casefold()
    for phrase in ('report-level', 'success-only', 'first diagnostic', 'not a closed schema', 'semantic_layers'):
        assert phrase in text, phrase
    assert b'Normalized report-envelope families' in pod and b'matched_failure_support_accounting_presence_keys' in pod
    print(json.dumps({'tables': view.tables, 'book_sha256': hashlib.sha256(html).hexdigest(),
        'pod_sha256': hashlib.sha256(pod).hexdigest(), 'reader_source': Path(__file__).read_text(),
        'scope': 'Selected actual native HTML table/content and generated POD; not browser or whole-manual visual qualification.'}, sort_keys=True))


if __name__ == '__main__':
    main()
