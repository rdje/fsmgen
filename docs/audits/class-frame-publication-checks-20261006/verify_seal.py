"""Independently consume the complete publication and its actual execution roles."""
import ast
import copy
import json
import re
import shlex
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
CHECKS = Path('docs/audits/class-frame-publication-checks-20261006')
ns = {'__name__':'independent_complete_publication','__file__':str(BASE / 'verify.py')}
exec(compile((BASE / 'verify.py').read_bytes(),str(BASE / 'verify.py'),'exec'),ns)
require,same,identity,load = (ns[k] for k in ('require','same','identity','load'))
COMMAND = ['scripts/run_with_ram_guard.sh','--','python3','-B',str(BASE / 'verify.py'),'--seal']
GUARD = r'ram-guard: PID [0-9]+; host [0-9]+\.[0-9]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n'


def process(actual,command,stdout,programme=None):
    require(type(actual['status']) is int and actual['status'] == 0,'actual publication integer process success')
    require(actual['command'] == command and actual['stdout'] == stdout,'exact actual publication command and complete output role')
    require(re.fullmatch(GUARD,actual['stderr']) is not None,'actual publication unchanged default guard diagnostics')
    expected = {str(CHECKS / 'run.py'),command[4],'scripts/run_with_ram_guard.sh'}
    require(set(actual['instruments']) == expected and all(same(pin,identity((programme if p == command[4] and programme else Path(p)).read_bytes()))
        for p,pin in actual['instruments'].items()),'whole actual publication invocation programmes')


def header(receipt):
    process(receipt,COMMAND,ns['SUCCESS'])
    require(all(type(p['bytes']) is int and p['bytes'] >= 0 for p in receipt['whole_members'].values()),'actual publication discrete sealed member byte-count kinds')
    whole = {str(Path(p).relative_to(BASE)):pin for p,pin in ns['whole'](BASE).items()}
    require(same(receipt['whole_members'],whole),'every actual complete publication sealed member conserves')
    original = load(CHECKS / 'seal-command.json')
    require(same({k:receipt[k] for k in original},original) and same(receipt['actual_result_identity'],identity((CHECKS / 'seal-command.json').read_bytes())),
        'whole untouched actual publication result identity')
    require(set(receipt) == set(original) | {'whole_members','actual_result_identity'},'closed whole actual publication result')
    require(same(load(BASE / 'manifest.json'),ns['members']()),'whole immutable complete publication seal')
    return whole


