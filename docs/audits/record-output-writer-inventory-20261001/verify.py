"""Authenticate detached inventory evidence without HDL or source admission."""
import copy
import hashlib
import json
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
BASE = 'f2aab272fac2d625bfc611a580484eaf8d9348d7'


def sha(raw):
    return hashlib.sha256(raw).hexdigest()


def validate(prototype, inventory):
    assert set(inventory) == {'module', 'output_declarations', 'writers'}
    assert inventory['module'] == prototype['ir']['actor_name'] == 'prototype'
    port = next(p for p in prototype['ir']['ports'] if p['name'] == 'packet')
    assert port['type'] == 'frame' and int(port['width']) == 5
    assert 'type_spec' not in port
    assert 'type_spec' not in prototype['declarations']['declarations']['packet']
    assert 'missing_declared_type' in prototype['unresolved_member_error']
    assert '(output packet (width 5))' in prototype['source']
    assert inventory['output_declarations'] == [{
        'name': 'packet', 'direction': 'output', 'width': 5, 'type': 'frame',
        'type_kind': 'record', 'fields': [
            {'path': 'tag', 'width': 2, 'lsb': 3, 'msb': 4, 'signed': 0},
            {'path': 'payload', 'width': 3, 'lsb': 0, 'msb': 2, 'signed': 0}]}]
    actual = []
    for kind, key in [('state', 'states'), ('dt', 'dt_blocks')]:
        for container in prototype['ir'][key]:
            for index, assignment in enumerate(container['assignments']):
                if assignment['lhs'] == 'packet':
                    actual.append((kind, container, index, assignment))
    assert len(actual) == len(inventory['writers']) == 1
    for writer, (kind, container, index, assignment) in zip(inventory['writers'], actual):
        assert kind == 'state' and writer['assignment'] == assignment
        assert assignment == {'lhs': 'packet', 'op': '<-', 'rhs': 'held', 'source_kind': 'set'}
        assert writer['owner']['source_name'] == container['transaction'] == 'main'
        assert writer['owner']['source_kind'] == 'transaction'
        assert writer['owner']['container_name'] == container['name']
        assert writer['activation']['assignment_index'] == index
        assert writer['activation']['container_enable'] == {'kind': 'state_active', 'state': container['name']}
        assert [writer['target'][k] for k in ['module', 'root', 'low', 'high', 'width']] == ['prototype', 'packet', 0, 4, 5]


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert manifest['baseline_revision'] == BASE
    assert set(manifest['sha256']) == {p.name for p in HERE.iterdir() if p.is_file() and p.name != 'manifest.json'}
    for name, digest in manifest['sha256'].items():
        assert sha((HERE / name).read_bytes()) == digest
    for path, item in manifest['baseline_sources'].items():
        blob = subprocess.check_output(['git', 'rev-parse', BASE + ':' + path], cwd=ROOT).decode().strip()
        assert blob == item['git_blob']
        assert sha(subprocess.check_output(['git', 'cat-file', 'blob', blob], cwd=ROOT)) == item['sha256']
    for name, projection in manifest['receipt_projections'].items():
        assert len((HERE / name).read_bytes()) == projection['raw_bytes'] - projection['replacement_count'] * (projection['root_prefix_bytes'] - len(b'<repo>'))
    assert all(type(code) is int for code in manifest['terminal_exit_codes'].values())
    assert (HERE / 'baseline-production.txt').read_text().strip() == 'perl/FSM/Scheduler/ISF/RecordOutputWriters.pm'
    for name, count in [('focused.txt', 'Files=1, Tests=7'), ('regression.txt', 'Files=4, Tests=17'), ('docs.txt', 'Files=3, Tests=310')]:
        text = (HERE / name).read_text()
        assert count in text and 'All tests successful.' in text and 'Result: PASS' in text
    assert 'HTML book written to' in (HERE / 'book.txt').read_text()
    assert 'syntax OK' in (HERE / 'syntax.txt').read_text()
    assert 'Not an ARRAY reference' in (HERE / 'draft-layout-test.txt').read_text()
    draft = (HERE / 'draft-layout-test.t.source').read_text()
    current = (HERE / 'test.t.source').read_text()
    assert current == draft.replace('$port->{type_spec}{members}[0]{type_spec}{signed}=1', '$port->{type_spec}{members}{tag}{signed}=1')
    for marker in ['actual rule and named-drive', 'actual domain realization', 'complete actor caller JSON', 'first numeric reads', 'authored record output stays closed', "['left','right']"]:
        assert marker in current
    prototype = json.loads((HERE / 'prototype.json').read_bytes())
    inventory = json.loads((HERE / 'inventory.json').read_bytes())
    validate(prototype, inventory)
    for mutation in [lambda x: x['writers'].clear(), lambda x: x['writers'][0]['owner'].update(source_name='invented'), lambda x: x['writers'][0]['target'].update(low=1), lambda x: x.update(admitted=True)]:
        bad = copy.deepcopy(inventory)
        mutation(bad)
        try:
            validate(prototype, bad)
        except AssertionError:
            continue
        raise AssertionError('Hostile omitted-writer, owner, range or admission substitution accepted')
    print('Complete detached prototype inventory, source-layout gap, exact draft correction, terminal focused/regression/docs/book receipts and baseline producer objects authenticate; omitted writers, invented owners, shifted ranges and invented admission reject. No authored output or HDL qualification.')


if __name__ == '__main__':
    main()
