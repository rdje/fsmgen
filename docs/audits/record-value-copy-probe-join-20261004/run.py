"""Reexecute the qualified finite reader and retain every full native product."""
import json
import subprocess
from pathlib import Path

BASE = Path('docs/audits/record-value-copy-probe-join-20261004')
ns = {'__name__': 'qualification_join'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
ns['check_binding'](ns['load'](BASE / 'binding.json'))
destination = BASE / 'execution.json'
ns['require'](not destination.exists(), 'join execution receipts are never overwritten')
command = ['python3', '-B', str(ns['READER'] / 'replay.py')]
result = subprocess.run(command, text=True, capture_output=True, timeout=60)
receipt = {'command': command, 'working_directory': '.', 'status': result.returncode,
           'stdout': result.stdout, 'stderr': result.stderr,
           'programs': {name: ns['identity']((ns['READER'] / name).read_bytes())
                        for name in ('verify.py', 'replay.py')}}
destination.write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
ns['require'](result.returncode == 0 and result.stderr == '', 'fresh join replay failed')
path = Path(result.stdout.strip().split(': ', 1)[1])
ns['require'](not path.is_absolute() and '..' not in path.parts and path.parts[0] == '.artifacts',
              'fresh complete replay path containment')
receipt['replay'] = ns['load'](path)
receipt['controls'] = ns['authority_controls'](ns['load'](BASE / 'binding.json'))
destination.write_text(json.dumps(receipt, sort_keys=True, indent=2) + '\n')
ns['check_products']()
print('PASS full finite join execution and actual owner/replay authority RED controls retained.')
