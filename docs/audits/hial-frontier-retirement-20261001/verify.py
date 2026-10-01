"""Prove exact historical-view recovery and preservation of live contracts."""
import hashlib
import json
import re
import subprocess
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]


def digest(data):
    return hashlib.sha256(data).hexdigest()


def owner_node(prefix, owner):
    start = prefix.index(('- ID: `' + owner + '`\n').encode())
    return prefix[start:]


def preserved(old, current, manifest):
    start, end = [v.encode() for v in manifest['boundaries']]
    a = old.index(start)
    b = old.index(end, a)
    section = old[a:b]
    assert digest(section) == manifest['section_sha256']
    stamp = (HERE / 'stamp.md.source').read_bytes()
    acceptance = (HERE / 'acceptance.md.source').read_bytes()
    c = current.index(b'## Historical Frontier Snapshot\n')
    assert current[c:] == stamp + old[b:] + acceptance
    prior, now = old[:a], current[:c]
    old_node = owner_node(prior, manifest['owner'])
    new_node = owner_node(now, manifest['owner'])
    for field in ('Goal', 'Acceptance'):
        pattern = ('^  ' + field + ': .*\n').encode()
        assert re.search(pattern, old_node, re.M).group() == re.search(pattern, new_node, re.M).group()
    assert b'  Status: `done`\n' in new_node
    assert b'  Commit: `this commit`\n' in new_node
    assert prior[:-len(old_node)] == now[:-len(new_node)]
    assert b'## Current Frontier\n' not in current
    return section


def main():
    m = json.loads((HERE / 'manifest.json').read_bytes())
    assert m['schema'] == 'fsmgen.historical_task_view_retirement.v1'
    assert m['source_revision'] == '889d7e1beb7bcec1b214f4209d1cf725cb2f5239'
    old = subprocess.check_output(['git', 'show', m['source_revision'] + ':' + m['source_path']], cwd=ROOT)
    assert digest(old) == m['source_sha256'] and len(old) == m['source_bytes']
    assert subprocess.check_output(['git', 'rev-parse', m['source_revision'] + ':' + m['source_path']], cwd=ROOT).decode().strip() == m['source_git_blob']
    current = (ROOT / m['source_path']).read_bytes()
    if digest(current) != m['current_sha256']:
        current = subprocess.check_output(['git', 'cat-file', 'blob', m['current_git_blob']], cwd=ROOT)
    assert digest(current) == m['current_sha256']
    section = preserved(old, current, m)
    assert len(section) == m['section_bytes'] and section.count(b'\n') == m['section_lines']
    perl = subprocess.check_output(['perl', '-MDigest::SHA=sha256_hex', '-MJSON::PP', '-e',
        'local $/; my $s=<STDIN>; print encode_json({bytes=>length($s),lines=>scalar(()=$s=~/\\n/g),sha256=>sha256_hex($s)});'], input=section)
    assert json.loads(perl) == {'bytes': m['section_bytes'], 'lines': m['section_lines'], 'sha256': m['section_sha256']}
    for bad in (current.replace(m['source_revision'].encode(), b'0' * 40),
                current.replace(b'Capture native causality at the next newly required feature HDL qualification.', b'Withdraw native causality ownership.'),
                current.replace(b'## Open Questions\n', b'## Deleted Questions\n')):
        assert bad != current
        try:
            preserved(old, bad, m)
        except (AssertionError, ValueError):
            continue
        raise AssertionError('corrupt history pointer, authoritative node or adjacent suffix accepted')
    paths = {str(p.relative_to(HERE)) for p in HERE.rglob('*') if p.is_file() and p.name != 'manifest.json'}
    assert paths == set(m['sha256'])
    for name, expected in m['sha256'].items():
        assert digest((HERE / name).read_bytes()) == expected
    assert '588028b01271a706ec78c0f66a4b5e1a00bd0b70' in (HERE / 'history-pickaxe.txt').read_text()
    print('Exact complete historical section recovered; Python/Perl byte/digest/line accounting agrees. All other live nodes and adjacent material preserved; hostile pointer/node/suffix controls reject.')


if __name__ == '__main__':
    main()
