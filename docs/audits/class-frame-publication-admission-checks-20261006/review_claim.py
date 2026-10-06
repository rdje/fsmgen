"""Review the new immutable Git identifier under existing candidate authority."""
import json
from pathlib import Path

base = Path('docs/audits/record-value-class-frame-publication-admission-20261006')
checks = Path('docs/audits/class-frame-publication-admission-checks-20261006')
inventory = [json.loads(s) for s in Path('doctrine/claim_verification/inventory.jsonl').read_text().splitlines()]
candidate = next(r for r in inventory if r.get('candidate_id') == 'published-e7c11f3a66ca348e3d01950e')
assert candidate['excerpt'] == 'transitive admitted member at 017a8f70. Complete source associations, raw objects,'
binding = json.loads((base / 'binding.json').read_bytes())
assert binding['revision'] == '017a8f70b02490288ec87e6815eb6fdda6702061'
registry = Path('doctrine/claim_verification/dispositions.jsonl')
rows = [json.loads(s) for s in registry.read_text().splitlines()]
assert not any(r.get('candidate_id') == candidate['candidate_id'] for r in rows)
review = dict(candidate_id=candidate['candidate_id'],disposition='reviewed_incidental',
    owner_path='docs/tasks/CLAIM-VERIFICATION-ADOPTION.md',owner_task='CLAIM-VERIFICATION-ADOPTION.5.3',
    reason='017a8f70 is the immutable prerequisite Git identity, not a numerical behavior or capacity claim. Its whole source/member/task-owner/result and original fact/question authority are authenticated in docs/audits/record-value-class-frame-publication-admission-20261006; the current leaf owns this mechanical existing-group review.',
    reason_code='structural_reference',record_type='disposition',schema_version=1)
rows = [rows[0],*sorted([*rows[1:],review],key=lambda r:r['candidate_id'])]
registry.write_text('\n'.join(json.dumps(r,sort_keys=True,separators=(',',':')) for r in rows) + '\n')
output = checks / 'claim-review.json'; assert not output.exists()
output.write_text(json.dumps(dict(candidate=candidate,disposition=review,
    current_owner=(base / 'scope.txt').read_text().splitlines()[0].removeprefix('Owner: '),
    binding_revision=binding['revision'],scope='Existing candidate-group authority unchanged; the publication-admission leaf owns identifier review only.'),sort_keys=True,indent=2) + '\n')
print('PASS new Git identifier reviewed; existing candidate-group authority and numerical claims remain unchanged.')
