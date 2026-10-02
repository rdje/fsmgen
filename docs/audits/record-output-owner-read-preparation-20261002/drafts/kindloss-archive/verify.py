import copy
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path(__file__).resolve().parent
BASELINE = '851358dd6dca12ba69a2d2491bc70d766dd4dde1'
INGRESS = ['spawn_writer', 'blocking_writer', 'spawn_readers', 'storage_then_output',
           'unused_with_child', 'competing_children', 'formal_shadow', 'imported_writer',
           'scalar_control', 'scalar_writer', 'scalar_reader', 'input_control',
           'domain_writer', 'domain_readers', 'imported_domain_blocking']
COLLISIONS = ['packet', 'start', 'done', 'isf_child_start_seen']
ROLES = ['slice', 'guard_assert', 'alias_collision', 'unused_source_collision',
         'type_collision', 'parameter_shadow', 'formal_shadow', 'self_read',
         'sample', 'record_self_read']
STATIC = ['enum_mask', 'package_mask', 'constant_mask', 'literal', 'xz_refusal', 'unused_handshake']
CASES = (INGRESS + ['collision_' + name for name in COLLISIONS]
         + ['role_' + name for name in ROLES] + ['static_' + name for name in STATIC]
         + ['precedence_' + str(i) for i in range(17)]
         + ['precedence_dt_' + str(i) for i in range(6)])
READERS = {'spawn_readers', 'domain_readers', 'scalar_reader'}
READ_ROLES = set(ROLES) - {'parameter_shadow', 'formal_shadow'}
SPEC = dict(kind='record', width=5, signed=0, member_order=['tag', 'payload'], members={
    'tag': dict(kind='bits', width='2', signed=0),
    'payload': dict(kind='bits', width='3', signed=1, state_model='four_state')})


def encoded(value):
    return json.dumps(value, sort_keys=True, separators=(',', ':'), ensure_ascii=False)


def same(left, right, label):
    assert encoded(left) == encoded(right), label


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def facts(name, value):
    child, plan = value['child'], value['prepared']
    same(plan, value['expected'], name + ' complete independently expected product')
    assert value['source'].startswith('(actor '), name + ' complete authored source'
    same(plan['counters'], child['counters'], name + ' no new register/counter')
    same(plan['declared_storage'], child['declared_storage'], name + ' no new storage')
    same(plan['reset'], child['reset'], name + ' clock/reset contract')
    same(plan['clock'], child['clock'], name + ' clock')
    same(len(plan['states']), len(child['states']), name + ' no added state')
    same(len(plan['dt_blocks']), len(child['dt_blocks']), name + ' no added DT')
    for before, after in zip(child['states'] + child['dt_blocks'], plan['states'] + plan['dt_blocks']):
        same(before['name'], after['name'], name + ' opaque container name')
        same([(a['lhs'], a['op']) for a in before['assignments']],
             [(a['lhs'], a['op']) for a in after['assignments']], name + ' write target/operator identities')
    for pin, direction in [('start', 'input'), ('done', 'output')]:
        same([p for p in plan['ports'] if p['name'] == pin],
             [dict(name=pin, direction=direction, width=1)], name + ' canonical handshake')
        assert pin not in plan['signal_type_refs'], name + ' no inherited handshake type'
    history = [dt for dt in plan['dt_blocks'] if dt['kind'] == 'child_activation']
    same(history, [dt for dt in child['dt_blocks'] if dt['kind'] == 'child_activation'], name + ' exact history')
    reads = plan['actor_output_reads']
    has_read = (name in READERS or name.startswith('collision_')
                or name.startswith('precedence_')
                or name.startswith('role_') and name[5:] in READ_ROLES)
    same(len(reads), 1 if has_read else 0, name + ' independently fixed view membership')
    if reads:
        read = reads[0]
        root = name[10:] if name.startswith('collision_') else 'packet'
        alias = 'isf_output_read_' + root
        if name in {'role_alias_collision', 'role_unused_source_collision', 'role_type_collision'}:
            alias += '_output_read'
        same(read['name'], root, name + ' source owner')
        same(read['input_port'], alias, name + ' exact private collision allocation')
        record = name in {'spawn_readers', 'domain_readers', 'role_sample', 'role_record_self_read'} or name.startswith('collision_')
        width = 5 if record else '3'
        same([p for p in plan['ports'] if p['name'] == alias],
             [dict(name=alias, direction='input', width=width, isf_handoff=1)], name + ' typed input role')
        same(plan['signal_widths'][alias], width, name + ' exact scalar JSON kind')
        assert alias not in plan['counters'] and alias not in plan['reset_values'], name + ' live input has no capture/reset'
        if record:
            same(read, dict(name=root, input_port=alias, width=5, type='frame', type_spec=SPEC), name + ' entire literal recursive type')
            same(plan['signal_type_refs'][alias], 'frame', name + ' emitted alias')
            assert '(' + alias + ' frame)' in value['emitted'], name + ' actual typed carrier'
        else:
            same(read, dict(name=root, input_port=alias, width='3'), name + ' entire literal scalar view')
    same(value['emitted'], (BASE / 'prepared' / (name + '.fsm')).read_text(), name + ' full emitted bytes')
    check = value['strict_check']
    if name.startswith('precedence_'):
        same(check, None, name + ' synthetic operand fixture is not an executable topology')
    else:
        same(check['signal'], 0, name + ' native terminal signal')
        report = json.loads(check['stdout'])
        same(report['check_schema_version'], 1, name + ' actual report version')
        if name == 'static_xz_refusal':
            same(check['exit_code'], 1, name + ' exact owned failed phase')
            same(report['success'], False, name + ' no false success')
            assert "references undeclared internal operand 'x01'" in check['stdout'], name + ' precise false operand'
        else:
            same(check['exit_code'], 0, name + ' standalone strict carrier')
            same(report['success'], True, name + ' successful check report')


