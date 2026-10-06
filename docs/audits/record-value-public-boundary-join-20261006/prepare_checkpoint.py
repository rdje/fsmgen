"""Prepare the explicit immutable-input scope for resource-safe sealing."""
from pathlib import Path

BASE = Path('docs/audits/record-value-public-boundary-join-20261006')
ns = {'__name__': 'prepare_public_boundary_checkpoint'}
exec(compile((BASE / 'verify.py').read_bytes(), str(BASE / 'verify.py'), 'exec'), ns)
checkpoint = ns['module'](BASE / 'checkpoint.py')
ns['save']('checkpoint-inputs.json', checkpoint['derive'](ns))
ns['save']('checkpoint-proof.json', checkpoint['controls'](ns))
print('PASS committed transitive checkpoint inputs, saved actual prerequisite receipts and genuine scope/member/typed/borrowed controls.')
