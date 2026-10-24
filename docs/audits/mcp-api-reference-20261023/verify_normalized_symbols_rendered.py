#!/usr/bin/env python3
"""Join both native symbol tables to the qualified field/value/subject census."""
import argparse
import gzip
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent


class SymbolView(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.tables = []
        self.row = None
        self.cell = None
        self.text = []

    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'normalized-symbol-family-subjects'
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
    packet = json.loads(gzip.decompress((BASE / 'normalized-symbols-final-qualified.json.gz').read_bytes()))
    view = SymbolView()
    view.feed(html.decode())
    assert len(view.tables) == 2
    roots = dict(view.tables[0][1:])
    assert roots == {'symbol_contract_': 'semantic.symbol_contract',
        'success_forward_ir_intent_hir_symbol_contract_': 'semantic.forward_ir.intent_hir.symbol_contract'}
    rows = {r[0]: r for r in view.tables[1][1:]}
    assert len(rows) == len(view.tables[1]) - 1 and all(len(r) == 4 for r in rows.values())
    expected_suffixes = {key.removeprefix('symbol_contract_') for key in packet['fields'] if key.startswith('symbol_contract_')}
    assert set(rows) == expected_suffixes
    for prefix, root in roots.items():
        for suffix, row in rows.items():
            field = packet['fields'][prefix + suffix]
            assert root + '.' + row[1] == field['subject']
            value = field['value']
            assert row[2] == (', '.join(value) if isinstance(value, list) else value)
    text = ' '.join(''.join(view.text).split())
    assert 'single-element arrays' in text and 'not a closed schema' in text
    assert b'Normalized symbol family subjects' in pod and b'member_payload_map' in pod
    print(json.dumps({'tables': view.tables, 'book_sha256': hashlib.sha256(html).hexdigest(),
        'pod_sha256': hashlib.sha256(pod).hexdigest(), 'reader_source': Path(__file__).read_text(),
        'scope': 'Selected actual native symbol tables and generated POD content only; not browser or whole-manual visual signoff.'}, sort_keys=True))


if __name__ == '__main__':
    main()
