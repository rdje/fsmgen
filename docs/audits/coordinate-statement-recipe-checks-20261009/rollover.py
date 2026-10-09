"""Atomic exact-version rollover of optional historical task views only."""
import hashlib
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/coordinate-statement-recipe-checks-20261009')
TASK = Path('docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md')
MANIFEST = Path('docs/tasks/history/SEMANTIC-INTROSPECTION-MCP-FRONTIER/acceptance-history.jsonl')
REVISION = '663489aa0a15bfde83c3dfc137fde65c5cd3952a'
HEADING = b'## Candidate Future Phases\n'
LIVE = b'## Version-Retrievable Historical Views\n'


def pin(raw):
    return {'bytes': len(raw), 'lines': raw.count(b'\n'), 'sha256': hashlib.sha256(raw).hexdigest()}


def fixed(path):
    result = subprocess.run(['git', '--no-replace-objects', 'show', REVISION + ':' + str(path)], capture_output=True)
    if result.returncode or result.stderr:
        raise ValueError('complete fixed rollover source result')
    return result.stdout


def graph(raw):
    return raw.split(b'## Task Tree\n', 1)[1].split(b'\n## ', 1)[0]


def main():
    if (BASE / 'rollover.json').exists():
        raise ValueError('rollover capture cannot overwrite its first result')
    original = fixed(TASK)
    current = TASK.read_bytes()
    if original.count(HEADING) != 1 or current.count(HEADING) != 1:
        raise ValueError('unique complete historical view boundary')
    history = original[original.index(HEADING):]
    start = current.index(HEADING)
    if current[start:] != history:
        raise ValueError('unchanged whole historical suffix before rollover')
    prior = fixed(MANIFEST)
    if MANIFEST.read_bytes() != prior:
        raise ValueError('exact original manifest chain')
    pointer = current[current.index(LIVE):]
    pointer = pointer.split(b'\n## ', 1)[0].rstrip() + b'\n'
    after = current[:start] + pointer
    if graph(current) != graph(after) or after[:start] + history != current:
        raise ValueError('complete live node graph and exact beforeimage reconstruction')
    registry, record = map(json.loads, prior.splitlines())
    source_id, history_id = pin(original), pin(history)
    record.update(history_id='through_' + REVISION[:12], source_revision=REVISION,
                  source_sha256=source_id['sha256'], source_lines=source_id['lines'], source_bytes=source_id['bytes'],
                  start_heading='Candidate Future Phases', history_sha256=history_id['sha256'],
                  history_lines=history_id['lines'], history_bytes=history_id['bytes'],
                  history_sections=sum(line.startswith(b'## ') for line in history.splitlines()))
    # The fixed source revision also retains the previous descriptor, including
    # its exact older-source locator; no history chain is reconstructed by guess.
    manifest = ''.join(json.dumps(row, sort_keys=True, separators=(',', ':')) + '\n'
                       for row in (registry, record)).encode()
    if len(manifest) > registry['max_bytes']:
        raise ValueError('unchanged finite manifest capacity')
    MANIFEST.write_bytes(manifest)
    TASK.write_bytes(after)
    proof = {'source_revision': REVISION, 'source_path': str(TASK), 'source': source_id,
             'history': history_id, 'prior_manifest': pin(prior), 'manifest': pin(manifest),
             'before': pin(current), 'after': pin(after), 'unchanged_live_graph': pin(graph(current)),
             'boundary': HEADING.decode().strip(), 'retention_contract': record['retention_contract'],
             'legs': {'rederive': 'Exact Git source, suffix and previous descriptor reproduce all archived bytes.',
                      'falsify': 'Unchanged historical suffix, exact beforeimage reconstruction and complete live-node byte equality separate retention from omission or graph edits; unchanged task integrity checker independently retrieves source and suffix.',
                      'durability': 'Existing finite manifest, fixed source and prior manifest revisions, named retention contract, tracked capture and owning work-unit Git commit.'}}
    (BASE / 'rollover.json').write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
    print('PASS exact optional-history rollover, whole live-node conservation and prior descriptor chain; no ceiling increase.')


if __name__ == '__main__':
    main()
