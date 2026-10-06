"""Consume the actual retention seal and regenerate its complete products."""
import copy
import json
import re
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-retention-20261006')
CHECKS = Path('docs/audits/public-boundary-retention-checks-20261006')
ns = {'__name__': 'independent_retention_result'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
require, same, load, identity = (ns[k] for k in ('require', 'same', 'load', 'identity'))
COMMAND = ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'verify.py'), '--live-unchanged', '--seal']


def members():
    return {Path(p).name: identity(raw) for p, raw in ns['whole'](BASE).items()}


def header(receipt):
    require(type(receipt['status']) is int and receipt['status'] == 0, 'actual retention seal integer success')
    require(receipt['command'] == COMMAND and receipt['stdout'] == ns['SUCCESS'], 'exact actual retention-only seal command/result')
    require(re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', receipt['stderr']) is not None,
            'actual successful retention default-guard diagnostics')
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0 for pin in receipt['whole_members'].values()),
            'actual retention receipt discrete member byte counts')
    actual = members()
    require(same(receipt['whole_members'], actual), 'whole actual retention receipt member pins')
    raw = load(CHECKS / 'seal-command.json')
    require(receipt['actual_result_identity'] == identity((CHECKS / 'seal-command.json').read_bytes())
            and same({k: receipt[k] for k in ('command', 'status', 'stdout', 'stderr')}, raw),
            'whole raw actual retention result identity')
    require(same(load(BASE / 'manifest.json'), ns['members']()), 'whole immutable retention manifest')
    return actual


def check(receipt):
    before = header(receipt)
    ns['module'](BASE / 'prepare.py')['main'](quiet=True)
    require(same(ns['authenticate'](), load(BASE / 'prerequisite-proof.json')), 'regenerated whole original/draft/public retention roots')
    proposal, review = load(BASE / 'proposal.json'), load(BASE / 'retention-map.json')
    require(same(ns['check_semantics'](proposal, review), load(BASE / 'proof.json')), 'regenerated complete semantic retention/source/question/budget proof')
    require(same(ns['controls'](proposal, review), load(BASE / 'controls.json')), 'regenerated genuine coherent and per-fact retention controls')
    require(same(ns['recoveries'](proposal, review), load(BASE / 'recovery-proof.json')), 'regenerated actual first failures and corrections')
    native = ns['module'](BASE / 'native-guide.py.txt')
    html = (BASE / 'native-input.html').read_text()
    expected_native = dict(input_identity=identity(html.encode()), programme_identity=identity((BASE / 'native-guide.py.txt').read_bytes()),
        controls=native['controls'](html), role='Captured native guide only; current source delivery is a separate explicit check.', visual_QA='pending')
    require(same(expected_native, load(BASE / 'native-proof.json')), 'regenerated complete native retention snapshot guide and controls')
    conservation = load(BASE / 'live-conservation.json')
    captured_cards = {p: identity(raw) for p, raw in sorted(ns['committed']('docs/knowledge').items())
                      if Path(p).parent == Path('docs/knowledge') and p.endswith('.md')}
    captured_authority = next(json.loads(s) for s in ns['git'](ns['REGISTRY']).decode().splitlines() if json.loads(s).get('surface_id') == 'knowledge_cards')
    require(same(conservation, dict(revision=ns['REVISION'], role='Pre-publication snapshot only; no current-publication currency.',
        complete_members=captured_cards, authority=captured_authority)), 'whole fixed-source live-conservation snapshot')
    require(same(before, header(receipt)), 'every sealed retention byte conserved after independent consumption')


def main():
    receipt = load(CHECKS / 'sealed-replay.json')
    check(receipt)
    controls = []

    def refuse(name, candidate, cause):
        try:
            header(candidate)
        except ValueError as error:
            require(str(error) == cause, 'intended retention result refusal: ' + name)
            controls.append(dict(control=name, status=1, cause=str(error)))
        else:
            raise ValueError('false-green retention result: ' + name)

    for status in (True, 0.0, 1):
        refuse('status-' + repr(status), {**receipt, 'status': status}, 'actual retention seal integer success')
    for count in (True, 0.0):
        candidate = copy.deepcopy(receipt); next(iter(candidate['whole_members'].values()))['bytes'] = count
        refuse('byte-count-' + repr(count), candidate, 'actual retention receipt discrete member byte counts')
    candidate = copy.deepcopy(receipt); candidate['whole_members'].pop(next(iter(candidate['whole_members'])))
    refuse('lost-sealed-member', candidate, 'whole actual retention receipt member pins')
    candidate = {**receipt, 'stderr': receipt['stderr'].replace('cutoff 88%', 'cutoff 99%')}
    refuse('invented-guard-authority', candidate, 'actual successful retention default-guard diagnostics')
    borrowed = load(Path('docs/audits/public-boundary-draft-checks-20261006/sealed-replay.json'))
    require(type(borrowed['status']) is int and borrowed['status'] == 0, 'genuine prior draft-only seal success')
    refuse('borrowed-draft-construction-success', borrowed, 'exact actual retention-only seal command/result')
    print('PASS independently consumed actual retention seal, complete regenerated source/fact/control/native products and typed/member/borrowed-result refusals.')
    for row in controls:
        print(row['control'] + ': refused at ' + row['cause'])


if __name__ == '__main__':
    main()
