"""Verify exact semantic book partition and preserve the rejected first layout."""
import argparse
import hashlib
import json
import subprocess

from common import BASE, ROOT, LOG, document, pin, write
import review

STAGES = ('split-layout', 'split-book', 'split-book-inspect', 'split-claims-write', 'split-claims-check', 'split-claim-review')


def layout():
    first = document(BASE / 'first-staged-gate/review.json')
    saved = {}
    for row in first['files']:
        body = (ROOT / row['retained_path']).read_bytes()
        assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
        saved[row['path']] = body
    streams = {}
    for row in first['outputs']:
        body = bytes.fromhex(row['raw_hex'])
        assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
        streams[row['path'].rsplit('.', 1)[-1]] = body
    assert streams['exit'] == b'1\n'
    assert b'[doctrine] FAIL: LIVE-DOCUMENT-SIZE' in streams['stderr']
    assert b'[doctrine] FAIL: README-ENTRYPOINT' in streams['stderr']
    plan = document(BASE / 'book-split-plan.json')
    original = saved[plan['source_chapter']].decode()
    segment = original[plan['segment_start']:plan['segment_end']]
    assert hashlib.sha256(segment.encode()).hexdigest() == plan['segment_sha256']
    assert segment.count('\n') == plan['segment_lines']
    assert (ROOT / plan['new_page']).read_text() == plan['new_page_prefix'] + segment + plan['new_page_suffix']
    assert (ROOT / plan['source_chapter']).read_text() == original[:plan['segment_start']] + plan['replacement'] + original[plan['segment_end']:]
    previous_summary = saved[plan['source_summary']].decode()
    assert previous_summary.startswith('# Summary\n\n') and previous_summary.count(plan['summary_anchor']) == 1
    expected_summary = previous_summary.replace('# Summary\n\n', '# Summary\n', 1).replace(
        plan['summary_anchor'], plan['summary_anchor'] + plan['summary_new_link'])
    assert (ROOT / plan['source_summary']).read_text() == expected_summary
    before = [json.loads(line) for line in saved['doctrine/live_document_size/surfaces.jsonl'].splitlines()]
    after = [json.loads(line) for line in (ROOT / 'doctrine/live_document_size/surfaces.jsonl').read_bytes().splitlines()]
    for rows in (before, after):
        next(x for x in rows if x.get('surface_id') == 'shipped_behavior')['reference_contract'].pop('aggregate_change')
    assert before == after
    surface = next(x for x in after if x.get('surface_id') == 'shipped_behavior')
    byte_limit = surface['baseline']['bytes_each'] + surface['transition']['max_growth']['bytes_each']
    assert len(saved[plan['source_chapter']]) > byte_limit
    revision = document(BASE / 'plan.json')['source_revision']
    old_paths = [path for path in subprocess.check_output(['git', 'ls-tree', '-r', '--name-only', revision,
                 '--', 'docs/book/src/'], cwd=ROOT).decode().splitlines() if path.endswith('.md')]
    paths = sorted(old_paths + [plan['new_page']])
    assert len(paths) == len(set(paths))
    current_paths = sorted(str(path.relative_to(ROOT)) for path in (ROOT / 'docs/book/src').glob('*.md'))
    assert current_paths == paths
    largest = max((ROOT / path).stat().st_size for path in paths)
    assert largest <= byte_limit
    index = surface['reference_contract']['mandatory_read']
    assert len(expected_summary.encode()) <= index['bytes_ceiling']
    assert expected_summary.count('\n') <= index['lines_ceiling']
    for row in document(BASE / 'split-pins.json'):
        assert pin(row['path']) == row
    return dict(exact_topic_text_preserved=True, prior_nonempty_navigation_preserved=True, unchanged_part_byte_allowance=byte_limit,
                first_chapter_bytes=len(saved[plan['source_chapter']]), current_chapter_bytes=(ROOT / plan['source_chapter']).stat().st_size,
                largest_current_part_bytes=largest, new_page_bytes=(ROOT / plan['new_page']).stat().st_size,
                current_book_files=len(paths), summary_lines=expected_summary.count('\n'), summary_bytes=len(expected_summary.encode()))


def verify():
    partition = layout()
    original_review = review.verify()
    assert original_review == document(BASE / 'review.json')
    claim = document(BASE / 'split-claim-review.json')
    assert claim['candidate_identities_and_semantics_unchanged'] and claim['dispositions_unchanged']
    captures = document(BASE / 'split-verification-outputs.json')
    assert [x['path'] for x in captures] == [str((LOG / (stage + '.' + ext)).relative_to(ROOT))
                                           for stage in STAGES for ext in ('stdout', 'stderr', 'exit')]
    streams = {}
    for row in captures:
        body = bytes.fromhex(row['raw_hex'])
        assert len(body) == row['size_bytes'] and hashlib.sha256(body).hexdigest() == row['sha256']
        streams[row['path'].rsplit('/', 1)[-1]] = body
    for stage in STAGES:
        assert streams[stage + '.exit'] == b'0\n'
    for row in claim['raw_outputs']:
        assert bytes.fromhex(row['raw_hex']) == streams[row['path'].rsplit('/', 1)[-1]]
    book = document(BASE / 'split-book-review.json')
    assert book == json.loads(streams['split-book-inspect.stdout'])
    assert book['exit_code'] == 0 and book['exact_output_absent']
    assert not (ROOT / book['output']).exists() and not (ROOT / book['output']).is_symlink()
    return dict(schema='fsmgen.inactive_lifetime_book_split_review.v1', owner=original_review['owner'],
                source_revision=original_review['source_revision'], partition=partition,
                original_model_review=pin(str((BASE / 'review.json').relative_to(ROOT))),
                original_failed_gate=pin(str((BASE / 'first-staged-gate/review.json').relative_to(ROOT))),
                final_claim_review=pin(str((BASE / 'split-claim-review.json').relative_to(ROOT))),
                final_book_review=pin(str((BASE / 'split-book-review.json').relative_to(ROOT))),
                raw_captures=len(captures), runtime_qualification=False,
                claim_legs=dict(rederivation='Reconstruct both final pages and complete navigation from the retained first layout; rederive all book metrics from Git and current source.',
                                falsification='Require the original layout to exceed the unchanged byte allowance and the final complete page set to satisfy it; original lifetime evidence retains its independent falsifiers.',
                                durability='Exact failed gate, prior layout, split plan and prospective hashes, first successful corrected render/claim outputs, original model review, saved-only verification and Git.'))


def main():
    parser = argparse.ArgumentParser()
    group = parser.add_mutually_exclusive_group()
    group.add_argument('--verify-layout', action='store_true')
    group.add_argument('--retain', action='store_true')
    args = parser.parse_args()
    if args.verify_layout:
        print(json.dumps(layout(), sort_keys=True)); return
    if args.retain:
        rows = []
        for stage in STAGES:
            for extension in ('stdout', 'stderr', 'exit'):
                path = LOG / (stage + '.' + extension)
                rows.append(dict(pin(str(path.relative_to(ROOT))), raw_hex=path.read_bytes().hex()))
        write(BASE / 'split-verification-outputs.json', rows)
    result = verify()
    if args.retain:
        write(BASE / 'split-review.json', result)
    else:
        assert document(BASE / 'split-review.json') == result
    print(json.dumps(result, sort_keys=True))


if __name__ == '__main__':
    main()
