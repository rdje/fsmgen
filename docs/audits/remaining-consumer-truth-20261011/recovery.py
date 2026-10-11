"""Retain and reproduce the first model failure; qualify the explicit kind repair."""
import argparse
import types
import sys
from remaining_common import *

FIRST = ('source-before', 'replay-source-contract', 'replay-helper', 'current-before', 'produce', 'independent', 'diagnosis')
PATCHES = {'intake.py', 'value_inputs.py', 'produce.py', 'reader.py', 'controls.py', 'publish.py', 'verify.py'}


def first_epoch():
    failed = json.loads((BASE / 'independent-actual.json').read_bytes())
    need(type(failed['status']) is int and failed['status'] == 1
         and type(failed['expected_status']) is int and failed['expected_status'] == 0
         and failed['command'] == ['scripts/run_with_ram_guard.sh', '--', 'python3', '-B', str(BASE / 'reader.py'), '--save']
         and failed['stdout'] == '' and failed['stderr'].endswith('ValueError: whole source-derived remaining typed consumer operand and truth\n')
         and 'ram-guard: terminating PID tree' not in failed['stderr'], 'complete actual first unexpected model failure retains')
    programmes = failed['programmes']
    need(same(programmes, failed['programmes_after']), 'whole first failed unchanged programme epoch')
    initial = json.loads(gzip.decompress((BASE / 'recovery-inputs-before.json.gz').read_bytes()))
    own = {name: row for name, row in programmes.items() if Path(name).parent == BASE}
    need(len(own) == 14, 'complete first own model programme population')
    for name, entry in programmes.items():
        raw = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
        need(pin(raw) == entry['identity'], 'whole first model programme bytes')
        if name in own:
            need(raw == bytes.fromhex(initial[Path(name).name]['body_hex']), 'complete preserved first programme source')
        else:
            need(Path(name).read_bytes() == raw, 'every original maintained instrument retains')
    for label in FIRST:
        row = json.loads((BASE / (label + '-actual.json')).read_bytes())
        started = json.loads((BASE / (label + '-started.json')).read_bytes())
        need(same(row['programmes'], row['programmes_after'])
             and all(same(row['programmes'][name], entry) for name, entry in programmes.items())
             and all(same(row[key], value) for key, value in started.items()), 'whole complete first native programme/command epoch')
        extras = set(row['programmes']) - set(programmes)
        command_files = {arg for arg in row['command'][2:] if '\n' not in arg and len(arg) < 240 and Path(arg).is_file()}
        need(extras == command_files - set(programmes), 'only complete original command-file programmes supplement first epoch')
        for name in extras:
            entry = row['programmes'][name]
            raw = entry['body'].encode() if 'body' in entry else bytes.fromhex(entry['body_hex'])
            need(pin(raw) == entry['identity'] and fixed([name])[name] == raw == Path(name).read_bytes(),
                 'whole fixed original first command-file programme')
        need(type(row['status']) is int and row['status'] == (1 if label == 'independent' else 0)
             and type(row['expected_status']) is int and row['expected_status'] == 0,
             'original declared and actual first results never relabel')
    diagnosis = json.loads((BASE / 'diagnosis-actual.json').read_bytes())
    need(diagnosis['stdout'] == "first mismatch storable 16 prepared scope does not share parser types\nkind /expected/1/storage/1/0/1/signals/1/0/1/type_spec/1/members/1/data/1/width str int '7' 7\n",
         'complete actual first Storable source-kind diagnosis')
    first = json.loads((BASE / 'source-before.json').read_bytes())
    original = {name: pin(gzip.decompress((BASE / snapshot).read_bytes())) for name, snapshot in (
        (TASK, 'activation-task.gz'), ('MEMORY.md', 'activation-memory.gz'), ('docs/TASK_TREE.md', 'activation-index.gz'))}
    need(first['overlays'] == original, 'first source epoch retains exact original activation metadata')
    return programmes, initial


def qualify(gate, *, current=False):
    first, initial = first_epoch()
    record = json.loads((BASE / 'recovery.json').read_bytes())
    need(record['owner'] == PLAN['owner'] and record['first_candidate'] == pin(bytes.fromhex(initial['candidate.json.gz']['body_hex']))
         and pin((BASE / 'candidate.json.gz').read_bytes()) == record['first_candidate'],
         'whole first failed candidate remains unchanged')
    original = {Path(name).name: row['body'] for name, row in first.items() if Path(name).parent == BASE}
    need(set(record['corrected_programmes']) == set(original) | {'recovery.py'}, 'complete corrected programme population')
    changed = set()
    for name, body in record['corrected_programmes'].items():
        if name in original and body != original[name]:
            changed.add(name)
        if current:
            need((BASE / name).read_bytes() == body.encode(), 'whole current explicit corrected source')
    need(changed == PATCHES, 'only exact declared source-kind recovery patches')
    receipt = gate('reproduce-first-v2', ['python3', '-B', str(BASE / 'recovery.py'), '--reproduce-first'], 1, current=current)
    reproduced = json.loads((BASE / 'reproduce-first-v2-actual.json').read_bytes())
    need(reproduced['stdout'] == '' and reproduced['stderr'].endswith('ValueError: whole source-derived remaining typed consumer operand and truth\n'),
         'unchanged first reader actually reproduces its original refusal')
    return dict(first_failure=pin((BASE / 'independent-actual.json').read_bytes()),
        first_programmes=pin(canonical(first)), first_candidate=record['first_candidate'], reproduction=receipt,
        corrected_sources=pin(canonical(record['corrected_programmes'])), defect=pin((BASE / 'defect.json').read_bytes()),
        resolution='The corrected source model binds already qualified original Storable test-copy primitive kinds. It preserves authored actor structure/scalar meaning and independently checks every raw operand kind; no new provider/flag/identity inference. The first failed result remains failed and its separate actual reproduction remains an expected refusal.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--reproduce-first', action='store_true', required=True)
    parser.parse_args()
    programmes, _ = first_epoch()
    # Reconstruct all own imports from complete first captured source bodies.
    # Old intake uses immutable original activation snapshots and fixed inputs.
    for name in ('capture', 'remaining_common', 'intake', 'value_inputs', 'source_terms', 'comparison', 'reader'):
        path = str(BASE / (name + '.py'))
        module = types.ModuleType(name)
        module.__file__ = path
        sys.modules[name] = module
        exec(compile(programmes[path]['body'], path, 'exec'), module.__dict__)
    sys.modules['reader'].check(sys.modules['remaining_common'].load_product('candidate.json.gz'))
    raise ValueError('first wrong-kind reader unexpectedly accepted its original failed candidate')
