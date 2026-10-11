"""Final qualification with explicit original/model/launcher-repair source epochs."""
import argparse
from remaining_common import *
import intake
import publish
import reader
import recovery

MODEL = json.loads((BASE / 'recovery.json').read_bytes())['corrected_programmes']
INITIAL = {'__name__': 'frozen_model_qualification', '__file__': str(BASE / 'verify.py')}
exec(compile(MODEL['verify.py'], str(BASE / 'verify.py'), 'exec'), INITIAL)


def postfix(*, current=False):
    record = json.loads((BASE / 'recovery-postfix.json').read_bytes())
    need(record['owner'] == PLAN['owner'] and set(record['patches']) == {'recovery.py', 'verify.py', 'publish.py'},
         'exact source-kind recovery bookkeeping patch population')
    wanted_recovery = MODEL['recovery.py'].replace("for arg in row['command'] if", "for arg in row['command'][2:] if")
    wanted_recovery = wanted_recovery.replace("gate('reproduce-first',", "gate('reproduce-first-v2',")
    wanted_recovery = wanted_recovery.replace("'reproduce-first-actual.json'", "'reproduce-first-v2-actual.json'")
    wanted_verify = MODEL['verify.py'].split("if __name__ == '__main__':", 1)[0] + (
        "if __name__ == '__main__':\n    import runpy\n    runpy.run_path(str(BASE / 'complete.py'), run_name='__main__')\n")
    for name, patch in record['patches'].items():
        need(patch['before'] == MODEL[name] and patch['before'] != patch['after'], 'whole original/corrected recovery source bodies')
    need(record['patches']['recovery.py']['after'] == wanted_recovery
         and record['patches']['verify.py']['after'] == wanted_verify,
         'only exact launcher-prefix/receipt-route and preserved entrypoint correction')
    extra = record['publication_notice']
    need(record['patches']['publish.py']['after'] == MODEL['publish.py'].replace(record['publication_anchor'], extra + record['publication_anchor'], 1)
         and MODEL['publish.py'].count(record['publication_anchor']) == 1,
         'only explicit final task evidence adds retained failed recovery and correction')
    need(set(record['final_programmes']) == set(MODEL) | {'complete.py'}, 'whole final remaining-consumer programme population')
    for name, body in record['final_programmes'].items():
        if name != 'complete.py':
            need(body == (record['patches'][name]['after'] if name in record['patches'] else MODEL[name]),
                 'every unchanged semantic model programme retains')
        if current:
            need((BASE / name).read_bytes() == body.encode(), 'whole exact final current programme epoch')
    wrong = 'only complete original command-file programmes supplement first epoch'
    for label, declared, command in (
        ('reproduce-first', 1, ['python3', '-B', str(BASE / 'recovery.py'), '--reproduce-first']),
        ('core', 0, ['python3', '-B', str(BASE / 'verify.py'), '--core', '--current'])):
        row = json.loads((BASE / (label + '-actual.json')).read_bytes())
        need(row['command'] == ['scripts/run_with_ram_guard.sh', '--', *command]
             and type(row['status']) is int and row['status'] == 1
             and type(row['expected_status']) is int and row['expected_status'] == declared
             and row['stdout'] == '' and row['stderr'].endswith('ValueError: ' + wrong + '\n')
             and same(row['programmes'], row['programmes_after']), 'whole failed bookkeeping attempts retain their actual first cause')
        need({Path(name).name: entry['body'] for name, entry in row['programmes'].items() if Path(name).parent == BASE} == MODEL,
             'complete failed bookkeeping source epoch')
    # Every semantic native case remains bound to its unchanged model epoch.
    # Final delivery is separately captured under all final programme bodies.
    for path in BASE.glob('*-actual.json'):
        row = json.loads(path.read_bytes())
        own = {Path(name).name: entry['body'] for name, entry in row['programmes'].items() if Path(name).parent == BASE}
        if set(own) == set(MODEL):
            need(own == MODEL and same(row['programmes'], row['programmes_after']), 'whole retained model-era native programme scope')
        elif set(own) == set(record['final_programmes']):
            need(own == record['final_programmes'] and same(row['programmes'], row['programmes_after']), 'whole final native programme scope')
        else:
            need(len(own) == 14 and path.name.removesuffix('-actual.json') in recovery.FIRST,
                 'only explicitly original/model/final native epochs')
    fixed = INITIAL['gate']('independent-final', ['python3', '-B', str(BASE / 'reader.py')], stdout=reader.SUCCESS, current=current)
    return dict(patches=pin(canonical(record)), first_recovery=pin((BASE / 'reproduce-first-actual.json').read_bytes()),
                failed_core=pin((BASE / 'core-actual.json').read_bytes()), independent_final=fixed,
                condition='Initial source-kind failure and later wrong-cause recovery refusal remain distinct failed epochs. The exact launcher correction preserves every operand/model/comparison/control and original/native/private/opaque boundary; the maintained verify entrypoint invokes final complete qualification.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--core', action='store_true')
    parser.add_argument('--seal', action='store_true')
    parser.add_argument('--current', action='store_true')
    args = parser.parse_args()
    need(not (args.core and args.seal), 'one complete final remaining qualification role')
    result = INITIAL['core'](current=False)
    result['postfix'] = postfix(current=args.current or args.seal)
    if args.current or args.seal:
        roles = intake.derive()
        source = json.loads((BASE / ('source-before-v2.json' if args.core else 'source-published.json')).read_bytes())
        need(same(intake.live(roles, not args.core), source), 'whole actual final current source epoch')
    if args.core:
        print('PASS complete corrected original remaining consumer truth core and retained failed source epochs; complete join/meaning acceptance retain.')
    else:
        result['delivery'] = INITIAL['delivery'](current=False)
        if args.current or args.seal:
            publish.qualify(current=True)
        need(json.loads(canonical(result)) == result, 'whole final remaining proof JSON-native round trip')
        if args.seal:
            save('proof.json', result)
            save('manifest.json', INITIAL['catalogue']())
        else:
            need(same(json.loads((BASE / 'proof.json').read_bytes()), result)
                 and same(json.loads((BASE / 'manifest.json').read_bytes()), INITIAL['catalogue']()),
                 'whole immutable complete final remaining qualification')
        print(INITIAL['SUCCESS'], end='')
