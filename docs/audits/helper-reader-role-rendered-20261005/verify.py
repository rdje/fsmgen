"""Qualify the exact native apostrophe rendering without editing the first seal."""
import argparse
import copy
import hashlib
import importlib.util
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/helper-reader-role-rendered-20261005')
ROLE = Path('docs/audits/record-value-helper-reader-role-adapter-20261005')
spec = importlib.util.spec_from_file_location('retained_role_book_checker', ROLE / 'verify_book.py')
old = importlib.util.module_from_spec(spec); spec.loader.exec_module(old)
spec = importlib.util.spec_from_file_location('sealed_role_publisher', ROLE / 'publish_book.py')
publisher = importlib.util.module_from_spec(spec); spec.loader.exec_module(publisher)


def same(a, b):
    return json.dumps(a, sort_keys=True, allow_nan=False) == json.dumps(b, sort_keys=True, allow_nan=False)


def check(html, transform):
    assert transform['block'] == publisher.BLOCK, 'independent complete published role meaning'
    mains = re.findall(r'<main\b[^>]*>(.*?)</main>', html, re.S)
    assert len(mains) == 1, 'unique actual rendered chapter body'
    parser = old.Text(); parser.feed(mains[0])
    visible = ' '.join(' '.join(parser.parts).split())
    paragraphs = transform['block'].strip().replace('```bash\n', '').replace('```\n', '').split('\n\n')
    expected = [' '.join(paragraph.split()) for paragraph in paragraphs]
    # These exact prose tokens account for the observed native smart punctuation.
    # Code, command options, other punctuation and the source bytes stay exact.
    for before, after in (("reader's", 'reader’s'), ("helper's", 'helper’s')):
        assert expected[0].count(before) == 1, 'exact declared prose apostrophe source'
        expected[0] = expected[0].replace(before, after)
    assert all(visible.count(paragraph) == 1 for paragraph in expected), 'complete unique actual historical/current guidance and command'
    return expected


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--current', action='store_true')
    parser.add_argument('--build', default='.artifacts/helper-reader-role-adapter/book')
    args = parser.parse_args()
    source = json.loads((BASE / 'boundary.json').read_text())
    manifest = (ROLE / 'manifest.json').read_bytes()
    assert same(source['role_manifest'], {'bytes': len(manifest), 'sha256': hashlib.sha256(manifest).hexdigest()})
    role_pins = json.loads(manifest)
    assert set(role_pins) == {path.name for path in ROLE.iterdir()} - {'manifest.json'}
    for name, pin in role_pins.items():
        raw = (ROLE / name).read_bytes()
        assert same(pin, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
    transform = json.loads((ROLE / 'book-transform.json').read_text())
    assert source['transform'] == transform
    before = {path: subprocess.check_output(['git', 'show', transform['revision'] + ':' + path]) for path in transform['paths']}
    assert before[transform['path']].decode() == transform['before']
    assert transform['before'].replace(transform['marker'], transform['block'] + transform['marker']) == transform['after']
    after = {**before, transform['path']: transform['after'].encode()}
    assert old.metrics(before) == transform['authority']['before'] and old.metrics(after) == transform['authority']['after']
    html = (BASE / 'initial-rendered-chapter.html').read_text()
    expected = check(html, transform)
    initial = source['initial_receipt']
    assert (type(initial['status']) is int and initial['status'] == 1 and
            'AssertionError: complete rendered historical/current role guidance' in initial['stderr'])
    controls = []
    for name, candidate in [
        ('missing-main', html.replace('<main>', '<div>')),
        ('wrong-rendered-prose', html.replace('reader’s historical replay', 'reader’s fabricated replay')),
        ('wrong-command-role', html.replace('adapter.py --snapshot', 'adapter.py --current')),
        ('lost-current-scope', html.replace('does not qualify current', 'qualifies current')),
        ('unadmitted-straight-apostrophe', html.replace('reader’s historical replay', "reader's historical replay")),
    ]:
        assert candidate != html, 'actual rendered control changes input'
        try:
            check(candidate, transform)
        except AssertionError as error:
            controls.append({'control': name, 'status': 1, 'cause': str(error)})
        else:
            raise AssertionError('false-green rendered historical role: ' + name)
    borrowed = copy.deepcopy(transform)
    borrowed['block'] = borrowed['block'].replace('does not qualify current', 'qualifies current')
    coordinated = html.replace('does not qualify current', 'qualifies current')
    try:
        check(coordinated, borrowed)
    except AssertionError as error:
        assert str(error) == 'independent complete published role meaning'
        controls.append({'control': 'coordinated-render/source-scope', 'status': 1, 'cause': str(error)})
    else:
        raise AssertionError('false-green coordinated rendered role scope')
    if args.current:
        assert all(Path(path).read_bytes() == raw for path, raw in after.items()), 'whole current role-book source boundary'
        surface = next(row for row in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines()) if row.get('surface_id') == 'shipped_behavior')
        assert surface['reference_contract']['aggregate_change']['baseline'] == transform['authority']['before']
        assert surface['reference_contract']['aggregate_change']['delta'] == transform['authority']['delta']
        current = Path(args.build) / (Path(transform['path']).stem + '.html')
        assert check(current.read_text(), transform) == expected
    proof = {'expected_visible_paragraphs': expected, 'controls': controls,
             'scope': 'Exact source/aggregate and native rendered prose/command with only the two declared smart apostrophes; visual QA remains pending.'}
    target = BASE / 'proofs.json'
    if target.exists():
        assert same(json.loads(target.read_text()), proof)
    else:
        assert not (BASE / 'manifest.json').exists()
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    if (BASE / 'manifest.json').exists():
        pins = json.loads((BASE / 'manifest.json').read_text())
        assert set(pins) == {path.name for path in BASE.iterdir()} - {'manifest.json'}
        for name, pin in pins.items():
            raw = (BASE / name).read_bytes()
            assert same(pin, {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})
    print('PASS exact source/aggregate/rendered historical-role guidance and command with declared native smart apostrophes; original failure/seal retained, visual QA pending.')


if __name__ == '__main__':
    main()
