"""Qualify complete native control custody without selecting semantic refusals."""
import argparse
import copy
import hashlib
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-native-control-capture-20261008')
PLANS = Path('docs/audits/record-value-coordinate-native-control-plans-20261008')
ROLE = 'Dated native control custody only. Every raw coordinate/frame/error/argument remains intact; semantic refusing decisions and original identities remain pending.'
SUCCESS = 'PASS complete one-time native control custody and genuine custody controls; semantic refusals remain pending.\n'


def need(value, cause):
    if not value:
        raise ValueError(cause)


def pin(raw):
    return dict(bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest())


def same(a, b):
    return json.dumps(a, sort_keys=True) == json.dumps(b, sort_keys=True)


def read(path):
    return json.loads(path.read_bytes())


def capture_module():
    ns = {'__name__': 'native_control_capture_contract'}
    exec(compile((BASE / 'capture.py').read_bytes(), str(BASE / 'capture.py'), 'exec'), ns)
    return ns


def actual(row, command, root):
    need(row['command'] == command and row['cwd'] == root, 'exact legitimate control native command and actual root')
    need(type(row['status']) is int and row['status'] == 0, 'integer actual control native success')
    for field in ('stdout', 'stderr'):
        need(type(row[field]) is str and same(row[field + '_identity'], pin(row[field].encode())),
             'whole raw native control stream identity')


def derive(wire):
    module = capture_module(); plans = read(PLANS / 'plans.json')['plans']
    need(wire['scope'] == module['SCOPE'], 'native custody cannot promote semantic or original qualification')
    admission = wire['admission']
    need(same(admission['binding'], module['binding']()) and admission['planned_invocations'] == [p['invocation'] for p in plans],
         'whole committed native control plan admission')
    need(same(admission['capture_programme'], pin((BASE / 'capture.py').read_bytes())), 'whole native control capture instrument identity')
    need(admission['scope'] == module['SCOPE'] and type(admission['captured_utc']) is str and admission['captured_utc'],
         'whole dated native control admission scope')
    need(type(wire['runs']) is list and len(wire['runs']) == len(plans), 'complete declared native control run population')
    tools = wire['tools']; root = plans[0]['invocation']['root']
    actual(tools['version'], ['perl', '-V'], root); actual(tools['modules'], module['METADATA'], root)
    need(same(tools['executable_before'], tools['executable_after'])
         and type(tools['executable_before']['bytes']) is int and tools['executable_before']['bytes'] > 0
         and type(tools['executable_before']['sha256']) is str and len(tools['executable_before']['sha256']) == 64,
         'complete stable opaque native executable identity')
    metadata = json.loads(tools['modules']['stdout'])
    need(set(metadata) == {'perl', 'json_pp', 'carp', 'test_more'} and all(type(v) is str for v in metadata.values()),
         'complete native public module version metadata')
    roles = [r['role'] for r in read(PLANS / 'inputs.json')['hypotheses']['calls']]
    products = []
    for row, plan in zip(wire['runs'], plans):
        need(row['name'] == plan['name'] and same(row['invocation'], plan['invocation']), 'exact native control variant allocation')
        actual(row['actual'], plan['invocation']['command'], plan['invocation']['root'])
        need(same(row['source'], plan['source']), 'complete independently committed native variant source bytes')
        need(same(row['before'], plan['source_pins']) and same(row['after'], plan['source_pins']),
             'every complete native variant source member conserves')
        need(same(row['environment'], dict(PERL5OPT='', PERL5LIB='', temporary_root=plan['invocation']['root'] + '/.tmp',
                                          runtime_absolute_temporary_values=True)), 'unchanged native control environment and locality recipe')
        payload = json.loads(row['actual']['stdout'])
        need(set(payload) == {'observations', 'module_filename'} and type(payload['module_filename']) is str
             and [r['role'] for r in payload['observations']] == roles, 'whole source-declared native control observation allocation')
        for observed in payload['observations']:
            need(set(observed) == {'role', 'frames', 'trace', 'guard_ok', 'guard_error'}
                 and observed['guard_ok'] is None and type(observed['trace']) is str and observed['trace']
                 and type(observed['guard_error']) is str and observed['guard_error'], 'whole raw native control error observation')
            need(type(observed['frames']) is list and observed['frames'], 'whole nonempty native control frames')
            for frame in observed['frames']:
                need(type(frame) is list and len(frame) == 8 and type(frame[2]) is int and frame[2] > 0
                     and all(type(frame[i]) is str for i in (0, 1, 3)), 'whole raw native control frame kinds')
        products.append(dict(name=row['name'], invocation=row['invocation'], payload=payload,
                             whole_raw_wire_identity=pin(row['actual']['stdout'].encode()), source_pins=row['before']))
    return dict(runs=products, tools=tools, role=ROLE)