def recoveries():
    current = (BASE / 'verify.py').read_bytes(); first = CHECKS / 'first-current-verify.py.txt'
    old = b"replace('original classes were unmeasured','original classes were measured',1)"
    new = b"replace('classes were unmeasured','classes were measured',1)"
    require(current.count(new) == 1 and first.read_bytes() == current.replace(new,old),'exact single genuine native-promotion control literal repair')
    recovery = load(CHECKS / 'current-control-recovery.json')
    for original,pin in recovery['members'].items():
        raw = Path(pin['retained']).read_bytes()
        require(same({k:v for k,v in pin.items() if k != 'retained'},identity(raw)),'whole retained first actual control/revision member: ' + original)
    failed = load(CHECKS / 'first-current-native-result.json')
    require(type(failed['status']) is int and failed['status'] == 1 and failed['stdout'] == ''
        and failed['command'] == COMMAND[:-1] + ['--current','--build','.artifacts/class-frame-publication-book']
        and failed['stderr'].endswith('ValueError: genuine full current publication intervention: core-native-promotion\n')
        and same(failed['instruments'][str(BASE / 'verify.py')],identity(first.read_bytes())),'whole actual nongenuine-control failure and programme')
    previous = ns['module'](first)
    try: previous['controls'](load(BASE / 'publication.json')['snapshot'],load(BASE / 'binding.json'))
    except ValueError as error: require(str(error) == 'genuine full current publication intervention: core-native-promotion','independently reproduced original wrapped-clause cause')
    else: raise ValueError('false-green original wrapped-clause control')
    revision = ns['module'](CHECKS / 'verify_revision.py')['check']()
    require(same(revision,load(BASE / 'reader-revision.json')),'whole independently regenerated original execution and stronger population revision')
    require(same({**revision,'after':identity(first.read_bytes())},load(CHECKS / 'first-reader-revision.json')),'whole retained pre-control-repair revision proof')
    stop = load(CHECKS / 'first-native-guard-result.json'); saved = load(CHECKS / 'native-guard-stop.json')
    require(type(stop['status']) is int and stop['status'] == 137 and stop['stdout'] == ''
        and 'host memory 89.9% reached cutoff 88%' in stop['stderr'] and 'descendant RSS cutoff 4096 MiB; poll 2s' in stop['stderr'],
        'actual terminal native host guard failure without limit widening')
    require(same(saved['actual'],identity((CHECKS / 'first-native-guard-result.json').read_bytes()))
        and same(saved['programme'],identity((CHECKS / 'first-native-programme.py.txt').read_bytes()))
        and (CHECKS / 'first-native-programme.py.txt').read_bytes() == (CHECKS / 'build_native.py').read_bytes(), 'whole terminal native failure and programme retention')
    stale = load(CHECKS / 'pre-refresh-current-native-result.json'); differences = load(CHECKS / 'pre-refresh-copy-differences.json')
    require(type(stale['status']) is int and stale['status'] == 1 and stale['stdout'] == ''
        and stale['stderr'].endswith('ValueError: fresh whole native copied source bytes\n') and len(differences) == 1
        and differences[0]['source'] == 'MEMORY.md' and not same(differences[0]['current'],differences[0]['copied']), 'actual stale continuity source-copy refusal and complete mismatch census')
    def execution_function(path):
        return next(ast.dump(n,include_attributes=False) for n in ast.parse(path.read_bytes()).body
            if isinstance(n,ast.FunctionDef) and n.name == 'execute')
    require(execution_function(CHECKS / 'second-qualify-roles.py.txt') == execution_function(CHECKS / 'qualify_roles.py'),
        'whole unchanged child execution and actual receipt function under lightweight parent')
    second = load(CHECKS / 'second-role-guard-result.json')
    require(type(second['status']) is int and second['status'] == 137 and second['stdout'] == ''
        and second['command'] == COMMAND[:4] + [str(CHECKS / 'qualify_roles.py'),'--resume']
        and re.fullmatch(GUARD + r'ram-guard: host memory 88\.2% reached cutoff 88%\nram-guard: terminating PID tree: [0-9 ]+\n',second['stderr']) is not None,
        'actual terminal second role guard stop before any suffix completion')
    require(set(second['instruments']) == {str(CHECKS / 'run.py'),str(CHECKS / 'qualify_roles.py'),'scripts/run_with_ram_guard.sh'}
        and all(same(pin,identity((CHECKS / 'second-qualify-roles.py.txt' if p == str(CHECKS / 'qualify_roles.py') else Path(p)).read_bytes()))
            for p,pin in second['instruments'].items()),'whole retained second role controller invocation programmes')
    process(load(CHECKS / 'revision-result.json'),COMMAND[:4] + [str(CHECKS / 'verify_revision.py')],
        'PASS complete original execution/source/model functions preserve; genuine global question/physical population/member losses pass the first sketch and refuse the strengthened current predicate.\n')
    recovery = ns['module'](CHECKS / 'crash_recovery.py')
    recovery['check']()
    process(load(CHECKS / 'crash-restoration-result.json'),COMMAND[:4] + [str(CHECKS / 'crash_recovery.py'),'--restore'],
        'PASS exact interrupted prefix/controller/book custody and publication-byte restoration; missing process result remains unclaimed.\n')
    denial = load(CHECKS / 'crash-restoration-sandbox-denial.json')
    require(type(denial['status']) is int and denial['status'] == 2 and denial['stdout'] == ''
        and denial['stderr'] == 'ram-guard: process-tree inspection is unavailable; rerun outside the sandbox or with process-inspection approval\n',
        'actual sandbox process-inspection denial retained before guarded restoration')
    require(execution_function(CHECKS / 'crash-qualify-roles.py.txt') == execution_function(CHECKS / 'qualify_roles.py'),
        'whole unchanged child execution after exact crash-prefix recovery')
    stale = load(CHECKS / 'crash-current-native-stale-result.json')
    differences = load(CHECKS / 'crash-copy-differences.json')
    require(type(stale['status']) is int and stale['status'] == 1 and stale['stdout'] == ''
        and stale['command'] == COMMAND[:-1] + ['--current','--build','.artifacts/class-frame-publication-book']
        and stale['stderr'].endswith('ValueError: fresh whole native copied source bytes\n')
        and differences and all(not same(r['current'],r['copied']) for r in differences),
        'actual recovered native stale-copy refusal and whole mismatch census retained')


