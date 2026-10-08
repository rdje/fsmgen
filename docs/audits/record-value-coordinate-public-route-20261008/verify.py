"""Qualify the non-growing dated public fact route and current reader seam."""
import argparse
import copy
import hashlib
import io
import json
import subprocess
import sys
import tarfile
from pathlib import Path

sys.path.insert(0, str(Path.cwd() / 'scripts'))
import check_record_value_publication as current
import record_value_public_reference_fact as fact

BASE = Path('docs/audits/record-value-coordinate-public-route-20261008')
CHECKS = Path('docs/audits/coordinate-public-route-checks-20261008')
CARD = 'docs/knowledge/mdbook-build-destination-locality.md'
SUCCESS = 'PASS complete non-growing public fact route, current source/query allocation and genuine controls; original identities remain unmeasured.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(path):
    return json.loads(path.read_bytes())


def fixed(path):
    return subprocess.check_output(['git', 'show', load(CHECKS / 'epoch.json')['revision'] + ':' + str(path)])


def binding():
    revision = load(CHECKS / 'epoch.json')['revision']
    names = subprocess.check_output(['git', 'ls-tree', '-z', '--name-only', revision + ':docs/audits']).split(b'\0')
    roots = ['docs/audits/' + n.decode() for n in names if n.startswith((b'coordinate-', b'record-value-coordinate-'))]
    raw = subprocess.check_output(['git', 'archive', revision, *roots])
    with tarfile.open(fileobj=io.BytesIO(raw)) as archive:
        saved = {m.name: archive.extractfile(m).read() for m in archive.getmembers() if m.isfile()}
    observed = {}
    for root in roots:
        paths = list(Path(root).iterdir())
        need(not Path(root).is_symlink() and all(p.is_file() and not p.is_symlink()
             and p.stat().st_dev == Path.cwd().stat().st_dev for p in paths), 'regular same-volume route prerequisites')
        observed.update({str(p): p.read_bytes() for p in paths})
    need(observed == saved, 'complete committed public raw/programme/product/result conservation')
    task = fixed('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
    owners = {}
    for root in roots:
        if '/record-value-' in root:
            owner = saved[root + '/scope.txt'].decode().splitlines()[0][7:]
            row = task.decode().split('- ID: `' + owner + '`', 1)[1].split('\n- ID:', 1)[0]
            need('\n  Status: `done`\n' in row, 'complete committed completed public owner')
            owners[owner] = '- ID: `' + owner + '`' + row
    return dict(revision=revision, roots=roots, members={p: pin(v) for p, v in saved.items()},
                owners=owners, task_identity=pin(task))


def route():
    old = fixed(CARD).decode(); proposed = fact.extend(old)
    need((CHECKS / 'tooling-before.md.txt').read_text() == old
         and (CHECKS / 'tooling-proposed.md.txt').read_text() == proposed
         and Path(CARD).read_text() == proposed, 'complete prior proposed and current tooling bytes')
    review = load(CHECKS / 'clause-review.json')
    need([(r['name'], r['before'], r['after']) for r in review['groups']] == list(fact.EDITS)
         and all(r['conserved_propositions'] for r in review['groups'])
         and review['added_question'] == fact.QUESTION and review['added_fact'] == fact.BODY,
         'complete exact reviewed proposition allocation')
    prior = current.historical(); canonical = current.sources()
    for path, raw in canonical.items():
        if path != CARD:
            need(raw == fixed(path), 'complete non-target canonical bytes conserve')
    record = current.current_input(prior, canonical)
    current.check(record, canonical, prior, current.authority(prior))
    # Retain the committed pre-publication guide epoch. Its current/retained
    # roles remain valid; final native publication has a separate whole proof.
    record['chapter'] = fixed(prior['CHAPTER']).decode()
    record['tooling_chapter'] = fixed(prior['TOOLING_CHAPTER']).decode()
    current.check(record, canonical, prior, current.authority(prior))
    physical = {p: v for p, v in canonical.items() if Path(p).parent == Path('docs/knowledge')}
    before = dict(physical); before[CARD] = old.encode()
    old_census = prior['public']['metrics'](before)
    need(record['census']['files'] == old_census['files']
         and record['census']['bytes_total'] <= old_census['bytes_total'], 'non-growing whole physical card population')
    metadata = prior['metadata']['metadata']
    old_questions = metadata(old.encode())[1]; new_questions = metadata(proposed.encode())[1]
    need(new_questions == old_questions + [fact.QUESTION], 'complete ordered old questions and one new public question')
    first = load(CHECKS / 'first-proposal.json'); actual = load(CHECKS / 'first-proposal-result.json')
    paths = [CHECKS / 'run.py', Path('scripts/run_with_ram_guard.sh'), CHECKS / 'first_proposal.py']
    need(first['before'] == old and first['live_card_unchanged'] is True
         and first['candidate_bytes'] > first['before_bytes']
         and type(actual['status']) is int and actual['status'] == 1
         and actual['stdout'] == ''
         and actual['stderr'].endswith('ValueError: public-reference tooling extension must not grow physical card bytes\n')
         and actual['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(CHECKS / 'first_proposal.py')]
         and actual['instruments'] == {str(p): pin(p.read_bytes()) for p in paths},
         'complete actual first growth refusal before live mutation')
    return dict(card=dict(before=old, after=proposed, review=review), current=record,
                before_census=old_census, first_proposal=first, first_actual=actual,
                role='Dated public fixtures only; original coordinates/identities unmeasured.')


def controls(product):
    prior = current.historical(); canonical = current.sources(); declared = current.authority(prior)
    results = []
    for name, mutate, cause in (
        ('lost-public-question', lambda r: r['cards'].update({CARD: r['cards'][CARD].replace(fact.QUESTION, 'lost question')}), 'complete current target meanings questions metadata and replay routes'),
        ('borrowed-public-reader', lambda r: r['cards'].update({CARD: r['cards'][CARD].replace('../' + fact.READER.removeprefix('docs/'), 'foreign.py')}), 'complete current target meanings questions metadata and replay routes'),
        ('original-identity-promotion', lambda r: r['cards'].update({CARD: r['cards'][CARD].replace('original coordinates/identities unmeasured', 'original coordinates/identities qualified')}), 'complete current target meanings questions metadata and replay routes'),
        ('lost-global-row', lambda r: r['queries']['direct'].update(stdout=r['queries']['direct']['stdout'].split('\n', 1)[1]), 'complete source-derived current global query allocation'),
        ('Boolean-census', lambda r: r['census'].update(files=True), 'physical capacity kind/allowance: files'),
        ('positive-growth-over-authority', lambda r: r['census'].update(bytes_total=r['surface']['baseline']['bytes_total'] + r['surface']['transition']['max_growth']['bytes_total'] + 1), 'physical capacity kind/allowance: bytes_total'),
        ('widened-authority', lambda r: r['surface']['transition']['max_growth'].update(files=999), 'whole unchanged physical card authority'),
    ):
        candidate = copy.deepcopy(product['current']); mutate(candidate)
        need(not current.same(candidate, product['current']), 'genuine route control')
        try:
            current.check(candidate, canonical, prior, declared)
        except ValueError as error:
            need(str(error) == cause, 'intended route refusal: ' + name)
            results.append(dict(name=name, cause=cause, status=1, candidate=pin(json.dumps(candidate, sort_keys=True).encode())))
        else:
            raise ValueError('false-green route control: ' + name)
    return results


def save(name, value):
    path = BASE / name; raw = json.dumps(value, sort_keys=True, indent=2) + '\n'
    if path.exists():
        need(path.read_text() == raw, 'complete retained route product: ' + name)
    else:
        need(not (BASE / 'manifest.json').exists(), 'sealed route cannot publish')
        path.write_text(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument('--seal', action='store_true'); args = parser.parse_args()
    members = lambda: {p.name: pin(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}
    if (BASE / 'manifest.json').exists():
        need(current.same(load(BASE / 'manifest.json'), members()), 'complete immutable public route seal')
    before = binding(); save('binding.json', before)
    product = route(); save('route.json', product); save('controls.json', controls(product))
    need(current.same(binding(), before), 'complete committed public raw evidence conserves')
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