def controls(wire):
    mutations = [
        ('Boolean-status', lambda c: c['runs'][0]['actual'].update(status=False), 'integer actual control native success'),
        ('float-status', lambda c: c['runs'][1]['actual'].update(status=0.0), 'integer actual control native success'),
        ('lost-run', lambda c: c['runs'].pop(), 'complete declared native control run population'),
        ('borrowed-root', lambda c: c['runs'][2]['actual'].update(cwd=c['runs'][2]['invocation']['root'] + '/borrowed'),
         'exact legitimate control native command and actual root'),
        ('lost-source-member', lambda c: c['runs'][3]['after'].pop('borrowed-body.pl'), 'every complete native variant source member conserves'),
        ('borrowed-source', lambda c: c['runs'][0]['source'].update({'fixture.pl': c['runs'][1]['source']['fixture.pl']}),
         'complete independently committed native variant source bytes'),
        ('lost-wire-byte', lambda c: c['runs'][0]['actual'].update(stdout=c['runs'][0]['actual']['stdout'][:-1]),
         'whole raw native control stream identity'),
        ('borrowed-instrument', lambda c: c['admission']['capture_programme'].update(sha256='0' * 64),
         'whole native control capture instrument identity'),
        ('semantic-promotion', lambda c: c.update(scope='All native semantic refusals and original identities qualify.'),
         'native custody cannot promote semantic or original qualification'),
    ]
    rows = []
    for name, mutate, cause in mutations:
        candidate = copy.deepcopy(wire); mutate(candidate)
        need(not same(candidate, wire), 'genuine native custody candidate')
        try:
            derive(candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended native custody refusal: ' + name)
            rows.append(dict(control=name, status=1, cause=cause))
        else:
            raise ValueError('false-green native custody candidate: ' + name)
    return rows


def members():
    need(all(p.is_file() and not p.is_symlink() and p.stat().st_dev == Path.cwd().stat().st_dev for p in BASE.iterdir()),
         'whole regular same-volume native capture seal')
    return {p.name: pin(p.read_bytes()) for p in BASE.iterdir() if p.name != 'manifest.json'}


def save(name, value):
    raw = json.dumps(value, sort_keys=True, indent=2) + '\n'; path = BASE / name
    if path.exists():
        need(path.read_text() == raw, 'whole retained native custody product: ' + name)
    else:
        need(not (BASE / 'manifest.json').exists(), 'sealed native custody cannot publish')
        path.write_text(raw)


def main():
    parser = argparse.ArgumentParser(description=__doc__); parser.add_argument('--seal', action='store_true'); args = parser.parse_args()
    if (BASE / 'manifest.json').exists():
        need(same(read(BASE / 'manifest.json'), members()), 'whole immutable native control custody seal')
    module = capture_module(); before = module['binding']()
    wire = read(BASE / 'wire.json')
    need(same(wire['admission'], read(BASE / 'started.json')) and same(wire['tools'], read(BASE / 'tools.json'))
         and all(same(row, read(BASE / ('run-' + row['name'] + '.json'))) for row in wire['runs']),
         'every complete retained native admission/tool/run checkpoint')
    save('binding.json', before); save('custody.json', derive(wire)); save('controls.json', controls(wire))
    need(same(module['binding'](), before), 'every complete plan prerequisite conserves')
    if args.seal:
        save('manifest.json', members())
    print(SUCCESS, end='')


if __name__ == '__main__':
    main()
