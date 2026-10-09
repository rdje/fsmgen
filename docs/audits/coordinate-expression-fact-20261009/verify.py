"""Independent complete source/question/authority and real archive controls.

Semantic correspondence is explicitly reviewed; exact source and current
coverage are mechanically checked. This is a dated atomic-publication audit.
"""
import copy
import hashlib
import json
import re
import shutil
import subprocess
import uuid
from pathlib import Path

BASE = Path('docs/audits/coordinate-expression-fact-20261009')
REVISION = '6b3783bb03f5f0d65619dddbba31ea4fda3d0890'
CARD = 'docs/knowledge/mdbook-build-destination-locality.md'
QUESTION = 'why can Perl caller lines follow pattern or predicate expressions?'
PROBE = 'docs/audits/coordinate-expression-alternative-checks-20261009/verify_alternatives.py'


def need(ok, why):
    if not ok:
        raise ValueError(why)


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'),
            'sha256': hashlib.sha256(raw).hexdigest()}


def native(*args, data=None):
    run = subprocess.run(['git', '--no-replace-objects', *args], input=data, capture_output=True)
    need(run.returncode == 0 and not run.stderr, 'independent complete Git source')
    return run.stdout


def blobs(paths):
    raw = native('cat-file', '--batch', data=''.join(REVISION + ':' + p + '\n' for p in paths).encode())
    result, offset = {}, 0
    for path in paths:
        end = raw.index(b'\n', offset)
        oid, kind, size = raw[offset:end].split()
        need(kind == b'blob', 'complete fixed source blob')
        offset = end + 1
        size = int(size)
        result[path] = raw[offset:offset + size]
        need(raw[offset + size:offset + size + 1] == b'\n', 'complete source framing')
        offset += size + 1
    need(offset == len(raw), 'complete fixed source consumption')
    return result


def metrics(rows):
    values = list(rows.values())
    return {'files': len(values), 'bytes_total': sum(map(len, values)),
            'lines_total': sum(r.count(b'\n') for r in values),
            'bytes_each': max(map(len, values)),
            'lines_each': max(r.count(b'\n') for r in values),
            'line_bytes_each': max(len(line.rstrip(b'\r')) for r in values for line in r.split(b'\n'))}


def normalize(text):
    return ' '.join(text.split())


def paragraph_check(original, current, correspondence):
    old_front, old_body = original.decode().rsplit('---\n', 1)
    new_front, new_body = current.decode().rsplit('---\n', 1)
    old_parts, new_parts = old_body.strip().split('\n\n'), new_body.strip().split('\n\n')
    rows = correspondence['paragraphs']
    need([r['source'] for r in rows] == old_parts, 'complete original semantic paragraph domain')
    need(len(new_parts) == len(old_parts) + 1, 'complete current semantic paragraph domain')
    need([normalize(r['current']) for r in rows] == [normalize(p) for p in new_parts[:-1]],
         'complete reviewed current semantic correspondence')
    expected = ('Public caller/compiler fixtures: helper pattern starts; live guard predicate endings; '
                'constant-only guard statement labels. Conditional source alternatives; '
                'original/private/toolchain coordinates unmeasured. [Probe](../audits/'
                'coordinate-expression-alternative-checks-20261009/verify_alternatives.py).')
    need(new_parts[-1] == expected, 'complete conditional expression fact and public probe')
    old_front = old_front.replace('date: 2026-10-08\n',
        '  - "' + QUESTION + '"\ndate: 2026-10-09\n', 1)
    need(old_front == new_front, 'every original metadata question evidence and probe retained')


def check(publication, originals, current, surface):
    need(publication['revision'] == REVISION and set(publication['sources']) == {CARD},
         'complete admitted original card scope')
    for path, original in originals.items():
        need(publication['sources'][path] == pin(original), 'complete original source identity')
        need(publication['current'][path] == pin(current[path]), 'complete current publication identity')
        paragraph_check(original, current[path], publication['semantic_mapping'][path])
    for dimension in ('bytes', 'lines'):
        before = sum(pin(raw)[dimension] for raw in originals.values())
        after = sum(pin(raw)[dimension] for raw in current.values())
        need(publication['products']['live_dimensions']['before'][dimension] == before
             and publication['products']['live_dimensions']['after'][dimension] == after
             and after <= before, 'independent non-growing semantic working set')
    need(publication['products']['unretained_residue']['bytes'] == 0,
         'complete source retrieval leaves no unretained bytes')
    previous = next(r for r in map(json.loads, native('show', REVISION + ':doctrine/live_document_size/surfaces.jsonl').splitlines())
                    if r.get('surface_id') == 'knowledge_cards')
    need(previous == surface, 'whole Knowledge Map authority unchanged')


