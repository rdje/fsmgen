"""Bind the complete dated observer prerequisite domain without recapturing it."""
import ast
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/observer-join-prerequisite-20261010')
REVISION = '60f6259b7c789d91d6df24c13e0ee1994ca030d7'
ADMISSION = Path('docs/audits/address-raw-admission-20261010')
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
JOIN = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.3.5'
EXTRA = ['record-value-class-frame-join', 'class-frame-join-checks',
         'record-value-original-observer-sources', 'record-value-original-observer-boundaries',
         'record-value-public-boundary-join', 'record-value-public-framework-profile',
         'record-value-public-native-fixtures']


def pin(raw):
    return {'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}


def native(*args):
    r = subprocess.run(['git', '--no-replace-objects', *args], capture_output=True)
    assert r.returncode == 0 and not r.stderr
    return r.stdout


def module(path):
    ns = {'__name__': 'observer_diagnosis_binding', '__file__': str(path)}
    exec(compile(path.read_bytes(), str(path), 'exec'), ns)
    return ns


def node(text, owner):
    marker = '- ID: `' + owner + '`'
    assert text.count(marker) == 1
    a = text.index(marker)
    b = text.find('\n- ID: ', a + len(marker))
    return text[a:b if b >= 0 else None]


def main():
    destination = BASE / 'binding.json'
    assert not destination.exists(), 'retain first complete binding'
    inherited = json.loads(native('show', REVISION + ':' + str(ADMISSION / 'admission.json')))
    roots = set(inherited['custody']['roots']) | {str(ADMISSION)}
    roots.update('docs/audits/' + name + '-2026100' + ('5' if 'original-observer' in name else '6')
                 for name in EXTRA)
    roots = sorted(p for p in roots if not any(p.startswith(q + '/') for q in roots if q != p))
    old = module(ADMISSION / 'admit.py')
    old['REVISION'] = REVISION
    old['roots'] = lambda: roots
    custody = old['custody']()
    task = native('show', REVISION + ':' + TASK)
    text = task.decode()
    raw_parent = JOIN.rsplit('.', 3)[0]
    owners = [JOIN, JOIN.rsplit('.', 1)[0], JOIN.rsplit('.', 2)[0],
              JOIN.rsplit('.', 2)[0] + '.6', raw_parent, raw_parent + '.5']
    bodies = {owner: node(text, owner) for owner in owners}
    assert '\n  Status: `pending`\n' in bodies[JOIN]
    assert '\n  Status: `done`\n' in bodies[JOIN.rsplit('.', 2)[0] + '.6']
    mechanisms = {}
    for name, function in [
        ('docs/audits/record-value-original-value-frames-20261005/verify.py', 'check_footprint'),
        ('docs/audits/record-value-public-boundary-join-20261006/verify.py', 'public_arguments'),
        ('docs/audits/record-value-class-frame-join-20261006/verify.py', 'prior_predicates')]:
        raw = native('show', REVISION + ':' + name)
        parsed = ast.parse(raw)
        selected = [n for n in parsed.body if isinstance(n, ast.FunctionDef) and n.name == function]
        assert len(selected) == 1
        mechanisms[name + ':' + function] = {'source': pin(raw),
            'function': ast.get_source_segment(raw.decode(), selected[0])}
    checks = json.loads((BASE / 'checks.json').read_bytes())
    assert all(type(checks[name]['status']) is int and checks[name]['status'] == 0
               for name in ('distinction', 'frontier-history'))
    record = {'revision': REVISION, 'owner': (BASE / 'scope.txt').read_text().strip(),
              'custody': custody, 'task': {'path': TASK, 'identity': pin(task), 'nodes': bodies},
              'prior_memory': native('show', REVISION + ':MEMORY.md').decode(),
              'mechanisms': mechanisms,
              'probe': json.loads((BASE / 'probe.json').read_bytes()),
              'actual_results': {name: checks[name] for name in ('distinction', 'frontier-history')},
              'scope': 'Dated prerequisite/continuity diagnosis only. Limited historical predicates remain valid; full observer/header/format repair and original parents stay open.'}
    destination.write_text(json.dumps(record, sort_keys=True, indent=2) + '\n')
    print('PASS complete fixed-Git observer prerequisite binding; whole source/evidence custody and pending original acceptance retain.')


if __name__ == '__main__':
    main()
