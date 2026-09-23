#!/usr/bin/env python3
"""Cross-check paragraph triage through a separate raw-HTML extraction path."""
import argparse
import html
import json
from pathlib import Path
import re
import runpy

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def raw_paragraph_lengths(document):
    main = re.search(r'<main\b[^>]*>(.*?)</main>', document, re.S)
    if not main:
        raise ValueError('missing main element')
    text = re.sub(r'<(pre|table|script|style)\b[^>]*>.*?</\1>', '', main.group(1), flags=re.S)
    lengths = []
    for paragraph in re.findall(r'<p\b[^>]*>(.*?)</p>', text, re.S):
        paragraph = re.sub(r'<br\b[^>]*>', ' ', paragraph)
        plain = html.unescape(re.sub(r'<[^>]+>', '', paragraph))
        count = len(re.findall(r'\S+', plain))
        if count:
            lengths.append(count)
    return lengths


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--build', required=True, type=Path)
    args = parser.parse_args()
    build = args.build.resolve()
    build.relative_to(ROOT)
    if build.stat().st_dev != ROOT.stat().st_dev:
        raise ValueError('off-volume build')
    producer = runpy.run_path(str(HERE / 'census.py'))
    record = json.loads((HERE / 'candidates.json').read_text())
    total = 0
    for filename in record['rendered_sha256']:
        document = (build / filename).read_text()
        independent = raw_paragraph_lengths(document)
        parsed = producer['Prose']()
        parsed.feed(document)
        expected = [r['words'] for r in parsed.rows() if r['selector'] == 'main p']
        if independent != expected:
            raise ValueError('paragraph length disagreement: '+filename)
        total += len(independent)
    if total != record['population']['p']:
        raise ValueError('saved paragraph population differs')
    # Independently labeled scope and block-boundary fixture, not a production count.
    fixture = '<p>outside</p><main><p>a <em>b</em></p><p>c<br>d</p><table><p>excluded</p></table></main>'
    if raw_paragraph_lengths(fixture) != [2, 2]:
        raise ValueError('oracle control differs')
    print(f'raw-HTML oracle: all {total} paragraph lengths agree; list-item and visual claims are outside this oracle')


if __name__ == '__main__':
    main()
