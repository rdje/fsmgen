"""Publish the entire qualified card/reader/book epoch in one owned slice."""
import ast
import hashlib
import json
import subprocess
import sys
from pathlib import Path

sys.path.insert(0, str(Path('scripts').resolve()))
import check_record_value_publication as current

BASE = Path('docs/audits/coordinate-current-publication-20261010')
REVISION = 'ca3dfac9d35b76d0a08fd97161fb0bef6570cd10'
DESCRIPTORS = Path('doctrine/live_document_size/archive_descriptors.jsonl')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')


def need(ok, cause):
    if not ok:
        raise ValueError(cause)


def git(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    need(result.returncode == 0 and not result.stderr, 'complete committed publication source')
    return result.stdout


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'), 'sha256': hashlib.sha256(raw).hexdigest()}


def counts(rows):
    return {'files': len(rows), 'bytes_total': sum(map(len, rows)), 'lines_total': sum(r.count(b'\n') for r in rows)}


def literal(raw, name):
    values = [ast.literal_eval(node.value) for node in ast.parse(raw).body
              if isinstance(node, ast.Assign) and any(isinstance(target, ast.Name) and target.id == name for target in node.targets)]
    need(len(values) == 1, 'unique complete original guide literal')
    return values[0]


def replace(text, old, new):
    need(text.count(old) == 1, 'unique reviewed complete book replacement: ' + old[:80])
    return text.replace(old, new, 1)


def main():
    need(not (BASE / 'publication.json').exists(), 'refuse to overwrite completed atomic publication')
    proposal = current.coordinate_fact.proposal()
    need(Path(current.coordinate_fact.PROPOSAL).read_bytes() == git('show', REVISION + ':' + current.coordinate_fact.PROPOSAL),
         'whole committed qualified proposal')
    old_namespace = {'__name__': 'previous_current', '__file__': str(Path('scripts/check_record_value_publication.py').resolve())}
    exec(compile(git('show', REVISION + ':scripts/check_record_value_publication.py'),
                 old_namespace['__file__'], 'exec'), old_namespace)
    prior = current.historical()
    cards = current.expected_cards(prior)
    need(cards == {p: row['text'] for p,row in proposal['cards'].items()}, 'whole exact qualified proposal admission')
    old_descriptors = git('show', REVISION + ':' + str(DESCRIPTORS))
    need(DESCRIPTORS.read_bytes() == old_descriptors, 'every existing archive descriptor remains exact')
    appended = []
    for path, row in proposal['cards'].items():
        raw = Path(path).read_bytes()
        need(raw == git('show', REVISION + ':' + path) and pin(raw) == row['original']
             and Path(row['locator']).read_bytes() == raw, 'complete exact original card and retained beforeimage')
        appended.append({'schema_version': 1, 'record_type': 'descriptor',
            'descriptor_id': 'coordinate-current-' + Path(path).stem + '-20261010',
            'surface_id': 'exact_history', 'former_path': path,
            'range_id': 'complete-card-before-qualified-original-coordinate-admission',
            'revision': proposal['revision'], **pin(raw), 'retrieval_kind': 'file',
            'retrieval_locator': row['locator'], 'current_pointer': path,
            'sealed_on': '2026-10-10', 'verifier': 'builtin:file'})
    chapters = {p: git('show', REVISION + ':' + p).decode() for p in
                ('docs/book/src/13k-isf-feature-support-matrix.md', 'docs/book/src/90-reference-map.md')}
    need(all(Path(p).read_text() == text for p,text in chapters.items()), 'stable whole book sources before publication')
    feature = chapters['docs/book/src/13k-isf-feature-support-matrix.md']
    feature = replace(feature, old_namespace['guide'](prior), current.guide(prior))
    parser_path = 'docs/audits/record-value-parser-path-publication-20261006/verify.py'
    feature = replace(feature, literal(git('show', REVISION + ':' + parser_path), 'GUIDE'), current.coordinate_fact.PARSER_GUIDE)
    reference = chapters['docs/book/src/90-reference-map.md']
    start = reference.index('The current-coordinate publication now has a qualified complete proposal.')
    end = reference.index('<div id="knowledge-map-architecture">', start)
    reference = reference[:start] + current.coordinate_fact.REFERENCE + reference[end:]
    reference = replace(reference,
        'Original-coordinate joining remains pending, with original private runtime\nmeanings and alias downstream still owned separately.',
        'At that source-only checkpoint, original-coordinate joining was still pending.\nOriginal private runtime meanings and alias downstream remain separately owned.')
    reference = replace(reference,
        'qualified; joining original raw coordinates remains the next owned step.',
        'qualified at that checkpoint; original raw-coordinate joining is qualified below.')
    proposed_book = {'docs/book/src/13k-isf-feature-support-matrix.md': feature.encode(),
                     'docs/book/src/90-reference-map.md': reference.encode()}
    paths = sorted(p for p in git('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/book/src').decode().splitlines()
                   if p.endswith('.md') and Path(p).parent == Path('docs/book/src'))
    need(paths == sorted(str(p) for p in Path('docs/book/src').glob('*.md')), 'whole unchanged book membership')
    before_rows = [git('show', REVISION + ':' + p) for p in paths]
    after_rows = [proposed_book.get(p, Path(p).read_bytes()) for p in paths]
    need([p for p,a,b in zip(paths,before_rows,after_rows) if a != b] == sorted(proposed_book), 'only affected complete book chapters change')
    old_book, new_book = counts(before_rows), counts(after_rows)
    records = list(map(json.loads, SURFACES.read_text().splitlines()))
    for row in records:
        if row.get('surface_id') == 'shipped_behavior':
            row['reference_contract']['aggregate_change'] = {
                'authority_id': 'COORDINATE-CURRENT-PUBLICATION-20261010', 'baseline': old_book,
                'delta': {k: new_book[k] - old_book[k] for k in old_book},
                'owner': (BASE / 'scope.txt').read_text().strip(),
                'rationale': 'Admit complete original own-coordinate facts and four-card current reader roles with exact retained source history, preserved questions/probes/locality and unchanged Knowledge Map authority; final whole closure remains separately owned.'}
    authenticated = current.coordinate_fact.authenticate()
    for path, text in cards.items():
        Path(path).write_text(text)
    DESCRIPTORS.write_bytes(old_descriptors + ''.join(json.dumps(r,sort_keys=True,separators=(',',':'))+'\n' for r in appended).encode())
    for path, raw in proposed_book.items():
        Path(path).write_bytes(raw)
    SURFACES.write_text(''.join(json.dumps(r,sort_keys=True)+'\n' for r in records))
    product = {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(),
        'proposal': pin(Path(current.coordinate_fact.PROPOSAL).read_bytes()), 'cards': {p:pin(t.encode()) for p,t in cards.items()},
        'descriptors': appended, 'original_descriptor_bytes': pin(old_descriptors),
        'chapters': {p:{'before':pin(chapters[p].encode()), 'after':pin(proposed_book[p]),
                       'original':chapters[p], 'current':proposed_book[p].decode()} for p in proposed_book},
        'book_before': old_book, 'book_after': new_book, 'authenticated_qualification': authenticated,
        'scope': 'Atomic current source/question/reader publication; final whole-publication closure and unmeasured private/external/address/native gaps remain owned.'}
    (BASE / 'publication.json').write_text(json.dumps(product,sort_keys=True,indent=2)+'\n')
    command = ['git','--no-replace-objects','log','-1','--format=%H %s','-S',
               'The current-coordinate publication now has a qualified complete proposal.','--','docs/book/src/90-reference-map.md']
    result = subprocess.run(command,capture_output=True,text=True)
    (BASE / 'root-cause.json').write_text(json.dumps({'command':command,'status':result.returncode,
        'stdout':result.stdout,'stderr':result.stderr},sort_keys=True,indent=2)+'\n')
    need(result.returncode == 0 and not result.stderr and result.stdout.startswith(REVISION), 'actual committed preparation and missing current admission locus')
    print('PASS complete atomic coordinate fact/reader/book admission, exact governed history and unchanged Knowledge Map authority.')


if __name__ == '__main__':
    main()