def native(name,programme):
    value = load(CHECKS / name); destination = '.artifacts/class-frame-publication-book'
    commands = [['python3','-B','scripts/book_source_references.py','--write'],['mdbook','build','docs/book','-d',destination],
        ['python3','-B','scripts/book_source_references.py','--check','--verify-build',destination],['python3','-B','scripts/check_book_source_index.py'],
        ['python3','-B',str(CHECKS / 'native_guide.py')]]
    require(set(value) == {'destination','phases','role'} and value['destination'] == destination
        and value['role'] == 'Actual complete repository-local canonical/current/copied-source/index/native-guide phases; original raw/native captures retained and visual QA pending.'
        and [r['command'] for r in value['phases']] == commands,'whole actual ordered native publication phase population and scope')
    for phase in value['phases']:
        require(type(phase['status']) is int and phase['status'] == 0 and set(phase) == {'command','status','stdout','stderr','instruments'},'closed native publication actual integer success')
        require(set(phase['instruments']) == {p for p in phase['command'] if p.endswith('.py')}
            and all(same(pin,identity(Path(p).read_bytes())) for p,pin in phase['instruments'].items()),'whole actual native invocation programmes')
    message = 'book-source-references: complete source/role/member/relative-endpoint/current-byte/ignore contracts hold\n'
    require(value['phases'][0]['stdout'] == message and value['phases'][2]['stdout'] == message
        and value['phases'][3]['stdout'] == 'book-source-index: complete indexed directory and checked source projection agree\n'
        and value['phases'][4]['stdout'] == 'PASS native complete class/frame current retained guide and genuine scope controls; whole rendered input retained.\n', 'whole actual native canonical/copied/index/guide output roles')
    result = {'native-phases.json':'native-result.json','refresh-native-phases.json':'refresh-native-result.json',
        'recovery-native-phases.json':'recovery-native-result.json'}[name]
    process(load(CHECKS / result),COMMAND[:4] + [str(CHECKS / programme)],
        ''.join(r['stdout'] + r['stderr'] for r in value['phases']) + 'PASS actual complete local source/native class/frame publication phases.\n')


