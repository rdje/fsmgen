"""Independently consume complete actual semantic-retention results and controls."""
import copy
import json
import re
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-retention-20261006')
CHECKS = Path('docs/audits/class-frame-retention-checks-20261006')
ns = {'__name__':'independent_complete_retention','__file__':str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(),str(BASE / 'verify.py'),'exec'),ns)
require,same,identity,load = (ns[k] for k in ('require','same','identity','load'))
COMMAND = ['scripts/run_with_ram_guard.sh','--','python3','-B',str(BASE / 'verify.py'),'--seal']
GUARD = r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n'


def process(actual,command,stdout,programme=None):
    require(type(actual['status']) is int and actual['status'] == 0,'actual semantic-retention integer process success')
    require(actual['command'] == command and actual['stdout'] == stdout,'exact actual semantic-retention command and complete output role')
    require(re.fullmatch(GUARD,actual['stderr']) is not None,'actual semantic-retention default guard diagnostics')
    expected = {str(CHECKS / 'run.py'),command[4],'scripts/run_with_ram_guard.sh'}
    require(set(actual['instruments']) == expected and all(same(pin,identity((programme if p == command[4] and programme else Path(p)).read_bytes()))
        for p,pin in actual['instruments'].items()),'whole actual semantic-retention invocation programmes')


def header(receipt):
    process(receipt,COMMAND,ns['SUCCESS'])
    require(all(type(pin['bytes']) is int and pin['bytes'] >= 0 for pin in receipt['whole_members'].values()),'actual semantic-retention discrete sealed byte-count kinds')
    whole = {str(Path(p).relative_to(BASE)):pin for p,pin in ns['whole'](BASE).items()}
    require(same(receipt['whole_members'],whole),'every actual semantic-retention sealed member conserves')
    original = load(CHECKS / 'seal-command.json')
    require(same({k:receipt[k] for k in original},original) and same(receipt['actual_result_identity'],identity((CHECKS / 'seal-command.json').read_bytes())),
            'whole untouched actual semantic-retention result identity')
    require(set(receipt) == set(original) | {'whole_members','actual_result_identity'},'closed whole actual semantic-retention result')
    require(same(load(BASE / 'manifest.json'),ns['members']()),'whole immutable semantic-retention seal')
    return whole


