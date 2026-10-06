"""Qualify a source-bound draft and its budget, without publishing semantics."""
import argparse
import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-draft-20261006')
REVISION = '89631f67061eb741a95a06e3ec6eb6fa1df335da'
CARD = 'docs/knowledge/record-value-original-observer-helper-paths.md'
QUESTION = 'what qualifies original public subtest header and boundary compatibility?'
FACT = ('Original Test::Builder/Test::More headers match authored-name prefixes, CODE\n'
        'kinds and body/delegate/entry/do-load order through every throw phase. Separate\n'
        'dated public fixtures select these signatures; receiver tokens and private eval\n'
        'intervals stay opaque. Wrong public name/kind/population/order rejects.\n')
ROLE = 'Draft only; no live card mutation or semantic retention qualification yet.'


def require(value, cause):
    if not value:
        raise ValueError(cause)


def identity(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def load(name):
    return json.loads((BASE / name).read_bytes())


def save(name, value):
    target = BASE / name
    if target.exists():
        require(load(name) == value, 'whole saved draft product: ' + name)
    else:
        require(not (BASE / 'draft-manifest.json').exists(), 'sealed draft cannot publish')
        target.write_text(json.dumps(value, sort_keys=True, indent=2) + '\n')


def questions(text):
    header = text.split('---', 2)[1]
    return [json.loads(line.removeprefix('  - ')) for line in header.splitlines() if line.startswith('  - ')]


def check(draft):
    original = subprocess.check_output(['git', 'show', REVISION + ':' + CARD]).decode()
    require(draft['before'] == original, 'whole committed draft source card')
    require(draft['role'] == ROLE, 'explicit draft-only unqualified semantic role')
    require(type(draft['byte_delta']) is int and type(draft['LF_delta']) is int,
            'discrete draft metric kinds')
    constructed = original
    for replacement in draft['replacements']:
        require(set(replacement) == {'before', 'after'} and all(type(v) is str for v in replacement.values()),
                'closed exact draft replacement grammar')
        require(constructed.count(replacement['before']) == 1, 'unique declared draft source replacement')
        constructed = constructed.replace(replacement['before'], replacement['after'], 1)
    constructed += FACT
    require(constructed == draft['after'], 'whole deterministically reconstructed draft body')
    require(questions(draft['after']) == questions(original) + [QUESTION], 'ordered prior questions and exact proposed new question')
    marker = '## Qualified own subtest and do-load source boundaries\n\n'
    end = 'These own source roles refine the earlier broad subtest/require gap; full\n'
    protected = original[original.index(marker):original.index(end)]
    require(draft['after'].count(protected) == 1, 'whole protected authored subtest and load section')
    before, after = original.encode(), draft['after'].encode()
    byte_delta, LF_delta = len(after) - len(before), after.count(b'\n') - before.count(b'\n')
    require((draft['byte_delta'], draft['LF_delta']) == (byte_delta, LF_delta), 'independently measured complete draft deltas')
    require(byte_delta <= 0 and LF_delta <= 0, 'no net draft encoded-byte or LF growth')
    return dict(revision=REVISION, card=CARD, source_identity=identity(before), proposed_identity=identity(after),
                byte_delta=byte_delta, LF_delta=LF_delta,
                questions_before=questions(original), questions_after=questions(draft['after']),
                protected_section_identity=identity(protected.encode()), role=ROLE)


def coherent_change(draft, before, after):
    require(draft['after'].count(before) == 1, 'genuine coherent draft intervention')
    draft['replacements'].append(dict(before=before, after=after))
    draft['after'] = draft['after'].replace(before, after, 1)
    draft['byte_delta'] = len(draft['after'].encode()) - len(draft['before'].encode())
    draft['LF_delta'] = draft['after'].count('\n') - draft['before'].count('\n')


def controls(draft):
    cases = [
        ('wrong-source', lambda d: d.update(before=d['before'] + '\n'), 'whole committed draft source card'),
        ('borrowed-semantic-assurance', lambda d: d.update(role='Every fact is qualified.'), 'explicit draft-only unqualified semantic role'),
        ('Boolean-byte-delta', lambda d: d.update(byte_delta=True), 'discrete draft metric kinds'),
        ('float-LF-delta', lambda d: d.update(LF_delta=-4.0), 'discrete draft metric kinds'),
        ('changed-unconstructed-body', lambda d: d.update(after=d['after'] + '\n'), 'whole deterministically reconstructed draft body'),
        ('lost-prior-question', lambda d: coherent_change(d, '  - "what inventories original observer and callback source roles?"\n', ''), 'ordered prior questions and exact proposed new question'),
        ('changed-authored-section', lambda d: coherent_change(d, 'supply no extra arguments.', 'supply arguments.'), 'whole protected authored subtest and load section'),
    ]
    results = []
    for name, mutate, cause in cases:
        candidate = copy.deepcopy(draft); mutate(candidate)
        try:
            check(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended draft refusal: ' + name)
            results.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green draft control: ' + name)
    # An accepted separating input proves why this narrow success cannot stand
    # in for the semantic-retention leg owned by .5.4.2.
    candidate = copy.deepcopy(draft)
    coherent_change(candidate, 'The parser receiver role is declared; identity is unmeasured.\n', '')
    check(candidate)
    return dict(refusals=results, separating_semantic_gap=dict(
        draft_status=0, removed_unique_fact='The parser receiver role is declared; identity is unmeasured.',
        proposed_identity=identity(candidate['after'].encode()),
        scope='Construction/budget acceptance only; live publication is forbidden until .5.4.2 independently rejects this fact loss.'))


def members():
    paths = list(BASE.iterdir())
    require(all(p.is_file() and not p.is_symlink() for p in paths), 'whole regular draft member population')
    return {p.name: identity(p.read_bytes()) for p in paths if p.name != 'draft-manifest.json'}


def main():
    p = argparse.ArgumentParser(description=__doc__); p.add_argument('--seal', action='store_true'); args = p.parse_args()
    if (BASE / 'draft-manifest.json').exists():
        require(load('draft-manifest.json') == members(), 'whole immutable draft seal')
    draft = load('first-card-proposal.json')
    save('draft-proof.json', check(draft)); save('draft-controls.json', controls(draft))
    require(Path(CARD).read_bytes() == subprocess.check_output(['git', 'show', REVISION + ':' + CARD]),
            'live card remains unchanged during draft qualification')
    if args.seal:
        save('draft-manifest.json', members())
    print('PASS exact source-bound draft construction, ordered questions, protected section and non-growing budget; semantic retention/publication remain unqualified.')


if __name__ == '__main__':
    main()
