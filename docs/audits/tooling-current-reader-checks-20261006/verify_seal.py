"""Independently consume the actual tooling current result and whole seal."""
import copy
import json
import re
from pathlib import Path

BASE = Path('docs/audits/record-value-tooling-current-reader-20261006')
CHECKS = Path('docs/audits/tooling-current-reader-checks-20261006')
ns = {'__name__': 'tooling_result', '__file__': str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, identity, load = (ns[k] for k in ('require', 'same', 'identity', 'load'))
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'),
           '--current', '--build', '.artifacts/tooling-current-reader-book', '--seal']


def whole_members():
    return {Path(p).name: identity(raw) for p, raw in ns['whole'](BASE).items()}


def header(receipt):
    require(type(receipt['status']) is int and receipt['status'] == 0, 'actual current reader integer success')
    require(receipt['command'] == COMMAND and receipt['stdout'] == ns['CURRENT_SUCCESS'], 'exact actual current reader command and result')
    require(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', receipt['stderr']) is not None,
            'actual current reader default guard diagnostics')
    require(all(type(p['bytes']) is int and p['bytes'] >= 0 for p in receipt['whole_members'].values()), 'actual reader member byte-count kinds')
    actual = whole_members()
    require(same(receipt['whole_members'], actual), 'whole actual reader member conservation')
    raw = load(CHECKS / 'seal-command.json')
    require(same(receipt['actual_result_identity'], identity((CHECKS / 'seal-command.json').read_bytes()))
        and same({k: receipt[k] for k in raw}, raw), 'whole raw actual reader result identity')
    require(set(raw['instruments']) == {str(CHECKS / 'run.py'), 'scripts/run_with_ram_guard.sh', str(BASE / 'verify.py')}
        and all(same(pin, identity(Path(p).read_bytes())) for p, pin in raw['instruments'].items()),
        'whole invocation-time current reader instruments')
    require(same(load(BASE / 'manifest.json'), ns['members']()), 'whole immutable actual reader manifest')
    return actual


def roles():
    record = load(CHECKS / 'roles.json')
    require(record['restored'] is True and same(record['programme_identity'], identity((CHECKS / 'qualify_roles.py').read_bytes())),
            'whole actual reader role programme and restoration identity')
    for role, command, status, token in (
        ('superseded_current', ['python3', '-B', 'docs/audits/record-value-own-boundary-publication-20261005/verify.py', '--current'], 1, 'whole current source/role/question/reader epoch'),
        ('snapshot', ['python3', '-B', str(BASE / 'verify.py')], 0, ns['SUCCESS']),
        ('progress', ['python3', '-B', str(BASE / 'verify.py'), '--current'], 0, ns['CURRENT_SUCCESS']),
    ):
        actual = record[role]
        require(type(actual['status']) is int and actual['status'] == status and actual['command'] == command
            and token in actual['stderr' if status else 'stdout'], 'whole actual reader role: ' + role)
    publication = load(BASE / 'publication.json')
    chapter = record['source_before'][ns['CHAPTER']]
    require(chapter == publication['chapter_after'] and record['candidate_chapter'] ==
        chapter + '\n<!-- Owned tooling-reader unrelated progress; restore before commit. -->\n', 'whole genuine unrelated book progress')
    candidate = copy.deepcopy(publication['snapshot']); candidate['chapter'] = record['candidate_chapter']
    ns['check_current'](candidate)
    book = {p: raw for p, raw in ns['committed']('docs/book/src').items()
            if Path(p).parent == Path('docs/book/src') and p.endswith('.md')}
    book[ns['CHAPTER']] = record['candidate_chapter'].encode()
    public = ns['module'](ns['PUBLIC'] / 'verify.py')
    change = next(json.loads(s) for s in record['candidate_registry'].splitlines()
                  if json.loads(s).get('surface_id') == 'shipped_behavior')['reference_contract']['aggregate_change']
    require(same(change['baseline'], publication['baseline']) and same(change['delta'],
        {k: public['metrics'](book)[k] - publication['baseline'][k] for k in publication['baseline']}),
        'whole independent unrelated-progress book authority')
    old = ns['module'](Path('docs/audits/record-value-own-boundary-publication-20261005/verify.py'))
    try:
        old['check_live'](load(Path('docs/audits/record-value-own-boundary-publication-20261005/publication.json')),
                          ns['expected_cards'](), {}, chapter, '', {})
    except ValueError as error:
        require(str(error) == 'whole current source/role/question/reader epoch', 'independent superseded current epoch refusal')
    else:
        raise ValueError('false-green superseded current epoch')