def check(receipt):
    before = header(receipt)
    bound = ns['binding'](); ns['check_binding'](load(BASE / 'binding.json'),bound)
    ns['construct'](); sources = ns['original_sources']()
    proposal,review = load(BASE / 'proposal.json'),load(BASE / 'retention-map.json')
    for name,derived in (
        ('semantic-proof.json',ns['semantics'](proposal,review,sources)),
        ('collection-proof.json',ns['collection'](proposal,sources)),
        ('source-authority.json',ns['authority']()),
        ('controls.json',ns['controls'](proposal,review,sources,bound)),
        ('recovery-proof.json',ns['module'](BASE / 'recoveries.py')['check'](ns)),
        ('admission-proof.json',ns['fresh_admission'](False)),
        ('book-proof.json',ns['module'](BASE / 'book.py')['proof']((BASE / 'book-input.html').read_text()))):
        require(same(derived,load(BASE / name)),'whole independently regenerated retention product: ' + name)
    prerequisite = load(BASE / 'admission-replay.json')
    require(set(prerequisite) == {'command','status','stdout','stderr','instruments','inputs','role'},'closed complete fresh retention prerequisite receipt')
    first = CHECKS / 'first-semantic-verify.py.txt'
    raw = (BASE / 'verify.py').read_bytes(); extra = b"    save('recovery-proof.json',module(BASE / 'recoveries.py')['check'](globals()))\n"
    require(raw.count(extra) == 1 and first.read_bytes() == raw.replace(extra,b''),'exact retained first preparation before explicit added recovery predicate')
    process(load(CHECKS / 'semantic-preparation.json'),COMMAND[:-1] + ['--prepare'],
        'PASS complete reviewed source proposal, corpus and qualified semantic authority preparation; fresh actual admission and native/result qualification remain required.\n',first)
    process(load(CHECKS / 'fresh-replay.json'),COMMAND[:-1] + ['--replay'],ns['SUCCESS'])
    ns['module'](CHECKS / 'verify_native_failure.py')['check'](ns)
    publication = ns['module'](CHECKS / 'verify_publication.py')
    paths = publication['subprocess'].check_output(['git','ls-tree','-r','--name-only',ns['REVISION'],'docs/book/src'],text=True).splitlines()
    books = {p:publication['original'](p) for p in paths if Path(p).parent == publication['chapter'].parent and p.endswith('.md')}
    rows = publication['original'](publication['registry']).decode().splitlines()
    prior = next(json.loads(s) for s in rows if json.loads(s).get('surface_id') == 'shipped_behavior')
    publication['check'](load(BASE / 'book-change.json'),books,prior)
    process(load(CHECKS / 'publication-check.json'),['scripts/run_with_ram_guard.sh','--','python3','-B',str(CHECKS / 'verify_publication.py')],
        'PASS complete independent class/frame-guide aggregate and controls; every physical fact and collection authority unchanged.\n')
    native = load(CHECKS / 'native-phases.json'); destination = '.artifacts/class-frame-retention-book'
    commands = [
        ['python3','-B','scripts/book_source_references.py','--write'],
        ['mdbook','build','docs/book','-d',destination],
        ['python3','-B','scripts/book_source_references.py','--check','--verify-build',destination],
        ['python3','-B','scripts/check_book_source_index.py'],
        ['python3','-B',str(CHECKS / 'native_guide.py')]]
    require(set(native) == {'destination','phases','role'} and native['destination'] == destination
        and native['role'] == 'Actual repository-local native build, source selection/current/copied-byte/index checks and complete rendered retention guide controls; visual QA remains pending.',
        'whole actual native retention phase scope and destination')
    require([r['command'] for r in native['phases']] == commands,'whole ordered actual retention source native and guide phase population')
    for phase in native['phases']:
        require(type(phase['status']) is int and phase['status'] == 0 and set(phase) == {'command','status','stdout','stderr','instruments'},'closed actual retention native phase integer success')
        paths = {item for item in phase['command'] if item.endswith('.py')}
        require(set(phase['instruments']) == paths and all(same(pin,identity(Path(p).read_bytes())) for p,pin in phase['instruments'].items()),'whole actual native retention invocation programmes')
    message = 'book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold\n'
    require(native['phases'][0]['stdout'] == message and native['phases'][2]['stdout'] == message
        and native['phases'][3]['stdout'] == 'book-source-index: complete indexed directory and checked source projection agree\n'
        and native['phases'][4]['stdout'] == 'PASS native semantic-retention guide and genuine scope controls; complete rendered input retained.\n','complete actual source native index and retention guide output roles')
    complete = ''.join(r['stdout'] + r['stderr'] for r in native['phases']) + 'PASS actual complete local source/native retention publication phases.\n'
    process(load(CHECKS / 'native-result.json'),['scripts/run_with_ram_guard.sh','--','python3','-B',str(CHECKS / 'build_native.py')],complete)
    require(same(before,header(receipt)),'every semantic-retention seal byte conserves after independent consumption')


def main():
    receipt = load(CHECKS / 'sealed-replay.json'); check(receipt)
    controls = []
    def refuse(name,changed,cause):
        require(not same(changed,receipt),'genuine actual retention intervention: ' + name)
        try:
            header(changed)
        except ValueError as error:
            require(str(error) == cause,'intended actual semantic-retention refusal: ' + name + ': ' + str(error))
            controls.append(dict(control=name,status=1,cause=cause))
        else:
            raise ValueError('false-green actual semantic-retention result: ' + name)
    for status in (True,0.0,1):
        refuse('status-' + repr(status),{**receipt,'status':status},'actual semantic-retention integer process success')
    for count in (True,0.0):
        changed = copy.deepcopy(receipt); next(iter(changed['whole_members'].values()))['bytes'] = count
        refuse('member-count-' + repr(count),changed,'actual semantic-retention discrete sealed byte-count kinds')
    changed = copy.deepcopy(receipt); changed['whole_members'].pop(next(iter(changed['whole_members'])))
    refuse('lost-sealed-member',changed,'every actual semantic-retention sealed member conserves')
    refuse('widened-guard',{**receipt,'stderr':receipt['stderr'].replace('cutoff 88%','cutoff 99%')},'actual semantic-retention default guard diagnostics')
    for name,borrowed in (
        ('borrowed-admission-success',load(ns['ADMISSION_CHECKS'] / 'sealed-replay.json')),
        ('borrowed-constructor-success',load(CHECKS / 'complete-preparation.json')),
        ('borrowed-budget-success',load(CHECKS / 'complete-budget.json'))):
        require(type(borrowed['status']) is int and borrowed['status'] == 0,'genuine narrower actual retention success: ' + name)
        refuse(name,borrowed,'exact actual semantic-retention command and complete output role')
    for control in controls:
        print(control['control'] + ': refused at ' + control['cause'])
    print('PASS independently consumed complete actual semantic retention, regenerated all source/semantic/collection/recovery/native products and qualified typed/member/guard/real borrowed-result refusals.')


if __name__ == '__main__':
    main()
