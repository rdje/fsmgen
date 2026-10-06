"""Pin the completed context slice before the bounded publication."""
import json
from pathlib import Path

BASE = Path('docs/audits/record-value-parser-path-publication-20261006')
ns = {'__name__': 'prepare_full_parser_publication'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
assert not (BASE / 'binding.json').exists() and not (BASE / 'manifest.json').exists()
task_path = 'docs/tasks/SEMANTIC-INTROSPECTION-MCP-FRONTIER.md'
task = ns['git'](task_path)
start = task.decode().index('- ID: `' + ns['SOURCE_OWNER'] + '`')
end = task.decode().index('\n- ID:', start + 1)
body = task.decode()[start:end]
assert '\n  Status: `done`\n' in body
archives = {str(root): ns['pins'](ns['committed'](str(root)))
            for root in (ns['CONTEXT'], ns['CHECKS'])}
(BASE / 'binding.json').write_text(json.dumps(dict(revision=ns['REVISION'], owner=ns['SOURCE_OWNER'],
    task_path=task_path, task_identity=ns['identity'](task), owner_body=body,
    archives=archives), sort_keys=True, indent=2) + '\n')
proposal = ns['transform']()
proof = ns['source_proof']()
assert proof['collection_after']['bytes_total'] <= proof['collection_before']['bytes_total'] + 890
(BASE / 'proposed-publication.json').write_text(json.dumps(proposal, sort_keys=True, indent=2) + '\n')
(BASE / 'proposed-source-proof.json').write_text(json.dumps(proof, sort_keys=True, indent=2) + '\n')
print('PASS complete committed context intake and independently measured bounded proposal.')
