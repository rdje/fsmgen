"""Retain the task-layout failure and seal completed isolation history exactly."""
import base64
import gzip
import hashlib
import json
from pathlib import Path
import re
import subprocess

ROOT = Path(__file__).resolve().parents[3]
AUDIT = 'docs/audits/original-join-parent-acceptance-20261018/'
TASK = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
REVISION = '5c2cabcac2cf83253587b233cb728788ba15e11a'
PREFIX = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.4.3.3.2.2.3.3.2.3.3.2.1.3.2.1.2.3.5.3'
SEALED = PREFIX + '.1'
OWNER = PREFIX + '.3.1'
OUTPUT = AUDIT + 'sequence-repair-frontier.json.gz'


def blob(body):
    return dict(bytes=len(body), sha256=hashlib.sha256(body).hexdigest(),
                body_base64=base64.b64encode(body).decode())


def nodes(body):
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n', body, re.M))
    rows = {match[1].decode(): body[match.start():matches[index + 1].start() if index + 1 < len(matches) else len(body)]
            for index, match in enumerate(matches)}
    assert len(rows) == len(matches)
    return rows


def field(body, key):
    values = re.findall(rb'^  ' + re.escape(key.encode()) + rb': `(.*)`$', body, re.M)
    assert len(values) <= 1
    return values[0].decode() if values else None


def native(revision, path):
    result = subprocess.run(['git', '--no-replace-objects', 'show', revision + ':' + path], cwd=ROOT,
                            stdin=subprocess.DEVNULL, capture_output=True, timeout=30)
    assert result.returncode == 0 and result.stderr == b''
    return result.stdout


def check():
    command = ['scripts/check_task_tree_integrity.pl']
    result = subprocess.run(command, cwd=ROOT, stdin=subprocess.DEVNULL, capture_output=True)
    return dict(command=command, status=result.returncode, stdout=blob(result.stdout), stderr=blob(result.stderr))


def main():
    output = ROOT / OUTPUT
    assert not output.exists() and not output.is_symlink()
    original = native(REVISION, TASK)
    graph = nodes(original)
    selected = {name: body for name, body in graph.items() if name == SEALED or name.startswith(SEALED + '.')}
    assert len(selected) > 1 and all(field(body, 'Status') == 'done' and field(body, 'Terminal') is None for body in selected.values())
    before = (ROOT / TASK).read_bytes()
    current = nodes(before)
    assert all(current[name] == body for name, body in selected.items()), 'complete selected history unchanged'
    terminal = (f'- ID: `{SEALED}`\n  Status: `done`\n  Goal: `{field(selected[SEALED], "Goal")}`\n'
        '  Terminal: `version_object`\n'
        f'  Revision: `{REVISION}`\n  Retrieval path: `{TASK}`\n'
        f'  Retrieved SHA256: `{hashlib.sha256(original).hexdigest()}`\n'
        f'  Archived node count: `{len(selected)}`\n  Retention contract: `fsmgen_required_history`\n'
        f'  Verification: `Whole native source and every completed isolation node/goal remain exact; sequence-repair-frontier.json.gz retains reconstruction and real checker controls. No source or live obligation is lost.`\n'
        f'  Commit: `{OWNER}: preserve task-layout failure and bounded repair frontier`\n\n').encode()
    after = before
    for name, body in selected.items():
        after = after.replace(body, terminal if name == SEALED else b'', 1)
    rebuilt = {name: body for name, body in nodes(after).items() if name != SEALED}
    rebuilt.update(selected)
    assert rebuilt == current, 'all complete current node bytes reconstruct'
    (ROOT / TASK).write_bytes(after)
    positive = check()
    assert positive['status'] == 0, positive
    bad = after.replace((f'  Archived node count: `{len(selected)}`').encode(),
                        (f'  Archived node count: `{len(selected) + 1}`').encode(), 1)
    assert bad != after
    try:
        (ROOT / TASK).write_bytes(bad)
        negative = check()
        assert negative['status'] != 0, 'real checker must reject wrong native count'
    finally:
        (ROOT / TASK).write_bytes(after)
    # Independently recover the old contract whose compact layout stopped the
    # actual helper. This proves retention; it does not repair the reader yet.
    failed_root = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.4'
    descriptor = nodes(after)[failed_root]
    retained_source = native(field(descriptor, 'Revision'), field(descriptor, 'Retrieval path'))
    assert hashlib.sha256(retained_source).hexdigest() == field(descriptor, 'Retrieved SHA256')
    old_contracts = json.loads(gzip.decompress((ROOT / 'docs/audits/original-join-canonical-publication-20261017/v2-proof.json.gz').read_bytes()))['contracts']
    canonical = nodes(retained_source)[failed_root]
    assert field(descriptor, 'Acceptance') is None
    assert field(canonical, 'Acceptance') == field(old_contracts[failed_root].encode(), 'Acceptance')
    assert field(canonical, 'Goal') == field(descriptor, 'Goal')
    value = dict(schema='fsmgen.sequence_repair_frontier.v1', revision=REVISION, owner=OWNER,
        original=blob(original), before=blob(before), after=blob(after),
        subtree={name: blob(body) for name, body in selected.items()},
        positive=positive, negative=dict(candidate=blob(bad), actual=negative),
        failed_contract=dict(root=failed_root, physical=blob(descriptor), archived_source=blob(retained_source),
                             canonical=blob(canonical), original=blob(old_contracts[failed_root].encode())),
        programme=blob(Path(__file__).read_bytes()),
        scope='Exact completed isolation source/node retention and real checker rejection; original compact-address contract is still exact in native history. Only planning/containment closes. Canonical-contract reader repair and complete sequence remain open; every original/private/native/custody gate retains.')
    with output.open('xb') as stream:
        stream.write(gzip.compress((json.dumps(value, sort_keys=True) + '\n').encode(), mtime=0))
    print('Completed isolation history reconstructs exactly; real wrong-count control refuses; failed original acceptance remains canonically retained.')


if __name__ == '__main__':
    if not __debug__:
        raise SystemExit('Acceptance assertions must be enabled.')
    main()
