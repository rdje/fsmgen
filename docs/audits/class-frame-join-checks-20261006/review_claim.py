"""Review the new digit-leading immutable Git identifier under existing groups."""
import json
from pathlib import Path

base = Path('docs/audits/record-value-class-frame-join-20261006')
checks = Path('docs/audits/class-frame-join-checks-20261006')
inventory = [json.loads(s) for s in Path('doctrine/claim_verification/inventory.jsonl').read_text().splitlines()]
candidate = next(r for r in inventory if r.get('candidate_id') == 'published-54b8c8d2f481754234fb3d50')
assert candidate['excerpt'] == 'programmes/results are bound to committed 0373153b.'
binding = json.loads((base / 'binding.json').read_bytes())
assert binding['revision'] == '0373153be5fc564797d75f07928d1df4b0bd6be2'
registry = Path('doctrine/claim_verification/dispositions.jsonl')
rows = [json.loads(s) for s in registry.read_text().splitlines()]
assert not any(r.get('candidate_id') == candidate['candidate_id'] for r in rows)
review = dict(candidate_id=candidate['candidate_id'], disposition='reviewed_incidental',
    owner_path='docs/tasks/CLAIM-VERIFICATION-ADOPTION.md', owner_task='CLAIM-VERIFICATION-ADOPTION.5.3',
    reason='0373153b is the immutable prerequisite Git identity, not a numerical behavior or capacity claim. The full revision, whole committed source/member/task-owner archive comparison and actual class/frame results are retained under docs/audits/record-value-class-frame-join-20261006; the current slice owns this mechanical existing-group review.',
    reason_code='structural_reference', record_type='disposition', schema_version=1)
rows = [rows[0], *sorted([*rows[1:], review], key=lambda r:r['candidate_id'])]
registry.write_text('\n'.join(json.dumps(r,sort_keys=True,separators=(',',':')) for r in rows) + '\n')
output = checks / 'claim-review.json'; assert not output.exists()
output.write_text(json.dumps(dict(candidate=candidate, disposition=review, current_owner='SEMANTIC-INTROSPECTION-MCP-FRONTIER.60.4.3.3.5.2.1.5.2.2.3.1.2.1.3.1.2.3.2.3.3.3.3.2.3.2.3.3.2.3.2.2.2.6.2',
    binding_revision=binding['revision'], scope='Existing general-book group authority unchanged; current leaf owns new identifier review only.'),sort_keys=True,indent=2) + '\n')
print('PASS new Git identifier reviewed; existing candidate-group authority and numerical claims remain unchanged.')
