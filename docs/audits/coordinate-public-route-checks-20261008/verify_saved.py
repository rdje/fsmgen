"""Independently reconstruct card, source census and all question rows."""
import copy
import hashlib
import io
import json
import os
import subprocess
import tarfile
from pathlib import Path

BASE = Path('docs/audits/coordinate-public-route-checks-20261008')
MODEL = Path('docs/audits/record-value-coordinate-public-route-20261008')
CARD = 'docs/knowledge/mdbook-build-destination-locality.md'
QUESTION = 'where are public coordinate recipes verified?'
FACT = '\n[Reader](../audits/record-value-coordinate-public-reference-20261008/verify.py): dated public fixtures; original coordinates/identities unmeasured.\n'
SUCCESS = 'PASS independent whole public fact route, non-growing source census and exact global question allocation with genuine controls.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(path):
    return json.loads(path.read_bytes())


def metadata(raw):
    text = raw.decode(); lines = text.splitlines()
    if not lines or lines[0] != '---':
        return None
    stop = lines.index('---', 1); header = lines[1:stop]
    ids = [s[4:].strip().strip('"') for s in header if s.startswith('id: ')]
    starts = [i for i, s in enumerate(header) if s.startswith('answers:')]
    if not starts:
        return None
    questions = []
    for start in starts:
        inline = header[start][len('answers:'):].strip()
        if inline:
            questions.extend(json.loads(inline))
        else:
            for line in header[start + 1:]:
                if not line.startswith(' '):
                    break
                need(line.lstrip().startswith('- '), 'independent answer-list grammar')
                questions.append(line.lstrip()[2:].strip().removeprefix('"').removesuffix('"'))
    if not questions:
        return None
    need(len(ids) == 1, 'independent question owner identity')
    return ids[0], questions


def questions(blobs):
    rows = {}
    for path, raw in blobs.items():
        record = metadata(raw)
        if record:
            identifier, answers = record
            for answer in answers:
                rows.setdefault(answer, []).append((identifier, path))
    return ''.join(q + '\t' + ','.join(i for i, p in sorted(m)) + '\t' + ','.join(p for i, p in sorted(m)) + '\n'
                   for q, m in sorted(rows.items()))


def census(blobs):
    values = list(blobs.values())
    return dict(files=len(values), bytes_total=sum(map(len, values)), bytes_each=max(map(len, values)),
                lines_total=sum(v.count(b'\n') for v in values), lines_each=max(v.count(b'\n') for v in values),
                line_bytes_each=max(len(line.rstrip(b'\r')) for v in values for line in v.split(b'\n')))


def expected():
    revision = load(BASE / 'epoch.json')['revision']
    raw = subprocess.check_output(['git', 'archive', revision, 'docs/knowledge', 'docs/decisions'])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        old = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile() and m.name.endswith('.md')}
    review = load(BASE / 'clause-review.json'); after = old[CARD].decode()
    for group in review['groups']:
        need(after.count(group['before']) == 1 and group['conserved_propositions'], 'independent unique reviewed clause')
        after = after.replace(group['before'], group['after'], 1)
    need(after.count('date: 2026-10-07\n') == 1, 'independent prior date')
    after = after.replace('date: 2026-10-07\n', '  - "' + QUESTION + '"\ndate: 2026-10-08\n', 1) + FACT
    need(len(after.encode()) <= len(old[CARD]), 'independent non-growing tooling fact')
    need(metadata(after.encode())[1] == metadata(old[CARD])[1] + [QUESTION], 'independent complete ordered old and new questions')
    observed = {}
    for root in ('docs/knowledge', 'docs/decisions'):
        for directory, children, files in os.walk(root, followlinks=False):
            base = Path(directory)
            need(not base.is_symlink() and not (base / '.git').exists(), 'independent local scan root')
            for child in children:
                need(not (base / child).is_symlink() and not (base / child / '.git').exists(), 'independent local scan directory')
            for name in files:
                if name.endswith('.md'):
                    path = base / name
                    need(not path.is_symlink() and path.is_file() and path.stat().st_dev == Path.cwd().stat().st_dev,
                         'independent regular same-volume source')
                    observed[str(path)] = path.read_bytes()
    wanted = dict(old); wanted[CARD] = after.encode()
    need(observed == wanted, 'independent whole canonical before after source conservation')
    registry = Path('doctrine/live_document_size/surfaces.jsonl')
    fixed_registry = subprocess.check_output(['git', 'show', revision + ':' + str(registry)])
    authority = lambda raw: next(json.loads(s) for s in raw.decode().splitlines() if json.loads(s).get('surface_id') == 'knowledge_cards')
    need(authority(registry.read_bytes()) == authority(fixed_registry), 'independent unchanged complete physical authority')
    physical = {p: v for p, v in observed.items() if Path(p).parent == Path('docs/knowledge')}
    return dict(before=old[CARD].decode(), after=after, sources={p: pin(v) for p, v in observed.items()},
                census=census(physical), allocation=questions(observed), surface=authority(fixed_registry))


