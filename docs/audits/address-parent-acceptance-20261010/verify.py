"""Qualify complete unchanged raw-parent acceptance, not totals or native identity."""
import copy
import json
import re
import runpy
from pathlib import Path

BASE = Path('docs/audits/address-parent-acceptance-20261010')
SUCCESS = ('PASS complete unchanged finite raw/numerical parent acceptance; whole original associations and '
           'fresh prerequisite readers qualify; address container and canonical publication remain open.\n')


def main():
    oracle = runpy.run_path(str(BASE / 'oracle.py')); need, same, pin = (oracle[k] for k in ('need', 'same', 'pin'))
    intake = runpy.run_path(str(BASE / 'source.py')); spec, declared = intake['rebuild']()
    registry, binding, data = oracle['fixed_inputs']()
    need(same(spec, registry) and same(declared, binding), 'whole immutable parent source intake')
    records, views, controls, counts = oracle['reconstruct'](data)
    actual = json.loads((BASE / 'checks.json').read_bytes())
    product = json.loads((BASE / 'acceptance.json').read_bytes())
    qualify = lambda p: oracle['qualify'](p, registry, binding, records, views, controls, actual)
    qualify(product)
    rejected = []

    def reject(name, mutate, cause):
        candidate = copy.deepcopy(product); mutate(candidate)
        need(not same(candidate, product), 'genuine complete parent control: ' + name)
        try:
            qualify(candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended parent refusal: ' + name + ': ' + str(error))
            rejected.append({'name': name, 'refusal': cause, 'whole_candidate': pin(json.dumps(candidate, sort_keys=True).encode())})
        else:
            raise ValueError('false-green complete parent control: ' + name)

    def first(p):
        return p['views'][0]

    def receipt(p):
        return p['actual_readers']['numerical']

    reject('native-identity-field', lambda p: p.update(native_identity=True), 'closed complete parent witness')
    reject('count-only-closure', lambda p: p.update(measured=counts), 'closed complete parent witness')
    reject('borrowed-owner', lambda p: p.update(owner='foreign'), 'exact finite parent and remaining scopes')
    reject('lost-native-boundary', lambda p: p['open'].pop(0), 'exact finite parent and remaining scopes')
    reject('cross-capture-identity-promotion', lambda p: p.update(scope='Equal numbers prove cross-capture identity'), 'exact finite parent and remaining scopes')
    reject('lost-prerequisite-input', lambda p: p['inputs'].pop('classes'), 'whole parent input identity')
    raw_parent = (BASE / 'scope.txt').read_text().strip().rsplit('.', 2)[0]
    reject('weakened-parent-acceptance', lambda p: p['contracts'][raw_parent]['contract'].update(Acceptance='Counts agree'),
           'complete unchanged parent and prerequisite contracts')
    reject('lost-completed-prerequisite', lambda p: p['completed'].pop(next(iter(p['completed']))),
           'complete unchanged parent and prerequisite contracts')
    reject('lost-original-mode', lambda p: p['original_allocation'].pop(), 'complete original parent record body phase allocation')
    reject('lost-original-empty', lambda p: p['original_allocation'][0]['domains']['api']['empty'].pop(), 'complete original parent record body phase allocation')
    reject('Boolean-original-population', lambda p: p['original_allocation'][0]['domains']['test_run'].update(population=True),
           'complete original parent record body phase allocation')
    reject('borrowed-original-body', lambda p: p['original_allocation'][0]['domains']['api']['nonempty'][0].update(
        body=p['original_allocation'][1]['domains']['api']['nonempty'][0]['body']), 'complete original parent record body phase allocation')
    nested = next((mi, name, ri) for mi, mode in enumerate(product['original_allocation']) for name, d in mode['domains'].items()
                  for ri, r in enumerate(d['nonempty']) if r['forwarded'])
    def lose_forward(p):
        mi, name, ri = nested; p['original_allocation'][mi]['domains'][name]['nonempty'][ri]['forwarded'] = None
    reject('lost-nested-forwarding', lose_forward, 'complete original parent record body phase allocation')
    reject('lost-source-view', lambda p: p['views'].pop(), 'complete parent view population')
    reject('unknown-source-view-field', lambda p: first(p).update(global_identity=True), 'closed complete parent source view')
    reject('borrowed-source-domain', lambda p: first(p).update(domain=p['views'][1]['domain']), 'whole parent original source holder numerical association')
    reject('borrowed-source-model', lambda p: first(p).update(whole_source=p['views'][1]['whole_source']), 'whole parent original source holder numerical association')
    reject('borrowed-holder-model', lambda p: first(p).update(whole_holders=p['views'][1]['whole_holders']), 'whole parent original source holder numerical association')
    reject('borrowed-numerical-view', lambda p: first(p).update(whole_numerical=p['views'][1]['whole_numerical']), 'whole parent original source holder numerical association')
    reject('lost-visible-source-slot', lambda p: first(p)['source_operands'].pop(), 'complete parent visible source numerical operands')
    reject('borrowed-visible-number', lambda p: first(p)['source_operands'][0].update(hex=first(p)['source_operands'][1]['hex']),
           'complete parent visible source numerical operands')
    reject('lost-source-provenance', lambda p: first(p)['source_operands'][0]['source']['provenance'].pop(), 'complete parent visible source numerical operands')
    ui = next(i for i, v in enumerate(product['views']) if v['unaddressed']); hi = next(i for i, v in enumerate(product['views']) if v['hidden'])
    reject('lost-unaddressed-regex', lambda p: p['views'][ui]['unaddressed'].pop(), 'complete parent unaddressed and hidden conservation')
    reject('hidden-address-promotion', lambda p: p['views'][hi]['hidden'][0].update(hex='0x1'), 'complete parent unaddressed and hidden conservation')
    for name in ('admission', 'operand', 'holder', 'numerical'):
        reject('lost-' + name + '-semantic-control', lambda p: p['controls'][name].pop(), 'complete prior semantic separating controls')
    reject('lost-actual-reader', lambda p: p['actual_readers'].pop('holders'), 'complete actual parent prerequisite population')
    reject('unknown-actual-field', lambda p: receipt(p).update(native_identity=True), 'closed complete actual parent prerequisite result')
    reject('Boolean-actual-status', lambda p: receipt(p).update(status=False), 'actual parent prerequisite integer success')
    reject('nonzero-actual-status', lambda p: receipt(p).update(status=1), 'actual parent prerequisite integer success')
    reject('borrowed-actual-command', lambda p: receipt(p).update(command=p['actual_readers']['holders']['command']), 'exact actual parent prerequisite command')
    reject('short-actual-output', lambda p: receipt(p).update(stdout='PASS\n'), 'complete actual parent prerequisite stdout')
    reject('lost-actual-instrument', lambda p: receipt(p)['instruments'].pop('scripts/run_with_ram_guard.sh'), 'complete actual parent prerequisite instruments')
    reject('widened-actual-guard', lambda p: receipt(p).update(stderr=receipt(p)['stderr'].replace('cutoff 88%', 'cutoff 99%')),
           'complete actual parent prerequisite guard stream')
    reject('borrowed-actual-PID', lambda p: receipt(p).update(stderr=receipt(p)['stderr'].replace('PID ', 'PID 1')),
           'whole current actual parent prerequisite receipt')
    producer = actual['audit']; paths = (BASE / 'checks.py', BASE / 'audit.py', Path('scripts/run_with_ram_guard.sh'))
    need(set(producer) == {'command', 'status', 'stdout', 'stderr', 'instruments'} and type(producer['status']) is int
         and producer['status'] == 0 and producer['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'audit.py')]
         and producer['stdout'] == 'PASS complete finite raw-parent acceptance witness produced; independent unchanged-contract qualification remains required.\n'
         and producer['instruments'] == {str(p): pin(p.read_bytes()) for p in paths}
         and re.fullmatch(r'ram-guard: PID [0-9]+; host [0-9.]+%; host cutoff 88%; descendant RSS cutoff 4096 MiB; poll 2s\n', producer['stderr']),
         'actual complete finite parent witness producer')
    proof = {'scope': product['scope'], 'open': product['open'], 'acceptance': pin((BASE / 'acceptance.json').read_bytes()),
             'measured': counts, 'controls': rejected,
             'programmes': {n: pin((BASE / n).read_bytes()) for n in ('source.py', 'audit.py', 'oracle.py', 'verify.py', 'checks.py')},
             'legs': {'re_derivation': 'audit.py joins the complete qualified operand/numerical/source/holder products and unchanged full contracts to every original record and source view.',
                      'falsification': 'oracle.py independently enumerates original captures, matches every complete body/phase/source/holder/numerical association, consumes fresh whole semantic readers and checks genuine whole-contract/result interventions. The prior numerical reader remains the independently qualified numerical semantic authority.',
                      'durability': 'Complete fixed predecessor namespaces/semantic products/task bodies, full acceptance witness, actual four reader commands/results/instruments, independent programmes/controls and task/book/Git retain.'},
             'missing_legs': 'Only finite raw/numerical parents qualify; all listed open scopes remain. No fresh original capture, native identity or canonical currency is established.'}
    target = BASE / 'proof.json'
    if target.exists():
        need(same(json.loads(target.read_bytes()), proof), 'whole immutable parent qualification')
    else:
        target.write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
