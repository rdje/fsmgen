"""Qualify exact task-history rollover and the bounded coordinate container."""
import copy
import hashlib
import json
import re
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-coordinate-continuity-20261007')
PARENT = 'SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.3'


def require(condition, message):
    if not condition:
        raise ValueError(message)


def identity(raw):
    return dict(bytes=len(raw), lines=raw.count(b'\n'), sha256=hashlib.sha256(raw).hexdigest())


def get(revision, path):
    return subprocess.check_output(['git', 'show', revision + ':' + path])


def nodes(raw):
    start = raw.index(b'## Task Tree\n')
    end = raw.index(b'\n## ', start + 1)
    graph = raw[start:end]
    matches = list(re.finditer(rb'^- ID: `([^`]+)`\n', graph, re.M))
    result = {}
    for index, match in enumerate(matches):
        stop = matches[index + 1].start() if index + 1 < len(matches) else len(graph)
        name = match[1].decode()
        require(name not in result, 'unique complete task node identity')
        result[name] = graph[match.start():stop].strip()
    return result


def history(record):
    source = get(record['source_revision'], record['source_path'])
    for key, value in identity(source).items():
        require(type(record['source_' + key]) is type(value) and record['source_' + key] == value,
                'whole historical source identity')
    needle = ('## ' + record['start_heading'] + '\n').encode()
    require(source.count(needle) == 1, 'unique complete historical boundary')
    suffix = source[source.index(needle):]
    for key, value in identity(suffix).items():
        require(type(record['history_' + key]) is type(value) and record['history_' + key] == value,
                'whole historical suffix identity')
    require(type(record['history_sections']) is int and record['history_sections'] == len(re.findall(rb'^## ', suffix, re.M)),
            'complete historical section population')
    require(record['retention_contract'] == 'fsmgen_required_history', 'unchanged history retention authority')
    return source, suffix


def check(binding, after):
    source, suffix = history(binding['history'])
    require(source == get(binding['revision'], binding['task']), 'exact fixed complete predecessor')
    prior = get(binding['revision'], binding['manifest'])
    require(prior.decode() == binding['prior_manifest'], 'whole prior manifest source chain')
    history(json.loads(prior.splitlines()[1]))
    old, new = nodes(source), nodes(after)
    graph_heading = b'## Task Tree\n'
    require(source[:source.index(graph_heading)] == after[:after.index(graph_heading)],
            'whole original task metadata prefix')
    def notes(raw):
        end = raw.index(b'\n## ', raw.index(graph_heading) + 1)
        stop = raw.index(b'## Version-Retrievable Historical Views\n')
        return raw[end:stop]
    require(notes(source) == notes(after), 'whole original live engineering notes')
    require(set(new) == set(old) | {PARENT + '.1', PARENT + '.2'}, 'complete original plus coordinate-child population')
    for name in old:
        if name != PARENT:
            require(old[name] == new[name], 'whole unchanged original node: ' + name)
    original = old[PARENT].replace(b'Status: `pending`', b'Status: `active`', 1)
    children = ('Children: `' + PARENT + '.1, ' + PARENT + '.2`').encode()
    require(new[PARENT].startswith(original) and children in new[PARENT]
        and new[PARENT][len(original):].strip() == children, 'only explicit original coordinate container changes')
    require(b'Status: `done`' in new[PARENT + '.1'] and b'Status: `pending`' in new[PARENT + '.2'],
            'history closure and unimplemented coordinate successor roles')
    require(after.count(binding['live_pointer'].encode()) == 1, 'unique complete live manifest retrieval pointer')
    require(len(re.findall(rb'^## Acceptance Checklist', after, re.M)) == 1,
            'only this fresh acceptance checklist stays live')


def main():
    binding = json.loads((BASE / 'binding.json').read_bytes())
    manifest = json.loads((BASE / 'manifest.json').read_bytes())
    require({p.name for p in BASE.iterdir()} == set(manifest) | {'manifest.json'}, 'complete immutable continuity corpus')
    require(all(identity((BASE / name).read_bytes()) == pin for name, pin in manifest.items()),
            'whole immutable continuity member bytes')
    after = (BASE / 'after-task.md.txt').read_bytes()
    published = (BASE / 'after-manifest.jsonl.txt').read_bytes()
    actual = [json.loads(row) for row in published.splitlines()]
    prior_header = json.loads(binding['prior_manifest'].splitlines()[0])
    require(actual == [prior_header, binding['history']], 'whole published bounded history manifest')
    check(binding, after)
    source, suffix = history(binding['history'])
    controls = []
    for field, value, cause in (
        ('source_sha256', '0' * 64, 'whole historical source identity'),
        ('history_sha256', '0' * 64, 'whole historical suffix identity'),
        ('history_sections', True, 'complete historical section population')):
        changed = copy.deepcopy(binding); changed['history'][field] = value
        try:
            check(changed, after)
        except ValueError as error:
            require(str(error) == cause, 'intended source/suffix corruption refusal')
            controls.append(dict(field=field, cause=cause))
        else:
            raise ValueError('corrupt historical authority accepted')
    old = nodes(source)
    name = next(name for name in old if name != PARENT and b'Status: `done`' in old[name])
    changed = after.replace(old[name], old[name].replace(b'Status: `done`', b'Status: `pending`', 1), 1)
    require(changed != after, 'genuine complete old-node mutation')
    try:
        check(binding, changed)
    except ValueError as error:
        require(str(error) == 'whole unchanged original node: ' + name, 'intended original-node conservation refusal')
        controls.append(dict(node=name, cause=str(error)))
    else:
        raise ValueError('changed original task node accepted')
    print(json.dumps(dict(source=identity(source), suffix=identity(suffix), after=identity(after),
        prior_nodes=len(old), current_nodes=len(nodes(after)), controls=controls,
        scope='Exact saved task rollover and prior-source chain; complete original live graph except declared container/two children. No later task currency or coordinate meaning is claimed.'), sort_keys=True))


if __name__ == '__main__':
    main()