def public_members():
    revision = load(BASE / 'epoch.json')['revision']
    paths = [p.decode() for p in subprocess.check_output(['git', 'ls-tree', '-r', '-z', '--name-only', revision, 'docs/audits']).split(b'\0')
             if p.startswith((b'docs/audits/coordinate-', b'docs/audits/record-value-coordinate-'))]
    wire = subprocess.check_output(['git', 'cat-file', '--batch'], input=''.join(revision + ':' + p + '\n' for p in paths).encode())
    position = 0; members = {}
    for path in paths:
        end = wire.index(b'\n', position); header = wire[position:end].split()
        need(len(header) == 3 and header[1] == b'blob', 'independent public Git binary member')
        size = int(header[2]); position = end + 1; raw = wire[position:position + size]; position += size + 1
        need(len(raw) == size and Path(path).read_bytes() == raw, 'independent complete committed public binary source')
        members[path] = pin(raw)
    need(position == len(wire), 'independent complete public binary frame')
    need(load(MODEL / 'binding.json')['members'] == members, 'independent complete public prerequisite members')
    return members


def check(product, wanted):
    need(product['role'] == 'Dated public fixtures only; original coordinates/identities unmeasured.', 'independent original identity gap')
    need(product['card']['before'] == wanted['before'] and product['card']['after'] == wanted['after'], 'independent complete exact tooling card')
    need(product['card']['review'] == load(BASE / 'clause-review.json'), 'independent exact whole proposition review')
    record = product['current']
    need(record['source_members'] == wanted['sources'], 'independent whole source member allocation')
    need(all(type(v) is int for v in record['census'].values()) and record['census'] == wanted['census'], 'independent typed complete physical census')
    need(record['surface'] == wanted['surface'], 'independent whole physical authority')
    need(set(record['queries']) == {'direct', 'cached'}, 'independent complete actual query roles')
    for role, actual in record['queries'].items():
        need(type(actual['status']) is int and actual['status'] == 0 and actual['stderr'] == ''
             and actual['command'] == ['knowledge-map/scripts/query_knowledge_map.sh', '--all'] + (['--no-cache'] if role == 'direct' else [])
             and actual['stdout'] == wanted['allocation'], 'independent complete actual global question rows')


def main():
    members = {p.name: pin(p.read_bytes()) for p in MODEL.iterdir() if p.name != 'manifest.json'}
    need(load(MODEL / 'manifest.json') == members, 'independent whole immutable route seal')
    wanted = expected(); product = load(MODEL / 'route.json'); check(product, wanted)
    controls = []
    for name, mutate, cause in (
        ('lost-old-question', lambda c: c['card'].update(after=c['card']['after'].replace('where does mdbook build resolve a relative dest-dir?', 'lost')), 'independent complete exact tooling card'),
        ('lost-source-member', lambda c: c['current']['source_members'].pop(next(iter(c['current']['source_members']))), 'independent whole source member allocation'),
        ('Boolean-census', lambda c: c['current']['census'].update(files=True), 'independent typed complete physical census'),
        ('borrowed-query', lambda c: c['current']['queries']['cached'].update(stdout=''), 'independent complete actual global question rows'),
        ('original-promotion', lambda c: c.update(role='Original identities measured.'), 'independent original identity gap'),
    ):
        candidate = copy.deepcopy(product); mutate(candidate); need(candidate != product, 'independent genuine route control')
        try:
            check(candidate, wanted)
        except ValueError as error:
            need(str(error) == cause, 'independent intended route refusal')
            controls.append(dict(name=name, status=1, cause=cause))
        else:
            raise ValueError('independent false-green route control')
    proof = dict(members=members, public_prerequisites=public_members(), whole_expected=wanted, controls=controls,
                 scope='Exact byte/question/census/source oracles; prose equivalence is the separate named review. Original identities and visual QA remain open.')
    path = BASE / 'proof.json'; raw = json.dumps(proof, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'whole retained independent route proof')
    else:
        path.write_text(raw)
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
