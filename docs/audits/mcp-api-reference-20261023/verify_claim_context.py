#!/usr/bin/env python3
"""Replay the exact original classifier against retained native paragraph proof."""
import gzip
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[3]


def verify(record):
    def original(path):
        return subprocess.check_output(['git', 'show', record['source_revision'] + ':' + path], cwd=ROOT)

    source = original(record['source_path'])
    classifier = original(record['classifier_path'])
    assert hashlib.sha256(source).hexdigest() == record['source_sha256']
    assert hashlib.sha256(classifier).hexdigest() == record['classifier_sha256']
    assert record['physical_line'] in source.decode().splitlines()
    text = classifier.decode()
    function = text[text.index('sub classify_prose {'):text.index('\nsub referenced_producers {')]
    assert function == record['classifier_function']
    program = ('use strict; use warnings; use JSON::PP;\n' + function +
               '\nmy $j=JSON::PP->new->utf8; local $/; my $r=$j->decode(<STDIN>); '
               'my @v=classify_prose($r->{line}); print $j->encode({classification=>$v[0],reason=>$v[1],tokens=>$v[2]});')
    actual = []
    for line in (record['physical_line'], 'Default ' + record['physical_line']):
        result = subprocess.run(['perl', '-e', program], cwd=ROOT, input=json.dumps({'line': line}).encode(),
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=10, check=True)
        assert not result.stderr
        actual.append(json.loads(result.stdout))
    assert actual == record['actual_classifications']
    assert [r['classification'] for r in actual] == ['incidental', 'actionable_review_debt']
    relative = Path(record['retained_native_render'])
    assert not relative.is_absolute() and '..' not in relative.parts
    html = gzip.decompress((ROOT / relative).read_bytes())
    assert hashlib.sha256(html).hexdigest() == record['native_render_sha256']

    class Paragraphs(HTMLParser):
        def __init__(self):
            super().__init__()
            self.inside, self.current, self.rows = False, '', []

        def handle_starttag(self, tag, attrs):
            if tag == 'p':
                self.inside, self.current = True, ''

        def handle_data(self, data):
            if self.inside:
                self.current += data

        def handle_endtag(self, tag):
            if tag == 'p' and self.inside:
                self.rows.append(self.current)
                self.inside = False

    parser = Paragraphs()
    parser.feed(html.decode())
    assert record['rendered_tag'] == 'p' and record['rendered_paragraph'] in parser.rows
    assert 'negative limits select\n10.' in record['rendered_paragraph']
    return {'original_false_incidental_reproduced': True, 'native_paragraph_retained': True,
            'repair_owner': record['owner']}


if __name__ == '__main__':
    assert len(sys.argv) == 2
    print(json.dumps(verify(json.loads(Path(sys.argv[1]).read_bytes())), indent=2))
