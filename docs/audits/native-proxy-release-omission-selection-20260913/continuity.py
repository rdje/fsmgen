"""Census every live registry before compacting the completed composition subtree."""
import hashlib
import json
from pathlib import Path
import re
import subprocess
import sys

BASE = Path(__file__).resolve().parent
ROOT = BASE.parents[2]
REVISION = 'b31f942cd6e8d7407594b8ed4a8a9a1d87f2ae67'
OWNER = 'HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.19.2.3.1.2.2.5.5.2.3.1.2.2.3.2.15.7.3.12.4.1.3.4.4.5.1'
TERMINAL = OWNER.rsplit('.', 2)[0] + '.4.6'
TASK = 'docs/tasks/HIAL-VIAL-VERIFICATION-FIXTURE-ARCHITECTURE.md'


def nodes(raw):
    text = raw.decode()
    start = text.index('## Task Tree\n')
    end = text.index('\n## ', start + 1)
    region = text[start:end]
    matches = list(re.finditer(r'^- ID: `([^`]+)`\n', region, re.M))
    result = {}
    for index, match in enumerate(matches):
        stop = matches[index + 1].start() if index + 1 < len(matches) else len(region)
        assert match.group(1) not in result
        result[match.group(1)] = region[match.start():stop]
    return result


def values(value, location=''):
    if isinstance(value, dict):
        for key, child in value.items():
            yield from values(child, location + '/' + key)
    elif isinstance(value, list):
        for index, child in enumerate(value):
            yield from values(child, location + '/' + str(index))
    elif isinstance(value, str):
        yield location, value


def census():
    files = subprocess.check_output(['git', 'ls-files', '--', 'doctrine'], cwd=ROOT, text=True).splitlines()
    files = [path for path in files if path.endswith(('.json', '.jsonl'))]
    assert files
    records, matches = [], []
    pattern = re.compile(re.escape(TERMINAL) + r'(?:\.|\b)')
    for relative in files:
        path = ROOT / relative
        assert not path.is_symlink() and path.stat().st_dev == ROOT.stat().st_dev
        raw = path.read_bytes()
        parsed = [json.loads(line) for line in raw.splitlines()] if path.suffix == '.jsonl' else [json.loads(raw)]
        for index, value in enumerate(parsed):
            for location, text in values(value):
                if pattern.search(text):
                    matches.append(dict(path=relative, record=index, field=location, value=text))
        records.append(dict(path=relative, size_bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
    assert not matches, matches
    # A second raw-byte census is conservative about any unparsed reference.
    assert all(TERMINAL.encode() not in (ROOT / path).read_bytes() for path in files)
    return records


def expected(source):
    original = nodes(source)
    selected = {ident: body for ident, body in original.items() if ident == TERMINAL or ident.startswith(TERMINAL + '.')}
    assert selected and TERMINAL in selected
    assert all('  Status: `done`\n' in body and '  Terminal:' not in body for body in selected.values())
    goal = re.search(r'^  Goal: `([^`]+)`$', selected[TERMINAL], re.M).group(1)
    compact = f'''- ID: `{TERMINAL}`
  Status: `done`
  Goal: `{goal}`
  Terminal: `version_object`
  Revision: `{REVISION}`
  Retrieval path: `{TASK}`
  Retrieved SHA256: `{hashlib.sha256(source).hexdigest()}`
  Archived node count: `{len(selected)}`
  Retention contract: `fsmgen_required_history`
  Verification: `Exact revision retrieval reconstructs every completed composition child, acceptance and original failure record. Fresh parsed and raw live-registry censuses preserve all current owners; no nested terminal or containment ceiling changes.`
  Commit: `{REVISION}`

'''
    return selected, compact


def main():
    assert sys.argv[1:] in ([], ['--apply'])
    registry_files = census()
    source = subprocess.check_output(['git', 'show', REVISION + ':' + TASK], cwd=ROOT)
    selected, compact = expected(source)
    path = ROOT / TASK; raw = path.read_bytes(); current = nodes(raw)
    if sys.argv[1:]:
        assert all(current[ident] == body for ident, body in selected.items())
        original = ''.join(selected.values())
        assert raw.decode().count(original) == 1
        updated = raw.decode().replace(original, compact, 1)
        assert updated.count('\n') < raw.count(b'\n')
        path.write_text(updated)
        current = nodes(path.read_bytes())
    assert current[TERMINAL] == compact
    assert not any(ident.startswith(TERMINAL + '.') for ident in current)
    print(json.dumps(dict(schema='fsmgen.release_omission_continuity_census.v1', owner=OWNER,
        source_revision=REVISION, source_path=TASK, source_sha256=hashlib.sha256(source).hexdigest(),
        source_bytes=len(source), source_lines=source.count(b'\n'), terminal=TERMINAL,
        archived_nodes=len(selected), archived_lines=sum(body.count('\n') for body in selected.values()),
        compact_lines=compact.count('\n'), task_lines=path.read_bytes().count(b'\n'),
        live_owner_matches=[], registry_files=registry_files, parsed_and_raw_censuses_agree=True), sort_keys=True, indent=2))


if __name__ == '__main__':
    main()