def archive_fixtures(descriptors):
    root = Path('.artifacts/tmp/archive-transport-fact') / uuid.uuid4().hex
    root.mkdir(parents=True)
    need(root.stat().st_dev == Path('.').stat().st_dev, 'same-volume owned fixtures')
    results = []
    surface = next(r for r in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines())
                   if r.get('surface_id') == 'exact_history')
    surface.update(targets=['archive'], verifier='archive:archive')
    header = {'record_type': 'registry', 'schema_version': 1,
              'max_records': 8, 'max_bytes': 8192, 'max_record_bytes': 2048}
    try:
        for name in ('valid', 'missing-source', 'changed-source-byte', 'wrong-digest'):
            fixture = root / name
            fixture.mkdir(); (fixture / 'archive').mkdir()
            rows = copy.deepcopy(descriptors)
            for row in rows:
                for field in ('retrieval_locator', 'current_pointer'):
                    target = fixture / row[field]
                    target.parent.mkdir(parents=True, exist_ok=True)
                    shutil.copyfile(row[field], target)
            if name == 'missing-source':
                (fixture / rows[0]['retrieval_locator']).unlink()
            elif name == 'changed-source-byte':
                target = fixture / rows[0]['retrieval_locator']
                raw = target.read_bytes()
                target.write_bytes(bytes([raw[0] ^ 1]) + raw[1:])
            elif name == 'wrong-digest':
                rows[0]['sha256'] = '0' * 64
            (fixture / 'surfaces.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in [header, surface]))
            (fixture / 'archives.jsonl').write_text(''.join(json.dumps(r) + '\n' for r in [header, *rows]))
            command = ['perl', 'live-document-size/scripts/check_live_document_size.pl',
                       '--root', str(fixture), '--registry', 'surfaces.jsonl', '--archives', 'archives.jsonl']
            for flag in ('routes', 'ledgers', 'evidence-maps', 'retention-contracts', 'derived-state'):
                (fixture / (flag + '.jsonl')).write_text(json.dumps(header) + '\n')
                command.extend(['--' + flag, flag + '.jsonl'])
            run = subprocess.run(command, capture_output=True, text=True)
            print(json.dumps({'native_archive_result': {'fixture': name, 'command': command,
                'status': run.returncode, 'stdout': run.stdout, 'stderr': run.stderr}}, sort_keys=True))
            need((run.returncode == 0) == (name == 'valid') and 'Usage:' not in run.stderr,
                 'actual native archive separating result: ' + name)
            if name != 'valid':
                token = 'not a regular file' if name == 'missing-source' else 'retrieval digest changed'
                need(token in run.stdout + run.stderr, 'intended actual archive source refusal')
            results.append({'fixture': name, 'command': command, 'status': run.returncode,
                            'stdout': run.stdout, 'stderr': run.stderr})
    finally:
        shutil.rmtree(root)
    need(not root.exists(), 'owned fixture disposal')
    return results


def main():
    publication = json.loads((BASE / 'manifest.json').read_bytes())
    originals = blobs([CARD])
    current = {p: Path(p).read_bytes() for p in originals}
    surface = next(r for r in map(json.loads, Path('doctrine/live_document_size/surfaces.jsonl').read_text().splitlines())
                   if r.get('surface_id') == 'knowledge_cards')
    check(publication, originals, current, surface)
    descriptors = publication['descriptors']
    need(len(descriptors) == len(originals), 'one complete original per archive descriptor')
    for row in descriptors:
        path = row['former_path']
        need(row['revision'] == REVISION and row['current_pointer'] == path
             and row['verifier'] == 'builtin:file' and row['retrieval_kind'] == 'file', 'portable original archive identity')
        need(Path(row['retrieval_locator']).read_bytes() == originals[path], 'byte-exact complete source retrieval')
        need({k:row[k] for k in ('bytes', 'lines', 'sha256')} == pin(originals[path]), 'archive declared dimensions/digest')
    prior_descriptors = native('show', REVISION + ':doctrine/live_document_size/archive_descriptors.jsonl')
    need(Path('doctrine/live_document_size/archive_descriptors.jsonl').read_bytes() == prior_descriptors
         + ''.join(json.dumps(r, sort_keys=True, separators=(',', ':')) + '\n' for r in descriptors).encode(),
         'exact atomic archive descriptor append')
    paths = native('ls-tree', '-r', '--name-only', REVISION, '--', 'docs/knowledge').decode().splitlines()
    paths = sorted(p for p in paths if Path(p).parent == Path('docs/knowledge') and p.endswith('.md'))
    need(paths == sorted(str(p) for p in Path('docs/knowledge').glob('*.md')), 'whole card membership conserved')
    before = blobs(paths)
    after = {p: Path(p).read_bytes() for p in paths}
    need({p for p in paths if before[p] != after[p]} == set(originals), 'all other original fact bytes conserved')
    old_metrics, new_metrics = metrics(before), metrics(after)
    need(all(new_metrics[k] <= old_metrics[k] for k in new_metrics), 'all collection dimensions non-growing')
    need(all(new_metrics[k] <= surface['baseline'][k] + surface['transition']['max_growth'][k]
             and new_metrics[k] <= surface['enforcement_ceilings'][k] for k in new_metrics), 'unchanged collection allowance and ceilings')
    # Fixed committed shards independently give the entire former public question
    # allocation. Other fact bytes are unchanged; exactly one owner/question joins.
    shards = native('ls-tree', '-r', '--name-only', REVISION, '--', 'knowledge-map/generated').decode().splitlines()
    rows = {}
    for raw in blobs(shards).values():
        for line in raw.decode().splitlines():
            match = re.fullmatch(r'- q=(.*) · facts=(.*)', line)
            if not match:
                continue
            question = json.loads(match[1])
            members = re.findall(r'\[([a-z0-9-]+)\]\(\.\./\.\./([^\)]+)\)', match[2])
            need(members and question not in rows, 'whole original unique query allocation')
            rows[question] = ','.join(i for i, p in members) + '\t' + ','.join(p for i, p in members)
    need(QUESTION not in rows, 'genuine newly admitted question')
    rows[QUESTION] = 'mdbook-build-destination-locality\t' + CARD
    expected = ''.join(q + '\t' + rows[q] + '\n' for q in sorted(rows))
    queries = []
    for options in (['--all', '--no-cache'], ['--all'], [QUESTION]):
        command = ['knowledge-map/scripts/query_knowledge_map.sh', *options]
        run = subprocess.run(command, capture_output=True, text=True)
        answer = expected if '--all' in options else QUESTION + '\t' + rows[QUESTION] + '\n'
        need(run.returncode == 0 and not run.stderr and run.stdout == answer, 'actual complete direct/cache/public question parity')
        queries.append({'command': command, 'status': run.returncode, 'stdout': pin(run.stdout.encode()), 'stderr': run.stderr})
    # The complete original source-hypothesis corpus remains byte-identical.
    namespace = 'docs/audits/coordinate-expression-alternatives-20261009'
    conserved = native('ls-tree', '-r', '--name-only', REVISION, '--', namespace).decode().splitlines()
    need(conserved == sorted(str(p) for p in Path(namespace).rglob('*') if p.is_file()), 'whole hypothesis corpus membership')
    need(all(Path(p).read_bytes() == raw for p, raw in blobs(conserved).items()), 'whole hypothesis corpus conserved')
    # Reproduce both actual prepublication refusals with their exact programmes.
    import runpy
    first_results = []
    for name in ('expression_fact.py.txt', 'second-expression_fact.py.txt'):
        draft = runpy.run_path(str(BASE / 'first' / name))
        try:
            draft['extend'](originals[CARD].decode())
        except ValueError as error:
            need(str(error) == 'non-growing expression fact bytes and lines', 'retained first refusal')
            first_results.append({'programme': name, 'result': str(error)})
        else:
            raise ValueError('first over-budget draft unexpectedly accepted')
    controls = {}
    for name, mutate, expected_error in (
        ('lost-locality-rule', lambda p,c,s: c.update({CARD:c[CARD].replace(b'containment/same-volume', b'foreign-volume')}), 'complete reviewed current semantic correspondence'),
        ('swapped-question', lambda p,c,s: c.update({CARD:c[CARD].replace(QUESTION.encode(), b'foreign question')}), 'every original metadata question evidence and probe retained'),
        ('promoted-original-coordinate', lambda p,c,s: c.update({CARD:c[CARD].replace(b'coordinates unmeasured', b'coordinates qualified')}), 'complete conditional expression fact and public probe'),
        ('borrowed-source', lambda p,c,s: p['sources'].update({CARD:p['current'][CARD]}), 'complete original source identity'),
        ('lost-semantic-paragraph', lambda p,c,s: p['semantic_mapping'][CARD]['paragraphs'].pop(), 'complete original semantic paragraph domain'),
        ('widened-allowance', lambda p,c,s: s['transition']['max_growth'].update(bytes_total=s['transition']['max_growth']['bytes_total'] + 1), 'whole Knowledge Map authority unchanged')):
        bad_p, bad_c, bad_s = copy.deepcopy(publication), copy.deepcopy(current), copy.deepcopy(surface)
        mutate(bad_p, bad_c, bad_s)
        if name in ('lost-locality-rule', 'swapped-question', 'promoted-original-coordinate'):
            bad_p['current'][CARD] = pin(bad_c[CARD])
        try:
            check(bad_p, originals, bad_c, bad_s)
        except ValueError as error:
            need(str(error) == expected_error, 'intended compaction control predicate: ' + name)
            controls[name] = str(error)
        else:
            raise ValueError('false-green compaction control: ' + name)
    print(json.dumps({'result': 'PASS complete originals, reviewed semantic closure, whole questions and non-growing authority',
                      'before': old_metrics, 'after': new_metrics, 'queries': queries,
                      'controls': controls, 'native_archives': archive_fixtures(descriptors), 'first_refusals': first_results}, sort_keys=True))


if __name__ == '__main__':
    main()