def verify():
    manifest = json.loads((BASE / 'manifest.json').read_text())
    same(manifest['baseline'], BASELINE, 'exact ingress baseline')
    paths = {str(p.relative_to(BASE)) for p in BASE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    same(sorted(paths), sorted(manifest['entries']), 'complete sealed file membership')
    for name, entry in manifest['entries'].items():
        raw = (BASE / name).read_bytes()
        same(dict(bytes=len(raw), sha256=sha(raw)), entry, name + ' sealed identity')
    same(sorted(p.stem for p in (BASE / 'prepared').glob('*.json')), sorted(CASES), 'independent complete product membership')
    same(sorted(p.stem for p in (BASE / 'prepared').glob('*.fsm')), sorted(CASES), 'independent complete carrier membership')
    captures = {name: json.loads((BASE / 'prepared' / (name + '.json')).read_text()) for name in CASES}
    for name, value in captures.items():
        facts(name, value)
    for label, mutate in [
        ('role', lambda p: p['ports'][-1].update(direction='output')),
        ('kind', lambda p: p['actor_output_reads'][0]['type_spec']['members']['payload'].update(signed='1')),
        ('omitted_view', lambda p: p.update(actor_output_reads=[])),
        ('wrong_width', lambda p: p['ports'][-1].update(width=4)),
        ('omitted_port', lambda p: p['ports'].pop()),
    ]:
        value = copy.deepcopy(captures['collision_start'])
        mutate(value['prepared'])
        value['expected'] = copy.deepcopy(value['prepared'])
        same(value['prepared'], value['expected'], label + ' shared-corruption parity')
        try:
            facts('collision_start', value)
        except AssertionError:
            pass
        else:
            raise AssertionError(label + ' escaped independent literal witness')
    for name in ['omitted_reads', 'unmasked_statics', 'weak_history']:
        receipt = (BASE / 'mutants' / (name + '.tap')).read_text()
        assert 'not ok' in receipt and ('Looks like you failed' in receipt or 'No tests run' in receipt), name + ' genuine RED'
        same(manifest['mutants'][name]['exit_zero'], False, name + ' terminal non-success')
    assert 'Files=1, Tests=41' in (BASE / 'final-preparation.tap').read_text()
    assert 'All tests successful' in (BASE / 'final-focused.tap').read_text()
    assert 'Files=5, Tests=80' in (BASE / 'final-focused.tap').read_text()
    inventory = json.loads((BASE / 'production-inventory.json').read_text())
    same(inventory['changed_existing'], ['perl/FSM/Scheduler/ISF/LoweringIR.pm'], 'complete production change set')
    same(inventory['added'], ['perl/FSM/Scheduler/ISF/ChildOutputReads.pm'], 'complete production addition')
    before = subprocess.check_output(['git', 'show', BASELINE + ':perl/FSM/Scheduler/ISF/LoweringIR.pm'])
    current = (BASE / 'executed' / 'LoweringIR.pm').read_bytes()
    start = current.index(b'\n# The detached output-view planner uses')
    end = current.index(b'\nsub _formal_pruned_repeat_paths', start)
    assert current[:start] + current[end:] == before, 'exact unused scope provider is the sole LoweringIR delta'
    planner = (BASE / 'executed' / 'ChildOutputReads.pm').read_text()
    assert 'sub plan {' in planner and 'connect_child' not in planner, 'no production connection in detached module'
    print('PASS complete detached read products, literal/role/absence witnesses, native phases, shared corruptions and sealed durability')


if __name__ == '__main__':
    verify()