def roles():
    value = load(CHECKS / 'roles.json'); rows = value['records']
    expected = ['new-default','new-current','retention-default','retention-old-epoch','tooling-default','tooling-old-epoch',
        'core-obligation-1','core-obligation-2','core-obligation-3','core-obligation-4','original-locality-obligation','unrelated-progress-current','unrelated-progress-default']
    require(set(value) == {'records','role'} and value['role'] == 'Actual distinct current, saved checkpoint and original obligations; fresh finite probe is not original raw-error recapture.'
        and [r['name'] for r in rows] == expected,'complete actual current/checkpoint/original/unrelated-progress role population')
    by = {r['name']:r for r in rows}; tooling = Path('docs/audits/record-value-tooling-current-reader-20261006/verify.py'); old = ns['module'](tooling)
    commands = {
        'new-default':(['python3','-B',str(BASE / 'verify.py')],ns['SUCCESS']),
        'new-current':(['python3','-B',str(BASE / 'verify.py'),'--current'],ns['CURRENT_SUCCESS']),
        'retention-default':(['python3','-B',str(ns['RETENTION'] / 'verify.py')],ns['retention']['SUCCESS']),
        'retention-old-epoch':(['python3','-B',str(ns['RETENTION'] / 'verify.py'),'--live-unchanged'],None),
        'tooling-default':(['python3','-B',str(tooling)],old['SUCCESS']),
        'tooling-old-epoch':(['python3','-B',str(tooling),'--current'],None),
        'unrelated-progress-current':(['python3','-B',str(BASE / 'verify.py'),'--current'],ns['CURRENT_SUCCESS']),
        'unrelated-progress-default':(['python3','-B',str(BASE / 'verify.py')],ns['SUCCESS'])}
    for i,c in enumerate(ns['model']['replay_value'](ns['model']['cards']()[ns['CORE']]).split(' && ')):
        commands['core-obligation-' + str(i+1)] = (shlex.split(c),None)
    commands['original-locality-obligation'] = (shlex.split(ns['model']['replay_value'](ns['model']['cards']()[ns['TOOLING']]).split(' && ')[0]),None)
    original = (CHECKS / 'unrelated-book-before.md.txt').read_bytes()
    progress = b'\nTemporary unrelated book-progress control for the owned current-reader qualification.\n'
    require(original == load(BASE / 'publication.json')['chapter_after'].encode(),'whole original unrelated progress chapter epoch')
    for row in rows:
        command,stdout = commands[row['name']]; status = 1 if row['name'].endswith('old-epoch') else 0
        require(type(row['status']) is int and row['status'] == status and row['command'] == command,'whole actual role command and integer status: ' + row['name'])
        require(set(row) == {'name','command','status','stdout','stderr','instruments','cards','chapter'},'closed actual role execution')
        wanted = {str(CHECKS / 'qualify_roles.py')} | {p for p in command if p.endswith('.py') or p == 'scripts/run_with_ram_guard.sh'}
        saved_controller = ('first-qualify-roles.py.txt' if row['name'] in expected[:6]
            else 'crash-qualify-roles.py.txt' if row['name'] in expected[6:11] else 'qualify_roles.py')
        require(set(row['instruments']) == wanted and all(same(pin,identity((CHECKS / saved_controller if p == str(CHECKS / 'qualify_roles.py') else Path(p)).read_bytes()))
            for p,pin in row['instruments'].items()),'whole actual initial/resumed role invocation programmes')
        require(row['cards'] == {p:identity(t.encode()) for p,t in ns['model']['cards']().items()},'complete current card input for each actual role')
        require(same(row['chapter'],identity(original + (progress if row['name'].startswith('unrelated-progress-') else b''))),'whole actual genuine unrelated progress input')
        if stdout is not None: require(row['stdout'] == stdout and row['stderr'] == '','whole actual distinct checkpoint/current output role')
        if status == 1:
            cause = 'whole unchanged live original source facts and decisions' if row['name'] == 'retention-old-epoch' else 'complete current core observer tooling facts questions identity and routes'
            require(row['stdout'] == '' and row['stderr'].endswith('ValueError: ' + cause + '\n'),'whole actual honest old-epoch refusal')
        if command[0] == 'scripts/run_with_ram_guard.sh': require(re.fullmatch(GUARD,row['stderr']) is not None,'actual original-chain unchanged guard diagnostics')
    fresh = by['core-obligation-3']; prefix = 'PASS fresh exact-source seven-mode native replay and independent complete graph/cause/TAP controls: '
    require(fresh['stdout'].startswith(prefix) and fresh['stdout'].endswith('\n'),'whole actual fresh finite probe replay output role')
    path = Path(fresh['stdout'][len(prefix):].strip()); require(not path.is_absolute() and '..' not in path.parts and path.is_relative_to(Path('.artifacts/record-value-copy-reader-20261004')),'same-volume repository-relative actual finite probe receipt')
    ns['module'](CHECKS / 'retain_probe.py')['derive'](load(CHECKS / 'fresh-probe-retention.json'))
    process(load(CHECKS / 'finite-probe-retained-result.json'),COMMAND[:4] + [str(CHECKS / 'retain_probe.py')],
        'PASS complete actual fresh finite fixture copy, byte/member verification and independent native replay qualification; no ignored scratch dependency.\n')
    require(ns['CHAPTER'].read_bytes() == original,'exact actual unrelated progress restoration')
    crash = load(CHECKS / 'crash-role-prefix.json')
    require(same(crash['records'],rows[:11]),'whole completed crash prefix conserves without replay or fabricated terminal result')
    first = load(CHECKS / 'first-role-guard-result.json'); prefix = load(CHECKS / 'first-role-prefix.json')
    require(same(prefix['records'],rows[:6]),'whole actual completed first role prefix conserved by suffix-only resume')
    require(type(first['status']) is int and first['status'] == 137 and first['command'] == COMMAND[:4] + [str(CHECKS / 'qualify_roles.py')]
        and re.fullmatch(GUARD + r'ram-guard: host memory 88\.4% reached cutoff 88%\nram-guard: terminating PID tree: [0-9 ]+\n',first['stderr']) is not None
        and first['stdout'] == ''.join(r['name'] + ': actual status ' + str(r['status']) + '\n' for r in rows[:6]),'whole actual terminal first role guard stop and completed process prefix')
    require(set(first['instruments']) == {str(CHECKS / 'run.py'),str(CHECKS / 'qualify_roles.py'),'scripts/run_with_ram_guard.sh'}
        and all(same(pin,identity((CHECKS / 'first-qualify-roles.py.txt' if p == str(CHECKS / 'qualify_roles.py') else Path(p)).read_bytes()))
            for p,pin in first['instruments'].items()),'whole actual first role controller instruments retained before suffix resume')
    process(load(CHECKS / 'roles-result.json'),COMMAND[:4] + [str(CHECKS / 'qualify_roles.py'),'--resume-crash'],
        ''.join(r['name'] + ': actual status ' + str(r['status']) + '\n' for r in rows[11:]) + 'PASS actual full current/checkpoint/original replay and unrelated-book progress roles with exact restoration; original raw/native captures retained.\n')