def check(receipt):
    before = header(receipt); ns['authenticate']()
    require(same(ns['source_proof'](), load(BASE / 'source-proof.json')), 'whole regenerated reader source and snapshot products')
    snapshot = load(BASE / 'publication.json')['snapshot']
    require(same(ns['controls'](snapshot), load(BASE / 'controls.json')), 'whole regenerated genuine reader controls')
    require(same(ns['native_proof']((BASE / 'native-input.html').read_text()), load(BASE / 'native-proof.json')),
            'whole regenerated native reader products and controls')
    roles()
    first = load(CHECKS / 'first-preflight.json')
    require(type(first['status']) is int and first['status'] == 1 and 'genuine reader intervention: lost-native-role' in first['stderr'],
            'actual first control source-token failure')
    initial = ns['module'](CHECKS / 'first-verify.py.txt')
    record = initial['current_input'](); record['cards'] = initial['expected_cards']()
    record['chapter'] = load(BASE / 'publication.json')['chapter_after']
    try:
        initial['controls'](record)
    except ValueError as error:
        require(str(error) == 'genuine reader intervention: lost-native-role', 'independently reproduced first no-op intervention')
    else:
        raise ValueError('false-green first no-op intervention')
    locality = load(CHECKS / 'locality.json')
    require(type(locality['status']) is int and locality['status'] == 0 and locality['command'] ==
        ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', 'docs/audits/specforge-rule-admission-20260924/verify-book-output-locality.py']
        and all(same(pin, identity(Path(p).read_bytes())) for p, pin in locality['instruments'].items()),
        'actual unchanged required destination-locality replay and instruments')
    require(same(before, header(receipt)), 'every reader seal byte conserved after independent consumption')


def main():
    receipt = load(CHECKS / 'sealed-replay.json'); check(receipt)
    def refuse(name, candidate, cause):
        try:
            header(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended actual reader result refusal: ' + name)
            print(name + ': refused at ' + cause)
        else:
            raise ValueError('false-green actual reader result: ' + name)
    for status in (True, 0.0, 1):
        refuse('status-' + repr(status), {**receipt, 'status': status}, 'actual current reader integer success')
    for count in (True, 0.0):
        candidate = copy.deepcopy(receipt); next(iter(candidate['whole_members'].values()))['bytes'] = count
        refuse('bytes-' + repr(count), candidate, 'actual reader member byte-count kinds')
    candidate = copy.deepcopy(receipt); candidate['whole_members'].pop(next(iter(candidate['whole_members'])))
    refuse('lost-member', candidate, 'whole actual reader member conservation')
    refuse('widened-guard', {**receipt, 'stderr': receipt['stderr'].replace('cutoff 88%', 'cutoff 99%')}, 'actual current reader default guard diagnostics')
    borrowed = load(ns['PUBLIC_CHECKS'] / 'sealed-replay.json')
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine prior observer-only success')
    refuse('borrowed-observer-success', borrowed, 'exact actual current reader command and result')
    borrowed = load(CHECKS / 'roles.json')['snapshot']
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine tooling snapshot success')
    refuse('borrowed-snapshot-success', borrowed, 'exact actual current reader command and result')
    print('PASS independently consumed actual tooling current seal, complete products and typed/member/borrowed-result refusals.')


if __name__ == '__main__':
    main()
