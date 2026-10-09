"""Supersede the retained first wrapping result without changing source archives."""
import copy
import hashlib
import json
import runpy
from pathlib import Path

BASE = Path('docs/audits/archive-transport-fact-20261009')
URL = b'https://git-scm.com/docs/git-archive#Documentation/git-archive.txt-tarumask'


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'),
            'sha256': hashlib.sha256(raw).hexdigest()}


def main():
    if (BASE / 'publication.json').exists():
        raise ValueError('refuse to rewrite corrected publication')
    first = json.loads((BASE / 'manifest.json').read_bytes())
    model = runpy.run_path(str(BASE / 'model.py'))
    old_model = runpy.run_path(str(BASE / 'first/model.py.txt'))
    publication = copy.deepcopy(first)
    counts = {'bytes': 0, 'lines': 0}
    for row in first['descriptors']:
        path = row['former_path']
        original = Path(row['retrieval_locator']).read_bytes()
        previous = old_model['proposal'](path, original)
        if previous != (BASE / ('first/' + Path(path).name + '.txt')).read_bytes():
            raise ValueError('retain exact complete first draft and programme')
        if path == model['RETRIEVAL'] and URL in previous:
            raise ValueError('first URL wrapping defect not reproduced')
        corrected = model['proposal'](path, original)
        if path == model['RETRIEVAL'] and URL not in corrected:
            raise ValueError('corrected complete public URL')
        Path(path).write_bytes(corrected)
        publication['current'][path] = pin(corrected)
        for key in counts:
            counts[key] += pin(corrected)[key]
    publication['products']['live_dimensions']['after'] = counts
    if any(counts[k] > publication['products']['live_dimensions']['before'][k] for k in counts):
        raise ValueError('corrected whole non-growing dimensions')
    publication['supersedes'] = {'path': str(BASE / 'manifest.json'),
        'identity': pin((BASE / 'manifest.json').read_bytes()),
        'defect': 'Default textwrap.fill split the public URL at a hyphen in the first draft.',
        'reproduction': 'Exact retained first model regenerates both complete first card drafts and omits the intact URL.',
        'repair': 'Disable long-word and hyphen breaks; complete URL and tokens conserve. Source archives/descriptors/questions/probes remain unchanged.',
        'owner': 'Current archive transport fact admission leaf; repair before commitment.'}
    (BASE / 'publication.json').write_text(json.dumps(publication, sort_keys=True, indent=2) + '\n')
    print('PASS original URL wrapping failure reproduced; corrected non-growing publication supersedes it.')


if __name__ == '__main__':
    main()
