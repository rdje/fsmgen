"""Qualify the retained complete native response without a second server capture."""
import copy
import json
from html.parser import HTMLParser
from pathlib import Path

BASE = Path('docs/audits/record-value-current-helper-reader-20261005')


class MainText(HTMLParser):
    def __init__(self):
        super().__init__(); self.inside = False; self.parts = []
    def handle_starttag(self, tag, attrs):
        if tag == 'main': self.inside = True
    def handle_endtag(self, tag):
        if tag == 'main': self.inside = False
    def handle_data(self, data):
        if self.inside: self.parts.append(data)


def qualify(record, transform):
    assert type(record['chapter']['status']) is int and record['chapter']['status'] == 200
    assert type(record['missing']['status']) is int and record['missing']['status'] == 404
    assert type(record['server_status']) is int and record['server_status'] == -15, 'consumed terminated public server'
    assert record['built_chapter'] == record['chapter']['body'], 'exact fresh built/served chapter'
    parser = MainText(); parser.feed(record['chapter']['body'])
    text = ''.join(parser.parts)
    assert text == record['main_text'], 'whole independently parsed native main'
    expected = ' '.join(line for line in transform['reader_section'].splitlines() if not line.startswith('```'))
    assert ' '.join(expected.split()) in ' '.join(text.split()), 'complete unique source reader meaning and advertised command in native main'
    assert text.count(transform['reader_marker']) == 1


def main():
    record = json.loads((BASE / 'native-delivery.json').read_text())
    transform = json.loads((BASE / 'transform.json').read_text()); qualify(record, transform)
    refusals = []
    for name in ('lost-reader-command', 'wrong-source-guidance', 'Boolean-HTTP', 'unfinished-server', 'stale-build'):
        candidate = copy.deepcopy(record)
        if name == 'lost-reader-command':
            for key in ('built_chapter', 'main_text'): candidate[key] = candidate[key].replace(transform['new_command'], 'python3 -B missing-reader.py')
            candidate['chapter']['body'] = candidate['built_chapter']
        elif name == 'wrong-source-guidance':
            for key in ('built_chapter', 'main_text'): candidate[key] = candidate[key].replace('identity is', 'identity was').replace('historical census', 'current census')
            candidate['chapter']['body'] = candidate['built_chapter']
        elif name == 'Boolean-HTTP': candidate['chapter']['status'] = True
        elif name == 'unfinished-server': candidate['server_status'] = None
        else: candidate['built_chapter'] += '\nSTALE CONTROL\n'
        try: qualify(candidate, transform)
        except AssertionError as error: refusals.append({'control': name, 'refusal': str(error)})
        else: raise AssertionError('false-green native helper delivery: '+name)
    proof = {'controls': refusals, 'source_section': transform['reader_section'],
             'first_capture_qualification_gap': 'The original capture programme removes ```sh but the real source fence is ```bash. Native200/full content/built parity/missing404/terminated server were retained before that assertion refused. This independent fence-line normalizer qualifies those original bytes; no second capture is substituted.'}
    target = BASE / 'delivery-proofs.json'
    if target.exists(): assert json.loads(target.read_text()) == proof
    else: target.write_text(json.dumps(proof, sort_keys=True, indent=2)+'\n')
    print('PASS retained complete native helper reader delivery; genuine command/meaning/kind/stale/shutdown controls reject.')


if __name__ == '__main__': main()
