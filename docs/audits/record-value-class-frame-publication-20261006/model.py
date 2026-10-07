"""Declare the exact admitted bodies, new metadata and preserved replay chains."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-class-frame-publication-20261006')
RETENTION = Path('docs/audits/record-value-class-frame-retention-20261006')
COMMAND = 'scripts/run_with_ram_guard.sh -- python3 -B ' + str(BASE / 'verify.py') + ' --current'
CORE = 'docs/knowledge/record-value-finite-copy-probe-reader.md'
OBSERVER = 'docs/knowledge/record-value-original-observer-helper-paths.md'
TOOLING = 'docs/knowledge/mdbook-build-destination-locality.md'
PATHS = (CORE,OBSERVER,TOOLING)
JOIN_SCOPE = 'docs/audits/record-value-class-frame-join-20261006/scope.txt'


def replay_value(text):
    start = text.index('reverify:'); end = text.index('---\n',start)
    field = text[start:end]
    return ' '.join(field.removeprefix('reverify:').removeprefix(' >-').split())


def cards():
    admitted = json.loads((RETENTION / 'proposal.json').read_bytes())
    result = {}
    for path in PATHS:
        text = admitted[path]['after']; start = text.index('reverify:'); end = text.index('---\n',start)
        prior = replay_value(text)
        if path == CORE:
            field = prior + ' && ' + COMMAND
            old = '  docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md\n'
            assert text.count(old) == 1 and text.count('date: 2026-10-05\n') == 1
            text = text.replace(old,old.rstrip('\n') + '; ' + JOIN_SCOPE + '\n',1)
            text = text.replace('date: 2026-10-05\n','date: 2026-10-06\n',1)
        elif path == OBSERVER:
            field = COMMAND
        else:
            field = prior.split(' && ')[0] + ' && ' + COMMAND
        # Compute the new source interval after the preceding exact metadata edits.
        start = text.index('reverify:'); end = text.index('---\n',start)
        result[path] = text[:start] + 'reverify: ' + field + '\n' + text[end:]
        assert result[path].rsplit('---\n',1)[1] == admitted[path]['after'].rsplit('---\n',1)[1]
    return result
