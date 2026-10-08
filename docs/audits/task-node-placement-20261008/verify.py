"""Verify exact retrospective registration; historical sections stay historical."""
import copy
import hashlib
import json
import re
import subprocess
import tempfile
from pathlib import Path

BASE = Path('docs/audits/task-node-placement-20261008')
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
TREE = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER'
MOVED = {TREE + suffix for suffix in ('.78', '.78.1', '.78.2', '.78.3')}


def need(value, cause):
    if not value:
        raise ValueError(cause)


def section(text):
    lines = text.splitlines(keepends=True)
    start = lines.index('## Task Tree\n') + 1
    end = next((i for i in range(start, len(lines)) if lines[i].startswith('## ')), len(lines))
    return ''.join(lines[start:end])


def nodes(text):
    result = {}
    lines = text.splitlines(keepends=True)
    for i, line in enumerate(lines):
        if not line.startswith('- ID: `'):
            continue
        identity = line.split('`')[1]
        need(identity not in result, 'duplicate whole-document node')
        end = i + 1
        while end < len(lines) and not lines[end].startswith(('- ID: `', '## ')):
            end += 1
        result[identity] = ''.join(lines[i:end]).rstrip() + '\n'
    return result


def check(before, after):
    old, current = nodes(before), nodes(after)
    registered = nodes(section(after))
    need(set(current) == set(old) | {TREE + '.79'}, 'complete node population')
    need(set(current) == set(registered), 'all recorded nodes register authoritatively')
    for identity in old:
        if identity != TREE:
            need(old[identity] == current[identity], 'complete original node contract: ' + identity)
    old_children = re.search(r'^  Children: `(.*)`$', old[TREE], re.M)[1].split(', ')
    children = re.search(r'^  Children: `(.*)`$', current[TREE], re.M)[1].split(', ')
    need(children == old_children + [TREE + '.78', TREE + '.79'], 'exact root child additions')
    # Full source comparison is separate from node equality. Relocation changes
    # only the block, root registration and the newly owned correction node.
    block = before[before.index('- ID: `' + TREE + '.78`'):]
    stripped = after.replace(block, '', 1)
    owner = current[TREE + '.79']
    need(owner in stripped, 'complete correction owner')
    stripped = stripped.replace(owner, '', 1)
    old_root = re.search(r'^  Children: `.*`$', before, re.M)[0]
    new_root = re.search(r'^  Children: `.*`$', after, re.M)[0]
    stripped = stripped.replace(new_root, old_root, 1)
    baseline = before[:-len(block)]
    need([x for x in stripped.splitlines() if x.strip()] ==
         [x for x in baseline.splitlines() if x.strip()], 'complete nonblank source preservation')


def native(label, text, success, diagnostic=None):
    parent = Path('.artifacts/test/task-node-placement')
    parent.mkdir(parents=True, exist_ok=True)
    need(not parent.is_symlink() and parent.stat().st_dev == Path.cwd().stat().st_dev,
         'plain same-volume fixture parent')
    with tempfile.TemporaryDirectory(dir=parent) as temporary:
        root = Path(temporary)
        task = root / TASK
        task.parent.mkdir(parents=True)
        task.write_text('# Controlled node placement\n\n## Task Tree\n\n' + text)
        (root / 'docs/TASK_TREE.md').write_text('# Controlled index\n\n| Tree | Status | Lane | Frontier | File |\n'
             '| --- | --- | --- | --- | --- |\n'
             f'| `{TREE}` | `active` | `fixture` | `.79` | [{TASK}]({TASK}) |\n')
        command = ['perl', 'scripts/check_task_tree_integrity.pl', '--root', str(root.relative_to(Path.cwd()))]
        result = subprocess.run(command, capture_output=True, text=True)
        need((result.returncode == 0) == success, 'native controlled result: ' + label)
        need(diagnostic is None or diagnostic in result.stderr, 'native intended refusal: ' + label)
        need(not (root / '.git').exists(), 'no other Git repository created')
        row = {'case': label, 'command': command, 'status': result.returncode,
               'stdout': result.stdout, 'stderr': result.stderr}
    need(not root.exists(), 'owned fixture consumed')
    return row


def main():
    proof = json.loads((BASE / 'proof.json').read_bytes())
    for revision, row in proof['revisions'].items():
        raw = subprocess.check_output(['git', '--no-replace-objects', 'show', revision + ':' + TASK]).decode()
        need(raw == row['source'] and '## Task Tree\n' + section(raw).rstrip() == row['task_tree'].rstrip(),
             'entire exact committed source and independent section')
        need(set(nodes(raw)) - set(nodes(section(raw))) <= MOVED,
             'prior outside-section population')
        need(not MOVED & set(nodes(section(raw))), 'prior registration gap remains explicit')
    before = proof['revisions']['c0386c5063fb2c846775e54a6dc2132237b2ac5a']['source']
    after = proof['after_move']
    check(before, after)
    old, current = nodes(before), nodes(after)
    root = (f'- ID: `{TREE}`\n  Status: `active`\n  Goal: `Controlled placement graph.`\n'
            f'  Children: `{TREE}.78, {TREE}.79`\n\n')
    block = proof['moved_block']
    projection = root + block + '\n' + current[TREE + '.79']
    results = [native('complete-registration', projection, True)]
    hidden = root.replace(TREE + '.78, ', '') + current[TREE + '.79'] + '\n## Historical control\n' + block
    results.append(native('old-shape-passes-but-hidden-nodes-have-no-ownership', hidden, True))
    misplaced = root + current[TREE + '.79'] + '\n## Historical control\n' + block
    results.append(native('misplaced-same-whole-file-ids', misplaced, False, 'nonexistent direct children'))
    results.append(native('lost-root-reference', projection.replace(TREE + '.78, ', ''), False, 'omits direct children'))
    results.append(native('duplicate-node', projection + current[TREE + '.78.1'], False, 'duplicate node ID'))
    for label, candidate, cause in (
        ('contract-mutation', after.replace('  Goal: `Repair decision-catalog', '  Goal: `Corrupt decision-catalog', 1), 'complete original node contract: ' + TREE + '.78'),
        ('missing-registration', after.replace(block, '', 1) + '\n## Historical control\n' + block, 'all recorded nodes register authoritatively'),
        ('root-reference-loss', after.replace(', ' + TREE + '.78,', ',', 1), 'exact root child additions'),
    ):
        need(candidate != after, 'genuine source control')
        try:
            check(before, candidate)
        except ValueError as error:
            need(str(error) == cause, 'intended source refusal: ' + label)
            results.append({'case': label, 'status': 1, 'cause': cause})
        else:
            raise ValueError('false-green source control: ' + label)
    print(json.dumps({'scope': 'Dated complete-source and registration repair; no earlier graph ownership claimed.',
                      'controls': results}, sort_keys=True))


if __name__ == '__main__':
    main()
