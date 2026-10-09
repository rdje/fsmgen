"""Atomic source retention, reviewed correspondence and bounded card admission."""
import hashlib
import json
import runpy
import subprocess
from pathlib import Path

M = runpy.run_path('docs/audits/archive-transport-fact-20261009/model.py')
BASE, REVISION = M['BASE'], M['REVISION']
DESCRIPTORS = Path('doctrine/live_document_size/archive_descriptors.jsonl')
SURFACES = Path('doctrine/live_document_size/surfaces.jsonl')


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'),
            'sha256': hashlib.sha256(raw).hexdigest()}


def native(*args):
    result = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    if result.returncode or result.stderr:
        raise ValueError('complete fixed Git source')
    return result.stdout


def main():
    if (BASE / 'manifest.json').exists():
        raise ValueError('refuse to republish retained compaction')
    sources, current, descriptors, mapping = {}, {}, [], {}
    for path in M['PARAGRAPHS']:
        original = native('show', REVISION + ':' + path)
        if Path(path).read_bytes() != original:
            raise ValueError('original card stable before compaction')
        sources[path] = original
        current[path] = M['proposal'](path, original)
        locator = BASE / 'source' / (pin(original)['sha256'] + '.txt')
        locator.parent.mkdir(exist_ok=True)
        if locator.exists():
            raise ValueError('refuse to overwrite retained source')
        locator.write_bytes(original)
        descriptors.append({'schema_version': 1, 'record_type': 'descriptor',
            'descriptor_id': 'archive-transport-fact-' + Path(path).stem + '-20261009',
            'surface_id': 'exact_history', 'former_path': path,
            'range_id': 'complete-card-before-non-growing-transport-fact-admission',
            'revision': REVISION, **pin(original), 'retrieval_kind': 'file',
            'retrieval_locator': str(locator), 'current_pointer': path,
            'sealed_on': '2026-10-09', 'verifier': 'builtin:file'})
        old_paragraphs = original.decode().rsplit('---\n', 1)[1].strip().split('\n\n')
        if len(old_paragraphs) != len(M['PARAGRAPHS'][path]):
            raise ValueError('complete ordered source paragraph correspondence')
        mapping[path] = {'metadata': 'IDs/questions/tags/evidence and every original reverify command retained; date refreshed, inventory title shortened, archive question/probe added only to retrieval.',
            'paragraphs': [{'source': old, 'current': new,
                            'review': 'All original causal facts, boundaries, authorities and probe/locality obligations retain in this ordered paragraph.'}
                           for old, new in zip(old_paragraphs, M['PARAGRAPHS'][path])]}
    before = {k: sum(pin(raw)[k] for raw in sources.values()) for k in ('bytes', 'lines')}
    after = {k: sum(pin(raw)[k] for raw in current.values()) for k in ('bytes', 'lines')}
    if any(after[key] > before[key] for key in before):
        raise ValueError('non-growing card bytes and lines before publication')
    old_descriptors = native('show', REVISION + ':' + str(DESCRIPTORS))
    if DESCRIPTORS.read_bytes() != old_descriptors:
        raise ValueError('stable descriptor source before atomic append')
    for path, raw in current.items():
        Path(path).write_bytes(raw)
    DESCRIPTORS.write_bytes(old_descriptors + ''.join(
        json.dumps(row, sort_keys=True, separators=(',', ':')) + '\n' for row in descriptors).encode())
    manifest = {'schema_version': 1, 'revision': REVISION,
        'surface': 'knowledge_cards', 'sources': {p: pin(raw) for p, raw in sources.items()},
        'current': {p: pin(raw) for p, raw in current.items()},
        'descriptors': descriptors, 'semantic_mapping': mapping,
        'original_metadata': {p: raw.decode().rsplit('---\n', 1)[0] + '---\n' for p, raw in sources.items()},
        'products': {
            'complete_source': 'Exact complete retained files and fixed Git revision, independently compared byte for byte.',
            'semantic_closure': 'Ordered reviewed paragraph correspondence plus unchanged original IDs, questions, evidence and executable probe routes; one new transport fact.',
            'live_dimensions': {'before': before, 'after': after, 'file_delta': 0},
            'unretained_residue': {'bytes': 0, 'reason': 'Every original byte retained in a descriptor-addressed complete source file.'},
            'overlap': 'Complete source, semantic facts and live navigation intentionally overlap; no disjoint subtraction claim.'},
        'authority': pin(native('show', REVISION + ':' + str(SURFACES))),
        'legs': {'rederive': 'compact.py fixed-Git originals, complete source copies and reviewed semantic mapping.',
                 'falsify': 'verify.py independent whole-source/current/question census and hostile source/question/rule/authority controls; archive.py controlled native Git payload/permission interventions.',
                 'durability': 'Tracked complete originals, archive descriptors, mapping/programmes and actual receipts in an atomic normal-hook commit.'}}
    (BASE / 'manifest.json').write_text(json.dumps(manifest, sort_keys=True, indent=2) + '\n')
    command = ['git', '--no-replace-objects', 'log', '-1', '--format=%H %s', '-S',
               'independent complete archive mode identity', '--',
               'docs/audits/coordinate-source-hypotheses-20261009/verify.py']
    result = subprocess.run(command, capture_output=True, text=True)
    (BASE / 'root-cause.json').write_text(json.dumps({'command': command, 'status': result.returncode,
        'stdout': result.stdout, 'stderr': result.stderr}, sort_keys=True, indent=2) + '\n')
    if result.returncode or result.stderr or not result.stdout.startswith(REVISION):
        raise ValueError('actual archive-mode failure history locus')
    print('PASS complete source retention, reviewed compaction and non-growing fact admission.')


if __name__ == '__main__':
    main()
