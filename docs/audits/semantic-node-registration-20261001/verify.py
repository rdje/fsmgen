#!/usr/bin/env python3
"""Verify exact ownership registration using read-only Git and plain fixtures."""
import hashlib
import json
from pathlib import Path
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
TREE = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER'
MOVED = {f'{TREE}.{n}' for n in (61, 62, 63)}


def digest(data):
    return hashlib.sha256(data).hexdigest()


def section(text):
    lines = text.splitlines(keepends=True)
    start = lines.index('## Task Tree\n') + 1
    end = next((i for i in range(start, len(lines)) if lines[i].startswith('## ')), len(lines))
    return ''.join(lines[start:end])


def records(text):
    result = {}
    lines = text.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if not line.startswith('- ID: `'):
            continue
        name = line[len('- ID: `'):].split('`', 1)[0]
        assert name not in result, name
        body = []
        for field in lines[i + 1:]:
            if field.startswith('  '):
                body.append(field)
            elif field.strip():
                break
        result[name] = ''.join(body)
    return result


def preserved(before, after):
    old, new = records(before), records(after)
    assert set(old) == set(new)
    for name in old:
        if name not in (TREE, f'{TREE}.65'):
            assert old[name] == new[name], name
    assert set(records(after)) == set(records(section(after)))
    old_children = next(x for x in old[TREE].splitlines() if x.startswith('  Children: '))
    expected = old_children.replace(f', {TREE}.64',
        f', {TREE}.61, {TREE}.62, {TREE}.63, {TREE}.64')
    assert expected in new[TREE].splitlines()
    old_history = before[before.index('## Implementation Notes From `.4`'):]
    new_history = after[after.index('## Implementation Notes From `.4`'):]
    new_history = new_history.split('## Authoritative completed-node registration `.65`', 1)[0]
    for name in MOVED:
        old_history = old_history.replace(f'- ID: `{name}`\n' + old[name], '', 1)
    for number in (61, 62):
        new_history = new_history.replace(
            f'Canonical ownership is live node `.{number}` in the Task Tree above.\n', '', 1)
    # Moving records also moves their separating blank lines. Every pre-existing
    # nonblank historical prose line must retain its exact bytes and order.
    assert [line for line in old_history.splitlines() if line.strip()] == [
        line for line in new_history.splitlines() if line.strip()]


def fixture(label, text, successful, diagnostic=None):
    root = ROOT / '.artifacts/semantic-node-registration-controls' / label
    for parent in (root, *root.parents):
        if parent == ROOT:
            break
        assert not parent.is_symlink()
        assert not (parent / '.git').exists()
        if parent.exists():
            assert parent.stat().st_dev == ROOT.stat().st_dev
    task = root / TASK
    task.parent.mkdir(parents=True, exist_ok=True)
    task.write_text('# Controlled task\n\n## Task Tree\n\n' + text)
    (root / 'docs/TASK_TREE.md').write_text(
        '# Controlled index\n\n| Tree | Status | Lane | Frontier | File |\n'
        '| --- | --- | --- | --- | --- |\n'
        f'| `{TREE}` | `active` | `fixture` | `.65` | [{TASK}]({TASK}) |\n')
    run = subprocess.run(['perl', 'scripts/check_task_tree_integrity.pl', '--root', str(root)],
        cwd=ROOT, capture_output=True, text=True)
    assert (run.returncode == 0) == successful, run.stdout + run.stderr
    if diagnostic:
        assert diagnostic in run.stdout + run.stderr
    return {'case': label, 'exit_code': run.returncode, 'expected_status_verified': True}


def main():
    manifest = json.loads((HERE / 'manifest.json').read_bytes())
    assert set(manifest) == {'schema', 'baseline_revision', 'baseline_sha256',
        'source_path', 'qualified_blob', 'qualified_sha256', 'verifier_sha256'}
    assert manifest['schema'] == 'fsmgen.semantic_node_registration_repair.v1'
    assert manifest['source_path'] == TASK
    assert digest(Path(__file__).read_bytes()) == manifest['verifier_sha256']
    before = subprocess.check_output(['git', 'show', manifest['baseline_revision'] + ':' + TASK], cwd=ROOT)
    run = subprocess.run(['git', 'cat-file', 'blob', manifest['qualified_blob']],
        cwd=ROOT, capture_output=True)
    after = run.stdout if run.returncode == 0 else (ROOT / TASK).read_bytes()
    assert digest(before) == manifest['baseline_sha256']
    assert digest(after) == manifest['qualified_sha256']
    assert subprocess.check_output(['git', 'hash-object', '--stdin'],
        input=after, cwd=ROOT).decode().strip() == manifest['qualified_blob']
    old, new = before.decode(), after.decode()
    assert set(records(old)) - set(records(section(old))) == MOVED
    preserved(old, new)
    results = [fixture('before_structure_passes_but_omits_ownership', section(old), True),
               fixture('after_complete_registration', section(new), True)]
    moved = f'{TREE}.61'
    live = section(new)
    marker = f'- ID: `{moved}`\n'
    start = live.index(marker)
    end = live.index('- ID: `', start + len(marker))
    node = live[start:end]
    missing = live[:start] + live[end:]
    results.append(fixture('missing_node', missing, False, 'nonexistent direct children'))
    misplaced = missing + '\n## Historical control\n\n' + node
    assert set(records(misplaced)) == set(records(live))
    results.append(fixture('misplaced_node_whole_file_ids_still_equal', misplaced,
                           False, 'nonexistent direct children'))
    results.append(fixture('missing_root_reference', live.replace(f', {moved}', '', 1),
                           False, 'omits direct children'))
    results.append(fixture('duplicate_node', live + node, False, 'duplicate node ID'))
    changed = new.replace(node, node.replace('  Verification: `', '  Verification: `corrupted ', 1), 1)
    try:
        preserved(old, changed)
    except AssertionError:
        results.append({'case': 'changed_complete_contract', 'expected_status_verified': True})
    else:
        raise AssertionError('changed node contract accepted')
    print(json.dumps({'all_original_node_contracts_preserved_except_owned_root_and_65': True,
        'historical_nonblank_prose_preserved_in_exact_order': True,
        'previous_outside_section_records': sorted(MOVED),
        'all_qualified_records_are_authoritatively_registered': True,
        'controls': results, 'no_git_repository_created_or_modified': True}, sort_keys=True))


if __name__ == '__main__':
    main()