def check(receipt):
    before = header(receipt); bound = ns['binding'](); ns['check_binding'](load(BASE / 'binding.json'),bound)
    for name,derived in [('semantic-proof.json',ns['semantic_products']()),('source-model.json',ns['source_model']()),
        ('replay-proof.json',ns['replays'](False)),('controls.json',ns['controls'](load(BASE / 'publication.json')['snapshot'],bound)),
        ('native-proof.json',ns['book']['proof']((BASE / 'native-input.html').read_text()))]:
        require(same(derived,load(BASE / name)),'whole independently regenerated complete publication product: ' + name)
    first = CHECKS / 'first-verify.py.txt'
    process(load(CHECKS / 'preparation.json'),COMMAND[:-1] + ['--prepare'],
        'PASS complete publication source/semantic/capacity preparation; actual replay and atomic current publication remain required.\n',first)
    process(load(CHECKS / 'fresh-replay.json'),COMMAND[:-1] + ['--replay'],ns['REPLAY_SUCCESS'],first)
    process(load(CHECKS / 'global-loss-result.json'),COMMAND[:4] + [str(CHECKS / 'qualify_global_loss.py')],
        'ROOT CAUSE: unpublished target-only current predicate accepts a genuine non-target global question loss and reduced physical population; live publication must wait for whole-population repair.\n')
    recoveries(); publication = ns['module'](CHECKS / 'verify_publication.py')
    derived = publication['check'](load(BASE / 'publication.json'))
    require(same(derived,load(CHECKS / 'publication-proof.json')['proof']),'whole independently regenerated published source/global/book/authority')
    publication['main']()
    process(load(CHECKS / 'publication-check.json'),COMMAND[:4] + [str(CHECKS / 'verify_publication.py')],
        'PASS independent complete class/frame source/card/global/book population and measured authority; genuine source/member/scope/aggregate/ceiling losses refuse.\n')
    native('native-phases.json','build_native.py'); native('refresh-native-phases.json','refresh_native.py')
    native('recovery-native-phases.json','recovery_native.py'); roles()
    process(load(CHECKS / 'current-native-result.json'),COMMAND[:-1] + ['--current','--build','.artifacts/class-frame-publication-book'],ns['CURRENT_SUCCESS'])
    require(same(before,header(receipt)),'every complete publication byte conserves after independent full consumption')


def main():
    receipt = load(CHECKS / 'sealed-replay.json'); check(receipt); controls = []
    def refuse(name,candidate,cause):
        require(not same(candidate,receipt),'genuine complete actual publication intervention: ' + name)
        try: header(candidate)
        except ValueError as error:
            require(str(error) == cause,'intended actual publication refusal: ' + name + ': ' + str(error)); controls.append(dict(control=name,status=1,cause=cause))
        else: raise ValueError('false-green complete actual publication result: ' + name)
    for status in (True,0.0,1): refuse('status-' + repr(status),{**receipt,'status':status},'actual publication integer process success')
    for count in (True,0.0):
        changed = copy.deepcopy(receipt); next(iter(changed['whole_members'].values()))['bytes'] = count
        refuse('member-count-' + repr(count),changed,'actual publication discrete sealed member byte-count kinds')
    changed = copy.deepcopy(receipt); changed['whole_members'].pop(next(iter(changed['whole_members'])))
    refuse('lost-sealed-member',changed,'every actual complete publication sealed member conserves')
    refuse('widened-guard',{**receipt,'stderr':receipt['stderr'].replace('cutoff 88%','cutoff 99%')},'actual publication unchanged default guard diagnostics')
    for name,borrowed in [('borrowed-current-native-success',load(CHECKS / 'current-native-result.json')),
        ('borrowed-preparation-success',load(CHECKS / 'preparation.json')),
        ('borrowed-retention-success',load(ns['RETENTION_CHECKS'] / 'sealed-replay.json'))]:
        require(type(borrowed['status']) is int and borrowed['status'] == 0,'real narrower actual publication success: ' + name)
        refuse(name,borrowed,'exact actual publication command and complete output role')
    for c in controls: print(c['control'] + ': refused at ' + c['cause'])
    print('PASS independently consumed complete actual publication, regenerated full source/semantic/global/revision/recovery/native/role products and qualified typed/member/guard/real borrowed-result refusals.')


if __name__ == '__main__': main()
