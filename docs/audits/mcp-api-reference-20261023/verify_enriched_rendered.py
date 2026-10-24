#!/usr/bin/env python3
"""Check the actual built identity table and generated POD interpretation."""
import argparse
import gzip
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path

BASE = Path(__file__).resolve().parent


class Guide(HTMLParser):
    def __init__(self):
        super().__init__()
        self.active = False
        self.rows = []
        self.cell = None
        self.row = None
        self.text = []

    def handle_starttag(self, tag, attrs):
        if tag == 'h3':
            self.active = dict(attrs).get('id') == 'enriched-contract-identity-and-routes'
        if self.active and tag == 'tr':
            self.row = []
        if self.active and tag in ('td', 'th'):
            self.cell = []

    def handle_data(self, data):
        if self.active:
            self.text.append(data)
            if self.cell is not None:
                self.cell.append(data)

    def handle_endtag(self, tag):
        if self.active and tag in ('td', 'th'):
            self.row.append(' '.join(''.join(self.cell).split()))
            self.cell = None
        if self.active and tag == 'tr':
            self.rows.append(self.row)
            self.row = None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('build', type=Path)
    args = parser.parse_args()
    guide = Guide()
    book = (args.build / '11-extensions-and-embedding.html').read_bytes()
    guide.feed(book.decode())
    packet = json.loads(gzip.decompress((BASE / 'enriched-identity-final.json.gz').read_bytes()))
    rows = [r for r in packet['records'] if not r['pointer'].endswith('/section_contract')]
    assert len(guide.rows) == len(rows) + 1 and all(len(r) == 4 for r in guide.rows)
    for saved, rendered in zip(rows, guide.rows[1:]):
        assert saved['pointer'][1:].replace('/', '.') in rendered[0]
        assert rendered[1] == saved['owner'].removeprefix('FSM::Support::')
        assert rendered[2] == saved['fields']['report_source']['value'].removeprefix('FSM::Support::')
    text = ' '.join(''.join(guide.text).split())
    for phrase in ('optional_when_tools_installed', 'no cli_aliases', 'no guidance',
                   'not MCP tool names', 'absent field', 'mcp_adapter_entrypoints'):
        assert phrase in text, phrase
    pod = (args.build / 'perl-api/FSM/Support/CapabilityManifest.html').read_bytes()
    assert b'Enriched identity and routes' in pod and b'mcp_adapter_entrypoints' in pod
    print(json.dumps({'rendered_table': guide.rows,
        'book_html_sha256': hashlib.sha256(book).hexdigest(),
        'pod_html_sha256': hashlib.sha256(pod).hexdigest(),
        'scope': 'Actual selected HTML table/content and generated POD; no browser or whole-manual visual qualification.',
        'reader_text': Path(__file__).read_text(),
        'reader_sha256': hashlib.sha256(Path(__file__).read_bytes()).hexdigest()}, sort_keys=True))


if __name__ == '__main__':
    main()
